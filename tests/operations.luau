--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
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
	return {
		txId = "tx-1",
		replayed = false,
		seq = { ["7"] = 1 },
		results = {
			{
				subject = 7,
				field = "Currency.Gems",
				path = Json.array({}),
				op = "ADD",
				before = Json.null,
				after = 10,
				version = 1,
				entryId = Json.null,
			},
		},
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
		check(cache:Load().ok)
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
		cache:Destroy()
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
					c.fields:validateOps({ body = { ops = { { field = "Currency.Gems", op = "RESET" } } } }),
					"schema_unavailable"
				)
				check(f.count() == 0)
				check(c.fields:Schema(123):Load().ok)
				local invalid = c.fields:validateOps({
					body = { ops = { { field = "Missing", op = "RESET" }, { field = "Old", op = "RESET" } } },
				})
				check(
					invalid.ok and not invalid.value.valid and #invalid.value.errors == 2 and f.count() == 1
				)
				local valid = c.fields
					:Operations(123)
					:Add("Currency.Gems", -1)
					:MapAdd("Inventory.Items", "SWORD", 1)
					:validate()
				check(
					valid.ok and not valid.value.valid and System.equal(valid.value.errors, errors),
					if valid.ok
						then Json.encode(valid.value.errors)
						else (valid.error.code or valid.error.message)
				)
				code(
					c.fields:validateOps({
						body = {
							universeId = 124,
							ops = {
								{ field = "Currency.Gems", op = "RESET" },
							},
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
			check(c.fields:Schema(123):Load().ok)
			local tx = c.fields:Transaction(123, 7):Add("Currency.Gems", 1)
			local key = tx:IdempotencyKey()
			check(tx:validate().ok and not tx._sealed and tx:IdempotencyKey() == key)
			check(tx:Add("Currency.Gems", 1):Reason("Admin reward"):Commit().ok)
			code(
				c.fields:MultiTransaction(123):Subject(7):Add("Currency.Gems", 1):validate(),
				"invalid_request"
			)
			check(f.count() == 3)
			c:destroy()
		end)
	end)
	test("Codes typed award builder snapshots and canonicalizes Fields operations before create", function()
		local s = Scheduler.new()
		local response: Codes.CodeDto = {
			id = 9,
			universeId = 123,
			code = "WELCOME",
			award = { { field = "Currency.Gems", op = "ADD", delta = 10 } },
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
			{ body = s.json({ valid = true, errors = Json.array({}) }) },
			{
				status = 201,
				body = s.json(response),
				check = function(request)
					check(request.Url == "https://lb1.blox-api.com/code-service/api/codes")
					local body: any = JsonDecode.decode(request.Body :: string)
					check(#body.award == 3 and body.award[1].delta == 10 and body.award[1].subject == nil)
					check(string.find(request.Body :: string, '"items":[]', 1, true) ~= nil)
				end,
			},
		})
		s.run(function()
			check(c.fields:Schema(123):Load().ok)
			local builder = c.codes:Award(123):Add("Currency.Gems", 10):SetAdd("Tags", {}):Reset("Optional")
			local built = builder:build()
			check(built.ok)
			if not built.ok then
				return
			end
			check(builder:validate().ok)
			builder:Add("Currency.Gems", 5)
			check(#built.value == 3)
			check(c.codes:createCode({ code = "WELCOME", award = built.value, maxRedemptionsPerUser = 1 }).ok)
			code(
				c.codes:createCode({ code = "BAD", award = built.value, maxRedemptionsPerUser = 2 }),
				"invalid_request"
			)
			code(
				c.codes:createCode({ code = "BAD", award = { { field = "Missing", op = "RESET" } } }),
				"unknown_field"
			)
			code(
				c.codes:updateCode({
					path = { id = 9 },
					body = { award = { { field = "Old", op = "RESET" :: "RESET" } } },
				}),
				"field_archived"
			)
			code(
				c.codes:createCode(
					{ code = "BAD", award = { { field = "Currency.Gems", op = "RESET", subject = 7 } } } :: any
				),
				"invalid_request"
			)
			check(f.count() == 3)
			c:destroy()
		end)
		code(
			c.codes:createCode({ code = "CLOSED", award = { { field = "Currency.Gems", op = "RESET" } } }),
			"client_closed"
		)
	end)
	test("Code redemption decodes typed receipt nulls, replays and safe error diagnostics", function()
		local s = Scheduler.new()
		local response = {
			redemptionId = 42,
			codeId = 9,
			code = "WELCOME",
			universeId = 123,
			robloxUserId = 7,
			transaction = receipt(),
			replayed = true,
			redeemedAt = "now",
		}
		local c, f = client(s, {
			{
				body = s.json(response),
				check = function(request)
					check(
						System.equal(
							JsonDecode.decode(request.Body :: string),
							{ code = "WELCOME", robloxUserId = 7 }
						)
					)
				end,
			},
			{
				status = 422,
				body = s.json({
					code = "invalid_award",
					message = "must not escape",
					grantPending = true,
					errors = {
						{ opIndex = 0, field = "Currency.Gems", path = Json.array({}), code = "below_min" },
						{ opIndex = 1, field = "Settings", path = { "Sound" }, code = "wrong_type" },
					},
				}),
			},
		})
		s.run(function()
			local result = c.codes:redeem({ code = "WELCOME", robloxUserId = 7 })
			check(result.ok and result.value.replayed and not result.value.transaction.replayed)
			check(
				result.ok
					and result.value.transaction.results[1].entryId == Json.null
					and result.value.transaction.results[1].before == Json.null
			)
			local rejected = c.codes:redeem({ code = "WELCOME", robloxUserId = 7 })
			code(rejected, "invalid_award")
			check(
				not rejected.ok
					and rejected.error.grantPending
					and rejected.error.errors
					and #rejected.error.errors == 2
					and rejected.error.body == "[redacted]"
			)
			check(f.count() == 2)
			c:destroy()
		end)
	end)
	test("Code receipts fail closed on unsafe integers and incomplete successful responses", function()
		for _, body in { '{"transaction":{"txId":"x"}}', '{"redemptionId":9007199254740993}' } do
			local s = Scheduler.new()
			local c, f = client(s, { { body = body } })
			s.run(function()
				check(not c.codes:redeem({ code = "WELCOME", robloxUserId = 7 }).ok)
			end)
			check(f.count() == 1)
			c:destroy()
		end
	end)
end
