--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Schema = require(script.Parent.Parent.Fields.Schema)
local Transaction = require(script.Parent.Parent.Fields.Transaction)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Copy = require(script.Parent.Parent.Core.Idempotency)
local Cache = require(script.Parent.Parent.Core.Cache)
local Json = require(script.Parent.Parent.Core.Json)
local Errors = require(script.Parent.Parent.Core.Errors)
local FieldTypes = require(script.Parent.Parent.Fields.Types)
local ChangeSignal = require(script.Parent.Parent.Core.ChangeSignal)
local Operations = require(script.Parent.Parent.Fields.Operations)
local Profile = {}
Profile.__index = Profile
export type IO = {
	document: (Core.CallOptions?) -> Core.Result<Wire.Document>,
	changes: (number, Core.CallOptions?) -> Core.Result<Wire.ChangesResponse>,
	presence: (Wire.PresenceInput, Core.CallOptions?) -> Core.Result<Wire.Presence>,
	transaction: ((Wire.Result) -> ()) -> Transaction.Transaction,
}
export type Profile = typeof(setmetatable(
	{} :: {
		Changed: ChangeSignal.Signal,
		_base: { [string]: Core.Json },
		_buffer: { FieldTypes.PlayerOperation },
		_sent: { FieldTypes.PlayerOperation },
		_leaseReady: boolean,
		_recovering: boolean,
		_optimisticRecovery: boolean,
		_admit: (({ FieldTypes.PlayerOperation }) -> boolean)?,
		_releaseLease: ((number) -> boolean)?,
		_universe: string?,
		_onChange: ((ChangeSignal.Change) -> ())?,
		_onRelease: (() -> ())?,
		_runtime: Core.Runtime,
		_schema: Schema.Schema,
		_schemaVersion: number?,
		_io: IO,
		_user: number,
		_data: { [string]: Core.Json },
		versions: { [string]: number },
		_versionFloor: { [string]: number },
		seq: number,
		_snapshotFloor: number,
		_stale: boolean,
		_epoch: number,
		_closed: boolean,
		_session: string?,
		_place: number?,
		_timer: thread?,
		_heartbeat: number,
		_signal: Core.Signal,
		_presenceBusy: boolean,
		_stopping: boolean,
		lastError: Core.BloxError?,
	},
	Profile
))
--- Read a declared dotted document leaf, never flattening an object-valued field.
local function read(data: any, id: string): any
	local value = data
	for _, part in string.split(id, ".") do
		if type(value) ~= "table" or value == Json.null then
			return nil
		end
		value = value[part]
	end
	return value
