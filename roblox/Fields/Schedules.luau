--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Helpers = require(script.Parent.Parent.Fields.Client)
local Scope = require(script.Parent.Parent.Fields.Scope)
local Control = require(script.Parent.Parent.Fields.Control)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Copy = require(script.Parent.Parent.Core.Idempotency)
local Json = require(script.Parent.Parent.Core.Json)
local Errors = require(script.Parent.Parent.Core.Errors)
local Schedules = {}
Schedules.__index = Schedules
export type Client = typeof(setmetatable({} :: { _scope: Scope.Scope }, Schedules))
--- Bind ADMIN live-ops controls; execution is owned by durable service workers, never a local timer.
function Schedules.new(state: Helpers.State, universe: string | number): Client
	return setmetatable({ _scope = Scope.new(state, universe) }, Schedules)
end
--- Snapshot and validate UTC windows and closed Fields-owned runtime actions before any HTTP.
function Schedules.build(self: Client, input: Wire.ScheduleInput): Core.Result<Wire.ScheduleInput>
	if self._scope.state.closed then
		return Errors.make("Cancelled", "fields.createSchedule", 0, "Client is closed")
	end
	local raw: any = input
	if
		not Control.object(raw, {
			"universeId",
			"name",
			"start",
			"end",
			"startActions",
			"endActions",
			"restorePrevious",
			"reason",
			"idempotencyKey",
			"recurrence",
		})
		or not Control.reason(raw.reason)
		or type(raw.name) ~= "string"
		or not string.find(raw.name, "%S")
		or (utf8.len(raw.name) or math.huge) > 100
		or raw.universeId ~= nil and (not Control.subject(raw.universeId) or tostring(raw.universeId) ~= tostring(
			self._scope.universe
		))
		or raw.idempotencyKey ~= nil and not Control.key(raw.idempotencyKey)
		or raw.restorePrevious ~= nil and type(raw.restorePrevious) ~= "boolean"
		or not Control.array(raw.startActions, 1, 32)
		or raw.endActions ~= nil and not Control.array(raw.endActions, 0, 32)
	then
		return System.failure("invalid_request")
	end
	local start, startFraction = Control.instant(raw.start)
	local finish, finishFraction = Control.instant(raw["end"])
	if
		not start
		or raw["end"] ~= nil
			and (not finish or finish < start or finish == start and (finishFraction :: string) <= (startFraction :: string))
	then
		return System.failure("invalid_request")
	end
	if raw.recurrence ~= nil then
		local recurrence = raw.recurrence
		if
			not Control.object(recurrence, { "type", "daysOfWeek", "timezone" })
			or (recurrence.type ~= "NONE" and recurrence.type ~= "DAILY" and recurrence.type ~= "WEEKLY")
			or not Control.array(recurrence.daysOfWeek, 0, 7)
			or type(recurrence.timezone) ~= "string"
			or #recurrence.timezone == 0
			or #recurrence.timezone > 100
			or (recurrence.type == "WEEKLY") ~= (#recurrence.daysOfWeek > 0)
			or (recurrence.type ~= "NONE" and not finish)
		then
			return System.failure("invalid_request")
		end
		local days = {
			MONDAY = true,
			TUESDAY = true,
			WEDNESDAY = true,
			THURSDAY = true,
			FRIDAY = true,
			SATURDAY = true,
			SUNDAY = true,
		}
		local seen: { [string]: boolean } = {}
		for _, day in recurrence.daysOfWeek do
			if type(day) ~= "string" or not days[day] or seen[day] then
				return System.failure("invalid_request")
			end
			seen[day] = true
		end
		-- IANA timezone validity and DST/catch-up behavior belong to the service.
	end
	if raw.restorePrevious and raw.endActions and #raw.endActions > 0 then
		return System.failure("invalid_request")
	end
	for _, edge in { raw.startActions, raw.endActions or {} } do
		local keys: { [string]: boolean } = {}
		for _, action in edge do
			if not Control.action(action) then
				return System.failure("invalid_request")
			end
			if action.kind ~= "RUN_BULK" then
				local key = action.key
				if keys[key] then
					return System.failure("invalid_request")
				end
				keys[key] = true
			end
		end
	end
	local ok, copied = pcall(Copy.copy, input)
	if not ok then
		return System.failure("invalid_request")
	end
	copied.idempotencyKey = copied.idempotencyKey or Copy.key(self._scope.state.runtime)
	copied.startActions = Json.array(copied.startActions)
	if copied.endActions then
		copied.endActions = Json.array(copied.endActions)
	end
	if copied.recurrence then
		copied.recurrence.daysOfWeek = Json.array(copied.recurrence.daysOfWeek)
	end
	return { ok = true, value = copied }
end
--- Preview validated actions without capturing or changing remote configuration.
function Schedules.preview(
	self: Client,
	input: Wire.ScheduleInput,
	options: Core.CallOptions?
): Core.Result<Wire.SchedulePreview>
	local built = self:build(input)
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.schedulePreview", { body = built.value }, options)
end
--- Queue one durable UTC window; retain a built request/key for retries across separate calls.
function Schedules.create(
	self: Client,
	input: Wire.ScheduleInput,
	options: Core.CallOptions?
): Core.Result<Wire.JobReceipt>
	local built = self:build(input)
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.createSchedule", { body = built.value }, options)
end
--- Replace an unstarted schedule; the service's database clock decides eligibility.
function Schedules.edit(
	self: Client,
	id: string,
	input: Wire.ScheduleInput,
	options: Core.CallOptions?
): Core.Result<Wire.JobReceipt>
	local built = self:build(input)
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.editSchedule", { path = { id = id }, body = built.value }, options)
end
--- Read the durable phase and counters without captured config values.
function Schedules.get(self: Client, id: string, options: Core.CallOptions?): Core.Result<Wire.JobReceipt>
	return Scope.call(self._scope, "fields.schedule", { path = { id = id } }, options)
end
--- Read safe per-action diagnostics rather than configuration preimages.
function Schedules.actions(
	self: Client,
	id: string,
	options: Core.CallOptions?
): Core.Result<{ Wire.ScheduleActionResult }>
	return Scope.call(self._scope, "fields.scheduleActions", { path = { id = id } }, options)
end
--- Stop future actions, deliberately leaving already-applied effects in place.
function Schedules.cancel(
	self: Client,
	id: string,
	reason: string,
	options: Core.CallOptions?
): Core.Result<Wire.JobReceipt>
	if not Control.reason(reason) then
		return System.failure("invalid_request")
	end
	return Scope.call(
		self._scope,
		"fields.cancelSchedule",
		{ path = { id = id }, body = { reason = reason } },
		options
	)
end
--- Execute an ACTIVE schedule's end edge once, including configured restoration.
function Schedules.endNow(
	self: Client,
	id: string,
	reason: string,
	options: Core.CallOptions?
): Core.Result<Wire.JobReceipt>
	if not Control.reason(reason) then
		return System.failure("invalid_request")
	end
	return Scope.call(
		self._scope,
		"fields.endSchedule",
		{ path = { id = id }, body = { reason = reason } },
		options
	)
end
return table.freeze(Schedules)
