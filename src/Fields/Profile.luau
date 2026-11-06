--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Schema = require("./Schema")
local Transaction = require("./Transaction")
local System = require("./TypeSystem")
local Copy = require("../Core/Idempotency")
local Cache = require("../Core/Cache")
local Json = require("../Core/Json")
local Errors = require("../Core/Errors")
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
		_runtime: Core.Runtime,
		_schema: Schema.Schema,
		_io: IO,
		_user: number,
		_data: { [string]: Core.Json },
		Versions: { [string]: number },
		Seq: number,
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
		LastError: Core.BloxError?,
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
		_runtime = runtime,
		_schema = schema,
		_user = user,
		_io = io,
		_data = {},
		Versions = {},
		Seq = 0,
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
		LastError = nil,
	}, Profile)
end
--- Fetch and validate a complete snapshot; concurrent local commits cannot be overwritten by old reads.
function Profile.Refresh(self: Profile, opts: Core.CallOptions?): Core.Result<boolean>
	if self._closed then
		return System.failure("profile_closed")
	end
	local epoch = self._epoch
	local result = self._io.document(opts)
	if not result.ok then
		self.LastError = result.error
		return result
	end
	if self._closed then
		return System.failure("profile_closed")
	end
	local document = result.value
	if
		document.userId ~= self._user
		or document.seq % 1 ~= 0
		or document.seq < self.Seq
		or epoch ~= self._epoch
	then
		return System.failure("snapshot_race")
	end
	local data: { [string]: Core.Json } = {}
	for id, definition in self._schema:Definitions() do
		if definition.status == "ACTIVE" and definition.scope == "PLAYER" then
			local value = read(document.data, id)
			local validator = self._schema:Validator(id)
			if validator then
				local validated = validator.Validate(value)
				if not validated.ok then
					return validated
				end
				value = validated.value
			elseif definition.computed and (definition.computed :: any) ~= Json.null then
				local checked =
					System.validate({ kind = "nullable", of = { kind = definition.computed.returns } }, value)
				if not checked.ok then
					return checked
				end
				value = checked.value
			else
				return System.failure("missing_value")
			end
			if
				document.versions[id] == nil
				or document.versions[id] < 0
				or document.versions[id] % 1 ~= 0
			then
				return System.failure("invalid_version")
			end
			put(data, id, value)
		end
	end
	self._data = Cache.freeze(data)
	self.Versions = Cache.freeze(Copy.copy(document.versions))
	self.Seq = document.seq
	self._stale = false
	self._epoch += 1
	self.LastError = nil
	return { ok = true, value = true }
end
--- Return a validated immutable value; unknown/archived ids and stale snapshots return typed errors.
function Profile.TryGet(self: Profile, id: string): Core.Result<Core.Json>
	if self._closed then
		return System.failure("profile_closed")
	end
	local definition = self._schema:Get(id)
	if not definition then
		return System.failure("unknown_field", nil, id)
	end
	if definition.status == "ARCHIVED" then
		return System.failure("field_archived", nil, id)
	end
	if definition.scope ~= "PLAYER" then
		return System.failure("field_scope_mismatch", nil, id)
	end
	if self._stale then
		return System.failure("profile_stale", nil, id)
	end
	local value = read(self._data, id)
	if value == nil then
		return System.failure("missing_value", nil, id)
	end
	return { ok = true, value = value }
end
--- Synchronous getter for generated static accessors; throws only a value-free typed code on misuse.
function Profile.Get(self: Profile, id: string): Core.Json
	local result = self:TryGet(id)
	if not result.ok then
		error(result.error.code or "profile_error", 2)
	end
	return result.value
end
--- Apply returned subvalues, not deltas, exactly once after a successful transaction acknowledgement.
function Profile.Apply(self: Profile, result: Wire.Result): boolean
	local seq = result.seq[tostring(self._user)]
	if not seq or seq <= self.Seq then
		return true
	end
	self._epoch += 1
	if self._stale or seq ~= self.Seq + 1 then
		self._stale = true
		return false
	end
	local data = Copy.copy(self._data)
	local versions = Copy.copy(self.Versions)
	for _, item in result.results do
		if item.subject == self._user then
			local definition = self._schema:Get(item.field)
			if not definition or not definition.type then
				self._stale = true
				return false
			end
			local current = read(data, item.field)
			local replacement = System.apply(
				definition.type,
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
		end
	end
	-- Computed results require a fresh coherent server snapshot, never client-side arithmetic authority.
	for _, definition in self._schema:Definitions() do
		if
			definition.status == "ACTIVE"
			and definition.computed
			and (definition.computed :: any) ~= Json.null
		then
			self._stale = true
		end
	end
	self._data = Cache.freeze(data)
	self.Versions = Cache.freeze(versions)
	self.Seq = seq
	return not self._stale
end
--- Build an owned transaction that updates this profile after acknowledgement, not before commit.
function Profile.Transaction(self: Profile): Transaction.Transaction
	return self._io.transaction(function(result)
		if not self._closed then
			self:Apply(result)
		end
	end)
end
--- Drain complete sequence groups using nextSinceSeq, then snapshot NONE-history/computed/hash-only changes.
function Profile.PullChanges(self: Profile, opts: Core.CallOptions?): Core.Result<boolean>
	if self._closed then
		return System.failure("profile_closed")
	end
	local cursor = self.Seq
	for _ = 1, 10000 do
		local result = self._io.changes(cursor, opts)
		if not result.ok then
			self.LastError = result.error
			return result
		end
		local page = result.value
		if page.nextSinceSeq < cursor or page.nextSinceSeq > page.latestSeq then
			return System.failure("invalid_changes_cursor")
		end
		if page.nextSinceSeq >= page.latestSeq then
			if page.latestSeq > self.Seq or self._stale then
				return self:Refresh(opts)
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
function Profile.Heartbeat(self: Profile, opts: Core.CallOptions?): Core.Result<Wire.Presence>
	if self._closed or self._stopping or not self._session then
		return System.failure("presence_not_started")
	end
	local result =
		self._io.presence({ online = true, placeId = self._place, sessionId = self._session }, opts)
	if not result.ok then
		self.LastError = result.error
	else
		self.LastError = nil
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
		local result = self:Heartbeat({ signal = self._signal })
		if not result.ok and result.error.code == "session_conflict" then
			return
		end
		if not self._closed and not self._stopping and self._session then
			heartbeat(self)
		end
	end)
end
--- Acquire a session, then start serial heartbeats only after successful acquisition.
function Profile.StartPresence(
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
	local result = self:Heartbeat()
	if result.ok then
		heartbeat(self)
	else
		self._session = nil
	end
	return result
end
--- Stop future heartbeats and release only this session; retain identity on an uncertain release.
function Profile.StopPresence(self: Profile, opts: Core.CallOptions?): Core.Result<boolean>
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
		self.LastError = result.error
		return result
	end
	self._session = nil
	return { ok = true, value = true }
end
--- Release presence within the owning client's remaining shutdown deadline.
function Profile.Close(self: Profile, deadline: number): boolean
	local result = self:StopPresence({ deadline = deadline, priority = "critical" })
	self:Destroy()
	return result.ok
end
--- Cancel background activity without issuing any new requests.
function Profile.Destroy(self: Profile)
	self._closed = true
	self._signal.cancelled = true
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
end
return table.freeze(Profile)
