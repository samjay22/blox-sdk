--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local Profile = require("../src/Fields/Profile")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
local Bucket = require("../src/Core/TokenBucket")
type Call = { at: number, body: any }
type Stored = { value: number, version: number, seq: number }
type Harness = {
	s: Scheduler.Scheduler,
	client: SDK.Client,
	acquires: { Call },
	commits: { Call },
	renews: { Call },
	releases: { Call },
	requests: { number },
	data: { [number]: Stored },
	acquire: ((any) -> Core.HttpResponse)?,
	commit: ((any) -> Core.HttpResponse)?,
	commitDelay: number,
	reads: number,
}
--- Fail offline races with a stable, value-free label.
local function check(value: unknown, label: string?)
	assert(value, label or "Sessions regression")
end
--- Encode a minimal response without retaining credentials.
local function reply(value: unknown, status: number?): Core.HttpResponse
	return { StatusCode = status or 200, Headers = {}, Body = Json.encode(value) }
end
--- Format virtual-clock expirations relative to the deterministic scheduler epoch.
local function expires(at: number): string
	local seconds = 13 * 60 + 20 + math.floor(at)
	return string.format(
		"2023-11-14T%02d:%02d:%02dZ",
		22 + math.floor(seconds / 3600),
		math.floor(seconds / 60) % 60,
		seconds % 60
	)
end
--- Return a strict active numeric field used by both optimistic and immediate operations.
local function schema(): Wire.SchemaResponse
	return {
		universeId = 123,
		schemaVersion = 1,
		definitions = {
			{
				universeId = 123,
				id = "Score",
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
			},
		},
	}
end
--- Route real BatchService envelopes to an in-memory lease/commit service with fault injection.
local function harness(config: SDK.Config?): Harness
	local h: Harness = {
		s = Scheduler.new(),
		client = nil :: any,
		acquires = {},
		commits = {},
		renews = {},
		releases = {},
		requests = {},
		data = {},
		commitDelay = 0,
		reads = 0,
	}
	local options: SDK.Config = config or {}
	options.runtime = h.s.runtime
	options.universeId = 123
	options.key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
	options.sessions = options.sessions
		or { serverId = "job", kickOnFailure = false, kickOnLeaseLost = false }
	options.profileSync = options.profileSync or { enabled = false }
	local service = Fake.batch(h.s.runtime, function(request)
		local body: any = if request.Body then Decode.decode(request.Body) else nil
		if string.find(request.Url, "/schema", 1, true) then
			return reply(schema())
		end
		if string.find(request.Url, "/sessions/acquire", 1, true) then
			table.insert(h.acquires, { at = h.s.time(), body = body })
			if h.acquire then
				return h.acquire(body)
			end
			local items: { any } = {}
			for _, player in body.players do
				h.data[player.userId] = h.data[player.userId] or { value = 0, version = 0, seq = 0 }
				local data = h.data[player.userId]
				table.insert(items, {
					userId = player.userId,
					status = "granted",
					epoch = 7,
					expiresAt = expires(h.s.time() + body.ttlMs / 1000),
					snapshot = {
						seq = data.seq,
						fields = { Score = data.value },
						versions = { Score = data.version },
					},
				})
			end
			return reply({ items = items })
		elseif string.find(request.Url, "/commits", 1, true) then
			table.insert(h.commits, { at = h.s.time(), body = body })
			if h.commitDelay > 0 then
				h.s.runtime.wait(h.commitDelay)
			end
			if h.commit then
				return h.commit(body)
			end
			local items: { any } = {}
			for _, player in body.players do
				local data = h.data[player.userId]
				for _, op in player.ops do
					data.value = if op.op == "ADD" then data.value + op.delta else op.value
				end
				data.seq += 1
				data.version += 1
				table.insert(items, {
					userId = player.userId,
					status = "committed",
					seq = data.seq,
					versions = { Score = data.version },
					expiresAt = expires(h.s.time() + 60),
				})
			end
			return reply({ commitId = body.commitId, items = items })
		elseif string.find(request.Url, "/sessions/renew", 1, true) then
			table.insert(h.renews, { at = h.s.time(), body = body })
			local items: { any } = {}
			for _, lease in body.leases do
				table.insert(items, {
					userId = lease.userId,
					status = "renewed",
					expiresAt = expires(h.s.time() + body.ttlMs / 1000),
				})
			end
			return reply({ items = items })
		elseif string.find(request.Url, "/sessions/release", 1, true) then
			table.insert(h.releases, { at = h.s.time(), body = body })
			local items: { any } = {}
			for _, lease in body.leases do
				table.insert(items, { userId = lease.userId, status = "released" })
			end
			return reply({ items = items })
		elseif string.find(request.Url, "/changes/batch", 1, true) then
			local items: { any } = {}
			for _, player in body.players do
				table.insert(items, {
					userId = player.userId,
					entries = Json.array({}),
					latestSeq = player.sinceSeq,
					nextSinceSeq = player.sinceSeq,
					hasMore = false,
					needsSnapshot = false,
				})
			end
			return reply({ items = items, pollAfterMs = 5000 })
		elseif string.find(request.Url, "/transactions", 1, true) then
			return reply({
				txId = "critical",
				replayed = false,
				seq = { ["7"] = 1 },
				results = {
					{
						subject = 7,
						field = "Score",
						op = "SET",
						path = Json.array({}),
						before = 0,
						after = 99,
						version = 1,
						entryId = Json.null,
					},
				},
			})
		end
		local user = tonumber(string.match(request.Url, "/players/(%d+)/document"))
		check(user, "Unexpected session mock route")
		h.reads += 1
		local data = h.data[user :: number]
		return reply({
			userId = user,
			seq = data.seq,
			data = { Score = data.value },
			versions = { Score = data.version },
		})
	end)
	options.backend = function(request)
		table.insert(h.requests, h.s.time())
		return service(request)
	end
	h.client = SDK.new(options)
	return h
