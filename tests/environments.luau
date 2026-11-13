--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Config = require("../src/Core/Config")
local Errors = require("../src/Core/Errors")
local JsonDecode = require("../src/Core/JsonDecode")
local ServiceAccount = require("../src/Auth/ServiceAccount")
local Universe = require("../src/Core/Universe")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")

--- Assert behavior without including credentials in failure output.
local function check(value: unknown, message: string?)
	assert(value, message or ("Environment regression at " .. tostring(debug.info(2, "l"))))
end
--- Synthetic keys: `a` is prod, `d` is dev. Never real credentials.
local function key(kind: string): string
	return "bs" .. kind .. "_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
end
--- Build an offline client; `studio` injects the Roblox Studio answer.
local function build(s: Scheduler.Scheduler, options: { [string]: any }): SDK.Client
	local config: any = {
		runtime = s.runtime,
		backend = Fake.new(s.runtime, {}).backend,
		profileSync = { enabled = false },
		universeId = 123,
	}
	for name, value in options do
		config[name] = value
	end
	return SDK.new(config :: SDK.Config)
end
--- Run a constructor and return its error text, or nil when it succeeded.
local function refusal(s: Scheduler.Scheduler, options: { [string]: any }): string?
	local ok, err = pcall(function()
		build(s, options):destroy()
	end)
	if ok then
		return nil
	end
	return tostring(err)
end
local function studio(): boolean
	return true
end
local function live(): boolean
	return false
end
--- The echoed dev scope id for universe 123 (123 + 2^60), too large for an exact double.
local echoed = "1152921504606847099"

