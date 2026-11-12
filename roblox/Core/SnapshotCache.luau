--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Types = require(script.Parent.Parent.Types.Fields)
local Config = require(script.Parent.Parent.Core.Config)
local Cache = require(script.Parent.Parent.Core.Cache)
local Errors = require(script.Parent.Parent.Core.Errors)
local Json = require(script.Parent.Parent.Core.Json)
local Snapshot = {}
Snapshot.__index = Snapshot
export type Connection = { disconnect: (Connection) -> () }
export type Changed = { connect: (Changed, (Types.RuntimeSnapshot) -> ()) -> Connection }
export type Snapshot = typeof(setmetatable(
	{} :: {
		_runtime: Core.Runtime,
		_fetch: (string?, Core.CallOptions) -> Core.Result<Types.RuntimeSnapshot?>,
		_value: Types.RuntimeSnapshot?,
		_etag: string?,
		_flags: { [string]: Types.FlagDefinition },
		_listeners: { [(Types.RuntimeSnapshot) -> ()]: boolean },
		_signal: Core.Signal,
		_interval: number,
		_timer: thread?,
		_busy: boolean,
		_onDestroy: (() -> ())?,
		changed: Changed,
		lastError: Core.BloxError?,
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
		self:refresh()
		if not self._signal.cancelled then
			schedule(self, self._interval)
		end
	end)
end
--- Start an asynchronous first poll; reads remain synchronous and use only the last good snapshot.
function Snapshot.new(
	runtime: Core.Runtime,
	fetch: (string?, Core.CallOptions) -> Core.Result<Types.RuntimeSnapshot?>,
	interval: number?,
	onDestroy: (() -> ())?
): Snapshot
	local listeners: { [(Types.RuntimeSnapshot) -> ()]: boolean } = {}
	local changed: Changed = {
		connect = function(_self: Changed, callback: (Types.RuntimeSnapshot) -> ()): Connection
			listeners[callback] = true
			return {
				disconnect = function(_connection: Connection)
					listeners[callback] = nil
				end,
			}
		end,
	}
	local self: Snapshot = setmetatable({
		_runtime = runtime,
		_fetch = fetch,
		_value = nil,
		_etag = nil,
		_flags = {},
		_listeners = listeners,
		_signal = { cancelled = false },
		_interval = Config.number(interval, 30, 0.01, 3600, "snapshot interval"),
		_timer = nil,
		_busy = false,
		_onDestroy = onDestroy,
		changed = changed,
		lastError = nil,
	}, Snapshot)
	schedule(self, 0)
	return self
end
--- Fetch conditionally; errors, 304s and version regressions never discard a good snapshot.
function Snapshot.refresh(self: Snapshot): boolean
	if self._busy or self._signal.cancelled then
		return false
	end
	self._busy = true
	local old = self._value
	local ok, response = pcall(self._fetch, self._etag, { signal = self._signal })
	local result: Core.Result<Types.RuntimeSnapshot?> = if ok
		then response
		else Errors.make("Local", "fields.runtimeSnapshot", 0, "Snapshot fetch failed")
	self._busy = false
	if self._signal.cancelled then
		return false
	end
	if not result.ok then
		self.lastError = result.error
		return false
	end
	if result.status == 304 and old then
		self.lastError = nil
		return true
	end
	local value = result.value
	if
		not value
		or value.version < 0
		or value.version % 1 ~= 0
		or (old and value.version < old.version)
		or not value.flags
		or (value.flags :: any) == Json.null
	then
		local failure = Errors.make("Validation", "fields.runtimeSnapshot", 0, "Invalid snapshot version")
		if not failure.ok then
			self.lastError = failure.error
		end
		return false
	end
	self.lastError = nil
	local oldEtag = self._etag
	self._etag = result.etag
	if old and old.version == value.version and result.etag ~= nil and result.etag == oldEtag then
		return true
	end
	self._value = Cache.freeze(value)
	local flags: { [string]: Types.FlagDefinition } = {}
	for _, flag in value.flags :: { Types.FlagDefinition } do
		if type(flag.key) == "string" then
			flags[flag.key] = flag
		end
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
--- Read active heads from the last good snapshot; nil means the server has not supplied rotations.
function Snapshot.getRotations(self: Snapshot): { Types.RotationActive }?
	return if not self._signal.cancelled and self._value then self._value.rotations else nil
end
--- Expose lifecycle state without requiring a polling task.
function Snapshot.isDestroyed(self: Snapshot): boolean
	return self._signal.cancelled
end
--- Return the cached master switch, not per-user rollout/rules evaluation; use fields:evaluateFlags for that.
function Snapshot.isEnabled(self: Snapshot, flag: string): boolean
	local value = self._flags[flag]
	return value ~= nil and value.enabled
end
--- Read the last successfully applied universe generation.
function Snapshot.version(self: Snapshot): number?
	return if self._value then self._value.version else nil
end
--- Stop polling, cancel in-flight work and disconnect all listeners.
function Snapshot.destroy(self: Snapshot)
	if self._signal.cancelled then
		return
	end
	self._signal.cancelled = true
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
	table.clear(self._listeners)
	if self._onDestroy then
		self._onDestroy()
	end
end
return table.freeze(Snapshot)
