--!strict
local SDK = require("../src/BloxSDK")
local Universe = require("../src/Core/Universe")
local Json = require("../src/Core/Json")
local JsonDecode = require("../src/Core/JsonDecode")
local Scheduler = require("./Scheduler")
local Fake = require("../src/Testing/FakeBackend")
--- Assert behavior without including request data in failures.
local function check(value: unknown, message: string?)
	assert(value, message or ("Universe regression at " .. tostring(debug.info(2, "l"))))
end
local queued = {
	success = true,
	message = "",
	resolvedGameMode = "ranked",
	userIds = { "7" },
	bannedUserIds = Json.array({}),
}
--- Build a service-account client whose only statement of its universe is the constructor.
local function client(s: Scheduler.Scheduler, steps: { Fake.Step }): SDK.Client
	return SDK.new({
		runtime = s.runtime,
		backend = Fake.new(s.runtime, steps).backend,
		profileSync = { enabled = false },
		key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43),
		universeId = 123,
	})
end
return function(test: (string, () -> ()) -> ())
	test("Request bodies take their universe from the client in the wire type they declare", function()
		local s = Scheduler.new()
		local bodies: { any } = {}
		local step: Fake.Step = {
			body = s.json(queued),
			check = function(request)
				table.insert(bodies, JsonDecode.decode(request.Body :: string))
			end,
		}
		local c = client(s, { step, step })
		s.run(function()
			check(c.matchmaking:joinQueue({ robloxUserIds = { "7" }, gameModeName = "ranked" }).ok)
			check(c.matchmaking:joinQueue({
				robloxUniverseId = "123",
				robloxUserIds = { "7" },
				gameModeName = "ranked",
			}).ok)
			c:destroy()
		end)
		check(#bodies == 2 and bodies[1].robloxUniverseId == "123" and bodies[2].robloxUniverseId == "123")
	end)
	test("Users resolve from IDs and from anything carrying UserId", function()
		check(Universe.user(7) == 7 and Universe.user({ UserId = 7 }) == 7)
		check(
			Universe.user({ UserId = "7" }) == nil and Universe.user("7") == nil and Universe.user(nil) == nil
		)
		local s = Scheduler.new()
		local c = client(s, {})
		s.run(function()
			local missing = c.fields:loadProfile({ UserId = 0 })
			check(not missing.ok and missing.error.code == "invalid_request")
			check(not pcall(function()
				return c.fields:transactionBuilder("7" :: any)
			end))
			c:destroy()
		end)
	end)
	test("Helpers refuse to guess a universe the client was never given", function()
		local s = Scheduler.new()
		local c = SDK.new({
			runtime = s.runtime,
			backend = Fake.new(s.runtime, {}).backend,
			profileSync = { enabled = false },
		})
		check(not pcall(function()
			return c.fields:schemaCache()
		end))
		check((pcall(function()
			return c:withUniverse(9).fields:schemaCache()
		end)))
		c:destroy()
	end)
end
