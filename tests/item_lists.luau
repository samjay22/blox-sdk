--!strict
-- Item lists: bitmap fields on a leased profile (buffering, retries, refusals, stale and unloaded lists), the
-- transaction API, the type system, and the item list admin calls on a config namespace handle.
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Profile = require("../src/Fields/Profile")
local Bitmap = require("../src/Fields/Bitmap")
local System = require("../src/Fields/TypeSystem")
local Operations = require("../src/Fields/Operations")
local Schema = require("../src/Fields/Schema")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
type Member = { bit: number, label: string?, retired: boolean? }
type Player = { Owned: string, Equipped: string, seq: number, version: number }
type Harness = {
	s: Scheduler.Scheduler,
	client: SDK.Client,
	list: { version: number, down: boolean, members: { [string]: Member } },
	players: { [number]: Player },
	commits: { any },
	transactions: { any },
	memberReads: number,
	documentReads: number,
	commit: ((any) -> Core.HttpResponse)?,
	transaction: ((any) -> Core.HttpResponse)?,
}
local function check(value: unknown, label: string?)
	assert(value, (label or "Item list regression") .. " @" .. tostring(debug.info(2, "l")))
end
local function reply(value: unknown, status: number?): Core.HttpResponse
	return { StatusCode = status or 200, Headers = {}, Body = Json.encode(value) }
end
--- Virtual-clock lease expirations relative to the deterministic scheduler epoch.
local function expires(at: number): string
	local seconds = 13 * 60 + 20 + math.floor(at)
	return string.format(
		"2023-11-14T%02d:%02d:%02dZ",
		22 + math.floor(seconds / 3600),
		math.floor(seconds / 60) % 60,
		seconds % 60
	)
end
--- The hex value holding exactly these bits.
local function hex(...: number): string
	local bits: { [number]: boolean } = {}
	for _, bit in { ... } do
		bits[bit] = true
	end
	return Bitmap.encode(bits)
end
local function definition(id: string, maxMembers: number): any
	return {
		universeId = 123,
		id = id,
		description = "",
		status = "ACTIVE",
		type = { kind = "bitmap", source = "Equipment", maxMembers = maxMembers },
		default = "",
		history = "LEDGER",
		writeLevel = "READ_WRITE",
		definitionVersion = 1,
		createdAt = "now",
		updatedAt = "now",
	}
end
local function newList(): { version: number, down: boolean, members: { [string]: Member } }
	return {
		version = 1,
		down = false,
		members = {
			Sword = { bit = 0, label = "Iron Sword" },
			Shield = { bit = 1 },
			Potion = { bit = 2 },
			Old_Axe = { bit = 4, retired = true },
		},
	}
end
--- The commit a real server would make: member names resolve through the list's permanent bits.
local function evaluate(h: Harness, player: Player, op: any): string?
	local current = (player :: any)[op.field] :: string
	local limit = if op.field == "Equipped" then 1 else 64
	local had: { [number]: boolean } = {}
	local currentBits: { number } = Bitmap.decode(current) or {}
	for _, bit in currentBits do
		had[bit] = true
	end
	local result: { [number]: boolean } = if op.op == "REPLACE" then {} else table.clone(had)
	for _, name in op.members do
		local member = h.list.members[name]
		if not member then
			return "unknown_member"
		end
		if op.op == "REVOKE" then
			result[member.bit] = nil
		else
			result[member.bit] = true
		end
	end
	local count = 0
	for bit in result do
		count += 1
		if not had[bit] then
			for _, member in h.list.members do
				if member.bit == bit and member.retired then
					return "member_retired"
				end
			end
		end
	end
	if count > limit then
		return "member_limit"
	end
	(player :: any)[op.field] = Bitmap.encode(result)
	return nil
