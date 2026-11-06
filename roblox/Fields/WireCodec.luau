--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Types = require(script.Parent.Parent.Fields.Types)
local Json = require(script.Parent.Parent.Core.Json)
local Codec = {}
--- Convert domain sets/int-key maps recursively; explicit null remains a sentinel, not absent nil.
local function convert(t: any, value: any, toWire: boolean): any
	if t.kind == "nullable" then
		return if value == Json.null then Json.null else convert(t.of, value, toWire)
	end
	if t.kind == "set" then
		local out: any = if toWire then Json.array({}) else {}
		if toWire then
			for item, present in value do
				assert(present == true, "Invalid domain set")
				table.insert(out, item)
			end
		else
			for _, item in value do
				out[item] = true
			end
		end
		return out
	elseif t.kind == "list" then
		local out = Json.array({})
		for _, item in value do
			table.insert(out, convert(t.item, item, toWire))
		end
		return out
	elseif t.kind == "map" then
		local out = {}
		for key, item in value do
			local target = key
			if t.key.kind == "int" then
				if toWire then
					assert(
						type(key) == "number" and key % 1 == 0 and math.abs(key) <= 9007199254740991,
						"Invalid domain int key"
					)
					target = string.format("%.0f", key)
				else
					target = tonumber(key)
					assert(target and math.abs(target) <= 9007199254740991, "Unsafe integer map key")
				end
			end
			out[target] = convert(t.value, item, toWire)
		end
		return out
	elseif t.kind == "object" then
		local out = {}
		for key, item in value do
			local member = t.members[key]
			assert(member, "unknown_member")
			out[key] = convert(member.type, item, toWire)
		end
		return out
	end
	return value
end
--- Convert an integer domain key without ever rounding fractional or unsafe values into a valid key.
function Codec.key(value: number): string
	if value % 1 == 0 and math.abs(value) <= 9007199254740991 then
		return string.format("%.0f", value)
	end
	return tostring(value)
end
--- Decode validated wire values into schema-generated client-domain types.
function Codec.decode(t: Types.TypeExpr, value: Core.Json): any
	return convert(t, value, false)
end
--- Convert domain containers; the transaction builder returns typed validation errors at Commit.
function Codec.encode(t: Types.TypeExpr, value: unknown): Core.Json
	return convert(t, value, true)
end
return table.freeze(Codec)
