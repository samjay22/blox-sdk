--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
-- One ConfigService namespace: a cached live copy kept fresh by a single ETag poller, plus its admin calls.
-- Reads (`get`, `snapshot`, ...) only touch memory; they never yield, never throw and never hit the network.
-- tools/gen.py generates the wire types and endpoint metadata used here; tools/check-coverage verifies that
-- every ConfigService route is reachable from `client.configs` (src/Services/Config.luau) or from this file.
local Core = require(script.Parent.Parent.Types.Core)
local Types = require(script.Parent.Parent.Types.Config)
local Config = require(script.Parent.Parent.Core.Config)
local Endpoints = require(script.Parent.Parent.Core.Endpoints)
local Errors = require(script.Parent.Parent.Core.Errors)
local Cache = require(script.Parent.Parent.Core.Cache)
local Json = require(script.Parent.Parent.Core.Json)
local Pagination = require(script.Parent.Parent.Core.Pagination)
local Namespace = {}
Namespace.__index = Namespace
--- What changed when a new version was applied. `keys` is every key whose value was added, changed or removed.
--- The first load reports `previousVersion = 0` with every key in `set`.
export type Change = {
	namespace: string,
	version: number,
	previousVersion: number,
	keys: { string },
	set: { string },
	deleted: { string },
}
export type Connection = { disconnect: (Connection) -> () }
export type Changed = { connect: (Changed, (Change) -> ()) -> Connection }
--- The whole namespace as of one version; frozen, so it is safe to keep and share.
export type Snapshot = { namespace: string, version: number, entries: { [string]: Core.Json } }
--- Polling policy. Seconds; `staleAfter` defaults to three poll intervals.
export type Options = { pollInterval: number?, staleAfter: number?, jitter: number? }
--- `description` and `expectedVersion` describe the write; the rest are the usual per-call options.
--- `expectedVersion` is the key's version: 0 creates only, n requires the key to be at version n.
export type WriteOptions = {
	description: string?,
	expectedVersion: number?,
	timeout: number?,
	deadline: number?,
	priority: ("critical" | "bulk" | "low")?,
	retry: number?,
	signal: Core.Signal?,
}
--- Atomic multi-key change. `expectedVersion` is the namespace version; `expectedVersions` and `descriptions`
--- are per key. At least one key must be set or deleted, and no key may be in both.
export type Changes = {
	set: { [string]: Core.Json }?,
	delete: { string }?,
	expectedVersion: number?,
	expectedVersions: { [string]: number }?,
	descriptions: { [string]: string }?,
}
export type Page = { limit: number?, cursor: string? }
export type Namespace = typeof(setmetatable(
	{} :: {
		name: string,
		Changed: Changed,
		_invoke: Core.Invoke,
		_universe: (string | number)?,
		_runtime: Core.Runtime,
		_interval: number,
		_jitter: number,
		_staleAfter: number,
		_entries: { [string]: Core.Json },
		_snapshot: Snapshot,
		_version: number,
		_etag: string?,
		_ready: boolean,
		_checkedClock: number?,
		_checkedUnix: number?,
		_error: Core.BloxError?,
		_failures: number,
		_listeners: { [Connection]: (Change) -> () },
		_signal: Core.Signal,
		_timer: thread?,
		_busy: boolean,
		_again: boolean,
		_onDestroy: (() -> ())?,
	},
	Namespace
))
local NAMESPACE_PATTERN = "^[A-Za-z0-9][A-Za-z0-9_%-]*$"
local KEY_PATTERN = "^[A-Za-z0-9_][A-Za-z0-9_%.%-]*$"
local MAX_VALUE_BYTES = 65536
local MAX_KEYS = 1000
--- Check a namespace name against the server's grammar so bad names fail before any request.
function Namespace.validName(name: unknown): boolean
	return type(name) == "string" and #name <= 64 and string.match(name, NAMESPACE_PATTERN) ~= nil
end
--- Check a key against the server's grammar.
local function validKey(key: unknown): boolean
	return type(key) == "string" and #key <= 100 and string.match(key, KEY_PATTERN) ~= nil
end
--- A local refusal with the same error shape the pipeline produces.
local function refuse(endpoint: string, message: string): Core.Result<any>
	return Errors.make("Validation", endpoint, 0, message)
