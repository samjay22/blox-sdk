--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local FieldTypes = require("../src/Fields/Types")
local Codes = require("../src/Types/Codes")
local Schema = require("../src/Fields/Schema")
local Operations = require("../src/Fields/Operations")
local System = require("../src/Fields/TypeSystem")
local Json = require("../src/Core/Json")
local JsonDecode = require("../src/Core/JsonDecode")
local Validation = require("../src/Core/Validation")
local Copy = require("../src/Core/Idempotency")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Vectors = require("./FixtureVectors")
--- Assert behavior without including request data in failures.
local function check(value: unknown, message: string?)
	assert(value, message or ("Operation regression at " .. tostring(debug.info(2, "l"))))
end
--- Complete the shared schema fixture exactly as a Fields response.
local function schema(): Wire.SchemaResponse
	local value = Copy.copy(Vectors.schema)
	for _, d in value.definitions do
		d.description = ""
		d.universeId = 123
		d.definitionVersion = 1
		d.createdAt = "now"
		d.updatedAt = "now"
		if not d.computed then
			d.history = "LEDGER"
			d.writeLevel = "ADMIN"
		end
	end
	return value
end
--- Build a scoped client with an injected offline transport.
local function client(s: Scheduler.Scheduler, steps: { Fake.Step }): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		profileSync = { enabled = false },
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
	}),
		fake
end
--- Require a local or remote safe machine code.
local function code(result: Core.Result<any>, expected: string)
	check(not result.ok and result.error.code == expected, "Expected " .. expected)
end
--- Construct the exact nullable Fields receipt returned by CodeService.
local function receipt(): Codes.FieldsTransactionResult
	local item: Codes.Result = {
		subject = 7,
		field = "Currency.Gems",
		path = Json.array({}),
		op = "ADD",
		before = Json.null,
		after = 10,
		version = 1,
		entryId = Json.null,
	}
	return {
		txId = "tx-1",
		replayed = false,
		seq = { ["7"] = 1 },
		results = { item },
	}
