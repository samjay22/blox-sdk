--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local FieldTypes = require("../src/Fields/Types")
local System = require("../src/Fields/TypeSystem")
local Schema = require("../src/Fields/Schema")
local Copy = require("../src/Core/Idempotency")
local Json = require("../src/Core/Json")
local Exact = require("../src/Core/ExactNumbers")
local JsonDecode = require("../src/Core/JsonDecode")
local Codec = require("../src/Fields/WireCodec")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Vectors = require("./FixtureVectors")
local Typed = require("./golden/fields/Typed")
--- Fail a regression with context but without credentials or player values.
local function check(value: unknown, message: string?)
	assert(value, message or "Fields regression")
end
--- Require a precise local/server machine code.
local function code(result: Core.Result<any>, expected: string)
	check(
		not result.ok and result.error.code == expected,
		"Expected code "
			.. expected
			.. " got "
			.. (if result.ok then "success" else tostring(result.error.code))
	)
end
--- Build a full wire schema from the contract example, excluding computed/read-only extra fixtures for profiles.
local function schema(version: number?): Wire.SchemaResponse
	local value = Copy.copy(Vectors.schema)
	value.schemaVersion = version or 12
	local definitions = {}
	for _, d in value.definitions do
		d.universeId = 123
		d.definitionVersion = 1
		d.description = ""
		d.createdAt = "now"
		d.updatedAt = "now"
		if not d.computed then
			d.history = d.history or "LEDGER"
			d.writeLevel = "READ_WRITE"
		end
		if d.id ~= "Total" then
			table.insert(definitions, d)
		end
	end
	value.definitions = definitions
	return value
end
--- Create an authenticated offline Fields facade using the existing deterministic transport.
local function client(s: Scheduler.Scheduler, steps: { Fake.Step }): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		retryRatio = 1,
		retries = 1,
	}),
		fake
end
--- Supply a complete document with virtual defaults and independent version/seq metadata.
local function document(seq: number, gems: number): Wire.Document
	return {
		userId = 7,
		seq = seq,
		data = {
			Currency = { Gems = gems, Coins = 0 },
			Inventory = { Items = {} },
			Characters = Json.array({}),
			Settings = { Sound = true, Language = "EN" },
			Metrics = { Kills = 0, PlaySeconds = 0 },
			Tags = Json.array({}),
			Ranks = {},
			Optional = Json.null,
		},
		versions = {
			["Currency.Gems"] = seq,
			["Currency.Coins"] = 0,
			["Inventory.Items"] = 0,
			Characters = 0,
			Settings = 0,
			Metrics = 0,
			Tags = 0,
			Ranks = 0,
			Optional = 0,
		},
	}
end
--- Supply a real transaction acknowledgement with a touched subvalue and final subject watermark.
local function receipt(seq: number, after: number): Wire.Result
	return {
		txId = "tx-" .. seq,
		replayed = false,
		results = {
			{
				subject = 7,
				field = "Currency.Gems",
				path = Json.array({}),
				op = "ADD",
				before = after - 1,
				after = after,
				version = seq,
				entryId = "entry",
			},
		},
		seq = { ["7"] = seq },
	}
