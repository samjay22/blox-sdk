--!strict
local Core = require("../Types/Core")
local Json = require("../Core/Json")
local System = require("./TypeSystem")
local Bindings = {}
--- Reject arrays, nulls and unknown properties at closed declaration boundaries.
local function object(value: any, keys: { string }): boolean
	if type(value) ~= "table" or value == Json.null or Json.isArray(value) then
		return false
	end
	for key in value do
		if type(key) ~= "string" or not table.find(keys, key) then
			return false
		end
	end
	return true
end
--- Match Java String length/isBlank without treating UTF-8 bytes as characters.
local function text(value: any, maximum: number): boolean
	if type(value) ~= "string" or not utf8.len(value) then
		return false
	end
	local units, nonblank = 0, false
	for _, point in utf8.codes(value) do
		units += if point > 65535 then 2 else 1
		local blank = point >= 9 and point <= 13
			or point >= 28 and point <= 32
			or point == 5760
			or point >= 8192 and point <= 8198
			or point >= 8200 and point <= 8202
			or point == 8232
			or point == 8233
			or point == 8287
			or point == 12288
		nonblank = nonblank or not blank
	end
	return nonblank and units <= maximum
end
--- Optional choices may be absent, never null or coerced from other JSON types.
local function choice(value: any, allowed: { string }): boolean
	return value == nil or type(value) == "string" and table.find(allowed, value) ~= nil
end
--- Validate one binding; DELTA cannot carry keep, even when its value is null.
function Bindings.board(value: unknown): boolean
	local b: any = value
	return object(b, { "board", "submit", "order", "reset", "keep", "displayName" })
		and type(b.board) == "string"
		and #b.board >= 1
		and #b.board <= 64
		and string.match(b.board, "^[A-Za-z0-9_-]+$") ~= nil
		and (b.submit == "VALUE" or b.submit == "DELTA")
		and choice(b.order, { "DESC", "ASC" })
		and choice(b.reset, { "NONE", "DAILY", "WEEKLY", "MONTHLY", "SEASONAL" })
		and choice(b.keep, { "LAST", "BEST" })
		and (b.submit ~= "DELTA" or b.keep == nil)
		and (b.displayName == nil or text(b.displayName, 100))
end
--- Validate declarations and stored-int eligibility, without provisioning or deriving boards.
function Bindings.validate(input: unknown, expression: unknown, computed: boolean): Core.Result<boolean>
	local value: any = input
	if value == nil or value == Json.null then
		return { ok = true, value = true }
	end
	if
		not object(value, { "leaderboards", "audit", "runtime" })
		or not choice(value.audit, { "NONE", "ADMIN_ONLY", "ALL" })
	then
		return System.failure("invalid_definition")
	end
	local boards = value.leaderboards
	if boards ~= nil then
		if type(boards) ~= "table" or boards == Json.null or Json.isObject(boards) or #boards > 32 then
			return System.failure("invalid_definition")
		end
		local count = 0
		for key in boards do
			if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #boards then
				return System.failure("invalid_definition")
			end
			count += 1
		end
		if count ~= #boards then
			return System.failure("invalid_definition")
		end
		if count > 0 then
			local root: any = expression
			if computed or root == nil then
				return System.failure("invalid_definition")
			end
			if type(root) ~= "table" or root.kind ~= "int" then
				return System.failure("leaderboard_requires_int")
			end
		end
		local seen: { [string]: boolean } = {}
		for _, board in boards do
			if not Bindings.board(board) or seen[board.board] then
				return System.failure("invalid_definition")
			end
			seen[board.board] = true
		end
	end
	if value.runtime ~= nil then
		if not object(value.runtime, { "enabledFlag" }) then
			return System.failure("invalid_definition")
		end
		for _, key in value.runtime do
			if not text(key, 200) then
				return System.failure("invalid_definition")
			end
		end
	end
	return { ok = true, value = true }
end
--- Check DTO shape independently of field context so legacy numeric schemas remain readable.
function Bindings.grammar(value: unknown): boolean
	return Bindings.validate(value, { kind = "int" }, false).ok
end
return table.freeze(Bindings)
