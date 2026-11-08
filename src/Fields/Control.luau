--!strict
local Core = require("../Types/Core")
local Types = require("./Types")
local Schema = require("./Schema")
local System = require("./TypeSystem")
local Json = require("../Core/Json")
local Copy = require("../Core/Idempotency")
local Control = {}
--- Check a closed object without traversing untrusted children.
function Control.object(value: any, keys: { string }): boolean
	if type(value) ~= "table" or value == Json.null or Json.isArray(value) then
		return false
	end
	for key in value do
		if not table.find(keys, key) then
			return false
		end
	end
	return true
end
--- Check a bounded dense array, including explicit JSON array/object markers.
function Control.array(value: any, minimum: number, maximum: number): boolean
	if
		type(value) ~= "table"
		or value == Json.null
		or Json.isObject(value)
		or #value < minimum
		or #value > maximum
	then
		return false
	end
	local count = 0
	for key in value do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #value then
			return false
		end
		count += 1
	end
	return count == #value
end
--- Keep numeric IDs exact rather than rounding int64 values on the Lua boundary.
function Control.subject(value: any): boolean
	return type(value) == "number" and value % 1 == 0 and value > 0 and value <= 9007199254740991
end
--- Enforce the administrative reason length after trimming, without echoing its content.
function Control.reason(value: any): boolean
	if type(value) ~= "string" then
		return false
	end
	local trimmed = string.match(value, "^%s*(.-)%s*$") :: string
	local length = utf8.len(trimmed)
	return length ~= nil and length >= 5 and length <= 500
end
--- Validate permanent caller identities before putting them into headers or request bodies.
function Control.key(value: any): boolean
	return type(value) == "string"
		and #value >= 1
		and #value <= 200
		and string.match(value, "^[A-Za-z0-9._-]+$") ~= nil
end
--- Recognize canonical UUIDs locally; resource existence and tenancy remain server checks.
function Control.uuid(value: any): boolean
	if type(value) ~= "string" then
		return false
	end
	local parts = string.split(value, "-")
	if #parts ~= 5 then
		return false
	end
	for i, length in { 8, 4, 4, 4, 12 } do
		if #parts[i] ~= length or not string.match(parts[i], "^%x+$") then
			return false
		end
	end
	return true
end
--- Validate and snapshot the complete bounded predicate tree against the cached schema.
function Control.target(schema: Schema.Schema, target: Types.BulkTarget): Core.Result<Types.BulkTarget>
	if schema:Version() == nil then
		return System.failure("schema_unavailable")
	end
	local leaves = 0
	--- Depth and aggregate leaf budgets bound recursion even for cyclic caller tables.
	local function filter(node: any, depth: number): boolean
		if depth > 4 or not Control.object(node, { "op", "clauses", "clause", "field", "value" }) then
			return false
		end
		if node.op == "AND" or node.op == "OR" then
			if not Control.object(node, { "op", "clauses" }) or not Control.array(node.clauses, 1, 16) then
				return false
			end
			for _, child in node.clauses do
				if not filter(child, depth + 1) then
					return false
				end
			end
			return true
		elseif node.op == "NOT" then
			return Control.object(node, { "op", "clause" }) and filter(node.clause, depth + 1)
		end
		leaves += 1
		if
			leaves > 16
			or not Control.object(node, { "op", "field", "value" })
			or type(node.field) ~= "string"
			or not table.find({ "EQ", "NE", "LT", "LE", "GT", "GE", "IN", "EXISTS" }, node.op)
		then
			return false
		end
		local d = schema:Get(node.field)
		local validator = schema:Validator(node.field)
		if
			not d
			or d.scope ~= "PLAYER"
			or not d.type
			or not validator
			or not table.find({ "int", "number", "bool", "string", "enum" }, d.type.kind)
		then
			return false
		end
		if node.op == "EXISTS" then
			return type(node.value) == "boolean"
		end
		if node.op == "IN" then
			if not Control.array(node.value, 1, 100) then
				return false
			end
			for _, value in node.value do
				if not validator.Validate(value).ok then
					return false
				end
			end
			return true
		end
		return validator.Validate(node.value).ok
	end
	local raw: any = target
	if not Control.object(raw, { "kind", "subjects", "where" }) then
		return System.failure("invalid_request")
	end
	if raw.kind == "ALL" then
		if not Control.object(raw, { "kind" }) then
			return System.failure("invalid_request")
		end
	elseif raw.kind == "SUBJECTS" then
		if not Control.object(raw, { "kind", "subjects" }) or not Control.array(raw.subjects, 1, 100000) then
			return System.failure("invalid_request")
		end
		local seen: { [number]: boolean } = {}
		for _, subject in raw.subjects do
			if not Control.subject(subject) or seen[subject] then
				return System.failure("invalid_request")
			end
			seen[subject] = true
		end
	elseif raw.kind == "WHERE" then
		if not Control.object(raw, { "kind", "where" }) or not filter(raw.where, 1) then
			return System.failure("invalid_request")
		end
	else
		return System.failure("invalid_request")
	end
	return { ok = true, value = Copy.copy(target) }
