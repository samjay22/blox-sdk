--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Types = require(script.Parent.Parent.Types.Audit)
local Config = require(script.Parent.Parent.Core.Config)
local Idempotency = require(script.Parent.Parent.Core.Idempotency)
local Validation = require(script.Parent.Parent.Core.Validation)
local Errors = require(script.Parent.Parent.Core.Errors)
local Writer = {}
Writer.__index = Writer
export type Options = { batchSize: number?, interval: number?, capacity: number? }
export type Writer = typeof(setmetatable(
	{} :: {
		_runtime: Core.Runtime,
		_send: ({ Types.EventInput }, Core.CallOptions) -> Core.Result<Types.Receipt>,
		_queue: { Types.EventInput },
		_head: number,
		_size: number,
		_capacity: number,
		_interval: number,
		_busy: boolean,
		_closed: boolean,
		_destroyed: boolean,
		_timer: thread?,
		_signal: Core.Signal,
		lastError: Core.BloxError?,
	},
	Writer
))
--- Schedule a periodic flush; no work starts just by requiring the module.
local function schedule(self: Writer)
	self._timer = self._runtime.delay(self._interval, function()
		self._timer = nil
		if self._closed or self._destroyed then
			return
		end
		self:flush()
		schedule(self)
	end)
end
--- Create a bounded queue with a single cooperative background sender.
function Writer.new(
	runtime: Core.Runtime,
	send: ({ Types.EventInput }, Core.CallOptions) -> Core.Result<Types.Receipt>,
	options: Options?
): Writer
	local opts: Options = options or {}
	local size = Config.number(opts.batchSize, 100, 1, 500, "batchSize", true)
	local self: Writer = setmetatable({
		_runtime = runtime,
		_send = send,
		_queue = {},
		_head = 1,
		_size = size,
		_capacity = Config.number(opts.capacity, 2000, size, 100000, "capacity", true),
		_interval = Config.number(opts.interval, 5, 0.01, 3600, "interval"),
		_busy = false,
		_closed = false,
		_destroyed = false,
		_signal = { cancelled = false },
		_timer = nil,
		lastError = nil,
	}, Writer)
	schedule(self)
	return self
end
--- Count queued and in-flight events; unacknowledged events remain in the queue.
function Writer.pending(self: Writer): number
	return #self._queue - self._head + 1
end
--- Enqueue without yielding; return false on invalid input, closed admission or capacity exhaustion.
function Writer.enqueue(self: Writer, event: Types.EventInput): boolean
	if self._closed or self._destroyed or self:pending() >= self._capacity then
		return false
	end
	local ok, item = pcall(Idempotency.copy, event)
	if not ok or type(item) ~= "table" then
		return false
	end
	if item.idemKey == nil then
		item.idemKey = Idempotency.key(self._runtime)
	end
	if not Validation.body("audit.append", item) then
		return false
	end
	table.insert(self._queue, item)
	if self:pending() >= self._size then
		self:flush()
	end
	return true
end
--- Start a serialized nonblocking flush; retain a failed batch and its keys for the next flush.
function Writer.flush(self: Writer)
	if self._busy or self._destroyed or self:pending() == 0 then
		return
	end
	self._busy = true
	self._runtime.spawn(function()
		while not self._destroyed and self:pending() > 0 do
			local count = math.min(self._size, self:pending())
			local batch: { Types.EventInput } = table.create(count)
			for i = 1, count do
				batch[i] = self._queue[self._head + i - 1]
			end
			local ok, response =
				pcall(self._send, batch, { priority = "bulk", signal = self._signal } :: Core.CallOptions)
			local result: Core.Result<Types.Receipt> = if ok
				then response
				else Errors.make("Local", "audit.batch", 0, "Batch sender failed")
			if result.ok and result.value.accepted + result.value.duplicate ~= count then
				result = Errors.make("Validation", "audit.batch", 0, "Incomplete batch acknowledgement")
			end
			if not result.ok then
				self.lastError = result.error
				break
			end
			self.lastError = nil
			self._head += count
			-- Compact only after acknowledgement, never lose a concurrent enqueue.
			if self._head > #self._queue then
				table.clear(self._queue)
				self._head = 1
			elseif self._head > self._capacity then
				self._queue = table.move(self._queue, self._head, #self._queue, 1, {})
				self._head = 1
			end
		end
		self._busy = false
	end)
end
--- Stop queue admission and cooperatively drain within the shutdown budget; failure remains observable.
function Writer.close(self: Writer, timeout: number?): boolean
	local budget = Config.number(timeout, 20, 0, 300, "writer timeout")
	self._closed = true
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
	local deadline = self._runtime.now() + budget
	self:flush()
	while self._busy and self._runtime.now() < deadline do
		self._runtime.wait(0.01)
	end
	return self:pending() == 0
end
--- Cancel pending transport and timers; unsent queue data is not persisted by this in-memory helper.
function Writer.destroy(self: Writer)
	self._destroyed = true
	self._closed = true
	self._signal.cancelled = true
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
end
return table.freeze(Writer)
