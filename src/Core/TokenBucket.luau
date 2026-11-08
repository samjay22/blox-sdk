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
	}
end
--- Consume a token or return the time until admission; never borrow from the reserve for bulk.
function Bucket.take(self: Bucket, now: number, critical: boolean): number
	self.tokens = math.min(self.capacity, self.tokens + math.max(0, now - self.last) * self.rate)
	self.last = now
	-- Token bursts alone can exceed a minute's quota. A bounded ring also caps every rolling minute.
	while self.count > 0 and now - self.history[self.head] >= 60 do
		self.head = self.head % self.limit + 1
		self.count -= 1
	end
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
return table.freeze(Bucket)
