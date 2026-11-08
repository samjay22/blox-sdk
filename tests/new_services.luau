--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Audit = require("../src/Types/Audit")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Session = require("../src/Auth/UserSession")
local Json = require("../src/Core/Json")
local Universe = require("../src/Core/Universe")
--- Fail a regression without logging request or response payloads.
local function check(value: unknown, _second: unknown?, _third: unknown?)
	assert(value, "New service regression failed")
end
--- Build a fresh offline client with enough earned budget to exercise one retry per call.
local function client(
	s: Scheduler.Scheduler,
	steps: { Fake.Step },
	config: SDK.Config?
): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	local cfg: SDK.Config = config or {}
	cfg.runtime = s.runtime
	cfg.backend = fake.backend
	cfg.retryRatio = 1
	cfg.retries = 1
	if not cfg.userSession and not cfg.authProvider then
		cfg.key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
		cfg.universeId = 123
	end
	return SDK.new(cfg), fake
end
--- Supply an explicit valid event independent of generated fixtures.
local function event(): Audit.EventInput
	return {
		occurredAt = "2026-11-05T00:00:00Z",
		actorType = "SYSTEM",
		actorId = "server",
		action = "player.join",
		resourceType = "player",
		resourceId = "7",
		outcome = "SUCCESS",
	}
end
--- Assert a boundary failure without disclosing payloads.
local function failed(result: Core.Result<any>, kind: string)
	check(not result.ok and result.error.kind == kind)
