--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Helpers = require(script.Parent.Parent.Fields.Client)
local Scope = require(script.Parent.Parent.Fields.Scope)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Errors = require(script.Parent.Parent.Core.Errors)
local Json = require(script.Parent.Parent.Core.Json)
local Instant = require(script.Parent.Parent.Core.Instant)
local Rotations = {}
Rotations.__index = Rotations
--- One thing that can be active. `data` is whatever JSON object you saved with the item.
export type Item = { id: string, data: { [string]: any }? }
--- The items active from `startsAt` until `endsAt` (Unix seconds).
export type Period = { items: { Item }, startsAt: number, endsAt: number }
--- What a game reads: the active period, flattened, plus the one after it.
export type Current = {
	key: string,
	version: number,
	items: { Item },
	startsAt: number,
	endsAt: number,
	next: Period,
}
export type Watch = { disconnect: (Watch) -> (), lastError: Core.BloxError? }
export type Client = typeof(setmetatable({} :: { _scope: Scope.Scope }, Rotations))
-- A cached answer is reused until the period ends, but never for longer than this, so edits show up.
local MAX_AGE = 60
local RETRY = 15
type Entry = { value: Current, fetchedAt: number }
local caches: { [Helpers.State]: { [string]: Entry } } = setmetatable({}, { __mode = "k" }) :: any
--- Bind rotations to this client's universe without starting background work.
function Rotations.new(state: Helpers.State, universe: string | number): Client
	return setmetatable({ _scope = Scope.new(state, universe) }, Rotations)
end
--- Check the published name grammar before building a route.
function Rotations.validName(name: unknown): boolean
	return type(name) == "string" and #name <= 100 and string.match(name, "^[A-Za-z][A-Za-z0-9_.%-]*$") ~= nil
end
--- Convert a wire period (ISO instants) to Unix seconds; nil if the server sent something unusable.
local function period(wire: Wire.RotationPeriod): Period?
	local startsAt, endsAt = Instant.unix(wire.startsAt), Instant.unix(wire.endsAt)
	if startsAt == nil or endsAt == nil then
		return nil
	end
	local items: { Item } = {}
	for _, item in wire.items do
		local data = item.data
		table.insert(
			items,
			{ id = item.id, data = if data == nil or data == Json.null then nil else data :: any }
		)
	end
	return { items = table.freeze(items), startsAt = startsAt, endsAt = endsAt }
end
--- Fetch fresh from the server and convert to the friendly shape.
local function fetch(self: Client, name: string, options: Core.CallOptions?): Core.Result<Current>
	local result: Core.Result<Wire.RotationCurrent> =
		Scope.call(self._scope, "fields.currentRotation", { path = { key = name } }, options)
	if not result.ok then
		return result
	end
	local now, nextPeriod = period(result.value.current), period(result.value.next)
	if now == nil or nextPeriod == nil then
		return Errors.make("Validation", "fields.currentRotation", 0, "Invalid rotation response")
	end
	return {
		ok = true,
		value = table.freeze({
			key = result.value.key,
			version = result.value.version,
			items = now.items,
			startsAt = now.startsAt,
			endsAt = now.endsAt,
			next = table.freeze(nextPeriod),
		}),
	}
end
--- What is active now and what comes next. Cached until the period ends (at most 60 seconds), so call
--- it as often as you like; if a refresh fails while the cached period is still running, that answer is kept.
function Rotations.current(self: Client, name: string, options: Core.CallOptions?): Core.Result<Current>
	if not Rotations.validName(name) then
		return System.failure("invalid_request")
	end
	local state = self._scope.state
	local cache = caches[state]
	if cache == nil then
		cache = {}
		caches[state] = cache
	end
	local slot = tostring(self._scope.universe) .. "/" .. name
	local entry = (cache :: { [string]: Entry })[slot]
	local now = state.runtime.unix()
	if entry and now < entry.value.endsAt and now - entry.fetchedAt < MAX_AGE then
		return { ok = true, value = entry.value }
	end
	local result = fetch(self, name, options)
	if result.ok then
		(cache :: { [string]: Entry })[slot] = { value = result.value, fetchedAt = now }
		return result
	end
	if entry and now < entry.value.endsAt and result.error.kind ~= "Cancelled" then
		return { ok = true, value = entry.value }
	end
	return result
end
--- Seconds until the active items change (display only; never negative).
function Rotations.secondsLeft(self: Client, current: Current): number
	return math.max(0, current.endsAt - self._scope.state.runtime.unix())
end
--- The next `count` periods (default 5, at most 50), starting with the active one. Not cached.
function Rotations.upcoming(
	self: Client,
	name: string,
	count: number?,
	options: Core.CallOptions?
): Core.Result<{ Period }>
	if
		not Rotations.validName(name)
		or count ~= nil and (type(count) ~= "number" or count % 1 ~= 0 or count < 1 or count > 50)
	then
		return System.failure("invalid_request")
	end
	local result: Core.Result<Wire.RotationSchedule> = Scope.call(
		self._scope,
		"fields.rotationSchedule",
		{ path = { key = name }, query = { count = count } },
		options
	)
	if not result.ok then
		return result
	end
	local periods: { Period } = {}
	for _, wire in result.value.periods do
		local converted = period(wire)
		if converted == nil then
			return Errors.make("Validation", "fields.rotationSchedule", 0, "Invalid rotation response")
		end
		table.insert(periods, table.freeze(converted))
	end
	return { ok = true, value = table.freeze(periods) }
end
--- Call `callback(current)` now and again whenever the active items change (a new period starts or the
--- list is edited). Stops with `watch:disconnect()` or when the client is destroyed.
function Rotations.watch(self: Client, name: string, callback: (Current) -> ()): Watch
	assert(Rotations.validName(name) and type(callback) == "function", "Invalid rotation watch")
	local state = self._scope.state
	assert(not state.closed, "Client is closed")
	local runtime = state.runtime
	local connected = true
	local generation = 0
	local timer: thread? = nil
	local last: string? = nil
	local watch: Watch
	local function disconnect()
		if not connected then
			return
		end
		connected = false
		generation += 1
		if timer then
			runtime.cancel(timer)
			timer = nil
		end
		state.cleanups[disconnect] = nil
	end
	local function check()
		timer = nil
		if not connected or state.closed then
			return
		end
		generation += 1
		local expected = generation
		runtime.spawn(function()
			local result = self:current(name)
			if not connected or state.closed or generation ~= expected then
				return
			end
			if not result.ok then
				watch.lastError = result.error
				timer = runtime.delay(RETRY + runtime.random() * 5, check)
				return
			end
			watch.lastError = nil
			local value = result.value
			local identity = tostring(value.version) .. ":" .. tostring(value.startsAt)
			if identity ~= last then
				last = identity
				pcall(callback, value)
			end
			local wait = math.clamp(value.endsAt - runtime.unix(), 1, MAX_AGE)
			timer = runtime.delay(wait + 0.05 + runtime.random() * 0.2, check)
		end)
	end
	watch = {
		disconnect = function(_self: Watch)
			disconnect()
		end,
		lastError = nil,
	}
	state.cleanups[disconnect] = true
	state.onUse()
	check()
	return watch
end
return table.freeze(Rotations)
