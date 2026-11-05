--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Breaker = require("../src/Core/Breaker")
local Gate = require("../src/Core/Gate")
local Bucket = require("../src/Core/TokenBucket")
local Retry = require("../src/Core/Retry")
local Path = require("../src/Core/Path")
local Session = require("../src/Auth/UserSession")
local ServiceAccount = require("../src/Auth/ServiceAccount")
local Json = require("../src/Core/Json")
local Validation = require("../src/Core/Validation")
local Schemas = require("../src/Core/Schemas")
local passed = 0
--- Fail with a consistent assertion message when a test omits a custom one.
local function check(value: unknown, message: string?): ()
	assert(value, message or "Test assertion failed")
end
--- Report a named regression without suppressing failures.
local function test(name: string, callback: () -> ())
	callback()
	passed += 1
	print("PASS " .. name)
end
--- Assert a precise typed failure, never print response payloads or credentials.
local function failure(result: Core.Result<any>, kind: Core.ErrorKind)
	check(not result.ok and result.error.kind == kind, "Expected " .. kind)
end
--- Generate an isolated synthetic credential; this is not a real account key.
local function key(): string
	return "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
end
--- Build an offline client with broad synthetic service permissions.
local function client(
	s: Scheduler.Scheduler,
	steps: { Fake.Step },
	options: SDK.Config?
): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	local cfg: SDK.Config = options or {}
	cfg.runtime = s.runtime
	cfg.backend = fake.backend
	if not cfg.userSession and not cfg.authProvider then
		cfg.key = key()
		cfg.universeId = 123
	end
	return SDK.new(cfg), fake
end
--- Produce a minimal valid response fixture from generated metadata.
local function fixture(schema: Core.Schema, defs: { [string]: Core.Schema }): any
	local kind = schema.kind
	if kind == "ref" then
		return fixture(defs[schema.name :: string], defs)
	end
	if kind == "string" then
		return "value"
	end
	if kind == "number" or kind == "decimal" then
		return 1
	end
	if kind == "boolean" then
		return true
	end
	if kind == "nil" then
		return nil
	end
	if kind == "enum" then
		return (schema.values :: { string })[1]
	end
	if kind == "json" then
		return {}
	end
	if kind == "union" then
		return fixture((schema.items :: { Core.Schema })[1], defs)
	end
	if kind == "nullable" then
		return Json.null
	end
	if kind == "array" then
		return Json.array({})
	end
	if kind == "map" then
		return {}
	end
	if kind == "cursorPage" then
		return { items = Json.array({}) }
	end
	if kind == "page" then
		return {
			content = Json.array({}),
			number = 0,
			size = 10,
			totalElements = 0,
			totalPages = 0,
			first = true,
			last = true,
		}
	end
	local value: { [string]: any } = {}
	for name, field in
		schema.fields :: { [string]: { schema: Core.Schema, required: boolean, notBlank: boolean } }
	do
		if field.required then
			value[name] = if (name == "universeId" or name == "robloxUniverseId")
					and field.schema.kind == "string"
				then "1"
				else fixture(field.schema, defs)
		end
	end
	return value
end

test("key validation, fixed offsets, redaction and opaque Secret AddPrefix", function()
	check(ServiceAccount.valid(key()))
	check(ServiceAccount.valid("bsa_" .. string.rep("_", 8) .. "_" .. string.rep("_", 43)))
	for _, bad in
		{
			"",
			key() .. "x",
			string.sub(key(), 2),
			string.sub(key(), 1, 55) .. " ",
			"bsa_" .. string.rep("a", 9) .. "_" .. string.rep("b", 42),
		}
	do
		check(not ServiceAccount.valid(bad))
	end
	local ok, message = pcall(ServiceAccount.new, "sensitive-invalid-key", 123, nil)
	check(not ok and not string.find(tostring(message), "sensitive-invalid-key", 1, true))
	local prefixed = false
	local fakeSecret: Core.Secret
	fakeSecret = {
		AddPrefix = function(_self: Core.Secret, prefix: string): Core.Secret
			prefixed = prefix == "Bearer "
			return fakeSecret
		end,
	}
	local auth = ServiceAccount.new(fakeSecret, 123, nil)
	local headers: Core.Headers = {}
	auth.apply(headers)
	check(prefixed and headers.Authorization == fakeSecret)
	check(not auth.onUnauthorized(nil))
end)

