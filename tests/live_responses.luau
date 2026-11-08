--!strict
local SDK = require("../src/BloxSDK")
local Matchmaking = require("../src/Types/Matchmaking")
local Core = require("../src/Types/Core")
local Json = require("../src/Core/Json")
local Validation = require("../src/Core/Validation")
local Schemas = require("../src/Core/Schemas")
local Vectors = require("./FixtureVectors")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")

--- Assert contracts without logging wire payloads.
local function check(value: unknown)
	assert(value, "Live response regression")
end

--- Register captured gateway bodies and independent nullable/type negative controls.
return function(test: (string, () -> ()) -> ())
	test("every health facade accepts every exact live health body through Transport", function()
		for _, service in
			{ "auth", "matchmaking", "party", "codes", "audit", "leaderboards", "fields", "platform" }
		do
			check(Schemas.definitions[service].HealthResponse == Schemas.definitions.auth.HealthResponse)
			for name, body in Vectors.liveResponseBodies do
				if name == "mm-queue-status" then
					continue
				end
				local s = Scheduler.new()
				local fake = Fake.new(s.runtime, { { status = 200, body = body } })
				local client = SDK.new({
					runtime = s.runtime,
					backend = fake.backend,
					key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
					universeId = 123,
				})
				s.run(function()
					local result: Core.Result<any> = (client :: any)[service]:healthProxy()
					check(result.ok and result.status == 200 and result.value.status == "UP")
				end)
				check(fake.count() == 1)
				client:destroy()
			end
			for _, status in { "UP", "DOWN", "OUT_OF_SERVICE", "UNKNOWN" } do
				check(
					Validation.response(
						service .. ".healthProxy",
						{ status = status, components = false, future = Json.null }
					)
				)
			end
			check(not Validation.response(service .. ".healthProxy", {}))
			check(not Validation.response(service .. ".healthProxy", { status = 1 }))
			check(not Validation.response(service .. ".healthProxy", { status = Json.null }))
		end
	end)

	test("exact queue status golden preserves nulls and string ids through Transport", function()
		local s = Scheduler.new()
		local fake =
			Fake.new(s.runtime, { { status = 200, body = Vectors.liveResponseBodies["mm-queue-status"] } })
		local client = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
			universeId = 999999800,
		})
		s.run(function()
			local result = client.matchmaking:getPlayerQueueStatus({ query = { userId = "999999800005" } })
			check(result.ok)
			if result.ok then
				check(result.value.userId == "999999800005" and result.value.universeId == "999999800")
				check(not result.value.inQueue and result.value.queuedAt == Json.null)
				check(
					result.value.gameModeName == Json.null
						and result.value.gameModeNames == Json.null
						and result.value.partyId == Json.null
				)
			end
		end)
		check(fake.count() == 1)
		client:destroy()
		local empty = Vectors.liveResponses["mm-queue-status"]
		check(
			Validation.response(
				"matchmaking.getBulkQueueStatus",
				{ results = { [empty.userId] = empty }, future = 1 }
			)
		)
		local queued: any = table.clone(empty)
		queued.inQueue, queued.gameModeName, queued.gameModeNames, queued.queuedAt =
			true, "ranked", { "ranked", "duo" }, 1700000000000
		queued.future = { ignored = true }
		check(Validation.response("matchmaking.getPlayerQueueStatus", queued))
		queued.queuedAt = "1700000000000"
		check(not Validation.response("matchmaking.getPlayerQueueStatus", queued))
		for _, field in { "userId", "universeId" } do
			local invalid = table.clone(empty)
			invalid[field] = 123
			check(not Validation.response("matchmaking.getPlayerQueueStatus", invalid))
			invalid[field] = nil
			check(not Validation.response("matchmaking.getPlayerQueueStatus", invalid))
		end
	end)

	test("all queue DTO nullable branches remain typed and writes remain strict", function()
		check(
			Validation.response(
				"matchmaking.flushQueue",
				{ success = true, removedCount = 0, universeId = "123", gameModeName = Json.null }
			)
		)
		for _, endpoint in { "getWaitEstimate", "getWaitEstimateAlias" } do
			check(Validation.response("matchmaking." .. endpoint, {
				universeId = "123",
				gameModeName = "ranked",
				queuedPlayerCount = 0,
				maxMatchSize = 10,
				playersNeeded = 10,
				oldestEntryAgeSeconds = Json.null,
				estimatedWaitSeconds = Json.null,
			}))
		end
		check(Validation.response("matchmaking.getQueueMetrics", {
			totalPlayersInQueue = 2,
			timestamp = 1,
			universeBreakdown = {
				["123"] = {
					universeId = "123",
					totalPlayers = 2,
					gameModes = {
						ranked = {
							gameModeName = "ranked",
							playerCount = 2,
							players = {
								{
									robloxUserId = Json.null,
									robloxUserIds = { "1", "2" },
									gameModeName = "ranked",
									partyId = "party",
								} :: Matchmaking.PlayerInQueueInfo,
								{
									robloxUserId = "3",
									robloxUserIds = { "3" },
									gameModeName = "ranked",
									partyId = Json.null,
								} :: Matchmaking.PlayerInQueueInfo,
							},
						},
					},
				},
			},
		}))
		check(Validation.response("matchmaking.validateQueue", {
			valid = false,
			errors = {
				{
					fieldName = Json.null,
					criteriaType = Json.null,
					actualValue = Json.null,
					expectedConstraint = Json.null,
					reason = Json.null,
					future = "ignored",
				},
			},
		}))
		check(
			not Validation.body(
				"matchmaking.joinQueue",
				{ robloxUniverseId = "123", gameModeName = Json.null }
			)
		)
		check(
			not Validation.body(
				"matchmaking.joinQueue",
				{ robloxUniverseId = "123", gameModeName = "ranked", typo = true }
			)
		)
		-- RatingConfig is shared on reads/writes: response tolerates its nullable scope,
		-- but does not grant nullable/unknown fields to configuration writes.
		check(
			Validation.response(
				"leaderboards.ratingConfig",
				{ kFactor = 1, initialRating = 1, floor = 0, universeId = Json.null, future = true }
			)
		)
		check(
			not Validation.body(
				"leaderboards.ratingConfigure",
				{ kFactor = 1, initialRating = 1, floor = 0, universeId = Json.null }
			)
		)
	end)
end
