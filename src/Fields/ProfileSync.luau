--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Profile = require("./Profile")
local Schema = require("./Schema")
local Config = require("../Core/Config")
local Endpoints = require("../Core/Endpoints")
local ChangeSignal = require("../Core/ChangeSignal")
local Sync = {}
Sync.__index = Sync
type Registration = { universe: string, invoke: Core.Invoke }
type Reload = { at: number, busy: boolean, attempts: number }
type Group = { universe: string, invoke: Core.Invoke, users: { [number]: { Profile.Profile } } }
export type Sync = typeof(setmetatable(
	{} :: {
		wake: (() -> ())?,
		_runtime: Core.Runtime,
		_enabled: boolean,
		_pollAt: number,
		_concurrency: number,
		_canPoll: () -> boolean,
		_profiles: { [Profile.Profile]: Registration },
		_loads: { [Core.Signal]: number },
		_reloads: { [Profile.Profile]: Reload },
		_schemaPoll: { [Schema.Schema]: number },
		_generation: number,
		_active: number,
		_reloadTimer: thread?,
		_busy: boolean,
		_closed: boolean,
		_signal: Core.Signal,
		_failures: number,
		Changed: ChangeSignal.Signal,
		cleanup: (() -> ())?,
		lastError: Core.BloxError?,
	},
	Sync
))
--- Schedule completion-relative jitter, preserving the server's absolute five-second minimum.
local function jitter(self: Sync, seconds: number): number
	return math.max(5, seconds * (0.8 + 0.4 * self._runtime.random()))
end
--- Back off with bounded exponential jitter; Retry-After is a floor, never jittered down.
local function backoff(self: Sync, attempts: number, retryAfter: number?): number
	return math.max(retryAfter or 0, jitter(self, math.min(300, 5 * 2 ^ math.min(attempts - 1, 6))))
end
--- Allocate a lazy registry without scheduling work until a profile is successfully loaded.
function Sync.new(runtime: Core.Runtime, options: Config.ProfileSyncConfig?, canPoll: () -> boolean): Sync
	local config: Config.ProfileSyncConfig = options or {}
	return setmetatable({
		_runtime = runtime,
		_enabled = config.enabled ~= false,
		_pollAt = 0,
		_concurrency = Config.number(
			config.maxConcurrentReloads,
			2,
			1,
			16,
			"profileSync.maxConcurrentReloads",
			true
		),
		_canPoll = canPoll,
		_profiles = {},
		_loads = {},
		_reloads = {},
		_schemaPoll = {},
		_generation = 0,
		_active = 0,
		_reloadTimer = nil,
		_busy = false,
		_closed = false,
		_signal = { cancelled = false },
		_failures = 0,
		Changed = ChangeSignal.new(runtime),
		cleanup = nil,
		lastError = nil,
	}, Sync)
end
--- Report whether ticks must stay armed; disabled sync never keeps an idle client alive.
function Sync.hasProfiles(self: Sync): boolean
	return not self._closed and self._enabled and next(self._profiles) ~= nil
end
--- Enqueue all profile chunks before the batch tick dispatches; no separate polling clock.
function Sync.tick(self: Sync)
	if self:hasProfiles() then
		self:_poll()
	end
