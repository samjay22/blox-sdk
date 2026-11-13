--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
--- Fail a regression without printing request or response payloads.
local function check(value: unknown, message: string?)
	assert(value, (message or "Config regression failed") .. " @" .. tostring(debug.info(2, "l")))
end
--- Build a fresh offline client; polling is fast and unjittered so virtual time is exact.
local function client(
	s: Scheduler.Scheduler,
	steps: { Fake.Step },
	config: SDK.Config?
): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	local cfg: SDK.Config = config or {}
	cfg.runtime = s.runtime
	cfg.backend = fake.backend
	cfg.profileSync = { enabled = false }
	cfg.retryRatio = 1
	cfg.retries = 1
	cfg.key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
	cfg.universeId = 123
	if cfg.configs == nil then
		cfg.configs = { pollInterval = 1, jitter = 0, staleAfter = 1.2 }
	end
	return SDK.new(cfg), fake
end
--- A snapshot response body.
local function snapshot(s: Scheduler.Scheduler, version: number, entries: { [string]: unknown }): string
	return s.json({ namespace = "Shop", version = version, kind = "settings", entries = entries })
end
--- A ConfigService error body.
local function problem(s: Scheduler.Scheduler, code: string): string
	return s.json({ code = code, message = "ignored" })
end
--- Assert a failed result with a machine code.
local function code(result: Core.Result<any>, expected: string)
	check(
		not result.ok and result.error.code == expected,
		"Expected " .. expected .. " got " .. (if result.ok then "success" else tostring(result.error.code))
	)
