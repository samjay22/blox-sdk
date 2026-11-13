--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
-- Reject LocalScript requires before resolving credentials or allocating any SDK state.
if game ~= nil then
	assert(game:GetService("RunService"):IsServer(), "BloxSDK is server-only")
end
local Types = require(script.Types.Core)
local AuthTypes = require(script.Types.Auth)
local Profile = require(script.Fields.Profile)
local Transaction = require(script.Fields.Transaction)
local Schema = require(script.Fields.Schema)
local Rotations = require(script.Fields.Rotations)
local Operations = require(script.Fields.OpBuilder)
local Jobs = require(script.Fields.Jobs)
local Schedules = require(script.Fields.Schedules)
local Bulk = require(script.Fields.Bulk)
local Health = require(script.Fields.Health)
local Config = require(script.Core.Config)
local Pipeline = require(script.Core.Pipeline)
local Batcher = require(script.Core.Batcher)
local Roblox = require(script.Core.Roblox)
local Bucket = require(script.Core.TokenBucket)
local Errors = require(script.Core.Errors)
local Cache = require(script.Core.Cache)
local Endpoints = require(script.Core.Endpoints)
local Json = require(script.Core.Json)
local Pagination = require(script.Core.Pagination)
local ServiceAccount = require(script.Auth.ServiceAccount)
local UserSession = require(script.Auth.UserSession)
local ScopedTokens = require(script.Auth.ScopedTokens)
local Auth = require(script.Services.Auth)
local Matchmaking = require(script.Services.Matchmaking)
local Party = require(script.Services.Party)
local Codes = require(script.Services.Codes)
local Audit = require(script.Services.Audit)
local Leaderboards = require(script.Services.Leaderboards)
local Fields = require(script.Services.Fields)
local Platform = require(script.Services.Platform)
local ConfigService = require(script.Services.Config)
local NamespaceModule = require(script.Configs.Namespace)
local FieldsHelpers = require(script.Fields.Client)
local ProfileSync = require(script.Fields.ProfileSync)
local Sessions = require(script.Fields.Sessions)
local SessionSignal = require(script.Fields.SessionSignal)
local ChangeSignal = require(script.Core.ChangeSignal)
local Observers = require(script.Core.Observers)
local AuditWriter = require(script.Core.AuditWriter)
local SnapshotCache = require(script.Core.SnapshotCache)
local Universe = require(script.Core.Universe)
local SDK = {}
local Client = {}
Client.__index = Client
export type Config = Config.Config
export type CallOptions = Types.CallOptions
export type Result<T> = Types.Result<T>
export type BloxError = Types.BloxError
export type ErrorKind = Types.ErrorKind
export type Json = Types.Json
export type Environment = Types.Environment
export type Signal = Types.Signal
export type Logger = Types.Logger
export type Hooks = Types.Hooks
export type Runtime = Types.Runtime
export type Backend = Types.Backend
export type AuthProvider = Types.AuthProvider
export type AuthClient = Auth.Service
export type FieldsClient = Fields.Service
export type CodesClient = Codes.Service
export type CodeOutcome = Codes.Outcome
export type CodeReward = Codes.Reward
export type CodeAward = Codes.Award
export type PartyClient = Party.Service
export type MatchmakingClient = Matchmaking.Service
export type LeaderboardsClient = Leaderboards.Service
export type AuditClient = Audit.Service
export type PlatformClient = Platform.Service
export type ConfigsClient = ConfigService.Service
export type ConfigNamespace = NamespaceModule.Namespace
export type ConfigChange = NamespaceModule.Change
export type ConfigSnapshot = NamespaceModule.Snapshot
export type ConfigPollOptions = NamespaceModule.Options
export type ConfigWriteOptions = NamespaceModule.WriteOptions
export type ConfigChanges = NamespaceModule.Changes
export type ConfigsConfig = Config.ConfigsConfig
export type Snapshot = SnapshotCache.Snapshot
export type AuditWriter = AuditWriter.Writer
export type Metrics = Pipeline.Counters
export type HealthReport = { [string]: { result: Types.Result<Types.Json>, latency: number } }
export type ProfileChange = ChangeSignal.Change
export type ProfileChangeConnection = ChangeSignal.Connection
export type ProfileSyncConfig = Config.ProfileSyncConfig
export type SessionConfig = Config.SessionConfig
export type SessionEvent = SessionSignal.Change
export type Profile = Profile.Profile
export type Transaction = Transaction.Transaction
export type SchemaCache = Schema.Schema
export type RotationsClient = Rotations.Client
export type RotationWatch = Rotations.Watch
export type RotationItem = Rotations.Item
export type RotationPeriod = Rotations.Period
export type RotationCurrent = Rotations.Current
export type OperationsBuilder = Operations.Builder
export type JobsClient = Jobs.Client
export type SchedulesClient = Schedules.Client
export type BulkBuilder = Bulk.Builder
export type FieldsHealthClient = Health.Client
export type AuditWriterOptions = AuditWriter.Options
export type SnapshotConnection = SnapshotCache.Connection
export type TokenStore = UserSession.TokenStore
export type ManagedSession = UserSession.Session
export type Secret = Types.Secret
export type Headers = Types.Headers
export type HttpRequest = Types.HttpRequest
export type HttpResponse = Types.HttpResponse
type ScopeBinding = {
	provider: ScopedTokens.Provider,
	invoke: Types.Invoke,
	fields: FieldsHelpers.State,
}
type Helpers = {
	sync: ProfileSync.Sync,
	sessions: Sessions.Sessions,
	addedCleanup: (() -> ())?,
	writers: { AuditWriter.Writer },
	snapshots: { SnapshotCache.Snapshot },
	configs: { [string]: NamespaceModule.Namespace },
	configDefaults: Config.ConfigsConfig?,
	fields: FieldsHelpers.State?,
	fieldStates: { FieldsHelpers.State },
	scopes: { [string]: ScopeBinding },
	lifecycle: { native: boolean, bound: boolean },
}
export type Client = typeof(setmetatable(
	{} :: {
		environment: Types.Environment?,
		ProfileChanged: ChangeSignal.Signal,
		LeaseLost: SessionSignal.Signal,
		CommitRejected: SessionSignal.Signal,
		auth: Auth.Service,
		matchmaking: Matchmaking.Service,
		party: Party.Service,
		codes: Codes.Service,
		audit: Audit.Service,
		leaderboards: Leaderboards.Service,
		fields: Fields.Service,
		platform: Platform.Service,
		configs: ConfigService.Service,
		_helpers: Helpers,
		_state: Pipeline.State,
		_invoke: Types.Invoke,
		_session: UserSession.Session?,
		_provider: Types.AuthProvider?,
	},
	Client
))
local serverBucket: Bucket.Bucket? = nil
--- Validate the untyped invocation boundary before entering the shared pipeline.
local function requestValue(value: unknown): Types.Request?
	if type(value) ~= "table" then
		return nil
	end
	local t = value :: { [string]: unknown }
	if t.path ~= nil and type(t.path) ~= "table" then
		return nil
	end
	if t.query ~= nil and type(t.query) ~= "table" then
		return nil
	end
	return value :: Types.Request