end
--- Register contract-specific runtime regressions in the existing deterministic harness.
return function(test: (string, () -> ()) -> ())
	test("gateway prefixes, exact permissions, bearer key and scoped paths", function()
		local s = Scheduler.new()
		local urls: { string } = {}
		local c, f = client(s, {
			{
				body = s.json({ items = Json.array({}) }),
				check = function(r)
					table.insert(urls, r.Url)
					check(
						type(r.Headers.Authorization) == "string"
							and string.sub(r.Headers.Authorization :: string, 1, 11) == "Bearer bsa_"
					)
				end,
			},
			{
				body = s.json({ items = Json.array({}) }),
				check = function(r)
					table.insert(urls, r.Url)
				end,
			},
			{
				body = s.json({ items = Json.array({}) }),
				check = function(r)
					table.insert(urls, r.Url)
				end,
			},
			{
				body = s.json({ items = Json.array({}) }),
				check = function(r)
					table.insert(urls, r.Url)
				end,
			},
		}, {
			levels = {
				AuditService = "READ",
				LeaderboardService = "READ",
				FieldsService = "READ",
			},
		})
		s.run(function()
			check(c.audit:list().ok)
			check(c.fields:products().ok)
			check(c.leaderboards:list().ok)
			check(c.fields:products().ok)
			failed(c.leaderboards:rollover({ path = { name = "wins" } }), "Local")
			failed(c.audit:append(event()), "Local")
		end)
		check(f.count() == 4)
		check(urls[1] == "https://lb1.blox-api.com/audit-service/api/audit/events?universeId=123")
		check(urls[2] == "https://lb1.blox-api.com/fields-service/api/fields/universes/123/products")
		check(urls[3] == "https://lb1.blox-api.com/leaderboard-service/api/leaderboards/universes/123/boards")
		check(urls[4] == "https://lb1.blox-api.com/fields-service/api/fields/universes/123/products")
	end)
	test("user JWT works for new services and never leaks into URLs", function()
		local s = Scheduler.new()
		local store = Session.memoryStore()
		store.set({
			accessToken = "synthetic-jwt",
			refreshToken = "synthetic-refresh",
			expiresAt = 1800000000,
		})
		local c, f = client(s, {
			{
				body = s.json({ items = Json.array({}) }),
				check = function(r)
					check(r.Headers.Authorization == "Bearer synthetic-jwt")
					check(not string.find(r.Url, "jwt"))
				end,
			},
		}, { userSession = { store = store }, universeId = 123 })
		s.run(function()
			check(c.fields:products().ok)
		end)
		check(f.count() == 1)
	end)
	test("positive universe validation covers config, path, query, body and nested batches", function()
		for _, id in
			{ 0, -1, 1.5, math.huge, 0 / 0, "0", "-1", "1.5", "no", "01", "9223372036854775808" } :: { unknown }
		do
			check(not Universe.valid(id))
		end
		check(Universe.valid("9223372036854775807"))
		check(Universe.valid(1))
		local s = Scheduler.new()
		local c, f = client(s, {})
		s.run(function()
			failed(c.fields:products({ path = { universeId = 0 } }), "Local")
			failed(c.audit:list({ query = { universeId = -1 } }), "Local")
			local input = event()
			input.universeId = 0
			failed(c.audit:append(input), "Local")
			input.universeId = 124
			failed(c.audit:batch({ events = { input } }), "Local")
			check(not pcall(function()
				c:withUniverse("zero")
			end))
		end)
		local global = client(s, {}, {
			authProvider = {
				kind = "custom",
				apply = function(_h) end,
				onUnauthorized = function()
					return false
				end,
			},
		})
		s.run(function()
			failed(global.fields:products({ path = { universeId = -1 } }), "Validation")
		end)
		check(f.count() == 0)
	end)
	test("leaderboard single and batch submission IDs survive retries and caller mutation", function()
		local s = Scheduler.new()
		local bodies: { string } = {}
		local capture = function(r: Core.HttpRequest)
			table.insert(bodies, r.Body :: string)
		end
		local score = { submissionId = "result", userId = 7, score = 9, applied = true, periodId = "period" }
		local c, f = client(s, {
			{ status = 503, delay = 0.1, check = capture },
			{ body = s.json(score), check = capture },
			{ status = 503, check = capture },
			{ body = s.json({ score }), check = capture },
		})
		local body = { userId = 7, score = 9 }
		s.run(function()
			s.runtime.delay(0.05, function()
				body.score = 999
			end)
			check(c.leaderboards:submit({ path = { name = "wins" }, body = body }).ok)
			check(c.leaderboards:batch({
				path = { name = "wins" },
				body = {
					scores = {
						{ userId = 7, score = 9 },
						{
							userId = 8,
							score = 10,
							submissionId = "provided",
						},
					},
				},
			}).ok)
		end)
		check(f.count() == 4 and bodies[1] == bodies[2] and bodies[3] == bodies[4])
		check(string.find(bodies[1], '"score":9', 1, true))
		check(string.find(bodies[3], '"submissionId":"provided"', 1, true))
	end)
	test("audit append and batch generate per-event keys, reuse them on retries, enforce max 500", function()
		local s = Scheduler.new()
		local bodies: { string } = {}
		local capture = function(r: Core.HttpRequest)
			table.insert(bodies, r.Body :: string)
		end
		local c, f = client(s, {
			{ status = 503, check = capture },
			{ status = 202, body = s.json({ accepted = 1, duplicate = 0 }), check = capture },
			{ status = 503, check = capture },
			{ status = 202, body = s.json({ accepted = 2, duplicate = 0 }), check = capture },
		})
		s.run(function()
			check(c.audit:append(event()).ok)
			check(c.audit:batch({ events = { event(), event() } }).ok)
			failed(c.audit:batch({ events = {} }), "Validation")
			local many = {}
			for _ = 1, 501 do
				table.insert(many, event())
			end
			failed(c.audit:batch({ events = many }), "Validation")
		end)
		check(f.count() == 4 and bodies[1] == bodies[2] and bodies[3] == bodies[4])
		local keys = {}
		for key in string.gmatch(bodies[3], '"idemKey":"([^"]+)"') do
			table.insert(keys, key)
		end
		check(#keys == 2 and keys[1] ~= keys[2])
	end)
	test("manual rollover never retries even with retry override or a 401 refresh provider", function()
		for _, status in { 503, 401, 429 } do
			local s = Scheduler.new()
			local refreshed = false
			local c, f = client(s, { { status = status } }, {
				universeId = 123,
				authProvider = {
					kind = "custom",
					apply = function(_h) end,
					onUnauthorized = function()
						refreshed = true
						return true
					end,
				},
			})
			s.run(function()
				local result = c.leaderboards:rollover({ path = { name = "wins" } }, { retry = 10 })
				check(not result.ok)
			end)
			check(f.count() == 1 and not refreshed)
		end
	end)
	test("cursor helpers preserve filters, encode opaque cursors, stop on null and expose failure", function()
		local s = Scheduler.new()
		local urls: { string } = {}
		local capture = function(r: Core.HttpRequest)
			table.insert(urls, r.Url)
		end
		local c, f = client(s, {
			{ body = s.json({ items = Json.array({}), nextCursor = "a/b?" }), check = capture },
			{ body = s.json({ items = Json.array({}), nextCursor = Json.null }), check = capture },
			{ status = 400 },
		})
		local request = { query = { action = "player.*", limit = 20 } }
		s.run(function()
			local pages = c.audit:listPages(request)
			local a = pages()
			check(a and a.ok)
			local b = pages()
			check(b and b.ok)
			check(pages() == nil)
			local failures = c.fields:productsPages()
			local bad = failures()
			check(bad and not bad.ok)
			check(failures() == nil)
		end)
		check(f.count() == 3 and string.find(urls[2], "cursor=a%2Fb%3F", 1, true))
		check(string.find(urls[2], "action=player.%2A", 1, true))
		check((request.query :: any).cursor == nil)
	end)
	test("cursor cycles and page limits yield a visible terminal error", function()
		local count = 0
		local pages = SDK.cursorPages(function(_cursor: string?): Core.Result<{ nextCursor: string }>
			count += 1
			return { ok = true, value = { nextCursor = "same" } }
		end, function(page)
			return page.nextCursor
		end, 10)
		check((pages() :: any).ok)
		check((pages() :: any).ok)
		failed(pages() :: any, "Local")
		check(pages() == nil and count == 2)
		local bounded = SDK.cursorPages(function(_cursor: string?): Core.Result<{ nextCursor: string }>
			return { ok = true, value = { nextCursor = "next" } }
		end, function(page)
			return page.nextCursor
		end, 1)
		check((bounded() :: any).ok)
		failed(bounded() :: any, "Local")
		check(bounded() == nil)
	end)
	test(
		"audit writer enqueues without yielding, flushes on size and close, never exceeds batch bound",
		function()
			local s = Scheduler.new()
			local sent: { string } = {}
			local capture = function(r: Core.HttpRequest)
				check(string.find(r.Url, "/events/batch", 1, true))
				table.insert(sent, r.Body :: string)
			end
			local c, f = client(s, {
				{
					delay = 0.2,
					status = 202,
					body = s.json({ accepted = 500, duplicate = 0 }),
					check = capture,
				},
				{ status = 202, body = s.json({ accepted = 1, duplicate = 0 }), check = capture },
			})
			local writer = c:auditWriter({ batchSize = 500, capacity = 501, interval = 5 })
			for _ = 1, 501 do
				check(writer:enqueue(event()))
			end
			check(f.count() == 0 and s.time() == 0 and not writer:enqueue(event()))
			s.run(function()
				check(c:flush(2))
				c:destroy()
			end)
			check(f.count() == 2 and writer:pending() == 0 and not writer:enqueue(event()))
			local _, count = string.gsub(sent[1], '"idemKey":', "")
			check(count == 500)
		end
	)
	test(
		"audit interval flush retains failed events and keys, rejects incomplete acknowledgements",
		function()
			local s = Scheduler.new()
			local sent: { string } = {}
			local capture = function(r: Core.HttpRequest)
				table.insert(sent, r.Body :: string)
			end
			local c, f = client(s, {
				{ status = 400, check = capture },
				{ status = 202, body = s.json({ accepted = 0, duplicate = 0 }), check = capture },
				{ status = 202, body = s.json({ accepted = 0, duplicate = 1 }), check = capture },
			})
			local writer = c:auditWriter({ batchSize = 2, interval = 0.1 })
			check(writer:enqueue(event()))
			s.run(function()
				s.runtime.wait(0.15)
				check(writer:pending() == 1 and writer.lastError ~= nil)
				s.runtime.wait(0.1)
				check(writer:pending() == 1 and writer.lastError ~= nil)
				s.runtime.wait(0.1)
				check(writer:pending() == 0 and writer.lastError == nil)
				c:destroy()
			end)
			check(f.count() == 3 and sent[1] == sent[2] and sent[2] == sent[3])
		end
	)
	test("audit writer close has a finite deadline and destroy cancels timers", function()
		local s = Scheduler.new()
		local c, f =
			client(s, { { delay = 2, status = 202, body = s.json({ accepted = 1, duplicate = 0 }) } })
		local writer = c:auditWriter({ batchSize = 1, interval = 1 })
		check(writer:enqueue(event()))
		s.run(function()
			check(not writer:close(0.1))
			check(s.time() < 0.2)
			c:destroy()
		end)
		check(f.count() == 1 and s.pending() == 0)
	end)
	test(
		"Fields runtime snapshot polls opaque ETag, keeps last good state on 304 and errors, signals changes",
		function()
			local s = Scheduler.new()
			local versions: { string } = {}
			local capture = function(r: Core.HttpRequest)
				table.insert(versions, tostring(r.Headers["If-None-Match"]))
				check(not string.find(r.Url, "version", 1, true))
			end
			local flag = {
				universeId = 123,
				key = "double_xp",
				enabled = true,
				rolloutPct = 100,
				version = 1,
				updatedAt = "2026-11-05T00:00:00Z",
				createdAt = "2026-11-05T00:00:00Z",
				displayName = "Double XP",
				type = "bool",
				defaultValue = false,
				rules = Json.array({}),
				variants = Json.array({}),
				sticky = false,
			}
			local c, f = client(s, {
				{
					body = s.json({
						version = 1,
						maintenance = { enabled = false, message = "", allowlistUserIds = Json.array({}) },
						gameValues = { welcome = "Hello" },
						flags = {
							flag,
						},
					}),
					headers = { ETag = '"hash-one"' },
					check = capture,
				},
				{ status = 304, check = capture },
				{ status = 400, check = capture },
				{
					body = s.json({
						version = 2,
						maintenance = { enabled = false, message = "", allowlistUserIds = Json.array({}) },
						gameValues = { welcome = "Welcome" },
						flags = Json.array({}),
					}),
					check = capture,
				},
			})
			local cache = c:runtimeSnapshot(0.1)
			local changes = 0
			local connection = cache.changed:connect(function(_value)
				changes += 1
			end)
			cache.changed:connect(function(_value)
				error("Synthetic handler failure")
			end)
			check(cache:get("welcome") == nil and not cache:isEnabled("double_xp"))
			s.run(function()
				s.runtime.wait(0.05)
				check(
					cache:get("welcome") == "Hello" and cache:isEnabled("double_xp") and cache:version() == 1
				)
				s.runtime.wait(0.1)
				check(cache:version() == 1 and changes == 1)
				s.runtime.wait(0.1)
				check(cache:get("welcome") == "Hello" and cache.lastError ~= nil)
				s.runtime.wait(0.1)
				check(cache:get("welcome") == "Welcome" and not cache:isEnabled("double_xp") and changes == 2)
				connection:disconnect()
				c:destroy()
			end)
			check(
				f.count() == 4
					and versions[1] == "nil"
					and versions[2] == '"hash-one"'
					and versions[4] == '"hash-one"'
					and s.pending() == 0
			)
		end
	)
	test(
		"snapshot rejects malformed/regressing state and no background tasks survive shared destroy",
		function()
			local s = Scheduler.new()
			local good = {
				version = 4,
				maintenance = { enabled = false, message = "", allowlistUserIds = Json.array({}) },
				gameValues = { n = 2 },
				flags = Json.array({}),
			}
			local c, f = client(s, {
				{ body = s.json(good) },
				{
					body = s.json({
						version = 3,
						maintenance = { enabled = false, message = "", allowlistUserIds = Json.array({}) },
						gameValues = {},
						flags = Json.array({}),
					}),
				},
				{ body = s.json({ version = 5 }) },
			})
			local cache = c:runtimeSnapshot(0.1)
			s.run(function()
				s.runtime.wait(0.05)
				check(cache:version() == 4)
				s.runtime.wait(0.1)
				check(cache:version() == 4 and cache.lastError ~= nil)
				s.runtime.wait(0.1)
				check(cache:get("n") == 2)
				c:withUniverse(123):destroy()
			end)
			check(f.count() >= 3 and s.pending() == 0)
		end
	)
	test("keyed 401 replay preserves key while refreshing at most once", function()
		local s = Scheduler.new()
		local refreshed = 0
		local bodies: { string } = {}
		local capture = function(r: Core.HttpRequest)
			table.insert(bodies, r.Body :: string)
		end
		local c, f = client(s, {
			{ status = 401, check = capture },
			{
				status = 202,
				body = s.json({ accepted = 0, duplicate = 1 }),
				check = capture,
			},
		}, {
			universeId = 123,
			authProvider = {
				kind = "custom",
				apply = function(_h) end,
				onUnauthorized = function()
					refreshed += 1
					return true
				end,
			},
		})
		s.run(function()
			check(c.audit:append(event()).ok)
		end)
		check(f.count() == 2 and refreshed == 1 and bodies[1] == bodies[2])
	end)
end
