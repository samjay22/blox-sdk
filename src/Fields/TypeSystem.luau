--!strict
local Core = require("../Types/Core")
local Types = require("./Types")
local Json = require("../Core/Json")
local Cache = require("../Core/Cache")
local Copy = require("../Core/Idempotency")
local Pattern = require("./Pattern")
local Bitmap = require("./Bitmap")
local System = {}
export type TypeExpr = Types.TypeExpr
export type Validator = {
	type: TypeExpr,
	validate: (unknown) -> Core.Result<Core.Json>,
	default: (Core.Json?) -> Core.Result<Core.Json>,
}
local SAFE = 9007199254740991
--- Raise only a machine code; no input values or credentials enter errors.
local function fail(code: string): never
	error(code, 0)
end
--- Raise a machine code with the member names (at most 20) or limit that explain it.
local function failMembers(code: string, members: { string }?, maxMembers: number?): never
	local listed: { string }? = nil
	if members then
		listed = {}
		for index, name in members do
			if index > 20 then
				break
			end
			table.insert(listed :: { string }, name)
		end
	end
	error({ code = code, members = listed, maxMembers = maxMembers }, 0)
end
--- Return a typed validation error with the original operation path (server convention).
function System.failure(code: string, path: Types.Path?, field: string?, opIndex: number?): Core.Result<any>
	local unavailable = code == "enum_source_unavailable"
	return {
		ok = false,
		error = {
			kind = if unavailable then "Server" else "Validation",
			message = code,
			code = code,
			status = if unavailable
				then 503
				elseif code == "invalid_definition" or code == "invalid_request" then 400
				else 422,
			endpoint = "fields",
			attempts = 0,
			path = path or {},
			field = field,
			opIndex = opIndex,
		},
	}
end
--- Protect pure validation; unexpected malformed Lua structures also fail closed.
local function protect(callback: () -> any, path: Types.Path?): Core.Result<any>
	local ok, value = pcall(callback)
	if ok then
		return { ok = true, value = value }
	end
	if type(value) == "table" and type(value.code) == "string" then
		local result = System.failure(value.code, path)
		if not result.ok then
			result.error.members = value.members
			result.error.maxMembers = value.maxMembers
		end
		return result
	end
	local code = if type(value) == "string" and string.match(value, "^[a-z][a-z0-9_]+$")
		then value
		else "wrong_type"
	return System.failure(code, path)
end
--- Distinguish dense wire arrays from objects, allowing an unmarked empty caller table.
local function array(value: any): boolean
	if type(value) ~= "table" or value == Json.null or Json.isObject(value) then
		return false
	end
	local count = 0
	for k in value do
		if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or k > #value then
			return false
		end
		count += 1
	end
	return count == #value
end
--- Reject arrays where a closed JSON object is required.
local function object(value: any): boolean
	if type(value) ~= "table" or value == Json.null or Json.isArray(value) then
		return false
	end
	for key in value do
		if type(key) ~= "string" then
			return false
		end
	end
	return true
end
--- Validate numeric representation before arithmetic; never silently round int64 values.
local function numeric(t: any, v: any)
	if v == nil then
		fail("missing_value")
	end
	if type(v) ~= "number" or t.kind == "int" and v % 1 ~= 0 then
		fail("wrong_type")
	end
	if t.kind == "int" and (v < -9223372036854775808 or v >= 9223372036854775808) then
		fail("int64_overflow")
	end
	if v ~= v or math.abs(v) == math.huge then
		fail("non_finite_number")
	end
	if t.kind == "int" and math.abs(v) > SAFE then
		fail("unsafe_integer")
	end