end
--- Construct a facade without duplicating auth, cache, queues, breakers or rate budgets.
local function facade(
	state: Pipeline.State,
	invoke: Types.Invoke,
	universe: (string | number)?,
	session: UserSession.Session?,
	helpers: Helpers,
	provider: Types.AuthProvider?
): Client
	local created: Client? = nil
	local host: ConfigService.Host = {
		runtime = state.config.runtime,
		handles = helpers.configs,
		defaults = helpers.configDefaults,
		closing = function(): boolean
			return state.closing or state.destroyed
		end,
		onUse = function()
			if helpers.lifecycle.native and not helpers.lifecycle.bound then
				helpers.lifecycle.bound = true
				Roblox.bindToClose(function()
					local current = created
					if current then
						current:flush(20)
						current:destroy()
					end
				end)
			end
		end,
	}
	local client: Client = setmetatable({
		environment = (provider or state.config.auth).environment,
		ProfileChanged = helpers.sync.Changed,
		LeaseLost = helpers.sessions.LeaseLost,
		CommitRejected = helpers.sessions.CommitRejected,
		_state = state,
		_helpers = helpers,
		_invoke = invoke,
		_session = session,
		_provider = provider,
		auth = Auth.new(invoke, universe),
		matchmaking = Matchmaking.new(invoke, universe),
		party = Party.new(invoke, universe),
		codes = Codes.new(invoke, universe, helpers.fields),
		audit = Audit.new(invoke, universe),
		leaderboards = Leaderboards.new(invoke, universe),
		fields = Fields.new(invoke, universe, helpers.fields),
		platform = Platform.new(invoke, universe),
		configs = ConfigService.new(invoke, universe, host),
	}, Client)
	created = client
	if helpers.fields then
		-- Profiles read item lists through the same shared handles as `client.configs`.
		helpers.fields.itemList = function(universeId, source)
			return ConfigService.new(invoke, universeId, host):namespace(source)
		end
	end
	return client
