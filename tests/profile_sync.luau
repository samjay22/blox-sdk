--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local Profile = require("../src/Fields/Profile")
local Scheduler = require("./Scheduler")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
local Fake = require("../src/Testing/FakeBackend")
local ChangeSignal = require("../src/Core/ChangeSignal")
type Poll = { at: number, body: Wire.BatchChangesInput }
type Harness = {
	client: SDK.Client,
	s: Scheduler.Scheduler,
	polls: { Poll },
	batches: { { string } },
	documents: { number },
	document: (number) -> Wire.Document,
	schema: () -> Wire.SchemaResponse,
	batch: (Wire.BatchChangesInput, number) -> Core.HttpResponse,
	docDelay: number,
	activeDocs: number,
	maxDocs: number,
	activePolls: number,
	maxPolls: number,
}
--- Fail regressions with a concise value-free label.
local function check(value: unknown, label: string?)
	assert(value, label or "ProfileSync regression")
end
--- Supply a minimal strict schema with two independent fields.
local function schema(): Wire.SchemaResponse
	local definitions: { Wire.Definition } = {}
	for _, id in { "Score", "Other" } do
		table.insert(definitions, {
			universeId = 123,
			id = id,
			description = "",
			scope = "PLAYER",
			status = "ACTIVE",
			type = { kind = "int" },
			default = 0,
			history = "LEDGER",
			writeLevel = "READ_WRITE",
			definitionVersion = 1,
			createdAt = "now",
			updatedAt = "now",
		})
	end
	return { universeId = 123, schemaVersion = 1, definitions = definitions }
end
--- Build a complete coherent snapshot.
local function document(user: number, seq: number?, value: number?, version: number?): Wire.Document
	return {
		userId = user,
		seq = seq or 0,
		data = { Score = value or 0, Other = 0 },
		versions = { Score = version or 0, Other = 0 },
	}
end
--- Construct a complete batch item, including empty arrays on the wire.
local function item(
	user: number,
	seq: number,
	entries: { Wire.Entry }?,
	more: boolean?,
	snapshot: boolean?
): Wire.PlayerChangesItem
	return {
		userId = user,
		entries = Json.array(entries or {}),
		latestSeq = seq,
		nextSinceSeq = seq,
		hasMore = more or false,
		needsSnapshot = snapshot or false,
	}
end
--- Construct a full-field ledger snapshot, not an arithmetic delta.
local function entry(user: number, seq: number, version: number, value: number, field: string?): Wire.Entry
	return {
		subject = user,
		universeId = 123,
		seq = seq,
		versionAfter = version,
		ordinal = 0,
		field = field or "Score",
		op = "SET",
		path = Json.array({}),
		before = 0,
		after = value,
		beforeExists = true,
		afterExists = true,
		beforeSize = 1,
		afterSize = 1,
		kind = "TRANSACTION",
	}
end
--- Encode a response with the portable real JSON codec.
local function response(value: unknown, status: number?, headers: { [string]: string }?): Core.HttpResponse
	return { StatusCode = status or 200, Body = Json.encode(value), Headers = headers or {} }