test("precompiled paths encode delimiters UTF8 and false query values", function()
	local p = SDK.endpoints["auth.getAccountByUsername"]
	local path = Path.build(p, { path = { username = "a/b ?#é" } :: { [string]: unknown } }, nil)
	check(path == "/api/auth/accounts/username/a%2Fb%20%3F%23%C3%A9")
	local codes = Path.build(
		SDK.endpoints["codes.searchCodes"],
		{ query = { active = false, page = 0 } :: { [string]: unknown } },
		123
	)
	check(codes == "/api/codes?active=false&page=0&universeId=123")
	local missing = Path.build(p, { path = {} }, nil)
	check(missing == nil)
	check(Path.scalar(9007199254740992, "id") == nil)
end)

test("full jitter bounds and Retry-After seconds/http-date", function()
	check(Retry.backoff(1, 0.5, 0.25, 8) == 0.125)
	check(Retry.backoff(99, 1, 0.25, 8) == 8)
	check(Retry.backoff(2, -1, 0.25, 8) == 0)
	check(Retry.after("5", 0) == 5)
	check(Retry.after("Thu, 01 Jan 1970 00:00:10 GMT", 3) == 7)
	check(Retry.after("garbage", 0) == nil)
end)

test("token bucket reserve and monotonic refill", function()
	local b = Bucket.new(3, 1, 1, 0)
	check(Bucket.take(b, 0, false) == 0)
	check(Bucket.take(b, 0, false) == 0)
	check(Bucket.take(b, 0, false) == 1)
	check(Bucket.take(b, 0, true) == 0)
	check(Bucket.take(b, 2, false) == 0)
end)

test("breaker closed/open/half-open singleton and recovery", function()
	local b = Breaker.new()
	for _ = 1, 5 do
		check((Breaker.allow(b, 0)))
		Breaker.record(b, 0, true)
	end
	check(b.state == "open")
	check(not Breaker.allow(b, 1))
	check((Breaker.allow(b, 10)))
	check(not Breaker.allow(b, 10))
	Breaker.record(b, 10, false)
	check((b.state :: string) == "closed")
	for i = 1, 6 do
		Breaker.record(b, i * 31, true)
	end
	check((b.state :: string) == "closed")
end)

test("bounded queue cancellation O1 removal and critical priority", function()
	local g = Gate.new(1, 2)
	check((Gate.enter(g, false) :: Gate.Ticket).granted)
	local bulk = Gate.enter(g, false) :: Gate.Ticket
	local critical = Gate.enter(g, true) :: Gate.Ticket
	check(Gate.enter(g, false) == nil)
	Gate.release(g)
	check(critical.granted and not bulk.granted)
	Gate.remove(g, bulk)
	check(g.queued == 0)
	Gate.release(g)
	check(g.active == 0)
end)

test("JSON explicit null, empty arrays, cycles and schema rejection", function()
	check(
		Json.encode({ description = SDK.null, permissions = SDK.array({}) })
			== '{"description":null,"permissions":[]}'
	)
	local cyclic: { [string]: any } = {}
	cyclic.self = cyclic
	check(not pcall(Json.encode, cyclic))
	check(not Validation.body("party.createParty", { ownerId = 1 }))
	check(not Validation.body("auth.patchServiceAccount", { universeId = 123 }))
	check(Validation.body("auth.patchServiceAccount", { description = SDK.null, enabled = false }))
	check(not Validation.body("codes.redeem", { code = "  ", robloxUserId = 1 }))
end)

test("local role and universe guards perform no HTTP", function()
	local s = Scheduler.new()
	local c, f = client(s, {})
	s.run(function()
		local result = c.auth:listServiceAccounts()
		failure(result, "Local")
		check(not result.ok and result.error.message == "requires super-admin user token")
		failure(c.data:getSchemaDefaults({ query = { universeId = 456 } }), "Local")
	end)
	check(f.count() == 0)
	check(not pcall(function()
		c:withUniverse(456)
	end))
end)