end
--- Structural JSON equality for decoded values; used only to name the keys a new version changed.
local function equal(a: any, b: any, depth: number): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" or depth > 64 then
		return false
	end
	for key, value in a do
		if not equal(value, b[key], depth + 1) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end
--- Diff two entry maps into sorted key lists.
local function diff(old: { [string]: Core.Json }, new: { [string]: Core.Json }): ({ string }, { string })
	local set: { string } = {}
	local deleted: { string } = {}
	for key, value in new do
		if old[key] == nil or not equal(old[key], value, 0) then
			table.insert(set, key)
		end
	end
	for key in old do
		if new[key] == nil then
			table.insert(deleted, key)
		end
	end
	table.sort(set)
	table.sort(deleted)
	return set, deleted
end
--- Seconds until the next poll: the interval, or a short backoff while failing, jittered either way.
local function nextDelay(self: Namespace): number
	local base = if self._failures == 0
		then self._interval
		else math.min(self._interval, 2 ^ math.min(self._failures, 6))
	local spread = (self._runtime.random() * 2 - 1) * self._jitter
	local delay = base * (1 + spread)
	local failure = self._error
	if failure and failure.retryAfterSeconds then
		delay = math.max(delay, math.min(failure.retryAfterSeconds, 3600))
	end
	return math.max(delay, 0.01)
end
--- Poll serially: the next timer is armed only after the previous refresh finished.
local function schedule(self: Namespace, seconds: number)
	if self._signal.cancelled then
		return
	end
	self._timer = self._runtime.delay(seconds, function()
		self._timer = nil
		if self._signal.cancelled then
			return
		end
		self:refresh()
		schedule(self, nextDelay(self))
	end)
end
--- Bind a namespace handle and start its poller. The first fetch runs on the next scheduler turn.
function Namespace.new(
	name: string,
	invoke: Core.Invoke,
	universe: (string | number)?,
	runtime: Core.Runtime,
	defaults: Config.ConfigsConfig?,
	options: Options?,
	onDestroy: (() -> ())?
): Namespace
	assert(Namespace.validName(name), "Invalid namespace name")
	local base: Config.ConfigsConfig = defaults or {}
	local given: Options = options or {}
	local interval = Config.number(given.pollInterval or base.pollInterval, 30, 1, 3600, "pollInterval")
	local jitter = Config.number(given.jitter or base.jitter, 0.2, 0, 0.5, "jitter")
	local staleAfter =
		Config.number(given.staleAfter or base.staleAfter, interval * 3, 1, 86400, "staleAfter")
	local listeners: { [Connection]: (Change) -> () } = {}
	local changed: Changed = {
		connect = function(_self: Changed, callback: (Change) -> ()): Connection
			local connection: Connection
			connection = {
				disconnect = function(_connection: Connection)
					listeners[connection] = nil
				end,
			}
			listeners[connection] = callback
			return connection
		end,
	}
	local entries: { [string]: Core.Json } = table.freeze({})
	local self: Namespace = setmetatable({
		name = name,
		Changed = changed,
		_invoke = invoke,
		_universe = universe,
		_runtime = runtime,
		_interval = interval,
		_jitter = jitter,
		_staleAfter = staleAfter,
		_entries = entries,
		_snapshot = table.freeze({ namespace = name, version = 0, entries = entries }),
		_version = 0,
		_etag = nil,
		_ready = false,
		_checkedClock = nil,
		_checkedUnix = nil,
		_error = nil,
		_failures = 0,
		_listeners = listeners,
		_signal = { cancelled = false },
		_timer = nil,
		_busy = false,
		_again = false,
		_onDestroy = onDestroy,
	}, Namespace)
	schedule(self, 0)
	return self
end
--- Record a fetch that confirmed (or replaced) the cache.
local function confirmed(self: Namespace)
	self._ready = true
	self._error = nil
	self._failures = 0
	self._checkedClock = self._runtime.now()
	self._checkedUnix = self._runtime.unix()
