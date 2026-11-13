--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Bucket = require("../src/Core/TokenBucket")
local Errors = require("../src/Core/Errors")
local Fake = require("../src/Testing/FakeBackend")
local Scheduler = require("./Scheduler")
local Json = require("../src/Core/Json")
--- Fail named release regressions without logging inputs.
local function check(value: unknown)
	assert(value, "Release regression")
end
--- Construct a fully offline client without sharing budgets across test cases.
local function client(
	s: Scheduler.Scheduler,
	steps: { Fake.Step },
	config: SDK.Config?
): (SDK.Client, Fake.Fake)
	local fake = Fake.new(s.runtime, steps)
	local options: SDK.Config = config or {}
	options.runtime = s.runtime
	options.backend = fake.backend
	options.key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
	options.universeId = 123
	return SDK.new(options), fake
end
--- Register v1 public-contract, sliding-budget, observer and transport regressions.
return function(test: (string, () -> ()) -> ())
	test("1.0 root surface excludes internal modules and has stable error codes", function()
		local root: any = SDK
		check(
			SDK.version == "10.0.0"
				and root.endpoints == nil
				and root.Testing == nil
				and root.Fields == nil
				and root.Auth == nil
		)
		for _, kind in { "Local", "Network", "Timeout", "Cancelled", "RateLimited", "Server" } do
			local result = Errors.make(kind :: Core.ErrorKind, "test", 0, "Safe")
			check(
				not result.ok
					and result.error.code
						== "sdk_" .. string.lower((string.gsub(kind, "(%l)(%u)", "%1_%2")))
			)
		end
		local authError = Errors.domain(401, "auth.login", 1, { errorCode = "INVALID_CREDENTIALS" })
		check(not authError.ok and authError.error.code == "invalid_credentials")
		local s = Scheduler.new()
		local c = client(s, {})
		check((c.fields :: any).Schema == nil and (c.fields :: any).LoadProfile == nil)
		check(not pcall(SDK.new, {
			runtime = s.runtime,
			backend = function(_request: Core.HttpRequest): Core.HttpResponse
				error("No HTTP")
			end,
			requestsPerMinute = 500,
		}))
	end)
	test("API-key refusals keep their stable codes and the Retry-After delay", function()
		local limited: any =
			Errors.domain(429, "fields.schema", 1, { code = "key_rate_limited", message = "do not expose" })
		check(
			not limited.ok
				and limited.error.kind == "RateLimited"
				and limited.error.code == "key_rate_limited"
		)
		check(limited.error.message == "HTTP request failed")
		local denied: any = Errors.domain(
			403,
			"fields.player.get",
			1,
			{ code = "scope_denied", field = "Secret.A", allowedPrefixes = { "Currency." } }
		)
		check(not denied.ok and denied.error.kind == "Forbidden" and denied.error.code == "scope_denied")
		check(denied.error.message == "HTTP request failed" and denied.error.field == nil)
		local configDenied: any =
			Errors.domain(403, "config.get", 1, { code = "scope_denied", namespace = "secrets" })
		check(configDenied.error.kind == "Forbidden" and configDenied.error.code == "scope_denied")
		local perOp: any = Errors.domain(
			409,
			"fields.batch",
			1,
			{ errors = { { code = "scope_denied", opIndex = 2, field = "Secret.A", path = {} } } }
		)
		check(perOp.error.errors ~= nil and perOp.error.errors[1].code == "scope_denied")
	end)
	test("rolling minute cap includes bursts, retries, idle restarts and boundary eviction", function()
		local bucket = Bucket.new(500, 500 / 60, 0, 0)
		for _ = 1, 499 do
			check(Bucket.take(bucket, 0, true) == 0)
		end
		check(Bucket.take(bucket, 0, true) == 60)
		check(Bucket.take(bucket, 59.99, true) > 0)
		check(Bucket.take(bucket, 60, true) == 0)
		local admissions: { number } = {}
		for tick = 1, 20000 do
			local now = tick / 20
			if Bucket.take(bucket, now + 60, true) == 0 then
				table.insert(admissions, now + 60)
				if #admissions >= 500 then
					check(admissions[#admissions] - admissions[#admissions - 499] >= 60)
				end
			end
		end
		check(#bucket.history <= 499)
	end)
	test("per-call timeout covers queue and wire time and malformed options never dispatch", function()
		local s = Scheduler.new()
		local c, f = client(s, { { delay = 0.2, status = 204 } })
		s.run(function()
			local result = c.fields:schema(nil, { timeout = 0.05 })
			check(not result.ok and result.error.code == "sdk_timeout")
			for _, options in
				{ { timeout = 0 }, { timeout = math.huge }, { idempotencyKey = false } } :: { any }
			do
				check(not c.fields:schema(nil, options :: any).ok)
			end
		end)
		check(f.count() == 0)
	end)
	test("common idempotency option maps service key, snapshots inputs and rejects conflicts", function()
		local s = Scheduler.new()
		local c, f = client(s, {
			{
				status = 204,
				check = function(request)
					check(string.find(request.Body :: string, '"submissionId":"release-key"', 1, true) ~= nil)
				end,
			},
		})
		local body = { userId = 7, score = 1 }
		s.run(function()
			check(
				c.leaderboards:submit(
					{ path = { name = "smoke" }, body = body },
					{ idempotencyKey = "release-key" }
				).ok
			)
			local conflict = c.leaderboards:submit(
				{ path = { name = "smoke" }, body = { userId = 7, score = 1, submissionId = "other" } },
				{ idempotencyKey = "release-key" }
			)
			check(not conflict.ok and conflict.error.kind == "Validation")
			check(not c.fields:schema(nil, { idempotencyKey = "unsupported" }).ok)
		end)
		check((body :: any).submissionId == nil and f.count() == 1)
	end)
	test("pluggable logger receives only immutable allowlisted metadata and isolates failures", function()
		local s = Scheduler.new()
		local logs, hooks = 0, 0
		local c = client(s, { { status = 503, body = "SECRET_BACKEND_PAYLOAD" } }, {
			logger = function(name, event)
				check(name == "onRequest" or name == "onResponse")
				check(table.isfrozen(event))
				check(not string.find(Json.encode(event), "SECRET", 1, true))
				logs += 1
				error("SECRET_LOGGER_FAILURE")
			end,
			hooks = {
				onResponse = function()
					hooks += 1
				end,
			},
		})
		s.run(function()
			local result = c.fields:schema()
			check(not result.ok and result.error.body == "[redacted]")
		end)
		check(logs == 2 and hooks == 1)
	end)
	test("bounded admission surfaces backpressure as a Result, never an unbounded queue", function()
		local s = Scheduler.new()
		local c, f = client(s, { { delay = 0.2, status = 204 } }, { concurrency = 1, queueCapacity = 1 })
		local rejected = false
		s.run(function()
			s.runtime.spawn(function()
				c.fields:schema(nil, { signal = { cancelled = false } })
			end)
			s.runtime.wait(0.01)
			local result = c.fields:schema(nil, { signal = { cancelled = false } })
			rejected = not result.ok and result.error.code == "sdk_rate_limited"
		end)
		check(rejected and f.count() == 1)
	end)
end
