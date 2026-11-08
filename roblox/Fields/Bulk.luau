--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Types = require(script.Parent.Parent.Fields.Types)
local Helpers = require(script.Parent.Parent.Fields.Client)
local OpBuilder = require(script.Parent.Parent.Fields.OpBuilder)
local Scope = require(script.Parent.Parent.Fields.Scope)
local Control = require(script.Parent.Parent.Fields.Control)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Copy = require(script.Parent.Parent.Core.Idempotency)
local Errors = require(script.Parent.Parent.Core.Errors)
local Bulk = {}
Bulk.__index = Bulk
export type Builder = typeof(setmetatable(
	{} :: {
		_scope: Scope.Scope,
		ops: OpBuilder.Builder,
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
		ops = Helpers.operations(state, universe),
		_target = nil,
		_reason = nil,
		_key = Copy.key(state.runtime),
		_invalid = false,
	}, Bulk)
end
--- Snapshot an explicit selection; never silently default a grant to all players.
function Bulk.target(self: Builder, target: Types.BulkTarget): Builder
	local ok, copied = pcall(Copy.copy, target)
	if ok then
		self._target = copied
	else
		self._invalid = true
	end
	return self
end
--- Set the required administrative audit reason.
function Bulk.reason(self: Builder, reason: string): Builder
	self._reason = reason
	return self
end
--- Supply a persisted key for deliberate retries across calls or server restarts.
function Bulk.idempotencyKey(self: Builder, key: string): Builder
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
	local ops = self.ops:build()
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
