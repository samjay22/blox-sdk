--!strict
local Types = require("../Types/Core")
local Json = require("../Core/Json")
local Decode = require("../Core/JsonDecode")
local Routing = require("../Core/Routing")
local Path = require("../Core/Path")
local Fake = {}
--- Adapt endpoint fixtures to BatchService, asserting that the physical boundary is batch-only.
function Fake.batch(runtime: Types.Runtime, handler: Types.Backend): Types.Backend
	return function(request: Types.HttpRequest): Types.HttpResponse
		assert(string.match(request.Url, "^https://[^/]+/batch%-service/api/batch$"), "Direct HTTP forbidden")
		assert(request.Method == "POST", "Batch must POST")
		assert(request.Body and #request.Body <= 1024 * 1024, "Invalid batch bytes")
		local batch = Decode.decode(request.Body :: string) :: any
		assert(#batch.ops >= 1 and #batch.ops <= 100, "Invalid batch size")
		local results: { any } = {}
		for _, op in batch.ops do
			local service = if op.service == "leaderboard" then "leaderboards" else op.service
			local prefix = assert(Routing.prefixes[service], "Unknown service")
			local url = string.match(request.Url, "^https://[^/]+") .. prefix .. op.path
			local names: { string } = {}
			for name in op.query or {} do
				table.insert(names, name)
			end
			table.sort(names)
			for i, name in names do
				url ..= (if i == 1 then "?" else "&") .. name .. "=" .. Path.encode(op.query[name])
			end
			local headers = table.clone(request.Headers)
			for name, value in op.headers or {} do
				headers[name] = value
			end
			local wire = handler({
				Url = url,
				Method = op.method,
				Headers = headers,
				Body = if op.body == nil
					then nil
					else if type(op.body) == "string"
							and headers["Content-Type"] == "application/x-ndjson"
						then op.body
						else Json.encode(op.body),
			})
			local value: unknown = Json.null
			if headers.Accept ~= "application/json" then
				value = wire.Body
			elseif wire.Body ~= "" then
				local ok, decoded = pcall(Decode.decode, wire.Body)
				value = if ok then decoded else wire.Body
			end
			table.insert(
				results,
				{ id = op.id, status = wire.StatusCode, headers = wire.Headers, body = value }
			)
		end
		return {
			StatusCode = 200,
			Headers = {},
			Body = runtime.encode({ results = Json.array(results), serverTimeMs = 0 }),
		}
	end
end
export type Step = {
	status: number?,
	body: string?,
	headers: { [string]: string }?,
	delay: number?,
	fail: boolean?,
	check: ((Types.HttpRequest) -> ())?,
}
export type Fake = { backend: Types.Backend, count: () -> number, remaining: () -> number }
--- Return a deterministic scripted backend. Request headers/bodies are never retained or logged.
function Fake.new(runtime: Types.Runtime, steps: { Step }): Fake
	local index = 0
	local backend: Types.Backend = function(request: Types.HttpRequest): Types.HttpResponse
		index += 1
		local step = steps[index]
		assert(step, "Fake backend script exhausted")
		if step.check then
			step.check(request)
		end
		if step.delay then
			runtime.wait(step.delay)
		end
		if step.fail then
			error("Synthetic network failure")
		end
		return { StatusCode = step.status or 200, Body = step.body or "", Headers = step.headers or {} }
	end
	return {
		backend = Fake.batch(runtime, backend),
		count = function(): number
			return index
		end,
		remaining = function(): number
			return math.max(0, #steps - index)
		end,
	}
end
return table.freeze(Fake)
