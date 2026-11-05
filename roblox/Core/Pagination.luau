--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Errors = require(script.Parent.Parent.Core.Errors)
local Json = require(script.Parent.Parent.Core.Json)
local Pagination = {}
--- Build a bounded lazy page iterator; preserve failures instead of silently truncating lists.
function Pagination.new<T>(
	fetch: (number) -> Types.Result<T>,
	isLast: (T) -> boolean,
	maximum: number?
): () -> Types.Result<T>?
	local page = 0
	local done = false
	local limit = maximum or 10000
	return function(): Types.Result<T>?
		if done then
			return nil
		end
		if page >= limit then
			done = true
			return Errors.make("Local", "pagination", 0, "Pagination limit reached")
		end
		local result = fetch(page)
		page += 1
		if not result.ok then
			done = true
		else
			done = isLast(result.value)
		end
		return result
	end
end
--- Iterate opaque cursor pages with a finite bound and cycle detection, yielding errors once.
function Pagination.cursor<T>(
	fetch: (string?) -> Types.Result<T>,
	nextCursor: (T) -> (string | Types.Null)?,
	maximum: number?,
	initial: string?
): () -> Types.Result<T>?
	local limit = maximum or 10000
	assert(limit >= 1 and limit <= 1000000 and limit % 1 == 0, "Invalid page limit")
	local cursor = initial
	local seen: { [string]: boolean } = {}
	local count = 0
	local done = false
	return function(): Types.Result<T>?
		if done then
			return nil
		end
		if count >= limit or (cursor ~= nil and seen[cursor]) then
			done = true
			return Errors.make("Local", "pagination", 0, "Cursor cycle or page limit reached")
		end
		if cursor then
			seen[cursor] = true
		end
		local result = fetch(cursor)
		count += 1
		if not result.ok then
			done = true
		else
			local nextValue = nextCursor(result.value)
			done = nextValue == nil or nextValue == Json.null or nextValue == ""
			cursor = if type(nextValue) == "string" then nextValue else nil
		end
		return result
	end
end
return table.freeze(Pagination)
