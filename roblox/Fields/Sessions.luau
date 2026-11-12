--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Profile = require(script.Parent.Parent.Fields.Profile)
local Schema = require(script.Parent.Parent.Fields.Schema)
local Config = require(script.Parent.Parent.Core.Config)
local Copy = require(script.Parent.Parent.Core.Idempotency)
local Json = require(script.Parent.Parent.Core.Json)
local Cache = require(script.Parent.Parent.Core.Cache)
local Instant = require(script.Parent.Parent.Core.Instant)
local Endpoints = require(script.Parent.Parent.Core.Endpoints)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Operations = require(script.Parent.Parent.Fields.Operations)
local Signal = require(script.Parent.Parent.Fields.SessionSignal)
local Sessions = {}
Sessions.__index = Sessions
local commitCounter = 0
local commitInFlight = false
type Lease = {
	universe: string,
	user: number,
	invoke: Core.Invoke,
	started: number,
	nextAt: number,
	expires: number,
	epoch: number?,
	snapshot: Wire.SessionSnapshot?,
	profile: Profile.Profile?,
	busy: boolean,
	closing: boolean,
	lost: boolean,
	error: string?,
	needsRecovery: boolean?,
	schemaRecoveryAt: number?,
}
type Commit = { universe: string, invoke: Core.Invoke, body: Wire.CommitInput, leases: { Lease } }
export type Sessions = typeof(setmetatable(
	{} :: {
		_runtime: Core.Runtime,
		_config: Config.SessionConfig,
		_server: string,
		_ttl: number,
		_interval: number,
		_timeout: number,
		_nextFlush: number,
		_retryAt: number,
		_counter: number,
		_leases: { [string]: Lease },
		_schemaAt: { [Schema.Schema]: number },
		_commit: Commit?,
		_busy: boolean,
		_closed: boolean,
		_kick: (number, string) -> (),
		wake: (() -> ())?,
		LeaseLost: Signal.Signal,
		CommitRejected: Signal.Signal,
	},
	Sessions
))
--- Allocate a server-wide session coordinator; no tasks start until acquire is requested.
function Sessions.new(
	runtime: Core.Runtime,
	options: Config.SessionConfig?,
	serverId: string,
	kick: (number, string) -> ()
): Sessions
	local config: Config.SessionConfig = options or {}
	local server = config.serverId or serverId
	assert(
		type(server) == "string"
			and #server <= 64
			and (server == "" and config.serverId == nil or string.find(server, "%S") ~= nil),
		"Invalid sessions.serverId"
	)
	return setmetatable({
		_runtime = runtime,
		_config = config,
		_server = server :: string,
		_ttl = Config.number(config.ttlMs, 60000, 10000, 300000, "sessions.ttlMs", true),
		_interval = Config.number(config.flushInterval, 5, 0.5, 300, "sessions.flushInterval"),
		_timeout = Config.number(config.acquireTimeout, 60, 15, 300, "sessions.acquireTimeout"),
		_nextFlush = runtime.now() + (config.flushInterval or 5),
		_retryAt = 0,
		_counter = 0,
		_leases = {},
		_schemaAt = {},
		_commit = nil,
		_busy = false,
		_closed = false,
		_kick = kick,
		LeaseLost = Signal.new(runtime),
		CommitRejected = Signal.new(runtime),
	}, Sessions)
end
--- Keep the existing batch clock armed for acquisition, renewal, retries and buffered writes.
function Sessions.hasWork(self: Sessions): boolean
	return not self._closed and next(self._leases) ~= nil
end
--- Name this server while it holds a granted lease for the player, whose outside changes then arrive in its inbox.
function Sessions.inboxServer(self: Sessions, universe: string, user: number): string?
	local lease = self._leases[universe .. ":" .. tostring(user)]
	if lease and lease.epoch and not lease.lost and not lease.closing then
		return self._server
	end
	return nil
end
--- Fence and discard all local writes on lost ownership, reporting before optional native kick.
function Sessions._lost(self: Sessions, lease: Lease, code: string)
	if lease.lost then
		return
	end
	lease.lost = true
	lease.error = code
	local profile = lease.profile
	if profile then
		table.clear(profile._buffer)
		profile._sent = {}
		profile._leaseReady = false
		profile._stale = true
		profile._optimisticRecovery = false
		profile:destroy()
	end
	self.LeaseLost:fire({ userId = lease.user, universeId = lease.universe, code = code })
	if self._config.kickOnLeaseLost ~= false then
		self._kick(lease.user, "Data session lost")
	end
