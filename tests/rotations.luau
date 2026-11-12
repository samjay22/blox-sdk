--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local Json = require("../src/Core/Json")
local Copy = require("../src/Core/Idempotency")
local Instant = require("../src/Core/Instant")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local V = require("./FixtureVectors").rotations
local ID = "00000000-0000-4000-8000-000000000001"
--- Fail a regression without logging request secrets or payloads.
local function check(value: unknown, message: string?)
	assert(value, message or "Rotations regression at " .. tostring(debug.info(2, "l")))
end
--- Bind synthetic WRITE-capable credentials and the existing deterministic mock transport.
local function client(s: Scheduler.Scheduler, steps: { Fake.Step }): (SDK.Client, Fake.Fake)
	local f = Fake.new(s.runtime, steps)
	return SDK.new({
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		runtime = s.runtime,
		backend = f.backend,
		profileSync = { enabled = false },
		levels = { FieldsService = "ADMIN" },
		requestsPerMinute = 480,
		burst = 100,
		retries = 1,
		retryRatio = 1,
	}),
		f
end
--- Make an authoritative head with an edge relative to the scheduler's 2023 Unix epoch.
local function active(id: string, finish: string): Wire.RotationActive
	local value = Copy.copy(V.active)
	value.current.id = id
	value.current.endsAt = finish
	return value
end
--- Assemble a minimal ETag snapshot, preserving absent versus present-empty rotations.
local function snapshot(values: { Wire.RotationActive }?, version: number?): any
	return {
		version = version or 1,
		flags = Json.array({}),
		maintenance = { enabled = false, message = "", allowlistUserIds = Json.array({}) },
		rotations = if values then Json.array(values) else nil,
	}
