--!strict
--!native
--!optimize 2
local Bucket = {}
export type Bucket = {
	tokens: number,
	capacity: number,
	rate: number,
	last: number,
	reserve: number,
	limit: number,
	history: { number },
	head: number,
	count: number,
	requests: { number },
}
--- Construct a monotonic token bucket with a critical-traffic reserve.
function Bucket.new(capacity: number, rate: number, reserve: number, now: number): Bucket
	return {
		tokens = capacity,
		capacity = capacity,
		rate = rate,
		last = now,
		reserve = reserve,
		limit = math.min(499, math.max(1, math.floor(rate * 60))),
		history = {},
		head = 1,
		count = 0,
		requests = {},
	}
end
--- Read the rolling-minute usage without consuming a token; expire old ring entries.
function Bucket.used(self: Bucket, now: number): number
	while self.count > 0 and now - self.history[self.head] >= 60 do
		self.head = self.head % self.limit + 1
		self.count -= 1
	end
	return self.count
end
--- Consume a token or return the time until admission; never borrow from the reserve for bulk.
function Bucket.take(self: Bucket, now: number, critical: boolean): number
	self.tokens = math.min(self.capacity, self.tokens + math.max(0, now - self.last) * self.rate)
	self.last = now
	-- Token bursts alone can exceed a minute's quota. A bounded ring also caps every rolling minute.
	Bucket.used(self, now)
	if self.count >= self.limit then
		return math.max(0.000001, self.history[self.head] + 60 - now)
	end
	local floor = if critical then 0 else self.reserve
	if self.tokens >= floor + 1 then
		self.tokens -= 1
		self.history[(self.head + self.count - 1) % self.limit + 1] = now
		self.count += 1
		return 0
	end
	return (floor + 1 - self.tokens) / self.rate
end
--- Admit physical HTTP only when both the rolling-second and rolling-minute budgets allow it.
function Bucket.http(self: Bucket, now: number): number
	while #self.requests > 0 and now - self.requests[1] >= 1 do
		table.remove(self.requests, 1)
	end
	if #self.requests >= 8 then
		return math.max(0.000001, self.requests[1] + 1 - now)
	end
	local waitFor = Bucket.take(self, now, true)
	if waitFor == 0 then
		table.insert(self.requests, now)
	end
	return waitFor
end
return table.freeze(Bucket)