end
local check: (any, any, number) -> any
--- Validate canonical decimal map keys and their declared scalar constraints.
local function mapKey(t: any, key: any)
	if type(key) ~= "string" then
		fail("invalid_map_key")
	end
	if t.kind == "int" then
		if key ~= "0" and not string.match(key, "^%-?[1-9]%d*$") then
			fail("invalid_map_key")
		end
		local negative = string.sub(key, 1, 1) == "-"
		local digits = if negative then string.sub(key, 2) else key
		local limit = if negative then "9223372036854775808" else "9223372036854775807"
		if #digits > 19 or #digits == 19 and digits > limit then
			fail("int64_overflow")
		end
		-- Keys stay strings on the wire, but constraints must never compare rounded integers.
		local n = tonumber(key)
		if n == nil or math.abs(n) > SAFE then
			fail("unsafe_integer")
		end
		check(t, n, 1)
	else
		check(t, key, 1)
	end
end
--- Enforce collection bounds after canonicalization/pruning.
local function size(t: any, n: number)
	if n < (t.minSize or 0) then
		fail("below_min_size")
	end
	if n > (t.maxSize or 1000) then
		fail("above_max_size")
	end
end
--- Validate a recursively typed value, copying and canonicalizing without mutating the caller.
check = function(t: any, v: any, depth: number): any
	if depth > 64 then
		fail("value_too_large")
	end
	if v == nil then
		fail("missing_value")
	end
	local k = t.kind
	if k == "int" or k == "number" then
		numeric(t, v)
		if t.min ~= nil and v < t.min then
			fail("below_min")
		end
		if t.max ~= nil and v > t.max then
			fail("above_max")
		end
		return if v == 0 then 0 else v
	elseif k == "bool" then
		if type(v) ~= "boolean" then
			fail("wrong_type")
		end
		return v
	elseif k == "string" then
		if type(v) ~= "string" then
			fail("wrong_type")
		end
		local length = utf8.len(v)
		if not length then
			fail("wrong_type")
		end
		if length < (t.minLength or 0) then
			fail("below_min_length")
		end
		if length > (t.maxLength or 256) then
			fail("above_max_length")
		end
		if t.pattern then
			local units = 0
			for _, cp in utf8.codes(v) do
				units += if cp > 65535 then 2 else 1
			end
			if units > 4096 then
				fail("pattern_input_too_long")
			end
			if not Pattern.compile(t.pattern)(v) then
				fail("pattern_mismatch")
			end
		end
		return v
	elseif k == "enum" then
		if type(v) ~= "string" then
			fail("wrong_type")
		end
		if not table.find(t.values, v) then
			fail("invalid_enum")
		end
		return v
	elseif k == "nullable" then
		return if v == Json.null then Json.null else check(t.of, v, depth + 1)
	elseif k == "bitmap" then
		if type(v) ~= "string" then
			fail("wrong_type")
		end
		local bits = Bitmap.decode(v)
		if not bits then
			fail("invalid_bitmap")
		end
		local limit = t.maxMembers or Bitmap.MAX_MEMBERS
		if #(bits :: { number }) > limit then
			failMembers("member_limit", nil, limit)
		end
		return v
	elseif k == "object" then
		if not object(v) then
			fail("wrong_type")
		end
		for name in v do
			if not t.members[name] then
				fail("unknown_member")
			end
		end
		local out = {}
		for name, m in t.members do
			if v[name] ~= nil then
				out[name] = check(m.type, v[name], depth + 1)
			elseif m.default ~= nil then
				out[name] = check(m.type, m.default, depth + 1)
			elseif not m.optional then
				fail("missing_member")
			end
		end
		return out
	elseif k == "list" or k == "set" then
		if not array(v) then
			fail("wrong_type")
		end
		local out = Json.array({})
		local seen: { [string]: boolean } = {}
		for _, child in v do
			local value = check(t.item, child, depth + 1)
			if k == "set" then
				local key = Json.encode(value)
				if seen[key] then
					fail("duplicate_element")
				end
				seen[key] = true
			end
			table.insert(out, value)
		end
		if k == "set" then
			table.sort(out)
		end
		size(t, #out)
		return out
	elseif k == "map" then
		if not object(v) then
			fail("wrong_type")
		end
		local out = {}
		local count = 0
		for key, child in v do
			mapKey(t.key, key)
			local value = check(t.value, child, depth + 1)
			if not (t.pruneZero and value == 0) then
				out[key] = value
				count += 1
			end
		end
		size(t, count)
		return out
	end
	return fail("invalid_definition")
end
--- Apply the canonical UTF-8 field storage cap after recursive validation.
local function validate(t: any, v: any): any
	local value = check(t, v, 1)
	if #Json.encode(value) > 262144 then
		fail("value_too_large")
	end
	return value
end
--- Synthesize natural defaults; unlike SET, required object members get natural zeros.
local function natural(t: any): any
	local k = t.kind
	if k == "int" then
		return math.max(t.min or -SAFE, math.min(0, t.max or SAFE))
	end
	if k == "number" then
		return 0
	end
	if k == "bool" then
		return false
	end
	if k == "string" then
		return ""
	end
	if k == "nullable" then
		return Json.null
	end
	if k == "bitmap" then
		return ""
	end
	if k == "list" or k == "set" then
		return Json.array({})
	end
	if k == "map" then
		return {}
	end
	if k == "object" then
		local out = {}
		for name, m in t.members do
			if m.default ~= nil then
				out[name] = m.default
			elseif not m.optional then
				out[name] = natural(m.type)
			end
		end
		return out
	end
	return fail("default_required")
end
--- Reject unknown metadata/operation properties rather than silently ignoring typos.
local function only(t: any, names: { string }, code: string)
	if not object(t) then
		fail(code)
	end
	for name in t do
		if not table.find(names, name) then
			fail(code)
		end
	end
end
--- Check bounded, finite metadata cardinalities.
local function bounds(t: any, low: string, high: string, fallback: number, hard: number)
	for _, key in { low, high } do
		local value = t[key]
		if
			value ~= nil and (type(value) ~= "number" or value % 1 ~= 0 or value < 0 or value > 2147483647)
		then
			fail("invalid_definition")
		end
	end
	if (t[high] or fallback) > hard or (t[low] or 0) > (t[high] or fallback) then
		fail("invalid_definition")
	end
end
--- Parse the closed TypeExpr grammar with depth/member/size limits.
local function compile(t: any, depth: number)
	if not object(t) or depth > 8 then
		fail("invalid_definition")
	end
	local k = t.kind
	if k == "int" or k == "number" then
		only(t, { "kind", "min", "max", "maxDelta" }, "invalid_definition")
		for _, key in { "min", "max", "maxDelta" } do
			if t[key] ~= nil then
				numeric(t, t[key])
			end
		end
		if t.min ~= nil and t.max ~= nil and t.min > t.max or t.maxDelta ~= nil and t.maxDelta < 0 then
			fail("invalid_definition")
		end
	elseif k == "bool" then
		only(t, { "kind" }, "invalid_definition")
	elseif k == "string" then
		only(t, { "kind", "minLength", "maxLength", "pattern" }, "invalid_definition")
		bounds(t, "minLength", "maxLength", 256, 65536)
		if t.pattern ~= nil then
			if type(t.pattern) ~= "string" then
				fail("invalid_definition")
			end
			Pattern.compile(t.pattern)
		end
	elseif k == "enum" then
		only(t, { "kind", "values" }, "invalid_definition")
		if not array(t.values) or #t.values < 1 or #t.values > 256 then
			fail("invalid_definition")
		end
		local seen = {}
		for _, v in t.values do
			if type(v) ~= "string" or seen[v] then
				fail("invalid_definition")
			end
			seen[v] = true
		end
	elseif k == "object" then
		only(t, { "kind", "members" }, "invalid_definition")
		if not object(t.members) then
			fail("invalid_definition")
		end
		local count = 0
		for name, m in t.members do
			count += 1
			if not string.match(name, "^[A-Za-z][A-Za-z0-9_]*$") then
				fail("invalid_definition")
			end
			only(m, { "type", "default", "optional" }, "invalid_definition")
			if m.optional ~= nil and type(m.optional) ~= "boolean" then
				fail("invalid_definition")
			end
			compile(m.type, depth + 1)
			if m.default ~= nil then
				validate(m.type, m.default)
			end
		end
		if count > 64 then
			fail("invalid_definition")
		end
	elseif k == "list" or k == "set" then
		only(
			t,
			if k == "list" then { "kind", "item", "minSize", "maxSize" } else { "kind", "item", "maxSize" },
			"invalid_definition"
		)
		bounds(t, "minSize", "maxSize", 1000, 10000)
		compile(t.item, depth + 1)
		if k == "set" and not table.find({ "int", "string", "enum" }, t.item.kind) then
			fail("invalid_definition")
		end
	elseif k == "map" then
		only(t, { "kind", "key", "value", "maxSize", "pruneZero" }, "invalid_definition")
		bounds(t, "minSize", "maxSize", 1000, 10000)
		compile(t.key, depth + 1)
		compile(t.value, depth + 1)
		if
			not table.find({ "int", "string", "enum" }, t.key.kind)
			or t.pruneZero ~= nil and type(t.pruneZero) ~= "boolean"
			or t.pruneZero and not table.find({ "int", "number" }, t.value.kind)
		then
			fail("invalid_definition")
		end
	elseif k == "nullable" then
		only(t, { "kind", "of" }, "invalid_definition")
		compile(t.of, depth + 1)
	elseif k == "bitmap" then
		-- An item list field is a whole field: never nested in a container or a nullable.
		only(t, { "kind", "source", "maxMembers" }, "invalid_definition")
		if
			depth > 1
			or type(t.source) ~= "string"
			or #t.source > 64
			or not string.match(t.source, "^[A-Za-z0-9][A-Za-z0-9_%-]*$")
		then
			fail("invalid_definition")
		end
		local limit = t.maxMembers
		if
			limit ~= nil
			and (type(limit) ~= "number" or limit % 1 ~= 0 or limit < 1 or limit > Bitmap.MAX_MEMBERS)
		then
			fail("invalid_definition")
		end
	else
		fail("invalid_definition")
	end
end
--- Compile and freeze a validated schema; callers cannot alter a cached validator's rules.
function System.compile(expression: unknown): Core.Result<Validator>
	local parsed = protect(function()
		if #Json.encode(expression) > 65536 then
			fail("invalid_definition")
		end
		compile(expression, 1)
		return Cache.freeze(Copy.copy(expression))
	end, nil)
	if not parsed.ok then
		return System.failure("invalid_definition")
	end
	local t = parsed.value
	return {
		ok = true,
		value = {
			type = t,
			validate = function(v)
				return protect(function()
					return validate(t, v)
				end, nil)
			end,
			default = function(explicit)
				return System.default(t, explicit)
			end,
		},
	}
end
--- Validate a value against a TypeExpr; schema compilation is explicit for hot-path callers.
function System.validate(t: TypeExpr, value: unknown): Core.Result<Core.Json>
	return protect(function()
		return validate(t, value)
	end, nil)
end
--- Synthesize or validate a default, returning default_required for unusable natural values.
function System.default(t: TypeExpr, explicit: Core.Json?): Core.Result<Core.Json>
	local result = protect(function()
		return validate(t, if explicit ~= nil then explicit else natural(t))
	end, nil)
	return if result.ok then result else System.failure("invalid_definition")
end
--- Navigate types and optional values; paths are always wire zero-based indices.
local function target(t: any, v: any, default: any, path: Types.Path, static: boolean?): (any, any, any)
	if not array(path) or #path > 8 then
		fail("invalid_path")
	end
	for _, part in path do
		if t.kind == "nullable" then
			if not static and (v == nil or v == Json.null) then
				fail("null_path")
			end
			t = t.of
		end
		local key: any = part
		if t.kind == "object" then
			if type(part) ~= "string" or not t.members[part] then
				fail("unknown_member")
			end
			local member = t.members[part]
			t = member.type
			default = if type(default) == "table" and default ~= Json.null then default[key] else nil
			if default == nil then
				default = member.default
			end
		elseif t.kind == "map" then
			if type(part) ~= "string" then
				fail(if static then "invalid_map_key" else "invalid_path")
			end
			mapKey(t.key, part)
			t = t.value
			default = if type(default) == "table" and default ~= Json.null then default[key] else nil
		elseif t.kind == "list" then
			if type(part) ~= "number" or part % 1 ~= 0 or part < 0 or part > 2147483647 then
				fail(if static then "invalid_index" else "invalid_path")
			end
			if static and (part :: number) >= (t.maxSize or 1000) then
				fail("not_found")
			end
			key = (part :: number) + 1
			t = t.item
			default = if type(default) == "table" then default[key] else nil
		else
			fail("invalid_path")
		end
		v = if type(v) == "table" and v ~= Json.null then v[key] else nil
	end
	return t, v, default
end
--- Resolve the declared target type without assuming current player state.
function System.targetType(t: TypeExpr, path: Types.Path?): Core.Result<TypeExpr>
	return protect(function()
		return (target(t, nil, nil, path or {}, true))
	end, path)
end
--- Resolve RESET's field-path/member/natural default without inventing a current player value.
function System.resetDefault(t: TypeExpr, default: Core.Json?, path: Types.Path?): Core.Result<Core.Json>
	return protect(function()
		local root = System.default(t, default)
		if not root.ok then
			fail("default_required")
		end
		local sub, _, selected = target(
			t,
			if root.ok then root.value else nil,
			if root.ok then root.value else nil,
			path or {},
			true
		)
		local result = System.default(sub, selected)
		if not result.ok then
			fail("default_required")
		end
		return if result.ok then result.value else nil
	end, path)
end
--- Check numeric deltas independent of the player's balance.
local function delta(t: any, v: any)
	numeric(t, v)
	if v == 0 then
		fail("zero_delta")
	end
	if t.maxDelta ~= nil and math.abs(v) > t.maxDelta then
		fail("max_delta_exceeded")
	end
end
--- The distinct member names of a GRANT/REVOKE/REPLACE argument. Shape only: whether they exist is a lookup.
local function memberNames(value: any, op: string): { string }
	if not array(value) then
		fail("wrong_type")
	end
	if op ~= "REPLACE" and #value == 0 then
		fail("below_min_size")
	end
	if #value > Bitmap.MAX_MEMBERS then
		fail("above_max_size")
	end
	local seen: { [string]: boolean } = {}
	local names: { string } = {}
	for _, name in value do
		if
			type(name) ~= "string"
			or #name > 100
			or not string.match(name, "^[A-Za-z0-9_][A-Za-z0-9_%.%-]*$")
		then
			fail("invalid_member_name")
		end
		if not seen[name] then
			seen[name] = true
			table.insert(names, name)
		end
	end
	return names
end
--- Check an exact nonnegative Java int list index.
local function index(v: any)
	if type(v) ~= "number" or v % 1 ~= 0 or v < 0 or v > 2147483647 then
		fail("invalid_index")
	end
end
local arguments = {
	SET = { "value" },
	RESET = {},
	ADD = { "delta" },
	MIN = { "value" },
	MAX = { "value" },
	APPEND = { "items" },
	INSERT = { "index", "items" },
	REMOVE_AT = { "index", "count" },
	REMOVE_VALUE = { "value" },
	SET_ADD = { "items" },
	SET_REMOVE = { "items" },
	GRANT = { "members" },
	REVOKE = { "members" },
	REPLACE = { "members" },
	MAP_PUT = { "entries" },
	MAP_REMOVE = { "keys" },
	MAP_ADD = { "key", "delta" },
}
--- Validate every statically knowable operation constraint, without a fictitious default balance.
local function operation(t: any, op: string, a: any, static: boolean?)
	local allowed = arguments[op]
	if not allowed then
		fail("op_not_applicable")
	end
	only(a, allowed, "invalid_request")
	if op == "SET" then
		validate(t, a.value)
		return
	end
	if op == "RESET" then
		return
	end
	local k = t.kind
	if op == "ADD" or op == "MIN" or op == "MAX" then
		if k ~= "int" and k ~= "number" then
			fail("op_not_applicable")
		end
		if op == "ADD" then
			if static and a.delta == nil then
				fail("wrong_type")
			end
			delta(t, a.delta)
		else
			numeric(t, a.value)
			if op == "MIN" and t.min ~= nil and a.value < t.min then
				fail("below_min")
			end
			if op == "MAX" and t.max ~= nil and a.value > t.max then
				fail("above_max")
			end
		end
	elseif op == "APPEND" or op == "INSERT" or op == "REMOVE_AT" or op == "REMOVE_VALUE" then
		if k ~= "list" then
			fail("op_not_applicable")
		end
		if op == "APPEND" or op == "INSERT" then
			if not array(a.items) then
				fail("wrong_type")
			end
			for _, v in a.items do
				validate(t.item, v)
			end
			if op == "INSERT" then
				index(a.index)
				if a.index > (t.maxSize or 1000) then
					fail("not_found")
				end
			end
			if
				static
				and math.max(if op == "INSERT" then a.index else 0, t.minSize or 0) + #a.items
					> (t.maxSize or 1000)
			then
				fail("above_max_size")
			end
		elseif op == "REMOVE_AT" then
			index(a.index)
			if a.count ~= nil then
				index(a.count)
			end
			if a.index + (a.count or 1) > (t.maxSize or 1000) then
				fail("not_found")
			end
			if a.count == 0 then
				fail(if static then "invalid_index" else "not_found")
			end
		else
			validate(t.item, a.value)
		end
	elseif op == "GRANT" or op == "REVOKE" or op == "REPLACE" then
		if k ~= "bitmap" then
			fail("op_not_applicable")
		end
		memberNames(a.members, op)
	elseif op == "SET_ADD" or op == "SET_REMOVE" then
		if k ~= "set" then
			fail("op_not_applicable")
		end
		if not array(a.items) then
			fail("wrong_type")
		end
		local distinct: { [string]: boolean } = {}
		local count = 0
		for _, v in a.items do
			local canonical = validate(t.item, v)
			local key = Json.encode(canonical)
			if not distinct[key] then
				distinct[key] = true
				count += 1
			end
		end
		if op == "SET_ADD" and count > (t.maxSize or 1000) then
			fail("above_max_size")
		end
	else
		if k ~= "map" then
			fail("op_not_applicable")
		end
		if op == "MAP_PUT" then
			if not object(a.entries) then
				fail("wrong_type")
			end
			validate(t, a.entries)
		elseif op == "MAP_REMOVE" then
			if not array(a.keys) then
				fail("wrong_type")
			end
			for _, key in a.keys do
				mapKey(t.key, key)
			end
		else
			if static then
				mapKey(t.key, a.key)
			end
			if t.value.kind ~= "int" and t.value.kind ~= "number" then
				fail("op_not_applicable")
			end
			mapKey(t.key, a.key)
			if static and a.delta == nil then
				fail("wrong_type")
			end
			delta(t.value, a.delta)
		end
	end
end
--- Validate an op against a cached field schema; state-dependent constraints remain server-authoritative.
function System.checkOperation(
	t: TypeExpr,
	op: string,
	args: { [string]: any },
	path: Types.Path?
): Core.Result<boolean>
	return protect(function()
		local sub = target(t, nil, nil, path or {}, true)
		operation(sub, op, args, true)
		return true
	end, path)
end
--- Canonicalize checked operation operands so empty arrays and object defaults have correct wire shapes.
function System.prepareOperation(
	t: TypeExpr,
	op: string,
	args: { [string]: any },
	path: Types.Path?
): Core.Result<{ [string]: any }>
	return protect(function()
		local sub = target(t, nil, nil, path or {}, true)
		operation(sub, op, args, true)
		local out = Copy.copy(args)
		if op == "SET" then
			out.value = validate(sub, args.value)
		elseif op == "REMOVE_VALUE" then
			out.value = validate(sub.item, args.value)
		elseif args.items ~= nil then
			out.items = Json.array({})
			for _, value in args.items do
				table.insert(out.items, validate(sub.item, value))
			end
		elseif op == "MAP_PUT" then
			out.entries = {}
			for key, value in args.entries do
				out.entries[key] = validate(sub.value, value)
			end
		elseif op == "MAP_REMOVE" then
			out.keys = Json.array(table.clone(args.keys))
		elseif args.members ~= nil then
			out.members = Json.array(memberNames(args.members, op))
		end
		return out
	end, path)
end
--- Canonical structural equality, including null and object-key ordering.
function System.equal(a: unknown, b: unknown): boolean
	return Json.encode(a) == Json.encode(b)
end
--- Replace a selected value without creating missing intermediate containers or extending lists.
local function replace(t: any, v: any, path: Types.Path, at: number, replacement: any): any
	if at > #path then
		return replacement
	end
	if t.kind == "nullable" then
		t = t.of
	end
	if v == nil or v == Json.null then
		fail("not_found")
	end
	local key: any = path[at]
	local child
	if t.kind == "list" then
		key += 1
		if key > #v then
			fail("not_found")
		end
		child = t.item
	elseif t.kind == "map" then
		child = t.value
	else
		child = t.members[key].type
	end
	v[key] = replace(child, v[key], path, at + 1, replacement)
	return v
end
--- The set bits of a stored bitmap value, ascending (empty for the unset value).
local function bitsOf(value: string): { number }
	local bits: { number } = Bitmap.decode(value) or {}
	return bits
end
--- Refuse a bitmap that gains a bit that is not an active member of its item list: unknown first, then retired.
local function guardGained(before: string, after: string, members: { [string]: Types.MemberInfo })
	local byBit: { [number]: string } = {}
	local retired: { [number]: boolean } = {}
	for name, info in members do
		byBit[info.bit] = name
		retired[info.bit] = info.retired == true
	end
	local had: { [number]: boolean } = {}
	for _, bit in bitsOf(before) do
		had[bit] = true
	end
	local unknown: { string } = {}
	local gone: { string } = {}
	for _, bit in bitsOf(after) do
		if not had[bit] then
			if byBit[bit] == nil then
				table.insert(unknown, "#" .. tostring(bit))
			elseif retired[bit] then
				table.insert(gone, byBit[bit])
			end
		end
	end
	if #unknown > 0 then
		failMembers("unknown_member", unknown)
	end
	if #gone > 0 then
		table.sort(gone)
		failMembers("member_retired", gone)
	end
end
--- GRANT, REVOKE or REPLACE by member name, resolved through the item list's permanent bits.
local function applyMembers(
	t: any,
	current: string,
	op: string,
	value: any,
	lookup: Types.MemberLookup?
): string
	local names = memberNames(value, op)
	local members = if lookup then lookup(t.source) else nil
	if not members then
		failMembers("enum_source_unavailable")
	end
	local resolved: { [number]: boolean } = {}
	local unknown: { string } = {}
	for _, name in names do
		local info = (members :: { [string]: Types.MemberInfo })[name]
		if info then
			resolved[info.bit] = true
		else
			table.insert(unknown, name)
		end
	end
	if #unknown > 0 then
		failMembers("unknown_member", unknown)
	end
	local result: { [number]: boolean } = {}
	if op ~= "REPLACE" then
		for _, bit in bitsOf(current) do
			result[bit] = true
		end
	end
	for bit in resolved do
		if op == "REVOKE" then
			result[bit] = nil
		else
			result[bit] = true
		end
	end
	local encoded = validate(t, Bitmap.encode(result))
	guardGained(current, encoded, members :: { [string]: Types.MemberInfo })
	return encoded
end
--- Evaluate one checked operation and revalidate both the target and full field.
--- Bitmap member operations (and a bitmap SET) are checked against `lookup`, the item list's members; a
--- GRANT, REVOKE or REPLACE needs it (`enum_source_unavailable` without), a SET is only checked when it is given.
function System.apply(
	t: TypeExpr,
	value: Core.Json,
	default: Core.Json?,
	op: string,
	args: { [string]: any },
	path: Types.Path?,
	lookup: Types.MemberLookup?
): Core.Result<Core.Json>
	local p = path or {}
	return protect(function()
		value = validate(t, value)
		local sub, current, def = target(t, value, default, p)
		operation(sub, op, args)
		local result: any
		if op == "GRANT" or op == "REVOKE" or op == "REPLACE" then
			result = applyMembers(sub, current, op, args.members, lookup)
		elseif op == "SET" then
			result = validate(sub, args.value)
			local members = if sub.kind == "bitmap" and lookup then lookup(sub.source) else nil
			if members then
				guardGained(current, result, members)
			end
		elseif op == "RESET" then
			local d = System.default(sub, def)
			if not d.ok then
				fail("default_required")
			end
			result = if d.ok then d.value else nil
		else
			if current == nil then
				fail("not_found")
			end
			result = Copy.copy(current)
			if op == "ADD" then
				result = current + args.delta
				numeric(sub, result)
			elseif op == "MIN" then
				result = math.min(current, args.value)
			elseif op == "MAX" then
				result = math.max(current, args.value)
			elseif op == "APPEND" or op == "INSERT" then
				local at = if op == "APPEND" then #result else args.index
				if at > #result then
					fail("not_found")
				end
				for i, v in args.items do
					table.insert(result, at + i, validate(sub.item, v))
				end
			elseif op == "REMOVE_AT" then
				local count = args.count or 1
				if args.index >= #result or args.index + count > #result then
					fail("not_found")
				end
				for _ = 1, count do
					table.remove(result, args.index + 1)
				end
			elseif op == "REMOVE_VALUE" then
				local needle = validate(sub.item, args.value)
				local found = nil
				for i, v in result do
					if System.equal(v, needle) then
						found = i
						break
					end
				end
				if not found then
					fail("not_found")
				end
				table.remove(result, found)
			elseif op == "SET_ADD" or op == "SET_REMOVE" then
				local set: { [string]: any } = {}
				for _, v in result do
					set[Json.encode(v)] = v
				end
				for _, v in args.items do
					local checked = validate(sub.item, v)
					set[Json.encode(checked)] = if op == "SET_ADD" then checked else nil
				end
				result = Json.array({})
				for _, v in set do
					table.insert(result, v)
				end
			elseif op == "MAP_PUT" then
				for key, v in args.entries do
					result[key] = validate(sub.value, v)
				end
			elseif op == "MAP_REMOVE" then
				for _, key in args.keys do
					result[key] = nil
				end
			elseif op == "MAP_ADD" then
				result[args.key] = (result[args.key] or 0) + args.delta
				numeric(sub.value, result[args.key])
			end
			result = validate(sub, result)
		end
		return validate(t, replace(t, Copy.copy(value), p, 1, result))
	end, p)
end
return table.freeze(System)
