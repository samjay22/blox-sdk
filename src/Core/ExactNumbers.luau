--!strict
local ExactNumbers = {}
--- Fail closed on unsafe integral JSON tokens before an IEEE-754 decoder can silently round them.
function ExactNumbers.check(text: string): string
	local i = 1
	while i <= #text do
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
			local start = i
			i += 1
			while i <= #text and string.match(string.sub(text, i, i), "[%d%.eE%+%-]") do
				i += 1
			end
			local token = string.sub(text, start, i - 1)
			local number = tonumber(token)
			assert(number and number == number and math.abs(number) < math.huge, "Invalid JSON number")
			if not string.find(token, "[%.eE]") then
				assert(math.abs(number) <= 9007199254740991, "Unsafe integer JSON token")
			end
		else
			i += 1
		end
	end
	return text
end
return table.freeze(ExactNumbers)
