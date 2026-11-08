--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Types = require(script.Parent.Parent.Fields.Types)
local Schema = require(script.Parent.Parent.Fields.Schema)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Json = require(script.Parent.Parent.Core.Json)
local Copy = require(script.Parent.Parent.Core.Idempotency)
local Operations = {}
local arguments: { [string]: { string } } = {
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
	MAP_PUT = { "entries" },
	MAP_REMOVE = { "keys" },
	MAP_ADD = { "key", "delta" },
}
--- Recognize dense bounded arrays, rejecting null, objects and sparse Lua tables.
local function array(value: any, maximum: number): boolean
	if type(value) ~= "table" or value == Json.null or Json.isObject(value) or #value > maximum then
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
--- Parse all structural properties before looking up definitions, matching the server's 400 boundary.
function Operations.shape(ops: unknown): boolean
	local list: any = ops
	if not array(list, 100) or #list == 0 then
		return false
	end
	for _, op in list do
		if
			type(op) ~= "table"
			or op == Json.null
			or Json.isArray(op)
			or type(op.field) ~= "string"
			or not string.find(op.field, "%S")
			or type(op.op) ~= "string"
			or not string.find(op.op, "%S")
		then
			return false
		end
		local allowed = arguments[op.op] or {}
		for key in op do
			if key ~= "field" and key ~= "op" and key ~= "path" and not table.find(allowed, key) then
				return false
			end
		end
		if op.path ~= nil then
			if not array(op.path, 8) then
				return false
			end
			for _, segment in op.path do
				if
					type(segment) ~= "string"
					and (type(segment) ~= "number" or segment % 1 ~= 0 or segment < 0 or segment > 2147483647)
				then
					return false
				end
			end
		end
	end
	return true
end
--- Check the closed CodeService wire union without requiring a particular universe schema.
function Operations.wire(value: unknown): boolean
	if not Operations.shape({ value } :: any) then
		return false
	end
	local op: any = value
	local allowed = arguments[op.op]
	if not allowed or #op.field > 200 then
		return false
	end
	local parts = string.split(op.field, ".")
	if #parts > 8 then
		return false
	end
	for _, part in parts do
		if #part > 64 or not string.match(part, "^[A-Za-z][A-Za-z0-9_]*$") then
			return false
		end
	end
	for _, name in allowed do
		if name ~= "count" and op[name] == nil then
			return false
		end
	end
	if
		op.delta ~= nil
		and (type(op.delta) ~= "number" or op.delta ~= op.delta or math.abs(op.delta) == math.huge)
	then
		return false
	end
	if (op.op == "MIN" or op.op == "MAX") and type(op.value) ~= "number" then
		return false
	end
	for _, name in { "index", "count" } do
		local v = op[name]
		if
			v ~= nil
			and (
				type(v) ~= "number"
				or v % 1 ~= 0
				or v < (if name == "count" then 1 else 0)
				or v > 2147483647
			)
		then
			return false
		end
	end
	if op.items ~= nil and not array(op.items, math.huge) then
		return false
	end
	if op.keys ~= nil then
		if not array(op.keys, math.huge) then
			return false
		end
		for _, key in op.keys do
			if type(key) ~= "string" then
				return false
			end
		end
	end
	if op.key ~= nil and type(op.key) ~= "string" then
		return false
	end
	if op.entries ~= nil then
		if type(op.entries) ~= "table" or op.entries == Json.null or Json.isArray(op.entries) then
			return false
		end
		for key in op.entries do
			if type(key) ~= "string" then
				return false
			end
		end
	end
	return true
end
--- Copy the shared operation grammar without retaining caller-owned nested tables.
function Operations.make(
	id: string,
	op: string,
	args: { [string]: any },
	path: Types.Path?
): Core.Result<Types.PlayerOperation>
	local item = table.clone(args)
	item.field = id
	item.op = op
	item.path = path
	local ok, value = pcall(Copy.copy, item)
	return if ok then { ok = true, value = value } else System.failure("invalid_request")
end
--- Extract only operands for the TypeSystem; never let envelope properties bypass its closed grammar.
local function operands(op: Types.PlayerOperation): { [string]: any }
	local args: any = Copy.copy(op)
	args.field = nil
	args.op = nil
	args.path = nil
	return args
end
--- Collect one diagnostic per failing op in input order; no hypothetical player state or write authority.
function Operations.validate(
	schema: Schema.Schema,
	ops: { Types.PlayerOperation }
): Core.Result<Wire.OpsValidationResult>
	local copied, snapshot = pcall(Copy.copy, ops)
	if not copied then
		return System.failure("invalid_request")
	end
	ops = snapshot
	if not Operations.shape(ops) then
		return System.failure("invalid_request")
	end
	if schema:version() == nil then
		return System.failure("schema_unavailable")
	end
	local errors: { Wire.OpValidationError } = Json.array({})
	for i, op in ops do
		local d = schema:get(op.field)
		local code: string? = nil
		if not d then
			code = "unknown_field"
		elseif d.scope ~= "PLAYER" then
			code = "field_scope_mismatch"
		elseif
			not d.type
			or (d.type :: any) == Json.null
			or d.computed and (d.computed :: any) ~= Json.null
		then
			code = "field_computed"
		elseif d.status == "ARCHIVED" then
			code = "field_archived"
		else
			local result = System.checkOperation(d.type :: Types.TypeExpr, op.op, operands(op), op.path)
			if not result.ok then
				code = result.error.code or "invalid_request"
			end
		end
		if code then
			table.insert(errors, {
				opIndex = i - 1,
				field = op.field,
				path = Copy.copy(op.path or Json.array({})),
				code = code,
			})
		end
	end
	return { ok = true, value = { valid = #errors == 0, errors = errors } }
end
--- Return a canonical private op list, or the first diagnostic when a mutation must fail closed.
function Operations.prepare(
	schema: Schema.Schema,
	ops: { Types.PlayerOperation }
): Core.Result<{ Types.PlayerOperation }>
	local valid = Operations.validate(schema, ops)
	if not valid.ok then
		return valid
	end
	if not valid.value.valid then
		-- This report was constructed locally above, not read from a tolerant wire DTO.
		local e = (valid.value.errors :: { Wire.OpValidationError })[1]
		if type(e.code) ~= "string" then
			return System.failure("invalid_request")
		end
		return System.failure(
			e.code,
			e.path :: { string | number }?,
			if type(e.field) == "string" then e.field else nil,
			e.opIndex
		)
	end
	local result: { Types.PlayerOperation } = Json.array({})
	for _, op in ops do
		local d = schema:get(op.field) :: Wire.Definition
		local prepared = System.prepareOperation(d.type :: Types.TypeExpr, op.op, operands(op), op.path)
		if not prepared.ok then
			return prepared
		end
		local item: any = prepared.value
		item.field = op.field
		item.op = op.op
		item.path = if op.path then Json.array(Copy.copy(op.path)) else nil
		table.insert(result, item)
	end
	return { ok = true, value = result }
end
return table.freeze(Operations)
