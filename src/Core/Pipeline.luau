--!strict
--!native
--!optimize 2
local Types = require("../Types/Core")
local Errors = require("./Errors")
local Path = require("./Path")
local Access = require("./Access")
local Bucket = require("./TokenBucket")
local Gate = require("./Gate")
local Breaker = require("./Breaker")
local Retry = require("./Retry")
local Transport = require("./Transport")
local Cache = require("./Cache")
local Validation = require("./Validation")
local Options = require("./CallOptions")
local Idempotency = require("./Idempotency")
local Universe = require("./Universe")
local Pipeline = {}
local latencyBounds = table.freeze({ 0.05, 0.1, 0.25, 0.5, 1 })
export type Config = {
	runtime: Types.Runtime,
	backend: Types.Backend,
	auth: Types.AuthProvider,
	origins: { [string]: string },
	baseUrls: { [string]: string },
	concurrency: number,
	queueCapacity: number,
	requestsPerMinute: number,
	burst: number,
	criticalReserve: number,
	retries: number,
	retryRatio: number,
	timeout: number,
	cacheCapacity: number,
	staleIfError: number,
	hooks: Types.Hooks?,
	sharedBucket: Bucket.Bucket?,
}
export type Host = { gate: Gate.State, breaker: Breaker.State }
export type Flight = { result: Types.Result<any>?, done: boolean }
export type Counters = {
	requests: number,
	attempts: number,
	retries: number,
	failures: number,
	cacheHits: number,
	coalesced: number,
	rateLimited: number,
	latency: { number },
	latencySum: number,
}
export type State = {
	config: Config,
	hosts: { [string]: Host },
	bucket: Bucket.Bucket,
	budget: number,
	cache: Cache.State,
	flights: { [string]: Flight },
	counters: Counters,
	closing: boolean,
	destroyed: boolean,
	active: number,
	epoch: number,
	lifecycle: Types.Signal,
}
--- Compose stateful stages once. No middleware closure chains are rebuilt per call.
function Pipeline.new(config: Config): State
	local hosts: { [string]: Host } = {}
	for _, host in config.origins do
		if not hosts[host] then
			hosts[host] =
				{ gate = Gate.new(config.concurrency, config.queueCapacity), breaker = Breaker.new() }
		end
	end
	return {
		config = config,
		hosts = hosts,
		bucket = config.sharedBucket or Bucket.new(
			config.burst,
			config.requestsPerMinute / 60,
			config.criticalReserve,
			config.runtime.now()
		),
		budget = 0,
		cache = Cache.new(config.cacheCapacity),
		flights = {},
		counters = {
			requests = 0,
			attempts = 0,
			retries = 0,
			failures = 0,
			cacheHits = 0,
			coalesced = 0,
			rateLimited = 0,
			latency = table.create(6, 0),
			latencySum = 0,
		},
		closing = false,
		destroyed = false,
		active = 0,
		epoch = 0,
		lifecycle = { cancelled = false },
	}
end
--- Optional hook boundary: never pass credentials/payloads, and isolate observer failures.
local function emit(hook: ((Types.Event) -> ())?, event: Types.Event)
	if hook then
		pcall(hook, table.freeze(event))
	end
end
--- Check monotonic deadline and caller/client cancellation between every yielding stage.
local function stopped(
	self: State,
	spec: Types.Endpoint,
	opts: Types.CallOptions,
	deadline: number,
	attempts: number
): Types.Result<any>?
	if self.destroyed or (opts.signal and opts.signal.cancelled) then
		return Errors.make("Cancelled", spec.id, attempts, "Call cancelled")
	end
	if self.config.runtime.now() >= deadline then
		return Errors.make("Timeout", spec.id, attempts, "Call deadline exceeded")
	end
	return nil
