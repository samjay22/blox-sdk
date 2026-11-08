--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Types = require("./Types")
local System = require("./TypeSystem")
local Schema = require("./Schema")
local Json = require("../Core/Json")
local Copy = require("../Core/Idempotency")
local Universe = require("../Core/Universe")
local Cache = require("../Core/Cache")
local Operations = require("./Operations")
local Transaction = {}
Transaction.__index = Transaction
export type Transaction = typeof(setmetatable(
	{} :: {
		_schema: Schema.Schema,
		_validateOps: ((
			{ Types.PlayerOperation },
			Core.CallOptions?
		) -> Core.Result<Wire.OpsValidationResult>)?,
		_subject: number?,
		_multi: boolean,
		_ops: { Types.Operation },
		_conditions: { Types.Condition },
		_key: string,
		_reason: string,
		_ref: Wire.Ref?,
		_sealed: boolean,
		_busy: boolean,
		_result: Core.Result<Wire.Result>?,
		_send: (Wire.TransactionInput, Core.CallOptions?) -> Core.Result<Wire.Result>,
		_error: Core.BloxError?,
		_onCommit: ((Wire.Result) -> ())?,
	},
	Transaction
))
--- Own one immutable-on-first-commit request identity, including retries across Commit calls.
function Transaction.new(
	schema: Schema.Schema,
	runtime: Core.Runtime,
	subject: number?,
	send: (Wire.TransactionInput, Core.CallOptions?) -> Core.Result<Wire.Result>,
	onCommit: ((Wire.Result) -> ())?,
	validateOps: ((
		{ Types.PlayerOperation },
		Core.CallOptions?
	) -> Core.Result<Wire.OpsValidationResult>)?
): Transaction
	return setmetatable({
		_schema = schema,
		_validateOps = validateOps,
		_subject = subject,
		_multi = subject == nil,
		_ops = {},
		_conditions = {},
		_key = Copy.key(runtime),
		_reason = "",
		_ref = nil,
		_sealed = false,
		_busy = false,
		_result = nil,
		_send = send,
		_error = nil,
		_onCommit = onCommit,
	}, Transaction)
end
--- Remember the first local misuse; no malformed builder may reach transport.
local function reject(self: Transaction, code: string)
	local result = System.failure(code)
	if not result.ok and not self._error then
		self._error = result.error
	end
end
--- Select a subject for subsequent multi-subject operations and conditions; zero means shared fields.
function Transaction.subject(self: Transaction, subject: number): Transaction
	if self._sealed or not self._multi or subject ~= 0 and not Universe.valid(subject) then
		reject(self, "invalid_request")
	else
		self._subject = subject
	end
	return self
end
--- Append a private op snapshot, retaining programmer mutations outside the transaction.
local function push(
	self: Transaction,
	id: string,
	op: string,
	args: { [string]: any },
	path: Types.Path?
): Transaction
	if self._sealed then
		reject(self, "transaction_sealed")
		return self
	end
	local item = Operations.make(id, op, args, path)
	if not item.ok then
		reject(self, "invalid_request")
	else
		local value: any = item.value
		if self._multi then
			value.subject = self._subject or 0
		end
		table.insert(self._ops, value)
	end
	return self
end
--- Set a whole field or declared nested target.
function Transaction.set(self: Transaction, id: string, value: Core.Json, path: Types.Path?): Transaction
	return push(self, id, "SET", { value = value }, path)
end
--- Add a nonzero numeric delta.
function Transaction.add(self: Transaction, id: string, delta: number, path: Types.Path?): Transaction
	return push(self, id, "ADD", { delta = delta }, path)
end
--- Clamp a numeric target downward.
function Transaction.min(self: Transaction, id: string, value: number, path: Types.Path?): Transaction
	return push(self, id, "MIN", { value = value }, path)
end
--- Clamp a numeric target upward.
function Transaction.max(self: Transaction, id: string, value: number, path: Types.Path?): Transaction
	return push(self, id, "MAX", { value = value }, path)
end
--- Reset to the field/member/natural default.
function Transaction.reset(self: Transaction, id: string, path: Types.Path?): Transaction
	return push(self, id, "RESET", {}, path)
end
--- Append validated list items.
function Transaction.append(
	self: Transaction,
	id: string,
	items: { Core.Json },
	path: Types.Path?
): Transaction
	return push(self, id, "APPEND", { items = items }, path)
end
--- Insert items at a zero-based list index.
function Transaction.insert(
	self: Transaction,
	id: string,
	index: number,
	items: { Core.Json },
	path: Types.Path?
): Transaction
	return push(self, id, "INSERT", { index = index, items = items }, path)
end
--- Remove a complete zero-based range (count defaults to one).
function Transaction.removeAt(
	self: Transaction,
	id: string,
	index: number,
	count: number?,
	path: Types.Path?
): Transaction
	return push(self, id, "REMOVE_AT", { index = index, count = count }, path)
