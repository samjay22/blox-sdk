--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
-- The stored form of an item list field: lowercase hex of a little-endian byte string. Bit `b` is byte `b // 8`,
-- mask `1 << (b % 8)`; trailing zero bytes are trimmed, so the empty set is "". At most 512 bits (128 characters).
-- Pure helpers; the server stays authoritative for which bit belongs to which member.
local Bitmap = {}
Bitmap.MAX_MEMBERS = 512
local MAX_BYTES = 64
--- True for the canonical stored form: even-length lowercase hex of at most 64 bytes, no trailing zero byte.
function Bitmap.valid(value: unknown): boolean
	if type(value) ~= "string" or #value > MAX_BYTES * 2 or #value % 2 ~= 0 then
		return false
	end
	return string.match(value, "^[0-9a-f]*$") ~= nil and string.sub(value, -2) ~= "00"
end
--- The set bits of a canonical value, ascending; nil when the value is not canonical.
function Bitmap.decode(value: unknown): { number }?
	if not Bitmap.valid(value) then
		return nil
	end
	local text = value :: string
	local bits: { number } = {}
	for index = 1, #text // 2 do
		local byte = tonumber(string.sub(text, index * 2 - 1, index * 2), 16) :: number
		for offset = 0, 7 do
			if bit32.band(byte, bit32.lshift(1, offset)) ~= 0 then
				table.insert(bits, (index - 1) * 8 + offset)
			end
		end
	end
	return bits
end
--- The canonical value of a set of bits (a map `bit -> true`); bits outside 0..511 are ignored by callers.
function Bitmap.encode(bits: { [number]: boolean }): string
	local bytes: { number } = {}
	local last = 0
	for bit in bits do
		local index = bit // 8 + 1
		bytes[index] = bit32.bor(bytes[index] or 0, bit32.lshift(1, bit % 8))
		last = math.max(last, index)
	end
	local out: { string } = {}
	for index = 1, last do
		out[index] = string.format("%02x", bytes[index] or 0)
	end
	return table.concat(out)
end
return table.freeze(Bitmap)
