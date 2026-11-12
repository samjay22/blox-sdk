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
--- Return the universe a facade was created for; every helper reads it from here, never from an argument.
function Universe.bound(value: (string | number)?): string | number
	return assert(
		value,
		"This client has no universe: pass universeId to BloxSDK.new or use client:withUniverse(id)"
	)
end
--- Resolve a Roblox user ID from a number or anything carrying UserId, such as a Player.
function Universe.user(value: unknown): number?
	if type(value) == "number" then
		return value
	end
	local kind: string = typeof(value)
	if kind == "table" or kind == "Instance" then
		local ok, id = pcall(function(): unknown
			return (value :: any).UserId
		end)
		if ok and type(id) == "number" then
			return id
		end
	end
	return nil
end
return table.freeze(Universe)
