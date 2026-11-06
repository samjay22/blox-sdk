--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Auth = require("../src/Types/Auth")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Session = require("../src/Auth/UserSession")
local Scoped = require("../src/Auth/ScopedTokens")
local Validation = require("../src/Core/Validation")
local Path = require("../src/Core/Path")
local Errors = require("../src/Core/Errors")

--- Assert a regression without exposing credential-bearing fixtures.
local function check(value: unknown)
	assert(value, "Tenant Auth assertion failed")
end

--- Install an isolated synthetic identity without issuing a real login.
local function identity(s: Scheduler.Scheduler): Session.Session
	local session = Session.new(s.runtime)
	check(session.accept({ accessToken = "identity", refreshToken = "refresh", expiresIn = 3600 }))
	return session
end

--- Exercise tenant contracts and credential races independently of generated endpoint fixtures.
return function(test: (string, () -> ()) -> ())
	test(
		"service key rotation validates grace bounds and requires org-qualified identity requests",
		function()
			for _, grace in { 0, 1, 3600, 604800 } do
				check(Validation.body("auth.rotateServiceAccount", { gracePeriodSeconds = grace }))
			end
			local invalid: { unknown } = { -1, 604801, 0.5, math.huge, 0 / 0, "1", SDK.null }
			for _, grace in invalid do
				check(not Validation.body("auth.rotateServiceAccount", { gracePeriodSeconds = grace }))
			end
			check(Validation.body("auth.rotateServiceAccount", {}))
			check(Validation.body("auth.rotateServiceAccount", nil))
			check(not Validation.body("auth.rotateServiceAccount", { graceSeconds = 1 }))
			local endpoint = SDK.endpoints["auth.rotateServiceAccount"]
			check(not endpoint.retryable and not endpoint.cacheable and not endpoint.idempotent)
			check(not Path.build(endpoint, { path = { id = "key" } :: { [string]: unknown } }, nil))
			local path =
				Path.build(endpoint, { path = { org = "org/a", id = "key b" } :: { [string]: unknown } }, nil)
			check(path == "/api/auth/orgs/org%2Fa/service-accounts/key%20b/rotate")
		end
	)
	test("service key rotation preserves metadata and never replays a lost one-time response", function()
		local s = Scheduler.new()
		local metadata = {
			id = "key",
			name = "server",
			universeId = 42,
			orgId = "org",
			enabled = true,
			createdAt = "2026-11-06T00:00:00Z",
			createdBy = "actor",
			permissions = SDK.array({}),
			expiresAt = "2026-12-01T00:00:00Z",
			rotatedAt = "2026-11-06T01:00:00Z",
			previousKeyExpiresAt = "2026-11-06T01:05:00Z",
			status = "EXPIRING_SOON",
			key = "one-time",
		}
		for _, status in { "ACTIVE", "EXPIRING_SOON", "EXPIRED", "REVOKED" } do
			metadata.status = status
			check(Validation.response("auth.getServiceAccount", metadata, 200))
			check(Validation.response("auth.listServiceAccounts", { metadata }, 200))
		end
		metadata.status = "DISABLED"
		check(not Validation.response("auth.getServiceAccount", metadata, 200))
		metadata.status = "EXPIRING_SOON"
		local store = Session.memoryStore()
		store.set({ accessToken = "identity", refreshToken = "refresh" })
		local f = Fake.new(s.runtime, {
			{
				body = s.json(metadata),
				check = function(req)
					check(
						req.Method == "POST"
							and req.Url
								== "https://lb1.blox-api.com/auth-service/api/auth/orgs/org/service-accounts/key/rotate"
					)
					check(req.Headers.Authorization == "Bearer identity")
					check(req.Body == s.runtime.encode({ gracePeriodSeconds = 300 }))
				end,
			},
			{ status = 503 },
		})
		local client = SDK.new({ runtime = s.runtime, backend = f.backend, userSession = { store = store } })
		s.run(function()
			local result = client.auth:rotateServiceAccount({
				path = { org = "org", id = "key" },
				body = { gracePeriodSeconds = 300 },
			})
			check(result.ok and result.value.status == "EXPIRING_SOON" and result.value.key == "one-time")
			check(result.ok and result.value.previousKeyExpiresAt == metadata.previousKeyExpiresAt)
			local lost = client.auth:rotateServiceAccount(
				{ path = { org = "org", id = "key" } },
				{ retry = 3 }
			)
			check(not lost.ok and f.count() == 2)
			local denied = client:scoped(42).auth:rotateServiceAccount({ path = { org = "org", id = "key" } })
			check(not denied.ok and f.count() == 2)
		end)
	end)
	test("scoped tokens cache by universe and refresh early with one exchange per concurrent wave", function()
		local s = Scheduler.new()
		local session = identity(s)
		local calls, successes = 0, 0
		local provider = Scoped.new(s.runtime, session, 42, function(): Core.Result<Auth.Token>
			calls += 1
			s.runtime.wait(0.1)
			return {
				ok = true,
				value = {
					accessToken = "scope-" .. tostring(calls),
					tokenType = "Bearer",
					expiresIn = 10,
				},
			}
		end)
		s.run(function()
			for _ = 1, 5 do
				s.runtime.spawn(function()
					check(provider.get().ok)
					successes += 1
				end)
			end
			s.runtime.wait(0.2)
			check(provider.get().ok and calls == 1)
			s.runtime.wait(9)
			for _ = 1, 5 do
				s.runtime.spawn(function()
					check(provider.get().ok)
					successes += 1
				end)
			end
		end)
		check(calls == 2 and successes == 10)
	end)
	test("scoped waiters cancel or time out without cancelling a shared exchange", function()
		local s = Scheduler.new()
		local session = identity(s)
		local calls, success = 0, false
		local signal: Core.Signal = { cancelled = false }
		local provider = Scoped.new(s.runtime, session, 42, function(): Core.Result<Auth.Token>
			calls += 1
			s.runtime.wait(1)
			return { ok = true, value = { accessToken = "scope", tokenType = "Bearer", expiresIn = 600 } }
		end)
		s.run(function()
			s.runtime.spawn(function()
				success = provider.get().ok
			end)
			s.runtime.spawn(function()
				local r = provider.get(nil, signal)
				check(not r.ok and r.error.kind == "Cancelled")
			end)
			local r = provider.get(s.time() + 0.03)
			check(not r.ok and r.error.kind == "Timeout" and s.time() < 0.1)
			signal.cancelled = true
		end)
		check(success and calls == 1 and provider.get().ok)
	end)
	test("identity replacement and logout fence stale scoped exchanges and headers", function()
		for _, action in { "login", "logout", "destroy" } do
			local s = Scheduler.new()
			local session = identity(s)
			local provider = Scoped.new(s.runtime, session, 42, function(): Core.Result<Auth.Token>
				s.runtime.wait(0.2)
				return {
					ok = true,
					value = { accessToken = "old-scope", tokenType = "Bearer", expiresIn = 600 },
				}
			end)
			s.run(function()
				s.runtime.spawn(function()
					check(not provider.get().ok)
				end)
				s.runtime.wait(0.02)
				if action == "login" then
					session.accept({ accessToken = "other", refreshToken = "other" })
				elseif action == "logout" then
					session.clear()
				else
					(session.destroy :: () -> ())()
				end
			end)
			check(not pcall(function()
				provider.apply({})
			end))
		end
	end)
	test("scoped failures and malformed or expired exchanges fail closed without storms", function()
		for _, ttl in { 0, 0.5, 3601, 1 } do
			local s = Scheduler.new()
			local calls = 0
			local provider = Scoped.new(s.runtime, identity(s), 42, function(): Core.Result<Auth.Token>
				calls += 1
				s.runtime.wait(1.1)
				return { ok = true, value = { accessToken = "scope", tokenType = "Bearer", expiresIn = ttl } }
			end)
			s.run(function()
				check(not provider.get().ok)
				check(not provider.get().ok)
			end)
			check(calls == 1 and not pcall(function()
				provider.apply({})
			end))
		end
	end)
	test("scoped facades isolate identity management, universes, routing and Fields helpers", function()
		local s = Scheduler.new()
		local store = Session.memoryStore()
		store.set({ accessToken = "identity", refreshToken = "refresh" })
		local f = Fake.new(s.runtime, {
			{
				body = s.json({ accessToken = "scope42", tokenType = "Bearer", expiresIn = 600 }),
				check = function(req)
					check(
						req.Url == "https://auth.example/api/auth/universes/42/token"
							and req.Headers.Authorization == "Bearer identity"
					)
				end,
			},
			{
				body = s.json({ universeId = 42, schemaVersion = 1, definitions = SDK.array({}) }),
				check = function(req)
					check(
						req.Headers.Authorization == "Bearer scope42"
							and string.find(req.Url, "/fields-service/", 1, true)
					)
				end,
			},
			{ body = s.json({ accessToken = "scope43", tokenType = "Bearer", expiresIn = 600 }) },
			{
				body = s.json({ universeId = 43, schemaVersion = 1, definitions = SDK.array({}) }),
				check = function(req)
					check(req.Headers.Authorization == "Bearer scope43")
				end,
			},
			{
				body = "[]",
				check = function(req)
					check(req.Headers.Authorization == "Bearer identity")
				end,
			},
		})
		local c = SDK.new({
			runtime = s.runtime,
			backend = f.backend,
			userSession = { store = store },
			services = { auth = { baseUrl = "https://auth.example" } },
		})
		local a, b = c:scoped(42), c:scoped(43)
		s.run(function()
			check(not a.auth:listOrgs().ok and f.count() == 0)
			check(not a.matchmaking:getAllUniverses().ok and f.count() == 0)
			check(a.fields:Schema(42):Load().ok)
			check(not a.fields:schema({ path = { universeId = 43 } }).ok)
			check(b.fields:schema().ok)
			check(c.auth:getMyAccess().ok)
			c:destroy()
		end)
		check(f.count() == 5 and not pcall(function()
			a:withUniverse(43)
		end))
		c:destroy()
		check(not store.get())
	end)
	test("scoped 401 re-exchanges once and never refreshes scoped JWTs or loops", function()
		local s = Scheduler.new()
		local store = Session.memoryStore()
		store.set({ accessToken = "identity", refreshToken = "refresh" })
		local f = Fake.new(s.runtime, {
			{ body = s.json({ accessToken = "scope1", tokenType = "Bearer", expiresIn = 600 }) },
			{ status = 401 },
			{
				body = s.json({ accessToken = "scope2", tokenType = "Bearer", expiresIn = 600 }),
				check = function(req)
					check(
						string.find(req.Url, "/42/token", 1, true)
							and req.Headers.Authorization == "Bearer identity"
					)
				end,
			},
			{ status = 401 },
		})
		local c = SDK.new({ runtime = s.runtime, backend = f.backend, userSession = { store = store } })
		s.run(function()
			local result = c:scoped(42).fields:schema()
			check(not result.ok and result.error.kind == "Unauthorized")
		end)
		check(f.count() == 4 and (store.get() :: Session.Tokens).accessToken == "identity")
	end)
	test("late and concurrent scoped 401s join one exchange without evicting the replacement", function()
		local s = Scheduler.new()
		local calls, successes = 0, 0
		local provider = Scoped.new(s.runtime, identity(s), 42, function(): Core.Result<Auth.Token>
			calls += 1
			s.runtime.wait(0.1)
			return {
				ok = true,
				value = {
					accessToken = "scope" .. tostring(calls),
					tokenType = "Bearer",
					expiresIn = 600,
				},
			}
		end)
		s.run(function()
			check(provider.get().ok)
			local observed = (provider.version :: () -> number)()
			for _ = 1, 5 do
				s.runtime.spawn(function()
					(provider.invalidate :: (number?) -> ())(observed)
					check(provider.onUnauthorized(observed))
					successes += 1
				end)
			end
			s.runtime.wait(0.2)
			local invalidate = provider.invalidate :: (number?) -> ()
			invalidate(observed)
			check(provider.onUnauthorized(observed) and calls == 2)
		end)
		check(successes == 5 and calls == 2)
	end)
	test(
		"identity refresh does not discard independent universe tokens and destroy clears providers",
		function()
			local s = Scheduler.new()
			local session = identity(s)
			local calls, refreshes = 0, 0
			session.bind(function(): Core.Result<any>
				refreshes += 1
				return {
					ok = true,
					value = {
						accessToken = "rotated",
						refreshToken = "rotated-refresh",
						expiresIn = 3600,
					},
				}
			end)
			local provider = Scoped.new(s.runtime, session, 42, function(): Core.Result<Auth.Token>
				calls += 1
				return { ok = true, value = { accessToken = "scope", tokenType = "Bearer", expiresIn = 600 } }
			end)
			s.run(function()
				check(provider.get().ok)
				local epoch = session.epoch()
				check(session.onUnauthorized((session.version :: () -> number)()))
				check(session.epoch() == epoch and provider.get().ok and calls == 1 and refreshes == 1)
				local destroy = provider.destroy :: () -> ()
				destroy()
				check(not provider.get().ok and not pcall(function()
					provider.apply({})
				end))
			end)
		end
	)
	test("scoped unkeyed mutations never replay and public health does not exchange", function()
		local s = Scheduler.new()
		local store = Session.memoryStore()
		store.set({ accessToken = "identity", refreshToken = "refresh" })
		local f = Fake.new(s.runtime, {
			{
				body = s.json({ status = "ok" }),
				check = function(req)
					check(req.Headers.Authorization == nil)
				end,
			},
			{ body = s.json({ accessToken = "scope", tokenType = "Bearer", expiresIn = 600 }) },
			{ status = 401 },
		})
		local client = SDK.new({ runtime = s.runtime, backend = f.backend, userSession = { store = store } })
		local scoped = client:scoped(42)
		check(scoped._helpers.fields == client:scoped("42")._helpers.fields)
		s.run(function()
			check(scoped.auth:health().ok and f.count() == 1)
			local result = scoped.party:createParty({ ownerId = 1, placeId = 2 })
			check(not result.ok and result.error.kind == "Unauthorized" and f.count() == 3)
		end)
	end)
	test(
		"tenant requests reject removed fields and distinguish org grants, clears and nullable plans",
		function()
			check(
				not Validation.body(
					"auth.createAccount",
					{ username = "u", password = "p", accountType = "USER" }
				)
			)
			check(not Validation.body("auth.updateCurrentAccount", { universeId = 42 }))
			check(Validation.body("auth.patchMember", { overrides = {} }))
			check(not Validation.body("auth.patchMember", { role = "SUPER_ADMIN" }))
			check(
				Validation.body(
					"auth.setOrgPlan",
					{ maxUniverses = SDK.null, maxMembers = 10, maxServiceAccounts = SDK.null }
				)
			)
			check(not Path.build(SDK.endpoints["auth.listServiceAccounts"], {}, nil))
			local path = Path.build(
				SDK.endpoints["auth.removeMember"],
				{ path = { org = "o", user = "u" } :: { [string]: unknown } },
				42
			)
			check(path == "/api/auth/orgs/o/members/u")
			check(
				not Path.build(
					SDK.endpoints["auth.exchangeScopedToken"],
					{ path = { universe = 0 } :: { [string]: unknown } },
					nil
				)
			)
			local err = Errors.domain(
				409,
				"auth.patchMember",
				1,
				{ errorCode = "last_owner", message = "secret", token = "secret" }
			)
			check(not err.ok and err.error.code == "last_owner" and err.error.body == "[redacted]")
			local unknown = Errors.domain(400, "auth.patchMember", 1, { errorCode = "secret" })
			check(not unknown.ok and unknown.error.code == nil)
		end
	)
end
