--!strict
--!native
--!optimize 2
local Breaker = {}
export type State = {
	state: string,
	generation: number,
	untilTime: number,
	probe: boolean,
	times: { number },
	failed: { boolean },
	cursor: number,
	count: number,
	capacity: number,
	threshold: number,
	window: number,
	cooldown: number,
}
--- Allocate a fixed rolling sample window per host.
function Breaker.new(): State
	return {
		state = "closed",
		generation = 0,
		untilTime = 0,
		probe = false,
		times = table.create(20, 0),
		failed = table.create(20, false),
		cursor = 1,
		count = 0,
		capacity = 20,
		threshold = 5,
		window = 30,
		cooldown = 10,
	}
end
--- Inspect admission without taking a half-open probe or spending rate tokens.
function Breaker.blocked(self: State, now: number): boolean
	return (self.state == "open" and now < self.untilTime) or (self.state == "half-open" and self.probe)
end
--- Permit one half-open probe after cooldown; synchronous and atomic between yields.
function Breaker.allow(self: State, now: number): (boolean, number)
	if self.state == "open" then
		if now < self.untilTime then
			return false, self.generation
		end
		self.state = "half-open"
		self.generation += 1
	end
	if self.state == "half-open" then
		if self.probe then
			return false, self.generation
		end
		self.probe = true
	end
	return true, self.generation
end
--- Record transport/server failures; authorization and validation failures are not outages.
function Breaker.record(self: State, now: number, failed: boolean, generation: number?)
	if generation ~= nil and generation ~= self.generation then
		return
	end
	if self.state == "half-open" then
		self.probe = false
		if failed then
			self.state = "open"
			self.generation += 1
			self.untilTime = now + self.cooldown
		else
			self.state = "closed"
			self.generation += 1
			self.count = 0
			self.cursor = 1
		end
		return
	end
	if self.state == "open" then
		return
	end
	self.times[self.cursor] = now
	self.failed[self.cursor] = failed
	self.cursor = self.cursor % self.capacity + 1
	self.count = math.min(self.count + 1, self.capacity)
	local failures = 0
	for i = 1, self.count do
		if now - self.times[i] <= self.window and self.failed[i] then
			failures += 1
		end
	end
	if failures >= self.threshold then
		self.state = "open"
		self.generation += 1
		self.untilTime = now + self.cooldown
	end
end
return table.freeze(Breaker)
