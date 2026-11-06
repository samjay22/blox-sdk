--!strict
-- Bounded, full-string matcher for the server's single-quantifier safe pattern subset.
local Pattern = {}
type Predicate = (number) -> boolean
type Atom = { matches: Predicate, minimum: number, maximum: number }
--- Split valid UTF-8 into scalar values without losing astral characters.
local function points(text: string): { number }
	local result = {}
	for _, cp in utf8.codes(text) do
		table.insert(result, cp)
	end
	return result
end
--- Match Java's default ASCII shorthand character classes.
local function shorthand(cp: number, code: number): boolean
	local lower = string.lower(string.char(code))
	local yes = if lower == "d"
		then cp >= 48 and cp <= 57
		elseif lower == "w" then cp >= 48 and cp <= 57
			or cp >= 65 and cp <= 90
			or cp >= 97 and cp <= 122
			or cp == 95
		else cp == 32 or cp >= 9 and cp <= 13
	return if code >= 65 and code <= 90 then not yes else yes
end
--- Compile supported safe atoms; invalid/unsupported patterns fail closed at schema load.
function Pattern.compile(pattern: string): (string) -> boolean
	local chars = points(pattern)
	assert(#chars <= 200, "invalid_definition")
	local at, quantifiers = 1, 0
	--- Consume a literal or shorthand escape.
	local function unit(): (Predicate, number?)
		local cp = chars[at]
		assert(cp, "invalid_definition")
		at += 1
		if cp == 92 then
			cp = chars[at]
			assert(cp, "invalid_definition")
			at += 1
			if string.find("dDwWsS", string.char(math.min(cp, 255)), 1, true) then
				local code = cp
				return function(v)
					return shorthand(v, code)
				end, nil
			end
			local escapes = { [110] = 10, [114] = 13, [116] = 9, [102] = 12 }
			if cp == 117 or cp == 120 then
				local size = if cp == 117 then 4 else 2
				local digits = ""
				for _ = 1, size do
					digits ..= string.char(chars[at] or 0)
					at += 1
				end
				cp = tonumber(digits, 16) :: number
				assert(cp, "invalid_definition")
			elseif escapes[cp] then
				cp = escapes[cp]
			else
				assert(
					not (cp >= 48 and cp <= 57 or cp >= 65 and cp <= 90 or cp >= 97 and cp <= 122),
					"invalid_definition"
				)
			end
		end
		local literal = cp
		return function(v)
			return v == literal
		end, literal
	end
	local atoms: { Atom } = {}
	if chars[at] == 94 then
		at += 1
	end
	while at <= #chars do
		if chars[at] == 36 and at == #chars then
			break
		end
		local predicate: Predicate
		if chars[at] == 91 then
			at += 1
			local negate = chars[at] == 94
			if negate then
				at += 1
			end
			local choices: { Predicate } = {}
			while chars[at] and chars[at] ~= 93 do
				local fn, low = unit()
				if chars[at] == 45 and chars[at + 1] ~= 93 then
					at += 1
					local _, high = unit()
					assert(low and high and low <= high, "invalid_definition")
					local a, b = low :: number, high :: number
					fn = function(v)
						return v >= a and v <= b
					end
				end
				table.insert(choices, fn)
			end
			assert(chars[at] == 93 and #choices > 0, "invalid_definition")
			at += 1
			predicate = function(v)
				local yes = false
				for _, fn in choices do
					if fn(v) then
						yes = true
						break
					end
				end
				return if negate then not yes else yes
			end
		elseif chars[at] == 46 then
			at += 1
			predicate = function(v)
				return v ~= 10 and v ~= 13 and v ~= 133 and v ~= 8232 and v ~= 8233
			end
		else
			assert(
				not table.find({ 40, 41, 124, 123, 125, 42, 43, 63, 94, 36, 93 }, chars[at]),
				"invalid_definition"
			)
			predicate = (unit())
		end
		local minimum, maximum = 1, 1
		if chars[at] == 42 or chars[at] == 43 or chars[at] == 63 then
			quantifiers += 1
			assert(quantifiers <= 1, "invalid_definition")
			minimum = if chars[at] == 43 then 1 else 0
			maximum = if chars[at] == 63 then 1 else 4096
			at += 1
		end
		table.insert(atoms, { matches = predicate, minimum = minimum, maximum = maximum })
	end
	return function(value: string): boolean
		local input = points(value)
		local fixed = 0
		for _, atom in atoms do
			if atom.minimum == atom.maximum then
				fixed += 1
			end
		end
		local offset = 1
		for _, atom in atoms do
			local count = if atom.minimum == atom.maximum then 1 else #input - fixed
			if count < atom.minimum or count > atom.maximum then
				return false
			end
			for _ = 1, count do
				if not input[offset] or not atom.matches(input[offset]) then
					return false
				end
				offset += 1
			end
		end
		return offset == #input + 1
	end
end
return table.freeze(Pattern)
