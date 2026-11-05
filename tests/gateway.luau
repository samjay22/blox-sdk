--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Config = require("../src/Core/Config")
local Routing = require("../src/Core/Routing")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
local Session = require("../src/Auth/UserSession")
local Tests = {}
--- Fail a routing regression without logging request data or credentials.
local function check(value: unknown)
	assert(value, "Gateway routing regression failed")
end
-- Independent deployment expectations, not copied from the generated runtime table.
Tests.prefixes = table.freeze({
	auth = "/auth-service",
	data = "/data-service",
	matchmaking = "/matchmaking-service",
	party = "/party-service",
	codes = "/code-service",
	audit = "/audit-service",
	config = "/remote-config-service",
	leaderboards = "/leaderboard-service",
	economy = "/economy-service",
}) :: { [string]: string }
--- Register offline URL, override, validation and shared-origin regressions.
function Tests.register(test: (string, () -> ()) -> ())
	test("gateway routing is canonical, immutable and isolated from caller configuration", function()
		check(Routing.gatewayUrl == "https://lb1.blox-api.com")
		local origins, bases = Config.resolve({})
		check(table.isfrozen(origins) and table.isfrozen(bases) and table.isfrozen(Routing.prefixes))
		for service, prefix in Tests.prefixes do
			check(Routing.prefixes[service] == prefix)
			check(origins[service] == Routing.gatewayUrl and bases[service] == Routing.gatewayUrl .. prefix)
		end
		local options: { [string]: Config.ServiceConfig } =
			{ data = { baseUrl = "https://DIRECT.example:0443/" }, config = {} }
		local customOrigins, customBases =
			Config.resolve({ gatewayUrl = "https://GATEWAY.example:8443/", services = options })
		check(customOrigins.data == "https://direct.example" and customBases.data == customOrigins.data)
		check(customBases.config == "https://gateway.example:8443/remote-config-service")
		options.data.baseUrl = "https://changed.example"
		check(customBases.data == "https://direct.example")
		check(bases.data == "https://lb1.blox-api.com/data-service")
	end)

	test("invalid URLs and removed hosts option fail before runtime or credential access", function()
		local invalid: { any } = {
			"",
			false,
			1,
			{},
			"http://secret.invalid",
			"https://secret.invalid/path",
			"https://secret.invalid?token=hidden",
			"https://secret.invalid#hidden",
			"https://user:hidden@secret.invalid",
			"https://secret.invalid\r\nHeader: hidden",
			"https://secret.invalid:0",
			"https://secret.invalid:65536",
			"https://secret.invalid//",
			"https://secret.invalid\\hidden",
			" https://secret.invalid",
			"//secret.invalid",
		}
		for _, value in invalid do
			for _, config in { { gatewayUrl = value }, { services = { data = { baseUrl = value } } } } do
				local ok, message = pcall(SDK.new, config :: any)
				check(not ok and string.find(tostring(message), "HTTPS", 1, true))
				check(not string.find(tostring(message), "hidden", 1, true))
				check(not string.find(tostring(message), "secret.invalid", 1, true))
			end
		end
		local badConfigs: { any } = {
			{ hosts = { data = "https://direct.example" } },
			{ services = false },
			{ services = { missing = {} } },
			{ services = { data = false } },
			{ services = { data = { baseURL = "https://direct.example" } } },
		}
		for _, config in badConfigs do
			local ok, message = pcall(SDK.new, config :: any)
			check(not ok and not string.find(tostring(message), "Roblox", 1, true))
		end
	end)

	test("health covers all nine prefixes with custom gateways and direct-host exceptions", function()
		local policies: { SDK.Config } = {
			{},
			{ gatewayUrl = "https://gateway.example/" },
			{
				gatewayUrl = "https://gateway.example",
				services = { config = { baseUrl = "https://direct.example/" } },
			},
		}
		for index, config in policies do
			local s = Scheduler.new()
			local seen: { [string]: boolean } = {}
			config.runtime = s.runtime
			config.backend = function(request: Core.HttpRequest): Core.HttpResponse
				check(request.Method == "GET" and not seen[request.Url])
				seen[request.Url] = true
				return {
					StatusCode = 200,
					Headers = {},
					Body = s.json({ status = "UP", service = "test", timestamp = "now" }),
				}
			end
			local c = SDK.new(config)
			s.run(function()
				local results = c:health()
				for service, prefix in Tests.prefixes do
					check(results[service].result.ok)
					local base = if index == 1 then "https://lb1.blox-api.com" else "https://gateway.example"
					local url = if index == 3 and service == "config"
						then "https://direct.example/health"
						else base .. prefix .. "/health"
					check(seen[url])
				end
			end)
			check(c:metrics().attempts == 9)
			c:destroy()
		end
	end)

	test("audit list, config snapshot and economy grant use exact gateway URLs", function()
		local s = Scheduler.new()
		local urls: { string } = {}
		local methods: { string } = {}
		local fake = Fake.new(s.runtime, {
			{ body = s.json({ items = SDK.array({}) }) },
			{ body = s.json({ version = 1, entries = {}, flags = SDK.array({}), maintenance = false }) },
			{ body = s.json({ entries = SDK.array({}), replayed = false }) },
		})
		local c = SDK.new({
			runtime = s.runtime,
			backend = function(request: Core.HttpRequest): Core.HttpResponse
				table.insert(urls, request.Url)
				table.insert(methods, request.Method)
				return fake.backend(request)
			end,
			userSession = {},
		})
		s.run(function()
			check(c.audit:list().ok)
			check(c:withUniverse(123).config:snapshot().ok)
			check(c:withUniverse(123).economy:grant({
				path = { userId = 7 },
				body = { currency = "COIN", amount = "100", reason = "reward" },
			}).ok)
		end)
		check(urls[1] == "https://lb1.blox-api.com/audit-service/api/audit/events" and methods[1] == "GET")
		check(
			urls[2] == "https://lb1.blox-api.com/remote-config-service/api/config/universes/123/snapshot"
				and methods[2] == "GET"
		)
		check(
			urls[3] == "https://lb1.blox-api.com/economy-service/api/economy/universes/123/users/7/grant"
				and methods[3] == "POST"
		)
	end)

	test("automatic session refresh and logout respect gateway and direct auth overrides", function()
		for _, direct in { false, true } do
			local s = Scheduler.new()
			local store = Session.memoryStore()
			store.set({ accessToken = "old", refreshToken = "synthetic", expiresAt = 1700000001 })
			local urls: { string } = {}
			local fake = Fake.new(s.runtime, {
				{ body = s.json({ accessToken = "new", refreshToken = "rotated", expiresIn = 3600 }) },
				{ body = s.json({}) },
				{ body = s.json({ message = "ok" }) },
			})
			local c = SDK.new({
				runtime = s.runtime,
				gatewayUrl = "https://gateway.example",
				services = if direct then { auth = { baseUrl = "https://direct.example" } } else nil,
				userSession = { store = store },
				backend = function(request: Core.HttpRequest): Core.HttpResponse
					table.insert(urls, request.Url)
					return fake.backend(request)
				end,
			})
			s.run(function()
				check(c:withUniverse(123).data:getSchemaDefaults().ok)
				check(c:logout().ok)
			end)
			local authBase = if direct
				then "https://direct.example"
				else "https://gateway.example/auth-service"
			check(urls[1] == authBase .. "/api/auth/refresh")
			check(
				urls[2] == "https://gateway.example/data-service/api/universes/schema/defaults?universeId=123"
			)
			check(urls[3] == authBase .. "/api/auth/logout" and store.get() == nil)
		end
	end)

	test("gateway shares concurrency across prefixes but direct origins remain independent", function()
		local s = Scheduler.new()
		local body = s.json({ status = "UP" })
		local fake = Fake.new(s.runtime, { { delay = 0.1, body = body }, { body = body } })
		local c = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			concurrency = 1,
			queueCapacity = 0,
			services = { codes = { baseUrl = "https://direct.example" } },
		})
		s.run(function()
			s.runtime.spawn(function()
				check(c.data:healthProxy().ok)
			end)
			s.runtime.wait(0.01)
			local blocked = c.party:healthProxy()
			check(not blocked.ok and blocked.error.kind == "RateLimited")
			check(c.codes:healthProxy().ok)
		end)
		check(fake.count() == 2)
	end)

	test("gateway breaker is shared across services without blocking a direct origin", function()
		local s = Scheduler.new()
		local steps: { Fake.Step } = {}
		for _ = 1, 5 do
			table.insert(steps, { status = 503 })
		end
		table.insert(steps, { body = s.json({ status = "UP" }) })
		local fake = Fake.new(s.runtime, steps)
		local c = SDK.new({
			runtime = s.runtime,
			backend = fake.backend,
			retries = 0,
			services = { codes = { baseUrl = "https://direct.example" } },
		})
		s.run(function()
			for _ = 1, 5 do
				check(not c.data:healthProxy().ok)
			end
			local blocked = c.party:healthProxy()
			check(not blocked.ok and blocked.error.kind == "CircuitOpen")
			check(c.codes:healthProxy().ok)
		end)
		check(fake.count() == 6)
	end)
end
return table.freeze(Tests)
