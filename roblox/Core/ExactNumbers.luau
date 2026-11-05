--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local ExactNumbers = {}
--- Quote unsafe integer JSON tokens before an IEEE-754 decoder can round ledger balances.
function ExactNumbers.preserve(text: string): string
	local parts: { string } = {}
	local i = 1
	while i <= #text do
		local start = i
		local char = string.sub(text, i, i)
		if char == '"' then
			i += 1
			while i <= #text do
				local c = string.sub(text, i, i)
				i += 1
				if c == "\\" then
					i += 1
				elseif c == '"' then
					break
				end
			end
		elseif string.match(char, "[%d%-]") then
			i += 1
			while i <= #text and string.match(string.sub(text, i, i), "[%d%.eE%+%-]") do
				i += 1
			end
			local token = string.sub(text, start, i - 1)
			local number = tonumber(token)
			if number and math.abs(number) > 9007199254740991 then
				-- The contract uses plain integer smallest units. Never accept rounded exponent forms.
				assert(string.match(token, "^%-?%d+$"), "Unsafe non-integer JSON number")
				table.insert(parts, '"' .. token .. '"')
				continue
			end
		else
			i += 1
		end
		table.insert(parts, string.sub(text, start, i - 1))
	end
	return table.concat(parts)
end
return table.freeze(ExactNumbers)