end
--- Wait cooperatively within the same end-to-end deadline, not an attempt-specific timer.
local function pause(
	self: State,
	duration: number,
	spec: Types.Endpoint,
	opts: Types.CallOptions,
	deadline: number,
	attempts: number
): Types.Result<any>?
	local runtime = self.config.runtime
	local untilTime = math.min(deadline, runtime.now() + duration)
	while runtime.now() < untilTime do
		local stop = stopped(self, spec, opts, deadline, attempts)
		if stop then
			return stop
		end
		runtime.wait(math.min(0.05, untilTime - runtime.now()))
	end
	return stopped(self, spec, opts, deadline, attempts)
end
--- Execute admission, auth, transport and retry stages for one logical operation.
local function execute(
	self: State,
	spec: Types.Endpoint,
	request: Types.Request,
	opts: Types.CallOptions,
	url: string,
	deadline: number,
	auth: Types.AuthProvider
): Types.Result<any>
	local config, runtime = self.config, self.config.runtime
	local hostName = config.origins[spec.service]
	local host = self.hosts[hostName]
	local hooks = config.hooks
	local public = table.find(spec.authKinds, "none") ~= nil
	local attempt, retryCount, refreshed = 0, 0, false
	local maxRetries = math.min(opts.retry or config.retries, 10)
	while true do
		local stop = stopped(self, spec, opts, deadline, attempt)
		if stop then
			return stop
		end
		if not public and auth.prepare then
			auth.prepare(deadline, opts.signal)
		end
		if not public and auth.ready then
			local ready = auth.ready(deadline, opts.signal)
			if not ready.ok then
				return ready
			end
		end
		stop = stopped(self, spec, opts, deadline, attempt)
		if stop then
			return stop
		end
		local ticket = Gate.enter(host.gate, opts.priority == "critical")
		if not ticket then
			self.counters.rateLimited += 1
			if hooks and hooks.onRateLimited then
				emit(hooks.onRateLimited, { endpoint = spec.id, host = hostName, state = "queueFull" })
			end
			return Errors.make("RateLimited", spec.id, attempt, "Host queue is full")
		end
		while not ticket.granted do
			stop = stopped(self, spec, opts, deadline, attempt)
			if stop then
				Gate.remove(host.gate, ticket)
				return stop
			end
			runtime.wait(0.01)
		end
		-- Recheck after queue handoff, before consuming rate or breaker admission.
		stop = stopped(self, spec, opts, deadline, attempt)
		if stop then
			Gate.release(host.gate)
			return stop
		end
		if Breaker.blocked(host.breaker, runtime.now()) then
			Gate.release(host.gate)
			return Errors.make("CircuitOpen", spec.id, attempt, "Host circuit is open")
		end
		local waitFor = Bucket.take(self.bucket, runtime.now(), opts.priority == "critical")
		while waitFor > 0 do
			self.counters.rateLimited += 1
			if hooks and hooks.onRateLimited then
				emit(hooks.onRateLimited, { endpoint = spec.id, host = hostName })
			end
			stop = pause(self, waitFor, spec, opts, deadline, attempt)
			if stop then
				Gate.release(host.gate)
				return stop
			end
			waitFor = Bucket.take(self.bucket, runtime.now(), opts.priority == "critical")
		end
		local previous = host.breaker.state
		local allowed, breakerGeneration = Breaker.allow(host.breaker, runtime.now())
		if not allowed then
			Gate.release(host.gate)
			return Errors.make("CircuitOpen", spec.id, attempt, "Host circuit is open")
		end
		if previous ~= host.breaker.state and hooks and hooks.onBreakerChange then
			emit(hooks.onBreakerChange, { host = hostName, state = host.breaker.state })
		end
		local headers: Types.Headers = {
			Accept = spec.responseContentType
				or (if spec.responseFormat == "text" then "text/plain" else "application/json"),
		}
		if request.body ~= nil then
			headers["Content-Type"] = if spec.requestFormat == "ndjson"
				then "application/x-ndjson"
				else "application/json"
		end
		if spec.idempotencyHeader and request.idempotencyKey then
			headers["Idempotency-Key"] = request.idempotencyKey
		end
		if spec.conditional and request.etag ~= nil then
			headers["If-None-Match"] = request.etag
		end
		local version = if auth.version then auth.version() else nil
		if attempt == 0 then
			self.budget = math.min(10, self.budget + self.config.retryRatio)
		end
		attempt += 1
		self.counters.attempts += 1
		if hooks and hooks.onRequest then
			emit(hooks.onRequest, { endpoint = spec.id, attempt = attempt })
		end
		local start = runtime.now()
		local result, responseHeaders = Transport.send(
			runtime,
			config.backend,
			host.gate,
			{ Url = url, Method = spec.method, Headers = headers },
			request.body,
			spec,
			attempt,
			deadline,
			opts.signal,
			self.lifecycle,
			if public then nil else auth
		)
		local duration = runtime.now() - start
		self.counters.latencySum += duration
		local bucketIndex = 6
		for i = 1, 5 do
			if duration <= latencyBounds[i] then
				bucketIndex = i
				break
			end
		end
		self.counters.latency[bucketIndex] += 1
		local failure = not result.ok
			and (
				result.error.kind == "Network"
				or result.error.kind == "Timeout"
				or result.error.kind == "Server"
			)
		previous = host.breaker.state
		Breaker.record(host.breaker, runtime.now(), failure, breakerGeneration)
		if previous ~= host.breaker.state and hooks and hooks.onBreakerChange then
			emit(hooks.onBreakerChange, { host = hostName, state = host.breaker.state })
		end
		if hooks and hooks.onResponse then
			emit(hooks.onResponse, {
				endpoint = spec.id,
				attempt = attempt,
				duration = duration,
				status = if result.ok then result.status else result.error.status,
			})
		end
		if result.ok then
			return result
		end
		if result.error.kind == "Unauthorized" and not public and auth.invalidate then
			auth.invalidate(version)
		end
		if
			result.error.kind == "Unauthorized"
			and not public
			and not refreshed
			and spec.retryable
			and spec.idempotent
		then
			refreshed = true
			if auth.onUnauthorized(version, deadline, opts.signal) then
				continue
			end
			stop = stopped(self, spec, opts, deadline, attempt)
			if stop then
				return stop
			end
		end
		local retryable = result.error.kind == "Network"
			or result.error.kind == "Server"
			or result.error.kind == "RateLimited"
		local safe = spec.retryable and spec.idempotent
		if not retryable or not safe or retryCount >= maxRetries or self.budget < 1 then
			return result
		end
		self.budget -= 1
		retryCount += 1
		self.counters.retries += 1
		local retryAfter: string? = nil
		for name, value in responseHeaders do
			if string.lower(name) == "retry-after" then
				retryAfter = value
			end
		end
		local delay = Retry.backoff(retryCount, runtime.random(), 0.25, 8)
		if result.error.status == 429 or (result.error.status and result.error.status >= 500) then
			delay = math.max(delay, Retry.after(retryAfter, runtime.unix()) or 0)
		end
		if hooks and hooks.onRetry then
			emit(
				hooks.onRetry,
				{ endpoint = spec.id, attempt = attempt, status = result.error.status, duration = delay }
			)
		end
		stop = pause(self, delay, spec, opts, deadline, attempt)
		if stop then
			return stop
		end
	end