end
--- Install a new version and tell listeners which keys moved. Listener errors are isolated.
local function apply(self: Namespace, version: number, values: { [string]: Core.Json }, etag: string?)
	local previous = self._version
	local set, deleted = diff(self._entries, values)
	local entries: { [string]: Core.Json } = Cache.freeze(values)
	self._entries = entries
	self._snapshot = table.freeze({ namespace = self.name, version = version, entries = entries })
	self._version = version
	self._etag = etag
	confirmed(self)
	if version == previous then
		return
	end
	local keys: { string } = table.clone(set)
	for _, key in deleted do
		table.insert(keys, key)
	end
	table.sort(keys)
	local change: Change = Cache.freeze({
		namespace = self.name,
		version = version,
		previousVersion = previous,
		keys = keys,
		set = set,
		deleted = deleted,
	})
	for connection, listener in self._listeners do
		self._runtime.spawn(function()
			if not self._signal.cancelled and self._listeners[connection] then
				pcall(listener, change)
			end
		end)
	end
end
--- Quote a version the way the server's strong ETag does, for a response that carried none.
local function etagFor(result: Core.Result<any>, version: number): string
	if result.ok and type(result.etag) == "string" and string.match(result.etag, '^"[^"%c]+"$') then
		return result.etag
	end
	return '"' .. string.format("%.0f", version) .. '"'
end
--- One conditional fetch. 200 swaps the whole map, 304 keeps it, a never-written namespace is an empty one.
local function fetch(self: Namespace): boolean
	local options: Core.CallOptions = { priority = "low", signal = self._signal }
	local ok, result = pcall(
		self._invoke,
		Endpoints["config.snapshot"],
		{ path = { namespace = self.name }, etag = self._etag },
		options,
		self._universe
	)
	local reply: Core.Result<any> = if ok
		then result
		else Errors.make("Local", "config.snapshot", 0, "Snapshot fetch failed")
	if self._signal.cancelled then
		return false
	end
	if reply.ok then
		if reply.status == 304 and self._ready then
			confirmed(self)
			return true
		end
		local value: any = reply.value
		if
			type(value) ~= "table"
			or type(value.version) ~= "number"
			or value.version < 0
			or value.version % 1 ~= 0
			or type(value.entries) ~= "table"
			or value.entries == Json.null
			or value.version < self._version
		then
			local failure = Errors.make("Validation", "config.snapshot", 0, "Invalid snapshot version")
			if not failure.ok then
				self._error = failure.error
			end
			self._failures += 1
			return false
		end
		if self._ready and value.version == self._version then
			confirmed(self)
			return true
		end
		apply(self, value.version, value.entries, etagFor(reply, value.version))
		return true
	end
	-- A namespace is created by its first write; until then it is simply empty (version 0).
	if reply.error.code == "namespace_not_found" and self._version == 0 then
		if not self._ready then
			apply(self, 0, {}, nil)
		else
			confirmed(self)
		end
		return true
	end
	self._error = reply.error
	self._failures += 1
	return false
end
--- Fetch the namespace now and merge it into the cache. Returns true when the cache is confirmed current.
--- A failed fetch keeps the last good snapshot and is visible through `lastError` and `isStale`.
--- Normally the poller does this for you; call it after changes made outside this server.
--- GET /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/snapshot via gateway; access: READ.
function Namespace.refresh(self: Namespace): boolean
	if self._signal.cancelled then
		return false
	end
	if self._busy then
		self._again = true
		while self._busy and not self._signal.cancelled do
			self._runtime.wait(0.01)
		end
		return not self._signal.cancelled and self._error == nil
	end
	self._busy = true
	local current = false
	repeat
		self._again = false
		current = fetch(self)
	until not self._again or self._signal.cancelled
	self._busy = false
	return current
end
--- Refresh soon after a successful local write so this server sees its own change quickly.
local function kick(self: Namespace)
	if self._signal.cancelled then
		return
	end
	if self._busy then
		self._again = true
	else
		self._runtime.spawn(function()
			Namespace.refresh(self)
		end)
	end
end
--- The cached value of `key`, or `default` when the key is missing or nothing has loaded yet.
--- Never yields or throws. Values are frozen and shared; copy before modifying.
function Namespace.get(self: Namespace, key: string, default: Core.Json?): Core.Json?
	if type(key) ~= "string" then
		return default
	end
	local value = self._entries[key]
	if value == nil then
		return default
	end
	return value