end
--- Refuse a prod key in Roblox Studio unless the developer opted in; dev keys work anywhere.
local function guardStudio(environment: Types.Environment?, config: Config.Config)
	if environment ~= "prod" or config.allowProdInStudio == true then
		return
	end
	-- Injected runtimes are offline/test clients: only an explicit isStudio can make them Studio.
	local studio = if config.isStudio
		then config.isStudio()
		elseif config.runtime then false
		else Roblox.isStudio()
	if studio then
		error(
			Errors.prodKeyInStudio
				.. ": a prod (bsa_) key is not used in Roblox Studio; use a dev (bsd_) key or pass allowProdInStudio = true",
			0
		)
	end
end
--- Create one server-side SDK client; invalid configuration fails before any network activity.
function SDK.new(config: Config): Client
	if game ~= nil then
		assert(game:GetService("RunService"):IsServer(), "BloxSDK is server-only")
	end
	assert(type(config) == "table", "BloxSDK.new requires a config table")
	Config.validate(config)
	local origins = Config.resolve(config)
	local choices = (if config.key then 1 else 0)
		+ (if config.secretName then 1 else 0)
		+ (if config.authProvider then 1 else 0)
		+ (if config.userSession then 1 else 0)
	assert(choices <= 1, "Choose at most one auth mechanism")
	local http: Roblox.HttpService? = nil
	if not config.runtime or not config.backend or config.secretName then
		http = Roblox.httpService()
	end
	local runtime = config.runtime or Roblox.runtime(http :: Roblox.HttpService)
	local backend = config.backend or Roblox.backend(http :: Roblox.HttpService)
	local auth: Types.AuthProvider
	local session: UserSession.Session? = nil
	-- The universe is stated once here; on Roblox it defaults to the running experience.
	local universeId: (string | number)? = config.universeId
	if universeId == nil and config.runtime == nil then
		universeId = Roblox.universe()
	end
	if config.key or config.secretName then
		assert(universeId ~= nil, "Service accounts require universeId")
		-- Studio protection runs before the secret is fetched or any request exists.
		guardStudio(if config.key then ServiceAccount.environment(config.key) else config.environment, config)
		local key: string | Types.Secret = config.key
			or (http :: Roblox.HttpService):GetSecret(config.secretName :: string)
		auth = ServiceAccount.new(key, universeId, config.levels, config.environment)
	elseif config.userSession then
		session = UserSession.new(runtime, config.userSession.store, config.userSession.role)
		auth = session :: UserSession.Session
	elseif config.authProvider then
		auth = config.authProvider
		guardStudio(auth.environment, config)
	else
		auth = {
			kind = "none",
			apply = function(_headers: Types.Headers) end,
			onUnauthorized = function(_version: number?): boolean
				return false
			end,
		}
	end
	local rpm = Config.number(config.requestsPerMinute, 450, 1, 480, "requestsPerMinute", true)
	local burst = Config.number(config.burst, 15, 1, 500, "burst")
	local reserve =
		Config.number(config.criticalReserve, math.min(3, burst - 1), 0, burst - 1, "criticalReserve")
	if not config.runtime and not serverBucket then
		serverBucket = Bucket.new(burst, rpm / 60, reserve, runtime.now())
	end
	local syncOptions: Config.ProfileSyncConfig = config.profileSync or {}
	local threshold = Config.number(syncOptions.budgetThreshold, 0.8, 0.01, 1, "profileSync.budgetThreshold")
	Config.number(config.concurrency, 1, 1, 100, "concurrency", true)
	local state = Pipeline.new({
		batchInterval = Config.number(
			if config.batch then config.batch.intervalSeconds else nil,
			0.5,
			0.25,
			300,
			"batch.intervalSeconds"
		),
		batchUrl = origins.fields .. "/batch-service/api/batch",
		runtime = runtime,
		backend = backend,
		auth = auth,
		origins = origins,
		queueCapacity = Config.number(config.queueCapacity, 10000, 0, 10000, "queueCapacity", true),
		requestsPerMinute = rpm,
		burst = burst,
		criticalReserve = reserve,
		retries = Config.number(config.retries, 3, 0, 10, "retries", true),
		retryRatio = Config.number(config.retryRatio, 0.2, 0, 1, "retryRatio"),
		timeout = Config.number(config.timeout, 15, 0.01, 300, "timeout"),
		cacheCapacity = Config.number(config.cacheCapacity, 128, 0, 10000, "cacheCapacity", true),
		staleIfError = Config.number(config.staleIfError, 0, 0, 3600, "staleIfError"),
		hooks = Observers.new(config.hooks, config.logger),
		sharedBucket = if not config.runtime then serverBucket else nil,
	})
	local invoke: Types.Invoke = function(
		spec: Types.Endpoint,
		value: unknown,
		opts: Types.CallOptions?,
		universe: (string | number)?
	): Types.Result<any>
		local request = requestValue(value)
		if not request then
			return Errors.make("Validation", spec.id, 0, "Invalid request structure")
		end
		local result = Pipeline.call(state, spec, request, opts, universe)
		if session and spec.service == "auth" then
			if spec.id == "auth.login" and result.ok then
				session.accept(result.value)
			elseif spec.id == "auth.logout" then
				session.clear()
			end
		end
		return result
	end
	if session then
		session.bind(function(action: string, body: unknown): Types.Result<any>
			return invoke(Endpoints["auth." .. action], { body = body }, { priority = "critical" }, nil)
		end)
	end
	local sync = ProfileSync.new(runtime, config.profileSync, function()
		return Bucket.used(state.bucket, runtime.now()) < state.bucket.limit * threshold and not state.closing
	end)
	local sessions = Sessions.new(
		runtime,
		config.sessions,
		if game ~= nil then game.JobId or "" else "",
		function(userId, message)
			if not config.runtime then
				Roblox.kick(userId, message)
			end
		end
	)
	sync.inbox = function(universe: string, userId: number): string?
		return sessions:inboxServer(universe, userId)
	end
	state.batcher.beforeTick = function()
		sessions:tick()
		sync:tick()
	end
	state.batcher.hasPoll = function()
		return sync:hasProfiles() or sessions:hasWork()
	end
	sessions.wake = function()
		Batcher.wake(state.batcher)
	end
	sync.wake = function()
		Batcher.wake(state.batcher)
	end
	local helpers: Helpers = {
		sync = sync,
		sessions = sessions,
		addedCleanup = nil,
		writers = {},
		snapshots = {},
		configs = {},
		configDefaults = config.configs,
		fields = nil,
		fieldStates = {},
		scopes = {},
		lifecycle = { native = config.runtime == nil, bound = false },
	}
	local client: Client? = nil
	helpers.fields = FieldsHelpers.new(runtime, invoke, function()
		if helpers.lifecycle.native and not sync.cleanup then
			sync.cleanup = Roblox.playerRemoving(function(userId)
				sync:cancelLoads(userId)
				sessions:removePlayer(userId)
			end)
		end
		if helpers.lifecycle.native and not helpers.lifecycle.bound then
			helpers.lifecycle.bound = true
			Roblox.bindToClose(function()
				local current = client
				if current then
					current:flush(20)
					current:destroy()
				end
			end)
		end
	end, sync, sessions)
	table.insert(helpers.fieldStates, helpers.fields :: FieldsHelpers.State)
	client = facade(state, invoke, universeId or auth.universeId, session, helpers)
	if helpers.lifecycle.native and universeId then
		local universe = universeId
		helpers.addedCleanup = Roblox.playerAdded(function(userId)
			runtime.spawn(function()
				FieldsHelpers.loadProfile(helpers.fields :: FieldsHelpers.State, universe, userId)
			end)
		end)
	end
	return client :: Client
