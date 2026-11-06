--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Types = require("./Types")
local Helpers = require("./Client")
local OpBuilder = require("./OpBuilder")
local Scope = require("./Scope")
local Control = require("./Control")
local System = require("./TypeSystem")
local Copy = require("../Core/Idempotency")
local Errors = require("../Core/Errors")
local Bulk = {}
Bulk.__index = Bulk
export type Builder = typeof(setmetatable(
	{} :: {
		_scope: Scope.Scope,
		Ops: OpBuilder.Builder,
		_target: Types.BulkTarget?,
		_reason: string?,
		_key: string,
		_invalid: boolean,
	},
	Bulk
))
--- Compose the shared typed operation builder; each bulk builder owns one stable logical key.
function Bulk.new(state: Helpers.State, universe: string | number): Builder
	return setmetatable({
		_scope = Scope.new(state, universe),
		Ops = Helpers.operations(state, universe),
		_target = nil,
		_reason = nil,
		_key = Copy.key(state.runtime),
		_invalid = false,
	}, Bulk)
end
--- Snapshot an explicit selection; never silently default a grant to all players.
function Bulk.Target(self: Builder, target: Types.BulkTarget): Builder
	local ok, copied = pcall(Copy.copy, target)
	if ok then
		self._target = copied
	else
		self._invalid = true
	end
	return self
end
--- Set the required administrative audit reason.
function Bulk.Reason(self: Builder, reason: string): Builder
	self._reason = reason
	return self
end
--- Supply a persisted key for deliberate retries across calls or server restarts.
function Bulk.IdempotencyKey(self: Builder, key: string): Builder
	self._key = key
	return self
end
--- Build a private, locally validated request without issuing HTTP or loading schema implicitly.
function Bulk.build(self: Builder): Core.Result<Wire.BulkInput>
	if self._scope.state.closed then
		return Errors.make("Cancelled", "fields.bulk", 0, "Client is closed")
	end
	if
		self._invalid
		or not self._target
		or not Control.reason(self._reason)
		or not Control.key(self._key)
	then
		return System.failure("invalid_request")
	end
	local target = Control.target(Helpers.schema(self._scope.state, self._scope.universe), self._target)
	if not target.ok then
		return target
	end
	local ops = self.Ops:build()
	if not ops.ok then
		return ops
	end
	return {
		ok = true,
		value = {
			target = target.value,
			ops = ops.value,
			reason = self._reason :: string,
			idempotencyKey = self._key,
		},
	}
end
--- Ask for an authoritative preview; this does not reserve target membership or current player state.
function Bulk.preview(self: Builder, options: Core.CallOptions?): Core.Result<Wire.BulkPreview>
	local built = self:build()
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.bulkPreview", { body = built.value }, options)
end
--- Queue ADMIN bulk work, not an atomic all-player transaction or a completion acknowledgement.
function Bulk.submit(self: Builder, options: Core.CallOptions?): Core.Result<Wire.JobReceipt>
	local built = self:build()
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.bulk", { body = built.value }, options)
end
--- Store an immutable definition for RUN_BULK schedule actions; creation is not automatically retried.
function Bulk.saveDefinition(
	self: Builder,
	options: Core.CallOptions?
): Core.Result<Wire.BulkDefinitionCreated>
	local built = self:build()
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.createBulkDefinition", { body = built.value }, options)
end
return table.freeze(Bulk)
