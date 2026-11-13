--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Types = require("./Types")
local Schema = require("./Schema")
local Operations = require("./Operations")
local Builder = {}
Builder.__index = Builder
export type Builder = typeof(setmetatable(
	{} :: {
		_schema: Schema.Schema,
		_ops: { Types.PlayerOperation },
		_error: Core.BloxError?,
		_validate: ({ Types.PlayerOperation }, Core.CallOptions?) -> Core.Result<Wire.OpsValidationResult>,
	},
	Builder
))
--- Bind a subject-free op builder to one schema and a read-only validation sender.
function Builder.new(
	schema: Schema.Schema,
	validate: (
		{ Types.PlayerOperation },
		Core.CallOptions?
	) -> Core.Result<Wire.OpsValidationResult>
): Builder
	return setmetatable({ _schema = schema, _ops = {}, _error = nil, _validate = validate }, Builder)
end
--- Queue a private operation using the same constructor as Fields transactions.
local function push(
	self: Builder,
	id: string,
	op: string,
	args: { [string]: any },
	path: Types.Path?
): Builder
	local item = Operations.make(id, op, args, path)
	if item.ok then
		table.insert(self._ops, item.value)
	elseif not self._error then
		self._error = item.error
	end
	return self
end
--- Set a whole field or declared nested target.
function Builder.set(self: Builder, id: string, value: Core.Json, path: Types.Path?): Builder
	return push(self, id, "SET", { value = value }, path)
end
--- Add a nonzero numeric delta.
function Builder.add(self: Builder, id: string, delta: number, path: Types.Path?): Builder
	return push(self, id, "ADD", { delta = delta }, path)
end
--- Clamp a numeric target downward.
function Builder.min(self: Builder, id: string, value: number, path: Types.Path?): Builder
	return push(self, id, "MIN", { value = value }, path)
end
--- Clamp a numeric target upward.
function Builder.max(self: Builder, id: string, value: number, path: Types.Path?): Builder
	return push(self, id, "MAX", { value = value }, path)
end
--- Reset to the field/member/natural default.
function Builder.reset(self: Builder, id: string, path: Types.Path?): Builder
	return push(self, id, "RESET", {}, path)
end
--- Append validated list items.
function Builder.append(self: Builder, id: string, items: { Core.Json }, path: Types.Path?): Builder
	return push(self, id, "APPEND", { items = items }, path)
end
--- Insert items at a zero-based list index.
function Builder.insert(
	self: Builder,
	id: string,
	index: number,
	items: { Core.Json },
	path: Types.Path?
): Builder
	return push(self, id, "INSERT", { index = index, items = items }, path)
end
--- Remove a complete zero-based range (count defaults to one).
function Builder.removeAt(
	self: Builder,
	id: string,
	index: number,
	count: number?,
	path: Types.Path?
): Builder
	return push(self, id, "REMOVE_AT", { index = index, count = count }, path)
end
--- Remove the first canonical list match.
function Builder.removeValue(self: Builder, id: string, value: Core.Json, path: Types.Path?): Builder
	return push(self, id, "REMOVE_VALUE", { value = value }, path)
end
--- Union validated set members.
function Builder.setAdd(self: Builder, id: string, items: { Core.Json }, path: Types.Path?): Builder
	return push(self, id, "SET_ADD", { items = items }, path)
end
--- Remove matching set members, ignoring absent values.
function Builder.setRemove(self: Builder, id: string, items: { Core.Json }, path: Types.Path?): Builder
	return push(self, id, "SET_REMOVE", { items = items }, path)
end
--- Give item list members to the player (idempotent; unknown and retired members are refused).
function Builder.grant(self: Builder, id: string, members: { string }): Builder
	return push(self, id, "GRANT", { members = members }, nil)
end
--- Take item list members away from the player (idempotent; retired members may be taken away).
function Builder.revoke(self: Builder, id: string, members: { string }): Builder
	return push(self, id, "REVOKE", { members = members }, nil)
end
--- Make the player hold exactly these item list members; an empty list clears them.
function Builder.replace(self: Builder, id: string, members: { string }): Builder
	return push(self, id, "REPLACE", { members = members }, nil)
end
--- Merge/replace validated map entries.
function Builder.mapPut(
	self: Builder,
	id: string,
	entries: { [string]: Core.Json },
	path: Types.Path?
): Builder
	return push(self, id, "MAP_PUT", { entries = entries }, path)
end
--- Remove validated wire-string map keys.
function Builder.mapRemove(self: Builder, id: string, keys: { string }, path: Types.Path?): Builder
	return push(self, id, "MAP_REMOVE", { keys = keys }, path)
end
--- Add to a numeric map value (missing values start at zero).
function Builder.mapAdd(self: Builder, id: string, key: string, delta: number, path: Types.Path?): Builder
	return push(self, id, "MAP_ADD", { key = key, delta = delta }, path)
end
--- Produce a canonical, schema-validated snapshot; later builder edits cannot mutate it.
function Builder.build(self: Builder): Core.Result<{ Types.PlayerOperation }>
	if self._error then
		return { ok = false, error = self._error }
	end
	return Operations.prepare(self._schema, self._ops)
end
--- Pre-validate every op locally, then ask Fields for current authoritative diagnostics.
function Builder.validate(self: Builder, options: Core.CallOptions?): Core.Result<Wire.OpsValidationResult>
	if self._error then
		return { ok = false, error = self._error }
	end
	return self._validate(self._ops, options)
end
return table.freeze(Builder)
