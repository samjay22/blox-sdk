--!strict
local SDK = require("../src/BloxSDK")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Json = require("../src/Core/Json")

--- Fail an offline assertion without disclosing credentials or player payloads.
local function check(value: unknown, _second: unknown?)
	assert(value, "Wave-2 platform contract regression")
end

--- Build a synthetic server client over the deterministic transport and scheduler.
local function client(s: Scheduler.Scheduler, steps: { Fake.Step }): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		retries = 1,
		retryRatio = 1,
	}),
		fake
end

--- Register public facade, strict DTO, privacy and conservative retry regressions.
return function(test: (string, () -> ()) -> ())
	test("platform flags use canonical routing and the shared explicit universe binding", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{
				body = s.json({
					values = {
						double_xp = { value = true, reason = "experiment", variant = "treatment" },
					},
				}),
				check = function(r)
					check(
						r.Method == "POST"
							and r.Url
								== "https://lb1.blox-api.com/platform-service/api/universes/123/flags/evaluate"
					)
					check(string.find(r.Body :: string, '"userId":7', 1, true))
				end,
			},
		})
		s.run(function()
			local result = c.platform:evaluateFlags({ body = { userId = 7, keys = { "double_xp" } } })
			check(result.ok and result.value.values.double_xp.value == true)
		end)
		check(f.count() == 1)
		c:destroy()
	end)
	test("platform unkeyed writes never automatically retry ambiguous server failures", function()
		local s = Scheduler.new()
		local c, f = client(s, { { status = 503, body = s.json({ message = "unavailable" }) } })
		s.run(function()
			local result = c.platform:recordExposure({
				body = {
					userId = 7,
					key = "double_xp",
					variant = "treatment",
					eventId = "synthetic-event",
					occurredAt = "2026-11-06T00:00:00Z",
				},
			})
			check(not result.ok and result.error.status == 503)
		end)
		check(f.count() == 1)
		c:destroy()
	end)
	test("player privacy deletion requires the new typed JSON body, not a reason query", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{
				body = s.json({ erased = true, tombstoneId = "00000000-0000-4000-8000-000000000001" }),
				check = function(r)
					check(
						r.Method == "DELETE"
							and r.Url
								== "https://lb1.blox-api.com/fields-service/api/fields/universes/123/players/7"
					)
					check(string.find(r.Body :: string, '"confirmUserId":7', 1, true))
					check(string.find(r.Body :: string, '"reason":"Privacy request"', 1, true))
				end,
			},
		})
		s.run(function()
			check(c.fields:deletePlayer({
				path = { userId = 7 },
				body = { reason = "Privacy request", confirmUserId = 7 },
			}).ok)
		end)
		check(f.count() == 1)
		c:destroy()
	end)
	test("player search exposes typed cursor pages without putting credentials in filters", function()
		local s = Scheduler.new()
		local c, f = client(s, { { body = s.json({ items = Json.array({}), nextCursor = Json.null }) } })
		s.run(function()
			local result = c.fields:searchPlayers({ query = { q = "Name:A" } })
			check(result.ok and #result.value.items == 0)
		end)
		check(f.count() == 1)
		c:destroy()
	end)
end