end
return function(test: (string, () -> ()) -> ())
	for _, vector in V.vectors do
		test("Rotations wire golden " .. vector.endpoint, function()
			local s = Scheduler.new()
			local c, f = client(s, {
				{
					body = s.json(vector.response),
					check = function(request: Core.HttpRequest)
						check(request.Method == vector.method and request.Url == vector.url, vector.endpoint)
						if vector.request.body then
							check(request.Body == Json.encode(vector.request.body), "Request body drift")
						end
					end,
				},
			})
			s.run(function()
				local method = string.match(vector.endpoint, "%.(.+)$")
				local facade: any = c.fields
				local result = facade[method](facade, vector.request)
				check(
					result.ok and Json.encode(result.value) == Json.encode(vector.response),
					vector.endpoint
				)
			end)
			check(f.count() == 1)
			c:destroy()
		end)
	end
	test("Rotations/Generators helpers preserve typed results and preview/odds request shape", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json(V.active) },
			{ body = s.json(V.stock) },
			{ body = s.json(V.roll) },
			{ body = s.json({ V.roll.results[1] }) },
			{ body = s.json(V.odds) },
		})
		local rotations, generators = c.fields:rotations(), c.fields:generators()
		s.run(function()
			local got = rotations:get("weather")
			check(got.ok and got.value.current ~= Json.null)
			local stock = rotations:getStock(ID)
			check(stock.ok and stock.value[1].remaining == 19)
			local roll = generators:roll("card_pack", 7)
			check(roll.ok and #roll.value.results[1].picks == 5 and roll.value.transaction.replayed == false)
			check(generators:preview("card_pack", 7, 1).ok)
			check(generators:getOdds("card_pack", 7).ok)
		end)
		check(f.count() == 5)
		c:destroy()
	end)
	test(
		"roll and claim auto/supplied idempotency keys survive transient retries and caller tables stay unchanged",
		function()
			for _, claim in { false, true } do
				for _, supplied in { false, true } do
					local s = Scheduler.new()
					local first: string? = nil
					local header: unknown = nil
					local capture = function(request: Core.HttpRequest)
						local key = string.match(request.Body or "", '"idempotencyKey":"([^"]+)"')
						check(
							key ~= nil
								and (
									request.Headers["Idempotency-Key"] == nil
									or request.Headers["Idempotency-Key"] == key
								)
						)
						if supplied then
							check(key == "saved-key")
						end
						if first then
							check(first == request.Body and header == key)
						else
							first = request.Body
							header = key
						end
					end
					local c, f = client(s, {
						{ status = 503, check = capture },
						{ body = s.json(if claim then V.claim else V.roll), check = capture },
					})
					local options = { playerId = 7, idempotencyKey = if supplied then "saved-key" else nil }
					s.run(function()
						local result = if claim
							then c.fields:rotations():claim(ID, "packs:0", "starter_pack", 1, options)
							else c.fields
								:generators()
								:roll("card_pack", 7, { idempotencyKey = options.idempotencyKey })
						check(result.ok)
					end)
					check(
						f.count() == 2 and options.idempotencyKey == (if supplied then "saved-key" else nil)
					)
					c:destroy()
				end
			end
		end
	)
	test("409 sold-out, expired and insufficient-funds are redacted non-retryable conflicts", function()
		for _, code in
			{ "rotation_out_of_stock", "rotation_expired", "insufficient_funds", "idempotency_conflict" }
		do
			local s = Scheduler.new()
			local c, f = client(
				s,
				{ { status = 409, body = s.json({ code = code, message = "Do not expose this" }) } }
			)
			s.run(function()
				local result = c.fields:rotations():claim(ID, "packs:0", "starter_pack", 1, { playerId = 7 })
				check(
					not result.ok
						and result.error.code == code
						and result.error.kind == "Conflict"
						and result.error.status == 409
						and result.error.body == "[redacted]"
				)
			end)
			check(f.count() == 1)
			c:destroy()
		end
	end)
	test("claim permanent replay retains its historical remaining and transaction.replayed", function()
		local s = Scheduler.new()
		local c, f = client(s, { { body = s.json(V.claim) }, { body = s.json(V.claim) } })
		s.run(function()
			local rotations = c.fields:rotations()
			local first =
				rotations:claim(ID, "packs:0", "starter_pack", 1, { playerId = 7, idempotencyKey = "same" })
			local again =
				rotations:claim(ID, "packs:0", "starter_pack", 1, { playerId = 7, idempotencyKey = "same" })
			check(
				first.ok
					and again.ok
					and Json.encode(first.value) == Json.encode(again.value)
					and again.value.remaining == 19
					and not again.value.transaction.replayed
			)
		end)
		check(f.count() == 2)
		c:destroy()
	end)
	test("closed helpers and malformed gameplay inputs fail before transport", function()
		local s = Scheduler.new()
		local c, f = client(s, {})
		local r, g = c.fields:rotations(), c.fields:generators()
		s.run(function()
			for _, key in { "", "../unsafe", "a/b", string.rep("x", 101) } do
				check(not r:get(key).ok)
				check(not g:roll(key, 7).ok)
				check(not g:getOdds(key).ok)
			end
			for _, count in { 0, 11, 1.5, math.huge } do
				check(not g:roll("pack", 7, { count = count }).ok)
				check(not g:preview("pack", 7, count).ok)
			end
			check(not g:roll("pack", 0).ok and not g:getOdds("pack", -1).ok)
			check(not g:roll("pack", 7, { idempotencyKey = "bad key" }).ok)
			check(not g:roll("pack", 7, { unknown = true } :: any).ok)
			check(not r:getStock("not-a-uuid").ok)
			check(not r:claim(ID, "slot", "entry", 0, { playerId = 7 }).ok)
			check(not r:claim(ID, "slot", "entry", 101, { playerId = 7 }).ok)
			check(not r:claim(ID, "slot", "entry", 1, { playerId = 0 }).ok)
			check(not r:claim(ID, "slot", "entry", 1, { playerId = 7, idempotencyKey = "bad key" }).ok)
			check(not r:claim(ID, "slot", "entry", 1, { playerId = 7, unknown = true } :: any).ok)
			c:destroy()
			check(not r:get("weather").ok and not r:getAll().ok and not g:roll("pack", 7).ok)
		end)
		check(f.count() == 0)
	end)
	test("GetAll catalog fallback and partial failure use actual active endpoints", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json({ { kind = "ROTATION", key = "weather", version = 1, definition = {} } }) },
			{ body = s.json(V.active) },
			{ status = 403 },
		})
		s.run(function()
			local all = c.fields:rotations():getAll()
			check(all.ok and #all.value == 1)
			check(not c.fields:rotations():getAll().ok)
		end)
		check(f.count() == 3)
		c:destroy()
	end)
	test("UTC remaining time handles epoch, leap centuries, fractions and expired edges", function()
		check(Instant.unix("1970-01-01T00:00:00Z") == 0)
		check(Instant.unix("2000-02-29T00:00:00Z") == 951782400)
		check(Instant.unix("1900-02-29T00:00:00Z") == nil)
		check(Instant.unix("2023-11-14T22:13:20.5Z") == 1700000000.5)
		local s = Scheduler.new()
		local c = client(s, {})
		local r = c.fields:rotations()
		check(
			r:timeRemaining(active("one", "2023-11-14T22:13:21.5Z").current :: Wire.RotationInstance) == 1.5
		)
		check(r:timeRemaining(active("one", "2023-11-14T22:13:19Z").current :: Wire.RotationInstance) == 0)
		c:destroy()
	end)
	test("Watch fallback schedules one refresh at endsAt+jitter and never loops on expired heads", function()
		local s = Scheduler.new()
		local one, two = active("one", "2023-11-14T22:13:21Z"), active("two", "2023-11-14T22:13:21Z")
		local c, f = client(s, { { body = s.json(one) }, { body = s.json(two) } })
		local ids: { string } = {}
		local watch = c.fields:rotations():watch("weather", function(instance)
			table.insert(ids, instance.id)
		end)
		s.run(function()
			s.runtime.wait(1.1)
			check(f.count() == 1 and #ids == 1)
			s.runtime.wait(0.6)
			check(f.count() == 2 and #ids == 2)
			s.runtime.wait(100)
			check(f.count() == 2)
			watch:disconnect()
			c:destroy()
		end)
		check(s.pending() == 0)
	end)
	test(
		"Watch snapshot mode costs zero extra HTTP, handles same-version ETag changes, 304 and dedup",
		function()
			local s = Scheduler.new()
			local one, two = active("one", "2023-11-14T22:13:21Z"), active("two", "2023-11-14T22:13:22Z")
			local c, f = client(s, {
				{ body = s.json(snapshot({ one })), headers = { ETag = '"a"' } },
				{ status = 304 },
				{ body = s.json(snapshot({ two })), headers = { ETag = '"b"' } },
				{ body = s.json(snapshot({ two }, 2)), headers = { ETag = '"c"' } },
				{ body = s.json(snapshot({}, 3)), headers = { ETag = '"d"' } },
			})
			local cache = c:runtimeSnapshot(0.5)
			check(cache == c:runtimeSnapshot(0.5))
			local ids: { string } = {}
			local r = c.fields:rotations()
			local watch = r:watch("weather", function(instance)
				table.insert(ids, instance.id)
			end)
			cache.changed:connect(function(_value)
				error("Isolate unrelated listener")
			end)
			s.run(function()
				s.runtime.wait(0.6)
				check(#ids == 1 and ids[1] == "one")
				local all = r:getAll()
				check(all.ok and #all.value == 1 and f.count() == 1)
				s.runtime.wait(1)
				check(#ids == 1 and f.count() == 2)
				s.runtime.wait(1)
				check(#ids == 2 and ids[2] == "two" and f.count() == 3)
				s.runtime.wait(1)
				check(#ids == 2 and f.count() == 4)
				s.runtime.wait(1)
				check(#ids == 2 and f.count() == 5)
				local empty = r:getAll()
				check(empty.ok and #empty.value == 0 and f.count() == 5)
				watch:disconnect()
				c:destroy()
			end)
			check(s.pending() == 0)
		end
	)
	test(
		"Watch legacy snapshot omits rotations: unrelated snapshot changes do not add active polls",
		function()
			local s = Scheduler.new()
			local one = active("one", "2023-11-14T22:13:25Z")
			local c, f = client(s, {
				{ body = s.json(snapshot(nil)) },
				{ body = s.json(one) },
				{ body = s.json(snapshot(nil, 2)) },
			})
			c:runtimeSnapshot(1)
			local n = 0
			local watch = c.fields:rotations():watch("weather", function(_instance)
				n += 1
			end)
			s.run(function()
				s.runtime.wait(2.2)
				check(n == 1 and f.count() == 3)
				watch:disconnect()
				c:destroy()
			end)
		end
	)
	test(
		"Watch switches fallback to a later snapshot, resumes on snapshot destroy and disconnect cancels timers",
		function()
			local s = Scheduler.new()
			local one = active("one", "2023-11-14T22:13:25Z")
			local c, f = client(
				s,
				{ { body = s.json(one) }, { body = s.json(snapshot({ one })) }, { body = s.json(one) } }
			)
			local n = 0
			local watch = c.fields:rotations():watch("weather", function(_instance)
				n += 1
				error("Isolated callback")
			end)
			s.run(function()
				s.runtime.wait(0.6)
				local cache = c:runtimeSnapshot(10)
				s.runtime.wait(0.6)
				check(n == 1 and f.count() == 2)
				cache:destroy()
				s.runtime.wait(0.6)
				check(n == 1 and f.count() == 3)
				watch:disconnect()
				watch:disconnect()
				s.runtime.wait(20)
				check(f.count() == 3)
				c:destroy()
			end)
		end
	)
	test(
		"Watch error/disabled refresh stops until explicit retry; client destroy cancels in-flight callbacks",
		function()
			local s = Scheduler.new()
			local c, f = client(s, {
				{ status = 409, body = s.json({ code = "rotation_clock_regressed" }) },
				{ body = s.json({ enabled = false, current = Json.null, next = Json.null }) },
				{ body = s.json(V.active), delay = 1 },
			})
			local n = 0
			local watch = c.fields:rotations():watch("weather", function(_instance)
				n += 1
			end)
			s.run(function()
				s.runtime.wait(1)
				check(watch.lastError ~= nil and f.count() == 1)
				watch:refresh()
				s.runtime.wait(1)
				check(watch.lastError == nil and f.count() == 2 and n == 0)
				watch:refresh()
				s.runtime.wait(0.6)
				c:destroy()
				s.runtime.wait(2)
				check(n == 0 and f.count() == 3)
			end)
			check(s.pending() == 0)
		end
	)
	test("all randomness history page helpers preserve opaque cursors and terminate on null", function()
		for _, name in
			{ "randomDefinitionHistory", "rotationHistory", "playerRollHistory", "playerClaimHistory" }
		do
			local s = Scheduler.new()
			local c, f = client(s, {
				{ body = s.json({ items = Json.array({}), nextCursor = "opaque /?" }) },
				{
					body = s.json({ items = Json.array({}), nextCursor = Json.null }),
					check = function(request)
						check(string.find(request.Url, "cursor=opaque%20%2F%3F", 1, true) ~= nil)
					end,
				},
			})
			s.run(function()
				local facade: any = c.fields
				local pages = facade[name .. "Pages"](facade, {
					path = if string.sub(name, 1, 6) == "player"
						then { playerId = 7 }
						else { key = "weather" },
				})
				local first, second = pages(), pages()
				check(first and first.ok and second and second.ok and pages() == nil)
			end)
			check(f.count() == 2)
			c:destroy()
		end
	end)
	test("roll replay keeps original grants/pity and roll conflicts do not retry", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json(V.roll) },
			{ body = s.json(V.roll) },
			{ status = 409, body = s.json({ code = "insufficient_funds" }) },
		})
		s.run(function()
			local g = c.fields:generators()
			local first = g:roll("card_pack", 7, { idempotencyKey = "persisted" })
			local replay = g:roll("card_pack", 7, { idempotencyKey = "persisted" })
			check(first.ok and replay.ok and Json.encode(first.value) == Json.encode(replay.value))
			local failed = g:roll("card_pack", 7)
			check(not failed.ok and failed.error.code == "insufficient_funds")
		end)
		check(f.count() == 3)
		c:destroy()
	end)
	test("GetAll fails on individual head error instead of returning a partial catalog", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json({ { kind = "ROTATION", key = "weather", version = 1, definition = {} } }) },
			{ status = 404, body = s.json({ code = "rotation_definition_not_found" }) },
		})
		s.run(function()
			local result = c.fields:rotations():getAll()
			check(not result.ok and result.error.code == "rotation_definition_not_found")
		end)
		check(f.count() == 2)
		c:destroy()
	end)
	test("Watch snapshot errors retain last head without extra requests or fallback timers", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{
				body = s.json(snapshot({ active("one", "2023-11-14T22:13:21Z") })),
				headers = {
					ETag = '"one"',
				},
			},
			{ status = 400 },
			{ status = 304 },
		})
		local cache = c:runtimeSnapshot(1)
		local calls = 0
		local watch = c.fields:rotations():watch("weather", function(_instance)
			calls += 1
		end)
		s.run(function()
			s.runtime.wait(2.2)
			check(calls == 1 and cache.lastError ~= nil and f.count() == 2)
			s.runtime.wait(1.5)
			check(calls == 1 and cache.lastError == nil and f.count() == 3)
			watch:disconnect()
			c:destroy()
		end)
	end)
	test("disconnect before first response and same-ID refresh never dispatch duplicate callbacks", function()
		local s = Scheduler.new()
		local one = active("one", "2023-11-14T22:13:25Z")
		local c, f =
			client(s, { { body = s.json(one) }, { body = s.json(one) }, { body = s.json(one), delay = 1 } })
		local calls = 0
		local watch = c.fields:rotations():watch("weather", function(_instance)
			calls += 1
		end)
		s.run(function()
			s.runtime.wait(0.6)
			watch:refresh()
			s.runtime.wait(0.6)
			check(calls == 1)
			watch:refresh()
			s.runtime.wait(0.6)
			watch:disconnect()
			s.runtime.wait(2)
			check(calls == 1 and f.count() == 3)
			c:destroy()
		end)
	end)
end
