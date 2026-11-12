--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Endpoints = require("../src/Core/Endpoints")
local Scheduler = require("./Scheduler")
local Decode = require("../src/Core/JsonDecode")
local Json = require("../src/Core/Json")
local Batcher = require("../src/Core/Batcher")
local Bucket = require("../src/Core/TokenBucket")
type Op = {
	id: string,
	service: string,
	method: string,
	path: string,
	query: { [string]: string }?,
	body: any,
	headers: { [string]: string },
	sequence: string?,
}
type Envelope = { ops: { Op } }
--- Fail a named batch invariant without exposing request data.
local function check(value: unknown, label: string?)
	assert(value, label or "Batch invariant failed")
end
--- Parse and assert the only permitted native HTTP target and both envelope limits.
local function envelope(request: Core.HttpRequest): Envelope
	check(
		request.Url == "https://batch.invalid/batch-service/api/batch" and request.Method == "POST",
		"Direct HTTP forbidden"
	)
	check(request.Body and #request.Body <= 1024 * 1024)
	local value = Decode.decode(request.Body :: string) :: Envelope
	check(#value.ops >= 1 and #value.ops <= 100)
	for _, op in value.ops do
		check(not string.find(op.path, "-service", 1, true))
		check(op.headers.Authorization == nil)
		if op.body ~= nil then
			check(#Json.encode(op.body) <= 256 * 1024)
		end
	end
	return value
end
--- Return valid results in reverse order to exercise ID routing rather than positional routing.
local function response(
	ops: { Op },
	choose: ((Op) -> (number, unknown, { [string]: string }?))?
): Core.HttpResponse
	local results: { any } = {}
	for i = #ops, 1, -1 do
		local op = ops[i]
		local status, body, headers = 200, { status = op.id } :: unknown, nil :: { [string]: string }?
		if choose then
			status, body, headers = choose(op)
		end
		table.insert(results, {
			id = op.id,
			status = status,
			body = if body == nil then Json.null else body,
			headers = headers or {},
		})
	end
	return {
		StatusCode = 200,
		Headers = {},
		Body = Json.encode({ results = Json.array(results), serverTimeMs = 1 }),
	}
end
--- Create an isolated real pipeline over a batch-only mock boundary.
local function client(s: Scheduler.Scheduler, backend: Core.Backend, options: SDK.Config?): SDK.Client
	local config: SDK.Config = options or {}
	config.runtime = s.runtime
	config.backend = backend
	config.gatewayUrl = "https://batch.invalid"
	config.profileSync = { enabled = false }
	config.key = "bsa_" .. string.rep("a", 8) .. "_" .. string.rep("b", 43)
	config.universeId = 123
	return SDK.new(config)
end
--- Issue independent health calls, avoiding the optional identical-GET singleflight optimization.
local function health(c: SDK.Client, options: Core.CallOptions?): Core.Result<any>
	local opts: Core.CallOptions = options or {}
	if not opts.signal then
		opts.signal = { cancelled = false }
	end
	return c.fields:healthProxy(nil, opts)
end
--- Register end-to-end timing, capacity, protocol, retry and lifecycle tests with no network.
return function(test: (string, () -> ()) -> ())
	test("batch ticks coalesce calls, skip idle ticks and route shuffled IDs", function()
		local s = Scheduler.new()
		local times: { number } = {}
		local c = client(s, function(request)
			local batch = envelope(request)
			check(request.Headers.Authorization ~= nil)
			table.insert(times, s.time())
			check(#batch.ops == 60)
			return response(batch.ops)
		end)
		local count = 0
		s.run(function()
			s.runtime.wait(2)
			check(#times == 0)
			for i = 1, 60 do
				s.runtime.spawn(function()
					local result = health(c)
					check(result.ok and result.value.status == tostring(i), "Misrouted operation")
					count += 1
				end)
			end
			s.runtime.wait(0.49)
			check(#times == 0 and count == 0)
			s.runtime.wait(0.1)
			check(count == 60 and times[1] == 2.5)
			s.runtime.wait(2)
			check(#times == 1)
			c:destroy()
		end)
	end)

	test("batch interval minimum and 100-op FIFO overflow", function()
		local s = Scheduler.new()
		local sizes: { number } = {}
		local times: { number } = {}
		local c = client(s, function(request)
			local batch = envelope(request)
			table.insert(sizes, #batch.ops)
			check(batch.ops[1].id == tostring((#sizes - 1) * 100 + 1), "Overflow lost FIFO order")
			table.insert(times, s.time())
			return response(batch.ops)
		end, { batch = { intervalSeconds = 0.25 } })
		local done = 0
		s.run(function()
			for _ = 1, 205 do
				s.runtime.spawn(function()
					check(health(c).ok)
					done += 1
				end)
			end
			s.runtime.wait(0.8)
			check(done == 205 and sizes[1] == 100 and sizes[2] == 100 and sizes[3] == 5)
			check(times[1] == 0.25 and times[2] == 0.5 and times[3] == 0.75)
			c:destroy()
		end)
		for _, interval in { 0, 0.249, math.huge, 0 / 0 } do
			check(not pcall(client, s, function(_r: Core.HttpRequest): Core.HttpResponse
				error("Unexpected HTTP")
			end, { batch = { intervalSeconds = interval } }))
		end
	end)

	test("batch critical then bulk then low priority with stable FIFO lanes", function()
		local s = Scheduler.new()
		local c = client(s, function(request)
			local ops = envelope(request).ops
			local expected = { "3", "5", "2", "4", "1", "6" }
			for i, op in ops do
				check(op.id == expected[i])
			end
			return response(ops)
		end)
		s.run(function()
			for _, priority in { "low", "bulk", "critical", "bulk", "critical", "low" } do
				s.runtime.spawn(function()
					check(health(c, { priority = priority :: any }).ok)
				end)
			end
		end)
	end)

	test("batch byte splitting measures encoded UTF8 envelope and rejects oversized bodies", function()
		local s = Scheduler.new()
		local sizes: { number } = {}
		local batch = Batcher.new(s.runtime, function(request)
			local ops = envelope(request).ops
			table.insert(sizes, #ops)
			return response(ops)
		end, "https://batch.invalid/batch-service/api/batch", 0.5, 10000, Bucket.new(15, 450 / 60, 0, 0))
		local auth: Core.AuthProvider = {
			kind = "none",
			apply = function(_h) end,
			onUnauthorized = function()
				return false
			end,
		}
		s.run(function()
			for _ = 1, 5 do
				check(
					Batcher.enqueue(
						batch,
						Endpoints["fields.healthProxy"],
						"/health",
						{},
						Json.encode(string.rep("é", 130000)),
						nil,
						10,
						nil,
						auth,
						nil
					)
				)
			end
			s.runtime.wait(1.1)
			check(sizes[1] == 4 and sizes[2] == 1)
			Batcher.destroy(batch)
		end)
		local sent = 0
		local c = client(s, function(request)
			sent += 1
			return response(envelope(request).ops)
		end)
		s.run(function()
			local result = c.fields:transaction({
				path = { userId = 7 },
				body = {
					ops = { { field = "Score", op = "SET", value = string.rep("x", 256 * 1024) } },
					reason = "test",
				},
			})
			check(not result.ok and result.error.kind == "Validation" and sent == 0)
		end)
	end)

	test("per-op retries keep player sequence blocked and retain idempotency keys", function()
		local s = Scheduler.new()
		local seen: { Op } = {}
		local times: { number } = {}
		local c = client(s, function(request)
			local ops = envelope(request).ops
			check(#ops == 1)
			table.insert(seen, ops[1])
			table.insert(times, s.time())
			return response(ops, function(_op)
				if #seen == 1 then
					return 503, {}, { ["Retry-After"] = "2" }
				end
				return 204, nil, nil
			end)
		end, { retryRatio = 1 })
		local finished = 0
		s.run(function()
			for i = 1, 2 do
				s.runtime.spawn(function()
					local result = c.fields:transaction({
						path = { userId = 7 },
						body = { ops = { { field = "Score", op = "SET", value = i } }, reason = "test" },
					})
					check(result.ok)
					finished += 1
				end)
			end
		end)
		check(finished == 2 and #seen == 3 and seen[1].sequence == "universe:123:player:7")
		check(seen[2].sequence == seen[1].sequence and seen[3].sequence == seen[1].sequence)
		check(seen[1].body.idempotencyKey == seen[2].body.idempotencyKey and seen[3].body.ops[1].value == 2)
		check(times[2] - times[1] >= 2 and times[3] > times[2])
	end)

	test("per-op errors are isolated, conditional ETags survive and query is separate", function()
		local s = Scheduler.new()
		local c = client(s, function(request)
			return response(envelope(request).ops, function(op)
				if op.path == "/health" then
					return 403, { code = "denied" }, nil
				end
				check(
					op.path == "/api/fields/universes/123/runtime/snapshot"
						and op.headers["If-None-Match"] == '"before"'
				)
				return 304, nil, { ETag = '"after"' }
			end)
		end)
		s.run(function()
			s.runtime.spawn(function()
				local result = health(c)
				check(not result.ok and result.error.kind == "Forbidden")
			end)
			local result = c.fields:runtimeSnapshot({ etag = '"before"' })
			check(result.ok and result.status == 304 and result.etag == '"after"')
		end)
		local c2 = client(s, function(request)
			local op = envelope(request).ops[1]
			check(not string.find(op.path, "?", 1, true) and op.query and op.query.batchId == "a /?é")
			return response({ op }, function(_op)
				return 204, nil, nil
			end)
		end)
		s.run(function()
			check(c2.codes:list({ batchId = "a /?é" }).ok)
		end)
	end)

	test("whole-batch auth failures fail every caller without service fallback", function()
		for _, status in { 400, 401, 403 } do
			local s = Scheduler.new()
			local sent = 0
			local c = client(s, function(request)
				check(#envelope(request).ops == 3)
				sent += 1
				return { StatusCode = status, Headers = {}, Body = "" }
			end)
			s.run(function()
				for _ = 1, 3 do
					s.runtime.spawn(function()
						local result = health(c)
						check(not result.ok and result.error.status == status)
					end)
				end
			end)
			check(sent == 1)
		end
	end)

	test("whole-batch 429 pauses all work honoring Retry-After plus jitter", function()
		local s = Scheduler.new()
		local times: { number } = {}
		local c = client(s, function(request)
			local ops = envelope(request).ops
			table.insert(times, s.time())
			if #times == 1 then
				return { StatusCode = 429, Headers = { ["Retry-After"] = "2" }, Body = "" }
			end
			return response(ops)
		end, { retryRatio = 1 })
		s.run(function()
			s.runtime.spawn(function()
				check(health(c).ok)
			end)
			s.runtime.wait(0.7)
			check(health(c).ok)
		end)
		check(#times == 2 and times[2] - times[1] >= 2.25)
	end)

	test("busy ticks skip dispatch even after timeout, retaining native accounting", function()
		local s = Scheduler.new()
		local active, maximum = 0, 0
		local times: { number } = {}
		local c = client(s, function(request)
			local ops = envelope(request).ops
			active += 1
			maximum = math.max(maximum, active)
			table.insert(times, s.time())
			if #times == 1 then
				s.runtime.wait(1.2)
			end
			active -= 1
			return response(ops)
		end)
		local signal: Core.Signal = { cancelled = false }
		s.run(function()
			s.runtime.spawn(function()
				local result = health(c, { timeout = 0.6, signal = signal })
				check(not result.ok and result.error.kind == "Timeout" and signal.inFlight == 1)
			end)
			s.runtime.wait(0.7)
			check(health(c).ok)
			check(signal.inFlight == 0)
		end)
		check(maximum == 1 and times[1] == 0.5 and times[2] == 2)
	end)

	test("queue cancellation and enqueue deadlines dispatch nothing, destroy cancels waiters", function()
		local s = Scheduler.new()
		local sent = 0
		local c = client(s, function(request)
			sent += 1
			return response(envelope(request).ops)
		end)
		s.run(function()
			local signal: Core.Signal = { cancelled = false }
			s.runtime.spawn(function()
				local result = health(c, { signal = signal })
				check(not result.ok and result.error.kind == "Cancelled")
			end)
			s.runtime.delay(0.1, function()
				signal.cancelled = true
			end)
			local result = health(c, { timeout = 0.2 })
			check(not result.ok and result.error.kind == "Timeout")
			s.runtime.wait(0.5)
			check(sent == 0)
			s.runtime.spawn(function()
				local value = health(c)
				check(not value.ok and value.error.kind == "Cancelled")
			end)
			s.runtime.wait(0.1)
			c:destroy()
		end)
		check(sent == 0)
	end)

	test("malformed result envelopes reject atomically and per-endpoint schemas still validate", function()
		for _, mode in { "duplicate", "missing", "unknown", "schema" } do
			local s = Scheduler.new()
			local c = client(s, function(request)
				local ops = envelope(request).ops
				if mode == "schema" then
					return response(ops, function(_op)
						return 200, {}, nil
					end)
				end
				local id = if mode == "unknown" then "unknown" else ops[1].id
				local results = { { id = id, status = 200, headers = {}, body = { status = "UP" } } }
				if mode ~= "missing" then
					table.insert(results, results[1])
				end
				return {
					StatusCode = 200,
					Headers = {},
					Body = Json.encode({ results = results, serverTimeMs = 1 }),
				}
			end, { retries = 0 })
			s.run(function()
				for _ = 1, 2 do
					s.runtime.spawn(function()
						local result = health(c)
						check(not result.ok and result.error.kind == "Network")
					end)
				end
			end)
		end
	end)
	test("health coalesces all eight services and maps leaderboard singular", function()
		local s = Scheduler.new()
		local calls = 0
		local c = client(s, function(request)
			local ops = envelope(request).ops
			check(#ops == 8)
			local services: { [string]: boolean } = {}
			for _, op in ops do
				check(op.path == "/health")
				services[op.service] = true
			end
			for _, service in
				{ "fields", "leaderboard", "codes", "matchmaking", "party", "audit", "platform", "auth" }
			do
				check(services[service])
			end
			calls += 1
			return response(ops)
		end)
		s.run(function()
			for _, report in c:health() do
				check(report.result.ok)
			end
		end)
		check(calls == 1)
	end)

	test("physical limiter charges one admission for many ops and caps later ticks", function()
		local s = Scheduler.new()
		local times: { number } = {}
		local c = client(s, function(request)
			local ops = envelope(request).ops
			table.insert(times, s.time())
			check(#ops == (if #times == 1 then 20 else 1))
			return response(ops)
		end, { requestsPerMinute = 1, timeout = 70 })
		s.run(function()
			for _ = 1, 20 do
				s.runtime.spawn(function()
					check(health(c).ok)
				end)
			end
			s.runtime.wait(0.6)
			check(c._state.bucket.count == 1)
			check(health(c).ok)
		end)
		check(#times == 2 and times[2] - times[1] >= 60)
	end)

	test("in-flight cancellation isolates other callers and retains the physical slot", function()
		local s = Scheduler.new()
		local c = client(s, function(request)
			local ops = envelope(request).ops
			check(#ops == 2)
			s.runtime.wait(1)
			return response(ops)
		end)
		local signal: Core.Signal = { cancelled = false }
		s.run(function()
			s.runtime.spawn(function()
				local result = health(c, { signal = signal })
				check(not result.ok and result.error.kind == "Cancelled" and signal.inFlight == 1)
			end)
			s.runtime.delay(0.7, function()
				signal.cancelled = true
			end)
			check(health(c).ok)
			check(signal.inFlight == 0)
		end)
	end)

	test("multi-subject ordering overlaps player lanes but independent players coalesce", function()
		local s = Scheduler.new()
		local counts: { number } = {}
		local c = client(s, function(request)
			local ops = envelope(request).ops
			table.insert(counts, #ops)
			for _, op in ops do
				check(op.sequence ~= nil)
			end
			return response(ops, function(_op)
				return 204, nil, nil
			end)
		end)
		s.run(function()
			s.runtime.spawn(function()
				check(c.fields:multiTransaction({
					ops = {
						{ subject = 7, field = "Score", op = "SET", value = 1 },
						{ subject = 8, field = "Score", op = "SET", value = 1 },
					},
					reason = "test",
				}).ok)
			end)
			for _, user in { 8, 9 } do
				s.runtime.spawn(function()
					check(c.fields:transaction({
						path = { userId = user },
						body = { ops = { { field = "Score", op = "SET", value = 2 } }, reason = "test" },
					}).ok)
				end)
			end
		end)
		check(counts[1] == 2 and counts[2] == 1)
	end)
	test("cancelled interior player waiter unlinks without disturbing dependent calls", function()
		local s = Scheduler.new()
		local values: { number } = {}
		local c = client(s, function(request)
			local ops = envelope(request).ops
			check(#ops == 1)
			table.insert(values, ops[1].body.ops[1].value)
			if #values == 1 then
				s.runtime.wait(1)
			end
			return response(ops, function(_op)
				return 204, nil, nil
			end)
		end)
		local signal: Core.Signal = { cancelled = false }
		s.run(function()
			for value = 1, 3 do
				s.runtime.spawn(function()
					local result = c.fields:transaction({
						path = { userId = 7 },
						body = {
							ops = { { field = "Score", op = "SET", value = value } },
							reason = "test",
						},
					}, if value == 2 then { signal = signal } else nil)
					if value == 2 then
						check(not result.ok and result.error.kind == "Cancelled")
					else
						check(result.ok)
					end
				end)
			end
			s.runtime.delay(0.7, function()
				signal.cancelled = true
			end)
		end)
		check(#values == 2 and values[1] == 1 and values[2] == 3 and next(c._state.orders) == nil)
	end)
	test("paused ticks reclaim expired queue payloads without another HTTP request", function()
		local s = Scheduler.new()
		local sent = 0
		local c = client(s, function(request)
			envelope(request)
			sent += 1
			return { StatusCode = 429, Headers = { ["Retry-After"] = "30" }, Body = "" }
		end, { retries = 0 })
		s.run(function()
			local throttled = health(c)
			check(not throttled.ok and throttled.error.status == 429)
			local expired = health(c, { timeout = 0.1 })
			check(not expired.ok and expired.error.kind == "Timeout")
			s.runtime.wait(0.6)
			check(#c._state.batcher.queue == 0 and c._state.batcher.pausedUntil > s.time() and sent == 1)
			c:destroy()
		end)
	end)
end
