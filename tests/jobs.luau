--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
local Copy = require("../src/Core/Idempotency")
local System = require("../src/Fields/TypeSystem")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Vectors = require("./FixtureVectors")
local JOB = "00000000-0000-0000-0000-000000000001"
--- Assert a regression without logging credentials or uploaded records.
local function check(value: unknown, message: string?)
	assert(value, message or ("Job regression at " .. tostring(debug.info(2, "l"))))
end
--- Complete shared definitions with response metadata, preserving their declared constraints.
local function schema(): Wire.SchemaResponse
	local value = Copy.copy(Vectors.schema)
	for _, definition in
		{
			{ id = "Enabled", type = { kind = "bool" } },
			{ id = "Label", type = { kind = "string", minLength = 1, maxLength = 8 } },
			{ id = "Rarity", type = { kind = "enum", values = { "COMMON", "RARE" } }, default = "COMMON" },
			{ id = "Ratio", type = { kind = "number", min = 0, max = 1 } },
		} :: { any }
	do
		definition.status = "ACTIVE"
		if definition.id == "Label" then
			definition.default = "Player"
		end
		table.insert(value.definitions, definition)
	end
	for _, definition in value.definitions do
		definition.description = ""
		definition.universeId = 123
		definition.definitionVersion = 1
		definition.createdAt = "2026-11-05T00:00:00Z"
		definition.updatedAt = "2026-11-05T00:00:00Z"
		if not definition.computed then
			definition.history = "LEDGER"
			definition.writeLevel = "READ_WRITE"
		end
	end
	return value
end
--- Construct the exact safe receipt; SUCCEEDED deliberately includes a per-item failure.
local function receipt(state: string): Wire.JobReceipt
	return {
		id = JOB,
		kind = "BULK",
		state = state :: any,
		total = 2,
		succeeded = if state == "SUCCEEDED" then 1 else 0,
		failed = if state == "SUCCEEDED" then 1 else 0,
		prepared = true,
		cancelRequested = false,
		attempts = 0,
		updatedAt = "2026-11-05T00:00:00Z",
	}
end
--- Build an offline scoped client; metadata permissions are hints, never grants.
local function client(
	s: Scheduler.Scheduler,
	steps: { Fake.Step },
	level: Core.Level?,
	retries: number?
): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	return SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		profileSync = { enabled = false },
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
		levels = { FieldsService = level or "ADMIN" },
		retries = retries or 0,
		retryRatio = 1,
	}),
		fake
end
--- Supply an immutable-looking but caller-owned schedule for snapshot tests.
local function schedule(): Wire.ScheduleInput
	return {
		name = "Double gems",
		start = "2026-12-01T12:00:00Z",
		["end"] = "2026-12-01T14:00:00Z",
		startActions = { { kind = "ENABLE_FLAG", key = "double_gems" } },
		restorePrevious = true,
		reason = "Double gems weekend",
		idempotencyKey = "double-gems-dec1",
	}
