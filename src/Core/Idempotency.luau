--!strict
local Core = require("../Types/Core")
local Json = require("./Json")
local Idempotency = {}
local sequence = 0
--- Generate a collision-resistant operation identifier, never a credential.
function Idempotency.key(runtime: Core.Runtime): string
	sequence += 1
	if runtime.guid then
		return runtime.guid()
	end
	local pieces = { tostring(math.floor(runtime.unix())), tostring(sequence) }
	for _ = 1, 4 do
		table.insert(pieces, string.format("%08x", math.floor(runtime.random() * 4294967295)))
	end
	return table.concat(pieces, "-")
end
--- Snapshot JSON input before a yielding request; reject cycles and excessive nesting.
function Idempotency.copy(value: any, depth: number?): any
	if type(value) ~= "table" or value == Json.null then
		return value
	end
	local level = depth or 0
	assert(level < 64, "Request nesting exceeds limit")
	local result = table.clone(value)
	for key, child in value do
		result[key] = Idempotency.copy(child, level + 1)
	end
	return result
end
--- Fill omitted keys on a private request copy once, before any automatic retry.
function Idempotency.prepare(spec: Core.Endpoint, request: Core.Request, runtime: Core.Runtime): Core.Request
	local result: Core.Request = Idempotency.copy(request)
	local field = spec.idempotencyField
	if not field or type(result.body) ~= "table" then
		return result
	end
	local body = result.body :: { [string]: any }
	if spec.idempotencyItems then
		local items = body[spec.idempotencyItems]
		if type(items) == "table" then
			for _, item in items do
				if type(item) == "table" and item[field] == nil then
					item[field] = Idempotency.key(runtime)
				end
			end
		end
	elseif body[field] == nil then
		body[field] = Idempotency.key(runtime)
	end
	return result
end
return table.freeze(Idempotency)
