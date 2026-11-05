--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Universe = {}
--- Accept positive exact integers; digit strings also support Java's signed 64-bit IDs.
function Universe.valid(value: unknown): boolean
	if type(value) == "number" then
		return value > 0 and value <= 9007199254740991 and value % 1 == 0
	end
	if type(value) ~= "string" or not string.match(value, "^[1-9]%d*$") then
		return false
	end
	return #value < 19 or (#value == 19 and value <= "9223372036854775807")
end
return table.freeze(Universe)