end
--- Remove the first canonical list match.
function Transaction.removeValue(
	self: Transaction,
	id: string,
	value: Core.Json,
	path: Types.Path?
): Transaction
	return push(self, id, "REMOVE_VALUE", { value = value }, path)
end
--- Union validated set members.
function Transaction.setAdd(
	self: Transaction,
	id: string,
	items: { Core.Json },
	path: Types.Path?
): Transaction
	return push(self, id, "SET_ADD", { items = items }, path)
end
--- Remove matching set members, ignoring absent values.
function Transaction.setRemove(
	self: Transaction,
	id: string,
	items: { Core.Json },
	path: Types.Path?
): Transaction
	return push(self, id, "SET_REMOVE", { items = items }, path)
end
--- Merge/replace validated map entries.
function Transaction.mapPut(
	self: Transaction,
	id: string,
	entries: { [string]: Core.Json },
	path: Types.Path?
): Transaction
	return push(self, id, "MAP_PUT", { entries = entries }, path)
end
--- Remove validated wire-string map keys.
function Transaction.mapRemove(
	self: Transaction,
	id: string,
	keys: { string },
	path: Types.Path?
): Transaction
	return push(self, id, "MAP_REMOVE", { keys = keys }, path)
end
--- Add to a numeric map value (missing values start at zero).
function Transaction.mapAdd(
	self: Transaction,
	id: string,
	key: string,
	delta: number,
	path: Types.Path?
): Transaction
	return push(self, id, "MAP_ADD", { key = key, delta = delta }, path)
end
--- Add exactly one initial-state precondition, preserving explicit null equality.
function Transaction.expect(
	self: Transaction,
	id: string,
	expectation: Types.Expectation,
	path: Types.Path?
): Transaction
	if self._sealed then
		reject(self, "transaction_sealed")
		return self
	end
	local ok, value = pcall(Copy.copy, expectation)
	if not ok or type(value) ~= "table" then
		reject(self, "invalid_request")
		return self
	end
	for key in value do
		if not table.find({ "version", "equals", "exists" }, key) then
			reject(self, "invalid_request")
			return self
		end
	end
	value.expectedVersion = value.version
	value.version = nil
	value.field = id
	value.path = Copy.copy(path)
	if self._multi then
		value.subject = self._subject or 0
	end
	table.insert(self._conditions, value)
	return self
end
--- Attach the required audit reason.
function Transaction.reason(self: Transaction, text: string): Transaction
	if self._sealed then
		reject(self, "transaction_sealed")
	else
		self._reason = text
	end
	return self
end
--- Attach an optional trusted business reference.
function Transaction.ref(self: Transaction, kind: string, id: string): Transaction
	if self._sealed then
		reject(self, "transaction_sealed")
	else
		self._ref = { type = kind, id = id }
	end
	return self
end
--- Set a caller-persisted identity before commit for restart-safe workflows.
function Transaction.key(self: Transaction, key: string): Transaction
	if self._sealed then
		reject(self, "transaction_sealed")
	else
		self._key = key
	end
	return self
end
--- Expose the once-generated identity so callers can persist/reconcile an uncertain outcome.
function Transaction.idempotencyKey(self: Transaction): string
	return self._key
end
--- Check field existence/lifecycle/scope without any HTTP call.
local function definition(self: Transaction, id: string, subject: number?): Core.Result<Wire.Definition>
	local def = self._schema:get(id)
	if not def then
		return System.failure("unknown_field")
	end
	if def.status == "ARCHIVED" then
		return System.failure("field_archived")
	end
	if def.computed and (def.computed :: any) ~= Json.null then
		return System.failure("field_computed")
	end
	local selected = if self._multi then subject or 0 else self._subject
	if selected ~= 0 and not Universe.valid(selected) then
		return System.failure("invalid_request")
	end
	if (def.scope == "UNIVERSE") ~= (selected == 0) then
		return System.failure("field_scope_mismatch")
	end
	return { ok = true, value = def }
end
--- Check required text in Unicode code points, not UTF-8 bytes.
local function text(value: string, minimum: number, maximum: number): boolean
	return type(value) == "string"
		and not string.match(value, "^%s*$")
		and (utf8.len(value) or 0) >= minimum
		and (utf8.len(value) or math.huge) <= maximum
