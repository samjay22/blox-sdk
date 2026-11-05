--!strict
local Types = require("../Types/Core")
local Cache = {}
export type Entry = { result: Types.Result<any>, expires: number, staleUntil: number }
export type State = { entries: { [string]: Entry }, keys: { string }, cursor: number, maximum: number }
--- Allocate a bounded FIFO cache. Cached payloads are immutable and credential-free by policy.
function Cache.new(maximum: number): State
	return { entries = {}, keys = table.create(maximum), cursor = 1, maximum = maximum }
end
--- Recursively freeze decoded JSON before sharing across callers or flights.
function Cache.freeze(value: any): any
	if type(value) == "table" and not table.isfrozen(value) then
		for _, child in value do
			Cache.freeze(child)
		end
		table.freeze(value)
	end
	return value
end
--- Insert or replace one entry, evicting in bounded O(1) time.
function Cache.put(
	self: State,
	key: string,
	result: Types.Result<any>,
	now: number,
	ttl: number,
	stale: number
)
	if self.maximum == 0 then
		return
	end
	if not self.entries[key] then
		local old = self.keys[self.cursor]
		if old then
			self.entries[old] = nil
		end
		self.keys[self.cursor] = key
		self.cursor = self.cursor % self.maximum + 1
	end
	self.entries[key] = { result = Cache.freeze(result), expires = now + ttl, staleUntil = now + ttl + stale }
end
--- Invalidate all data after writes or lifecycle changes, preventing stale reads after saves.
function Cache.clear(self: State)
	table.clear(self.entries)
	table.clear(self.keys)
	self.cursor = 1
end
return table.freeze(Cache)
