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
	-- Profile loads now consume the coherent acquire snapshot, not a separate GET.
	for i = 2, #steps do
		local previous = if steps[i - 1].body
			then JsonDecode.decode(steps[i - 1].body :: string) :: any
			else nil
		local current = if steps[i].body then JsonDecode.decode(steps[i].body :: string) :: any else nil
		if previous and previous.definitions and current and current.data and current.userId then
			steps[i].body = s.json({
				items = {
					{
						userId = current.userId,
						status = "granted",
						epoch = 1,
						expiresAt = "2023-11-14T22:14:20Z",
						snapshot = { seq = current.seq, fields = current.data, versions = current.versions },
					},
				},
			})
		end
	end
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		profileSync = { enabled = false },
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		retryRatio = 1,
		retries = 1,
	}),
		fake
end
--- Supply a complete document with virtual defaults and independent version/seq metadata.
local function document(seq: number, gems: number, version: number?): Wire.Document
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
			["Currency.Gems"] = version or 0,
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
--- Supply an acknowledgement with independent field version and sparse allocation token.
local function receipt(seq: number, after: number, version: number?): Wire.Result
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
				version = version or 1,
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
				check(cache:load().ok)
				local first = cache:validator("Currency.Gems")
				check(
					not cache:refresh().ok
						and cache:version() == 13
						and cache:validator("Currency.Gems") == first
				)
				check(
					not cache:refresh().ok
						and cache:version() == 13
						and cache:validator("Currency.Gems") == first
				)
				cache:destroy()
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
				local loaded = cache:load()
				check(
					loaded.ok and cache:version() == 12,
					if loaded.ok then "schema version" else loaded.error.message
				)
				local validator = cache:validator("Currency.Gems")
				check(validator ~= nil)
				check((validator :: System.Validator).validate(7).ok)
				check(table.isfrozen(cache:definitions()))
				s.runtime.wait(0.11)
				check(cache:version() == 12 and cache.lastError ~= nil)
				s.runtime.wait(0.11)
				check(cache:version() == 12 and cache.lastError ~= nil)
				s.runtime.wait(0.11)
				check(cache:version() == 13 and cache.lastError == nil)
				cache:destroy()
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
					c.fields:transactionBuilder(7):add("Currency.Gems", 1):reason("reward"):commit(),
					"schema_unavailable"
				)
				check(f.count() == 0)
				check(c.fields:schemaCache():load().ok)
				local cases = {
					c.fields:transactionBuilder(7):add("Currency.Gems", 100001),
					c.fields:transactionBuilder(7):set("Currency.Gems", "wrong"),
					c.fields:transactionBuilder(7):add("Missing", 1),
					c.fields:transactionBuilder(7):add("Old", 1),
					c.fields:transactionBuilder(7):add("Shared", 1),
					c.fields:transactionBuilder(7):append("Currency.Gems", { 1 }),
					c.fields:transactionBuilder(7):mapAdd("Inventory.Items", "BOW", 1),
					c.fields:transactionBuilder(7):set("Settings", { Wrong = true }),
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
					local result = tx:reason("reward"):commit()
					code(result, expected[i])
					check(not result.ok and result.error.opIndex == 0)
				end
				local late = c.fields
					:transactionBuilder(7)
					:add("Currency.Gems", 1)
					:set("Currency.Gems", "wrong")
					:reason("reward")
					:commit()
				check(not late.ok and late.error.opIndex == 1)
				code(
					c.fields
						:transactionBuilder(7)
						:add("Currency.Gems", 1)
						:expect("Currency.Gems", { version = -1 })
						:reason("reward")
						:commit(),
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
				check(c.fields:schemaCache():load().ok)
				local tx = c.fields
					:transactionBuilder(7)
					:set("Characters", {})
					:append("Characters", { { Id = 1 } })
					:set("Currency.Gems", 4)
					:reason("quest reward")
					:ref("quest", "q1")
					:expect("Currency.Gems", { version = 0 })
				local key = tx:idempotencyKey()
				check(tx:commit().ok)
				check(tx:commit().ok)
				check(tx:idempotencyKey() == key and f.count() == 3)
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
			check(c.fields:schemaCache():load().ok)
			local tx = c.fields:transactionBuilder(7):add("Currency.Gems", 1):reason("reward")
			check(not tx:commit({ retry = 0 }).ok)
			check(tx:commit({ retry = 0 }).ok and bodies[1] == bodies[2])
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
			check(c.fields:schemaCache():load().ok)
			check(
				c.fields
					:multiTransactionBuilder()
					:subject(7)
					:add("Currency.Gems", 1)
					:subject(0)
					:add("Shared", 1)
					:reason("reward")
					:commit().ok
			)
			check(string.find(body, '"subject":0', 1, true) and string.find(body, '"subject":7', 1, true))
			local tx = c.fields:multiTransactionBuilder():reason("reward"):subject(1):add("Currency.Gems", 1)
			for user = 2, 11 do
				tx:subject(user):expect("Currency.Gems", { exists = true })
			end
			code(tx:commit(), "invalid_request")
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
				{ body = s.json(receipt(1001, 1)) },
				{
					body = s.json({ items = Json.array({}), latestSeq = 4000, nextSinceSeq = 2000 }),
					check = capture,
				},
				{
					body = s.json({ items = Json.array({}), latestSeq = 4000, nextSinceSeq = 4000 }),
					check = capture,
				},
				{ body = s.json(document(4000, 20, 2)) },
			})
			s.run(function()
				local loaded = c.fields:loadProfile(7)
				check(loaded.ok)
				if not loaded.ok then
					return
				end
				local profile = loaded.value
				check(Typed.Currency.Gems:get(profile) == 0)
				code(profile:tryGet("Old"), "field_archived")
				code(profile:tryGet("Missing"), "unknown_field")
				local tx = profile:immediate():reason("quest reward")
				Typed.Currency.Gems:add(tx, 1)
				check(
					tx:commit().ok
						and profile:get("Currency.Gems") == 1
						and profile.seq == 0
						and profile.versions["Currency.Gems"] == 1
				)
				check(tx:commit().ok and profile:get("Currency.Gems") == 1)
				check(profile:pullChanges().ok and profile:get("Currency.Gems") == 20 and profile.seq == 4000)
				check(
					string.find(cursors[1], "sinceSeq=0", 1, true)
						and string.find(cursors[2], "sinceSeq=2000", 1, true)
				)
				check(f.count() == 6)
				c:destroy()
			end)
		end
	)
	for _, vector in Vectors["profile-sync"] do
		test("Fields profile golden: " .. vector.name, function()
			local s = Scheduler.new()
			local c, f = client(s, {
				{ body = s.json(schema()) },
				{ body = s.json(document(10, 0)) },
			})
			s.run(function()
				local loaded = c.fields:loadProfile(7)
				check(loaded.ok)
				if not loaded.ok then
					return
				end
				local profile = loaded.value
				for i, result in vector.results do
					check(profile:apply(result) == vector.accepted[i], vector.name)
					check(profile.seq == 10, "Mutation token advanced the cursor")
				end
				for id, expected in vector.values do
					check(Json.encode(profile:get(id)) == Json.encode(expected), vector.name .. " value")
					check(profile.versions[id] == vector.versions[id], vector.name .. " version")
				end
				check(f.count() == 2, "Sparse/out-of-order tokens must not resync")
				c:destroy()
			end)
		end)
	end

	test("Fields real version and schema gaps drain feeds then recover a complete snapshot", function()
		for _, gap in
			{
				"missing_version",
				"invalid_version",
				"partial_version_gap",
				"schema_change",
				"unknown_field",
				"missing_results",
			}
		do
			local s = Scheduler.new()
			local cursors: { string } = {}
			local steps: { Fake.Step } = {
				{ body = s.json(schema()) },
				{ body = s.json(document(10, 0)) },
			}
			if gap == "schema_change" then
				table.insert(steps, { body = s.json(schema(13)) })
			end
			for _, cursor in { 500, 9000 } do
				table.insert(steps, {
					body = s.json({ items = Json.array({}), latestSeq = 9000, nextSinceSeq = cursor }),
					check = function(request)
						table.insert(cursors, request.Url)
					end,
				})
			end
			local recovered = document(9000, 25, 2)
			table.insert(steps, { body = s.json(recovered) })
			local c, f = client(s, steps)
			s.run(function()
				local loaded = c.fields:loadProfile(7)
				check(loaded.ok)
				if not loaded.ok then
					return
				end
				local profile = loaded.value
				local broken: any = receipt(4000, 1)
				if gap == "missing_version" then
					broken.results[1].version = nil
				elseif gap == "invalid_version" then
					broken.results[1].version = 1.5
				elseif gap == "partial_version_gap" then
					broken.results[1].field = "Settings"
					broken.results[1].path = { "Sound" }
					broken.results[1].after = false
					broken.results[1].version = 2
				elseif gap == "unknown_field" then
					broken.results[1].field = "New.Field"
				elseif gap == "missing_results" then
					broken.results = nil
				else
					check(c.fields:schemaCache():refresh().ok)
				end
				check(not profile:apply(broken), gap)
				code(profile:tryGet("Currency.Gems"), "profile_stale")
				check(profile.seq == 10 and profile.versions["Currency.Gems"] == 0)
				check(profile:pullChanges().ok, gap .. " recovery")
				check(profile:get("Currency.Gems") == 25 and profile.seq == 9000)
				check(string.find(cursors[1], "sinceSeq=10", 1, true) ~= nil)
				check(string.find(cursors[2], "sinceSeq=500", 1, true) ~= nil)
				check(f.count() == #steps)
				c:destroy()
			end)
		end
	end)

	test("Fields concurrent profile transactions retain player order across ticks", function()
		local s = Scheduler.new()
		local coins = receipt(9000, 20)
		local coinItems = coins.results :: { Wire.ResultItem }
		coinItems[1].field = "Currency.Coins"
		local c, f = client(s, {
			{ body = s.json(schema()) },
			{ body = s.json(document(10, 0)) },
			{ body = s.json(receipt(100, 10)), delay = 0.1 },
			{ body = s.json(coins), delay = 0.01 },
		})
		s.run(function()
			local loaded = c.fields:loadProfile(7)
			check(loaded.ok)
			if not loaded.ok then
				return
			end
			local profile = loaded.value
			local completed: { string } = {}
			s.runtime.spawn(function()
				check(profile:immediate():add("Currency.Gems", 10):reason("quest"):commit().ok)
				table.insert(completed, "gems")
			end)
			s.runtime.spawn(function()
				check(profile:immediate():add("Currency.Coins", 20):reason("quest"):commit().ok)
				table.insert(completed, "coins")
			end)
			s.runtime.wait(1.2)
			check(completed[1] == "gems" and completed[2] == "coins")
			check(profile:get("Currency.Gems") == 10 and profile:get("Currency.Coins") == 20)
			check(profile.versions["Currency.Gems"] == 1 and profile.versions["Currency.Coins"] == 1)
			check(profile.seq == 10 and f.count() == 4)
			c:destroy()
		end)
	end)

	test("Fields snapshot racing an acknowledgement cannot overwrite the newer field version", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json(schema()) },
			{ body = s.json(document(10, 0)) },
			{ body = s.json(document(10, 0)), delay = 0.1 },
		})
		s.run(function()
			local loaded = c.fields:loadProfile(7)
			check(loaded.ok)
			if not loaded.ok then
				return
			end
			local profile = loaded.value
			s.runtime.delay(0.01, function()
				check(profile:apply(receipt(7000, 10)))
			end)
			code(profile:refresh(), "snapshot_race")
			check(profile:get("Currency.Gems") == 10 and profile.versions["Currency.Gems"] == 1)
			check(profile.seq == 10 and f.count() == 3)
			c:destroy()
		end)
	end)

	test("Fields profile sync bypasses raw cached documents and older coalesced reads", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = s.json(document(10, 0)) }, -- Raw cache seed.
			{ body = s.json(schema()) },
			{ body = s.json(document(500, 10, 1)) },
			{ body = s.json(document(500, 10, 1)), delay = 0.1 }, -- Raw in-flight GET.
			{ body = s.json(document(9000, 20, 2)) },
		})
		s.run(function()
			check(c.fields:document({ path = { userId = 7 } }, { cacheTtl = 60 }).ok)
			local loaded = c.fields:loadProfile(7)
			check(loaded.ok)
			if not loaded.ok then
				return
			end
			local profile = loaded.value
			check(profile.seq == 500 and profile:get("Currency.Gems") == 10)
			s.runtime.spawn(function()
				check(c.fields:document({ path = { userId = 7 } }, { cacheTtl = 0 }).ok)
			end)
			s.runtime.wait(0.01)
			check(profile:refresh().ok and profile.seq == 9000)
			s.runtime.wait(0.2)
			check(f.count() == 5 and c:metrics().coalesced == 0)
			c:destroy()
		end)
	end)

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
		(doc.data :: any).Total = Json.null;
		(doc.versions :: { [string]: number }).Total = 0
		local c, f = client(s, { { body = s.json(contract) }, { body = s.json(doc) } })
		s.run(function()
			local loaded = c.fields:loadProfile(7)
			check(loaded.ok)
			if not loaded.ok then
				return
			end
			check(Typed.Total:get(loaded.value) == Json.null)
			code(loaded.value:immediate():set("Total", 1):reason("reward"):commit(), "field_computed")
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
				{ body = s.json({ items = { { userId = 7, status = "released" } } }) },
			})
			s.run(function()
				local loaded = c.fields:loadProfile(7)
				check(loaded.ok)
				if not loaded.ok then
					return
				end
				local profile = loaded.value
				local conflict = profile:startPresence(1, "session-a", 1)
				code(conflict, "session_conflict")
				check(not conflict.ok and conflict.error.body == "[redacted]")
				check(profile:startPresence(1, "session-a", 1).ok)
				s.runtime.wait(1.05)
				check(c:flush(2), "presence/session flush")
				c:destroy()
			end)
			check(f.count() == 7 and string.find(bodies[4], '"online":false', 1, true) and s.pending() == 0)
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
					c.fields:processReceipt({ purchaseId = "p1", userId = 7, productId = 1, robuxSpent = 25 }).ok
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
