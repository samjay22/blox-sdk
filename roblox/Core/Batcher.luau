--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Bucket = require(script.Parent.Parent.Core.TokenBucket)
local Retry = require(script.Parent.Parent.Core.Retry)
local Json = require(script.Parent.Parent.Core.Json)
local Decode = require(script.Parent.Parent.Core.JsonDecode)
local Batcher = {}
export type Reply = { status: number, headers: { [string]: string }, body: unknown }
export type Entry = {
	id: string,
	wire: string,
	priority: number,
	deadline: number,
	signal: Types.Signal?,
	auth: Types.AuthProvider,
	reply: Reply?,
	done: boolean,
	sent: boolean,
}
export type State = {
	runtime: Types.Runtime,
	backend: Types.Backend,
	url: string,
	interval: number,
	capacity: number,
	bucket: Bucket.Bucket,
	queue: { Entry },
	timer: thread?,
	inFlight: boolean,
	closed: boolean,
	serial: number,
	pausedUntil: number,
	throttles: number,
	beforeTick: (() -> ())?,
	hasPoll: (() -> boolean)?,
}
--- Allocate the sole physical HTTP boundary; construction starts no timers or requests.
function Batcher.new(
	runtime: Types.Runtime,
	backend: Types.Backend,
	url: string,
	interval: number,
	capacity: number,
	bucket: Bucket.Bucket
): State
	return {
		runtime = runtime,
		backend = backend,
		url = url,
		interval = interval,
		capacity = capacity,
		bucket = bucket,
		queue = {},
		timer = nil,
		inFlight = false,
		closed = false,
		serial = 0,
		pausedUntil = 0,
		throttles = 0,
	}
end
--- Test queued admission without retaining cancelled or expired calls.
local function live(self: State, entry: Entry): boolean
	return not self.closed
		and not entry.done
		and not (entry.signal and entry.signal.cancelled)
		and self.runtime.now() < entry.deadline
end
--- Release native-operation accounting only when the physical batch actually finishes.
local function complete(entry: Entry, reply: Reply?)
	entry.wire = ""
	entry.reply = reply
	entry.done = true
	if entry.sent and entry.signal then
		entry.signal.inFlight = (entry.signal.inFlight or 1) - 1
	end