end
--- Return another scoped facade over the same physical resource and credential lifetime.
function Client.withUniverse(self: Client, id: string | number): Client
	assert(Universe.valid(id), "Invalid universeId")
	local scoped = (self._provider or self._state.config.auth).universeId
	assert(scoped == nil or tostring(scoped) == tostring(id), "Service account is scoped to one universe")
	return facade(self._state, self._invoke, id, self._session, self._helpers, self._provider)
end
--- Bind downstream calls to a cached scoped JWT; retain the root client for identity management.
function Client.scoped(self: Client, id: string | number): Client
	assert(Universe.valid(id), "Invalid universeId")
	assert(self._provider == nil and self._session ~= nil, "Requires a managed identity client")
	assert(not self._state.closing, "Client is closing")
	local key = tostring(id)
	local binding = self._helpers.scopes[key]
	if not binding then
		local provider = ScopedTokens.new(
			self._state.config.runtime,
			self._session :: UserSession.Session,
			id,
			function()
				return self.auth:exchangeScopedToken({ path = { universe = id } }, { priority = "critical" })
			end
		)
		local invoke: Types.Invoke = function(spec, value, opts, universe)
			local request = requestValue(value)
			if not request then
				return Errors.make("Validation", spec.id, 0, "Invalid request structure")
			end
			return Pipeline.call(self._state, spec, request, opts, universe, provider)
		end
		local fields = FieldsHelpers.new(self._state.config.runtime, invoke, function()
			if self._helpers.lifecycle.native and not self._helpers.sync.cleanup then
				self._helpers.sync.cleanup = Roblox.playerRemoving(function(userId)
					self._helpers.sync:cancelLoads(userId)
					self._helpers.sessions:removePlayer(userId)
				end)
			end
			if self._helpers.lifecycle.native and not self._helpers.lifecycle.bound then
				self._helpers.lifecycle.bound = true
				Roblox.bindToClose(function()
					self:flush(20)
					self:destroy()
				end)
			end
		end, self._helpers.sync, self._helpers.sessions)
		binding = { provider = provider, invoke = invoke, fields = fields }
		self._helpers.scopes[key] = binding
		table.insert(self._helpers.fieldStates, fields)
	end
	local helpers = table.clone(self._helpers)
	helpers.fields = binding.fields
	return facade(self._state, binding.invoke, id, self._session, helpers, binding.provider)
