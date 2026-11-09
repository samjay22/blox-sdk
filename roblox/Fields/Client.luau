--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Endpoints = require(script.Parent.Parent.Core.Endpoints)
local Schema = require(script.Parent.Parent.Fields.Schema)
local Transaction = require(script.Parent.Parent.Fields.Transaction)
local Profile = require(script.Parent.Parent.Fields.Profile)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Universe = require(script.Parent.Parent.Core.Universe)
local Operations = require(script.Parent.Parent.Fields.Operations)
local OpBuilder = require(script.Parent.Parent.Fields.OpBuilder)
local Types = require(script.Parent.Parent.Fields.Types)
local Snapshot = require(script.Parent.Parent.Core.SnapshotCache)
local ProfileSync = require(script.Parent.Parent.Fields.ProfileSync)
local Sessions = require(script.Parent.Parent.Fields.Sessions)
local Helpers = {}
export type State = {
	runtime: Core.Runtime,
	invoke: Core.Invoke,
	schemas: { [string]: Schema.Schema },
	profiles: { [Profile.Profile]: boolean },
	loading: { [string]: boolean },
	sync: ProfileSync.Sync,
	sessions: Sessions.Sessions,
	closed: boolean,
	snapshots: { [string]: Snapshot.Snapshot? },
	snapshotListeners: { [(string, Snapshot.Snapshot?) -> ()]: boolean },
	cleanups: { [() -> ()]: boolean },
	onUse: () -> (),
}
--- Create shared helper ownership without starting a poll or issuing any HTTP.
function Helpers.new(
	runtime: Core.Runtime,
	invoke: Core.Invoke,
	onUse: () -> (),
	sync: ProfileSync.Sync,
	sessions: Sessions.Sessions
): State
	return {
		runtime = runtime,
		invoke = invoke,
		schemas = {},
		profiles = {},
		loading = {},
		sync = sync,
		sessions = sessions,
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
--- Read sync barriers afresh, never reusing cached or already in-flight snapshots.
local function snapshotOptions(options: Core.CallOptions?): Core.CallOptions
	local fresh = table.clone(options or {})
	fresh.cacheTtl = 0
	-- A request-specific signal also disables GET coalescing with an older read.
	fresh.signal = fresh.signal or { cancelled = false }
	return fresh
end
--- Load schema plus a coherent player document and register profile lifecycle ownership.
local function loadProfile(
	state: State,
	universeId: string | number,
	userId: number
): Core.Result<Profile.Profile>
	if not Universe.valid(userId) then
		return System.failure("invalid_request")
	end
	local schema = Helpers.schema(state, universeId)
	local ticket = state.sync:beginLoad(userId)
	local loaded = schema:load()
	if not loaded.ok then
		state.sync:endLoad(ticket)
		return loaded
	end
	if ticket.cancelled then
		state.sync:endLoad(ticket)
		return System.failure("profile_closed")
	end
	local acquired = state.sessions:acquire(tostring(universeId), userId, state.invoke, ticket)
	if not acquired.ok then
		state.sync:endLoad(ticket)
		return acquired
	end
	local lease = acquired.value
	local initial = lease.snapshot
	local profile = Profile.new(state.runtime, schema, userId, {
		document = function(options)
			if initial then
				local snapshot = initial
				initial = nil
				return {
					ok = true,
					value = {
						userId = userId,
						seq = snapshot.seq,
						data = snapshot.fields,
						versions = snapshot.versions,
					},
				}
			end
			return state.invoke(
				Endpoints["fields.document"],
				{ path = { universeId = universeId, userId = userId } },
				snapshotOptions(options),
				universeId
			)
		end,
		changes = function(since, options)
			return state.invoke(
				Endpoints["fields.changes"],
				{ path = { universeId = universeId, userId = userId }, query = { sinceSeq = since } },
				snapshotOptions(options),
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
	state.sessions:attach(lease, profile)
	local result = profile:refresh({ signal = ticket })
	state.sync:endLoad(ticket)
	if not result.ok then
		state.sessions:removePlayer(userId)
		profile:destroy()
		return result
	end
	if state.closed or ticket.cancelled then
		profile:destroy()
		return System.failure("client_closed")
	end
	state.profiles[profile] = true
	profile._onRelease = function()
		state.profiles[profile] = nil
		state.sync:unregister(profile)
		state.sessions:releaseProfile(profile)
	end
	state.sync:register(tostring(universeId), profile, state.invoke)
	return { ok = true, value = profile }
end
--- Share one loaded leased profile per universe/player, including concurrent load callers.
function Helpers.loadProfile(
	state: State,
	universeId: string | number,
	userId: number
): Core.Result<Profile.Profile>
	if not Universe.valid(userId) or not Universe.valid(universeId) then
		return System.failure("invalid_request")
	end
	local key = tostring(universeId) .. ":" .. tostring(userId)
	while state.loading[key] and not state.closed do
		state.runtime.wait(0.01)
	end
	if state.closed then
		return System.failure("client_closed")
	end
	for profile in state.profiles do
		if profile._user == userId and profile._universe == tostring(universeId) and not profile._closed then
			return { ok = true, value = profile }
		end
	end
	state.loading[key] = true
	local ok, result = pcall(loadProfile, state, universeId, userId)
	state.loading[key] = nil
	local response: Core.Result<Profile.Profile> = if ok
		then result
		else System.failure("profile_load_failed")
	if
		not response.ok
		and response.error.code ~= "profile_closed"
		and response.error.code ~= "client_closed"
	then
		state.sessions:loadFailure(userId)
	end
	return response
end
--- Close profiles only after the shared session coordinator has flushed and released leases.
function Helpers.close(state: State, deadline: number): boolean
	state.closed = true
	for cleanup in state.cleanups do
		cleanup()
	end
	for _, schema in state.schemas do
		schema:destroy()
	end
	local drained = true
	for profile in table.clone(state.profiles) do
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
	for profile in table.clone(state.profiles) do
		profile:destroy()
	end
end
return table.freeze(Helpers)