end
--- Register shared oracle vectors plus cache/builder/profile/receipt/lifecycle regressions.
return function(test: (string, () -> ()) -> ())
	test(
		"Fields TypeSystem shared JSON vectors: all kinds, defaults, operations, paths and exactness",
		function()
			local count = 0
			local exceptions = 0
			for _, v in Vectors["type-system"] do
				if v.luauSkip then
					exceptions += 1
					continue
				end
				local result: Core.Result<any>
				if v.action == "compile" then
					local compiled = System.compile(v.type)
					result = if compiled.ok then { ok = true, value = true } else compiled
				elseif v.action == "default" then
					result = System.default(v.type, v.default)
				elseif v.action == "apply" then
					result = System.apply(v.type, v.value, v.default, v.op, v.args, v.path)
				else
					result = System.validate(v.type, v.value)
				end
				local expectedCode = v.luauCode or v.code
				if expectedCode then
					check(
						not result.ok and result.error.code == expectedCode,
						v.name
							.. ": expected "
							.. expectedCode
							.. ", got "
							.. (if result.ok then "success" else tostring(result.error.code))
					)
					if v.action == "apply" and not result.ok then
						check(System.equal(result.error.path or {}, v.path or {}), v.name .. " path")
					end
				else
					check(
						result.ok and System.equal(result.value, v.expected),
						v.name .. ": unexpected value/error"
					)
				end
				count += 1
			end
			check(count == 133 and exceptions == 1)
			print("PASS 133 shared Luau vectors; 1 documented JSON integer-token representation difference")
		end
	)
	test(
		"Fields strict JSON decoder preserves null/array identity, Unicode and rejects malformed tokens",
		function()
			local value =
				JsonDecode.decode(' {"a":[null,1,false],"b":null,"c":{},"u":"\\uD83D\\uDE00"} ') :: any
			check(
				value.a[1] == Json.null and value.b == Json.null and value.a[3] == false and value.u == "😀"
			)
			check(Json.isArray(value.a) and Json.isObject(value.c))
			code(System.validate({ kind = "list", item = { kind = "int" } }, value.c), "wrong_type")
			for _, bad in
				{
					'{"x":1,"x":2}',
					"[1,]",
					'{"x":01}',
					'{"x":1.}',
					'{"x":1e}',
					'{"x":9007199254740992}',
					'"\\uD800"',
					"true false",
				}
			do
				check(not pcall(JsonDecode.decode, bad))
			end
		end
	)
	test(
		"Fields schema rejects invalid generations and prefix collisions without discarding last good",
		function()
			local s = Scheduler.new()
			local iteration = 0
			local cache = Schema.new(s.runtime, function()
				iteration += 1
				local value = schema(12 + iteration)
				if iteration == 2 then
					local duplicate = Copy.copy(value.definitions[1])
					duplicate.id = "Currency"
					table.insert(value.definitions, duplicate)
				elseif iteration == 3 then
					(value.definitions[1] :: any).type = { kind = "int", extra = true }
				end
				return { ok = true, value = value }
			end)
			s.run(function()
				check(cache:Load().ok)
				local first = cache:Validator("Currency.Gems")
				check(
					not cache:Refresh().ok
						and cache:Version() == 13
						and cache:Validator("Currency.Gems") == first
				)
				check(
					not cache:Refresh().ok
						and cache:Version() == 13
						and cache:Validator("Currency.Gems") == first
				)
				cache:Destroy()
			end)
		end
	)

	test("Fields numeric encoding refuses unsafe wire integers and never emits exponent-form ints", function()
		check(Json.encode(1000000000000000) == "1000000000000000")
		check(not pcall(Exact.check, '{"v":9007199254740992}'))
		check(Exact.check('{"v":9007199254740991,"s":"9007199254740992"}') ~= "")
		code(System.validate({ kind = "number" }, math.huge), "non_finite_number")
		local huge: any = { kind = "list", item = { kind = "int" } }
		for _ = 1, 8 do
			huge = { kind = "list", item = huge }
		end
		code(System.compile(huge), "invalid_definition")
	end)
	test(
		"Fields schema generation cache compiles validators, retains last good and cancels polling",
		function()
			local s = Scheduler.new()
			local requests = 0
			local cache = Schema.new(s.runtime, function()
				requests += 1
				if requests == 2 then
					return System.failure("schema_unavailable")
				end
				if requests == 3 then
					return { ok = true, value = schema(11) }
				end
				return { ok = true, value = schema(if requests > 3 then 13 else 12) }
			end, 0.1)
			s.run(function()
				local loaded = cache:Load()
				check(
					loaded.ok and cache:Version() == 12,
					if loaded.ok then "schema version" else loaded.error.message
				)
				local validator = cache:Validator("Currency.Gems")
				check(validator ~= nil)
				check((validator :: System.Validator).Validate(7).ok)
				check(table.isfrozen(cache:Definitions()))
				s.runtime.wait(0.11)
				check(cache:Version() == 12 and cache.LastError ~= nil)
				s.runtime.wait(0.11)
				check(cache:Version() == 12 and cache.LastError ~= nil)
				s.runtime.wait(0.11)
				check(cache:Version() == 13 and cache.LastError == nil)
				cache:Destroy()
			end)
			check(requests == 4 and s.pending() == 0)
		end
	)
	test(
		"Fields static validation rejects impossible collection capacities without inventing player state",
		function()
			local list: FieldTypes.TypeExpr =
				{ kind = "list", item = { kind = "int" }, minSize = 1, maxSize = 2 }
			code(System.checkOperation(list, "APPEND", { items = { 1, 2 } }), "above_max_size")
			code(System.checkOperation(list, "INSERT", { index = 3, items = { 1 } }), "not_found")
			code(System.checkOperation(list, "REMOVE_AT", { index = 1, count = 2 }), "not_found")
			code(
				System.checkOperation(
					{ kind = "set", item = { kind = "int" }, maxSize = 1 },
					"SET_ADD",
					{ items = { 1, 2 } }
				),
				"above_max_size"
			)
			code(
				System.checkOperation(
					{ kind = "map", key = { kind = "string" }, value = { kind = "int" }, maxSize = 1 },
					"MAP_PUT",
					{ entries = { a = 1, b = 2 } }
				),
				"above_max_size"
			)
			check(System.checkOperation({ kind = "int", min = 0 }, "ADD", { delta = -10 }).ok)
		end
	)

	test(
		"Fields builder validates every operation before transport and never fetches a missing schema",
		function()
			local s = Scheduler.new()
			local c, f = client(s, { { body = s.json(schema()) } })
			s.run(function()
				code(
					c.fields:Transaction(123, 7):Add("Currency.Gems", 1):Reason("reward"):Commit(),
					"schema_unavailable"
				)
				check(f.count() == 0)
				check(c.fields:Schema(123):Load().ok)
				local cases = {
					c.fields:Transaction(123, 7):Add("Currency.Gems", 100001),
					c.fields:Transaction(123, 7):Set("Currency.Gems", "wrong"),
					c.fields:Transaction(123, 7):Add("Missing", 1),
					c.fields:Transaction(123, 7):Add("Old", 1),
					c.fields:Transaction(123, 7):Add("Shared", 1),
					c.fields:Transaction(123, 7):Append("Currency.Gems", { 1 }),
					c.fields:Transaction(123, 7):MapAdd("Inventory.Items", "BOW", 1),
					c.fields:Transaction(123, 7):Set("Settings", { Wrong = true }),
				}
				local expected = {
					"max_delta_exceeded",
					"wrong_type",
					"unknown_field",
					"field_archived",
					"field_scope_mismatch",
					"op_not_applicable",
					"invalid_enum",
					"unknown_member",
				}
				for i, tx in cases do
					local result = tx:Reason("reward"):Commit()
					code(result, expected[i])
					check(not result.ok and result.error.opIndex == 0)
				end
				local late = c.fields
					:Transaction(123, 7)
					:Add("Currency.Gems", 1)
					:Set("Currency.Gems", "wrong")
					:Reason("reward")
					:Commit()
				check(not late.ok and late.error.opIndex == 1)
				code(
					c.fields
						:Transaction(123, 7)
						:Add("Currency.Gems", 1)
						:Expect("Currency.Gems", { version = -1 })
						:Reason("reward")
						:Commit(),
					"invalid_request"
				)
				check(f.count() == 1)
				c:destroy()
			end)
		end
	)
	test(
		"Fields builder serializes canonical arrays/defaults and reuses identity for retries and Commit",
		function()
			local s = Scheduler.new()
			local bodies: { string } = {}
			local capture = function(r: Core.HttpRequest)
				table.insert(bodies, r.Body :: string)
			end
			local c, f = client(s, {
				{ body = s.json(schema()) },
				{ status = 503, check = capture },
				{ body = s.json(receipt(1, 1)), check = capture },
			})
			s.run(function()
				check(c.fields:Schema(123):Load().ok)
				local tx = c.fields
					:Transaction(123, 7)
					:Set("Characters", {})
					:Append("Characters", { { Id = 1 } })
					:Set("Currency.Gems", 4)
					:Reason("quest reward")
					:Ref("quest", "q1")
					:Expect("Currency.Gems", { version = 0 })
				local key = tx:IdempotencyKey()
				check(tx:Commit().ok)
				check(tx:Commit().ok)
				check(tx:IdempotencyKey() == key and f.count() == 3)
				check(bodies[1] == bodies[2] and string.find(bodies[1], '"value":[]', 1, true))
				check(
					string.find(bodies[1], '"Level":1', 1, true)
						and string.find(bodies[1], '"Rarity":"COMMON"', 1, true)
				)
				c:destroy()
			end)
		end
	)
	test("Fields uncertain transaction retry seals payload and keeps its once-generated key", function()
		local s = Scheduler.new()
		local bodies: { string } = {}
		local capture = function(r: Core.HttpRequest)
			table.insert(bodies, r.Body :: string)
		end
		local c, f = client(s, {
			{ body = s.json(schema()) },
			{ status = 500, check = capture },
			{
				body = s.json(receipt(1, 1)),
				check = capture,
			},
		})
		s.run(function()
			check(c.fields:Schema(123):Load().ok)
			local tx = c.fields:Transaction(123, 7):Add("Currency.Gems", 1):Reason("reward")
			check(not tx:Commit({ retry = 0 }).ok)
			check(tx:Commit({ retry = 0 }).ok and bodies[1] == bodies[2])
			check(f.count() == 3)
			c:destroy()
		end)
	end)
	test("Fields multi-subject scope and limit includes both ops and conditions", function()
		local s = Scheduler.new()
		local body = ""
		local c, f = client(s, {
			{ body = s.json(schema()) },
			{
				body = s.json(receipt(1, 1)),
				check = function(r)
					body = r.Body :: string
				end,
			},
		})
		s.run(function()
			check(c.fields:Schema(123):Load().ok)
			check(
				c.fields
					:MultiTransaction(123)
					:Subject(7)
					:Add("Currency.Gems", 1)
					:Subject(0)
					:Add("Shared", 1)
					:Reason("reward")
					:Commit().ok
			)
			check(string.find(body, '"subject":0', 1, true) and string.find(body, '"subject":7', 1, true))
			local tx = c.fields:MultiTransaction(123):Reason("reward"):Subject(1):Add("Currency.Gems", 1)
			for user = 2, 11 do
				tx:Subject(user):Expect("Currency.Gems", { exists = true })
			end
			code(tx:Commit(), "invalid_request")
			check(f.count() == 2)
			c:destroy()
		end)
	end)
	test(
		"Fields profile getters, committed local application, change cursor groups and NONE-history snapshot",
		function()
			local s = Scheduler.new()
			local cursors: { string } = {}
			local capture = function(r: Core.HttpRequest)
				table.insert(cursors, r.Url)
			end
			local c, f = client(s, {
				{ body = s.json(schema()) },
				{ body = s.json(document(0, 0)) },
				{ body = s.json(receipt(1, 1)) },
				{
					body = s.json({ items = Json.array({}), latestSeq = 4, nextSinceSeq = 2 }),
					check = capture,
				},
				{
					body = s.json({ items = Json.array({}), latestSeq = 4, nextSinceSeq = 4 }),
					check = capture,
				},
				{ body = s.json(document(4, 20)) },
			})
			s.run(function()
				local loaded = c.fields:LoadProfile(123, 7)
				check(loaded.ok)
				if not loaded.ok then
					return
				end
				local profile = loaded.value
				check(Typed.Currency.Gems:Get(profile) == 0)
				code(profile:TryGet("Old"), "field_archived")
				code(profile:TryGet("Missing"), "unknown_field")
				local tx = profile:Transaction():Reason("quest reward")
				Typed.Currency.Gems:Add(tx, 1)
				check(
					tx:Commit().ok
						and profile:Get("Currency.Gems") == 1
						and profile.Seq == 1
						and profile.Versions["Currency.Gems"] == 1
				)
				check(tx:Commit().ok and profile:Get("Currency.Gems") == 1)
				check(profile:PullChanges().ok and profile:Get("Currency.Gems") == 20 and profile.Seq == 4)
				check(
					string.find(cursors[1], "sinceSeq=1", 1, true)
						and string.find(cursors[2], "sinceSeq=2", 1, true)
				)
				check(f.count() == 6)
				c:destroy()
			end)
		end
	)
	test("Fields computed profile values are nullable numeric and never writable", function()
		local s = Scheduler.new()
		local contract = schema()
		local computed: any = {
			universeId = 123,
			id = "Total",
			scope = "PLAYER",
			status = "ACTIVE",
			definitionVersion = 1,
			description = "",
			createdAt = "now",
			updatedAt = "now",
			computed = { expression = "Currency.Gems + Currency.Coins", returns = "int" },
		}
		table.insert(contract.definitions, computed)
		local doc = document(0, 0);
		(doc.data :: any).Total = Json.null
		doc.versions.Total = 0
		local c, f = client(s, { { body = s.json(contract) }, { body = s.json(doc) } })
		s.run(function()
			local loaded = c.fields:LoadProfile(123, 7)
			check(loaded.ok)
			if not loaded.ok then
				return
			end
			check(Typed.Total:Get(loaded.value) == Json.null)
			code(loaded.value:Transaction():Set("Total", 1):Reason("reward"):Commit(), "field_computed")
			check(f.count() == 2)
			c:destroy()
		end)
	end)

	test(
		"Fields presence session ownership surfaces 409 code and flush sends offline before closing admission",
		function()
			local s = Scheduler.new()
			local bodies: { string } = {}
			local capture = function(r: Core.HttpRequest)
				table.insert(bodies, r.Body :: string)
			end
			local c, f = client(s, {
				{ body = s.json(schema()) },
				{ body = s.json(document(0, 0)) },
				{
					status = 409,
					body = s.json({ code = "session_conflict", message = "do not expose" }),
					check = capture,
				},
				{
					body = s.json({ userId = 7, online = true, sessionId = "session-a", placeId = 1 }),
					check = capture,
				},
				{
					body = s.json({ userId = 7, online = true, sessionId = "session-a", placeId = 1 }),
					check = capture,
				},
				{
					body = s.json({ userId = 7, online = false, sessionId = "session-a", placeId = 1 }),
					check = capture,
				},
			})
			s.run(function()
				local loaded = c.fields:LoadProfile(123, 7)
				check(loaded.ok)
				if not loaded.ok then
					return
				end
				local profile = loaded.value
				local conflict = profile:StartPresence(1, "session-a", 1)
				code(conflict, "session_conflict")
				check(not conflict.ok and conflict.error.body == "[redacted]")
				check(profile:StartPresence(1, "session-a", 1).ok)
				s.runtime.wait(1.05)
				check(c:flush(2))
				c:destroy()
			end)
			check(f.count() == 6 and string.find(bodies[4], '"online":false', 1, true) and s.pending() == 0)
		end
	)
	test(
		"Fields document without key never retries; explicit key and receipt purchaseId retries remain stable",
		function()
			local s = Scheduler.new()
			local bodies: { string } = {}
			local capture = function(r: Core.HttpRequest)
				table.insert(bodies, r.Body :: string)
			end
			local c, f = client(s, {
				{ status = 503 },
				{ status = 503, check = capture },
				{ body = s.json(receipt(1, 1)), check = capture },
				{ status = 429, headers = { ["Retry-After"] = "1" }, check = capture },
				{
					body = s.json({
						purchaseId = "p1",
						status = "GRANTED",
						replayed = true,
						transaction = receipt(2, 2),
					}),
					check = capture,
				},
			})
			s.run(function()
				check(not c.fields:putDocument({
					path = { userId = 7 },
					body = { reason = "save", data = { Currency = { Gems = 1 } } },
				}).ok)
				check(f.count() == 1)
				check(c.fields:putDocument({
					path = { userId = 7 },
					body = { reason = "save", idempotencyKey = "save-1", data = { Currency = { Gems = 1 } } },
				}).ok)
				check(
					c.fields:ProcessReceipt(
						123,
						{ purchaseId = "p1", userId = 7, productId = 1, robuxSpent = 25 }
					).ok
				)
				check(bodies[1] == bodies[2] and bodies[3] == bodies[4] and s.time() >= 1)
				c:destroy()
			end)
			check(f.count() == 5)
		end
	)
	test("Fields generated domain adapters round-trip sets, int maps and explicit nullable values", function()
		local t: FieldTypes.TypeExpr = {
			kind = "object",
			members = {
				Tags = { type = { kind = "set", item = { kind = "string" } } },
				Counts = { type = { kind = "map", key = { kind = "int" }, value = { kind = "int" } } },
				Optional = { type = { kind = "nullable", of = { kind = "bool" } } },
			},
		}
		local wire = Codec.encode(
			t,
			{ Tags = { rare = true, common = true }, Counts = { [7] = 3 }, Optional = Json.null }
		)
		check(
			System.equal(wire, { Tags = { "common", "rare" }, Counts = { ["7"] = 3 }, Optional = Json.null })
		)
		local domain = Codec.decode(t, wire)
		check(domain.Tags.rare and domain.Counts[7] == 3 and domain.Optional == Json.null)
	end)
end