end
--- Queue once per player; wait for the next shared tick and bounded held/transport backoff.
function Sessions.acquire(
	self: Sessions,
	universe: string,
	user: number,
	invoke: Core.Invoke,
	signal: Core.Signal
): Core.Result<Lease>
	if self._server == "" then
		self._server = Copy.key(self._runtime)
	end
	local key = universe .. ":" .. tostring(user)
	if self._closed then
		return System.failure("client_closed")
	end
	if self._leases[key] then
		return System.failure("profile_already_loaded")
	end
	local lease: Lease = {
		universe = universe,
		user = user,
		invoke = invoke,
		started = self._runtime.now(),
		nextAt = 0,
		expires = 0,
		busy = false,
		closing = false,
		lost = false,
	}
	self._leases[key] = lease
	if self.wake then
		self.wake()
	end
	while
		not lease.snapshot
		and not lease.error
		and not signal.cancelled
		and not lease.closing
		and not self._closed
		and self._runtime.now() - lease.started < self._timeout
	do
		self._runtime.wait(0.01)
	end
	if lease.snapshot and not lease.closing and not signal.cancelled and not self._closed then
		return { ok = true, value = lease }
	end
	local cancelled = signal.cancelled or lease.closing or self._closed
	lease.closing = true -- A late grant must be released rather than orphaned.
	if not lease.busy and not lease.epoch then
		self._leases[key] = nil
	end
	return System.failure(lease.error or (if cancelled then "profile_closed" else "session_acquire_timeout"))
end
--- Apply the configured load-failure policy after schema, acquire or snapshot validation fails.
function Sessions.loadFailure(self: Sessions, user: number)
	if not self._closed and self._config.kickOnFailure ~= false then
		self._kick(user, "Unable to load data session")
	end
end
--- Convert a validated server expiration to the injected monotonic clock.
local function expiration(self: Sessions, value: string?): number?
	local unix = if type(value) == "string" then Instant.unix(value) else nil
	return if unix then self._runtime.now() + unix - self._runtime.unix() else nil
