--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Universe = {}
-- Fixed offset that the backend adds to a universe id to address its dev environment (2^60).
local DEV_OFFSET = "1152921504606846976"
local MAX_SAFE = "9007199254740991"
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
--- Map a dev scope id (universe + 2^60, as a digit string) back to the Roblox universe id.
--- Prod ids and anything that is not a valid dev scope id yield nil; the caller keeps its value.
function Universe.logicalDigits(text: string): string?
	if
		not string.match(text, "^[1-9]%d*$")
		or #text < #DEV_OFFSET
		or (#text == #DEV_OFFSET and text < DEV_OFFSET)
	then
		return nil
	end
	-- Schoolbook subtraction on digit strings, so no precision is lost above 2^53.
	local out: { string } = {}
	local borrow = 0
	for i = 0, #text - 1 do
		local a = string.byte(text, #text - i) - 48 - borrow
		local b = if i < #DEV_OFFSET then string.byte(DEV_OFFSET, #DEV_OFFSET - i) - 48 else 0
		if a < b then
			a += 10
			borrow = 1
		else
			borrow = 0
		end
		out[i + 1] = tostring(a - b)
	end
	local digits = string.match(string.reverse(table.concat(out)), "^0*(%d+)$") :: string
	if digits == "0" or #digits > #MAX_SAFE or (#digits == #MAX_SAFE and digits > MAX_SAFE) then
		return nil
	end
	return digits
end
--- Normalize an id a dev response echoed: dev scope ids become the logical universe id, others are unchanged.
function Universe.logical(value: string | number): string | number
	if type(value) == "number" then
		return value
	end
	local digits = Universe.logicalDigits(value)
	return digits or value
end
--- True when the digit string is a dev scope id (universe + 2^60).
function Universe.isDevScope(value: string): boolean
	return Universe.logicalDigits(value) ~= nil
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