end
--- Register operational helpers against a deterministic transport and clock on every runtime.
return function(test: (string, () -> ()) -> ())
	test("Bulk snapshots nested typed ops and validates filters before any request", function()
		local s = Scheduler.new()
		local c, f = client(s, { { body = s.json(schema()) } })
		s.run(function()
			local unloaded = c.fields
				:bulkBuilder()
				:target({ kind = "ALL" })
				:reason("Reward event")
				:idempotencyKey("event-1")
			unloaded.ops:add("Currency.Gems", 1)
			check(not unloaded:build().ok and f.count() == 0)
			check(c.fields:schemaCache():load().ok)
			local bulk = c.fields
				:bulkBuilder()
				:target({
					kind = "WHERE",
					where = {
						op = "AND",
						clauses = {
							{ op = "GE", field = "Currency.Gems", value = 100 },
							{
								op = "NOT",
								clause = { op = "EXISTS", field = "Currency.Coins", value = false },
							},
						},
					},
				})
				:reason("Reward event")
				:idempotencyKey("event-1")
			bulk.ops
				:add("Currency.Gems", 10)
				:set("Settings", false, { "Sound" })
				:mapAdd("Inventory.Items", "SWORD", 1)
			local built = bulk:build()
			check(built.ok and #built.value.ops == 3)
			bulk.ops:add("Currency.Gems", 1)
			check(built.ok and #built.value.ops == 3)
			local malformed: { any } = {
				{ kind = "SUBJECTS", subjects = { 0 } },
				{ kind = "SUBJECTS", subjects = { 7, 7 } },
				{ kind = "ALL", subjects = { 7 } },
				{ kind = "WHERE", where = { op = "EQ", field = "Missing", value = 1 } },
				{ kind = "WHERE", where = { op = "EQ", field = "Shared", value = 1 } },
				{ kind = "WHERE", where = { op = "EQ", field = "Total", value = 1 } },
				{ kind = "WHERE", where = { op = "EQ", field = "Settings", value = true } },
				{ kind = "WHERE", where = { op = "EQ", field = "Optional", value = 1 } },
				{ kind = "WHERE", where = { op = "EQ", field = "Currency.Gems", value = "1" } },
				{ kind = "WHERE", where = { op = "EQ", field = "Currency.Gems", value = 1, path = {} } },
				{ kind = "WHERE", where = { op = "SQL", field = "Currency.Gems", value = 1 } },
				{ kind = "WHERE", where = { op = "EXISTS", field = "Currency.Gems", value = 1 } },
				{ kind = "WHERE", where = { op = "AND", clauses = {} } },
				{ kind = "WHERE", where = { op = "IN", field = "Currency.Gems", value = {} } },
				{ kind = "WHERE", where = { op = "EQ", field = "Enabled", value = 1 } },
				{ kind = "WHERE", where = { op = "EQ", field = "Label", value = "too-long-label" } },
				{ kind = "WHERE", where = { op = "EQ", field = "Rarity", value = "LEGENDARY" } },
				{ kind = "WHERE", where = { op = "EQ", field = "Ratio", value = 2 } },
			}
			local cycle: any = { op = "NOT" }
			cycle.clause = cycle
			table.insert(malformed, { kind = "WHERE", where = cycle })
			for _, target in malformed do
				local bad =
					c.fields:bulkBuilder():target(target):reason("Reward event"):idempotencyKey("event-1")
				bad.ops:add("Currency.Gems", 1)
				check(not bad:preview().ok, "Malformed filter reached transport")
			end
			for _, field in { "Missing", "Old", "Shared", "Total" } do
				local bad = c.fields
					:bulkBuilder()
					:target({ kind = "ALL" })
					:reason("Reward event")
					:idempotencyKey("event-1")
				bad.ops:reset(field)
				check(not bad:submit().ok)
			end
			local bad = c.fields
				:bulkBuilder()
				:target({ kind = "ALL" })
				:reason("Reward event")
				:idempotencyKey("event-1")
			bad.ops:add("Currency.Gems", 100001)
			check(not bad:saveDefinition().ok and f.count() == 1)
			c:destroy()
		end)
	end)
	test("Bulk filter limits include the whole tree and accept exact boundaries", function()
		local s = Scheduler.new()
		local c, f = client(s, { { body = s.json(schema()) } })
		s.run(function()
			check(c.fields:schemaCache():load().ok)
			local bulk = c.fields:bulkBuilder():reason("Reward event"):idempotencyKey("event-1")
			bulk.ops:add("Currency.Gems", 1)
			for _, leaf in
				{
					{ op = "EQ", field = "Enabled", value = false },
					{ op = "LT", field = "Label", value = "Player" },
					{ op = "IN", field = "Rarity", value = { "COMMON", "RARE" } },
					{ op = "GE", field = "Ratio", value = 0.5 },
				} :: { any }
			do
				bulk:target({ kind = "WHERE", where = leaf })
				check(bulk:build().ok)
			end
			local values: { number } = {}
			for i = 1, 100 do
				table.insert(values, i)
			end
			bulk:target({ kind = "WHERE", where = { op = "IN", field = "Currency.Gems", value = values } })
			check(bulk:build().ok)
			table.insert(values, 101)
			bulk:target({ kind = "WHERE", where = { op = "IN", field = "Currency.Gems", value = values } })
			check(not bulk:build().ok)
			local leaves: { any } = {}
			for _ = 1, 16 do
				table.insert(leaves, { op = "EQ", field = "Currency.Gems", value = 1 })
			end
			bulk:target({ kind = "WHERE", where = { op = "AND", clauses = leaves } })
			check(bulk:build().ok)
			table.insert(leaves, { op = "EQ", field = "Currency.Gems", value = 2 })
			bulk:target({ kind = "WHERE", where = { op = "AND", clauses = leaves } })
			check(not bulk:build().ok)
			local tree: any = { op = "EQ", field = "Currency.Gems", value = 1 }
			for _ = 1, 3 do
				tree = { op = "NOT", clause = tree }
			end
			bulk:target({ kind = "WHERE", where = tree })
			check(bulk:build().ok)
			bulk:target({ kind = "WHERE", where = { op = "NOT", clause = tree } })
			check(not bulk:build().ok and f.count() == 1)
			c:destroy()
		end)
	end)
	test("Schedules validate closed actions, UTC windows and restoration before transport", function()
		local s = Scheduler.new()
		local c, f = client(s, {})
		local schedules = c.fields:scheduleClient()
		local input = schedule()
		local built = schedules:build(input)
		check(built.ok)
		input.name = "Changed"
		check(built.ok and built.value.name == "Double gems")
		local invalid: { any } = {}
		local conflict: any = schedule()
		conflict.endActions = { { kind = "DISABLE_FLAG", key = "double_gems" } }
		table.insert(invalid, conflict)
		for _, action in
			{
				{ kind = "SET_CONFIG", key = "x", type = "INTEGER", value = 1 },
				{ kind = "SET_CONFIG", key = "x", type = "NUMBER", value = "1" },
				{ kind = "ENABLE_FLAG", key = "x", value = true },
				{ kind = "SET_DEFINITION_RUNTIME", key = "x" },
			} :: { any }
		do
			local bad: any = schedule()
			bad.startActions = { action }
			table.insert(invalid, bad)
		end
		local duplicates: any = schedule()
		duplicates.startActions =
			{ { kind = "ENABLE_FLAG", key = "x" }, { kind = "DISABLE_FLAG", key = "x" } }
		table.insert(invalid, duplicates)
		for _, start in { "2026-12-01T12:00:00-06:00", "2026-02-30T12:00:00Z", "2026-12-01T25:00:00Z" } do
			local bad: any = schedule()
			bad.start = start
			table.insert(invalid, bad)
		end
		local reversed: any = schedule()
		reversed["end"] = reversed.start
		table.insert(invalid, reversed)
		local stringUniverse: any = schedule()
		stringUniverse.universeId = "123"
		table.insert(invalid, stringUniverse)
		s.run(function()
			for _, bad in invalid do
				check(not schedules:create(bad).ok)
			end
			check(f.count() == 0)
			c:destroy()
		end)
	end)
	test("Jobs typed import rejects malformed records and sends exact NDJSON bytes and key", function()
		local s = Scheduler.new()
		local wireBody = ""
		local c, f = client(s, {
			{ body = s.json(schema()) },
			{
				body = s.json({ dryRun = true, valid = true, records = 2, errors = Json.array({}) }),
				check = function(request)
					check(request.Headers["Content-Type"] == "application/x-ndjson")
					check(
						request.Body == wireBody and string.find(request.Url, "dryRun=false", 1, true) == nil
					)
				end,
			},
			{
				body = s.json(receipt("QUEUED")),
				check = function(request)
					check(request.Body == wireBody and request.Headers["Idempotency-Key"] == "import-1")
					check(string.find(request.Url, "dryRun=false", 1, true) ~= nil)
				end,
			},
		})
		s.run(function()
			local jobs = c.fields:jobClient()
			local records = {
				{ subject = 7, field = "Currency.Gems", op = "ADD" :: "ADD", delta = 1 },
				{ subject = 8, field = "Currency.Gems", op = "ADD" :: "ADD", delta = 2 },
			}
			check(not jobs:buildImport(records).ok and f.count() == 0)
			check(c.fields:schemaCache():load().ok)
			for _, bad in
				{
					{ subject = 0, field = "Currency.Gems", op = "SET", value = 1 },
					{ subject = 7, field = "Currency.Gems", op = "ADD", delta = "1" },
					{ subject = 7, field = "Currency.Gems", op = "ADD", delta = 1, value = 1 },
					{ subject = 7, field = "Currency.Gems", op = "SET", value = 1, path = {} },
					{ subject = 7, field = "Shared", op = "SET", value = 1 },
					{ subject = 7, field = "Currency.Gems", op = "SET", value = 1, universeId = 124 },
					{ subject = 7, field = "Currency.Gems", op = "SET", value = 1, universeId = "123" },
				} :: { any }
			do
				check(not jobs:import({ bad } :: any, { reason = "Import repair" }).ok)
			end
			check(f.count() == 1)
			local built = jobs:buildImport(records)
			check(built.ok)
			if not built.ok then
				return
			end
			wireBody = built.value
			local lines = string.split(string.gsub(wireBody, "\n$", ""), "\n")
			check(#lines == 2 and System.equal(Decode.decode(lines[1]), records[1]))
			check(jobs:import(records, { reason = "Import repair" }).ok)
			check(
				not jobs:import(records, { reason = "Import repair", dryRun = false }).ok and f.count() == 2
			)
			check(
				jobs:import(
					records,
					{ reason = "Import repair", dryRun = false, idempotencyKey = "import-1" }
				).ok
			)
			check(f.count() == 3)
			c:destroy()
		end)
	end)
	test("Jobs export validates target and scalar scope without uploading invalid requests", function()
		local s = Scheduler.new()
		local c, f = client(s, { { body = s.json(schema()) } })
		s.run(function()
			check(c.fields:schemaCache():load().ok)
			local jobs = c.fields:jobClient()
			for _, fields in
				{ { "Shared" }, { "Total" }, { "Missing" }, { "Currency.Gems", "Currency.Gems" }, {} }
			do
				check(
					not jobs:export({ fields = fields, reason = "Export backup", idempotencyKey = "export-1" }).ok
				)
			end
			check(not jobs:export({
				target = { kind = "SUBJECTS", subjects = { 0 } },
				reason = "Export backup",
				idempotencyKey = "export-1",
			}).ok)
			check(
				not jobs:export(
					{ target = false, reason = "Export backup", idempotencyKey = "export-1" } :: any
				).ok
			)
			check(
				not jobs:export(
					{ universeId = "123", reason = "Export backup", idempotencyKey = "export-1" } :: any
				).ok
			)
			check(f.count() == 1)
			c:destroy()
		end)
	end)
	test("Jobs waitFor observes every terminal state and reports per-item failures", function()
		for _, state in { "SUCCEEDED", "FAILED", "CANCELLED" } do
			local s = Scheduler.new()
			local c, f =
				client(s, { { body = s.json(receipt("QUEUED")) }, { body = s.json(receipt(state)) } })
			local progress = 0
			s.run(function()
				local result = c.fields:jobClient():waitFor(JOB, {
					timeout = 2,
					onProgress = function(_job)
						progress += 1
					end,
				})
				check(result.ok and result.value.state == state)
				if state == "SUCCEEDED" then
					check(result.ok and result.value.failed == 1)
				end
				check(f.count() == 2 and progress == 2)
				c:destroy()
			end)
		end
	end)
	test("Jobs polling bypasses cache and uses bounded backoff rather than a busy loop", function()
		local s = Scheduler.new()
		local times: { number } = {}
		local steps: { Fake.Step } = {}
		for i = 1, 8 do
			table.insert(steps, {
				body = s.json(receipt(if i == 8 then "SUCCEEDED" else "RUNNING")),
				check = function(request)
					check(
						request.Method == "GET" and string.find(request.Url, "/jobs/" .. JOB, 1, true) ~= nil
					)
					table.insert(times, s.time())
				end,
			})
		end
		local c, f = client(s, steps)
		s.run(function()
			check(c.fields:jobClient():waitFor(JOB, { timeout = 30 }).ok)
			check(f.count() == 8)
			for i, expected in { 0.25, 0.5, 1, 2, 4, 5, 5 } do
				local elapsed = times[i + 1] - times[i]
				check(elapsed >= expected and elapsed < expected + 0.6, "Unbounded polling interval")
			end
			c:destroy()
		end)
	end)
	test("Jobs progress callback failure is local, redacted and stops only polling", function()
		local s = Scheduler.new()
		local c, f = client(s, { { body = s.json(receipt("RUNNING")) } })
		s.run(function()
			local result = c.fields:jobClient():waitFor(JOB, {
				onProgress = function(_job)
					error("sensitive-callback-detail")
				end,
			})
			check(not result.ok and result.error.kind == "Local")
			check(
				not result.ok and not string.find(result.error.message, "sensitive-callback-detail", 1, true)
			)
			check(f.count() == 1)
			c:destroy()
		end)
	end)
	test("Jobs timeout and local cancellation never cancel or retry the remote job", function()
		for _, mode in { "timeout", "signal", "destroy" } do
			local s = Scheduler.new()
			local c, f = client(s, { { body = s.json(receipt("RUNNING")) } })
			local signal: Core.Signal = { cancelled = false }
			local returned = 0
			s.run(function()
				if mode ~= "timeout" then
					s.runtime.delay(0.05, function()
						if mode == "signal" then
							signal.cancelled = true
						else
							c:destroy()
						end
					end)
				end
				local result = c.fields:jobClient():waitFor(JOB, { timeout = 0.1, signal = signal })
				returned = s.time()
				check(
					not result.ok
						and result.error.kind == (if mode == "timeout" then "Timeout" else "Cancelled")
				)
				check(f.count() == 0)
				c:destroy()
			end)
			check(returned < 0.2)
		end
		local s = Scheduler.new()
		local c, f = client(s, {})
		s.run(function()
			for _, timeout in { -1, 0, 3601, math.huge, 0 / 0 } do
				check(not c.fields:jobClient():waitFor(JOB, { timeout = timeout }).ok)
			end
			check(f.count() == 0)
			c:destroy()
		end)
	end)
	test("Health summary is READ while durable job controls require a server ADMIN key", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{
				body = s.json({
					openAlerts = { WARNING = 1, CRITICAL = 0 },
					runningJobs = 2,
					upcomingSchedules = 1,
				}),
				check = function(request)
					check(
						request.Url
							== "https://lb1.blox-api.com/fields-service/api/fields/universes/123/health/summary"
					)
				end,
			},
		}, "READ")
		s.run(function()
			local summary = c.fields:healthClient():summary()
			check(summary.ok and summary.value.runningJobs == 2 and summary.value.openAlerts.WARNING == 1)
			check(not c.fields:jobClient():get(JOB).ok)
			check(not c.fields:scheduleClient():get(JOB).ok)
			check(f.count() == 1)
			c:destroy()
		end)
	end)
	test("Bulk and schedule helpers use exact ADMIN routes and typed request bodies", function()
		local s = Scheduler.new()
		local steps: { Fake.Step } = { { body = s.json(schema()) } }
		--- Add a response while independently checking the method, universe and endpoint suffix.
		local function route(method: string, suffix: string, value: unknown)
			table.insert(steps, {
				body = s.json(value),
				check = function(request)
					check(request.Method == method)
					check(
						request.Url
							== "https://lb1.blox-api.com/fields-service/api/fields/universes/123"
								.. suffix
					)
					if request.Body then
						local body: any = Decode.decode(request.Body)
						check(body.reason == "Reviewed event")
					end
				end,
			})
		end
		route("POST", "/bulk/preview", {
			matchedCount = 2,
			validation = { valid = true, errors = Json.array({}) },
			samples = Json.array({}),
		})
		route("POST", "/bulk", receipt("QUEUED"))
		route("POST", "/bulk/definitions", { id = JOB })
		local input = schedule()
		input.reason = "Reviewed event"
		route("POST", "/schedules/preview", {
			start = input.start,
			startActions = input.startActions,
			endActions = Json.array({}),
			restorePrevious = true,
			requiresExistingConfigResources = true,
		})
		route("POST", "/schedules", receipt("QUEUED"))
		route("PUT", "/schedules/" .. JOB, receipt("QUEUED"))
		route("GET", "/schedules/" .. JOB, receipt("RUNNING"))
		route("GET", "/schedules/" .. JOB .. "/actions", Json.array({}))
		route("POST", "/schedules/" .. JOB .. "/cancel", receipt("CANCELLED"))
		route("POST", "/schedules/" .. JOB .. "/end-now", receipt("SUCCEEDED"))
		local c, f = client(s, steps)
		s.run(function()
			check(c.fields:schemaCache():load().ok)
			local bulk = c.fields
				:bulkBuilder()
				:target({ kind = "ALL" })
				:reason("Reviewed event")
				:idempotencyKey("event-1")
			bulk.ops:add("Currency.Gems", 1)
			check(bulk:preview().ok and bulk:submit().ok and bulk:saveDefinition().ok)
			local schedules = c.fields:scheduleClient()
			check(
				schedules:preview(input).ok and schedules:create(input).ok and schedules:edit(JOB, input).ok
			)
			check(schedules:get(JOB).ok and schedules:actions(JOB).ok)
			check(schedules:cancel(JOB, "Reviewed event").ok and schedules:endNow(JOB, "Reviewed event").ok)
			check(f.count() == 11)
			c:destroy()
		end)
	end)
	test("Jobs controls preserve scoped queries and raw downloads without hidden mutations", function()
		local s = Scheduler.new()
		local steps: { Fake.Step } = {}
		--- Record exact scoped routes; downloads intentionally are not valid JSON envelopes.
		local function route(method: string, suffix: string, body: string)
			table.insert(steps, {
				body = body,
				check = function(request)
					if string.find(suffix, "/download", 1, true) then
						check(request.Headers.Accept == "application/x-ndjson")
					end
					check(
						request.Method == method
							and request.Url
								== "https://lb1.blox-api.com/fields-service/api/fields/universes/123" .. suffix
					)
				end,
			})
		end
		route("GET", "/jobs?limit=3&offset=2", s.json(Json.array({})))
		route("GET", "/jobs/" .. JOB .. "/events?after=4", s.json(Json.array({})))
		route("GET", "/jobs/" .. JOB .. "/failures?after=-1&limit=5", s.json(Json.array({})))
		local download = '{"subject":7,"field":"Currency.Gems","op":"SET","value":1}\n'
		local failures = '{"line":7,"subject":7,"error":"above_max"}\n'
		route("GET", "/jobs/" .. JOB .. "/download", download)
		route("GET", "/jobs/" .. JOB .. "/failures/download", failures)
		route("POST", "/jobs/" .. JOB .. "/cancel", s.json(receipt("CANCELLED")))
		route("POST", "/jobs/" .. JOB .. "/retry", s.json(receipt("QUEUED")))
		route("GET", "/jobs/" .. JOB .. "/download", "")
		local c, f = client(s, steps)
		s.run(function()
			local jobs = c.fields:jobClient()
			check(jobs:list({ limit = 3, offset = 2 }).ok)
			check(jobs:events(JOB, 4).ok and jobs:failures(JOB, { after = -1, limit = 5 }).ok)
			local exported, failed = jobs:download(JOB), jobs:downloadFailures(JOB)
			check(exported.ok and exported.value == download and failed.ok and failed.value == failures)
			check(jobs:cancel(JOB, "Reviewed event").ok and jobs:retry(JOB, "Reviewed event").ok)
			local empty = jobs:download(JOB)
			check(empty.ok and empty.value == "")
			check(f.count() == 8)
			c:destroy()
		end)
	end)
	test("Job wait deadline bounds an in-flight poll without cancelling durable work", function()
		local s = Scheduler.new()
		local c, f = client(s, { { delay = 2, body = s.json(receipt("SUCCEEDED")) } })
		local returned = 0
		s.run(function()
			local result = c.fields:jobClient():waitFor(JOB, { timeout = 0.05 })
			returned = s.time()
			check(not result.ok and result.error.kind == "Timeout")
		end)
		check(returned < 0.1 and f.count() == 0)
		c:destroy()
	end)
	test(
		"Raw generated NDJSON import preserves retry bytes and rejects unsafe or missing apply keys",
		function()
			local s = Scheduler.new()
			local raw = '{"subject":7, "field":"Currency.Gems", "op":"ADD", "delta":1}\n'
			local attempts = 0
			--- Verify the transport never canonicalizes import identity bytes or generates an apply key.
			local function applied(request: Core.HttpRequest)
				attempts += 1
				check(request.Body == raw and request.Headers["Idempotency-Key"] == "raw-import-1")
				check(request.Headers["Content-Type"] == "application/x-ndjson")
				check(
					request.Url
						== "https://lb1.blox-api.com/fields-service/api/fields/universes/123/import?dryRun=false&reason=Import%20repair"
				)
			end
			local c, f = client(s, {
				{
					body = s.json({ dryRun = true, valid = true, records = 1, errors = Json.array({}) }),
					check = function(request)
						check(request.Body == raw and request.Headers["Idempotency-Key"] == nil)
						check(request.Headers["Content-Type"] == "application/x-ndjson")
					end,
				},
				{ status = 503, check = applied },
				{ body = s.json(receipt("QUEUED")), check = applied },
			}, "ADMIN", 1)
			s.run(function()
				check(
					not c.fields:import({ body = raw, query = { dryRun = false, reason = "Import repair" } }).ok
				)
				check(not c.fields:import({
					body = raw,
					query = { dryRun = false, reason = "Import repair" },
					idempotencyKey = "bad\r\nInjected: value",
				}).ok)
				check(f.count() == 0)
				check(c.fields:import({ body = raw, query = { reason = "Import repair" } }).ok)
				check(c.fields:import({
					body = raw,
					query = { dryRun = false, reason = "Import repair" },
					idempotencyKey = "raw-import-1",
				}).ok)
				check(f.count() == 3 and attempts == 2)
				c:destroy()
			end)
		end
	)
end