test("GET success auth headers and immutable metadata", function()
	local s = Scheduler.new()
	local header = false
	local c, f = client(s, {
		{
			body = s.json({ universeId = 123 }),
			check = function(req: Core.HttpRequest)
				header = req.Headers.Authorization == "Bearer " .. key()
				check(req.Url == "https://data.blox-api.com/api/universes/schema/defaults?universeId=123")
			end,
		},
	})
	s.run(function()
		check(c.data:getSchemaDefaults().ok)
	end)
	check(header and f.count() == 1 and table.isfrozen(SDK.endpoints))
end)

test("POST not retried and HTTP failure payload is fully redacted", function()
	local s = Scheduler.new()
	local c, f = client(s, { { status = 503, body = "secret " .. key() } }, { retryRatio = 1 })
	s.run(function()
		local result = c.party:createParty({ ownerId = 1, placeId = 2 })
		failure(result, "Server")
		check(not result.ok and result.error.body == "[redacted]" and result.error.attempts == 1)
	end)
	check(f.count() == 1)
end)

test("safe GET retry honors Retry-After and caps retry budget", function()
	local s = Scheduler.new()
	local c, f = client(
		s,
		{ { status = 503, headers = { ["Retry-After"] = "2" } }, { body = s.json({}) } },
		{ retryRatio = 1 }
	)
	s.run(function()
		check(c.data:getSchemaDefaults().ok)
	end)
	check(f.count() == 2 and s.time() >= 2 and c:metrics().retries == 1)
	local s2 = Scheduler.new()
	local c2, f2 = client(s2, { { status = 503 } }, { retryRatio = 0.2 })
	s2.run(function()
		failure(c2.data:getSchemaDefaults(), "Server")
	end)
	check(f2.count() == 1)
end)

test("deadline drops late response and releases native slot only on completion", function()
	local s = Scheduler.new()
	local c, f = client(
		s,
		{ { delay = 2, body = s.json({}) } },
		{ timeout = 0.1, concurrency = 1, queueCapacity = 0 }
	)
	s.run(function()
		failure(c.data:getSchemaDefaults(), "Timeout")
		failure(c.data:getSchemaVersions(), "RateLimited")
	end)
	check(f.count() == 1 and s.pending() == 0 and s.time() >= 2)
	check(c._state.hosts["https://data.blox-api.com"].gate.active == 0)
end)

test("concurrent identical GETs single-flight; cache snapshots immutable", function()
	local s = Scheduler.new()
	local c, f = client(s, { { delay = 0.2, body = s.json({}) } })
	local count = 0
	s.run(function()
		for _ = 1, 8 do
			s.runtime.spawn(function()
				local r = c.data:getSchemaDefaults(nil, { cacheTtl = 5 })
				check(r.ok)
				count += 1
			end)
		end
	end)
	check(f.count() == 1 and count == 8 and c:metrics().coalesced == 7)
	s.run(function()
		local r = c.data:getSchemaDefaults(nil, { cacheTtl = 5 })
		check(r.ok and table.isfrozen(r.value))
	end)
	check(f.count() == 1 and c:metrics().cacheHits == 1)
end)

test("stale-if-error serves only eligible cached data, not authorization errors", function()
	local s = Scheduler.new()
	local c, f = client(
		s,
		{ { body = s.json({}) }, { status = 503 }, { status = 403 } },
		{ staleIfError = 10, retries = 0 }
	)
	s.run(function()
		check(c.data:getSchemaDefaults(nil, { cacheTtl = 0.1 }).ok)
		s.runtime.wait(0.2)
		local stale = c.data:getSchemaDefaults(nil, { cacheTtl = 0.1 })
		check(stale.ok and stale.stale)
		failure(c.data:getSchemaDefaults(nil, { cacheTtl = 0.1 }), "Forbidden")
	end)
	check(f.count() == 3)
end)

