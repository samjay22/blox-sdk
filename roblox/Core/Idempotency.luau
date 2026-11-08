--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Json = require(script.Parent.Parent.Core.Json)
local Idempotency = {}
local sequence = 0
--- Validate the owning service's header grammar; Codes uses Java UTF-16 length and ISO controls.
function Idempotency.header(value: unknown, freeform: boolean): boolean
	if type(value) ~= "string" or #value == 0 then
		return false
	end
	if not freeform then
		return #value <= 200 and string.match(value, "^[A-Za-z0-9._-]+$") ~= nil
	end
	if #value > 800 or utf8.len(value) == nil then
		return false
	end
	local length = 0
	local nonblank = false
	for _, cp in utf8.codes(value) do
		if cp <= 31 or (cp >= 127 and cp <= 159) then
			return false
		end
		length += if cp > 65535 then 2 else 1
		local whitespace = cp == 32
			or cp == 5760
			or (cp >= 8192 and cp <= 8198)
			or (cp >= 8200 and cp <= 8202)
			or cp == 8232
			or cp == 8233
			or cp == 8287
			or cp == 12288
		nonblank = nonblank or not whitespace
	end
	return length <= 200 and nonblank
end
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
function Idempotency.prepare(
	spec: Core.Endpoint,
	request: Core.Request,
	runtime: Core.Runtime,
	key: string?
): Core.Request
	local result: Core.Request = Idempotency.copy(request)
	if key ~= nil then
		assert(Idempotency.header(key, spec.id == "codes.bulkCreateCodes"), "Invalid key")
		if spec.idempotencyHeader then
			assert(result.idempotencyKey == nil or result.idempotencyKey == key, "Conflicting key")
			result.idempotencyKey = key
		else
			assert(
				spec.idempotencyField ~= nil and spec.idempotencyItems == nil and type(result.body) == "table",
				"Endpoint does not support a single key"
			)
			local body = result.body :: { [string]: any }
			local field = spec.idempotencyField :: string
			assert(body[field] == nil or body[field] == key, "Conflicting key")
			body[field] = key
		end
	end
	local field = spec.idempotencyField
	if spec.optionalKey or not field or type(result.body) ~= "table" then
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
