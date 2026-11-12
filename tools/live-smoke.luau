--!strict
-- Real writes are intentionally opt-in. Never print environment values or raw exceptions.
local Lune = require("./LuneTypes")
local requireLune: (string) -> any = require
local process = requireLune("@lune/process") :: Lune.Process
if #process.args ~= 1 or process.args[1] ~= "--yes-live" then
	print("FAIL preflight: explicit --yes-live required; no requests sent")
	process.exit(2)
end
for _, name in { "BLOX_BASE_URL", "BLOX_API_KEY", "BLOX_UNIVERSE_ID", "BLOX_PLAYER_ID" } do
	if not process.env[name] or process.env[name] == "" then
		print("FAIL preflight: missing " .. name .. "; no requests sent")
		process.exit(2)
	end
end
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Json = require("../src/Core/Json")
local JsonDecode = require("../src/Core/JsonDecode")
local Errors = require("../src/Core/Errors")
local net = requireLune("@lune/net") :: Lune.Net
local task = requireLune("@lune/task") :: Lune.Task
local universe, player = tonumber(process.env.BLOX_UNIVERSE_ID), tonumber(process.env.BLOX_PLAYER_ID)
if
	not universe
	or not player
	or universe % 1 ~= 0
	or player % 1 ~= 0
	or universe <= 0
	or player <= 0
	or universe > 9007199254740991
	or player > 9007199254740991
then
	print("FAIL preflight: IDs must be positive exact integers; no requests sent")
	process.exit(2)
end
local universeId = universe :: number
local playerId = player :: number
local runtime: Core.Runtime = {
	now = os.clock,
	unix = os.time,
	random = math.random,
	wait = function(seconds)
		task.wait(seconds)
	end,
	spawn = task.spawn,
	delay = task.delay,
	cancel = task.cancel,
	encode = Json.encode,
	decode = JsonDecode.decode,
}
--- Adapt the pinned Lune HTTP client to the SDK's single transport boundary.
local function backend(request: Core.HttpRequest): Core.HttpResponse
	local headers: { [string]: string } = {}
	for name, value in request.Headers do
		assert(type(value) == "string", "Lune requires explicit string credentials")
		headers[name] = value
	end
	local response =
		net.request({ url = request.Url, method = request.Method, headers = headers, body = request.Body })
	-- Lune returns repeated response headers as arrays; HttpService (and the SDK contract) uses strings.
	local responseHeaders: { [string]: string } = {}
	for name, value in response.headers :: { [string]: any } do
		responseHeaders[name] = if type(value) == "table" then table.concat(value, ", ") else tostring(value)
	end
	return { StatusCode = response.statusCode, Body = response.body, Headers = responseHeaders }
end
local smokeServer = "sdk-smoke-" .. tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local constructed, value = pcall(SDK.new, {
	sessions = { serverId = smokeServer, kickOnFailure = false, kickOnLeaseLost = false },
	gatewayUrl = process.env.BLOX_BASE_URL,
	key = process.env.BLOX_API_KEY,
	universeId = universeId,
	runtime = runtime,
	backend = backend,
	timeout = 10,
	retries = 0,
})
if not constructed then
	print("FAIL preflight: invalid SDK configuration; no requests sent")
	process.exit(2)
end
local client = value :: SDK.Client
local failures = 0
--- Log SDK machine codes only; never payloads, credentials or exception messages.
local function check(name: string, callback: () -> Core.Result<any>, scopeReason: string?)
	local ok, result = pcall(callback)
	if not ok then
		print("FAIL " .. name .. ": sdk_local")
		failures += 1
		return
	end
	if result.ok then
		print("PASS " .. name)
	elseif scopeReason and (result.error.status == 401 or result.error.status == 403) then
		print("SKIP " .. name .. ": " .. scopeReason .. " (" .. result.error.code .. ")")
	else
		print("FAIL " .. name .. ": " .. result.error.code)
		failures += 1
	end
end
local healthScopes: { [string]: string } = {
	party = "health endpoint requires user identity or PartyService scope unavailable to this machine key",
	audit = "AuditService health is outside this machine key's scope",
	platform = "Platform health requires user identity or scope unavailable to this machine key",
}
-- Only known out-of-scope health reads may skip; ordinary auth failures still fail.
for _, service in { "auth", "matchmaking", "party", "codes", "audit", "leaderboards", "fields", "platform" } do
	check(service .. " read", function()
		return (client :: any)[service]:healthProxy() :: Core.Result<any>
	end, healthScopes[service])
