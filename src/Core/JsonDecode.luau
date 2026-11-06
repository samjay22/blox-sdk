--!strict
local Core = require("../Types/Core")
local Json = require("./Json")
local Decode = {}
--- Decode Fields JSON without dropping present null members or rounding unsafe integer tokens.
function Decode.decode(text: string): Core.Json
	local at = 1
	--- Consume JSON whitespace only (not arbitrary locale whitespace).
	local function space()
		while string.find(" \t\r\n", string.sub(text, at, at), 1, true) and at <= #text do
			at += 1
		end
	end
	--- Parse four hexadecimal digits used by a JSON Unicode escape.
	local function hex(): number
		local digits = string.sub(text, at, at + 3)
		assert(#digits == 4 and string.match(digits, "^%x%x%x%x$"), "Invalid JSON unicode")
		at += 4
		return tonumber(digits, 16) :: number
	end
	--- Decode quoted UTF-8 with surrogate-pair validation and no control characters.
	local function quoted(): string
		assert(string.sub(text, at, at) == '"', "Expected JSON string")
		at += 1
		local parts = {}
		while at <= #text do
			local char = string.sub(text, at, at)
			at += 1
			if char == '"' then
				local value = table.concat(parts)
				assert(utf8.len(value), "Invalid JSON UTF8")
				return value
			end
			if char == "\\" then
				local escaped = string.sub(text, at, at)
				at += 1
				if escaped == "u" then
					local cp = hex()
					if cp >= 0xD800 and cp <= 0xDBFF then
						assert(string.sub(text, at, at + 1) == "\\u", "Missing low surrogate")
						at += 2
						local low = hex()
						assert(low >= 0xDC00 and low <= 0xDFFF, "Invalid low surrogate")
						cp = 0x10000 + (cp - 0xD800) * 0x400 + low - 0xDC00
					else
						assert(cp < 0xD800 or cp > 0xDFFF, "Unpaired surrogate")
					end
					table.insert(parts, utf8.char(cp))
				else
					local escapes = {
						['"'] = '"',
						["\\"] = "\\",
						["/"] = "/",
						b = "\b",
						f = "\f",
						n = "\n",
						r = "\r",
						t = "\t",
					}
					local value = escapes[escaped]
					assert(value, "Invalid JSON escape")
					table.insert(parts, value)
				end
			else
				assert(string.byte(char) >= 32, "Invalid JSON control character")
				table.insert(parts, char)
			end
		end
		error("Unterminated JSON string")
	end
	local parse: (number) -> any
	--- Parse one bounded JSON value, preserving arrays and explicit null identity.
	parse = function(depth: number): any
		assert(depth <= 64, "JSON depth exceeded")
		space()
		local char = string.sub(text, at, at)
		if char == '"' then
			return quoted()
		end
		if char == "{" or char == "[" then
			local list = char == "["
			local out: any = if list then Json.array({}) else Json.object({})
			local seen: { [string]: boolean } = {}
			local finish = if list then "]" else "}"
			at += 1
			space()
			if string.sub(text, at, at) == finish then
				at += 1
				return out
			end
			while true do
				space()
				local key: any = #out + 1
				if not list then
					key = quoted()
					assert(not seen[key], "Duplicate JSON member")
					seen[key] = true
					space()
					assert(string.sub(text, at, at) == ":", "Expected JSON colon")
					at += 1
				end
				out[key] = parse(depth + 1)
				space()
				local nextChar = string.sub(text, at, at)
				at += 1
				if nextChar == finish then
					return out
				end
				assert(nextChar == ",", "Expected JSON comma")
			end
		end
		local tokens: { [string]: Core.Json } = { ["true"] = true, ["false"] = false, ["null"] = Json.null }
		for token, value in tokens do
			if string.sub(text, at, at + #token - 1) == token then
				at += #token
				return value
			end
		end
		local start = at
		if char == "-" then
			at += 1
		end
		local first = string.sub(text, at, at)
		if first == "0" then
			at += 1
		else
			assert(string.match(first, "[1-9]"), "Invalid JSON value")
			repeat
				at += 1
			until not string.match(string.sub(text, at, at), "%d")
		end
		local integral = true
		if string.sub(text, at, at) == "." then
			integral = false
			at += 1
			assert(string.match(string.sub(text, at, at), "%d"), "Invalid JSON fraction")
			repeat
				at += 1
			until not string.match(string.sub(text, at, at), "%d")
		end
		if string.match(string.sub(text, at, at), "[eE]") then
			integral = false
			at += 1
			if string.match(string.sub(text, at, at), "[+-]") then
				at += 1
			end
			assert(string.match(string.sub(text, at, at), "%d"), "Invalid JSON exponent")
			repeat
				at += 1
			until not string.match(string.sub(text, at, at), "%d")
		end
		local value = tonumber(string.sub(text, start, at - 1))
		assert(value and value == value and math.abs(value) < math.huge, "Invalid JSON number")
		if integral then
			assert(math.abs(value) <= 9007199254740991, "Unsafe integer JSON token")
		end
		return value
	end
	local value = parse(0)
	space()
	assert(at > #text, "Trailing JSON input")
	return value
end
return table.freeze(Decode)
