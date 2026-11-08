--!strict
local SDK = require("../src/BloxSDK")
local Codes = require("../src/Types/Codes")
local Core = require("../src/Types/Core")
local Json = require("../src/Core/Json")
local JsonDecode = require("../src/Core/JsonDecode")
local Copy = require("../src/Core/Idempotency")
local Validation = require("../src/Core/Validation")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local BATCH = "00000000-0000-0000-0000-000000000005"
local CSV = "code,name,universeId,expiresAt,maxGlobalRedemptions\r\nSUMMER-K7M2XQ9PDA,Launch,123,,1\r\n"
--- Fail a regression without exposing request contents.
local function check(value: unknown)
	assert(value, "Bulk code regression at " .. tostring(debug.info(2, "l")))
end
--- Provide an exact request, never production data or credentials.
local function body(): Codes.BulkCreateCodesRequest
	return {
		universeId = 123,
		count = 1,
		name = "Launch",
		prefix = "SUMMER",
		award = { { field = "Currency.Gems", op = "ADD", delta = 100 } },
	}
end
--- Provide the compact bulk response rather than a full CodeDto.
local function response(): Codes.BulkCreateCodesResponse
	return { batchId = BATCH, count = 1, codes = { { id = 5, code = "SUMMER-K7M2XQ9PDA" } } }
end
--- Seed a loaded schema locally; other tests verify explicit schema loading over HTTP.
local function client(
	s: Scheduler.Scheduler,
	steps: { Fake.Step },
	level: Core.Level?
): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	local c = SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		profileSync = { enabled = false },
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		levels = if level then { CodeService = level } else nil,
	})
	local schema = c.fields:schemaCache(123)
	schema._version = 1
	schema._definitions["Currency.Gems"] = {
		universeId = 123,
		id = "Currency.Gems",
		description = "",
		scope = "PLAYER",
		status = "ACTIVE",
		type = { kind = "int" },
		definitionVersion = 1,
		createdAt = "now",
		updatedAt = "now",
	}
	return c, fake
