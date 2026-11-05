--!strict
local Types = require("../Types/Core")
local Json = {}
local null: Types.Null = { __bloxNull = true }
Json.null = table.freeze(null)
local arrayMarker = table.freeze({})
local escapes: { [string]: string } = {
	['"'] = '\\"',
	["\\"] = "\\\\",
	["\b"] = "\\b",
	["\f"] = "\\f",
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
}
--- Escape a single character without changing UTF-8 bytes.
local function escape(char: string): string
	return escapes[char] or string.format("\\u%04x", string.byte(char))
end
--- Mark an otherwise ambiguous empty array; nonempty dense arrays need no marker.
function Json.array<T>(value: { T }): { T }
	return (setmetatable(value, arrayMarker) :: unknown) :: { T }
end
--- Encode JSON exactly once, supporting explicit null PATCH fields and empty arrays.
function Json.encode(value: unknown, schema: Types.Schema?, definitions: { [string]: Types.Schema }?): string
	local seen: { [any]: boolean } = {}
	local parts: { string } = {}
	--- Append one bounded JSON node; reject cycles, metatables, nonfinite values and sparse arrays.
	local function append(node: any, depth: number, shape: Types.Schema?)
		if shape and shape.kind == "ref" and definitions then
			shape = definitions[shape.name :: string]
		end
		if shape and shape.kind == "union" then
			for _, choice in shape.items :: { Types.Schema } do
				if choice.kind == type(node) or (choice.kind == "array" and type(node) == "table") then
					shape = choice
					break
				end
			end
		end
		assert(depth <= 64, "JSON nesting exceeds limit")
		if node == Json.null or node == nil then
			parts[#parts + 1] = "null"
		elseif type(node) == "string" then
			parts[#parts + 1] = '"' .. string.gsub(node, '[%z\1-\31\\"]', escape) .. '"'
		elseif type(node) == "number" then
			assert(node == node and math.abs(node) < math.huge, "Invalid JSON number")
			parts[#parts + 1] = tostring(node)
		elseif type(node) == "boolean" then
			parts[#parts + 1] = tostring(node)
		elseif type(node) == "table" then
			assert(not seen[node], "Cyclic JSON")
			assert(getmetatable(node) == nil or getmetatable(node) == arrayMarker, "Invalid JSON object")
			seen[node] = true
			local array = (shape ~= nil and shape.kind == "array")
				or #node > 0
				or getmetatable(node) == arrayMarker
			parts[#parts + 1] = if array then "[" else "{"
			local count = 0
			if array then
				for key in node do
					assert(
						type(key) == "number" and key >= 1 and key <= #node and key % 1 == 0,
						"Invalid JSON array"
					)
					count += 1
				end
				assert(count == #node, "Sparse JSON array")
				for i = 1, #node do
					if i > 1 then
						parts[#parts + 1] = ","
					end
					append(node[i], depth + 1, if shape then shape.item else nil)
				end
			else
				local keys: { string } = {}
				for key in node do
					assert(type(key) == "string", "Invalid JSON key")
					keys[#keys + 1] = key
				end
				table.sort(keys)
				for i = 1, #keys do
					if i > 1 then
						parts[#parts + 1] = ","
					end
					append(keys[i], depth + 1, nil)
					parts[#parts + 1] = ":"
					local field = if shape and shape.fields then shape.fields[keys[i]] else nil
					append(
						node[keys[i]],
						depth + 1,
						if field then field.schema elseif shape then shape.item else nil
					)
				end
			end
			parts[#parts + 1] = if array then "]" else "}"
			seen[node] = nil
		else
			error("Invalid JSON value")
		end
	end
	append(value, 0, schema)
	return table.concat(parts)
end
return table.freeze(Json)