end
local BASE = "https://lb1.blox-api.com/remote-config-service/api/config/universes/123/namespaces/Shop"
--- Register ConfigService regressions in the shared deterministic harness.
return function(test: (string, () -> ()) -> ())
	test("Configs poll with ETag, keep last good state on 304 and errors, and signal changes", function()
		local s = Scheduler.new()
		local seen: { string } = {}
		local capture = function(r: Core.HttpRequest)
			table.insert(seen, tostring(r.Headers["If-None-Match"]))
			check(r.Method == "GET" and r.Url == BASE .. "/snapshot")
		end
		local c, f = client(s, {
			{ body = snapshot(s, 1, { a = 1, b = "x" }), headers = { ETag = '"1"' }, check = capture },
			{ status = 304, check = capture },
			{ status = 400, body = problem(s, "validation_failed"), check = capture },
			{ body = snapshot(s, 2, { a = 2, c = true }), headers = { ETag = '"2"' }, check = capture },
		})
		local shop = c.configs:namespace("Shop")
		check(c.configs:namespace("Shop") == shop, "One handle per namespace")
		local changes: { any } = {}
		shop.Changed:connect(function(change)
			table.insert(changes, change)
		end)
		shop.Changed:connect(function(_change)
			error("Synthetic listener failure")
		end)
		check(shop:get("a") == nil and shop:get("a", 9) == 9 and not shop:isReady() and shop:isStale())
		check(shop:version() == 0 and shop:snapshot().version == 0)
		s.run(function()
			check(shop:waitReady(5) and shop:isReady())
			check(shop:get("a") == 1 and shop:getString("b", "") == "x" and shop:version() == 1)
			check(shop:getNumber("missing", 7) == 7 and shop:getBoolean("a", false) == false)
			check(#changes == 1 and changes[1].version == 1 and changes[1].previousVersion == 0)
			check(#changes[1].set == 2 and #changes[1].deleted == 0)
			s.runtime.wait(2.0)
			check(shop:version() == 1 and shop:lastError() == nil and not shop:isStale())
			s.runtime.wait(1.5)
			check(shop:get("a") == 1 and shop:lastError() ~= nil and shop:isStale())
			check(shop:lastRefreshedAt() ~= nil)
			s.runtime.wait(2.0)
			check(shop:get("a") == 2 and shop:get("b") == nil and shop:has("c") and shop:lastError() == nil)
			check(#changes == 2 and changes[2].previousVersion == 1)
			local keys = table.concat(changes[2].keys, ",")
			check(keys == "a,b,c" and changes[2].deleted[1] == "b", keys)
			check(table.concat(shop:keys(), ",") == "a,c")
			check(shop:snapshot().entries.a == 2 and table.isfrozen(shop:snapshot().entries))
			c:destroy()
		end)
		check(f.count() == 4 and seen[1] == "nil" and seen[2] == '"1"' and seen[4] == '"1"')
		check(s.pending() == 0, "Poller stopped on destroy")
	end)
	test(
		"Configs treat a never-written namespace as empty and ignore regressing or malformed snapshots",
		function()
			local s = Scheduler.new()
			local c, f = client(s, {
				{ status = 404, body = problem(s, "namespace_not_found") },
				{ body = snapshot(s, 4, { n = 2 }) },
				{ body = snapshot(s, 3, { n = 99 }) },
				{ body = s.json({ version = 5 }) },
			})
			local fresh = c.configs:namespace("Shop")
			s.run(function()
				check(fresh:waitReady(5) and fresh:version() == 0 and fresh:lastError() == nil)
				check(fresh:snapshot().entries.n == nil)
				s.runtime.wait(2.0)
				check(fresh:version() == 4 and fresh:get("n") == 2)
				s.runtime.wait(1.5)
				check(fresh:version() == 4 and fresh:get("n") == 2 and fresh:lastError() ~= nil)
				s.runtime.wait(2.0)
				check(fresh:version() == 4 and fresh:get("n") == 2)
				c:destroy()
			end)
			check(f.count() >= 4 and s.pending() == 0)
		end
	)
	test("Configs waitReady times out without a response and destroy stops the poller", function()
		local s = Scheduler.new()
		local c, f = client(s, { { status = 400, body = problem(s, "validation_failed") } }, {
			configs = { pollInterval = 60, jitter = 0 },
		})
		local shop = c.configs:namespace("Shop")
		s.run(function()
			check(not shop:waitReady(0.5) and shop:lastError() ~= nil and shop:isStale())
			check(shop:get("x", "fallback") == "fallback")
			shop:destroy()
			check(shop:isDestroyed() and not shop:refresh())
			check(c.configs:namespace("Shop") ~= shop, "A destroyed handle is replaced")
			c:destroy()
		end)
		check(f.count() == 1 and s.pending() == 0)
	end)
	test(
		"Configs admin calls send exact requests, map conflicts and never reach transport when invalid",
		function()
			local s = Scheduler.new()
			local seen: { string } = {}
			local capture = function(r: Core.HttpRequest)
				table.insert(seen, r.Method .. " " .. r.Url .. " " .. tostring(r.Body))
			end
			local entry = {
				universeId = 123,
				namespace = "Shop",
				key = "limit",
				value = 5,
				version = 1,
				description = "d",
				updatedAt = "2026-11-12T00:00:00Z",
			}
			local summary = {
				universeId = 123,
				namespace = "Shop",
				version = 2,
				entryCount = 1,
				kind = "settings",
				nextBit = 0,
				createdAt = "2026-11-12T00:00:00Z",
				updatedAt = "2026-11-12T00:00:00Z",
			}
			local c, f = client(s, {
				{ body = s.json(entry), check = capture },
				{ status = 409, body = problem(s, "version_conflict"), check = capture },
				{ status = 204, check = capture },
				{ body = s.json(summary), check = capture },
				{ body = s.json(summary), check = capture },
				{ body = s.json({ items = Json.array({}) }), check = capture },
				{ status = 404, body = problem(s, "version_not_found"), check = capture },
				{ body = s.json({ items = Json.array({}) }), check = capture },
			})
			local shop = c.configs:namespace("Shop")
			shop:destroy()
			s.run(function()
				local put = shop:set("limit", 5, { description = "d", expectedVersion = 0 })
				check(put.ok and put.value.version == 1)
				code(shop:set("limit", 6, { expectedVersion = 0 }), "version_conflict")
				check(shop:delete("limit").ok)
				check(shop:setMany({ set = { a = 1 :: any }, delete = { "b" }, expectedVersion = 1 }).ok)
				check(shop:rollback(1).ok)
				check(shop:history({ limit = 5 }).ok)
				code(shop:at(9), "version_not_found")
				check(c.configs:namespaces().ok)
				-- None of these reach the transport.
				code(shop:set("bad key", 1), "sdk_validation")
				code(shop:set("limit", Json.null), "sdk_validation")
				code(shop:set("limit", nil :: any), "sdk_validation")
				code(shop:set("limit", string.rep("x", 70000)), "sdk_validation")
				code(shop:delete(""), "sdk_validation")
				code(shop:setMany({}), "sdk_validation")
				code(shop:setMany({ set = { a = 1 :: any }, delete = { "a" } }), "sdk_validation")
				code(shop:rollback(-1), "sdk_validation")
				code(shop:at(0), "sdk_validation")
				code(shop:entry("a b"), "sdk_validation")
				c:destroy()
			end)
			check(f.count() == 8)
			check(
				seen[1]
					== "PUT "
						.. BASE
						.. '/entries/limit {"description":"d","expectedVersion":0,"value":5}'
			)
			check(seen[3] == "DELETE " .. BASE .. "/entries/limit nil")
			local patch = Decode.decode(string.match(seen[4], "PATCH [^ ]+ (.*)") :: string) :: any
			check(string.find(seen[4], "PATCH " .. BASE .. "/entries ", 1, true) == 1)
			check(patch.expectedVersion == 1 and patch.set.a.value == 1 and patch.delete[1] == "b")
			check(seen[5] == "POST " .. BASE .. '/rollback {"toVersion":1}')
			check(seen[6] == "GET " .. BASE .. "/history?limit=5 nil")
			check(seen[7] == "GET " .. BASE .. "/history/9 nil")
			check(
				seen[8]
					== "GET https://lb1.blox-api.com/remote-config-service/api/config/universes/123/namespaces nil"
			)
		end
	)
	test("Configs refresh after a successful local write so the cache sees its own change", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{ body = snapshot(s, 1, { a = 1 }) },
			{
				body = s.json({
					universeId = 123,
					namespace = "Shop",
					key = "a",
					value = 2,
					version = 2,
					updatedAt = "2026-11-12T00:00:00Z",
				}),
			},
			{ body = snapshot(s, 2, { a = 2 }) },
		}, { configs = { pollInterval = 600, jitter = 0 } })
		local shop = c.configs:namespace("Shop")
		s.run(function()
			check(shop:waitReady(5) and shop:get("a") == 1)
			check(shop:set("a", 2).ok)
			s.runtime.wait(1.5)
			check(shop:get("a") == 2 and shop:version() == 2)
			c:destroy()
		end)
		check(f.count() == 3 and s.pending() == 0)
	end)
	test("Configs enforce access levels locally and validate names and options", function()
		local s = Scheduler.new()
		local c, f = client(
			s,
			{ { body = s.json({ namespace = "Shop", version = 1, kind = "settings", entries = {} }) } },
			{
				levels = { ConfigService = "READ" },
				configs = { pollInterval = 600, jitter = 0 },
			}
		)
		local shop = c.configs:namespace("Shop")
		s.run(function()
			check(shop:waitReady(5))
			code(shop:set("a", 1), "sdk_local")
			code(shop:delete("a"), "sdk_local")
			code(shop:setMany({ set = { a = 1 :: any } }), "sdk_local")
			code(shop:rollback(1), "sdk_local")
			check(not pcall(c.configs.namespace, c.configs, "bad name"))
			check(not pcall(c.configs.namespace, c.configs, "Other", { pollInterval = 0 }))
			c:destroy()
			check(not pcall(c.configs.namespace, c.configs, "Late"))
		end)
		check(f.count() == 1 and s.pending() == 0)
		check(not pcall(SDK.new, {
			key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
			universeId = 1,
			configs = { pollInterval = 0 },
		}))
	end)
end