test("cancellation removes waiting ticket without consuming another slot", function()
	local s = Scheduler.new()
	local c, f = client(s, { { delay = 0.3, body = s.json({}) } }, { concurrency = 1 })
	local signal: Core.Signal = { cancelled = false }
	local cancelled = false
	s.run(function()
		s.runtime.spawn(function()
			check(c.data:getSchemaDefaults().ok)
		end)
		s.runtime.wait(0.01)
		s.runtime.spawn(function()
			failure(c.data:getSchemaVersions(nil, { signal = signal }), "Cancelled")
			cancelled = true
		end)
		s.runtime.wait(0.02)
		signal.cancelled = true
	end)
	check(cancelled and f.count() == 1 and c._state.hosts["https://data.blox-api.com"].gate.queued == 0)
end)

test("concurrent 401s refresh once, replay once with rotated tokens", function()
	local s = Scheduler.new()
	local store = Session.memoryStore()
	store.set({ accessToken = "old", refreshToken = "refresh-old" })
	local replayHeaders = 0
	local c, f = client(s, {
		{ status = 401, delay = 0.1 },
		{ status = 401, delay = 0.1 },
		{
			body = s.json({ accessToken = "new", refreshToken = "refresh-new", expiresIn = 3600 }),
			delay = 0.1,
			check = function(req: Core.HttpRequest)
				check(
					req.Url == "https://security.blox-api.com/api/auth/refresh"
						and req.Headers.Authorization == nil
				)
			end,
		},
		{
			body = s.json({}),
			check = function(req: Core.HttpRequest)
				if req.Headers.Authorization == "Bearer new" then
					replayHeaders += 1
				end
			end,
		},
		{
			body = s.json({}),
			check = function(req: Core.HttpRequest)
				if req.Headers.Authorization == "Bearer new" then
					replayHeaders += 1
				end
			end,
		},
	}, { userSession = { store = store } })
	local successes = 0
	s.run(function()
		s.runtime.spawn(function()
			check(c.data:getSchemaDefaults({ query = { universeId = 1 } }).ok)
			successes += 1
		end)
		s.runtime.spawn(function()
			check(c.data:getSchemaDefaults({ query = { universeId = 2 } }).ok)
			successes += 1
		end)
	end)
	check(successes == 2 and f.count() == 5 and replayHeaders == 2)
	check((store.get() :: Session.Tokens).refreshToken == "refresh-new")
end)

test("failed refresh is single-flight too; replay 401 never loops", function()
	local s = Scheduler.new()
	local store = Session.memoryStore()
	store.set({ accessToken = "old", refreshToken = "r" })
	local c, f = client(
		s,
		{ { status = 401, delay = 0.1 }, { status = 401, delay = 0.1 }, { status = 401, delay = 0.1 } },
		{ userSession = { store = store } }
	)
	s.run(function()
		for i = 1, 2 do
			s.runtime.spawn(function()
				failure(c.data:getSchemaDefaults({ query = { universeId = i } }), "Unauthorized")
			end)
		end
	end)
	check(f.count() == 3)
end)

test("JWT exp reading, proactive refresh, login and logout token store", function()
	check(Session.exp("e30.eyJleHAiOjEyMzQ1fQ.sig") == 12345)
	check(Session.exp("not-jwt") == nil)
	local s = Scheduler.new()
	local store = Session.memoryStore()
	store.set({ accessToken = "old", refreshToken = "r", expiresAt = 1700000001 })
	local c, f = client(s, {
		{ body = s.json({ accessToken = "new", refreshToken = "next", expiresIn = 3600 }) },
		{ body = s.json({}) },
		{ body = s.json({ message = "ok" }) },
	}, { userSession = { store = store } })
	s.run(function()
		check(c.data:getSchemaDefaults().ok)
		check(c.auth:logout({ refreshToken = "next" }).ok)
	end)
	check(f.count() == 3 and store.get() == nil)
end)

