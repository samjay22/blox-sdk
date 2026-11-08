--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Fields = require("../src/Types/Fields")
local Bindings = require("../src/Fields/Bindings")
local Validation = require("../src/Core/Validation")
local Copy = require("../src/Core/Idempotency")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
local System = require("../src/Fields/TypeSystem")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Vectors = require("./FixtureVectors")
--- Fail without exposing payloads or credentials, while identifying the binding regression suite.
local function check(value: unknown, message: string?)
	assert(value, message or "Fields binding regression")
end
--- Construct only a fake transport; no board or definition is provisioned during tests.
local function client(s: Scheduler.Scheduler, steps: { Fake.Step }): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		retryRatio = 1,
		retries = 3,
	}),
		fake
end
--- Provide independently specified wire settings, not a fixture derived from generated schemas.
local function settings(): Fields.BoardSettings
	return {
		name = "wins",
		displayName = "Total Wins",
		sortOrder = "DESC",
		aggregation = "BEST",
		resetSchedule = "WEEKLY",
		minScore = 0,
		maxScore = 100,
	}
end
--- Register binding grammar, routing, wire-shape and failure-boundary regressions.
return function(test: (string, () -> ()) -> ())
	test("Fields bindings: 103 shared Java/Luau grammar and context vectors", function()
		local count = 0
		for _, v in Vectors.bindings do
			local result = Bindings.validate(v.bindings, v.scope, v.type, v.computed == true)
			if v.code then
				check(not result.ok and result.error.code == v.code, v.name)
			else
				check(result.ok and result.value == v.expected, v.name)
			end
			count += 1
		end
		check(count == 103)
		check(not Bindings.grammar({ leaderboards = { [2] = { board = "wins", submit = "VALUE" } } }))
		check(not Bindings.grammar({ leaderboards = { extra = true } }))
		check(not Bindings.board({ board = "wins", submit = "VALUE", displayName = "\255" }))
	end)
	test("Fields preview and bound definition invalid candidates make zero HTTP calls", function()
		local s = Scheduler.new()
		local c, f = client(s, {})
		local base: any = {
			id = "Stats.TotalWins",
			type = { kind = "int" },
			binding = { board = "wins", submit = "VALUE" },
		}
		s.run(function()
			for _, change in
				{
					{ binding = { board = "wins", submit = "DELTA", keep = "LAST" } },
					{ binding = { board = "wins", submit = "VALUE", order = Json.null } },
					{ binding = { board = "wins", submit = "VALUE", aggregation = "BEST" } },
					{ type = { kind = "number" } },
					{ type = { kind = "int", min = 1.5 } },
					{ type = { kind = "int", max = 9007199254740992 } },
					{ scope = "UNIVERSE" },
					{ type = Json.null },
					{ binding = Json.null },
				} :: { any }
			do
				local body = Copy.copy(base)
				for k, v in change do
					body[k] = v
				end
				local preview = c.fields:previewBoard({ body = body })
				check(not preview.ok and preview.error.kind == "Validation")
				body.bindings = { leaderboards = { body.binding } }
				body.binding = nil
				body.reason = "Provision wins"
				local create = c.fields:create({ body = body })
				check(not create.ok and create.error.kind == "Validation")
				body.expectedDefinitionVersion = 1
				local update = c.fields:update({ path = { id = "Stats.TotalWins" }, body = body })
				check(not update.ok and update.error.kind == "Validation")
			end
			local computed: any = {
				id = "Derived",
				computed = { expression = "1", returns = "int" },
				reason = "Invalid computed binding",
				bindings = { leaderboards = { base.binding } },
			}
			check(not c.fields:create({ body = computed }).ok)
		end)
		check(f.count() == 0)
		c:destroy()
	end)
	test(
		"Fields preview sends one read-only POST and exposes typed conflicts and effective ranges",
		function()
			for _, status in { "COMPATIBLE", "CONFLICT", "ARCHIVED", "MISSING_OR_ARCHIVED" } do
				local s = Scheduler.new()
				local effective = settings()
				effective.maxScore = 1000
				local conflicts: any = Json.array({})
				local valid = status == "COMPATIBLE" or status == "MISSING_OR_ARCHIVED"
				if not valid then
					conflicts = {
						{
							code = if status == "ARCHIVED"
								then "leaderboard_board_archived"
								else "leaderboard_board_mismatch",
							board = "wins",
							expected = settings(),
							actual = { aggregation = "SUM", maxDeltaPerSubmit = Json.null },
							field = "Other.Wins",
							source = "field_binding",
						},
					}
				end
				local c, f = client(s, {
					{
						body = s.json({
							settings = settings(),
							effectiveSettings = effective,
							status = status,
							valid = valid,
							conflicts = conflicts,
							willWiden = if status == "COMPATIBLE"
								then { minScore = -5, maxScore = 1000 }
								else nil,
						}),
						check = function(request: Core.HttpRequest)
							check(request.Method == "POST")
							check(
								request.Url
									== "https://lb1.blox-api.com/fields-service/api/fields/universes/123/definitions/preview-board"
							)
							local body: any = Decode.decode(request.Body :: string)
							check(
								body.binding.keep == "BEST"
									and body.binding.reset == "WEEKLY"
									and body.binding.order == "DESC"
							)
							check(body.reason == nil and body.idempotencyKey == nil)
						end,
					},
				})
				s.run(function()
					local result = c:withUniverse(123).fields:previewBoard({
						body = {
							id = "Stats.TotalWins",
							type = { kind = "int", min = 0, max = 100 },
							binding = {
								board = "wins",
								submit = "VALUE",
								keep = "BEST",
								reset = "WEEKLY",
								order = "DESC",
							},
						},
					})
					assert(result.ok, "Preview request failed")
					check(result.value.status == status and result.value.valid == valid)
					check((result.value.effectiveSettings :: Fields.BoardSettings).maxScore == 1000)
					if status == "COMPATIBLE" then
						check(
							result.value.willWiden
								and (result.value.willWiden :: Fields.ScoreRange).minScore == -5
						)
					else
						check(result.value.willWiden == nil)
					end
				end)
				check(f.count() == 1)
				c:destroy()
			end
		end
	)
	test("Fields binding removal preserves empty array and listing preserves archived metadata", function()
		local s = Scheduler.new()
		local definition: any = {
			universeId = 123,
			id = "Stats.TotalWins",
			scope = "PLAYER",
			type = { kind = "int" },
			status = "ACTIVE",
			definitionVersion = 2,
			description = "",
			createdAt = "now",
			updatedAt = "now",
			bindings = { leaderboards = Json.array({}) },
		}
		local c, f = client(s, {
			{
				body = s.json(definition),
				check = function(request: Core.HttpRequest)
					check(string.find(request.Body :: string, '"leaderboards":[]', 1, true) ~= nil)
				end,
			},
			{
				body = s.json({
					{
						field = "Stats.TotalWins",
						status = "ARCHIVED",
						binding = { board = "wins", submit = "VALUE", keep = "BEST" },
						settings = settings(),
					},
				}),
				check = function(request: Core.HttpRequest)
					check(request.Method == "GET" and request.Body == nil)
					check(
						request.Url
							== "https://lb1.blox-api.com/fields-service/api/fields/universes/123/leaderboard-bindings"
					)
				end,
			},
		})
		s.run(function()
			check(c.fields:update({
				path = { id = "Stats.TotalWins" },
				body = {
					type = { kind = "int" },
					reason = "Remove wins binding",
					expectedDefinitionVersion = 1,
					bindings = { leaderboards = {} },
				},
			}).ok)
			local result = c.fields:leaderboardBindings()
			check(
				result.ok
					and result.value[1].status == "ARCHIVED"
					and (result.value[1].settings :: Fields.BoardSettings).aggregation == "BEST"
			)
		end)
		check(f.count() == 2)
		c:destroy()
	end)
	test(
		"Fields provisioning errors preserve new codes but redact all server details and never retry writes",
		function()
			for _, machine in
				{
					"leaderboard_requires_int",
					"leaderboard_score_range",
					"leaderboard_board_mismatch",
					"leaderboard_board_archived",
					"leaderboard_unavailable",
				}
			do
				for _, method in { "previewBoard", "create", "update" } do
					local s = Scheduler.new()
					local status = if machine == "leaderboard_unavailable" then 503 else 422
					local c, f = client(s, {
						{
							status = status,
							body = s.json({
								code = machine,
								message = "private-server-text",
								actual = { credential = "private" },
								board = "private-board",
							}),
						},
					})
					s.run(function()
						local body: any = { id = "Stats.TotalWins", type = { kind = "int" } }
						local binding = { board = "wins", submit = "VALUE" }
						if method == "previewBoard" then
							body.binding = binding
						else
							body.reason = "Provision wins"
							body.bindings = { leaderboards = { binding } }
							if method == "update" then
								body.expectedDefinitionVersion = 1
							end
						end
						local fields: any = c.fields
						local result = fields[method](
							fields,
							{ path = if method == "update" then { id = body.id } else nil, body = body },
							{ retry = 3 }
						)
						check(
							not result.ok and result.error.code == machine and result.error.status == status
						)
						check(result.error.body == "[redacted]" and result.error.attempts == 1)
						check(not string.find(Json.encode(result.error), "private", 1, true))
					end)
					check(f.count() == 1)
					c:destroy()
				end
			end
		end
	)
	test(
		"Fields preview tolerates omitted references but rejects malformed settings and binding DTOs",
		function()
			local valid: any = {
				settings = settings(),
				effectiveSettings = settings(),
				status = "COMPATIBLE",
				valid = true,
				conflicts = Json.array({}),
			}
			check(Validation.response("fields.previewBoard", valid))
			for key in valid do
				local bad = Copy.copy(valid)
				bad[key] = nil
				check(Validation.response("fields.previewBoard", bad) == (key ~= "valid"), key)
			end
			for key in valid.settings do
				local bad = Copy.copy(valid)
				bad.settings[key] = nil
				check(
					Validation.response("fields.previewBoard", bad)
						== (key ~= "minScore" and key ~= "maxScore"),
					key
				)
			end
			for _, change in
				{
					{ aggregation = "MAX" },
					{ sortOrder = "desc" },
					{ resetSchedule = "YEARLY" },
					{ minScore = "0" },
				} :: { any }
			do
				local bad = Copy.copy(valid)
				for key, value in change do
					bad.settings[key] = value
				end
				check(not Validation.response("fields.previewBoard", bad))
			end
			check(not Validation.response("fields.leaderboardBindings", {
				{
					field = "Wins",
					status = "ACTIVE",
					settings = settings(),
					binding = { board = "wins", submit = "DELTA", keep = "BEST" },
				},
			}))
			check(System.equal(valid.settings, settings()))
		end
	)
end
