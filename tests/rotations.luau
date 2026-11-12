--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Json = require("../src/Core/Json")
local Copy = require("../src/Core/Idempotency")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local V = require("./FixtureVectors").rotations
-- The scheduler's clock starts at Unix 1700000000 = 2023-11-14T22:13:20Z.
local T0, T1, T2, T3 =
	"2023-11-14T22:13:20Z", "2023-11-14T22:23:20Z", "2023-11-14T22:33:20Z", "2023-11-14T22:43:20Z"
--- Fail a regression without logging request secrets or payloads.
local function check(value: unknown, message: string?)
	assert(value, message or "Rotations regression at " .. tostring(debug.info(2, "l")))
end
--- Unwrap a successful result (failing the test otherwise) without fighting the type narrowing.
local function ok(result: any): any
	assert(result.ok, "Expected a successful result")
	return result.value
end
--- Bind synthetic credentials and the existing deterministic mock transport.
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
		retries = 0,
	}),
		f
end
--- A `/current` body whose active period runs from `startsAt` to `endsAt`.
local function current(version: number, id: string, startsAt: string, endsAt: string, nextEnds: string): any
	local value = Copy.copy(V.current)
	value.version = version
	value.current =
		{ startsAt = startsAt, endsAt = endsAt, items = Json.array({ { id = id, data = { n = 1 } } }) }
	value.next = { startsAt = endsAt, endsAt = nextEnds, items = Json.array({ { id = "after_" .. id } }) }
	return value
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
				-- A call whose only path part is the universe takes its body directly.
				local argument = if vector.endpoint == "fields.previewRotation"
					then vector.request.body
					else vector.request
				local result = facade[method](facade, argument)
				check(
					result.ok and Json.encode(result.value) == Json.encode(vector.response),
					vector.endpoint
				)
			end)
			check(f.count() == 1)
			c:destroy()
		end)
	end
	test("current returns the active items, end time and next items in Unix seconds", function()
		local s = Scheduler.new()
		local c = client(s, { { body = s.json(current(3, "rain", T0, T1, T2)) } })
		s.run(function()
			local rotations = c.fields:rotations()
			local value: SDK.RotationCurrent = ok(rotations:current("weather"))
			check(value.key == "weather" and value.version == 3)
			check(#value.items == 1 and value.items[1].id == "rain" and value.items[1].data ~= nil)
			check((value.items[1].data :: any).n == 1)
			check(value.startsAt == 1700000000 and value.endsAt == 1700000600)
			check(value.next.startsAt == 1700000600 and value.next.endsAt == 1700001200)
			check(value.next.items[1].id == "after_rain" and value.next.items[1].data == nil)
			check(math.abs(rotations:secondsLeft(value) - 600) < 1)
			s.runtime.wait(125)
			check(math.abs(rotations:secondsLeft(value) - 475) < 1)
			s.runtime.wait(1000)
			check(rotations:secondsLeft(value) == 0)
			check(not pcall(function()
				(value :: any).items = {}
			end))
		end)
		c:destroy()
	end)
	test(
		"current is cached until the period ends, at most one minute, and is shared by every handle",
		function()
			local s = Scheduler.new()
			local c, f = client(s, {
				{ body = s.json(current(1, "a", T0, T3, T3)) },
				{ body = s.json(current(2, "b", T0, T3, T3)) },
				{ body = s.json(current(3, "c", T1, T2, T3)) },
			})
			s.run(function()
				check(c.fields:rotations():current("weather").ok)
				s.runtime.wait(30)
				check(ok(c.fields:rotations():current("weather")).version == 1 and f.count() == 1)
				s.runtime.wait(31)
				check(ok(c.fields:rotations():current("weather")).version == 2 and f.count() == 2)
				s.runtime.wait(30)
				check(ok(c.fields:rotations():current("weather")).version == 2 and f.count() == 2)
				-- Past the end of the cached period the cache is never used, even inside the minute.
				local s2 = Scheduler.new()
				local c2, f2 = client(s2, {
					{ body = s2.json(current(1, "a", T0, "2023-11-14T22:13:50Z", T1)) },
					{ body = s2.json(current(2, "b", "2023-11-14T22:13:50Z", T1, T2)) },
				})
				s2.run(function()
					check(ok(c2.fields:rotations():current("weather")).version == 1)
					s2.runtime.wait(31)
					check(ok(c2.fields:rotations():current("weather")).version == 2 and f2.count() == 2)
				end)
				c2:destroy()
			end)
			c:destroy()
		end
	)
	test("a failed refresh keeps serving a period that has not ended, but never an ended one", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json(current(1, "a", T0, T3, T3)) },
			{ status = 404, body = '{"code":"rotation_not_found"}' },
			{ status = 404, body = '{"code":"rotation_not_found"}' },
		})
		s.run(function()
			check(c.fields:rotations():current("weather").ok)
			s.runtime.wait(61)
			check(ok(c.fields:rotations():current("weather")).version == 1 and f.count() == 2)
			s.runtime.wait(2000)
			local ended = c.fields:rotations():current("weather")
			check(not ended.ok and ended.error.code == "rotation_not_found" and f.count() == 3)
		end)
		c:destroy()
	end)
	test("an unknown rotation is a plain not-found error with the server's code", function()
		local s = Scheduler.new()
		local c = client(
			s,
			{ { status = 404, body = '{"code":"rotation_not_found","message":"rotation_not_found"}' } }
		)
		s.run(function()
			local result = c.fields:rotations():current("missing")
			check(
				not result.ok
					and result.error.kind == "NotFound"
					and result.error.code == "rotation_not_found"
			)
		end)
		c:destroy()
	end)
	test("bad names, counts and closed clients fail before any request", function()
		local s = Scheduler.new()
		local c, f = client(s, {})
		local rotations = c.fields:rotations()
		s.run(function()
			for _, name in { "", "1abc", "has space", "a/b", string.rep("a", 101) } do
				local result = rotations:current(name)
				check(not result.ok and result.error.code == "invalid_request", name)
				check(not rotations:upcoming(name).ok)
				check(not pcall(rotations.watch, rotations, name, function() end))
			end
			for _, count in { 0, 51, 1.5, -1 } do
				check(not rotations:upcoming("weather", count).ok)
			end
			check(not pcall(rotations.watch, rotations, "weather", nil :: any))
			c:destroy()
			local closed = rotations:current("weather")
			check(not closed.ok and closed.error.kind == "Cancelled")
		end)
		check(f.count() == 0)
	end)
	test("upcoming converts every period and sends the count", function()
		local s = Scheduler.new()
		local c = client(s, {
			{
				body = s.json(V.schedule),
				check = function(request: Core.HttpRequest)
					check(string.find(request.Url, "/weather/schedule?count=3", 1, true) ~= nil)
				end,
			},
			{
				body = s.json(V.schedule),
				check = function(request: Core.HttpRequest)
					check(
						string.find(request.Url, "schedule", 1, true) ~= nil
							and string.find(request.Url, "count", 1, true) == nil
					)
				end,
			},
		})
		s.run(function()
			local periods: { SDK.RotationPeriod } = ok(c.fields:rotations():upcoming("weather", 3))
			check(#periods == 3)
			local first, second = periods[1], periods[2]
			check(
				first.items[1].id == "rain"
					and first.endsAt == second.startsAt
					and second.endsAt - second.startsAt == 3600
			)
			check(c.fields:rotations():upcoming("weather").ok)
		end)
		c:destroy()
	end)
	test("a response with unusable instants is a validation error, not a crash", function()
		local s = Scheduler.new()
		local bad = current(1, "a", "tomorrow", T1, T2)
		local c = client(s, { { body = s.json(bad) } })
		s.run(function()
			local result = c.fields:rotations():current("weather")
			check(not result.ok and result.error.kind == "Validation")
		end)
		c:destroy()
	end)
	test("watch fires now, again at each period edge, and again when the list is edited", function()
		local s = Scheduler.new()
		local edge = "2023-11-14T22:13:50Z"
		local c, f = client(s, {
			{ body = s.json(current(1, "a", T0, edge, T1)) },
			{ body = s.json(current(1, "b", edge, T1, T2)) },
			{ body = s.json(current(1, "b", edge, T1, T2)) },
			{ body = s.json(current(2, "c", edge, T1, T2)) },
		})
		local seen: { string } = {}
		local watch = c.fields:rotations():watch("weather", function(value)
			table.insert(seen, value.items[1].id)
		end)
		s.run(function()
			s.runtime.wait(1)
			check(#seen == 1 and seen[1] == "a" and f.count() == 1)
			s.runtime.wait(32)
			check(#seen == 2 and seen[2] == "b" and f.count() == 2, "period edge")
			s.runtime.wait(61)
			check(#seen == 2 and f.count() == 3, "unchanged answers are not repeated")
			s.runtime.wait(61)
			check(#seen == 3 and seen[3] == "c" and f.count() == 4, "edited list")
			watch:disconnect()
			local before = f.count()
			s.runtime.wait(500)
			check(f.count() == before and #seen == 3, "disconnect stops everything")
			c:destroy()
		end)
		check(s.pending() == 0)
	end)
	test("watch survives errors, records lastError and recovers", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ status = 404, body = '{"code":"rotation_not_found"}' },
			{ body = s.json(current(1, "a", T0, T1, T2)) },
		})
		local seen = 0
		local watch = c.fields:rotations():watch("weather", function()
			seen += 1
		end)
		s.run(function()
			s.runtime.wait(1)
			check(seen == 0 and watch.lastError ~= nil and watch.lastError.code == "rotation_not_found")
			s.runtime.wait(25)
			check(seen == 1 and watch.lastError == nil and f.count() == 2)
			watch:disconnect()
			c:destroy()
		end)
		check(s.pending() == 0)
	end)
	test("a throwing callback does not break the watch", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json(current(1, "a", T0, "2023-11-14T22:13:50Z", T1)) },
			{ body = s.json(current(1, "b", "2023-11-14T22:13:50Z", T1, T2)) },
		})
		local calls = 0
		local watch = c.fields:rotations():watch("weather", function()
			calls += 1
			error("boom")
		end)
		s.run(function()
			s.runtime.wait(35)
			check(calls == 2 and f.count() == 2)
			watch:disconnect()
			c:destroy()
		end)
	end)
	test("destroying the client stops watches", function()
		local s = Scheduler.new()
		local c, f = client(s, { { body = s.json(current(1, "a", T0, T1, T2)) } })
		local watch = c.fields:rotations():watch("weather", function() end)
		s.run(function()
			s.runtime.wait(1)
			c:destroy()
			local before = f.count()
			s.runtime.wait(1000)
			check(f.count() == before)
			watch:disconnect()
		end)
		check(s.pending() == 0)
	end)
end