end
--- Check every service health route, returning individual status and monotonic latency.
function Client.health(self: Client): HealthReport
	local results: HealthReport = {}
	local runtime = self._state.config.runtime
	local services =
		{ "auth", "matchmaking", "party", "codes", "audit", "leaderboards", "fields", "platform", "config" }
	for _, service in services do
		runtime.spawn(function()
			local start = runtime.now()
			local result = self._invoke(
				Endpoints[service .. ".healthProxy"],
				{},
				{ priority = "critical" },
				nil
			)
			results[service] = { result = result, latency = runtime.now() - start }
		end)
	end
	while true do
		local count = 0
		for _ in results do
			count += 1
		end
		if count == #services then
			break
		end
		runtime.wait(0.01)
	end
	return results
end
--- Log out with the latest rotated refresh token; clear local credentials even on server failure.
function Client.logout(self: Client): Types.Result<AuthTypes.LogoutResultValue>
	local session = self._session
	if not session then
		return Errors.make("Local", "auth.logout", 0, "Client has no managed user session")
	end
	return session.logout()
end
--- Snapshot counters and non-cumulative latency buckets without exposing mutable internal state.
function Client.metrics(self: Client): Metrics
	local result = table.clone(self._state.counters)
	result.latency = table.clone(result.latency)
	return Cache.freeze(result)
