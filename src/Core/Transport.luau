--!strict
local Types = require("../Types/Core")
local Errors = require("./Errors")
local Gate = require("./Gate")
local Validation = require("./Validation")
local Schemas = require("./Schemas")
local JsonDecode = require("./JsonDecode")
local Transport = {}
--- Run encode/request/decode inside the sole wire-edge pcall; never surface raw exceptions.
function Transport.send(
	runtime: Types.Runtime,
	backend: Types.Backend,
	gate: Gate.State,
	request: Types.HttpRequest,
	body: unknown,
	spec: Types.Endpoint,
	attempt: number,
	deadline: number,
	signal: Types.Signal?,
	lifecycle: Types.Signal,
	auth: Types.AuthProvider?
): (Types.Result<any>, { [string]: string })
	local finished = false
	local expired = false
	local abandoned = false
	local result: Types.Result<any> = Errors.make("Network", spec.id, attempt, "Transport failed")
	local headers: { [string]: string } = {}
	local timer = runtime.delay(math.max(0, deadline - runtime.now()), function()
		expired = true
	end)
	if signal then
		signal.inFlight = (signal.inFlight or 0) + 1
	end
	runtime.spawn(function()
		local ok, response, decoded = pcall(function(): (Types.HttpResponse, unknown)
			if auth then
				auth.apply(request.Headers)
			end
			if body ~= nil then
				local schema = Schemas.endpoints[spec.id]
				request.Body = if spec.requestFormat == "ndjson"
					then body :: string
					else runtime.encode(body, schema.body, Schemas.definitions[schema.service])
			end
			assert(
				not abandoned
					and not lifecycle.cancelled
					and not (signal and signal.cancelled)
					and runtime.now() < deadline,
				"Call stopped before dispatch"
			)
			local wire = backend(request)
			assert(
				type(wire.StatusCode) == "number"
					and wire.StatusCode % 1 == 0
					and wire.StatusCode >= 100
					and wire.StatusCode <= 599,
				"Invalid HTTP status"
			)
			assert(type(wire.Body) == "string" and type(wire.Headers) == "table", "Invalid HTTP response")
			for name, value in wire.Headers do
				assert(type(name) == "string" and type(value) == "string", "Invalid HTTP headers")
			end
			if abandoned then
				return wire, nil
			end
			local value: unknown = nil
			if
				wire.StatusCode >= 200
				and wire.StatusCode < 300
				and (wire.Body ~= "" or spec.responseFormat == "text")
				and request.Method ~= "HEAD"
			then
				value = if spec.responseFormat == "text" then wire.Body else JsonDecode.decode(wire.Body)
			end
			if wire.StatusCode >= 200 and wire.StatusCode < 300 then
				assert(Validation.response(spec.id, value, wire.StatusCode), "Invalid response schema")
			end
			if wire.StatusCode >= 400 then
				local decodedOk, domain = pcall(runtime.decode, wire.Body)
				if decodedOk then
					value = domain
				end
			end
			return wire, value
		end)
		table.clear(request.Headers)
		request.Body = nil
		-- Slots track native operations, not just waiting callers. Roblox cannot abort HTTP.
		Gate.release(gate)
		if signal then
			signal.inFlight = (signal.inFlight or 1) - 1
		end
		if not abandoned then
			if ok then
				headers = response.Headers
				result = if (response.StatusCode >= 200 and response.StatusCode < 300)
						or (spec.conditional and response.StatusCode == 304)
					then { ok = true, value = decoded, status = response.StatusCode }
					else Errors.domain(response.StatusCode, spec.id, attempt, decoded)
			end
			if result.ok and spec.conditional then
				for name, value in headers do
					if string.lower(name) == "etag" then
						result.etag = value
					end
				end
			end
			finished = true
		end
	end)
	while not finished and not expired and not lifecycle.cancelled and not (signal and signal.cancelled) do
		runtime.wait(0.01)
	end
	if not expired then
		runtime.cancel(timer)
	end
	if lifecycle.cancelled or (signal and signal.cancelled) then
		abandoned = true
		return Errors.make("Cancelled", spec.id, attempt, "Call cancelled"), {}
	end
	if expired or runtime.now() >= deadline then
		abandoned = true
		return Errors.make("Timeout", spec.id, attempt, "Call deadline exceeded"), {}
	end
	return result, headers
end
return table.freeze(Transport)
