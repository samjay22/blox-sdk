--!strict
local SDK = require("../src/BloxSDK")
local Fake = require("../src/Testing/FakeBackend")
local Scheduler = require("./Scheduler")
local Json = require("../src/Core/Json")

--- Fail a contract assertion without disclosing synthetic wire bodies.
local function check(value: unknown, _second: unknown?)
	assert(value, "F4 contract regression")
end

--- Exercise the public F4 facades through the real pipeline, without network IO.
return function(test: (string, () -> ()) -> ())
	test("criteria dry-run routes, numeric maps, dotted ids and direct body", function()
		local s = Scheduler.new()
		local fake = Fake.new(s.runtime, {
			{
				body = s.json({
					universeId = 123,
					sampled = 1,
					players = { { userId = 7, values = { ["Stats.Rating"] = 2.5 } } },
				}),
				check = function(r)
					check(r.Method == "GET")
					check(
						r.Url
							== "https://lb1.blox-api.com/fields-service/api/fields/universes/123/players/sample?fields=Stats.Rating%2CElo&limit=200"
					)
				end,
			},
			{
				body = s.json({
					sampled = 1,
					fieldCoverage = {
						["Stats.Rating"] = {
							present = 1,
							missing = 0,
							min = 2.5,
							max = 2.5,
							mean = 2.5,
							p50 = 2.5,
							p90 = 2.5,
						},
					},
					estimate = { groups = 0, avgGroupSize = 0, unmatchable = 1, unmatchablePct = 100 },
					warnings = Json.array({}),
				}),
				check = function(r)
					check(r.Method == "POST")
					check(
						r.Url
							== "https://lb1.blox-api.com/matchmaking-service/api/matchmaking/criteria/simulate"
					)
					check(string.find(r.Body :: string, '"universeId":"123"', 1, true))
					check(string.find(r.Body :: string, '"sampleSize":200', 1, true))
					check(string.find(r.Body :: string, '"fieldName":"Stats.Rating"', 1, true))
					check(not string.find(r.Body :: string, '"body":', 1, true))
				end,
			},
		})
		local c = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			profileSync = { enabled = false },
			key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
			universeId = 123,
		})
		s.run(function()
			local sample = c.fields:samplePlayers({ query = { fields = "Stats.Rating,Elo", limit = 200 } })
			check(sample.ok and sample.value.players[1].values["Stats.Rating"] == 2.5)
			local result = c.matchmaking:simulateCriteria({
				universeId = "123",
				sampleSize = 200,
				criteria = { { type = "SKILL_BASED", fieldName = "Stats.Rating", skillRange = 100 } },
			})
			check(result.ok and result.value.fieldCoverage["Stats.Rating"].present == 1)
		end)
		check(fake.count() == 2)
		c:destroy()
	end)

	test("criteria sample rejects malformed numeric maps and accepts omitted values", function()
		local s = Scheduler.new()
		local fake = Fake.new(s.runtime, {
			{ body = s.json({ universeId = 123, sampled = 1, players = { { userId = 7, values = {} } } }) },
			{
				body = s.json({
					universeId = 123,
					sampled = 1,
					players = { { userId = 7, values = { Rating = "bad" } } },
				}),
			},
		})
		local c = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			profileSync = { enabled = false },
			key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
			universeId = 123,
		})
		s.run(function()
			check(c.fields:samplePlayers().ok)
			local bad = c.fields:samplePlayers()
			check(not bad.ok and bad.error.kind == "Network")
		end)
		check(fake.count() == 2)
		c:destroy()
	end)

	test("simulation decodes empty coverage and does not retry the POST", function()
		local s = Scheduler.new()
		local fake = Fake.new(s.runtime, {
			{
				body = s.json({
					sampled = 0,
					fieldCoverage = {
						Rating = {
							present = 0,
							missing = 0,
							min = Json.null,
							max = Json.null,
							mean = Json.null,
							p50 = Json.null,
							p90 = Json.null,
						},
					},
					estimate = { groups = 0, avgGroupSize = 0, unmatchable = 0, unmatchablePct = 0 },
					warnings = { "No players available" },
				}),
			},
			{ status = 503 },
		})
		local c = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			profileSync = { enabled = false },
			key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
			universeId = 123,
			retries = 3,
			retryRatio = 1,
		})
		s.run(function()
			local request = {
				universeId = "123",
				sampleSize = 200,
				criteria = {
					{ type = "RANGE" :: "RANGE", fieldName = "Rating", minValue = 0, maxValue = 100 },
				},
			}
			local empty = c.matchmaking:simulateCriteria(request)
			check(empty.ok and empty.value.fieldCoverage.Rating.mean == Json.null)
			local unavailable = c.matchmaking:simulateCriteria(request)
			check(not unavailable.ok and unavailable.error.kind == "Server")
		end)
		check(fake.count() == 2)
		c:destroy()
	end)
end