end
--- Attach the only writable handle and bound its buffer to transport-safe sizes.
function Sessions.attach(self: Sessions, lease: Lease, profile: Profile.Profile)
	lease.profile = profile
	profile._leaseReady = true
	profile._releaseLease = function(deadline)
		lease.closing = true
		profile._leaseReady = false
		local key = lease.universe .. ":" .. tostring(lease.user)
		while self._leases[key] == lease and self._runtime.now() < deadline and not self._closed do
			self:tick(true)
			self._runtime.wait(0.05)
		end
		return self._leases[key] ~= lease and not self._closed
	end
	profile._admit = function(ops)
		if lease.closing or lease.lost or self._closed or self._runtime.now() >= lease.expires then
			return false
		end
		local combined = Copy.copy(profile._buffer)
		for _, op in ops do
			local previous = combined[#combined]
			-- Only adjacent ADDs with identical targets can be merged without reordering semantics.
			if
				previous
				and previous.op == "ADD"
				and op.op == "ADD"
				and previous.field == op.field
				and System.equal(previous.path or {}, op.path or {})
			then
				local delta = (previous.delta :: number) + (op.delta :: number)
				local merged = Copy.copy(previous)
				merged.delta = delta
				local valid = Operations.prepare(profile._schema, { merged })
				if math.abs(delta) <= 9007199254740991 and delta ~= 0 and valid.ok then
					previous.delta = delta
				else
					table.insert(combined, Copy.copy(op))
				end
			else
				table.insert(combined, Copy.copy(op))
			end
		end
		-- A single player's immutable payload must fit in an envelope with feed/control overhead.
		if #combined > 4000 or #Json.encode(combined) > 900000 then
			return false
		end
		profile._buffer = combined
		return true
	end
end
--- Re-sync after an acknowledgement; preserve writes admitted during the in-flight commit.
function Sessions._recover(self: Sessions, lease: Lease)
	local profile = lease.profile
	if not profile or profile._closed or lease.lost or profile._recovering then
		return
	end
	profile._recovering = true
	self._runtime.spawn(function()
		local options: Core.CallOptions = { retry = 0, cacheTtl = 0, signal = profile._signal }
		local result: Core.Result<any> = { ok = true, value = true }
		if lease.schemaRecoveryAt then
			while profile._schema._busy and not profile._closed and not self._closed do
				self._runtime.wait(0.01)
			end
			if (self._schemaAt[profile._schema] or -math.huge) < lease.schemaRecoveryAt then
				result = profile._schema:refresh(options)
				if result.ok then
					self._schemaAt[profile._schema] = self._runtime.now()
				end
			end
			if result.ok then
				lease.schemaRecoveryAt = nil
			end
		end
		if result.ok then
			result = profile:refresh(options)
		end
		profile._recovering = false
		profile._optimisticRecovery = false
		lease.needsRecovery = not result.ok
		if not result.ok then
			profile._stale = true
			profile.lastError = result.error
			lease.nextAt = self._runtime.now() + 5
		end
	end)
end
--- Validate full response identity before changing any lease or dropping any detached operations.
local function validCommit(self: Sessions, commit: Commit, response: Wire.CommitResponse): boolean
	if
		type(response) ~= "table"
		or type(response.items) ~= "table"
		or response.commitId ~= commit.body.commitId
		or #response.items ~= #commit.leases
	then
		return false
	end
	for i, item in response.items do
		if item.userId ~= commit.leases[i].user then
			return false
		end
		if item.status == "committed" then
			if
				type(item.seq) ~= "number"
				or item.seq < 0
				or item.seq % 1 ~= 0
				or item.seq > 9007199254740991
				or not item.versions
				or not expiration(self, item.expiresAt)
			then
				return false
			end
			for _, version in item.versions :: { [string]: number } do
				if
					type(version) ~= "number"
					or version < 0
					or version > 9007199254740991
					or version % 1 ~= 0
				then
					return false
				end
			end
		elseif item.status == "rejected" then
			if not item.error or type(item.error.code) ~= "string" then
				return false
			end
		elseif item.status ~= "lease_lost" then
			return false
		end
	end
	return true
end
--- Retry the exact detached request, never merging later writes into an ambiguous commit identity.
function Sessions._send(self: Sessions)
	local commit = self._commit
	if not commit or self._busy or commitInFlight or self._runtime.now() < self._retryAt then
		return
	end
	self._busy = true
	commitInFlight = true
	self._runtime.spawn(function()
		local signal: Core.Signal = { cancelled = false }
		local result = commit.invoke(
			Endpoints["fields.commitSession"],
			{ path = { universeId = commit.universe }, body = commit.body },
			{ retry = 0, signal = signal, priority = "critical" },
			commit.universe
		)
		-- Native HTTP cannot abort on timeout: no replacement commit until physical completion.
		while (signal.inFlight or 0) > 0 do
			self._runtime.wait(0.05)
		end
		self._busy = false
		commitInFlight = false
		if self._closed then
			return
		end
		if not result.ok or not validCommit(self, commit, result.value) then
			self._retryAt = self._runtime.now()
				+ math.max(0.5, if not result.ok then result.error.retryAfterSeconds or 0 else 0)
			return
		end
		for i, item in result.value.items do
			local lease = commit.leases[i]
			local profile = lease.profile
			if item.status == "lease_lost" then
				self:_lost(lease, "lease_lost")
			elseif profile and not lease.lost then
				profile._sent = {}
				profile._optimisticRecovery = item.status == "committed"
				if item.status == "committed" then
					lease.expires = expiration(self, item.expiresAt) :: number
					profile._snapshotFloor = math.max(profile._snapshotFloor, item.seq :: number)
					for field, version in item.versions :: { [string]: number } do
						profile._versionFloor[field] = math.max(profile._versionFloor[field] or 0, version)
					end
				else
					lease.schemaRecoveryAt = self._runtime.now()
					local err = item.error :: Wire.CommitError
					self.CommitRejected:fire({
						userId = lease.user,
						universeId = lease.universe,
						code = err.code,
						field = err.field,
					})
				end
				-- No authoritative values in a commit acknowledgement: snapshot before rebase.
				profile._stale = true
				lease.needsRecovery = true
				self:_recover(lease)
			end
		end
		self._commit = nil
		self._retryAt = 0
	end)
end
--- Detach at most 200 players/4000 ops into one immutable, body-limited server commit.
function Sessions._flush(self: Sessions, force: boolean)
	if self._commit then
		self:_send()
		return
	end
	local now = self._runtime.now()
	local due = force or now >= self._nextFlush
	for _, lease in self._leases do
		if lease.epoch and not lease.lost and (lease.closing or lease.expires - now <= 20) then
			due = true
		end
	end
	if not due then
		return
	end
	local commit: Commit? = nil
	local count = 0
	local keys: { string } = {}
	for key in self._leases do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in keys do
		local lease = self._leases[key]
		local profile = lease.profile
		if profile and lease.epoch and not lease.lost and #profile._buffer > 0 then
			if not commit then
				commitCounter += 1
				self._counter = commitCounter
				commit = {
					universe = lease.universe,
					invoke = lease.invoke,
					body = {
						serverId = self._server,
						commitId = self._server .. ":" .. tostring(self._counter),
						players = {},
					},
					leases = {},
				}
			end
			assert(commit ~= nil, "Missing commit")
			if
				commit.universe ~= lease.universe
				or commit.invoke ~= lease.invoke
				or #commit.leases >= 200
				or count + #profile._buffer > 4000
			then
				continue
			end
			local player: Wire.CommitPlayer =
				{ userId = lease.user, epoch = lease.epoch, ops = Json.array(Copy.copy(profile._buffer)) }
			table.insert(commit.body.players, player)
			if #Json.encode(commit.body) > 950000 then
				table.remove(commit.body.players)
				continue
			end
			table.insert(commit.leases, lease)
			count += #profile._buffer
			profile._sent = profile._buffer
			profile._buffer = {}
		end
	end
	if commit and #commit.leases > 0 then
		commit.body = Cache.freeze(commit.body)
		self._commit = commit
		self:_send()
	end
	self._nextFlush = now + self._interval
end
--- Send one bounded control group; different universes/auth providers are never combined.
function Sessions._control(self: Sessions, kind: string, leases: { Lease })
	if #leases == 0 then
		return
	end
	local first = leases[1]
	local body: any = { serverId = self._server }
	if kind == "acquireSessions" then
		body.ttlMs = self._ttl
		body.players = {}
		for _, lease in leases do
			table.insert(
				body.players,
				{ userId = lease.user, steal = self._runtime.now() - lease.started >= 15 }
			)
		end
	else
		body.leases = {}
		if kind == "renewSessions" then
			body.ttlMs = self._ttl
		end
		for _, lease in leases do
			table.insert(body.leases, { userId = lease.user, epoch = lease.epoch })
		end
	end
	for _, lease in leases do
		lease.busy = true
	end
	self._runtime.spawn(function()
		if kind == "releaseSessions" then
			for _, lease in leases do
				if lease.profile then
					lease.profile:stopPresence({ timeout = 2, priority = "critical" })
				end
			end
		end
		local signal: Core.Signal = { cancelled = false }
		local result = first.invoke(
			Endpoints["fields." .. kind],
			{ path = { universeId = first.universe }, body = body },
			{ retry = 0, priority = "critical", signal = signal },
			first.universe
		)
		while (signal.inFlight or 0) > 0 and not self._closed do
			self._runtime.wait(0.05)
		end
		local valid = result.ok
			and type(result.value) == "table"
			and type(result.value.items) == "table"
			and #result.value.items == #leases
		if valid and result.ok then
			for i, item in result.value.items do
				if item.userId ~= leases[i].user then
					valid = false
				end
			end
		end
		for i, lease in leases do
			lease.busy = false
			lease.nextAt = self._runtime.now()
				+ math.max(1, if not result.ok then result.error.retryAfterSeconds or 0 else 0)
			if
				lease.closing
				and not lease.epoch
				and (not valid or not result.ok or result.value.items[i].status ~= "granted")
			then
				self._leases[lease.universe .. ":" .. tostring(lease.user)] = nil
			end
			if not valid or not result.ok then
				continue
			end
			local item: Wire.SessionItem = result.value.items[i]
			if kind == "acquireSessions" then
				if
					item.status == "granted"
					and type(item.epoch) == "number"
					and item.epoch > 0
					and item.epoch <= 9007199254740991
					and item.epoch % 1 == 0
					and item.snapshot
					and expiration(self, item.expiresAt)
				then
					lease.nextAt = 0
					lease.epoch = item.epoch
					lease.snapshot = item.snapshot
					lease.expires = expiration(self, item.expiresAt) :: number
				elseif item.status == "held" then
					lease.nextAt = self._runtime.now() + math.max(0.5, (item.retryAfterMs or 5000) / 1000)
				end
			elseif kind == "releaseSessions" then
				if item.status == "released" or item.status == "lost" then
					lease.busy = true
					if lease.profile then
						lease.profile:destroy()
					end
					self._leases[lease.universe .. ":" .. tostring(lease.user)] = nil
				end
			elseif item.status == "lost" then
				self:_lost(lease, "lease_lost")
			elseif item.status == "renewed" and expiration(self, item.expiresAt) then
				lease.expires = expiration(self, item.expiresAt) :: number
			end
		end
	end)
end
--- Produce acquisition, renewal, flush and release operations on the existing 0.5-second tick.
function Sessions.tick(self: Sessions, force: boolean?)
	if self._closed then
		return
	end
	self:_flush(force == true)
	local groups: { { kind: string, leases: { Lease } } } = {}
	for _, lease in self._leases do
		local profile = lease.profile
		if lease.lost then
			self._leases[lease.universe .. ":" .. tostring(lease.user)] = nil
			continue
		end
		if
			profile
			and lease.needsRecovery
			and #profile._sent == 0
			and self._runtime.now() >= lease.nextAt
		then
			self:_recover(lease)
		end
		if lease.busy or self._runtime.now() < lease.nextAt then
			continue
		end
		local kind: string? = nil
		if not lease.epoch then
			if not lease.closing then
				kind = "acquireSessions"
			end
		elseif
			lease.closing
			and (not profile or #profile._sent == 0 and #profile._buffer == 0 and not profile._recovering)
		then
			kind = "releaseSessions"
		elseif lease.expires - self._runtime.now() <= 20 and (not profile or #profile._sent == 0) then
			kind = "renewSessions"
		end
		if not kind then
			continue
		end
		local selected: { kind: string, leases: { Lease } }? = nil
		for _, group in groups do
			if
				group.kind == kind
				and group.leases[1].universe == lease.universe
				and group.leases[1].invoke == lease.invoke
				and #group.leases < 200
			then
				selected = group
				break
			end
		end
		if not selected then
			local created = { kind = kind, leases = {} :: { Lease } }
			selected = created
			table.insert(groups, created)
		end
		assert(selected ~= nil, "Missing control group")
		table.insert(selected.leases, lease)
	end
	for _, group in groups do
		self:_control(group.kind, group.leases)
	end
end
--- Mark a manually destroyed handle for ordered flush/release on the shared clock.
function Sessions.releaseProfile(self: Sessions, profile: Profile.Profile)
	for _, lease in self._leases do
		if lease.profile == profile then
			lease.closing = true
		end
	end
	if self.wake then
		self.wake()
	end
end
--- Stop mutation admission immediately; flush ordering is retained even when a commit is in flight.
function Sessions.removePlayer(self: Sessions, user: number)
	for _, lease in self._leases do
		if lease.user == user then
			lease.closing = true
			if lease.profile then
				lease.profile._leaseReady = false
			end
		end
	end
	self:tick(true)
end
--- Drain all admitted writes before release, retaining ambiguous commits when the deadline expires.
function Sessions.close(self: Sessions, deadline: number): boolean
	for _, lease in self._leases do
		lease.closing = true
		if lease.profile then
			lease.profile._leaseReady = false
		end
	end
	while next(self._leases) and self._runtime.now() < deadline do
		self:tick(true)
		self._runtime.wait(0.05)
	end
	return next(self._leases) == nil and self._commit == nil
end
--- Stop producers without making network calls; destroy is explicitly not a save operation.
function Sessions.destroy(self: Sessions)
	self._closed = true
	for _, lease in self._leases do
		if lease.profile then
			lease.profile._leaseReady = false
		end
	end
	table.clear(self._leases)
	self.LeaseLost:destroy()
	self.CommitRejected:destroy()
end
return table.freeze(Sessions)
