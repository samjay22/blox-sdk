--!strict
local Endpoints = require("../src/Core/Endpoints")
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Json = require("../src/Core/Json")
local Validation = require("../src/Core/Validation")
local Idempotency = require("../src/Core/Idempotency")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Vectors = require("./FixtureVectors")

--- Fail deterministically without logging credentials or response payloads.
local function check(value: unknown, message: string?)
	assert(value, message or "Source contract regression")
end

--- Supply only a synthetic key, never a real credential, to the transport harness.
local function key(): string
	return "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
end

--- Construct an isolated machine client with an earned retry available on its first call.
local function client(s: Scheduler.Scheduler, steps: { Fake.Step }): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		key = key(),
		universeId = 123,
		retryRatio = 1,
	}),
		fake
end

--- Exercise source-reviewed wire vectors independently of generated request/response fixtures.
return function(test: (string, () -> ()) -> ())
	for _, vector in Vectors["service-contracts"] do
		test("source wire golden: " .. vector.endpoint, function()
			local s = Scheduler.new()
			local fake = Fake.new(s.runtime, {
				{
					status = vector.status,
					body = if vector.empty then "" else Json.encode(vector.response),
					check = function(wire)
						check(wire.Method == vector.method and wire.Url == vector.url, "Wire route drift")
						local public = table.find(Endpoints[vector.endpoint].authKinds, "none") ~= nil
						check(
							wire.Headers.Authorization
								== (
									if public
										then nil
										elseif vector.identity then "Bearer synthetic-identity"
										else "Bearer " .. key()
								),
							"Auth header drift"
						)
						if vector.body == Json.null then
							check(wire.Body == nil, "Unexpected body")
						else
							check(wire.Body == Json.encode(vector.body), "Wire body drift")
							check(wire.Headers["Content-Type"] == "application/json", "Content type drift")
						end
					end,
				},
			})
			local config: SDK.Config = { runtime = s.runtime, backend = fake.backend, universeId = 123 }
			if vector.identity then
				config.authProvider = {
					kind = "custom",
					role = "SUPER_ADMIN",
					apply = function(headers: Core.Headers)
						headers.Authorization = "Bearer synthetic-identity"
					end,
					onUnauthorized = function(): boolean
						return false
					end,
				}
			else
				config.key = key()
			end
			local c = SDK.new(config)
			s.run(function()
				local service, method = string.match(vector.endpoint, "^([^.]+)%.(.+)$")
				local facade = (c :: any)[service]
				local result = facade[method](facade, vector.request)
				check(result.ok, "Wire vector failed: " .. vector.endpoint)
				check(result.status == vector.status, "HTTP status drift")
				if vector.empty then
					check(result.value == nil, "Void must decode as nil")
				else
					check(
						Json.encode(result.value) == Json.encode(vector.response),
						"Response shape/null drift"
					)
				end
			end)
			check(fake.count() == 1, "Unexpected retry or omitted request")
			c:destroy()
		end)
	end

	test("Retry-After is honored on 429 and every transient 5xx, without exceeding deadlines", function()
		for _, status in { 429, 500, 502, 503, 504 } do
			local s = Scheduler.new()
			local after = if status % 2 == 0 then "Tue, 14 Nov 2023 22:13:22 GMT" else "2"
			local c, f = client(s, {
				{ status = status, headers = { ["rEtRy-AfTeR"] = after } },
				{ body = '{"universeId":123,"schemaVersion":0,"definitions":[]}' },
			})
			s.run(function()
				check(c.fields:schema().ok)
			end)
			check(f.count() == 2 and s.time() >= 2 and s.time() < 2.2)
			c:destroy()
		end
		local s = Scheduler.new()
		local c, f = client(s, { { status = 429, headers = { ["Retry-After"] = "10" } } })
		s.run(function()
			local result = c.fields:schema(nil, { deadline = s.time() + 0.2 })
			check(not result.ok and result.error.kind == "Timeout")
		end)
		check(f.count() == 1 and s.time() < 0.3)
		c:destroy()
	end)

	test("removed compatibility options and invalid ETags fail before HTTP", function()
		local s = Scheduler.new()
		local c, f = client(s, {})
		s.run(function()
			check(not c.fields:runtimeSnapshot({ version = 1 } :: any).ok)
			check(not c.fields:schema(nil, { idempotencyHint = true } :: any).ok)
			check(not c.fields:runtimeSnapshot({ path = true } :: any).ok)
			check(not c.fields:runtimeSnapshot({ query = "universeId=123" } :: any).ok)
			for _, etag in { '"ok"\r\nX-Injected: yes', "bare-version", '""', string.rep("a", 257) } do
				local result = c.fields:runtimeSnapshot({ etag = etag })
				check(not result.ok and result.error.kind == "Validation")
			end
		end)
		check(f.count() == 0 and (c :: any).config == nil and (c :: any).configSnapshot == nil)
		c:destroy()
	end)

	test("idempotency header grammar follows Codes freeform keys without weakening Fields keys", function()
		check(Idempotency.header("launch:2026 / 1", true))
		check(not Idempotency.header("launch:2026 / 1", false))
		check(Idempotency.header(string.rep("😀", 100), true))
		check(not Idempotency.header(string.rep("😀", 101), true))
		for _, bad in { "", "   ", "\r\nInjected", utf8.char(128), utf8.char(0x2000), string.char(255) } do
			check(not Idempotency.header(bad, true))
		end
	end)

	test("all JSON services fail closed on unsafe integer tokens and preserve explicit nulls", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = '{"userId":9007199254740993,"rank":1,"score":1,"percentile":1,"total":1}' },
			{ body = '{"observed":null,"values":[]}' },
		})
		s.run(function()
			check(not c.leaderboards:user({ path = { name = "wins", userId = 7 } }, { retry = 0 }).ok)
			local result = c.platform:analyticsSummary({ query = { from = "2026-11-01", to = "2026-11-07" } })
			check(result.ok and result.value.observed == Json.null and Json.isArray(result.value.values))
		end)
		check(f.count() == 2)
		c:destroy()
	end)

	test("fractional plan prices validate, while malformed decimal strings fail locally", function()
		local plan: any = {
			name = "test",
			monthlyLimits = { requests = 100 },
			rateLimit = { requestsPerSecond = 10, burst = 10, dailyRequests = 100 },
			overagePrices = {},
		}
		for _, value in { 0.01, "0.00000001", "123456789012.12345678" } :: { number | string } do
			plan.overagePrices.requests = value
			check(Validation.body("platform.createPlan", plan))
		end
		for _, value in
			{ "NaN", "1..2", "1e999", "1\r\n", string.rep("9", 39), math.huge, 0 / 0 } :: { number | string }
		do
			plan.overagePrices.requests = value
			check(not Validation.body("platform.createPlan", plan))
		end
	end)

	test(
		"schedule recurrence builder encodes empty weekdays and rejects inconsistent weekly windows",
		function()
			local s = Scheduler.new()
			local c, f = client(s, {})
			local input: any = {
				name = "XP",
				start = "2026-11-07T00:00:00Z",
				["end"] = "2026-11-07T01:00:00Z",
				startActions = { { kind = "ENABLE_FLAG", key = "double_xp" } },
				reason = "Weekend XP",
				recurrence = { type = "DAILY", daysOfWeek = {}, timezone = "America/Chicago" },
			}
			local schedules = c.fields:scheduleClient(123)
			local built = schedules:build(input)
			check(built.ok and string.find(Json.encode(built.value), '"daysOfWeek":[]', 1, true))
			input.recurrence.type = "WEEKLY"
			check(not schedules:build(input).ok)
			input.recurrence.daysOfWeek = { "SATURDAY" }
			check(schedules:build(input).ok)
			input.recurrence.daysOfWeek = { "SATURDAY", "SATURDAY" }
			check(not schedules:build(input).ok)
			check(f.count() == 0)
			c:destroy()
		end
	)
end