return function(test: (string, () -> ()) -> ())
	test("both key prefixes are valid and map to their environment", function()
		check(ServiceAccount.valid(key("a")) and ServiceAccount.valid(key("d")))
		check(
			ServiceAccount.environment(key("a")) == "prod" and ServiceAccount.environment(key("d")) == "dev"
		)
		check(ServiceAccount.environment("bsx_" .. string.rep("a", 52)) == nil)
		check(not ServiceAccount.valid("bsx_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)))
		check(not ServiceAccount.valid("bsd_" .. string.rep("a", 8) .. "_" .. string.rep("b", 42)))
		check(not ServiceAccount.valid("bsd_" .. string.rep("a", 8) .. "-" .. string.rep("b", 43)))
	end)
	test("client.environment follows the key prefix", function()
		local s = Scheduler.new()
		local prod = build(s, { key = key("a") })
		local dev = build(s, { key = key("d") })
		check(prod.environment == "prod" and dev.environment == "dev")
		check(dev:withUniverse(123).environment == "dev")
		prod:destroy()
		dev:destroy()
		local session = build(s, { userSession = {} })
		check(session.environment == nil)
		session:destroy()
	end)
	test("unknown key prefixes fail locally with a clear message", function()
		local s = Scheduler.new()
		local err = refusal(s, { key = "bsx_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43) })
		check(err ~= nil and string.find(err, "Unknown API key prefix", 1, true) ~= nil)
		check(string.find(err :: string, "bsx_", 1, true) == nil, "the message never echoes the key")
		local malformed = refusal(s, { key = "bsd_short" })
		check(malformed ~= nil and string.find(malformed, "Unknown API key prefix", 1, true) == nil)
		check(refusal(s, { key = "bsd_short" }) ~= nil and refusal(s, { key = "nope" }) ~= nil)
	end)
	test("a prod key is refused in Studio unless explicitly allowed", function()
		local s = Scheduler.new()
		local err = refusal(s, { key = key("a"), isStudio = studio })
		check(err ~= nil and string.find(err, Errors.prodKeyInStudio, 1, true) == 1)
		check(Errors.prodKeyInStudio == "prod_key_in_studio")
		check(string.find(err :: string, key("a"), 1, true) == nil, "the message never echoes the key")
		check(refusal(s, { key = key("a"), isStudio = studio, allowProdInStudio = true }) == nil)
		check(refusal(s, { key = key("a"), isStudio = live }) == nil)
		check(refusal(s, { key = key("a"), isStudio = studio, allowProdInStudio = false }) ~= nil)
	end)
	test("a dev key works in Studio and in a live server", function()
		local s = Scheduler.new()
		check(refusal(s, { key = key("d"), isStudio = studio }) == nil)
		check(refusal(s, { key = key("d"), isStudio = live }) == nil)
	end)
	test("injected runtimes are not Studio unless isStudio says so", function()
		local s = Scheduler.new()
		check(refusal(s, { key = key("a") }) == nil)
		check(refusal(s, { key = key("a"), isStudio = studio }) ~= nil)
	end)
	test("a custom auth provider that declares prod is refused in Studio", function()
		local s = Scheduler.new()
		local function provider(environment: Core.Environment?): Core.AuthProvider
			return {
				kind = "serviceAccount",
				universeId = 123,
				environment = environment,
				apply = function(_headers) end,
				onUnauthorized = function(_version)
					return false
				end,
			}
		end
		local err = refusal(s, { authProvider = provider("prod"), isStudio = studio })
		check(err ~= nil and string.find(err, "prod_key_in_studio", 1, true) == 1)
		check(refusal(s, { authProvider = provider("dev"), isStudio = studio }) == nil)
		check(refusal(s, { authProvider = provider(nil), isStudio = studio }) == nil)
		local custom = build(s, { authProvider = provider("dev") })
		check(custom.environment == "dev")
		custom:destroy()
	end)
	test("secrets must declare their environment, which a readable key never takes", function()
		local base: any = { secretName = "SYNTHETIC" }
		check(not pcall(Config.validate, base))
		base.environment = "staging"
		check(not pcall(Config.validate, base))
		base.environment = "dev"
		check(pcall(Config.validate, base))
		base.environment = "prod"
		check(pcall(Config.validate, base))
		check(not pcall(Config.validate, { key = key("d"), environment = "dev" } :: any))
		check(not pcall(Config.validate, { key = key("d"), isStudio = true } :: any))
		check(not pcall(Config.validate, { key = key("d"), allowProdInStudio = "yes" } :: any))
	end)
	test("environment error codes are recognized with their kinds and never retried", function()
		local cases: { { status: number, endpoint: string, code: string, kind: string } } = {
			{
				status = 409,
				endpoint = "fields.createDefinition",
				code = "dev_limit_exceeded",
				kind = "Conflict",
			},
			{
				status = 409,
				endpoint = "config.putNamespace",
				code = "dev_limit_exceeded",
				kind = "Conflict",
			},
			{ status = 403, endpoint = "fields.schema", code = "environment_mismatch", kind = "Forbidden" },
			{
				status = 403,
				endpoint = "config.getNamespace",
				code = "environment_mismatch",
				kind = "Forbidden",
			},
			{ status = 400, endpoint = "fields.schema", code = "environment_invalid", kind = "Validation" },
			{
				status = 400,
				endpoint = "config.getNamespace",
				code = "environment_required",
				kind = "Validation",
			},
		}
		for _, case in cases do
			local result =
				Errors.domain(case.status, case.endpoint, 1, { code = case.code, message = "do not expose" })
			check(not result.ok)
			if not result.ok then
				check(result.error.code == case.code and result.error.kind == case.kind)
				check(result.error.message == "HTTP request failed" and result.error.body == "[redacted]")
			end
		end
		local spoof = Errors.domain(403, "fields.schema", 1, { code = "prod_key_in_studio" })
		check(not spoof.ok)
		if not spoof.ok then
			check(spoof.error.code == "sdk_forbidden", "a backend body cannot produce a local code")
		end
		check(Errors.isLocalCode("prod_key_in_studio") and not Errors.isLocalCode("dev_limit_exceeded"))
	end)
	test("dev scope ids decode to the logical universe id", function()
		check(Universe.logicalDigits(echoed) == "123")
		check(Universe.logicalDigits("1152921504606846976") == nil, "2^60 itself is not universe 0")
		check(Universe.logicalDigits("1152921504606846977") == "1")
		check(Universe.logicalDigits("1161928703861587967") == "9007199254740991")
		check(Universe.logicalDigits("1161928703861587968") == nil, "above the safe universe range")
		check(Universe.logicalDigits("123") == nil and Universe.logicalDigits("1152921504606846975") == nil)
		check(Universe.logicalDigits("0123") == nil and Universe.logicalDigits("abc") == nil)
		check(
			Universe.logical(echoed) == "123"
				and Universe.logical("123") == "123"
				and Universe.logical(123) == 123
		)
		check(Universe.isDevScope(echoed) and not Universe.isDevScope("123"))
		local decoded: any =
			JsonDecode.decode('{"universeId":' .. echoed .. ',"robloxUniverseId":"' .. echoed .. '"}')
		check(decoded.universeId == 123 and decoded.robloxUniverseId == "123")
		local nested: any =
			JsonDecode.decode('{"items":[{"universeId":' .. echoed .. ',"n":1}],"universeId":123}')
		check(nested.items[1].universeId == 123 and nested.items[1].n == 1 and nested.universeId == 123)
		local prod: any = JsonDecode.decode('{"universeId":9007199254740991}')
		check(prod.universeId == 9007199254740991)
	end)
	test("only universe members tolerate dev scope ids; other unsafe integers still fail", function()
		check(not pcall(JsonDecode.decode, '{"count":' .. echoed .. "}"))
		check(not pcall(JsonDecode.decode, "[" .. echoed .. "]"))
		check(not pcall(JsonDecode.decode, '{"universeId":9007199254740993}'))
		check(not pcall(JsonDecode.decode, '{"universeId":1161928703861587968}'))
		local text: any = JsonDecode.decode('{"name":"' .. echoed .. '"}')
		check(text.name == echoed, "strings in other members are never rewritten")
	end)
	test("a dev response that echoes the scope id is a success with the logical id", function()
		local s = Scheduler.new()
		local body = '{"success":true,"gameModeName":null,"removedCount":2,"universeId":"' .. echoed .. '"}'
		local c = build(s, {
			key = key("d"),
			backend = Fake.new(s.runtime, { { body = body } }).backend,
		})
		s.run(function()
			local result: any = c.matchmaking:flushQueue()
			check(result.ok and result.value.universeId == "123" and result.value.removedCount == 2)
			c:destroy()
		end)
	end)
end