end
--- Run offline wire, local-validation and retry-safety tests for F5 only.
return function(test: (string, () -> ()) -> ())
	test("Bulk generation sends one typed award and preserves a caller replay key", function()
		local s = Scheduler.new()
		local req = { body = body(), idempotencyKey = "launch:2026 / 1" }
		local c, f = client(s, {
			{
				status = 201,
				body = s.json(response()),
				check = function(wire)
					check(
						wire.Method == "POST"
							and wire.Url == "https://lb1.blox-api.com/code-service/api/codes/bulk"
					)
					check(wire.Headers["Idempotency-Key"] == "launch:2026 / 1")
					check(wire.Headers["Content-Type"] == "application/json")
					local value: any = JsonDecode.decode(wire.Body :: string)
					check(value.count == 1 and value.length == nil and value.idempotencyKey == nil)
					check(#value.award == 1 and value.award[1].delta == 100)
				end,
			},
		})
		s.run(function()
			local built = c.codes:award(123):add("Currency.Gems", 100):build()
			check(built.ok)
			if built.ok then
				req.body.award = built.value
			end
			local result = c.codes:bulkCreateCodes(req)
			check(result.ok and result.status == 201)
			if result.ok then
				check(
					result.value.batchId == BATCH
						and result.value.count == 1
						and result.value.codes[1].id == 5
				)
			end
			check(
				req.body.award[1].op == "ADD" and req.idempotencyKey == "launch:2026 / 1" and f.count() == 1
			)
			c:destroy()
		end)
	end)
	test("Bulk request DTO enforces F5 boundaries and rejects single-code-only or unknown fields", function()
		for _, count in { 1, 1000 } do
			for _, length in { 8, 16 } do
				local value = body()
				value.count, value.length = count, length
				check(Validation.body("codes.bulkCreateCodes", value))
			end
		end
		local invalid: { { any } } = {
			{ "count", 0 },
			{ "count", 1001 },
			{ "count", 1.5 },
			{ "count", "1" },
			{ "length", 7 },
			{ "length", 17 },
			{ "length", 8.5 },
			{ "length", "10" },
			{ "universeId", 0 },
			{ "universeId", 1.5 },
			{ "name", " " },
			{ "award", {} },
			{ "award", { { field = "Currency.Gems", op = "RESET", subject = 7 } } },
			{ "maxRedemptionsPerUser", 1 },
			{ "code", "MANUAL" },
			{ "metadata", { "not-an-object" } },
		}
		for _, pair in invalid do
			local value: any = body()
			value[pair[1]] = pair[2]
			check(not Validation.body("codes.bulkCreateCodes", value))
		end
		for _, name in { "universeId", "count", "name", "award" } do
			local value: any = body()
			value[name] = nil
			check(not Validation.body("codes.bulkCreateCodes", value))
		end
		local value = body()
		value.award = {}
		for _ = 1, 101 do
			table.insert(value.award, { field = "Currency.Gems", op = "RESET" })
		end
		check(not Validation.body("codes.bulkCreateCodes", value))
	end)
	test(
		"Bulk preflight fails closed before HTTP for invalid schema, request, key and permissions",
		function()
			local s = Scheduler.new()
			local c, f = client(s, {})
			s.run(function()
				local value = body()
				value.award = { { field = "Missing", op = "RESET" } }
				local unknown = c.codes:bulkCreateCodes({ body = value })
				check(not unknown.ok and unknown.error.code == "unknown_field")
				check(not c.codes:bulkCreateCodes({} :: any).ok)
				check(
					not c.codes:bulkCreateCodes({ body = body(), idempotencyKey = "bad\r\nInjected: yes" }).ok
				)
				check(not c.codes:bulkCreateCodes({ body = body(), idempotencyKey = "" }).ok)
				value = body()
				value.count = 1001
				check(not c.codes:bulkCreateCodes({ body = value }).ok)
				value = body()
				value.universeId = 456
				check(not c.codes:bulkCreateCodes({ body = value }).ok)
				c.fields:schemaCache(123)._version = nil
				local unloaded = c.codes:bulkCreateCodes({ body = body() })
				check(not unloaded.ok and unloaded.error.code == "schema_unavailable")
				check(f.count() == 0)
				c:destroy()
				local closed = c.codes:bulkCreateCodes({ body = body() })
				check(not closed.ok and closed.error.code == "client_closed")
				local restricted, backend = client(s, {}, "READ_WRITE")
				check(not restricted.codes:bulkCreateCodes({ body = body() }).ok)
				check(not restricted.codes:exportBatch({ path = { batchId = BATCH } }).ok)
				check(backend.count() == 0)
				restricted:destroy()
			end)
		end
	)
	test("Bulk calls never auto-retry; explicit keyed replay preserves the exact body and header", function()
		local s = Scheduler.new()
		local sent: string? = nil
		--- Require byte-identical explicit replay, without inventing or moving the key into JSON.
		local function keyed(wire: Core.HttpRequest)
			check(wire.Headers["Idempotency-Key"] == "persisted-campaign")
			if sent then
				check(sent == wire.Body)
			else
				sent = wire.Body
			end
		end
		local steps: { Fake.Step } = {}
		-- Earn retry budget so a zero-budget client cannot mask an unsafe automatic retry.
		for _ = 1, 6 do
			table.insert(steps, { body = CSV })
		end
		table.insert(steps, { status = 503, check = keyed })
		table.insert(steps, { status = 201, body = s.json(response()), check = keyed })
		table.insert(steps, {
			status = 503,
			check = function(wire)
				check(wire.Headers["Idempotency-Key"] == nil)
			end,
		})
		local c, f = client(s, steps)
		s.run(function()
			for _ = 1, 6 do
				check(c.codes:exportBatch({ path = { batchId = BATCH } }).ok)
			end
			local req = { body = body(), idempotencyKey = "persisted-campaign" }
			check(not c.codes:bulkCreateCodes(req, { retry = 3 }).ok)
			check(f.count() == 7)
			check(c.codes:bulkCreateCodes(req).ok and f.count() == 8)
			check(not c.codes:bulkCreateCodes({ body = body() }, { retry = 3 }).ok)
			check(f.count() == 9 and c:metrics().retries == 0)
			c:destroy()
		end)
	end)
	test("Batch filtering is separately encoded and CSV exports return untouched text", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{
				body = s.json({
					content = Json.array({}),
					number = 0,
					size = 10,
					totalElements = 0,
					totalPages = 0,
					first = true,
					last = true,
				}),
				check = function(wire)
					check(
						wire.Url
							== "https://lb1.blox-api.com/code-service/api/codes?batchId=batch%20%2F%3F&page=0&size=10&universeId=123"
					)
				end,
			},
			{
				body = CSV,
				check = function(wire)
					check(
						wire.Url
							== "https://lb1.blox-api.com/code-service/api/codes/batches/batch%20%2F%3F/export"
					)
					check(wire.Headers.Accept == "text/csv" and wire.Method == "GET")
				end,
			},
		})
		s.run(function()
			check(c.codes:searchCodes({ query = { batchId = "batch /?", page = 0, size = 10 } }).ok)
			local csv = c.codes:exportBatch({ path = { batchId = "batch /?" } })
			check(csv.ok and csv.value == CSV and f.count() == 2)
			c:destroy()
		end)
		check(Validation.response("codes.bulkCreateCodes", response(), 201))
		for _, name in { "batchId", "count", "codes" } do
			local value: any = Copy.copy(response())
			value[name] = nil
			check(not Validation.response("codes.bulkCreateCodes", value, 201))
		end
		local value: any = Copy.copy(response())
		value.codes[1].id = "5"
		check(not Validation.response("codes.bulkCreateCodes", value, 201))
	end)
end