end
--- Dispatch a validated logical call, coalescing only safe identical GETs with matching policies.
function Pipeline.call(
	self: State,
	spec: Types.Endpoint,
	request: Types.Request,
	options: Types.CallOptions?,
	universe: (string | number)?,
	provider: Types.AuthProvider?
): Types.Result<any>
	local auth = provider or self.config.auth
	local opts: Types.CallOptions = options or {}
	if not Options.valid(opts) then
		return Errors.make("Local", spec.id, 0, "Invalid call options")
	end
	if self.closing then
		return Errors.make("Cancelled", spec.id, 0, "Client is closing")
	end
	local runtime = self.config.runtime
	local deadline =
		math.min(opts.deadline or math.huge, runtime.now() + (opts.timeout or self.config.timeout))
	if universe ~= nil and not Universe.valid(universe) then
		return Errors.make("Validation", spec.id, 0, "Invalid universeId")
	end
	if type(request) ~= "table" then
		return Errors.make("Validation", spec.id, 0, "Invalid request structure")
	end
	if
		(request.path ~= nil and type(request.path) ~= "table")
		or (request.query ~= nil and type(request.query) ~= "table")
	then
		return Errors.make("Validation", spec.id, 0, "Invalid request selectors")
	end
	for name in request :: any do
		if
			name ~= "path"
			and name ~= "query"
			and name ~= "body"
			and name ~= "etag"
			and name ~= "idempotencyKey"
		then
			return Errors.make("Validation", spec.id, 0, "Unknown request field")
		end
	end
	local copied, prepared = pcall(Idempotency.prepare, spec, request, runtime, opts.idempotencyKey)
	if not copied then
		return Errors.make("Validation", spec.id, 0, "Invalid request structure")
	end
	request = prepared
	if
		spec.optionalKey
		and not spec.idempotencyHeader
		and (type(request.body) ~= "table" or (request.body :: any).idempotencyKey == nil)
	then
		spec = table.clone(spec)
		spec.idempotent = false
		spec.retryable = false
	end
	if
		request.etag ~= nil
		and (
			not spec.conditional
			or type(request.etag) ~= "string"
			or #request.etag > 256
			or not (string.match(request.etag, '^"[^"%c]+"$') or string.match(request.etag, '^W/"[^"%c]+"$') or request.etag == "*")
			or string.find(request.etag, "[%c]") ~= nil
		)
	then
		return Errors.make("Validation", spec.id, 0, "Invalid snapshot ETag")
	end
	-- Import binds exact bytes and its header key, not a JSON string/body key or an arbitrary header map.
	if request.idempotencyKey ~= nil then
		if
			not spec.idempotencyHeader
			or not Idempotency.header(request.idempotencyKey, spec.id == "codes.bulkCreateCodes")
		then
			return Errors.make("Validation", spec.id, 0, "Invalid idempotency header")
		end
	end
	if spec.requestFormat == "ndjson" then
		if
			type(request.body) ~= "string"
			or #request.body == 0
			or #request.body > 16 * 1024 * 1024
			or utf8.len(request.body) == nil
		then
			return Errors.make("Validation", spec.id, 0, "Invalid NDJSON body")
		end
		if request.query and request.query.dryRun == false and request.idempotencyKey == nil then
			return Errors.make("Validation", spec.id, 0, "Import apply requires an idempotency key")
		end
	end
	-- Audit writes have no path selector; fill their declared body universe for user-token clients too.
	if spec.service == "audit" and type(request.body) == "table" and universe ~= nil then
		local body = request.body :: { [string]: any }
		if spec.idempotencyItems then
			if type(body.events) == "table" then
				for _, event in body.events do
					if type(event) == "table" and event.universeId == nil then
						event.universeId = tonumber(universe)
					end
				end
			end
		elseif body.universeId == nil then
			body.universeId = tonumber(universe)
		end
	end
	local accessError = Access.check(auth, spec, request, universe)
	if accessError then
		return Errors.make("Local", spec.id, 0, accessError)
	end
	if not Validation.body(spec.id, request.body) then
		return Errors.make("Validation", spec.id, 0, "Invalid request body schema")
	end
	local path, pathError = Path.build(spec, request, universe)
	if not path then
		return Errors.make("Validation", spec.id, 0, pathError or "Invalid path")
	end
	if spec.bodyRequired and request.body == nil then
		return Errors.make("Validation", spec.id, 0, "Missing request body")
	end
	local stop = stopped(self, spec, opts, deadline, 0)
	if stop then
		return stop
	end
	local base = self.config.baseUrls[spec.service]
	-- Platform domain controllers preserve /platform-service even on direct hosts;
	-- operational /health, /metrics, /info and actuator routes remain root-relative.
	if
		spec.service == "platform"
		and self.config.origins.platform == base
		and (string.sub(path, 1, 5) == "/api/" or string.sub(path, 1, 10) == "/internal/")
	then
		base ..= "/platform-service"
	end
	local url = base .. path
	-- Scoped authorization must refresh before cache reads, not only before HTTP.
	if auth.ready and not table.find(spec.authKinds, "none") then
		local ready = auth.ready(deadline, opts.signal)
		if not ready.ok then
			return ready
		end
	end
	local generation = if auth.version then auth.version() else 0
	local key = spec.id
		.. " "
		.. url
		.. " "
		.. tostring(generation)
		.. " "
		.. tostring(self.epoch)
		.. " "
		.. tostring(request.etag)
		.. " "
		.. auth.kind
		.. " "
		.. tostring(auth.universeId)
	local cached = if spec.cacheable then self.cache.entries[key] else nil
	if cached and cached.expires > runtime.now() then
		self.counters.cacheHits += 1
		return cached.result
	end
	-- Call-specific cancellation/deadlines must not cancel another caller's operation.
	local share = spec.method == "GET"
		and spec.idempotent
		and opts.signal == nil
		and opts.deadline == nil
		and opts.timeout == nil
	local flightKey = key
		.. " "
		.. tostring(opts.retry)
		.. " "
		.. tostring(opts.priority)
		.. " "
		.. tostring(opts.cacheTtl)
	local flight = if share then self.flights[flightKey] else nil
	if flight then
		self.counters.coalesced += 1
		while not flight.done do
			stop = stopped(self, spec, opts, deadline, 0)
			if stop then
				return stop
			end
			runtime.wait(0.01)
		end
		return flight.result :: Types.Result<any>
	end
	local owned: Flight = { done = false }
	if share then
		self.flights[flightKey] = owned
	end
	self.active += 1
	self.counters.requests += 1
	-- Retries accrue only from original logical traffic, never retries or cache hits.
	local result = execute(self, spec, request, opts, url, deadline, auth)
	self.active -= 1
	if not result.ok then
		self.counters.failures += 1
		if
			cached
			and cached.staleUntil > runtime.now()
			and (result.error.kind == "Server" or result.error.kind == "Network" or result.error.kind == "CircuitOpen")
			and cached.result.ok
		then
			result = { ok = true, value = cached.result.value, status = cached.result.status, stale = true }
		end
	elseif spec.method ~= "GET" and spec.method ~= "HEAD" then
		self.epoch += 1
		Cache.clear(self.cache)
	end
	if result.ok and spec.cacheable and (opts.cacheTtl or 0) > 0 and not result.stale then
		Cache.put(self.cache, key, result, runtime.now(), opts.cacheTtl :: number, self.config.staleIfError)
	end
	if share then
		owned.result = Cache.freeze(result)
		owned.done = true
		self.flights[flightKey] = nil
	end
	return result
end
--- Stop new admission and wait for physical requests and logical calls within a finite deadline.
function Pipeline.flush(self: State, timeout: number): boolean
	self.closing = true
	local untilTime = self.config.runtime.now() + timeout
	while self.config.runtime.now() < untilTime do
		local active = self.active
		for _, host in self.hosts do
			active += host.gate.active + host.gate.queued
		end
		if active == 0 then
			return true
		end
		self.config.runtime.wait(0.01)
	end
	return false
end
--- Cancel waiters and clear shared data; physical RequestAsync operations remain bounded until completion.
function Pipeline.destroy(self: State)
	self.closing = true
	self.destroyed = true
	self.lifecycle.cancelled = true
	Cache.clear(self.cache)
end
return table.freeze(Pipeline)