end
--- The cached value if it is a string, else `default`.
function Namespace.getString(self: Namespace, key: string, default: string): string
	local value = Namespace.get(self, key)
	return if type(value) == "string" then value else default
end
--- The cached value if it is a number, else `default`.
function Namespace.getNumber(self: Namespace, key: string, default: number): number
	local value = Namespace.get(self, key)
	return if type(value) == "number" then value else default
end
--- The cached value if it is a boolean, else `default`.
function Namespace.getBoolean(self: Namespace, key: string, default: boolean): boolean
	local value = Namespace.get(self, key)
	return if type(value) == "boolean" then value else default
end
--- Whether the cache holds `key`.
function Namespace.has(self: Namespace, key: string): boolean
	return type(key) == "string" and self._entries[key] ~= nil
end
--- Every cached key, sorted.
function Namespace.keys(self: Namespace): { string }
	local list: { string } = {}
	for key in self._entries do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end
--- The whole cached namespace. Before the first load this is version 0 with no entries.
function Namespace.snapshot(self: Namespace): Snapshot
	return self._snapshot
end
--- The cached namespace version; 0 before the first load or while the namespace has never been written.
function Namespace.version(self: Namespace): number
	return self._version
end
--- True once the first fetch succeeded, or the namespace was confirmed not to exist yet.
function Namespace.isReady(self: Namespace): boolean
	return self._ready
end
--- Unix seconds of the last successful check (a 304 counts), or nil before the first one.
function Namespace.lastRefreshedAt(self: Namespace): number?
	return self._checkedUnix
end
--- True before the first load and whenever the last successful check is older than `staleAfter`.
--- Stale values are still served; use this to decide whether to trust them for something critical.
function Namespace.isStale(self: Namespace): boolean
	local checked = self._checkedClock
	return checked == nil or self._runtime.now() - checked > self._staleAfter
end
--- The error from the latest failed fetch, cleared by the next success.
function Namespace.lastError(self: Namespace): Core.BloxError?
	return self._error
end
--- Yield until the first load completes. Returns false if `timeout` (default 10 seconds) passes first,
--- or the handle was destroyed; `lastError` then says why. Reads before that return their defaults.
function Namespace.waitReady(self: Namespace, timeout: number?): boolean
	local limit = Config.number(timeout, 10, 0, 300, "waitReady timeout")
	local deadline = self._runtime.now() + limit
	while not self._ready and not self._signal.cancelled and self._runtime.now() < deadline do
		self._runtime.wait(0.05)
	end
	return self._ready
end
--- True once the handle was destroyed by `client:destroy()`, `client:flush()` or `:destroy()`.
function Namespace.isDestroyed(self: Namespace): boolean
	return self._signal.cancelled
end
--- Stop polling and disconnect listeners. The cached values stay readable.
function Namespace.destroy(self: Namespace)
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
--- Split admin write options into the wire fields and the per-call options.
local function split(opts: WriteOptions?): (Core.CallOptions, string?, number?)
	local call: Core.CallOptions = {}
	local description, expected = nil, nil
	local source: any = opts or {}
	for name, value in source do
		if name == "description" then
			description = value :: string
		elseif name == "expectedVersion" then
			expected = value :: number
		else
			(call :: any)[name] = value
		end
	end
	return call, description, expected
end
--- Version tokens are non-negative integers.
local function validVersion(value: unknown, minimum: number): boolean
	return type(value) == "number" and value % 1 == 0 and value >= minimum and value <= 9007199254740991
end
--- Check one JSON value: present, not null, encodable and within the 64 KiB value limit.
local function validValue(value: unknown): boolean
	if value == nil or value == Json.null then
		return false
	end
	local ok, encoded = pcall(Json.encode, value)
	return ok and #encoded <= MAX_VALUE_BYTES
end
--- Check a description against the server's 2000-character limit.
local function validDescription(value: unknown): boolean
	return value == nil or (type(value) == "string" and (utf8.len(value) or math.huge) <= 2000)
end
--- Read one namespace's version and size, uncached.
--- GET /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace} via gateway; access: READ.
function Namespace.info(self: Namespace, opts: Core.CallOptions?): Core.Result<Types.Namespace>
	return self._invoke(
		Endpoints["config.namespace"],
		{ path = { namespace = self.name } },
		opts,
		self._universe
	)
