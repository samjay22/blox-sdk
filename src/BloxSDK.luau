--!strict
local Types = require("./Types/Core")
local Config = require("./Core/Config")
local Pipeline = require("./Core/Pipeline")
local Roblox = require("./Core/Roblox")
local Bucket = require("./Core/TokenBucket")
local Errors = require("./Core/Errors")
local Cache = require("./Core/Cache")
local Endpoints = require("./Core/Endpoints")
local Json = require("./Core/Json")
local Pagination = require("./Core/Pagination")
local ServiceAccount = require("./Auth/ServiceAccount")
local UserSession = require("./Auth/UserSession")
local FakeBackend = require("./Testing/FakeBackend")
local Auth = require("./Services/Auth")
local Data = require("./Services/Data")
local Matchmaking = require("./Services/Matchmaking")
local Party = require("./Services/Party")
local Codes = require("./Services/Codes")
local Audit = require("./Services/Audit")
local ConfigService = require("./Services/Config")
local Leaderboards = require("./Services/Leaderboards")
local Economy = require("./Services/Economy")
local AuditWriter = require("./Core/AuditWriter")
local SnapshotCache = require("./Core/SnapshotCache")
local Universe = require("./Core/Universe")
local SDK = {}
local Client = {}
Client.__index = Client
export type Config = Config.Config
export type CallOptions = Types.CallOptions
export type Result<T> = Types.Result<T>
type Helpers = {
	writers: { AuditWriter.Writer },
	snapshots: { SnapshotCache.Snapshot },
	native: boolean,
	bound: boolean,
}
export type Client = typeof(setmetatable(
	{} :: {
		auth: Auth.Service,
		data: Data.Service,
		matchmaking: Matchmaking.Service,
		party: Party.Service,
		codes: Codes.Service,
		audit: Audit.Service,
		config: ConfigService.Service,
		leaderboards: Leaderboards.Service,
		economy: Economy.Service,
		_helpers: Helpers,
		_state: Pipeline.State,
		_invoke: Types.Invoke,
		_session: UserSession.Session?,
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
	helpers: Helpers
): Client
	return setmetatable({
		_state = state,
		_helpers = helpers,
		_invoke = invoke,
		_session = session,
		auth = Auth.new(invoke, universe),
		data = Data.new(invoke, universe),
		matchmaking = Matchmaking.new(invoke, universe),
		party = Party.new(invoke, universe),
		codes = Codes.new(invoke, universe),
		audit = Audit.new(invoke, universe),
		config = ConfigService.new(invoke, universe),
		leaderboards = Leaderboards.new(invoke, universe),
		economy = Economy.new(invoke, universe),
	}, Client)
end
--- Create one server-side SDK client; invalid configuration fails before any network activity.
function SDK.new(config: Config): Client
	assert(type(config) == "table", "BloxSDK.new requires a config table")
	Config.validate(config)
	local origins, baseUrls = Config.resolve(config)
	local choices = (if config.key then 1 else 0)
		+ (if config.secretName then 1 else 0)
		+ (if config.authProvider then 1 else 0)
		+ (if config.userSession then 1 else 0)
	assert(choices <= 1, "Choose exactly one auth mechanism")
	local http: Roblox.HttpService? = nil
	if not config.runtime or not config.backend or config.secretName then
		http = Roblox.httpService()
	end
	local runtime = config.runtime or Roblox.runtime(http :: Roblox.HttpService)
	local backend = config.backend or Roblox.backend(http :: Roblox.HttpService)
	local auth: Types.AuthProvider
	local session: UserSession.Session? = nil
	if config.key or config.secretName then
		assert(config.universeId ~= nil, "Service accounts require universeId")
		local key: string | Types.Secret = config.key
			or (http :: Roblox.HttpService):GetSecret(config.secretName :: string)
		auth = ServiceAccount.new(key, config.universeId, config.levels)
	elseif config.userSession then
		session = UserSession.new(runtime, config.userSession.store, config.userSession.role)
		auth = session :: UserSession.Session
	elseif config.authProvider then
		auth = config.authProvider
	else
		auth = {
			kind = "none",
			apply = function(_headers: Types.Headers) end,
			onUnauthorized = function(_version: number?): boolean
				return false
			end,
		}
	end
	local rpm = Config.number(config.requestsPerMinute, 450, 1, 500, "requestsPerMinute")
	local burst = Config.number(config.burst, 15, 1, 500, "burst")
	local reserve =
		Config.number(config.criticalReserve, math.min(3, burst - 1), 0, burst - 1, "criticalReserve")
	if not config.runtime and not serverBucket then
		serverBucket = Bucket.new(burst, rpm / 60, reserve, runtime.now())
	end
	local state = Pipeline.new({
		runtime = runtime,
		backend = backend,
		auth = auth,
		origins = origins,
		baseUrls = baseUrls,
		concurrency = Config.number(config.concurrency, 6, 1, 100, "concurrency", true),
		queueCapacity = Config.number(config.queueCapacity, 64, 0, 10000, "queueCapacity", true),
		requestsPerMinute = rpm,
		burst = burst,
		criticalReserve = reserve,
		retries = Config.number(config.retries, 3, 0, 10, "retries", true),
		retryRatio = Config.number(config.retryRatio, 0.2, 0, 1, "retryRatio"),
		timeout = Config.number(config.timeout, 15, 0.01, 300, "timeout"),
		cacheCapacity = Config.number(config.cacheCapacity, 128, 0, 10000, "cacheCapacity", true),
		staleIfError = Config.number(config.staleIfError, 0, 0, 3600, "staleIfError"),
		hooks = config.hooks,
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
	return facade(
		state,
		invoke,
		config.universeId or auth.universeId,
		session,
		{ writers = {}, snapshots = {}, native = config.runtime == nil, bound = false }
	)
end
--- Return another scoped facade over the same physical resource and credential lifetime.
function Client.withUniverse(self: Client, id: string | number): Client
	assert(Universe.valid(id), "Invalid universeId")
	local scoped = self._state.config.auth.universeId
	assert(scoped == nil or tostring(scoped) == tostring(id), "Service account is scoped to one universe")
	return facade(self._state, self._invoke, id, self._session, self._helpers)
end
--- Check every service health route, returning individual status and monotonic latency.
function Client.health(self: Client): { [string]: { result: Types.Result<any>, latency: number } }
	local results: { [string]: { result: Types.Result<any>, latency: number } } = {}
	local runtime = self._state.config.runtime
	for _, service in
		{ "auth", "data", "matchmaking", "party", "codes", "audit", "config", "leaderboards", "economy" }
	do
		local start = runtime.now()
		local result = self._invoke(Endpoints[service .. ".healthProxy"], {}, { priority = "critical" }, nil)
		results[service] = { result = result, latency = runtime.now() - start }
	end
	return results
end
--- Log out with the latest rotated refresh token; clear local credentials even on server failure.
function Client.logout(self: Client): Types.Result<any>
	local session = self._session
	if not session then
		return Errors.make("Local", "auth.logout", 0, "Client has no managed user session")
	end
	return session.logout()
end
--- Snapshot counters and non-cumulative latency buckets without exposing mutable internal state.
function Client.metrics(self: Client): Pipeline.Counters
	local result = table.clone(self._state.counters)
	result.latency = table.clone(result.latency)
	return Cache.freeze(result)
end
--- Stop admission and drain; returns false when the finite shutdown budget expires.
function Client.flush(self: Client, timeout: number?): boolean
	local runtime = self._state.config.runtime
	local deadline = runtime.now() + Config.number(timeout, 10, 0, 300, "flush timeout")
	local drained = true
	for _, snapshot in self._helpers.snapshots do
		snapshot:Destroy()
	end
	for _, writer in self._helpers.writers do
		if not writer:Close(math.max(0, deadline - runtime.now())) then
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
	for _, writer in self._helpers.writers do
		writer:Destroy()
	end
	for _, snapshot in self._helpers.snapshots do
		snapshot:Destroy()
	end
	Pipeline.destroy(self._state)
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
	if self._helpers.native and not self._helpers.bound then
		self._helpers.bound = true
		Roblox.bindToClose(function()
			self:flush(20)
			self:destroy()
		end)
	end
	return writer
end
--- Start a fault-tolerant snapshot poller, scoped to this facade and owned by the shared lifetime.
function Client.configSnapshot(self: Client, interval: number?): SnapshotCache.Snapshot
	assert(not self._state.closing, "Client is closing")
	local snapshot = SnapshotCache.new(self._state.config.runtime, function(version, opts)
		return self.config:snapshot({ version = version }, opts)
	end, interval)
	table.insert(self._helpers.snapshots, snapshot)
	return snapshot
end
SDK.Auth = table.freeze({
	serviceAccount = ServiceAccount.new,
	userSession = UserSession.new,
	memoryTokenStore = UserSession.memoryStore,
})
SDK.Testing = table.freeze({ fakeBackend = FakeBackend.new })
SDK.endpoints = Endpoints
SDK.null = Json.null
SDK.array = Json.array
SDK.pages = Pagination.new
SDK.cursorPages = Pagination.cursor
return table.freeze(SDK)