end
local function harness(): Harness
	local h: Harness = {
		s = Scheduler.new(),
		client = nil :: any,
		list = newList(),
		players = {},
		commits = {},
		transactions = {},
		memberReads = 0,
		documentReads = 0,
		commit = nil,
		transaction = nil,
	}
	local function player(user: number): Player
		h.players[user] = h.players[user] or { Owned = "", Equipped = "", seq = 0, version = 0 }
		return h.players[user]
	end
	local function fields(p: Player): any
		return { Owned = p.Owned, Equipped = p.Equipped }
	end
	local function versions(p: Player): any
		return { Owned = p.version, Equipped = p.version }
	end
	local service = Fake.batch(h.s.runtime, function(request)
		local body: any = if request.Body then Decode.decode(request.Body) else nil
		local url = request.Url
		if string.find(url, "/schema", 1, true) then
			return reply({
				universeId = 123,
				schemaVersion = 1,
				definitions = { definition("Owned", 64), definition("Equipped", 1) },
			})
		elseif string.find(url, "/namespaces/Equipment/snapshot", 1, true) then
			if h.list.down then
				return reply({ code = "forbidden", message = "no access" }, 403)
			end
			local entries: any = {}
			for name, member in h.list.members do
				entries[name] = { bit = member.bit, label = member.label, retired = member.retired }
			end
			return reply({
				namespace = "Equipment",
				version = h.list.version,
				kind = "items",
				entries = entries,
			})
		elseif string.find(url, "/sessions/acquire", 1, true) then
			local items: { any } = {}
			for _, request_ in body.players do
				local p = player(request_.userId)
				table.insert(items, {
					userId = request_.userId,
					status = "granted",
					epoch = 7,
					expiresAt = expires(h.s.time() + body.ttlMs / 1000),
					snapshot = { seq = p.seq, fields = fields(p), versions = versions(p) },
				})
			end
			return reply({ items = items })
		elseif string.find(url, "/commits", 1, true) then
			table.insert(h.commits, body)
			if h.commit then
				return h.commit(body)
			end
			local items: { any } = {}
			for _, entry in body.players do
				local p = player(entry.userId)
				local refused: string? = nil
				for _, op in entry.ops do
					refused = refused or evaluate(h, p, op)
				end
				if refused then
					table.insert(
						items,
						{ userId = entry.userId, status = "rejected", error = { code = refused } }
					)
				else
					p.seq += 1
					p.version += 1
					table.insert(items, {
						userId = entry.userId,
						status = "committed",
						seq = p.seq,
						versions = versions(p),
						expiresAt = expires(h.s.time() + 60),
					})
				end
			end
			return reply({ commitId = body.commitId, items = items })
		elseif string.find(url, "/sessions/renew", 1, true) then
			local items: { any } = {}
			for _, lease in body.leases do
				table.insert(items, {
					userId = lease.userId,
					status = "renewed",
					expiresAt = expires(h.s.time() + body.ttlMs / 1000),
				})
			end
			return reply({ items = items })
		elseif string.find(url, "/sessions/release", 1, true) then
			local items: { any } = {}
			for _, lease in body.leases do
				table.insert(items, { userId = lease.userId, status = "released" })
			end
			return reply({ items = items })
		elseif string.find(url, "/changes/batch", 1, true) then
			local items: { any } = {}
			for _, entry in body.players do
				table.insert(items, {
					userId = entry.userId,
					entries = Json.array({}),
					latestSeq = entry.sinceSeq,
					nextSinceSeq = entry.sinceSeq,
					hasMore = false,
					needsSnapshot = false,
				})
			end
			return reply({ items = items, pollAfterMs = 5000 })
		elseif string.find(url, "/transactions", 1, true) then
			table.insert(h.transactions, body)
			if h.transaction then
				return h.transaction(body)
			end
			return reply({
				txId = "t1",
				replayed = false,
				seq = { ["7"] = 1 },
				results = {
					{
						subject = 7,
						field = "Owned",
						op = "GRANT",
						path = Json.array({}),
						before = "",
						after = hex(0),
						version = 1,
						entryId = Json.null,
					},
				},
			})
		end
		local user = tonumber(string.match(url, "/players/(%d+)/members/"))
		if user then
			h.memberReads += 1
			local p = player(user)
			local names: { string } = {}
			local retired: { string } = {}
			local bits: { number } = {}
			local ownedBits: { number } = Bitmap.decode(p.Owned) or {}
			for _, bit in ownedBits do
				table.insert(bits, bit)
				local found = "#" .. tostring(bit)
				for name, member in h.list.members do
					if member.bit == bit then
						found = name
						if member.retired then
							table.insert(retired, name)
						end
					end
				end
				table.insert(names, found)
			end
			return reply({
				field = "Owned",
				source = "Equipment",
				members = Json.array(names),
				retired = Json.array(retired),
				bits = Json.array(bits),
				value = p.Owned,
				version = p.version,
				configVersion = h.list.version,
			})
		end
		local reader = tonumber(string.match(url, "/players/(%d+)/document"))
		check(reader, "Unexpected route " .. url)
		h.documentReads += 1
		local p = player(reader :: number)
		return reply({ userId = reader, seq = p.seq, data = fields(p), versions = versions(p) })
	end)
	h.client = SDK.new({
		runtime = h.s.runtime,
		backend = service,
		universeId = 123,
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		retries = 1,
		sessions = { serverId = "job", kickOnFailure = false, kickOnLeaseLost = false },
		profileSync = { enabled = false },
		configs = { pollInterval = 1, jitter = 0, staleAfter = 1.2 },
	})
	return h
end
local function load(h: Harness, user: number): Profile.Profile
	local result = h.client.fields:loadProfile(user)
	check(result.ok, "Profile load failed")
	return (result :: any).value