test("telemetry hook failures cannot fail calls or reveal payloads", function()
	local s = Scheduler.new()
	local seen = 0
	local c = client(s, { { body = s.json({}) } }, {
		hooks = {
			onRequest = function(event: Core.Event)
				check(event.endpoint ~= nil)
				seen += 1
				error("observer failed")
			end,
		},
	})
	s.run(function()
		check(c.data:getSchemaDefaults().ok)
	end)
	check(seen == 1 and c:metrics().attempts == 1)
end)

test("flush/destroy and scope facades share state", function()
	local s = Scheduler.new()
	local c, f = client(s, {})
	check(c:withUniverse(123)._state == c._state)
	s.run(function()
		check(c:flush(1))
		failure(c.data:getSchemaDefaults(), "Cancelled")
		c:destroy()
		c:destroy()
	end)
	check(f.count() == 0)
end)

test("all 234 generated endpoint response contracts execute offline", function()
	local count = 0
	for id, spec in SDK.endpoints do
		local s = Scheduler.new()
		local schema = Schemas.endpoints[id]
		local value = fixture(schema.response, Schemas.definitions[schema.service])
		local status = if value == nil then 204 else 200
		local body = if value == nil then "" elseif spec.responseFormat == "text" then value else s.json(value)
		local request: Core.Request = { path = {}, query = {} }
		for _, p in spec.pathParams do
			(request.path :: { [string]: unknown })[p.name] = if p.type == "number" or p.type == "id"
				then 1
				elseif p.type == "boolean" then true
				elseif p.name == "universeId" or p.name == "robloxUniverseId" then "1"
				else "value"
		end
		for _, p in spec.queryParams do
			if p.required then
				(request.query :: { [string]: unknown })[p.name] = if p.type == "number"
						or p.type == "id"
					then 1
					elseif p.type == "boolean" then true
					elseif p.name == "universeId" or p.name == "robloxUniverseId" then "1"
					else "value"
			end
		end
		if schema.body then
			request.body = fixture(schema.body, Schemas.definitions[schema.service])
			if spec.idempotencyItems then
				local dto = if spec.service == "audit" then "EventInput" else "ScoreInput"
				(request.body :: any)[spec.idempotencyItems] =
					{ fixture(Schemas.definitions[spec.service][dto], Schemas.definitions[spec.service]) }
			end
		end
		local c, f = client(s, { { status = status, body = body } }, {
			authProvider = {
				kind = "custom",
				apply = function(_h: Core.Headers) end,
				onUnauthorized = function(_v: number?): boolean
					return false
				end,
			},
		})
		s.run(function()
			local facade = (c :: any)[spec.service]
			local name = string.match(id, "%.(.+)$") :: string
			local argument = if spec.bodyType
					and #spec.pathParams == 0
					and #spec.queryParams == 0
				then request.body
				else request
			local r = facade[name](facade, argument)
			check(r.ok, "Endpoint failed " .. id)
		end)
		check(f.count() == 1)
		count += 1
	end
	check(count == 234)
end)

test("short caller deadline does not wait for or cancel shared refresh", function()
	local s = Scheduler.new()
	local store = Session.memoryStore()
	store.set({ accessToken = "old", refreshToken = "r", expiresAt = 1700000001 })
	local c, f = client(
		s,
		{ { delay = 1, body = s.json({ accessToken = "new", refreshToken = "next", expiresIn = 3600 }) } },
		{ userSession = { store = store } }
	)
	local returned = 0
	s.run(function()
		failure(c.data:getSchemaDefaults(nil, { deadline = s.time() + 0.05 }), "Timeout")
		returned = s.time()
	end)
	check(returned < 0.1 and f.count() == 1 and (store.get() :: Session.Tokens).accessToken == "new")
end)

test("destroy interrupts active callers and refresh cannot resurrect credentials", function()
	local s = Scheduler.new()
	local store = Session.memoryStore()
	store.set({ accessToken = "old", refreshToken = "r" })
	local c, f = client(s, { { delay = 2, body = s.json({}) } }, { userSession = { store = store } })
	local returned = 0
	s.run(function()
		s.runtime.spawn(function()
			failure(c.data:getSchemaDefaults(), "Cancelled")
			returned = s.time()
		end)
		s.runtime.wait(0.05)
		c:destroy()
	end)
	check(returned < 0.1 and store.get() == nil and f.count() == 1 and s.pending() == 0)
end)