end
--- Run staggered, deduplicated reloads with bounded concurrency and retry admission.
function Sync._pump(self: Sync)
	if self._closed or self._reloadTimer or self._active >= self._concurrency then
		return
	end
	local selected: Profile.Profile? = nil
	local earliest = math.huge
	for profile, job in self._reloads do
		if not job.busy and job.at < earliest then
			selected = profile
			earliest = job.at
		end
	end
	if not selected then
		return
	end
	self._reloadTimer = self._runtime.delay(math.max(0.2, earliest - self._runtime.now()), function()
		self._reloadTimer = nil
		local profile = selected :: Profile.Profile
		local job = self._reloads[profile]
		if not job or not self._profiles[profile] or self._closed then
			self:_pump()
			return
		end
		if not self._canPoll() then
			job.at = self._runtime.now() + 5
			self:_pump()
			return
		end
		job.busy = true
		self._active += 1
		self:_pump()
		local options: Core.CallOptions = { priority = "low", retry = 0, signal = profile._signal }
		-- A migration requires fresh definitions, shared once per schema per recovery wave.
		local loaded: Core.Result<any> = { ok = true, value = true }
		while profile._schema._busy and not profile._closed and not self._closed do
			self._runtime.wait(0.01)
		end
		if
			self._schemaPoll[profile._schema] ~= self._generation
			and not profile._closed
			and not self._closed
		then
			loaded = profile._schema:refresh(options)
			if loaded.ok then
				self._schemaPoll[profile._schema] = self._generation
			end
		end
		if loaded.ok and not profile._closed and not self._closed then
			loaded = profile:refresh(options)
		end
		-- Native HttpService cannot abort: keep the recovery slot until physical completion.
		while (profile._signal.inFlight or 0) > 0 and not self._closed do
			self._runtime.wait(0.1)
		end
		self._active -= 1
		if self._reloads[profile] == job then
			if loaded.ok or profile._closed or self._closed then
				self._reloads[profile] = nil
			else
				profile.lastError = loaded.error
				job.attempts += 1
				job.busy = false
				job.at = self._runtime.now() + backoff(self, job.attempts, loaded.error.retryAfterSeconds)
			end
		end
		self:_pump()
	end)
end
--- Queue recovery without advancing the unsafe watermark or enqueueing duplicates.
function Sync._reload(self: Sync, profile: Profile.Profile)
	if self._closed or not self._profiles[profile] then
		return
	end
	if not self._reloads[profile] then
		self._reloads[profile] = { at = self._runtime.now(), busy = false, attempts = 0 }
	end
	self:_pump()