end
--- Validate the complete envelope before routing any result, rejecting duplicate/missing/unknown IDs.
local function replies(body: string, selected: { Entry }): { [string]: Reply }
	local value = Decode.decode(body) :: any
	assert(
		type(value) == "table" and type(value.results) == "table" and type(value.serverTimeMs) == "number",
		"Invalid batch envelope"
	)
	local expected: { [string]: boolean } = {}
	for _, entry in selected do
		expected[entry.id] = true
	end
	local out: { [string]: Reply } = {}
	assert(#value.results == #selected, "Incomplete batch results")
	for _, item in value.results do
		assert(
			type(item) == "table" and type(item.id) == "string" and expected[item.id] and not out[item.id],
			"Invalid result ID"
		)
		assert(
			type(item.status) == "number"
				and item.status % 1 == 0
				and item.status >= 100
				and item.status <= 599,
			"Invalid operation status"
		)
		assert(type(item.headers) == "table" and item.body ~= nil, "Invalid operation response")
		for name, header in item.headers do
			assert(type(name) == "string" and type(header) == "string", "Invalid operation header")
		end
		out[item.id] = {
			status = item.status,
			headers = item.headers,
			body = if item.body == Json.null then nil else item.body,
		}
	end
	return out
end
--- Reclaim abandoned payloads on busy/paused ticks too, without waiting for native HTTP.
local function prune(self: State)
	local queue: { Entry } = {}
	for _, entry in self.queue do
		if live(self, entry) then
			table.insert(queue, entry)
		else
			complete(entry, nil)
		end
	end
	self.queue = queue
end
--- Send at most one envelope; excess FIFO work and incompatible credentials wait for later ticks.
local function dispatch(self: State)
	if self.closed or self.inFlight or self.runtime.now() < self.pausedUntil then
		return
	end
	prune(self)
	local queue = self.queue
	if #queue == 0 then
		return
	end
	-- Linear stable partition avoids O(n log n) sorting under a saturated queue.
	local ordered: { Entry } = table.create(#queue)
	for priority = 1, 3 do
		for _, entry in queue do
			if entry.priority == priority then
				table.insert(ordered, entry)
			end
		end
	end
	queue = ordered
	local selected: { Entry } = {}
	local wires: { string } = {}
	local remaining: { Entry } = {}
	local size = #'{"ops":[]}'
	local provider = queue[1].auth
	local full = false
	for _, entry in queue do
		local added = #entry.wire + (if #selected == 0 then 0 else 1)
		if full or entry.auth ~= provider or #selected == 100 or size + added > 1024 * 1024 then
			table.insert(remaining, entry)
			-- Never pack around a large head entry: overflow stays FIFO within its priority.
			if entry.auth == provider then
				full = true
			end
		else
			table.insert(selected, entry)
			table.insert(wires, entry.wire)
			size += added
		end
	end
	if #selected == 0 then
		return
	end
	local waitFor = Bucket.http(self.bucket, self.runtime.now())
	if waitFor > 0 then
		self.pausedUntil = self.runtime.now() + waitFor
		return
	end
	self.queue = remaining
	self.inFlight = true
	for _, entry in selected do
		entry.sent = true
		if entry.signal then
			entry.signal.inFlight = (entry.signal.inFlight or 0) + 1
		end
	end
	local headers: Types.Headers = { ["Content-Type"] = "application/json", Accept = "application/json" }
	local ok, response = pcall(function(): Types.HttpResponse
		provider.apply(headers)
		return self.backend({
			Url = self.url,
			Method = "POST",
			Headers = headers,
			Body = '{"ops":[' .. table.concat(wires, ",") .. "]}",
		})
	end)
	table.clear(headers)
	local routed: { [string]: Reply }? = nil
	if ok then
		local valid, parsed = pcall(function(): { [string]: Reply }
			assert(
				type(response.StatusCode) == "number"
					and response.StatusCode % 1 == 0
					and response.StatusCode >= 100
					and response.StatusCode <= 599,
				"Invalid batch status"
			)
			assert(
				type(response.Headers) == "table" and type(response.Body) == "string",
				"Invalid batch response"
			)
			for name, value in response.Headers do
				assert(type(name) == "string" and type(value) == "string", "Invalid batch headers")
			end
			if response.StatusCode == 200 then
				return replies(response.Body, selected)
			end
			assert(response.StatusCode >= 400, "Invalid batch status")
			local out: { [string]: Reply } = {}
			for _, entry in selected do
				out[entry.id] = { status = response.StatusCode, headers = response.Headers, body = nil }
			end
			return out
		end)
		if valid then
			routed = parsed
		end
		if valid and response.StatusCode == 429 then
			self.throttles += 1
			local after: string? = nil
			for name, value in response.Headers do
				if string.lower(name) == "retry-after" then
					after = value
				end
			end
			self.pausedUntil = self.runtime.now()
				+ math.max(
					Retry.after(after, self.runtime.unix()) or 0,
					Retry.backoff(self.throttles, self.runtime.random(), self.interval, 30)
				)
				+ self.runtime.random() * self.interval
		elseif valid then
			self.throttles = 0
		end
	end
	for _, entry in selected do
		complete(entry, if routed then routed[entry.id] else nil)
	end
	self.inFlight = false
end
--- Arm a lazy fixed-cadence tick. Busy ticks are skipped, never flushed immediately on completion.
function Batcher.wake(self: State)
	if self.closed or self.timer then
		return
	end
	self.timer = self.runtime.delay(self.interval, function()
		self.timer = nil
		if self.closed then
			return
		end
		prune(self)
		if not self.inFlight and self.runtime.now() >= self.pausedUntil then
			if self.beforeTick then
				pcall(self.beforeTick)
			end
			-- Producers may spawn yielding pipeline calls; run after their initial enqueue steps.
			self.runtime.delay(0, function()
				dispatch(self)
			end)
		end
		if #self.queue > 0 or self.inFlight or (self.hasPoll and self.hasPoll()) then
			Batcher.wake(self)
		end
	end)
end
--- Encode schema-aware bodies once and reject over-limit operations before queue admission.
function Batcher.enqueue(
	self: State,
	spec: Types.Endpoint,
	path: string,
	headers: Types.Headers,
	body: string?,
	priority: string?,
	deadline: number,
	signal: Types.Signal?,
	auth: Types.AuthProvider,
	sequence: string?
): Entry?
	if self.closed or #self.queue >= self.capacity then
		return nil
	end
	self.serial += 1
	local internal, queryText = string.match(path, "^([^?]+)%??(.*)$")
	local query: { [string]: string } = {}
	for key, value in string.gmatch(queryText or "", "([^&=]+)=([^&]*)") do
		local decoded = string.gsub(value :: string, "%%(%x%x)", function(hex: string): string
			return string.char(tonumber(hex, 16) :: number)
		end)
		query[key :: string] = decoded
	end
	local op: any = {
		id = tostring(self.serial),
		service = if spec.service == "leaderboards" then "leaderboard" else spec.service,
		method = spec.method,
		path = internal,
		headers = headers,
		sequence = sequence,
	}
	if next(query) then
		op.query = query
	end
	local wire = self.runtime.encode(op)
	if body ~= nil then
		wire = string.sub(wire, 1, -2) .. ',"body":' .. body .. "}"
	end
	assert(#wire + #'{"ops":[]}' <= 1024 * 1024, "Operation envelope too large")
	local entry: Entry = {
		id = tostring(self.serial),
		wire = wire,
		priority = if priority == "critical" then 1 elseif priority == "low" then 3 else 2,
		deadline = deadline,
		signal = signal,
		auth = auth,
		done = false,
		sent = false,
	}
	table.insert(self.queue, entry)
	Batcher.wake(self)
	return entry
end
--- Stop future dispatch while native HTTP retains its in-flight accounting until completion.
function Batcher.destroy(self: State)
	self.closed = true
	if self.timer then
		self.runtime.cancel(self.timer)
		self.timer = nil
	end
	for _, entry in self.queue do
		complete(entry, nil)
	end
	table.clear(self.queue)
end
return table.freeze(Batcher)