test("replayed 401 terminates after one refresh", function()
	local s = Scheduler.new()
	local store = Session.memoryStore()
	store.set({ accessToken = "old", refreshToken = "r" })
	local c, f = client(s, {
		{ status = 401 },
		{ body = s.json({ accessToken = "new", refreshToken = "next", expiresIn = 3600 }) },
		{
			status = 401,
		},
	}, { userSession = { store = store } })
	s.run(function()
		failure(c.data:getSchemaDefaults(), "Unauthorized")
	end)
	check(f.count() == 3)
end)

test("login stores tokens and managed logout uses the current refresh token", function()
	local s = Scheduler.new()
	local store = Session.memoryStore()
	local logoutBody = false
	local c, f = client(s, {
		{ body = s.json({ accessToken = "new", refreshToken = "current", expiresIn = 3600 }) },
		{
			body = s.json({ message = "ok" }),
			check = function(req: Core.HttpRequest)
				logoutBody = req.Body == '{"refreshToken":"current"}'
			end,
		},
	}, { userSession = { store = store } })
	s.run(function()
		check(c.auth:login({ username = "test-user", password = "synthetic-test-password" }).ok)
		check(store.get() ~= nil)
		check(c:logout().ok)
	end)
	check(f.count() == 2 and store.get() == nil and logoutBody)
end)

test("generated schema encodes empty service permissions as an array", function()
	local s = Scheduler.new()
	local serialized = false
	local c = client(s, {
		{
			body = s.json({}),
			check = function(req: Core.HttpRequest)
				serialized = req.Body == "[]"
			end,
		},
	}, { userSession = { role = "SUPER_ADMIN" } })
	s.run(function()
		check(c.auth:setServiceAccountPermissions({ path = { id = "synthetic-id" }, body = {} }).ok)
	end)
	check(serialized)
end)

test("token-starved work remains bounded by host queue capacity", function()
	local s = Scheduler.new()
	local c, f = client(s, { { body = s.json({}) } }, {
		burst = 1,
		criticalReserve = 0,
		requestsPerMinute = 1,
		concurrency = 1,
		queueCapacity = 0,
		timeout = 0.2,
	})
	local full = false
	s.run(function()
		check(c.data:getSchemaDefaults().ok)
		s.runtime.spawn(function()
			failure(c.data:getSchemaDefaults(), "Timeout")
		end)
		s.runtime.wait(0.01)
		failure(c.data:getSchemaVersions(), "RateLimited")
		full = true
	end)
	check(full and f.count() == 1)
end)

test("query typo and invalid options fail before transport", function()
	local s = Scheduler.new()
	local c, f = client(s, {})
	s.run(function()
		failure(
			c._invoke(SDK.endpoints["codes.searchCodes"], { query = { univrseId = 123 } }, nil, nil),
			"Validation"
		)
		failure(c.data:getSchemaDefaults(nil, { retry = -1 }), "Local")
		failure(c.data:getSchemaDefaults(nil, { deadline = 0 / 0 }), "Local")
	end)
	check(f.count() == 0)
end)

test("universe facade fills string matchmaking identifiers", function()
	local s = Scheduler.new()
	local url = false
	local c = client(s, {
		{
			body = s.json({}),
			check = function(req: Core.HttpRequest)
				url = req.Url
					== "https://matchmaking.blox-api.com/api/matchmaking/123/gamemodes/ranked/queue/count"
			end,
		},
	})
	s.run(function()
		check(c:withUniverse(123).matchmaking:getQueueCount({ path = { gameModeName = "ranked" } }).ok)
	end)
	check(url)
end)