end
--- Write one declared leaf, creating only the document's namespace containers.
local function put(data: any, id: string, value: Core.Json)
	local parts = string.split(id, ".")
	local node = data
	for i = 1, #parts - 1 do
		node[parts[i]] = node[parts[i]] or {}
		node = node[parts[i]]
	end
	node[parts[#parts]] = value
end
--- Construct a profile only through a successful schema/document load.
function Profile.new(runtime: Core.Runtime, schema: Schema.Schema, user: number, io: IO): Profile
	return setmetatable({
		Changed = ChangeSignal.new(runtime),
		_base = {},
		_buffer = {},
		_sent = {},
		_leaseReady = false,
		_recovering = false,
		_optimisticRecovery = false,
		_admit = nil,
		_universe = nil,
		_onChange = nil,
		_onRelease = nil,
		_runtime = runtime,
		_schema = schema,
		_schemaVersion = nil,
		_user = user,
		_io = io,
		_data = {},
		versions = {},
		_versionFloor = {},
		seq = 0,
		_snapshotFloor = 0,
		_stale = true,
		_epoch = 0,
		_closed = false,
		_session = nil,
		_place = nil,
		_timer = nil,
		_heartbeat = 30,
		_signal = { cancelled = false },
		_presenceBusy = false,
		_stopping = false,
		lastError = nil,
	}, Profile)
end
--- Notify once per changed field with immutable final values, never intermediate operations.
function Profile._notify(self: Profile, old: { [string]: Core.Json }, source: "external" | "local")
	local ids: { string } = {}
	local values: { [string]: Core.Json } = {}
	for id, definition in self._schema:definitions() do
		if definition.scope == "PLAYER" and definition.status == "ACTIVE" then
			local value = read(self._data, id)
			if value ~= nil and not System.equal(read(old, id), value) then
				table.insert(ids, id)
				values[id] = value
			end
		end
	end
	if #ids == 0 then
		return
	end
	table.sort(ids)
	local change: ChangeSignal.Change = Cache.freeze({
		userId = self._user,
		universeId = self._universe,
		fieldIds = ids,
		values = values,
		source = source,
	})
	self.Changed:fire(change)
	if self._onChange then
		self._onChange(change)
	end
end
--- Accept only exact nonnegative counters representable by Luau numbers.
local function counter(value: unknown): boolean
	return type(value) == "number" and value >= 0 and value <= 9007199254740991 and value % 1 == 0
end
--- Replay pending writes over authoritative state; versions always describe only the server base.
function Profile._overlay(self: Profile, base: { [string]: Core.Json }): { [string]: Core.Json }
	local data = Copy.copy(base)
	for _, list in { self._sent, self._buffer } do
		for _, op in list do
			local definition = self._schema:get(op.field)
			if definition and definition.type then
				local result = System.apply(
					definition.type :: FieldTypes.TypeExpr,
					read(data, op.field),
					definition.default,
					op.op,
					Operations.operands(op),
					op.path
				)
				if result.ok then
					put(data, op.field, result.value)
				else
					self._stale = true
				end
			end
		end
	end
	return Cache.freeze(data)
end
--- Apply a validated operation list atomically and optimistically, without yielding or HTTP.
function Profile.mutate(self: Profile, ops: { FieldTypes.PlayerOperation }): Core.Result<boolean>
	if self._closed or not self._leaseReady then
		return System.failure("lease_lost")
	end
	if (self._stale or self._recovering) and not self._optimisticRecovery then
		return System.failure("profile_stale")
	end
	local prepared = Operations.prepare(self._schema, ops)
	if not prepared.ok then
		return prepared
	end
	local data = Copy.copy(self._data)
	for _, op in prepared.value do
		local definition = self._schema:get(op.field) :: Wire.Definition
		local result = System.apply(
			definition.type :: FieldTypes.TypeExpr,
			read(data, op.field),
			definition.default,
			op.op,
			Operations.operands(op),
			op.path
		)
		if not result.ok then
			return result
		end
		put(data, op.field, result.value)
	end
	if not self._admit or not self._admit(prepared.value) then
		return System.failure("buffer_full")
	end
	local old = self._data
	self._data = Cache.freeze(data)
	self:_notify(old, "local")
	return { ok = true, value = true }
end
--- Buffer a numeric delta and make its optimistic value visible immediately.
function Profile.add(
	self: Profile,
	field: string,
	delta: number,
	path: FieldTypes.Path?
): Core.Result<boolean>
	return self:mutate({ { field = field, op = "ADD", delta = delta, path = path } })
end
--- Buffer a last-writer-wins replacement and make it visible immediately.
function Profile.set(
	self: Profile,
	field: string,
	value: Core.Json,
	path: FieldTypes.Path?
): Core.Result<boolean>
	return self:mutate({ { field = field, op = "SET", value = value, path = path } })
end
--- Fetch and validate a complete snapshot; concurrent local commits cannot be overwritten by old reads.
function Profile.refresh(self: Profile, opts: Core.CallOptions?): Core.Result<boolean>
	if self._closed then
		return System.failure("profile_closed")
	end
	local epoch = self._epoch
	local schemaVersion = self._schema:version()
	local result = self._io.document(opts)
	if not result.ok then
		self.lastError = result.error
		return result
	end
	if self._closed then
		return System.failure("profile_closed")
	end
	local document = result.value
	if not document.versions or (document.versions :: any) == Json.null then
		return System.failure("invalid_version")
	end
	local documentVersions = document.versions :: { [string]: number }
	if
		document.userId ~= self._user
		or not counter(document.seq)
		or document.seq < math.max(self.seq, self._snapshotFloor)
		or epoch ~= self._epoch
		or schemaVersion ~= self._schema:version()
	then
		return System.failure("snapshot_race")
	end
	local data: { [string]: Core.Json } = {}
	for id, definition in self._schema:definitions() do
		if definition.status == "ACTIVE" and definition.scope == "PLAYER" then
			local value = read(document.data, id)
			local validator = self._schema:validator(id)
			if validator then
				local validated = validator.validate(value)
				if not validated.ok then
					return validated
				end
				value = validated.value
			elseif definition.computed and (definition.computed :: any) ~= Json.null then
				local checked = System.validate({
					kind = "nullable",
					of = { kind = (definition.computed :: FieldTypes.Computed).returns },
				}, value)
				if not checked.ok then
					return checked
				end
				value = checked.value
			else
				return System.failure("missing_value")
			end
			if
				not counter(documentVersions[id])
				or documentVersions[id] < math.max(self.versions[id] or 0, self._versionFloor[id] or 0)
			then
				return System.failure("invalid_version")
			end
			put(data, id, value)
		end
	end
	local old = self._data
	local wasLoaded = self._schemaVersion ~= nil
	self._base = Cache.freeze(data)
	self._stale = false
	self._data = self:_overlay(self._base)
	self.versions = Cache.freeze(Copy.copy(documentVersions))
	self.seq = document.seq
	self._snapshotFloor = 0
	table.clear(self._versionFloor)
	self._schemaVersion = schemaVersion
	self._epoch += 1
	self.lastError = nil
	if wasLoaded then
		self:_notify(old, "external")
	end
	return { ok = true, value = true }
end
--- Return a validated immutable value; unknown/archived ids and stale snapshots return typed errors.
function Profile.tryGet(self: Profile, id: string): Core.Result<Core.Json>
	if self._closed then
		return System.failure("profile_closed")
	end
	if self._schemaVersion ~= self._schema:version() then
		self._optimisticRecovery = false
		self._stale = true
	end
	local definition = self._schema:get(id)
	if not definition then
		return System.failure("unknown_field", nil, id)
	end
	if definition.status == "ARCHIVED" then
		return System.failure("field_archived", nil, id)
	end
	if definition.scope ~= "PLAYER" then
		return System.failure("field_scope_mismatch", nil, id)
	end
	if self._stale and not self._optimisticRecovery then
		return System.failure("profile_stale", nil, id)
	end
	local value = read(self._data, id)
	if value == nil then
		return System.failure("missing_value", nil, id)
	end
	return { ok = true, value = value }
end
--- Synchronous getter for generated static accessors; throws only a value-free typed code on misuse.
function Profile.get(self: Profile, id: string): Core.Json
	local result = self:tryGet(id)
	if not result.ok then
		error(result.error.code or "profile_error", 2)
	end
	return result.value
end
--- Apply newer per-field versions; mutation allocation tokens never advance the snapshot watermark.
function Profile.apply(self: Profile, result: Wire.Result, source: ("external" | "local")?): boolean
	if self._closed then
		return false
	end
	-- Even an unusable acknowledgement must invalidate an in-flight older snapshot.
	self._epoch += 1
	if type(result.results) ~= "table" or (result.results :: any) == Json.null then
		self._stale = true
		return false
	end
	if self._stale or self._schemaVersion ~= self._schema:version() then
		self._stale = true
		return false
	end
	local data = Copy.copy(self._base)
	local versions = Copy.copy(self.versions)
	local changed = false
	for _, item in result.results :: { Wire.ResultItem } do
		if item.subject == self._user then
			local definition = if type(item.field) == "string" then self._schema:get(item.field) else nil
			if
				not definition
				or not definition.type
				or (definition.type :: any) == Json.null
				or type(item.field) ~= "string"
				or definition.status ~= "ACTIVE"
				or definition.scope ~= "PLAYER"
				or not counter(item.version)
				or item.version == 0
				or not counter(self.versions[item.field])
				or (
					versions[item.field] ~= self.versions[item.field]
					and versions[item.field] ~= item.version
				)
			then
				self._stale = true
				return false
			end
			-- Compare with the pre-transaction version, not earlier ops in this response:
			-- every op on one field carries the same final version and must run in order.
			if item.version <= self.versions[item.field] then
				continue
			end
			if
				item.path
				and (item.path :: any) ~= Json.null
				and #item.path > 0
				and item.version > versions[item.field] + 1
			then
				-- A touched subvalue cannot reconstruct unseen writes to sibling paths.
				self._stale = true
				return false
			end
			local current = read(data, item.field)
			local replacement = System.apply(
				definition.type :: FieldTypes.TypeExpr,
				current,
				definition.default,
				"SET",
				{ value = item.after },
				item.path
			)
			if not replacement.ok then
				self._stale = true
				return false
			end
			put(data, item.field, replacement.value)
			versions[item.field] = item.version
			changed = true
		end
	end
	if not changed then
		return true
	end
	-- Computed results require a fresh coherent server snapshot, never client-side arithmetic authority.
	for _, definition in self._schema:definitions() do
		if
			definition.status == "ACTIVE"
			and definition.scope == "PLAYER"
			and definition.computed
			and (definition.computed :: any) ~= Json.null
		then
			self._stale = true
		end
	end
	local old = self._data
	self._base = Cache.freeze(data)
	self._data = self:_overlay(self._base)
	self.versions = Cache.freeze(versions)
	self:_notify(old, source or "local")
	return not self._stale
end
--- Fence older in-flight reads and require recovery to cover the last safe server cursor.
function Profile._invalidate(self: Profile, floor: number?)
	self._stale = true
	self._epoch += 1
	if floor then
		self._snapshotFloor = math.max(self._snapshotFloor, floor)
	end
end
--- Apply only complete server-visible ledger groups; acknowledgements never become watermarks.
function Profile.applyChanges(self: Profile, page: Wire.PlayerChangesItem, since: number): boolean
	if #self._sent > 0 or self._recovering then
		return true -- Do not advance the cursor until the own-commit snapshot barrier completes.
	end
	if self._closed then
		return false
	end
	if
		not counter(page.nextSinceSeq)
		or not counter(page.latestSeq)
		or page.nextSinceSeq < since
		or page.nextSinceSeq > page.latestSeq
	then
		self:_invalidate()
		return false
	end
	-- A concurrent snapshot can already cover this response. Never rewind its cursor.
	if page.nextSinceSeq < self.seq then
		return true
	end
	if page.needsSnapshot or self._stale or self._schemaVersion ~= self._schema:version() then
		self:_invalidate(page.nextSinceSeq)
		return false
	end
	local entries = table.clone(page.entries)
	table.sort(entries, function(a, b)
		return if a.seq == b.seq then a.ordinal < b.ordinal else a.seq < b.seq
	end)
	local groups: { { Wire.ResultItem } } = {}
	local lastSeq: number? = nil
	local ordinal = -1
	for _, entry in entries do
		if
			not counter(entry.seq)
			or entry.seq <= since
			or entry.seq > page.nextSinceSeq
			or entry.subject ~= self._user
			or tostring(entry.universeId) ~= self._universe
			or type(entry.field) ~= "string"
			or not counter(entry.ordinal)
			or not counter(entry.versionAfter)
			or entry.versionAfter == 0
			or entry.afterSize > 16384
			or not entry.afterExists
			or entry.after == nil
			or (entry.afterHash ~= nil and (entry.afterHash :: any) ~= Json.null)
			or entry.refType == "migration"
		then
			self:_invalidate(page.nextSinceSeq)
			return false
		end
		if lastSeq ~= entry.seq then
			table.insert(groups, {})
			lastSeq = entry.seq
			ordinal = -1
		end
		if entry.ordinal <= ordinal then
			self:_invalidate(page.nextSinceSeq)
			return false
		end
		ordinal = entry.ordinal
		table.insert(groups[#groups], {
			subject = entry.subject,
			field = entry.field,
			path = entry.path,
			op = entry.op,
			before = entry.before,
			after = entry.after,
			version = entry.versionAfter,
			entryId = entry.entryId or Json.null,
		})
	end
	for _, items in groups do
		if not self:apply(({ results = items } :: any) :: Wire.Result, "external") then
			self:_invalidate(page.nextSinceSeq)
			return false
		end
	end
	self.seq = math.max(self.seq, page.nextSinceSeq)
	return true
end
--- Build an owned transaction that updates this profile after acknowledgement, not before commit.
function Profile.immediate(self: Profile): Transaction.Transaction
	return self._io.transaction(function(result)
		if not self._closed then
			if #self._sent > 0 or self._recovering then
				self._epoch += 1
				self._stale = true
				return
			end
			self:apply(result)
		end
	end)
end
--- Drain complete sequence groups using nextSinceSeq, then snapshot NONE-history/computed/hash-only changes.
function Profile.pullChanges(self: Profile, opts: Core.CallOptions?): Core.Result<boolean>
	if self._closed then
		return System.failure("profile_closed")
	end
	local cursor = self.seq
	for _ = 1, 10000 do
		local result = self._io.changes(cursor, opts)
		if not result.ok then
			self.lastError = result.error
			return result
		end
		local page = result.value
		if self._schemaVersion ~= self._schema:version() then
			self._stale = true
		end
		if
			not counter(page.nextSinceSeq)
			or not counter(page.latestSeq)
			or page.nextSinceSeq < cursor
			or page.nextSinceSeq > page.latestSeq
		then
			return System.failure("invalid_changes_cursor")
		end
		if page.nextSinceSeq >= page.latestSeq then
			if page.latestSeq > self.seq or self._stale then
				return self:refresh(opts)
			end
			return { ok = true, value = true }
		end
		if page.nextSinceSeq == cursor then
			return System.failure("invalid_changes_cursor")
		end
		cursor = page.nextSinceSeq
	end
	return System.failure("changes_limit")
end
--- Publish the current lease and expose session_conflict without overriding the holder.
function Profile.heartbeat(self: Profile, opts: Core.CallOptions?): Core.Result<Wire.Presence>
	if self._closed or self._stopping or not self._session then
		return System.failure("presence_not_started")
	end
	local result =
		self._io.presence({ online = true, placeId = self._place, sessionId = self._session }, opts)
	if not result.ok then
		self.lastError = result.error
	else
		self.lastError = nil
	end
	return result
end
--- Reschedule a single heartbeat after completion; failures remain observable and bounded.
local function heartbeat(self: Profile)
	self._timer = self._runtime.delay(self._heartbeat, function()
		self._timer = nil
		if self._closed or not self._session then
			return
		end
		local result = self:heartbeat({ signal = self._signal })
		if not result.ok and result.error.code == "session_conflict" then
			return
		end
		if not self._closed and not self._stopping and self._session then
			heartbeat(self)
		end
	end)
end
--- Acquire a session, then start serial heartbeats only after successful acquisition.
function Profile.startPresence(
	self: Profile,
	placeId: number,
	sessionId: string?,
	interval: number?
): Core.Result<Wire.Presence>
	if self._closed or self._session then
		return System.failure("invalid_request")
	end
	local seconds = interval or 30
	if seconds < 1 or seconds > 60 or seconds ~= seconds then
		return System.failure("invalid_request")
	end
	self._stopping = false
	self._session = sessionId or Copy.key(self._runtime)
	self._place = placeId
	self._heartbeat = seconds
	local result = self:heartbeat()
	if result.ok then
		heartbeat(self)
	else
		self._session = nil
	end
	return result
end
--- Stop future heartbeats and release only this session; retain identity on an uncertain release.
function Profile.stopPresence(self: Profile, opts: Core.CallOptions?): Core.Result<boolean>
	self._stopping = true
	local deadline = if opts and opts.deadline then opts.deadline else self._runtime.now() + 15
	while self._presenceBusy and self._runtime.now() < deadline do
		self._runtime.wait(0.01)
	end
	if self._presenceBusy then
		return Errors.make("Timeout", "fields.putPresence", 0, "Presence shutdown deadline exceeded")
	end
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
	if not self._session then
		return { ok = true, value = true }
	end
	local result =
		self._io.presence({ online = false, placeId = self._place, sessionId = self._session }, opts)
	if not result.ok then
		self.lastError = result.error
		return result
	end
	self._session = nil
	return { ok = true, value = true }
end
--- Release presence within the owning client's remaining shutdown deadline.
function Profile.close(self: Profile, deadline: number): boolean
	if self._releaseLease then
		return self._releaseLease(deadline)
	end
	local result = self:stopPresence({ deadline = deadline, priority = "critical" })
	self:destroy()
	return result.ok
end
--- Cancel background activity without issuing any new requests.
function Profile.destroy(self: Profile)
	if self._closed then
		return
	end
	self._closed = true
	if self._onRelease then
		self._onRelease()
		self._onRelease = nil
	end
	self._onChange = nil
	self.Changed:destroy()
	self._signal.cancelled = true
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
end
--- Release this profile and its owned presence/background registration.
function Profile.release(self: Profile): boolean
	return self:close(self._runtime.now() + 15)
end
return table.freeze(Profile)