end
--- Validate the entire sealed transaction locally; no implicit schema fetch on invalid/unloaded builders.
function Transaction.validateLocal(self: Transaction): Core.Result<boolean>
	if self._error then
		return { ok = false, error = self._error }
	end
	if self._schema:version() == nil then
		return System.failure("schema_unavailable")
	end
	if #self._ops < 1 or #self._ops > 100 or #self._conditions > 100 or not text(self._reason, 1, 500) then
		return System.failure("invalid_request")
	end
	if not text(self._key, 1, 200) or not string.match(self._key, "^[A-Za-z0-9._-]+$") then
		return System.failure("invalid_request")
	end
	if self._ref and (not text(self._ref.type, 1, 100) or not text(self._ref.id, 1, 200)) then
		return System.failure("invalid_request")
	end
	local subjects: { [number]: boolean } = {}
	for i, op in self._ops do
		local d = definition(self, op.field, op.subject)
		if not d.ok then
			d.error.field = op.field
			d.error.opIndex = i - 1
			d.error.path = op.path or {}
			return d
		end
		subjects[op.subject or self._subject or 0] = true
		if d.value.writeLevel == "ADMIN" and not text(self._reason, 5, 500) then
			return System.failure("invalid_request", op.path, op.field, i - 1)
		end
		local args: any = Copy.copy(op)
		args.field = nil
		args.op = nil
		args.path = nil
		args.subject = nil
		local valid = System.checkOperation(d.value.type :: Types.TypeExpr, op.op, args, op.path)
		if valid.ok and op.op == "RESET" then
			local reset = System.resetDefault(d.value.type :: Types.TypeExpr, d.value.default, op.path)
			if not reset.ok then
				valid = reset
			end
		end
		if not valid.ok then
			valid.error.field = op.field
			valid.error.opIndex = i - 1
			return valid
		end
	end
	for _, condition in self._conditions do
		local d = definition(self, condition.field, condition.subject)
		if not d.ok then
			return d
		end
		subjects[condition.subject or self._subject or 0] = true
		local target = System.targetType(d.value.type :: Types.TypeExpr, condition.path)
		if not target.ok then
			return target
		end
		local c = condition :: any
		local count = 0
		for key in c do
			if not table.find({ "field", "subject", "path", "expectedVersion", "equals", "exists" }, key) then
				return System.failure("invalid_request")
			end
		end
		if c.expectedVersion ~= nil then
			count += 1
			if
				type(c.expectedVersion) ~= "number"
				or c.expectedVersion < 0
				or c.expectedVersion > 9007199254740991
				or c.expectedVersion % 1 ~= 0
			then
				return System.failure("invalid_request")
			end
		end
		if c.equals ~= nil then
			count += 1
			local v = System.validate(target.value, c.equals)
			if not v.ok then
				return v
			end
		end
		if c.exists ~= nil then
			count += 1
			if type(c.exists) ~= "boolean" then
				return System.failure("invalid_request")
			end
		end
		if count ~= 1 then
			return System.failure("invalid_request")
		end
	end
	local count = 0
	for _ in subjects do
		count += 1
	end
	if count > 10 then
		return System.failure("invalid_request")
	end
	return { ok = true, value = true }
end
--- Dry-run only the player operations, without sealing, committing, reason or key requirements.
function Transaction.validate(
	self: Transaction,
	options: Core.CallOptions?
): Core.Result<Wire.OpsValidationResult>
	if self._error then
		return { ok = false, error = self._error }
	end
	if self._multi then
		return System.failure("invalid_request")
	end
	if not self._validateOps then
		return Operations.validate(self._schema, Copy.copy(self._ops))
	end
	return self._validateOps(Copy.copy(self._ops), options)
end
--- Seal once, validate before sending, and reuse the same key/payload after uncertain failures.
function Transaction.commit(self: Transaction, options: Core.CallOptions?): Core.Result<Wire.Result>
	if self._busy then
		return System.failure("transaction_busy")
	end
	if self._result and self._result.ok then
		return self._result
	end
	local valid = self:validateLocal()
	if not valid.ok then
		return valid
	end
	if not self._sealed then
		local canonical: { Types.Operation } = {}
		for _, op in self._ops do
			local def = self._schema:get(op.field) :: Wire.Definition
			local args: any = Copy.copy(op)
			args.field = nil
			args.path = nil
			args.subject = nil
			args.op = nil
			local prepared = System.prepareOperation(def.type :: Types.TypeExpr, op.op, args, op.path)
			if not prepared.ok then
				return prepared
			end
			local item: any = prepared.value
			item.field = op.field
			item.path = op.path
			item.subject = op.subject
			item.op = op.op
			table.insert(canonical, item)
		end
		self._ops = Cache.freeze(canonical)
		local conditions: { Types.Condition } = Copy.copy(self._conditions)
		for _, condition in conditions do
			local c = condition :: any
			if c.equals ~= nil then
				local d = self._schema:get(c.field) :: Wire.Definition
				local sub = System.targetType(d.type :: Types.TypeExpr, c.path)
				if not sub.ok then
					return sub
				end
				local checked = System.validate(sub.value, c.equals)
				if not checked.ok then
					return checked
				end
				c.equals = checked.value
			end
		end
		self._conditions = Cache.freeze(conditions)
	end
	self._sealed = true
	self._busy = true
	local ok, response = pcall(self._send, {
		idempotencyKey = self._key,
		reason = self._reason,
		ref = self._ref,
		ops = self._ops,
		conditions = if #self._conditions > 0 then self._conditions else nil,
	}, options)
	self._busy = false
	local result: Core.Result<Wire.Result> = if ok
		then response
		else System.failure("transaction_send_failed")
	self._result = Cache.freeze(result)
	if result.ok and self._onCommit then
		self._onCommit(result.value)
	end
	return result
end
return table.freeze(Transaction)