end
--- Stop admission and drain; returns false when the finite shutdown budget expires.
function Client.flush(self: Client, timeout: number?): boolean
	local runtime = self._state.config.runtime
	local deadline = runtime.now() + Config.number(timeout, 10, 0, 300, "flush timeout")
	if self._helpers.addedCleanup then
		self._helpers.addedCleanup()
		self._helpers.addedCleanup = nil
	end
	local drained = self._helpers.sessions:close(deadline)
	self._helpers.sessions:destroy()
	self._helpers.sync:destroy()
	for _, fields in self._helpers.fieldStates do
		drained = FieldsHelpers.close(fields, deadline) and drained
	end
	for _, snapshot in self._helpers.snapshots do
		snapshot:destroy()
	end
	for _, handle in table.clone(self._helpers.configs) do
		handle:destroy()
	end
	for _, writer in self._helpers.writers do
		if not writer:close(math.max(0, deadline - runtime.now())) then
			drained = false
		end
	end
	return Pipeline.flush(self._state, math.max(0, deadline - runtime.now())) and drained
end
--- Idempotently terminate the client and all universe facades.
function Client.destroy(self: Client)
	if self._state.destroyed then
		return
	end
	if self._helpers.addedCleanup then
		self._helpers.addedCleanup()
		self._helpers.addedCleanup = nil
	end
	self._helpers.sessions:destroy()
	self._helpers.sync:destroy()
	for _, writer in self._helpers.writers do
		writer:destroy()
	end
	for _, snapshot in self._helpers.snapshots do
		snapshot:destroy()
	end
	for _, handle in table.clone(self._helpers.configs) do
		handle:destroy()
	end
	for _, fields in self._helpers.fieldStates do
		FieldsHelpers.destroy(fields)
	end
	Pipeline.destroy(self._state)
	for _, binding in self._helpers.scopes do
		if binding.provider.destroy then
			binding.provider.destroy()
		end
	end
	local destroy = self._state.config.auth.destroy
	if destroy then
		destroy()
	end
end
--- Create a nonblocking audit queue owned by this client; native Roblox clients bind shutdown once.
function Client.auditWriter(self: Client, options: AuditWriter.Options?): AuditWriter.Writer
	assert(not self._state.closing, "Client is closing")
	local writer = AuditWriter.new(self._state.config.runtime, function(events, opts)
		return self.audit:batch({ events = events }, opts)
	end, options)
	table.insert(self._helpers.writers, writer)
	if self._helpers.lifecycle.native and not self._helpers.lifecycle.bound then
		self._helpers.lifecycle.bound = true
		Roblox.bindToClose(function()
			self:flush(20)
			self:destroy()
		end)
	end
	return writer
end
--- Start a fault-tolerant snapshot poller, scoped to this facade and owned by the shared lifetime.
function Client.runtimeSnapshot(self: Client, interval: number?): SnapshotCache.Snapshot
	assert(not self._state.closing, "Client is closing")
	local fields = assert(self._helpers.fields, "Fields helpers unavailable")
	local universe = tostring(self.fields._universe)
	local existing = fields.snapshots[universe]
	if existing and not existing:isDestroyed() then
		return existing
	end
	local snapshot = SnapshotCache.new(
		self._state.config.runtime,
		function(etag, opts)
			return self.fields:runtimeSnapshot({ etag = etag }, opts)
		end,
		interval,
		function()
			FieldsHelpers.setSnapshot(fields, universe, nil)
		end
	)
	FieldsHelpers.setSnapshot(fields, universe, snapshot)
	table.insert(self._helpers.snapshots, snapshot)
	return snapshot
end
SDK.version = "9.0.0"
SDK.serviceAccount = ServiceAccount.new
SDK.userSession = UserSession.new
SDK.memoryTokenStore = UserSession.memoryStore
SDK.null = Json.null
SDK.array = Json.array
SDK.object = Json.object
SDK.pages = Pagination.new
SDK.cursorPages = Pagination.cursor
return table.freeze(SDK)