end
--- Snapshot deduplicated credential/universe groups and enqueue all chunks on this tick.
function Sync._poll(self: Sync)
	if self._closed or self._busy or self._runtime.now() < self._pollAt or not self:hasProfiles() then
		return
	end
	self._busy = true
	self._generation += 1
	local signal: Core.Signal = { cancelled = false }
	self._signal = signal
	local groups: { Group } = {}
	local byInvoke: { [Core.Invoke]: { [string]: Group } } = {}
	for profile, registration in self._profiles do
		local universes = byInvoke[registration.invoke]
		if not universes then
			universes = {}
			byInvoke[registration.invoke] = universes
		end
		local group = universes[registration.universe]
		if not group then
			local created: Group =
				{ universe = registration.universe, invoke = registration.invoke, users = {} }
			group = created
			universes[registration.universe] = created
			table.insert(groups, created)
		end
		assert(group ~= nil, "Missing sync group")
		local profiles = group.users[profile._user]
		if not profiles then
			profiles = {}
			group.users[profile._user] = profiles
		end
		table.insert(profiles, profile)
	end
	local pending = 0
	local failed = false
	for _, group in groups do
		local users: { number } = {}
		for user in group.users do
			table.insert(users, user)
		end
		table.sort(users)
		for first = 1, #users, 200 do
			local players: { Wire.PlayerChangesInput } = {}
			for i = first, math.min(first + 199, #users) do
				local user = users[i]
				local since = math.huge
				for _, profile in group.users[user] do
					since = math.min(since, profile.seq)
				end
				table.insert(players, { userId = user, sinceSeq = since })
			end
			pending += 1
			self._runtime.spawn(function()
				local result = group.invoke(Endpoints["fields.changesBatch"], {
					path = { universeId = group.universe },
					body = { players = players, maxEntries = 500 },
				}, { priority = "low", retry = 0, signal = signal }, group.universe)
				if not self._closed and not signal.cancelled then
					if result.ok then
						local response: Wire.BatchChangesResponse = result.value
						local valid = #response.items == #players
						for i, item in response.items do
							if not players[i] or item.userId ~= players[i].userId then
								valid = false
							end
						end
						if valid then
							for i, item in response.items do
								for _, profile in group.users[item.userId] do
									if
										self._profiles[profile]
										and not self._reloads[profile]
										-- A snapshot that completed during this poll already covers this response.
										and not (profile.seq > players[i].sinceSeq and profile.seq >= item.nextSinceSeq)
										and not profile:applyChanges(item, players[i].sinceSeq)
									then
										self:_reload(profile)
									end
								end
							end
						else
							failed = true
							self.lastError = {
								kind = "Validation",
								code = "invalid_changes_batch",
								endpoint = "fields.changesBatch",
								attempts = 1,
								message = "Invalid batch response",
							}
						end
					else
						failed = true
						self.lastError = result.error
					end
				end
				pending -= 1
				if pending == 0 then
					self._busy = false
					if not failed then
						self.lastError = nil
						self._failures = 0
					else
						self._failures += 1
						self._pollAt = self._runtime.now()
							+ backoff(
								self,
								self._failures,
								if self.lastError then self.lastError.retryAfterSeconds else nil
							)
					end
				end
			end)
		end
	end
	if pending == 0 then
		self._busy = false
	end
end
--- Fence asynchronous loads against player departure without retaining departed-user history.
function Sync.beginLoad(self: Sync, userId: number): Core.Signal
	local signal: Core.Signal = { cancelled = self._closed }
	if not self._closed then
		self._loads[signal] = userId
	end
	return signal
end
--- Drop a completed/failed load ticket on every exit path.
function Sync.endLoad(self: Sync, signal: Core.Signal)
	self._loads[signal] = nil
end
--- Register each handle once; duplicate player handles share one wire entry and minimum cursor.
function Sync.register(self: Sync, universe: string, profile: Profile.Profile, invoke: Core.Invoke)
	if self._closed or profile._closed or self._profiles[profile] then
		return
	end
	self._profiles[profile] = { universe = universe, invoke = invoke }
	profile._universe = universe
	profile._onChange = function(change)
		self.Changed:fire(change)
	end
	if self.wake and self._enabled then
		self.wake()
	end
end
--- Remove handles and pending recovery immediately, cancelling idle polling without retaining history.
function Sync.unregister(self: Sync, profile: Profile.Profile)
	self._profiles[profile] = nil
	self._reloads[profile] = nil
	if next(self._profiles) == nil then
		self._signal.cancelled = true
		if self._reloadTimer then
			self._runtime.cancel(self._reloadTimer)
			self._reloadTimer = nil
		end
		table.clear(self._schemaPoll)
	end
end
--- Drop all handles for a departed player; no network request is started by the removal hook.
function Sync.removePlayer(self: Sync, userId: number)
	for signal, user in self._loads do
		if user == userId then
			signal.cancelled = true
		end
	end
	local profiles = table.clone(self._profiles)
	for profile in profiles do
		if profile._user == userId then
			profile:destroy()
		end
	end
end
--- Stop admission before flush/destroy, cancelling queued polls, reloads and native connections.
function Sync.destroy(self: Sync)
	if self._closed then
		return
	end
	self._closed = true
	self._signal.cancelled = true
	if self._reloadTimer then
		self._runtime.cancel(self._reloadTimer)
		self._reloadTimer = nil
	end
	if self.cleanup then
		self.cleanup()
		self.cleanup = nil
	end
	for signal in self._loads do
		signal.cancelled = true
	end
	table.clear(self._loads)
	for profile in self._reloads do
		profile._signal.cancelled = true
	end
	table.clear(self._profiles)
	table.clear(self._reloads)
	table.clear(self._schemaPoll)
	self.Changed:destroy()
end
return table.freeze(Sync)
