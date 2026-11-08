--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Endpoints = require("../Core/Endpoints")
local Schema = require("./Schema")
local Transaction = require("./Transaction")
local Profile = require("./Profile")
local System = require("./TypeSystem")
local Universe = require("../Core/Universe")
local Operations = require("./Operations")
local OpBuilder = require("./OpBuilder")
local Types = require("./Types")
local Snapshot = require("../Core/SnapshotCache")
local Helpers = {}
export type State = {
	runtime: Core.Runtime,
	invoke: Core.Invoke,
	schemas: { [string]: Schema.Schema },
	profiles: { Profile.Profile },
	closed: boolean,
	snapshots: { [string]: Snapshot.Snapshot? },
	snapshotListeners: { [(string, Snapshot.Snapshot?) -> ()]: boolean },
	cleanups: { [() -> ()]: boolean },
	onUse: () -> (),
}
--- Create shared helper ownership without starting a poll or issuing any HTTP.
function Helpers.new(runtime: Core.Runtime, invoke: Core.Invoke, onUse: () -> ()): State
	return {
		runtime = runtime,
		invoke = invoke,
		schemas = {},
		profiles = {},
		closed = false,
		snapshots = {},
		snapshotListeners = {},
		cleanups = {},
		onUse = onUse,
	}
end
--- Publish snapshot ownership changes so existing watches can switch modes without polling.
function Helpers.setSnapshot(state: State, universe: string, snapshot: Snapshot.Snapshot?)
	state.snapshots[universe] = snapshot
	for listener in state.snapshotListeners do
		listener(universe, snapshot)
	end
end
--- Get one universe cache; repeated accesses reuse its compiled schema generation.
function Helpers.schema(state: State, universeId: string | number): Schema.Schema
	assert(not state.closed and Universe.valid(universeId), "Invalid Fields schema scope or closed client")
	local key = tostring(universeId)
	local cached = state.schemas[key]
	if cached then
		return cached
	end
	local cache = Schema.new(state.runtime, function(options)
		local result = state.invoke(
			Endpoints["fields.schema"],
			{ path = { universeId = universeId } },
			options,
			universeId
		)
		if result.ok and tostring(result.value.universeId) ~= tostring(universeId) then
			return System.failure("invalid_schema_scope")
		end
		return result
	end)
	state.schemas[key] = cache
	state.onUse()
	return cache
end
--- Create a transaction over the cached schema, with an immutable per-transaction idempotency identity.
function Helpers.transaction(
	state: State,
	universeId: string | number,
	userId: number?,
	onCommit: ((Wire.Result) -> ())?
): Transaction.Transaction
	local schema = Helpers.schema(state, universeId)
	return Transaction.new(
		schema,
		state.runtime,
		userId,
		function(body, options)
			if state.closed then
				return System.failure("client_closed")
			end
			return state.invoke(
				Endpoints[if userId ~= nil then "fields.transaction" else "fields.multiTransaction"],
				{ path = { universeId = universeId, userId = userId }, body = body },
				options,
				universeId
			)
		end,
		onCommit,
		function(ops, options)
			return Helpers.validateOps(state, universeId, { ops = ops }, options)
		end
	)
end
--- Validate the whole local template before issuing the read-only server validation request.
function Helpers.validateOps(
	state: State,
	universeId: string | number,
	body: Wire.OpsValidationInput,
	options: Core.CallOptions?
): Core.Result<Wire.OpsValidationResult>
	if state.closed then
		return System.failure("client_closed")
	end
	if not Universe.valid(universeId) or type(body) ~= "table" then
		return System.failure("invalid_request")
	end
	for key in body do
		if key ~= "ops" and key ~= "universeId" then
			return System.failure("invalid_request")
		end
	end
	if body.universeId ~= nil and tostring(body.universeId) ~= tostring(universeId) then
		return System.failure("invalid_request")
	end
	local schema = Helpers.schema(state, universeId)
	local checked = Operations.validate(schema, body.ops)
	if not checked.ok or not checked.value.valid then
		return checked
	end
	local prepared = Operations.prepare(schema, body.ops)
	if not prepared.ok then
		return prepared
	end
	return state.invoke(
		Endpoints["fields.validateOps"],
		{ path = { universeId = universeId }, body = { ops = prepared.value, universeId = body.universeId } },
		options,
		universeId
	)
end
--- Construct a subject-free operation list for dry runs and CodeService awards.
function Helpers.operations(state: State, universeId: string | number): OpBuilder.Builder
	return OpBuilder.new(Helpers.schema(state, universeId), function(ops: { Types.PlayerOperation }, options)
		return Helpers.validateOps(state, universeId, { ops = ops }, options)
	end)
end
--- Load schema plus a coherent player document and register profile lifecycle ownership.
function Helpers.loadProfile(
	state: State,
	universeId: string | number,
	userId: number
): Core.Result<Profile.Profile>
	if not Universe.valid(userId) then
		return System.failure("invalid_request")
	end
	local schema = Helpers.schema(state, universeId)
	local loaded = schema:load()
	if not loaded.ok then
		return loaded
	end
	local profile = Profile.new(state.runtime, schema, userId, {
		document = function(options)
			return state.invoke(
				Endpoints["fields.document"],
				{ path = { universeId = universeId, userId = userId } },
				options,
				universeId
			)
		end,
		changes = function(since, options)
			return state.invoke(
				Endpoints["fields.changes"],
				{ path = { universeId = universeId, userId = userId }, query = { sinceSeq = since } },
				options,
				universeId
			)
		end,
		presence = function(body, options)
			return state.invoke(
				Endpoints["fields.putPresence"],
				{ path = { universeId = universeId, userId = userId }, body = body },
				options,
				universeId
			)
		end,
		transaction = function(callback)
			return Helpers.transaction(state, universeId, userId, callback)
		end,
	})
	local result = profile:refresh()
	if not result.ok then
		profile:destroy()
		return result
	end
	-- Closed profiles no longer own background work; do not retain reconnect history indefinitely.
	for i = #state.profiles, 1, -1 do
		if state.profiles[i]._closed then
			table.remove(state.profiles, i)
		end
	end
	table.insert(state.profiles, profile)
	return { ok = true, value = profile }
end
--- Drain owned leases before pipeline admission closes; there is no hidden write-behind data queue.
function Helpers.close(state: State, deadline: number): boolean
	state.closed = true
	for cleanup in state.cleanups do
		cleanup()
	end
	for _, schema in state.schemas do
		schema:destroy()
	end
	local drained = true
	for _, profile in state.profiles do
		if not profile:close(deadline) then
			drained = false
		end
	end
	return drained
end
--- Cancel all helper tasks without sending a request.
function Helpers.destroy(state: State)
	state.closed = true
	for cleanup in state.cleanups do
		cleanup()
	end
	for _, schema in state.schemas do
		schema:destroy()
	end
	for _, profile in state.profiles do
		profile:destroy()
	end
end
return table.freeze(Helpers)