end
--- Register dry-run, award, response and source-independent regression fixtures.
return function(test: (string, () -> ()) -> ())
	test(
		"consumer wire schemas reject malformed operation unions and inconsistent dry-run reports",
		function()
			check(
				Validation.body(
					"codes.createCode",
					{ code = "WELCOME", award = { { field = "Currency.Gems", op = "ADD", delta = 1 } } }
				)
			)
			local malformed: { unknown } = {
				{ field = "Currency.Gems", op = "ADD", delta = "1" },
				{ field = "Currency.Gems", op = "RESET", subject = Json.null },
				{ field = "Currency.Gems", op = "RESET", value = 1 },
				{ field = "Tags", op = "SET_ADD", items = Json.object({}) },
				{ field = "Characters", op = "REMOVE_AT", index = 0, count = 0 },
				{ field = "Currency.Gems", op = "SET" },
			}
			for _, bad in malformed do
				check(not Validation.body("codes.createCode", { code = "WELCOME", award = { bad } }))
			end
			check(not Validation.body("codes.createCode", {
				code = "WELCOME",
				award = { { field = "Currency.Gems", op = "RESET" } },
				maxRedemptionsPerUser = 2,
			}))
			check(not Validation.response("fields.validateOps", { valid = false, errors = Json.array({}) }))
			check(not Validation.response("fields.validateOps", {
				valid = false,
				errors = { { opIndex = 0.5, field = "X", path = {}, code = "unknown_field" } },
			}))
			check(not Validation.response("fields.validateOps", {
				valid = true,
				errors = { { opIndex = 0, field = "X", path = {}, code = "unknown_field" } },
			}))
		end
	)
	test("subject-free validation vectors collect all diagnostics and enforce whole-request shape", function()
		local s = Scheduler.new()
		local cache = Schema.new(s.runtime, function()
			return { ok = true, value = schema() }
		end)
		check(cache:load().ok)
		for _, vector in Vectors["ops-validation"] do
			local result = Operations.validate(cache, vector.ops)
			if vector.code then
				code(result, vector.code)
			else
				check(result.ok and System.equal(result.value.errors, vector.errors), vector.name)
				check(result.ok and result.value.valid == (#vector.errors == 0), vector.name)
			end
		end
		local cycle: any = { field = "Currency.Gems", op = "SET" }
		cycle.value = cycle
		code(Operations.validate(cache, { cycle }), "invalid_request")
		cache:destroy()
	end)
	test(
		"Fields validateOps preflight sends no invalid ops and preserves authoritative diagnostics",
		function()
			local s = Scheduler.new()
			local errors = {
				{ opIndex = 0, field = "Currency.Gems", path = Json.array({}), code = "max_delta_exceeded" },
				{
					opIndex = 1,
					field = "Inventory.Items",
					path = Json.array({ "SWORD" }),
					code = "above_max",
				},
			}
			local c, f = client(s, {
				{ body = s.json(schema()) },
				{
					body = s.json({ valid = false, errors = errors }),
					check = function(request)
						check(
							request.Method == "POST"
								and request.Url
									== "https://lb1.blox-api.com/fields-service/api/fields/universes/123/ops/validate"
						)
						check(System.equal(JsonDecode.decode(request.Body :: string), {
							ops = {
								{ field = "Currency.Gems", op = "ADD", delta = -1 },
								{ field = "Inventory.Items", op = "MAP_ADD", key = "SWORD", delta = 1 },
							},
						}))
					end,
				},
			})
			s.run(function()
				code(
					c.fields:validateOps({ ops = { { field = "Currency.Gems", op = "RESET" } } }),
					"schema_unavailable"
				)
				check(f.count() == 0)
				check(c.fields:schemaCache():load().ok)
				local invalid = c.fields:validateOps({
					ops = { { field = "Missing", op = "RESET" }, { field = "Old", op = "RESET" } },
				})
				check(
					invalid.ok
						and not invalid.value.valid
						and #(invalid.value.errors :: { Wire.OpValidationError }) == 2
						and f.count() == 1
				)
				local valid = c.fields
					:operations()
					:add("Currency.Gems", -1)
					:mapAdd("Inventory.Items", "SWORD", 1)
					:validate()
				check(
					valid.ok and not valid.value.valid and System.equal(valid.value.errors, errors),
					if valid.ok
						then Json.encode(valid.value.errors)
						else (valid.error.code or valid.error.message)
				)
				code(
					c.fields:validateOps({
						universeId = 124,
						ops = {
							{ field = "Currency.Gems", op = "RESET" },
						},
					}),
					"invalid_request"
				)
				check(f.count() == 2)
				c:destroy()
			end)
		end
	)
	test("Transaction validate is a nonsealing player-op dry run independent of reason and key", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json(schema()) },
			{ body = s.json({ valid = true, errors = Json.array({}) }) },
			{ body = s.json(receipt()) },
		})
		s.run(function()
			check(c.fields:schemaCache():load().ok)
			local tx = c.fields:transactionBuilder(7):add("Currency.Gems", 1)
			local key = tx:idempotencyKey()
			check(tx:validate().ok and not tx._sealed and tx:idempotencyKey() == key)
			check(tx:add("Currency.Gems", 1):reason("Admin reward"):commit().ok)
			code(
				c.fields:multiTransactionBuilder():subject(7):add("Currency.Gems", 1):validate(),
				"invalid_request"
			)
			check(f.count() == 3)
			c:destroy()
		end)
	end)
	test(
		"Codes create resolves a builder or operation list, loading the schema and validating before send",
		function()
			local s = Scheduler.new()
			local award: { FieldTypes.PlayerOperation } =
				{ { field = "Currency.Gems", op = "ADD", delta = 10 } }
			local response: Codes.CodeDto = {
				id = 9,
				universeId = 123,
				code = "WELCOME",
				award = award,
				maxRedemptionsPerUser = 1,
				timesRedeemed = 0,
				pendingRedemptions = 0,
				active = true,
				redeemableNow = true,
				createdAt = "now",
				updatedAt = "now",
			}
			local c, f = client(s, {
				{ body = s.json(schema()) },
				{
					status = 201,
					body = s.json(response),
					check = function(request)
						check(request.Url == "https://lb1.blox-api.com/code-service/api/codes")
						local body: any = JsonDecode.decode(request.Body :: string)
						check(#body.award == 3 and body.award[1].delta == 10 and body.award[1].subject == nil)
						check(
							body.universeId == 123
								and body.code == "WELCOME"
								and body.maxRedemptionsPerUser == nil
						)
						check(string.find(request.Body :: string, '"items":[]', 1, true) ~= nil)
					end,
				},
				{ status = 201, body = s.json(response) },
				{ body = s.json(response) },
			})
			s.run(function()
				local builder = c.codes:award():add("Currency.Gems", 10):setAdd("Tags", {}):reset("Optional")
				check(c.codes:create({ code = "WELCOME", award = builder }).ok)
				check(f.count() == 2, "Schema loads implicitly, then one POST")
				check(c.codes:create({ code = "WELCOME2", award = award }).ok)
				check(c.codes:update(9, { description = "renamed" }).ok)
				check(f.count() == 4)
				code(
					c.codes:create({
						code = "BAD",
						award = { { field = "Missing", op = "RESET" :: "RESET" } },
					}),
					"unknown_field"
				)
				code(
					c.codes:update(9, { award = { { field = "Old", op = "RESET" :: "RESET" } } }),
					"field_archived"
				)
				code(
					c.codes:create({
						code = "BAD",
						award = { { field = "Currency.Gems", op = "RESET", subject = 7 } } :: any,
					}),
					"invalid_request"
				)
				code(
					c.codes:create({ code = "BAD", award = c.codes:award():add("Missing", 1) }),
					"unknown_field"
				)
				check(f.count() == 4, "Invalid awards never reach CodeService")
				c:destroy()
			end)
			code(
				c.codes:create({
					code = "CLOSED",
					award = { { field = "Currency.Gems", op = "RESET" :: "RESET" } },
				}),
				"client_closed"
			)
		end
	)
	test("Codes redeem returns one typed outcome and never a raw HTTP error", function()
		local s = Scheduler.new()
		local response = {
			redemptionId = 42,
			codeId = 9,
			code = "WELCOME",
			universeId = 123,
			robloxUserId = 7,
			transaction = receipt(),
			replayed = false,
			redeemedAt = "now",
		}
		local replay = table.clone(response)
		replay.replayed = true
		local function refusal(message: string): Fake.Step
			return { status = 409, body = s.json({ status = 409, error = "Conflict", message = message }) }
		end
		local c, f = client(s, {
			{
				body = s.json(response),
				check = function(request)
					check(
						System.equal(
							JsonDecode.decode(request.Body :: string),
							{ code = "WELCOME", universeId = 123, robloxUserId = 7 }
						)
					)
				end,
			},
			{ body = s.json(replay) },
			refusal("Code has expired"),
			refusal("Code is not active yet"),
			refusal("Code redemption limit reached (including pending grants)"),
			refusal("Code is not active"),
			refusal("Something else entirely"),
			{
				status = 404,
				body = s.json({ status = 404, error = "Not Found", message = "Code not found" }),
			},
			{
				status = 422,
				body = s.json({
					code = "invalid_award",
					message = "must not escape",
					grantPending = true,
					errors = {
						{ opIndex = 0, field = "Currency.Gems", path = Json.array({}), code = "below_min" },
					},
				}),
			},
			{ status = 503, body = s.json({ status = 503, code = "fields_unavailable", retryable = true }) },
			{ status = 403, body = s.json({ error = "Forbidden" }) },
		})
		s.run(function()
			local granted = c.codes:redeem({ UserId = 7 }, "  WELCOME ")
			if granted.status == "granted" then
				local reward = granted.rewards[1]
				check(granted.code == "WELCOME" and granted.redeemedAt == "now" and #granted.rewards == 1)
				check(reward.field == "Currency.Gems" and reward.op == "ADD" and #reward.path == 0)
				check(reward.before == Json.null and reward.after == 10)
			else
				check(false, "Expected granted")
			end
			local again = c.codes:redeem(7, "WELCOME")
			check(again.status == "already_redeemed" and again.rewards[1].after == 10)
			check(c.codes:redeem(7, "WELCOME").status == "expired")
			check(c.codes:redeem(7, "WELCOME").status == "not_started")
			check(c.codes:redeem(7, "WELCOME").status == "exhausted")
			check(c.codes:redeem(7, "WELCOME").status == "invalid")
			local unknown = c.codes:redeem(7, "WELCOME")
			check(
				unknown.status == "failed"
					and unknown.error.status == 409
					and unknown.error.code == "sdk_conflict"
			)
			check(c.codes:redeem(7, "NOPE").status == "invalid")
			local rejected = c.codes:redeem(7, "WELCOME")
			check(rejected.status == "failed" and rejected.error.code == "invalid_award")
			check(
				rejected.status == "failed"
					and rejected.error.grantPending
					and rejected.error.body == "[redacted]"
			)
			local outage = c.codes:redeem(7, "WELCOME")
			check(outage.status == "retry" and outage.error.code == "fields_unavailable")
			local denied = c.codes:redeem(7, "WELCOME")
			check(denied.status == "failed" and denied.error.kind == "Forbidden")
			check(f.count() == 11)
			check(
				c.codes:redeem(7, "   ").status == "invalid"
					and c.codes:redeem(7, string.rep("A", 129)).status == "invalid"
			)
			check(f.count() == 11, "Malformed codes are refused locally")
			c:destroy()
		end)
	end)
	test("Codes redeem treats malformed successful responses as failures, never grants", function()
		for _, body in { '{"transaction":{"txId":"x"}}', '{"redemptionId":9007199254740993}' } do
			local s = Scheduler.new()
			local c, f = client(s, { { body = body } })
			s.run(function()
				local outcome = c.codes:redeem(7, "WELCOME")
				check(outcome.status ~= "granted" and outcome.status ~= "already_redeemed")
			end)
			check(f.count() == 1)
			c:destroy()
		end
	end)
end
