--!strict
-- Exercise the actual runner with a mock Lune net boundary; never contact a host.
local requireLune: (string) -> any = require
local fs = requireLune("@lune/fs")
local compiler = requireLune("@lune/luau")
local SDK = require("../src/BloxSDK")
local Json = require("../src/Core/Json")
local Decode = require("../src/Core/JsonDecode")
local Errors = require("../src/Core/Errors")
local Scheduler = require("./Scheduler")
local V = require("./FixtureVectors").rotations
local source: string = fs.readFile("tools/live-smoke.luau")
local key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
local baseEnv = {
	BLOX_BASE_URL = "https://smoke.invalid",
	BLOX_API_KEY = key,
	BLOX_UNIVERSE_ID = "123",
	BLOX_PLAYER_ID = "7",
}
--- Run with fixed fixtures, capture only check labels and verify refusal/failure exit codes.
local function run(
	args: { string },
	env: { [string]: string },
	failNet: boolean?,
	healthStatus: number?,
	healthService: string?
): (number?, number, { string }, number)
	local requests, redeems = 0, 0
	local scheduler = Scheduler.new()
	local lines: { string } = {}
	local exitCode: number? = nil
	local process = {
		args = args,
		env = env,
		exit = function(code: number): never
			exitCode = code
			error("MOCK_EXIT", 0)
		end,
	}
	local function operationRequest(request: any): any
		requests += 1
		assert(request.url:sub(1, 22) == "https://smoke.invalid/", "Wrong mock origin")
		assert(
			request.headers.Authorization == nil or request.headers.Authorization == "Bearer " .. key,
			"Missing explicit auth"
		)
		if failNet then
			error("PRIVATE_WIRE_EXCEPTION")
		end
		local url = request.url
		if
			healthStatus
			and string.find(url, "/health", 1, true)
			and string.find(url, "/" .. (healthService or "party") .. "-service/", 1, true)
		then
			return {
				statusCode = healthStatus,
				body = '{"message":"PRIVATE_SCOPE_DETAIL"}',
				headers = { ["set-cookie"] = { "PRIVATE_COOKIE" } },
			}
		end
		local payload: any = nil
		if string.find(url, "/changes/batch", 1, true) then
			local body = Decode.decode(request.body) :: any
			local items = {}
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
			payload = { items = items, pollAfterMs = 5000 }
		elseif string.find(url, "/schema", 1, true) then
			payload = {
				universeId = 123,
				schemaVersion = 1,
				definitions = {
					{
						universeId = 123,
						id = "Smoke.Counter",
						type = { kind = "int", min = 0 },
						status = "ACTIVE",
						history = "LEDGER",
						writeLevel = "READ_WRITE",
						definitionVersion = 1,
						description = "",
						createdAt = "now",
						updatedAt = "now",
					},
				},
			}
		elseif string.find(url, "/sessions/acquire", 1, true) then
			payload = {
				items = {
					{
						userId = 7,
						status = "granted",
						epoch = 1,
						expiresAt = "2030-01-01T00:00:00Z",
						snapshot = {
							seq = 0,
							fields = { Smoke = { Counter = 0 } },
							versions = { ["Smoke.Counter"] = 0 },
						},
					},
				},
			}
		elseif string.find(url, "/sessions/poll", 1, true) then
			payload = { cursor = 0, reset = false, more = false, players = Json.array({}) }
		elseif string.find(url, "/sessions/release", 1, true) then
			payload = { items = { { userId = 7, status = "released" } } }
		elseif string.find(url, "/commits", 1, true) then
			local body = Decode.decode(request.body) :: any
			assert(
				#body.players == 1
					and #body.players[1].ops == 2
					and body.players[1].ops[1].delta == 1
					and body.players[1].ops[2].delta == -1,
				"Smoke commit must be atomic net-zero deltas"
			)
			payload = {
				commitId = body.commitId,
				items = {
					{
						userId = 7,
						status = "committed",
						seq = 0,
						versions = { ["Smoke.Counter"] = 0 },
						expiresAt = "2030-01-01T00:00:00Z",
					},
				},
			}
		elseif string.find(url, "/document", 1, true) then
			payload = {
				userId = 7,
				seq = 0,
				data = { Smoke = { Counter = 0 } },
				versions = {
					["Smoke.Counter"] = 0,
				},
			}
		elseif string.find(url, "/transactions", 1, true) then
			local body = Decode.decode(request.body) :: any
			assert(
				body.ops[1].value == 0 and body.conditions[1].expectedVersion == 0,
				"Smoke must preserve value with optimistic concurrency"
			)
			payload = {
				txId = "smoke-transaction",
				replayed = false,
				results = Json.array({}),
				seq = { ["7"] = 1 },
			}
		elseif string.find(url, "/active", 1, true) then
			payload = V.active
		elseif string.find(url, "/preview", 1, true) then
			payload = { V.roll.results[1] }
		elseif string.find(url, "/redeem", 1, true) then
			redeems += 1
			payload = {
				redemptionId = 1,
				codeId = 1,
				code = "SMOKE",
				robloxUserId = 7,
				replayed = false,
				redeemedAt = "now",
				transaction = {
					txId = "smoke-redeem",
					replayed = false,
					results = Json.array({}),
					seq = { ["7"] = 1 },
				},
			}
		end
		assert(
			not string.find(url, "/roll", 1, true)
				and not string.find(url, "/claim", 1, true)
				and request.method ~= "DELETE",
			"Unsafe smoke mutation"
		)
		return {
			statusCode = if payload then 200 else 204,
			body = if payload then Json.encode(payload) else "",
			headers = { ["set-cookie"] = { "PRIVATE_COOKIE", "PRIVATE_COOKIE_TWO" } },
		}
	end
	local net = {
		request = function(request: any): any
			assert(
				request.url == "https://smoke.invalid/batch-service/api/batch" and request.method == "POST",
				"Smoke bypassed BatchService"
			)
			local batch = Decode.decode(request.body) :: any
			assert(#batch.ops >= 1 and #batch.ops <= 100, "Invalid smoke batch")
			local results = {}
			for _, op in batch.ops do
				local prefix = if op.service == "codes" then "code" else op.service
				local headers = table.clone(request.headers)
				for name, value in op.headers do
					headers[name] = value
				end
				local returned = operationRequest({
					url = "https://smoke.invalid/" .. prefix .. "-service" .. op.path,
					method = op.method,
					headers = headers,
					body = if op.body == nil then nil else Json.encode(op.body),
				})
				local normalized = {}
				for name, value in returned.headers do
					normalized[name] = if type(value) == "table" then table.concat(value, ", ") else value
				end
				table.insert(results, {
					id = op.id,
					status = returned.statusCode,
					headers = normalized,
					body = if returned.body == "" then Json.null else Decode.decode(returned.body),
				})
			end
			return {
				statusCode = 200,
				body = Json.encode({ results = results, serverTimeMs = 1 }),
				headers = { ["set-cookie"] = { "PRIVATE_COOKIE", "PRIVATE_COOKIE_TWO" } },
			}
		end,
	}
	local envRequire = function(path: string): any
		if path == "@lune/process" then
			return process
		end
		if path == "@lune/net" then
			return net
		end
		if path == "@lune/task" then
			-- Virtual timers avoid wall-clock waits and Lune retaining cancelled sleeps.
			return {
				wait = function(seconds: number): number
					scheduler.runtime.wait(seconds)
					return seconds
				end,
				spawn = scheduler.runtime.spawn,
				delay = scheduler.runtime.delay,
				cancel = scheduler.runtime.cancel,
			}
		end
		if path == "./LuneTypes" then
			return {}
		end
		if path == "../src/BloxSDK" then
			return SDK
		end
		if path == "../src/Types/Core" then
			return {}
		end
		if path == "../src/Core/Json" then
			return Json
		end
		if path == "../src/Core/JsonDecode" then
			return Decode
		end
		if path == "../src/Core/Errors" then
			return Errors
		end
		error("Unexpected smoke import")
	end
	local callback = compiler.load(source, { debugName = "@mock-live-smoke" })
	setfenv(
		callback,
		setmetatable({
			require = envRequire,
			os = { clock = scheduler.runtime.now, time = scheduler.runtime.unix },
			print = function(line: string)
				table.insert(lines, line)
			end,
		}, { __index = getfenv() }) :: any
	)
	scheduler.run(function()
		local ok, err = pcall(callback)
		assert(not ok and err == "MOCK_EXIT", "Unexpected runner exception")
	end)
	for _, line in lines do
		assert(
			not string.find(line, key, 1, true) and not string.find(line, "PRIVATE", 1, true),
			"Runner leaked sensitive text"
		)
	end
	return exitCode, requests, lines, redeems
end
local code, requests = run({}, baseEnv)
assert(code == 2 and requests == 0, "Missing consent must refuse")
for name in baseEnv do
	local env = table.clone(baseEnv)
	env[name] = nil
	local status, count = run({ "--yes-live" }, env)
	assert(status == 2 and count == 0, "Every required variable must refuse before HTTP")
end
local code2, requests2, lines, redeemed = run({ "--yes-live" }, baseEnv)
for _, line in lines do
	if line:sub(1, 4) == "FAIL" then
		print(line)
	end
end
assert(code2 == 0 and requests2 >= 20 and redeemed == 0, "Configured mock smoke must pass all checks")
for _, label in { "session acquire snapshot", "session buffered commit", "session flush and release" } do
	assert(table.find(lines, "PASS " .. label), "Missing session smoke check")
end
local withCode = table.clone(baseEnv)
withCode.BLOX_CODE = "DISPOSABLE"
local code3, _, _, redeemed3 = run({ "--yes-live" }, withCode)
assert(code3 == 0 and redeemed3 == 1, "Code redemption must be explicitly enabled")
local code4, _, failed = run({ "--yes-live" }, baseEnv, true)
assert(code4 == 1 and #failed >= 10, "Network failure must fail checks without leaking exceptions")
assert(table.find(failed, "FAIL auth read: sdk_network"), "FAIL must include the safe SDK code")
for _, service in { "party", "audit", "platform" } do
	for _, status in { 401, 403 } do
		local skippedCode, _, skipped = run({ "--yes-live" }, baseEnv, false, status, service)
		assert(skippedCode == 0, "Expected out-of-scope health denial must not fail the run")
		local found = false
		for _, line in skipped do
			if line:sub(1, #("SKIP " .. service .. " read:")) == "SKIP " .. service .. " read:" then
				found = true
			end
		end
		assert(found, "Expected health denial must explain the skipped scope")
	end
end
for _, scenario in
	{
		{ service = "fields", status = 403 },
		{ service = "auth", status = 401 },
		{ service = "platform", status = 500 },
	}
do
	local failedCode = run({ "--yes-live" }, baseEnv, false, scenario.status, scenario.service)
	assert(failedCode == 1, "In-scope auth and real service failures must never skip")
end
print(
	"PASS actual live smoke runner: consent/env refusals, all mock reads/safe writes, optional code, network redaction"
)