end
local function code(result: Core.Result<any>, expected: string)
	check(
		not result.ok and result.error.code == expected,
		"Expected " .. expected .. " got " .. (if result.ok then "success" else tostring(result.error.code))
	)
end
local function names(result: Core.Result<{ string }>): string
	check(
		result.ok,
		"Expected a member list, got "
			.. (if result.ok then "" else tostring(result.error.code) .. " " .. result.error.message)
	)
	return table.concat((result :: any).value, ",")
end
--- Run a scripted ConfigService call against one namespace handle whose poller is stopped.
local function configClient(s: Scheduler.Scheduler, steps: { Fake.Step }): (any, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	local client = SDK.new({
		runtime = s.runtime,
		backend = fake.backend,
		universeId = 123,
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		retries = 0,
		profileSync = { enabled = false },
	})
	return client, fake
end
local CONFIG = "https://lb1.blox-api.com/remote-config-service/api/config/universes/123/namespaces/Equipment"
local FIELDS = "https://lb1.blox-api.com/fields-service/api/fields/universes/123/item-lists/Equipment"
local function entry(s: Scheduler.Scheduler, key: string, value: any, version: number): string
	return s.json({
		namespace = "Equipment",
		key = key,
		value = value,
		version = version,
		universeId = 123,
		updatedAt = "2026-11-13T00:00:00Z",
	})
end
local function namespaceInfo(s: Scheduler.Scheduler, kind: string): string
	return s.json({
		namespace = "Equipment",
		version = 4,
		entryCount = 3,
		kind = kind,
		nextBit = 3,
		universeId = 123,
		createdAt = "2026-11-13T00:00:00Z",
		updatedAt = "2026-11-13T00:00:00Z",
	})
end
local function problem(s: Scheduler.Scheduler, errorCode: string, extra: { [string]: unknown }?): string
	local body: { [string]: unknown } = { code = errorCode, message = "ignored" }
	local more: any = extra or {}
	for key, value in more do
		body[key] = value
	end
	return s.json(body)
end
local function sent(request: Core.HttpRequest): any
	return Decode.decode(request.Body :: string)
end
return function(test: (string, () -> ()) -> ())
	test(
		"Item list profile: grant, revoke and replace apply at once and save in order, idempotently",
		function()
			local h = harness()
			h.s.run(function()
				local p = load(h, 7)
				check(p:get("Owned") == "" and p.versions.Owned == 0)
				check(p:grant("Owned", { "Sword", "Shield" }).ok)
				check(p:grant("Owned", { "Sword" }).ok, "Granting a held member again is a no-op")
				check(p:get("Owned") == hex(0, 1) and names(p:members("Owned")) == "Shield,Sword")
				local has = p:has("Owned", "Sword")
				check(has.ok and has.value and not (p:has("Owned", "Potion") :: any).value)
				check(p:revoke("Owned", { "Shield" }).ok and p:revoke("Owned", { "Potion" }).ok)
				check(
					p:get("Owned") == hex(0) and #p._buffer == 2,
					"Adjacent grants (and revokes) merge; a revoke keeps its order after a grant"
				)
				check(p:replace("Equipped", { "Sword" }).ok and p:get("Equipped") == hex(0))
				check(p:replace("Equipped", {}).ok and p:get("Equipped") == "")
				h.s.runtime.wait(8)
				check(#h.commits == 1 and h.players[7].Owned == hex(0) and h.players[7].Equipped == "")
				local ops = h.commits[1].players[1].ops
				check(
					#ops == 4 and ops[1].op == "GRANT" and table.concat(ops[1].members, ",") == "Shield,Sword"
				)
				check(ops[2].op == "REVOKE" and table.concat(ops[2].members, ",") == "Potion,Shield")
				check(ops[3].op == "REPLACE" and ops[3].members[1] == "Sword" and #ops[4].members == 0)
				check(#p._buffer == 0 and #p._sent == 0 and p.versions.Owned == 1)
				h.client:destroy()
			end)
			check(h.s.pending() == 0)
		end
	)
	test(
		"Item list profile: unknown, retired, oversized and malformed grants are refused before buffering",
		function()
			local h = harness()
			h.players[8] = { Owned = hex(4), Equipped = "", seq = 0, version = 0 }
			h.s.run(function()
				local p = load(h, 7)
				local unknown = p:grant("Owned", { "Sword", "Nope", "Ghost" })
				code(unknown, "unknown_member")
				check(not unknown.ok and table.concat(unknown.error.members or {}, ",") == "Nope,Ghost")
				local retired = p:grant("Owned", { "Old_Axe" })
				code(retired, "member_retired")
				check(not retired.ok and (retired.error.members or {})[1] == "Old_Axe")
				local limited = p:grant("Equipped", { "Sword", "Shield" })
				code(limited, "member_limit")
				check(not limited.ok and limited.error.maxMembers == 1)
				code(p:grant("Owned", {}), "below_min_size")
				code(p:grant("Owned", { "bad name" }), "invalid_member_name")
				code(p:grant("Missing", { "Sword" }), "unknown_field")
				check(#p._buffer == 0 and p:get("Owned") == "", "Nothing was buffered")
				check(p:replace("Equipped", { "Shield" }).ok)
				code(p:grant("Equipped", { "Sword" }), "member_limit")
				-- A retired member the player already holds can be kept, listed and revoked.
				local old = load(h, 8)
				check(names(old:members("Owned")) == "Old_Axe" and names(old:usable("Owned")) == "")
				check(
					old:replace("Owned", { "Old_Axe", "Sword" }).ok and names(old:usable("Owned")) == "Sword"
				)
				check(old:revoke("Owned", { "Old_Axe" }).ok and names(old:members("Owned")) == "Sword")
				code(old:grant("Owned", { "Old_Axe" }), "member_retired")
				h.client:destroy()
			end)
		end
	)
	test(
		"Item list profile: the cached list is checked, so a stale list fails closed until it refreshes",
		function()
			local h = harness()
			h.players[9] = { Owned = hex(0, 5), Equipped = "", seq = 0, version = 0 }
			h.s.run(function()
				local p = load(h, 9)
				check(names(p:members("Owned")) == "#5,Sword", "A bit the list does not know shows as #bit")
				check(names(p:usable("Owned")) == "Sword")
				code(p:grant("Owned", { "Bow" }), "unknown_member")
				h.list.version = 2
				h.list.members.Bow = { bit = 5 }
				h.s.runtime.wait(2.5)
				check(p:grant("Owned", { "Bow" }).ok and names(p:members("Owned")) == "Bow,Sword")
				check(
					names(p:usable("Owned")) == "Bow,Sword" and h.memberReads == 0,
					"No request for a loaded list"
				)
				h.list.version = 3
				h.list.members.Bow.retired = true
				h.s.runtime.wait(2.5)
				check(names(p:usable("Owned")) == "Sword" and names(p:members("Owned")) == "Bow,Sword")
				check(p:revoke("Owned", { "Bow" }).ok)
				code(p:grant("Owned", { "Bow" }), "member_retired")
				h.client:destroy()
			end)
		end
	)
	test(
		"Item list profile: an unloaded list fails writes closed and reads fall back to the server",
		function()
			local h = harness()
			h.list.down = true
			h.players[7] = { Owned = hex(0, 4), Equipped = "", seq = 0, version = 0 }
			h.s.run(function()
				local started = h.s.time()
				local p = load(h, 7)
				check(h.s.time() - started <= 8, "Loading waits at most five seconds for the list")
				check(not h.client.configs:namespace("Equipment"):isReady())
				local refused = p:grant("Owned", { "Sword" })
				code(refused, "enum_source_unavailable")
				check(not refused.ok and refused.error.status == 503 and refused.error.kind == "Server")
				check(#p._buffer == 0)
				check(names(p:members("Owned")) == "Old_Axe,Sword" and h.memberReads == 1)
				check(names(p:usable("Owned")) == "Sword" and h.memberReads == 2)
				local has = p:has("Owned", "Old_Axe")
				check(has.ok and has.value and h.memberReads == 3, "A retired member still counts as held")
				h.list.down = false
				h.s.runtime.wait(4)
				check(h.client.configs:namespace("Equipment"):isReady())
				check(p:grant("Owned", { "Potion" }).ok and names(p:usable("Owned")) == "Potion,Sword")
				check(h.memberReads == 3, "Once loaded, reads stay local")
				h.client:destroy()
			end)
		end
	)
	test(
		"Item list profile: a commit the server refuses fires CommitRejected and resyncs to server truth",
		function()
			local h = harness()
			h.s.run(function()
				local p = load(h, 7)
				local rejected: { string } = {}
				h.client.CommitRejected:connect(function(event)
					table.insert(rejected, event.code)
				end)
				-- The server's list moved on: it no longer has Potion, while this server's cache still does.
				local listed: any = h.list.members
				listed.Potion = nil
				check(p:grant("Owned", { "Potion" }).ok and p:get("Owned") == hex(2))
				h.s.runtime.wait(8)
				check(#rejected == 1 and rejected[1] == "unknown_member")
				check(p:get("Owned") == "" and #p._buffer == 0 and #p._sent == 0)
				h.client:destroy()
			end)
		end
	)
	test("Item list profile: a failed save is retried as the same commit and applies once", function()
		local h = harness()
		local attempts = 0
		h.s.run(function()
			local p = load(h, 7)
			h.commit = function(body)
				attempts += 1
				if attempts == 1 then
					return reply({ code = "internal_server_error" }, 503)
				end
				h.commit = nil
				local p7 = h.players[7]
				for _, op in body.players[1].ops do
					check(evaluate(h, p7, op) == nil)
				end
				p7.seq += 1
				p7.version += 1
				return reply({
					commitId = body.commitId,
					items = {
						{
							userId = 7,
							status = "committed",
							seq = p7.seq,
							versions = { Owned = p7.version, Equipped = p7.version },
							expiresAt = expires(h.s.time() + 60),
						},
					},
				})
			end
			check(p:grant("Owned", { "Sword" }).ok and p:grant("Owned", { "Shield" }).ok)
			h.s.runtime.wait(20)
			check(attempts == 2 and #h.commits == 2 and h.commits[1].commitId == h.commits[2].commitId)
			check(h.players[7].Owned == hex(0, 1) and p:get("Owned") == hex(0, 1) and #p._sent == 0)
			h.client:destroy()
		end)
	end)
	test("Item list transactions: grant, revoke and replace send member names and refuse typos", function()
		local h = harness()
		h.s.run(function()
			local p = load(h, 7)
			local tx = p:immediate():grant("Owned", { "Sword", "Sword" }):revoke("Owned", { "Shield" })
			tx:replace("Equipped", { "Sword" })
			local committed = tx:reason("test"):commit()
			check(
				committed.ok and #h.transactions == 1,
				if committed.ok
					then "count"
					else tostring(committed.error.code) .. tostring(committed.error.message)
			)
			local ops = h.transactions[1].ops
			check(
				#ops == 3 and ops[1].op == "GRANT" and #ops[1].members == 1 and ops[1].members[1] == "Sword"
			)
			check(ops[2].op == "REVOKE" and ops[3].op == "REPLACE" and ops[3].field == "Equipped")
			local bad = p:immediate():grant("Owned", { "no good" }):reason("test"):commit()
			code(bad, "invalid_member_name")
			local wrong = p:immediate():grant("Missing", { "Sword" }):reason("test"):commit()
			code(wrong, "unknown_field")
			check(#h.transactions == 1, "Refused locally, nothing sent")
			local built = h.client.fields:operations():replace("Owned", { "Sword" }):build()
			check(built.ok and built.value[1].op == "REPLACE")
			h.transaction = function(_body)
				return reply({
					code = "unknown_member",
					message = "Not a member of item list Equipment: Nope",
					members = { "Nope" },
					source = "Equipment",
				}, 422)
			end
			local refused = p:immediate():grant("Owned", { "Nope" }):reason("test"):commit()
			code(refused, "unknown_member")
			check(
				not refused.ok
					and (refused.error.members or {})[1] == "Nope"
					and refused.error.source == "Equipment"
			)
			h.transaction = function(_body)
				return reply({ code = "member_limit", message = "too many", maxMembers = 1 }, 422)
			end
			local limited = p:immediate():grant("Equipped", { "Sword" }):reason("test"):commit()
			code(limited, "member_limit")
			check(not limited.ok and limited.error.maxMembers == 1)
			h.transaction = function(_body)
				return reply({ code = "enum_source_unavailable", message = "retry shortly" }, 503)
			end
			local unavailable = p:immediate():grant("Owned", { "Sword" }):reason("test"):commit()
			code(unavailable, "enum_source_unavailable")
			h.transaction = function(_body)
				return reply({ code = "member_retired", message = "retired", members = { "Old_Axe" } }, 422)
			end
			code(p:immediate():grant("Owned", { "Old_Axe" }):reason("test"):commit(), "member_retired")
			h.transaction = function(_body)
				return reply({ code = "source_immutable", message = "no" }, 409)
			end
			code(p:immediate():set("Owned", ""):reason("test"):commit(), "source_immutable")
			h.client:destroy()
		end)
	end)
	test(
		"Item list type system: bitmaps are whole fields holding canonical hex, checked against the list",
		function()
			check(
				Bitmap.encode({ [0] = true, [9] = true, [511] = true })
					== "0102" .. string.rep("00", 61) .. "80"
			)
			local decoded = Bitmap.decode(hex(0, 9, 511))
			check(decoded and table.concat(decoded, ",") == "0,9,511" and Bitmap.decode("0300") == nil)
			check(
				Bitmap.valid("")
					and not Bitmap.valid("AB")
					and not Bitmap.valid("abc")
					and not Bitmap.valid(1)
			)
			check(Bitmap.encode({}) == "", "The empty set is the empty string")
			local single: any = { kind = "bitmap", source = "Equipment", maxMembers = 1 }
			check(System.compile(single).ok and System.compile({ kind = "bitmap", source = "Equipment" }).ok)
			for _, bad in
				{
					{ kind = "bitmap" },
					{ kind = "bitmap", source = "bad name" },
					{ kind = "bitmap", source = "Equipment", maxMembers = 0 },
					{ kind = "bitmap", source = "Equipment", maxMembers = 513 },
					{ kind = "bitmap", source = "Equipment", maxMembers = 1.5 },
					{ kind = "bitmap", source = "Equipment", extra = true },
					{ kind = "nullable", of = { kind = "bitmap", source = "Equipment" } },
					{ kind = "list", item = { kind = "bitmap", source = "Equipment" } },
				}
			do
				code(System.compile(bad), "invalid_definition")
			end
			check(System.validate(single, "").ok and System.validate(single, "02").ok)
			code(System.validate(single, "0300"), "invalid_bitmap")
			code(System.validate(single, "AB"), "invalid_bitmap")
			code(System.validate(single, 5), "wrong_type")
			local limited = System.validate(single, "03")
			code(limited, "member_limit")
			check(not limited.ok and limited.error.maxMembers == 1)
			local default = System.default(single)
			check(default.ok and default.value == "")
			local members: { [string]: any } =
				{ Sword = { bit = 0 }, Shield = { bit = 1 }, Old = { bit = 4, retired = true } }
			local lookup = function(source: string): { [string]: any }?
				return if source == "Equipment" then members else nil
			end
			local wide: any = { kind = "bitmap", source = "Equipment" }
			local granted =
				System.apply(wide, "", "", "GRANT", { members = { "Sword", "Sword" } }, nil, lookup :: any)
			check(granted.ok and granted.value == hex(0))
			local both =
				System.apply(wide, hex(0), "", "GRANT", { members = { "Shield" } }, nil, lookup :: any)
			check(both.ok and both.value == hex(0, 1))
			local revoked = System.apply(
				wide,
				hex(0, 1),
				"",
				"REVOKE",
				{ members = { "Sword", "Shield" } },
				nil,
				lookup :: any
			)
			check(revoked.ok and revoked.value == "")
			local replaced =
				System.apply(wide, hex(0, 1), "", "REPLACE", { members = { "Shield" } }, nil, lookup :: any)
			check(replaced.ok and replaced.value == hex(1))
			local reset = System.apply(wide, hex(0), "", "RESET", {}, nil, nil)
			check(reset.ok and reset.value == "")
			code(
				System.apply(wide, "", "", "GRANT", { members = { "Sword" } }, nil, nil),
				"enum_source_unavailable"
			)
			code(
				System.apply(wide, "", "", "GRANT", { members = { "Sword" } }, nil, function(_s: string)
					return nil
				end),
				"enum_source_unavailable"
			)
			code(
				System.apply(wide, "", "", "GRANT", { members = { "Nope" } }, nil, lookup :: any),
				"unknown_member"
			)
			code(
				System.apply(wide, "", "", "GRANT", { members = { "Old" } }, nil, lookup :: any),
				"member_retired"
			)
			code(System.apply(wide, "", "", "GRANT", { members = {} }, nil, lookup :: any), "below_min_size")
			code(
				System.apply(wide, "", "", "GRANT", { members = { 1 } }, nil, lookup :: any),
				"invalid_member_name"
			)
			code(
				System.apply(wide, "", "", "GRANT", { items = { "Sword" } }, nil, lookup :: any),
				"invalid_request"
			)
			code(System.apply(wide, "", "", "ADD", { delta = 1 }, nil, lookup :: any), "op_not_applicable")
			code(
				System.apply({ kind = "int" }, 0, 0, "GRANT", { members = { "Sword" } }, nil, lookup :: any),
				"op_not_applicable"
			)
			code(
				System.apply(wide, "", "", "GRANT", { members = { "Sword" } }, { "x" }, lookup :: any),
				"invalid_path"
			)
			-- SET is only guarded when the list is known; the server is authoritative either way.
			check(System.apply(wide, "", "", "SET", { value = hex(7) }, nil, nil).ok)
			code(System.apply(wide, "", "", "SET", { value = hex(7) }, nil, lookup :: any), "unknown_member")
			code(System.apply(wide, "", "", "SET", { value = hex(4) }, nil, lookup :: any), "member_retired")
			check(
				System.apply(wide, hex(4), "", "SET", { value = hex(4, 0) }, nil, lookup :: any).ok,
				"Keeping a held retired member"
			)
			code(
				System.apply(single, "", "", "SET", { value = hex(0, 1) }, nil, lookup :: any),
				"member_limit"
			)
		end
	)
	test("Item list operations: member lists are normalized, deduplicated and checked statically", function()
		local s = Scheduler.new()
		local cache = Schema.new(s.runtime, function()
			return reply(nil) :: any
		end)
		cache._version = 1
		cache._definitions.Owned = definition("Owned", 64)
		cache._definitions.Score = {
			universeId = 123,
			id = "Score",
			description = "",
			status = "ACTIVE",
			type = { kind = "int" },
			default = 0,
			history = "LEDGER",
			writeLevel = "READ_WRITE",
			definitionVersion = 1,
			createdAt = "now",
			updatedAt = "now",
		}
		local prepared = Operations.prepare(
			cache,
			{ { field = "Owned", op = "REPLACE", members = { "B", "A", "B" } } :: any }
		)
		check(prepared.ok and table.concat((prepared.value[1] :: any).members, ",") == "B,A")
		local cleared =
			Operations.prepare(cache, { { field = "Owned", op = "REPLACE", members = {} } :: any })
		check(
			cleared.ok and Json.isArray((cleared.value[1] :: any).members),
			"An empty list keeps its array shape"
		)
		code(
			Operations.prepare(cache, { { field = "Owned", op = "GRANT", members = {} } :: any }),
			"below_min_size"
		)
		code(
			Operations.prepare(cache, { { field = "Score", op = "GRANT", members = { "A" } } :: any }),
			"op_not_applicable"
		)
		code(
			Operations.prepare(
				cache,
				{ { field = "Owned", op = "GRANT", members = { "A" }, delta = 1 } :: any }
			),
			"invalid_request"
		)
		check(Operations.wire({ field = "Owned", op = "GRANT", members = { "A" } }))
		check(not Operations.wire({ field = "Owned", op = "GRANT", members = { 1 } }))
		check(not Operations.wire({ field = "Owned", op = "GRANT" }))
	end)
	test(
		"Config namespace: the item list view reads kind, members and active members from the cache",
		function()
			local s = Scheduler.new()
			local fake = Fake.new(s.runtime, {
				{
					body = s.json({
						namespace = "Equipment",
						version = 3,
						kind = "items",
						entries = {
							Sword = { bit = 0, label = "Iron Sword", meta = { tier = 1 } },
							Old_Axe = { bit = 4, retired = true },
							Broken = "not a member",
						},
					}),
				},
				{
					body = s.json({
						namespace = "Equipment",
						version = 4,
						kind = "settings",
						entries = { a = 1 },
					}),
				},
			})
			local c = SDK.new({
				runtime = s.runtime,
				backend = fake.backend,
				universeId = 123,
				key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
				retries = 0,
				profileSync = { enabled = false },
				configs = { pollInterval = 1, jitter = 0, staleAfter = 5 },
			})
			local list = c.configs:namespace("Equipment")
			check(list:kind() == "settings" and next(list:members()) == nil, "Before the first load")
			s.run(function()
				check(list:waitReady(5) and list:kind() == "items" and list:snapshot().kind == "items")
				local members = list:members()
				check(
					members.Sword.bit == 0
						and members.Sword.label == "Iron Sword"
						and members.Sword.retired == false
				)
				check(members.Sword.meta ~= nil and members.Sword.meta.tier == 1 and table.isfrozen(members))
				check(members.Old_Axe.retired and members.Old_Axe.bit == 4 and members.Broken == nil)
				check(list:activeMembers().Old_Axe == nil and list:activeMembers().Sword ~= nil)
				check(list:member("Sword") == members.Sword and list:member("Nope") == nil)
				check(list:members() == members, "Built once per version")
				s.runtime.wait(1.5)
				check(list:kind() == "settings" and next(list:members()) == nil and list:get("a") == 1)
				c:destroy()
			end)
		end
	)
	test(
		"Config namespace: item list admin calls send the right requests and surface member_in_use",
		function()
			local s = Scheduler.new()
			local seen: { string } = {}
			--- One scripted step that records and checks its request.
			local function step(
				method: string,
				url: string,
				body: string,
				verify: ((any) -> ())?,
				status: number?
			): Fake.Step
				return {
					status = status,
					body = body,
					check = function(request: Core.HttpRequest)
						table.insert(seen, request.Method .. " " .. request.Url)
						check(
							request.Method == method and request.Url == url,
							method .. " " .. url .. " got " .. request.Method .. " " .. request.Url
						)
						if verify then
							verify(if request.Body then sent(request) else nil)
						end
					end,
				}
			end
			local put = CONFIG .. "/entries/Sword"
			local c, fake = configClient(s, {
				step("PUT", put, entry(s, "Sword", { bit = 0, label = "Iron Sword" }, 1), function(body)
					check(
						body.expectedVersion == 0
							and body.value.label == "Iron Sword"
							and body.value.bit == nil
					)
					check(body.value.retired == nil and body.value.meta.tier == 1)
				end),
				step(
					"GET",
					put,
					entry(
						s,
						"Sword",
						{ bit = 0, label = "Iron Sword", retired = true, meta = { tier = 1 } },
						3
					)
				),
				step("PUT", put, entry(s, "Sword", { bit = 0, label = "Steel Sword" }, 4), function(body)
					check(
						body.expectedVersion == 3
							and body.value.bit == 0
							and body.value.label == "Steel Sword"
					)
					check(body.value.retired == true and body.value.meta.tier == 1, "Edits keep the rest")
				end),
				step(
					"GET",
					put,
					entry(s, "Sword", { bit = 0, label = "Iron Sword", description = "Sharp" }, 4)
				),
				step("PUT", put, entry(s, "Sword", { bit = 0, retired = true }, 5), function(body)
					check(body.expectedVersion == 4 and body.value.retired == true and body.value.bit == 0)
					check(body.value.label == "Iron Sword" and body.value.description == "Sharp")
				end),
				step("GET", put, entry(s, "Sword", { bit = 0, retired = true }, 5)),
				step("PUT", put, entry(s, "Sword", { bit = 0 }, 6), function(body)
					check(body.expectedVersion == 5 and body.value.retired == nil and body.value.bit == 0)
				end),
				step("GET", put, entry(s, "Sword", "not a member", 5)),
				step(
					"DELETE",
					put,
					problem(
						s,
						"member_in_use",
						{
							details = {
								holders = {
									{ member = "Sword", count = 12, samplePlayers = { 1, 2, 3, 4, 5 } },
								},
							},
						} :: any
					),
					nil,
					409
				),
				step("DELETE", put, problem(s, "holder_check_unavailable"), nil, 503),
				step("DELETE", put, "", nil, 204),
				step("PUT", CONFIG .. "/kind", namespaceInfo(s, "items"), function(body)
					check(body.kind == "items")
				end),
				step("PUT", CONFIG .. "/kind", problem(s, "kind_immutable"), nil, 409),
				step(
					"GET",
					FIELDS .. "/usage",
					s.json({
						namespace = "Equipment",
						fields = { { field = "Owned", status = "ACTIVE", maxMembers = 64 } },
						holders = { Sword = 12 },
						configVersion = 4,
					})
				),
				step(
					"GET",
					FIELDS .. "/members/Sword/holders",
					s.json({
						member = "Sword",
						bit = 0,
						retired = false,
						count = 12,
						byField = { Owned = 12 },
						samplePlayers = { 1, 2 },
					})
				),
				step("PUT", CONFIG .. "/entries/Bow", problem(s, "version_conflict"), nil, 409),
				step("PUT", CONFIG .. "/entries/Bow", problem(s, "limit_exceeded"), nil, 409),
			})
			s.run(function()
				local list = c.configs:namespace("Equipment")
				list:destroy()
				local added = list:addMember("Sword", { label = "Iron Sword", meta = { tier = 1 } })
				check(added.ok and added.value.value.bit == 0)
				local updated = list:updateMember("Sword", { label = "Steel Sword" })
				check(updated.ok and updated.value.version == 4)
				check(list:retireMember("Sword").ok and list:unretireMember("Sword").ok)
				local notMember = list:retireMember("Sword")
				code(notMember, "sdk_validation")
				local inUse = list:removeMember("Sword")
				code(inUse, "member_in_use")
				check(not inUse.ok and inUse.error.status == 409 and inUse.error.kind == "Conflict")
				local holders = (inUse :: any).error.holders
				check(holders and #holders == 1 and holders[1].member == "Sword" and holders[1].count == 12)
				check(#holders[1].samplePlayers == 5 and holders[1].samplePlayers[5] == 5)
				local unavailable = list:removeMember("Sword")
				code(unavailable, "holder_check_unavailable")
				check(
					not unavailable.ok
						and unavailable.error.kind == "Server"
						and unavailable.error.holders == nil
				)
				check(list:removeMember("Sword").ok)
				check(list:setKind("items").ok)
				code(list:setKind("items"), "kind_immutable")
				local before = fake.count()
				code(list:setKind("bogus" :: any), "sdk_validation")
				code(list:addMember("bad name"), "sdk_validation")
				code(list:addMember("Sword", { label = string.rep("x", 101) }), "sdk_validation")
				code(list:addMember("Sword", { bit = 3 } :: any), "sdk_validation")
				code(list:updateMember("Sword", { meta = { 1, 2 } }), "sdk_validation")
				code(list:retireMember("bad name"), "sdk_validation")
				code(list:removeMember("bad name"), "sdk_validation")
				check(fake.count() == before, "Invalid input never reaches the network")
				local usage = list:usage()
				check(usage.ok and usage.value.holders.Sword == 12 and usage.value.fields[1].field == "Owned")
				local drill = list:holders("Sword")
				check(drill.ok and drill.value.count == 12 and drill.value.samplePlayers[2] == 2)
				code(list:holders("bad name"), "sdk_validation")
				code(list:addMember("Bow"), "version_conflict")
				code(list:addMember("Bow"), "limit_exceeded")
				check(fake.remaining() == 0 and #seen == 17)
				c:destroy()
			end)
		end
	)
end