end
check("fields schema", function()
	return client.fields:schema()
end)
check("matchmaking status", function()
	return client.matchmaking:getPlayerQueueStatus({
		query = { userId = tostring(playerId), universeId = tostring(universeId) },
	})
end)
check("party list", function()
	return client.party:getAllParties()
end, "listing every party is admin-only (ADMIN or UNIVERSE_ADMIN); game-server keys are refused")
check("codes search", function()
	return client.codes:list({ size = 1 })
end)
check("audit list", function()
	return client.audit:list({ query = { limit = 1 } })
end, "key is not scoped for AuditService")
check("leaderboard list", function()
	return client.leaderboards:list({ query = { limit = 1 } })
end)
local sessionFailure = false
client.LeaseLost:connect(function(_event)
	sessionFailure = true
end)
client.CommitRejected:connect(function(_event)
	sessionFailure = true
end)
local smokeProfile: SDK.Profile? = nil
check("session acquire snapshot", function()
	local loaded = client.fields:loadProfile(playerId)
	if loaded.ok then
		smokeProfile = loaded.value
	end
	return loaded
end)
if smokeProfile then
	local profile = smokeProfile
	local field = process.env.BLOX_FIELD_ID or "Smoke.Counter"
	check("critical immediate transaction", function()
		local current = profile:tryGet(field)
		if not current.ok then
			return current
		end
		-- Preserve existing immediate/precondition semantics, independent of buffered commits.
		return profile
			:immediate()
			:set(field, current.value)
			:expect(field, { version = profile.versions[field] })
			:reason("SDK live smoke")
			:commit()
	end)
	check("session buffered commit", function()
		-- Use a disposable numeric smoke field. Opposing deltas are atomic, net-zero and commute
		-- with concurrent external ADDs; the intermediate increment must satisfy its schema.
		local added = profile:mutate({
			{ field = field, op = "ADD", delta = 1 },
			{ field = field, op = "ADD", delta = -1 },
		})
		if not added.ok then
			return added
		end
		local deadline = os.clock() + 20
		while
			os.clock() < deadline
			and (#profile._buffer > 0 or #profile._sent > 0 or profile._recovering)
			and not profile._closed
		do
			task.wait(0.05)
		end
		if
			sessionFailure
			or profile._closed
			or #profile._buffer > 0
			or #profile._sent > 0
			or profile._recovering
			or profile._stale
		then
			return Errors.make("Timeout", "fields.commitSession", 0, "Commit not confirmed")
		end
		return { ok = true, value = true }
	end)
	check("session flush and release", function()
		return if profile:release()
			then { ok = true, value = true }
			else Errors.make("Timeout", "fields.releaseSessions", 0, "Release not confirmed")
	end)
end
check("leaderboard submit", function()
	return client.leaderboards:submit({
		path = { name = process.env.BLOX_BOARD or "sdk_smoke" },
		body = { userId = playerId, score = 0 },
	})
end)
local rotation = process.env.BLOX_ROTATION or "weather"
check("rotation get", function()
	return client.fields:rotations():get(rotation)
end)
check("rotation watch once", function()
	local observed = false
	local watch = client.fields:rotations():watch(rotation, function()
		observed = true
	end)
	local deadline = os.clock() + 10
	while not observed and not watch.lastError and os.clock() < deadline do
		task.wait(0.01)
	end
	watch:disconnect()
	return if observed
		then { ok = true, value = true }
		else {
			ok = false,
			error = watch.lastError or {
				kind = "Timeout",
				code = "sdk_timeout",
				message = "Watch timed out",
				endpoint = "fields.activeRotation",
				attempts = 1,
			},
		}
end)
check("generator preview", function()
	return client.fields:generators():preview(process.env.BLOX_GENERATOR or "card_pack", playerId, 1)
end)
if process.env.BLOX_CODE and process.env.BLOX_CODE ~= "" then
	check("code redeem", function()
		local outcome = client.codes:redeem(playerId, process.env.BLOX_CODE)
		if outcome.status == "retry" or outcome.status == "failed" then
			return { ok = false, error = outcome.error }
		end
		if outcome.status ~= "granted" and outcome.status ~= "already_redeemed" then
			return {
				ok = false,
				error = {
					kind = "Conflict",
					message = "Code refused",
					endpoint = "codes.redeem",
					attempts = 1,
					code = "sdk_" .. outcome.status,
				},
			}
		end
		return { ok = true, value = outcome.status }
	end)
else
	print("SKIP code redeem: BLOX_CODE not supplied")
end
check("final flush", function()
	return if client:flush(20)
		then { ok = true, value = true }
		else Errors.make("Timeout", "fields.commitSession", 0, "Flush not confirmed")
end)
client:destroy()
process.exit(if failures == 0 then 0 else 1)