end
--- Parse UTC ISO instants without platform date libraries; keep nanoseconds separate for ordering.
function Control.instant(value: any): (number?, string?)
	if type(value) ~= "string" then
		return nil, nil
	end
	local y, m, d, h, n, s, tail =
		string.match(value, "^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)(.*)$")
	if not y or not tail then
		return nil, nil
	end
	local fraction = if tail == "Z" then "" else string.match(tail, "^%.(%d+)Z$")
	if fraction == nil or #fraction > 9 then
		return nil, nil
	end
	local year, month, day, hour, minute, second =
		tonumber(y) :: number,
		tonumber(m) :: number,
		tonumber(d) :: number,
		tonumber(h) :: number,
		tonumber(n) :: number,
		tonumber(s) :: number
	if year < 1 or month < 1 or month > 12 or hour > 23 or minute > 59 or second > 59 then
		return nil, nil
	end
	local leap = year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
	local days = { 31, if leap then 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if day < 1 or day > days[month] then
		return nil, nil
	end
	-- Only relative ordering is needed; mixed-radix date components preserve it exactly.
	return (((((year * 13 + month) * 32 + day) * 24 + hour) * 60 + minute) * 60 + second),
		fraction .. string.rep("0", 9 - #fraction)
end
--- Validate one closed Fields-owned runtime action, never arbitrary executable input.
function Control.action(action: Types.ScheduleAction): boolean
	local a: any = action
	if not Control.object(a, { "kind", "key", "type", "value", "bulkDefinitionId" }) then
		return false
	end
	if a.kind == "RUN_BULK" then
		return Control.object(a, { "kind", "bulkDefinitionId" }) and Control.uuid(a.bulkDefinitionId)
	end
	if type(a.key) ~= "string" or #a.key > 100 or not string.match(a.key, "^[A-Za-z0-9_.-]+$") then
		return false
	end
	if a.kind == "ENABLE_FLAG" or a.kind == "DISABLE_FLAG" then
		return Control.object(a, { "kind", "key" })
	end
	if
		a.kind ~= "SET_CONFIG"
		or not Control.object(a, { "kind", "key", "type", "value" })
		or a.value == nil
	then
		return false
	end
	if a.type == "STRING" then
		if type(a.value) ~= "string" then
			return false
		end
	elseif a.type == "NUMBER" then
		if type(a.value) ~= "number" or a.value ~= a.value or math.abs(a.value) == math.huge then
			return false
		end
	elseif a.type == "BOOLEAN" then
		if type(a.value) ~= "boolean" then
			return false
		end
	elseif a.type ~= "JSON" then
		return false
	end
	local ok, encoded = pcall(Json.encode, a.value)
	return ok and #encoded <= 65536
end
return table.freeze(Control)