end
--- List entries with their descriptions and versions, ordered by key, uncached. For values alone use `get`.
--- GET /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/entries via gateway; access: READ.
function Namespace.entries(
	self: Namespace,
	page: Page?,
	opts: Core.CallOptions?
): Core.Result<Types.CursorPage<Types.Entry>>
	return self._invoke(
		Endpoints["config.entries"],
		{ path = { namespace = self.name }, query = page },
		opts,
		self._universe
	)
end
--- Lazily iterate every entry page; errors are yielded once and end the iteration.
function Namespace.entriesPages(
	self: Namespace,
	page: Page?,
	opts: Core.CallOptions?,
	maximum: number?
): () -> Core.Result<Types.CursorPage<Types.Entry>>?
	local query: Page = table.clone(page or {})
	return Pagination.cursor(function(cursor: string?)
		query.cursor = cursor
		return Namespace.entries(self, query, opts)
	end, function(result: Types.CursorPage<Types.Entry>)
		return result.nextCursor
	end, maximum, query.cursor)
end
--- Read one entry with its description and version, uncached. A missing key is a `key_not_found` error.
--- GET /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/entries/{key} via gateway; access: READ.
function Namespace.entry(self: Namespace, key: string, opts: Core.CallOptions?): Core.Result<Types.Entry>
	if not validKey(key) then
		return refuse("config.entry", "Invalid key")
	end
	return self._invoke(
		Endpoints["config.entry"],
		{ path = { namespace = self.name, key = key } },
		opts,
		self._universe
	)
end
--- Create or replace one key. Needs ConfigService ADMIN, so keep it in trusted admin tooling.
--- `value` is any JSON except null (use `delete`), at most 64 KiB; wrap an empty array in `BloxSDK.array`.
--- Writing an unchanged value is a no-op. Pass `expectedVersion` (0 = create only) to guard against races;
--- a mismatch fails with code `version_conflict`.
--- PUT /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/entries/{key} via gateway; access: ADMIN.
function Namespace.set(
	self: Namespace,
	key: string,
	value: Core.Json,
	opts: WriteOptions?
): Core.Result<Types.Entry>
	local call, description, expected = split(opts)
	if not validKey(key) then
		return refuse("config.putEntry", "Invalid key")
	elseif not validValue(value) then
		return refuse("config.putEntry", "Value must be non-null JSON of at most 64 KiB")
	elseif not validDescription(description) then
		return refuse("config.putEntry", "Invalid description")
	elseif expected ~= nil and not validVersion(expected, 0) then
		return refuse("config.putEntry", "Invalid expectedVersion")
	end
	local result = self._invoke(Endpoints["config.putEntry"], {
		path = { namespace = self.name, key = key },
		body = { value = value, description = description, expectedVersion = expected },
	}, call, self._universe)
	if result.ok then
		kick(self)
	end
	return result
end
--- Remove one key. Deleting a missing key is a `key_not_found` error. Needs ConfigService ADMIN.
--- DELETE /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/entries/{key} via gateway; access: ADMIN.
function Namespace.delete(self: Namespace, key: string, opts: Core.CallOptions?): Core.Result<nil>
	if not validKey(key) then
		return refuse("config.deleteEntry", "Invalid key")
	end
	local result = self._invoke(
		Endpoints["config.deleteEntry"],
		{ path = { namespace = self.name, key = key } },
		opts,
		self._universe
	)
	if result.ok then
		kick(self)
	end
	return result