end
--- Load the leased handle or fail the test setup explicitly.
local function load(h: Harness, user: number): Profile.Profile
	local result = h.client.fields:loadProfile(123, user)
	check(result.ok, "Acquire failed")
	return (result :: any).value
end
--- Register deterministic lease, buffering, retry and shutdown regressions under both Luau runtimes.
return function(test: (string, () -> ()) -> ())
	test(
		"Sessions batch acquire per tick, load granted snapshots and deduplicate concurrent handles",
		function()
			local h = harness()
			h.s.run(function()
				local profiles: { Profile.Profile } = {}
				for user = 1, 70 do
					h.s.runtime.spawn(function()
						profiles[user] = load(h, user)
					end)
				end
				h.s.runtime.wait(1.2)
				check(
					#profiles == 70
						and #h.acquires == 1
						and #h.acquires[1].body.players == 70
						and h.reads == 0
				)
				check(load(h, 1) == profiles[1] and profiles[1]:get("Score") == 0)
				check(profiles[1]._leaseReady and profiles[1].seq == 0)
				h.client:destroy()
			end)
		end
	)
	test("Sessions held backoff steals only after fifteen seconds and never becomes ready early", function()
		local h = harness()
		h.acquire = function(body)
			check(body.players[1].steal == (h.s.time() - h.acquires[1].at >= 15))
			return reply({
				items = {
					{
						userId = 7,
						status = "held",
						owner = "other",
						expiresAt = expires(100),
						retryAfterMs = 5000,
					},
				},
			})
		end
		h.s.run(function()
			local done = false
			h.s.runtime.spawn(function()
				local result = h.client.fields:loadProfile(123, 7)
				check(not result.ok and result.error.code == "session_acquire_timeout")
				done = true
			end)
			h.s.runtime.wait(61)
			check(done and #h.acquires >= 4 and #h.acquires <= 13)
			check(not h.acquires[1].body.players[1].steal and h.acquires[4].body.players[1].steal)
			h.client:destroy()
		end)
	end)
	test(
		"Sessions optimistic operations coalesce without HTTP and flush all dirty players at five seconds",
		function()
			local h = harness()
			h.s.run(function()
				local a, b = load(h, 7), load(h, 8)
				local requests = #h.requests
				check(a:add("Score", 2).ok and a:add("Score", 3).ok and a:get("Score") == 5)
				check(b:set("Score", 9).ok and #h.requests == requests and #a._buffer == 1)
				h.s.runtime.wait(2)
				check(#h.commits == 0)
				h.s.runtime.wait(2)
				check(#h.commits == 1 and #h.commits[1].body.players == 2)
				check(
					h.commits[1].body.serverId == "job"
						and string.match(h.commits[1].body.commitId, "^job:%d+$")
				)
				check(h.data[7].value == 5 and h.data[8].value == 9)
				h.client:destroy()
			end)
		end
	)
	test(
		"Sessions ambiguous retries retain commitId and exact body while later mutations remain buffered",
		function()
			local h = harness()
			h.commitDelay = 1
			local original: string? = nil
			h.commit = function(body)
				if not original then
					original = Json.encode(body)
				end
				check(Json.encode(body) == original, "Retry changed detached commit")
				if #h.commits == 1 then
					return reply({}, 503)
				end
				h.data[7] = { value = 5, seq = 1, version = 1 }
				return reply({
					commitId = body.commitId,
					items = {
						{
							userId = 7,
							status = "committed",
							seq = 1,
							versions = { Score = 1 },
							expiresAt = expires(100),
						},
					},
				})
			end
			h.s.run(function()
				local p = load(h, 7)
				check(p:add("Score", 5).ok)
				h.s.runtime.wait(4.1)
				check(p:add("Score", 2).ok and p:get("Score") == 7 and #p._buffer == 1)
				h.s.runtime.wait(3)
				check(p:add("Score", 1).ok, "Post-ack snapshot barrier blocked optimistic writes")
				h.s.runtime.wait(0.6)
				check(#h.commits == 2 and p:get("Score") == 8 and #p._buffer == 1 and p.versions.Score == 1)
				check(h.commits[2].at >= h.commits[1].at + 1)
				h.client:destroy()
			end)
		end
	)
	test("Sessions external versions rebase pending local deltas without double-applying own feed", function()
		local h = harness()
		h.s.run(function()
			local p = load(h, 7)
			check(p:add("Score", 5).ok)
			check(
				p:apply(
					{ results = { { subject = 7, field = "Score", after = 10, version = 1 } } } :: any,
					"external"
				)
			)
			check(p:get("Score") == 15 and p.versions.Score == 1)
			p._sent = p._buffer
			p._buffer = {}
			check(p:applyChanges({ userId = 7, latestSeq = 1, nextSinceSeq = 1, entries = {} } :: any, 0))
			check(p.seq == 0 and p:get("Score") == 15)
			h.client:destroy()
		end)
	end)
	test(
		"Sessions rejected detached ops fire CommitRejected and resync while preserving later writes",
		function()
			local h = harness()
			h.commitDelay = 1
			h.commit = function(body)
				return reply({
					commitId = body.commitId,
					items = {
						{
							userId = 7,
							status = "rejected",
							error = { code = "field_archived", field = "Score" },
						},
					},
				})
			end
			h.s.run(function()
				local p = load(h, 7)
				local rejected = 0
				h.client.CommitRejected:connect(function(event)
					check(event.userId == 7 and event.code == "field_archived")
					rejected += 1
				end)
				check(p:add("Score", 5).ok)
				h.s.runtime.wait(4.1)
				check(p:add("Score", 2).ok)
				h.s.runtime.wait(2)
				check(
					rejected == 1
						and #p._sent == 0
						and #p._buffer == 1
						and p:get("Score") == 2
						and h.reads == 1
				)
				h.client:destroy()
			end)
		end
	)
	test("Sessions lease_lost discards all buffers, emits once and uses configurable kick", function()
		local h = harness({ sessions = { serverId = "job", kickOnLeaseLost = true } })
		h.commit = function(body)
			return reply({ commitId = body.commitId, items = { { userId = 7, status = "lease_lost" } } })
		end
		local kicked = 0
		h.client._helpers.sessions._kick = function(user, _message)
			check(user == 7)
			kicked += 1
		end
		h.s.run(function()
			local p = load(h, 7)
			local lost = 0
			h.client.LeaseLost:connect(function(event)
				check(event.code == "lease_lost")
				lost += 1
			end)
			check(p:add("Score", 1).ok)
			h.s.runtime.wait(4.5)
			check(
				kicked == 1 and lost == 1 and #p._buffer == 0 and #p._sent == 0 and not p:add("Score", 2).ok
			)
			h.client:destroy()
		end)
	end)
	test("Sessions renew idle leases before expiry and dirty leases flush in the renewal window", function()
		local h = harness()
		h.s.run(function()
			local p = load(h, 7)
			h.s.runtime.wait(38)
			check(#h.renews == 0)
			check(p:add("Score", 3).ok)
			h.s.runtime.wait(3.6)
			check(#h.commits >= 1)
			h.s.runtime.wait(42)
			check(#h.renews >= 1 and h.renews[1].body.leases[1].epoch == 7)
			h.client:destroy()
		end)
	end)
	test("Sessions removal flushes during in-flight writes then releases with the acquired epoch", function()
		local h = harness()
		h.commitDelay = 1
		h.s.run(function()
			local p = load(h, 7)
			check(p:add("Score", 5).ok)
			h.s.runtime.wait(4.1)
			check(p:add("Score", 2).ok)
			h.client._helpers.sessions:removePlayer(7)
			check(not p:add("Score", 1).ok)
			h.s.runtime.wait(5)
			check(#h.commits == 2 and #h.releases == 1 and h.data[7].value == 7)
			check(
				h.releases[1].at > h.commits[2].at and h.releases[1].body.leases[1].epoch == 7 and p._closed
			)
			h.client:destroy()
		end)
	end)
	test("Sessions shutdown drains all players before releasing and cancelling the shared clock", function()
		local h = harness()
		h.s.run(function()
			local a, b = load(h, 7), load(h, 8)
			check(a:add("Score", 1).ok and b:add("Score", 2).ok)
			check(h.client:flush(5))
			check(#h.commits == 1 and #h.releases == 1 and #h.releases[1].body.leases == 2)
			check(a._closed and b._closed)
			h.client:destroy()
		end)
		check(h.s.pending() == 0)
	end)
	test(
		"Sessions malformed commit identities cannot discard buffered operations or release early",
		function()
			local h = harness()
			h.commit = function(_body)
				return reply({ commitId = "wrong", items = {} })
			end
			h.s.run(function()
				local p = load(h, 7)
				check(p:add("Score", 1).ok)
				check(not h.client:flush(2))
				check(#h.releases == 0 and #p._sent == 1)
				h.client:destroy()
			end)
		end
	)
	test(
		"Sessions critical immediate transactions still synchronously use the existing transaction API",
		function()
			local h = harness()
			h.s.run(function()
				local p = load(h, 7)
				check(p:immediate():set("Score", 99):reason("critical purchase"):commit().ok)
				check(p:get("Score") == 99 and #h.commits == 0 and #p._buffer == 0)
				h.client:destroy()
			end)
		end
	)
	test("Sessions late grants after player departure are released without publishing a handle", function()
		local h = harness()
		h.acquire = function(_body)
			h.s.runtime.wait(1.5)
			return reply({
				items = {
					{
						userId = 7,
						status = "granted",
						epoch = 7,
						expiresAt = expires(100),
						snapshot = { seq = 0, fields = { Score = 0 }, versions = { Score = 0 } },
					},
				},
			})
		end
		h.s.run(function()
			local result: Core.Result<Profile.Profile>? = nil
			h.s.runtime.spawn(function()
				result = h.client.fields:loadProfile(123, 7)
			end)
			h.s.runtime.wait(1.1)
			h.client._helpers.sync:cancelLoads(7)
			h.client._helpers.sessions:removePlayer(7)
			h.s.runtime.wait(3)
			check(result ~= nil and not (result :: Core.Result<Profile.Profile>).ok)
			check(#h.releases == 1 and next(assert(h.client._helpers.fields).profiles) == nil)
			h.client:destroy()
		end)
	end)
	test(
		"Sessions timeout retains the physical commit slot and cannot release before confirmation",
		function()
			local h = harness({ timeout = 0.75 })
			h.commitDelay = 3
			h.s.run(function()
				local p = load(h, 7)
				check(p:add("Score", 1).ok)
				check(not h.client:flush(1))
				h.s.runtime.wait(1)
				check(#h.commits == 1 and #h.releases == 0 and h.client._helpers.sessions._busy)
				h.client:destroy()
			end)
		end
	)
	test(
		"Sessions explicit profile release drains dirty state and returns only after fenced release",
		function()
			local h = harness()
			h.s.run(function()
				local p = load(h, 7)
				check(p:add("Score", 2).ok and p:release())
				check(h.data[7].value == 2 and #h.releases == 1 and p._closed)
				h.client:destroy()
			end)
		end
	)
	test("Sessions controls chunk 201 concurrent acquisitions without duplicate players", function()
		local h = harness()
		h.s.run(function()
			local loaded = 0
			for user = 1, 201 do
				h.s.runtime.spawn(function()
					load(h, user)
					loaded += 1
				end)
			end
			h.s.runtime.wait(1.3)
			check(loaded == 201 and #h.acquires == 2)
			check(#h.acquires[1].body.players <= 200 and #h.acquires[2].body.players <= 200)
			check(h.client:flush(5) and #h.releases == 2)
			h.client:destroy()
		end)
	end)
	test(
		"Sessions buffering validates atomically and does not coalesce deltas beyond schema maxDelta",
		function()
			local h = harness()
			h.s.run(function()
				local p = load(h, 7)
				check(not p:mutate({
					{ field = "Score", op = "ADD", delta = 2 },
					{ field = "Missing", op = "ADD", delta = 1 },
				}).ok)
				check(p:get("Score") == 0 and #p._buffer == 0)
				-- Use a separately compiled schema generation instead of mutating immutable definitions.
				local maxSchema = schema();
				(maxSchema.definitions[1].type :: any).maxDelta = 5
				local original = p._schema._fetch
				p._schema._fetch = function()
					return { ok = true, value = maxSchema }
				end
				maxSchema.schemaVersion = 2
				check(p._schema:refresh().ok)
				p._schema._fetch = original
				check(p:refresh().ok)
				check(p:add("Score", 4).ok)
				check(p:add("Score", 4).ok)
				check(#p._buffer == 2 and p:get("Score") == 8)
				h.client:destroy()
			end)
		end
	)
	test("Sessions default lease-loss kick can be disabled without suppressing the event", function()
		local h = harness()
		h.commit = function(body)
			return reply({ commitId = body.commitId, items = { { userId = 7, status = "lease_lost" } } })
		end
		local kicks = 0
		h.client._helpers.sessions._kick = function(_user, _message)
			kicks += 1
		end
		h.s.run(function()
			local p = load(h, 7)
			local lost = 0
			h.client.LeaseLost:connect(function(_event)
				lost += 1
			end)
			check(p:add("Score", 1).ok)
			h.s.runtime.wait(4.5)
			check(kicks == 0 and lost == 1 and p._closed)
			h.client:destroy()
		end)
	end)
	test(
		"Sessions raw wire validators reject duplicate players, invalid TTL, epochs and commit counts",
		function()
			local h = harness()
			h.s.run(function()
				for _, body in
					{
						{ serverId = "job", ttlMs = 9999, players = { { userId = 7, steal = false } } },
						{
							serverId = "job",
							ttlMs = 60000,
							players = { { userId = 7, steal = false }, { userId = 7, steal = true } },
						},
					}
				do
					check(not h.client.fields:acquireSessions({ body = body } :: any).ok)
				end
				check(not h.client.fields:commitSession({
					body = {
						serverId = "job",
						commitId = "job:1",
						players = {
							{
								userId = 7,
								epoch = 0,
								ops = { { field = "Score", op = "ADD", delta = 1 } },
							},
						},
					},
				}).ok)
				check(not h.client.fields:commitSession({
					body = {
						serverId = "job",
						commitId = "wrong:1",
						players = {
							{
								userId = 7,
								epoch = 1,
								ops = { { field = "Score", op = "ADD", delta = 1 } },
							},
						},
					},
				}).ok)
				check(#h.requests == 0)
				h.client:destroy()
			end)
		end
	)
	test(
		"Sessions invalid grant snapshots release ownership and honor the default load-failure kick",
		function()
			local h = harness({ sessions = { serverId = "job" } })
			h.acquire = function(_body)
				return reply({
					items = {
						{
							userId = 7,
							status = "granted",
							epoch = 7,
							expiresAt = expires(100),
							snapshot = { seq = 0, fields = { Score = "bad" }, versions = { Score = 0 } },
						},
					},
				})
			end
			local kicks = 0
			h.client._helpers.sessions._kick = function(user, _message)
				check(user == 7)
				kicks += 1
			end
			h.s.run(function()
				check(not h.client.fields:loadProfile(123, 7).ok)
				h.s.runtime.wait(1.1)
				check(kicks == 1 and #h.releases == 1)
				h.client:destroy()
			end)
		end
	)
	test("HTTP physical budget caps rolling seconds at eight including burst admission", function()
		local bucket = Bucket.new(500, 8, 0, 0)
		for _ = 1, 8 do
			check(Bucket.http(bucket, 0) == 0)
		end
		check(Bucket.http(bucket, 0) == 1 and Bucket.http(bucket, 0.99) > 0)
		check(Bucket.http(bucket, 1) == 0)
	end)
end