end
--- Route a deterministic in-memory mock transport while recording budget and overlap behavior.
local function harness(options: SDK.Config?): Harness
	local s = Scheduler.new()
	local h: Harness = {} :: any
	h.s = s
	h.polls = {}
	h.batches = {}
	h.documents = {}
	h.docDelay = 0
	h.activeDocs = 0
	h.maxDocs = 0
	h.activePolls = 0
	h.maxPolls = 0
	h.schema = schema
	h.document = function(user)
		return document(user)
	end
	h.batch = function(body)
		local items: { Wire.PlayerChangesItem } = {}
		for _, player in body.players do
			table.insert(items, item(player.userId, player.sinceSeq))
		end
		return response({ items = items, pollAfterMs = 15000 })
	end
	local config: SDK.Config = options or {}
	config.runtime = s.runtime
	local batchBackend = Fake.batch(s.runtime, function(request)
		if string.find(request.Url, "/changes/batch", 1, true) then
			local body = Decode.decode(request.Body :: string) :: Wire.BatchChangesInput
			table.insert(h.polls, { at = s.time(), body = body })
			h.activePolls += 1
			h.maxPolls = math.max(h.maxPolls, h.activePolls)
			local result = h.batch(body, #h.polls)
			h.activePolls -= 1
			return result
		elseif string.find(request.Url, "/health", 1, true) then
			return response({ status = "UP" })
		elseif string.find(request.Url, "/schema", 1, true) then
			return response(h.schema())
		elseif request.Method == "POST" and string.find(request.Url, "/transaction", 1, true) then
			return response({
				txId = "tx",
				replayed = false,
				seq = { ["7"] = 999 },
				results = {
					{
						subject = 7,
						field = "Score",
						path = Json.array({}),
						op = "SET",
						before = 0,
						after = 10,
						version = 1,
						entryId = Json.null,
					},
				},
			})
		end
		local user = tonumber(string.match(request.Url, "/players/(%d+)"))
		check(user ~= nil, "Unexpected mock route")
		table.insert(h.documents, s.time())
		h.activeDocs += 1
		h.maxDocs = math.max(h.maxDocs, h.activeDocs)
		if h.docDelay > 0 then
			s.runtime.wait(h.docDelay)
		end
		local result = response(h.document(user :: number))
		h.activeDocs -= 1
		return result
	end)
	config.backend = function(request)
		local batch = Decode.decode(request.Body :: string) :: any
		local paths: { string } = {}
		for _, op in batch.ops do
			table.insert(paths, op.path)
		end
		table.insert(h.batches, paths)
		return batchBackend(request)
	end
	config.burst = config.burst or 499
	config.requestsPerMinute = config.requestsPerMinute or 499
	config.criticalReserve = 0
	config.key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
	config.universeId = 123
	h.client = SDK.new(config)
	return h
end
--- Load a profile or fail the test at its setup boundary.
local function load(h: Harness, user: number): Profile.Profile
	local result = h.client.fields:loadProfile(123, user)
	check(result.ok, "Profile load failed")
	return (result :: any).value
end
--- Register deterministic background-sync regressions, using only mock HTTP and virtual time.
return function(test: (string, () -> ()) -> ())
	test("ProfileSync validates the shared batch contract before transport", function()
		local s = Scheduler.new()
		local fake =
			Fake.new(s.runtime, { { body = s.json({ items = { item(7, 0) }, pollAfterMs = 15000 }) } })
		local c = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
			universeId = 123,
		})
		s.run(function()
			for _, body in
				{
					{ players = {} },
					{ players = { { userId = 0, sinceSeq = 0 } } },
					{ players = { { userId = 7, sinceSeq = -1 } } },
					{ players = { { userId = 7, sinceSeq = 0.1 } } },
					{ players = { { userId = 7, sinceSeq = 0 }, { userId = 7, sinceSeq = 1 } } },
					{ players = { { userId = 7, sinceSeq = 0 } }, maxEntries = 1001 },
					{ players = { { userId = 7, sinceSeq = 0 } }, maxEntries = 0 },
				}
			do
				local result = c.fields:changesBatch({ path = { universeId = 123 }, body = body } :: any)
				check(not result.ok and result.error.kind == "Validation")
			end
			check(fake.count() == 0)
			check(c.fields:changesBatch({
				path = { universeId = 123 },
				body = { players = { { userId = 7, sinceSeq = 0 } } },
			}).ok)
			check(fake.count() == 1)
			c:destroy()
		end)
	end)

	test("ProfileSync piggybacks every tick, deduplicates handles and restarts after idle", function()
		local h = harness({ profileSync = { enabled = false } })
		h.s.run(function()
			local a, b = load(h, 7), load(h, 7)
			a.seq = 10
			h.client._helpers.sync._enabled = true
			assert(h.client._helpers.sync.wake, "Missing batch wake")()
			h.s.runtime.spawn(function()
				check(h.client.fields:healthProxy().ok)
			end)
			h.s.runtime.wait(1.1)
			check(#h.polls == 2 and #h.polls[1].body.players == 1)
			check(h.polls[1].body.players[1].sinceSeq == 0)
			local combined = false
			for _, paths in h.batches do
				if
					table.find(paths, "/health")
					and table.find(paths, "/api/fields/universes/123/players/changes/batch")
				then
					combined = true
				end
			end
			check(combined, "Sync did not piggyback gameplay envelope")
			a:destroy()
			b:destroy()
			h.s.runtime.wait(1)
			check(#h.polls == 2)
			load(h, 8)
			h.s.runtime.wait(0.6)
			check(#h.polls == 3 and h.polls[3].body.players[1].userId == 8)
			h.client._helpers.sync:removePlayer(8)
			check(next(h.client._helpers.sync._profiles) == nil)
			h.client:destroy()
		end)
	end)

	test("ProfileSync chunks 201 players into two piggyback operations and shares facade registry", function()
		local h = harness({ profileSync = { enabled = false } })
		h.s.run(function()
			for user = 1, 201 do
				load(h, user)
			end
			local scoped = h.client:withUniverse(123)
			check(scoped.fields:loadProfile(123, 1).ok and scoped.ProfileChanged == h.client.ProfileChanged)
			h.client._helpers.sync._enabled = true
			assert(h.client._helpers.sync.wake, "Missing batch wake")()
			h.s.runtime.wait(0.6)
			check(#h.polls == 2 and #h.polls[1].body.players == 200 and #h.polls[2].body.players == 1)
			check(h.polls[1].body.players[200].userId == 200 and h.polls[2].body.players[1].userId == 201)
			check(h.polls[1].at == h.polls[2].at)
			h.client:destroy()
		end)
	end)

	test(
		"ProfileSync safe watermarks, duplicate versions and local/external signals remain unchanged",
		function()
			local h = harness({ profileSync = { enabled = false } })
			local changes: { ChangeSignal.Change } = {}
			h.batch = function(body, count)
				check(body.players[1].sinceSeq == (if count == 1 then 0 else 42))
				local entries = if count == 1
					then { entry(7, 41, 1, 10), entry(7, 42, 2, 20) }
					else { entry(7, 43, 1, 5), entry(7, 44, 3, 30) }
				return response({
					items = { item(7, if count == 1 then 42 else 44, entries) },
					pollAfterMs = 15000,
				})
			end
			h.s.run(function()
				local p = load(h, 7)
				p.Changed:connect(function(change)
					table.insert(changes, change)
				end)
				check(p:transaction():set("Score", 10):reason("test"):commit().ok and p.seq == 0)
				h.client._helpers.sync._enabled = true
				assert(h.client._helpers.sync.wake, "Missing batch wake")()
				h.s.runtime.wait(1.1)
				check(p.seq == 44 and p:get("Score") == 30 and p.versions.Score == 3)
				check(#changes == 3 and changes[1].source == "local" and changes[3].source == "external")
				check(table.isfrozen(changes[3]) and table.isfrozen(changes[3].values))
				h.client:destroy()
			end)
		end
	)

	test("ProfileSync staggered recovery remains deduplicated and bounded behind BatchService", function()
		local h = harness({ profileSync = { enabled = false, maxConcurrentReloads = 2 } })
		h.batch = function(body)
			local items = {}
			for _, player in body.players do
				table.insert(items, item(player.userId, 10, nil, false, player.sinceSeq < 10))
			end
			return response({ items = items, pollAfterMs = 5000 })
		end
		h.s.run(function()
			local profiles = {}
			for user = 1, 5 do
				table.insert(profiles, load(h, user))
			end
			h.document = function(user)
				return document(user, 10, 99, 3)
			end
			h.client._helpers.sync._enabled = true
			assert(h.client._helpers.sync.wake, "Missing batch wake")()
			h.s.runtime.wait(5)
			for _, p in profiles do
				check(p.seq == 10 and p:get("Score") == 99)
			end
			check(#h.documents == 10 and next(h.client._helpers.sync._reloads) == nil)
			h.client:destroy()
		end)
	end)

	test("ProfileSync per-op Retry-After defers new polls without direct requests", function()
		local h = harness()
		h.batch = function(body, count)
			if count == 1 then
				return response({}, 429, { ["Retry-After"] = "10" })
			end
			return response({ items = { item(body.players[1].userId, 0) }, pollAfterMs = 5000 })
		end
		h.s.run(function()
			load(h, 7)
			h.s.runtime.wait(10)
			check(#h.polls == 1)
			h.s.runtime.wait(1.1)
			check(#h.polls == 2 and h.polls[2].at - h.polls[1].at >= 10)
			h.client:destroy()
		end)
	end)

	test("ProfileSync disabled clients remain idle and flush removes registry and timers", function()
		local h = harness({ profileSync = { enabled = false } })
		h.s.run(function()
			load(h, 7)
			h.s.runtime.wait(2)
			check(#h.polls == 0)
			check(h.client:flush(1))
			h.client:destroy()
			check(next(h.client._helpers.sync._profiles) == nil)
		end)
	end)

	test("ProfileSync hash-only/migration/NONE recovery fences old snapshots below safe cursor", function()
		for _, kind in { "hash", "migration", "NONE", "deleted", "retention" } do
			local h = harness({ profileSync = { enabled = false } })
			h.s.run(function()
				local p = load(h, 7)
				local e = entry(7, 10, 1, 20)
				local page = item(7, 10, { e }, false, kind == "NONE" or kind == "retention")
				if kind == "hash" then
					e.afterSize = 20000
					e.afterHash = "hash"
					e.after = Json.null
				end
				if kind == "migration" then
					e.refType = "migration"
				end
				if kind == "deleted" then
					e.afterExists = false
				end
				check(not p:applyChanges(page, 0) and p.seq == 0)
				check(p._snapshotFloor == 10 and p._stale)
				local old = p:refresh()
				check(not old.ok and old.error.code == "snapshot_race" and p._stale)
				h.document = function(user)
					return document(user, 10, 20, 1)
				end
				check(p:refresh().ok and p.seq == 10 and p:get("Score") == 20)
				h.client:destroy()
			end)
		end
	end)

	test(
		"ProfileSync applies ordinal subvalues atomically, skips duplicate versions and recovers gaps",
		function()
			local h = harness({ profileSync = { enabled = false } })
			h.schema = function()
				local value = schema()
				value.definitions[1].type = {
					kind = "object",
					members = { a = { type = { kind = "int" } }, b = { type = { kind = "int" } } },
				}
				value.definitions[1].default = { a = 0, b = 0 }
				return value
			end
			h.document = function(user)
				local value = document(user);
				(value.data :: any).Score = { a = 0, b = 0 }
				return value
			end
			h.s.run(function()
				local p = load(h, 7)
				local count = 0
				p.Changed:connect(function(change)
					check((change.values.Score :: any).a == 1 and (change.values.Score :: any).b == 2)
					count += 1
				end)
				local a, b = entry(7, 10, 1, 1), entry(7, 10, 1, 2)
				a.path = { "a" }
				b.path = { "b" }
				b.ordinal = 1
				local page = item(7, 10, { b, a })
				check(p:applyChanges(page, 0) and p.seq == 10)
				check(p:applyChanges(page, 0) and p.versions.Score == 1)
				h.s.runtime.wait(0.01)
				check(count == 1)
				local gap = entry(7, 20, 3, 5)
				gap.path = { "a" }
				check(not p:applyChanges(item(7, 20, { gap }), 10) and p.seq == 10)
				check(p.versions.Score == 1 and (p._data.Score :: any).a == 1)
				h.client:destroy()
			end)
		end
	)

	test("ProfileSync migration reload refreshes schema before validating replacement snapshots", function()
		local h = harness({ profileSync = { enabled = true } })
		h.batch = function(body)
			return response({
				items = { item(7, 10, nil, false, body.players[1].sinceSeq < 10) },
				pollAfterMs = 5000,
			})
		end
		h.s.run(function()
			local p = load(h, 7)
			h.schema = function()
				local value = schema()
				value.schemaVersion = 2
				value.definitions[1].type = { kind = "string" }
				value.definitions[1].default = ""
				return value
			end
			h.document = function(user)
				local value = document(user, 10, 0, 1);
				(value.data :: any).Score = "migrated"
				return value
			end
			h.s.runtime.wait(6)
			check(p:get("Score") == "migrated" and p._schemaVersion == 2 and p.seq == 10)
			h.client:destroy()
		end)
	end)

	test("ProfileSync shutdown during wire completion ignores late entries and starts no recovery", function()
		local h = harness({ profileSync = { enabled = true } })
		h.batch = function()
			h.s.runtime.wait(1)
			return response({ items = { item(7, 10, { entry(7, 10, 1, 20) }) }, pollAfterMs = 5000 })
		end
		h.s.run(function()
			local p = load(h, 7)
			h.s.runtime.wait(0.6)
			check(h.activePolls == 1)
			h.client:destroy()
			h.s.runtime.wait(10)
			check(p.seq == 0 and #h.polls == 1 and #h.documents == 1 and h.activePolls == 0)
		end)
	end)
	test(
		"ProfileSync player leave during load cancels admission without retaining a departed handle",
		function()
			local h = harness()
			h.docDelay = 1
			h.s.run(function()
				local result: Core.Result<Profile.Profile>? = nil
				h.s.runtime.spawn(function()
					result = h.client.fields:loadProfile(123, 7)
				end)
				h.s.runtime.wait(0.1)
				h.client._helpers.sync:removePlayer(7)
				h.s.runtime.wait(1.1)
				check(result ~= nil and not (result :: Core.Result<Profile.Profile>).ok)
				check(
					next(h.client._helpers.sync._profiles) == nil
						and next(h.client._helpers.sync._loads) == nil
				)
				h.s.runtime.wait(16)
				check(#h.polls == 0)
				h.client:destroy()
			end)
		end
	)
end
