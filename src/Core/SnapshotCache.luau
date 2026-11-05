--!strict
local Core = require("../Types/Core")
local Types = require("../Types/Config")
local Config = require("./Config")
local Cache = require("./Cache")
local Errors = require("./Errors")
local Snapshot = {}
Snapshot.__index = Snapshot
export type Connection = { Disconnect: (Connection) -> () }
export type Changed = { Connect: (Changed, (Types.Snapshot) -> ()) -> Connection }
export type Snapshot = typeof(setmetatable(
	{} :: {
		_runtime: Core.Runtime,
		_fetch: (number?, Core.CallOptions) -> Core.Result<Types.Snapshot?>,
		_value: Types.Snapshot?,
		_flags: { [string]: Types.Flag },
		_listeners: { [(Types.Snapshot) -> ()]: boolean },
		_signal: Core.Signal,
		_interval: number,
		_timer: thread?,
		_busy: boolean,
		Changed: Changed,
		LastError: Core.BloxError?,
	},
	Snapshot
))
--- Poll serially after each completion; a slow/erroring backend never creates overlapping polls.
local function schedule(self: Snapshot, seconds: number)
	self._timer = self._runtime.delay(seconds, function()
		self._timer = nil
		if self._signal.cancelled then
			return
		end
		self:Refresh()
		if not self._signal.cancelled then
			schedule(self, self._interval)
		end
	end)
end
--- Start an asynchronous first poll; reads remain synchronous and use only the last good snapshot.
function Snapshot.new(
	runtime: Core.Runtime,
	fetch: (number?, Core.CallOptions) -> Core.Result<Types.Snapshot?>,
	interval: number?
): Snapshot
	local listeners: { [(Types.Snapshot) -> ()]: boolean } = {}
	local changed: Changed = {
		Connect = function(_self: Changed, callback: (Types.Snapshot) -> ()): Connection
			listeners[callback] = true
			return {
				Disconnect = function(_connection: Connection)
					listeners[callback] = nil
				end,
			}
		end,
	}
	local self: Snapshot = setmetatable({
		_runtime = runtime,
		_fetch = fetch,
		_value = nil,
		_flags = {},
		_listeners = listeners,
		_signal = { cancelled = false },
		_interval = Config.number(interval, 30, 0.01, 3600, "snapshot interval"),
		_timer = nil,
		_busy = false,
		Changed = changed,
		LastError = nil,
	}, Snapshot)
	schedule(self, 0)
	return self
end
--- Fetch conditionally; errors, 304s and version regressions never discard a good snapshot.
function Snapshot.Refresh(self: Snapshot): boolean
	if self._busy or self._signal.cancelled then
		return false
	end
	self._busy = true
	local old = self._value
	local ok, response = pcall(self._fetch, if old then old.version else nil, { signal = self._signal })
	local result: Core.Result<Types.Snapshot?> = if ok
		then response
		else Errors.make("Local", "config.snapshot", 0, "Snapshot fetch failed")
	self._busy = false
	if self._signal.cancelled then
		return false
	end
	if not result.ok then
		self.LastError = result.error
		return false
	end
	if result.status == 304 and old then
		self.LastError = nil
		return true
	end
	local value = result.value
	if not value or value.version < 0 or value.version % 1 ~= 0 or (old and value.version < old.version) then
		local failure = Errors.make("Validation", "config.snapshot", 0, "Invalid snapshot version")
		if not failure.ok then
			self.LastError = failure.error
		end
		return false
	end
	self.LastError = nil
	if old and old.version == value.version then
		return true
	end
	self._value = Cache.freeze(value)
	local flags: { [string]: Types.Flag } = {}
	for _, flag in value.flags do
		flags[flag.key] = flag
	end
	self._flags = flags
	for listener in self._listeners do
		self._runtime.spawn(function()
			if not self._signal.cancelled and self._listeners[listener] then
				pcall(listener, value)
			end
		end)
	end
	return true
end
--- Return an immutable config value, or nil before initial success / for an unknown key.
function Snapshot.Get(self: Snapshot, key: string): Core.Json?
	return if self._value then self._value.entries[key] else nil
end
--- Return the cached master switch, not per-user rollout/rules evaluation; use config:evaluate for that.
function Snapshot.IsEnabled(self: Snapshot, flag: string): boolean
	local value = self._flags[flag]
	return value ~= nil and value.enabled
end
--- Read the last successfully applied universe generation.
function Snapshot.Version(self: Snapshot): number?
	return if self._value then self._value.version else nil
end
--- Stop polling, cancel in-flight work and disconnect all listeners.
function Snapshot.Destroy(self: Snapshot)
	self._signal.cancelled = true
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
	table.clear(self._listeners)
end
return table.freeze(Snapshot)
