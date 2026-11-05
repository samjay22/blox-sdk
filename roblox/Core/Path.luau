--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
--!native
--!optimize 2
local Types = require(script.Parent.Parent.Types.Core)
local Universe = require(script.Parent.Parent.Core.Universe)
local Path = {}
local encoded: { string } = table.create(256)
for i = 0, 255 do
	local c = string.char(i)
	encoded[i + 1] = if string.match(c, "[A-Za-z0-9%-_%.~]") then c else string.format("%%%02X", i)
end
table.freeze(encoded)
--- Encode one UTF-8 byte sequence as an RFC3986 component, not a URL.
function Path.encode(value: string): string
	local parts: { string } = table.create(#value)
	for i = 1, #value do
		parts[i] = encoded[string.byte(value, i) + 1]
	end
	return table.concat(parts)
end
--- Check scalar wire types and avoid imprecise numeric identifiers.
function Path.scalar(value: unknown, kind: string): string?
	if
		type(value) == "string"
		and (kind == "string" or kind == "id")
		and (#value > 0 or kind == "string")
	then
		return value
	end
	if type(value) == "boolean" and kind == "boolean" then
		return tostring(value)
	end
	if
		type(value) == "number"
		and (kind == "number" or kind == "id")
		and value == value
		and math.abs(value) <= 9007199254740991
		and value % 1 == 0
	then
		return tostring(value)
	end
	return nil
end
--- Join precompiled literal/name segments and sorted declared query parameters.
function Path.build(
	spec: Types.Endpoint,
	request: Types.Request,
	universe: (string | number)?
): (string?, string?)
	local values: { [string]: string } = {}
	local path: { [string]: unknown } = request.path or {}
	local query: { [string]: unknown } = request.query or {}
	local groups = { spec.pathParams, spec.queryParams }
	local output: { string } = table.create(#spec.segments + #spec.queryParams * 4)
	for group = 1, 2 do
		local params = groups[group]
		local input: { [string]: unknown } = if group == 1 then path else query
		for name in input do
			local found = false
			for i = 1, #params do
				if params[i].name == name then
					found = true
					break
				end
			end
			if not found then
				return nil, "Unknown path or query parameter"
			end
		end
		for i = 1, #params do
			local param = params[i]
			local value = input[param.name]
			if value == nil and (param.name == "universeId" or param.name == "robloxUniverseId") then
				value = if universe ~= nil and param.type == "string" then tostring(universe) else universe
			end
			if value == nil then
				if param.required then
					return nil, "Missing " .. param.name
				end
			else
				if
					(param.name == "universeId" or param.name == "robloxUniverseId")
					and not Universe.valid(value)
				then
					return nil, "Invalid universeId"
				end
				local scalar = Path.scalar(value, param.type)
				if not scalar or (group == 1 and scalar == "") then
					return nil, "Invalid " .. param.name
				end
				values[tostring(group) .. param.name] = Path.encode(scalar)
			end
		end
	end
	for i = 1, #spec.segments do
		output[#output + 1] = if i % 2 == 1 then spec.segments[i] else values["1" .. spec.segments[i]]
	end
	local separator = "?"
	for i = 1, #spec.queryParams do
		local param = spec.queryParams[i]
		local value = values["2" .. param.name]
		if value then
			output[#output + 1] = separator
			output[#output + 1] = param.name
			output[#output + 1] = "="
			output[#output + 1] = value
			separator = "&"
		end
	end
	return table.concat(output), nil
end
return table.freeze(Path)