end
--- Check a change set before sending it; returns the wire body or the reason it is invalid.
local function changeBody(changes: Changes): (Types.ChangeSet?, string?)
	if type(changes) ~= "table" then
		return nil, "Changes must be a table"
	end
	local body: Types.ChangeSet = {}
	local count = 0
	local setKeys: { [string]: boolean } = {}
	if changes.set ~= nil then
		local set: { [string]: Types.EntryPut } = {}
		for key, value in changes.set do
			if not validKey(key) or not validValue(value) then
				return nil, "Invalid key or value in set"
			end
			local description = if changes.descriptions then changes.descriptions[key] else nil
			local expected = if changes.expectedVersions then changes.expectedVersions[key] else nil
			if not validDescription(description) or (expected ~= nil and not validVersion(expected, 0)) then
				return nil, "Invalid description or expectedVersion"
			end
			set[key] = { value = value, description = description, expectedVersion = expected }
			setKeys[key] = true
			count += 1
		end
		if count > 0 then
			body.set = set
		end
	end
	if changes.delete ~= nil then
		local list: { string } = {}
		local seen: { [string]: boolean } = {}
		for _, key in changes.delete do
			if not validKey(key) or setKeys[key] or seen[key] then
				return nil, "Invalid, duplicate or conflicting key in delete"
			end
			seen[key] = true
			table.insert(list, key)
		end
		if #list > 0 then
			body.delete = list
			count += #list
		end
	end
	if count == 0 then
		return nil, "Nothing to change"
	end
	if count > MAX_KEYS * 2 then
		return nil, "Too many keys"
	end
	if changes.expectedVersion ~= nil then
		if not validVersion(changes.expectedVersion, 0) then
			return nil, "Invalid expectedVersion"
		end
		body.expectedVersion = changes.expectedVersion
	end
	return body, nil
end
--- Set and delete any number of keys atomically under one new namespace version; nothing is written if any
--- check fails. Returns the new namespace summary. Needs ConfigService ADMIN.
--- `expectedVersion` requires the namespace to be at that version (0 = never written).
--- PATCH /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/entries via gateway; access: ADMIN.
function Namespace.setMany(
	self: Namespace,
	changes: Changes,
	opts: Core.CallOptions?
): Core.Result<Types.Namespace>
	local body, problem = changeBody(changes)
	if not body then
		return refuse("config.changeEntries", problem or "Invalid changes")
	end
	local result = self._invoke(
		Endpoints["config.changeEntries"],
		{ path = { namespace = self.name }, body = body },
		opts,
		self._universe
	)
	if result.ok then
		kick(self)
	end
	return result
end
--- Page through the version history, newest first; only the 500 most recent versions are retained.
--- GET /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/history via gateway; access: READ.
function Namespace.history(
	self: Namespace,
	page: Page?,
	opts: Core.CallOptions?
): Core.Result<Types.CursorPage<Types.History>>
	return self._invoke(
		Endpoints["config.history"],
		{ path = { namespace = self.name }, query = page },
		opts,
		self._universe
	)
end
--- Lazily iterate every history page; errors are yielded once and end the iteration.
function Namespace.historyPages(
	self: Namespace,
	page: Page?,
	opts: Core.CallOptions?,
	maximum: number?
): () -> Core.Result<Types.CursorPage<Types.History>>?
	local query: Page = table.clone(page or {})
	return Pagination.cursor(function(cursor: string?)
		query.cursor = cursor
		return Namespace.history(self, query, opts)
	end, function(result: Types.CursorPage<Types.History>)
		return result.nextCursor
	end, maximum, query.cursor)
end
--- The complete content of one retained version, with the history row that produced it.
--- GET /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/history/{version} via gateway; access: READ.
function Namespace.at(
	self: Namespace,
	version: number,
	opts: Core.CallOptions?
): Core.Result<Types.VersionState>
	if not validVersion(version, 1) then
		return refuse("config.version", "Invalid version")
	end
	return self._invoke(
		Endpoints["config.version"],
		{ path = { namespace = self.name, version = version } },
		opts,
		self._universe
	)
end
--- Restore an older version's content as a NEW version; history is never rewritten. `0` empties the namespace.
--- Needs ConfigService ADMIN. A version that is no longer retained fails with `version_not_found`.
--- POST /remote-config-service/api/config/universes/{universeId}/namespaces/{namespace}/rollback via gateway; access: ADMIN.
function Namespace.rollback(
	self: Namespace,
	version: number,
	opts: Core.CallOptions?
): Core.Result<Types.Namespace>
	if not validVersion(version, 0) then
		return refuse("config.rollback", "Invalid version")
	end
	local result = self._invoke(
		Endpoints["config.rollback"],
		{ path = { namespace = self.name }, body = { toVersion = version } },
		opts,
		self._universe
	)
	if result.ok then
		kick(self)
	end
	return result
end
return table.freeze(Namespace)