test("all error classifications and malformed successful JSON are redacted", function()
	local cases: { [number]: Core.ErrorKind } = {
		[400] = "Validation",
		[401] = "Unauthorized",
		[403] = "Forbidden",
		[404] = "NotFound",
		[409] = "Conflict",
		[422] = "Validation",
		[429] = "RateLimited",
		[503] = "Server",
	}
	for status, kind in cases do
		local s = Scheduler.new()
		local c = client(s, { { status = status, body = "never expose this" } }, { retries = 0 })
		s.run(function()
			failure(c.data:getSchemaDefaults(), kind :: Core.ErrorKind)
		end)
	end
	local s = Scheduler.new()
	local c = client(s, { { body = "invalid-json" } })
	s.run(function()
		failure(c.data:getSchemaDefaults(), "Network")
	end)
end)

test("pagination preserves page errors and terminates lazily", function()
	local fetched = 0
	local iterator = SDK.pages(function(page: number): Core.Result<{ last: boolean }>
		fetched += 1
		return { ok = true, value = { last = page == 2 } }
	end, function(page: { last: boolean }): boolean
		return page.last
	end)
	for _ = 1, 3 do
		check(iterator() ~= nil)
	end
	check(iterator() == nil and fetched == 3)
end)

test("GET with online side effects is neither cached nor coalesced", function()
	local s = Scheduler.new()
	local c, f = client(s, { { delay = 0.1, body = s.json({}) }, { delay = 0.1, body = s.json({}) } })
	s.run(function()
		for _ = 1, 2 do
			s.runtime.spawn(function()
				check(c.data:getUserData({ path = { robloxUserId = 1 } }, { cacheTtl = 10 }).ok)
			end)
		end
	end)
	check(f.count() == 2 and c:metrics().coalesced == 0 and c:metrics().cacheHits == 0)
end)

test("late pre-open result cannot close a half-open probe", function()
	local b = Breaker.new()
	local allowed, oldGeneration = Breaker.allow(b, 0)
	check(allowed)
	for _ = 1, 5 do
		Breaker.record(b, 0, true, oldGeneration)
	end
	local probe, probeGeneration = Breaker.allow(b, 10)
	check(probe)
	Breaker.record(b, 11, false, oldGeneration)
	check(b.state == "half-open" and b.probe)
	Breaker.record(b, 12, false, probeGeneration)
	check((b.state :: string) == "closed")
end)

test("refresh wait observes caller cancellation without cancelling shared refresh", function()
	local s = Scheduler.new()
	local store = Session.memoryStore()
	store.set({ accessToken = "old", refreshToken = "r", expiresAt = 1700000001 })
	local c, f = client(
		s,
		{ { delay = 1, body = s.json({ accessToken = "new", refreshToken = "next", expiresIn = 3600 }) } },
		{ userSession = { store = store } }
	)
	local signal: Core.Signal = { cancelled = false }
	local returned = 0
	s.run(function()
		s.runtime.spawn(function()
			failure(c.data:getSchemaDefaults(nil, { signal = signal }), "Cancelled")
			returned = s.time()
		end)
		s.runtime.wait(0.02)
		signal.cancelled = true
	end)
	check(returned < 0.1 and f.count() == 1 and (store.get() :: Session.Tokens).accessToken == "new")
end)

test("known service levels reject writes without backend calls", function()
	local s = Scheduler.new()
	local c, f = client(s, {}, { levels = { PartyService = "READ", MatchmakingService = "READ_WRITE" } })
	s.run(function()
		failure(c.party:createParty({ ownerId = 1, placeId = 2 }), "Local")
		failure(
			c.matchmaking:createGameMode({ name = "ranked", universeId = "123", placeId = "456" }),
			"Local"
		)
	end)
	check(f.count() == 0)
end)

test("successful mutation invalidates cached reads", function()
	local s = Scheduler.new()
	local c, f =
		client(s, { { body = s.json({}) }, { body = s.json({}), status = 201 }, { body = s.json({}) } })
	s.run(function()
		check(c.data:getSchemaDefaults(nil, { cacheTtl = 10 }).ok)
		check(c.party:createParty({ ownerId = 1, placeId = 2 }).ok)
		check(c.data:getSchemaDefaults(nil, { cacheTtl = 10 }).ok)
	end)
	check(f.count() == 3)
end)
require("./new_services")(test)
print("PASS " .. tostring(passed) .. " test groups")
