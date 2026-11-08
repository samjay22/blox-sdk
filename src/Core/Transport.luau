--!strict
local Types = require("../Types/Core")
local Errors = require("./Errors")
local Batcher = require("./Batcher")
local Validation = require("./Validation")
local Schemas = require("./Schemas")
local Transport = {}
--- Enqueue one operation and await its routed result; this layer never performs HTTP.
function Transport.send(
	batcher: Batcher.State,
	path: string,
	headers: Types.Headers,
	body: unknown,
	spec: Types.Endpoint,
	attempt: number,
	deadline: number,
	signal: Types.Signal?,
	lifecycle: Types.Signal,
	auth: Types.AuthProvider,
	priority: string?,
	sequence: string?
): (Types.Result<any>, { [string]: string })
	local runtime = batcher.runtime
	local ok, encoded = pcall(function(): string?
		if body == nil then
			return nil
		end
		local schema = Schemas.endpoints[spec.id]
		return if spec.requestFormat == "ndjson"
			then runtime.encode(body)
			else runtime.encode(body, schema.body, Schemas.definitions[schema.service])
	end)
	if not ok then
		return Errors.make("Network", spec.id, attempt, "Encoding failed"), {}
	end
	if encoded and #encoded > 256 * 1024 then
		return Errors.make("Validation", spec.id, attempt, "Operation body exceeds 256 KiB"), {}
	end
	local admitted, entry = pcall(
		Batcher.enqueue,
		batcher,
		spec,
		path,
		headers,
		encoded,
		priority,
		deadline,
		signal,
		auth,
		sequence
	)
	if not admitted then
		return Errors.make("Network", spec.id, attempt, "Encoding failed"), {}
	end
	if not entry then
		return Errors.make("RateLimited", spec.id, attempt, "Batch queue is full"), {}
	end
	while
		not entry.done
		and runtime.now() < deadline
		and not lifecycle.cancelled
		and not (signal and signal.cancelled)
	do
		runtime.wait(0.01)
	end
	if lifecycle.cancelled or (signal and signal.cancelled) then
		if not entry.sent then
			entry.done = true
		end
		return Errors.make("Cancelled", spec.id, attempt, "Call cancelled"), {}
	end
	if runtime.now() >= deadline then
		if not entry.sent then
			entry.done = true
		end
		return Errors.make("Timeout", spec.id, attempt, "Call deadline exceeded"), {}
	end
	local reply = entry.reply
	if not reply then
		return Errors.make("Network", spec.id, attempt, "Invalid batch response"), {}
	end
	local result: Types.Result<any>
	if (reply.status >= 200 and reply.status < 300) or (spec.conditional and reply.status == 304) then
		if reply.status ~= 304 and not Validation.response(spec.id, reply.body, reply.status) then
			return Errors.make("Network", spec.id, attempt, "Invalid response schema"), reply.headers
		end
		result = { ok = true, value = reply.body, status = reply.status }
	else
		result = Errors.domain(reply.status, spec.id, attempt, reply.body)
	end
	if result.ok and spec.conditional then
		for name, value in reply.headers do
			if string.lower(name) == "etag" then
				result.etag = value
			end
		end
	end
	return result, reply.headers
end
return table.freeze(Transport)
