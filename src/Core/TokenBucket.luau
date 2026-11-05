--!strict
--!native
--!optimize 2
local Bucket = {}
export type Bucket = { tokens: number, capacity: number, rate: number, last: number, reserve: number }
--- Construct a monotonic token bucket with a critical-traffic reserve.
function Bucket.new(capacity: number, rate: number, reserve: number, now: number): Bucket
	return { tokens = capacity, capacity = capacity, rate = rate, last = now, reserve = reserve }
end
--- Consume a token or return the time until admission; never borrow from the reserve for bulk.
function Bucket.take(self: Bucket, now: number, critical: boolean): number
	self.tokens = math.min(self.capacity, self.tokens + math.max(0, now - self.last) * self.rate)
	self.last = now
	local floor = if critical then 0 else self.reserve
	if self.tokens >= floor + 1 then
		self.tokens -= 1
		return 0
	end
	return (floor + 1 - self.tokens) / self.rate
end
return table.freeze(Bucket)
