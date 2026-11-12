--!strict
local Core = require("../Types/Core")
local Wire = require("../Types/Fields")
local Types = require("./Types")
local Helpers = require("./Client")
local Operations = require("./Operations")
local Scope = require("./Scope")
local Control = require("./Control")
local System = require("./TypeSystem")
local Json = require("../Core/Json")
local Copy = require("../Core/Idempotency")
local Cache = require("../Core/Cache")
local Errors = require("../Core/Errors")
local Jobs = {}
Jobs.__index = Jobs
export type WaitOptions = { timeout: number?, onProgress: ((Wire.JobReceipt) -> ())?, signal: Core.Signal? }
export type ImportOptions = { dryRun: boolean?, reason: string, idempotencyKey: string? }
export type Client = typeof(setmetatable({} :: { _scope: Scope.Scope }, Jobs))
--- Bind ADMIN job controls without starting polls or fetching schema.
function Jobs.new(state: Helpers.State, universe: string | number): Client
	return setmetatable({ _scope = Scope.new(state, universe) }, Jobs)
end
--- Read current progress; completion may still contain per-item failures.
function Jobs.get(self: Client, id: string, options: Core.CallOptions?): Core.Result<Wire.JobReceipt>
	return Scope.call(self._scope, "fields.job", { path = { id = id } }, options)
end
--- List bounded summaries (offset pagination, not the cursor protocol).
function Jobs.list(
	self: Client,
	query: { limit: number?, offset: number? }?,
	options: Core.CallOptions?
): Core.Result<{ Wire.JobSummary }>
	return Scope.call(self._scope, "fields.jobs", { query = query }, options)
end
--- Read up to 200 audit transitions after an event ID.
function Jobs.events(
	self: Client,
	id: string,
	after: number?,
	options: Core.CallOptions?
): Core.Result<{ Wire.JobEvent }>
	return Scope.call(
		self._scope,
		"fields.jobEvents",
		{ path = { id = id }, query = { after = after } },
		options
	)
end
--- Read bounded failure details after a manifest ordinal.
function Jobs.failures(
	self: Client,
	id: string,
	query: { after: number?, limit: number? }?,
	options: Core.CallOptions?
): Core.Result<{ Wire.JobFailure }>
	return Scope.call(self._scope, "fields.jobFailures", { path = { id = id }, query = query }, options)
end
--- Download a completed export as raw NDJSON; HttpService buffers the whole response.
function Jobs.download(self: Client, id: string, options: Core.CallOptions?): Core.Result<string>
	return Scope.call(self._scope, "fields.jobDownload", { path = { id = id } }, options)
end
--- Download raw NDJSON failure records, not a JSON array or a public URL.
function Jobs.downloadFailures(self: Client, id: string, options: Core.CallOptions?): Core.Result<string>
	return Scope.call(self._scope, "fields.jobFailuresDownload", { path = { id = id } }, options)
end
--- Request durable cancellation without rolling back already committed bulk/import effects.
function Jobs.cancel(
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
		"fields.cancelJob",
		{ path = { id = id }, body = { reason = reason } },
		options
	)
end
--- Explicitly retry a FAILED job at its existing checkpoint; never invoked implicitly by waitFor.
function Jobs.retry(
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
		"fields.retryJob",
		{ path = { id = id }, body = { reason = reason } },
		options
	)
end
--- Poll with a total deadline and .25..5 second capped exponential delay, without a background task.
function Jobs.waitFor(self: Client, id: string, options: WaitOptions?): Core.Result<Wire.JobReceipt>
	local opts: WaitOptions = if options == nil then {} else options
	local raw: any = opts
	if not Control.object(raw, { "timeout", "onProgress", "signal" }) then
		return System.failure("invalid_request")
	end
	local timeout = if opts.timeout == nil then 60 else opts.timeout
	if
		not Control.object(raw, { "timeout", "onProgress", "signal" })
		or type(timeout) ~= "number"
		or timeout ~= timeout
		or timeout <= 0
		or timeout > 3600
		or raw.onProgress ~= nil and type(raw.onProgress) ~= "function"
		or raw.signal ~= nil
			and (not Control.object(raw.signal, { "cancelled" }) or type(raw.signal.cancelled) ~= "boolean")
	then
		return System.failure("invalid_request")
	end
	local state = self._scope.state
	local runtime = state.runtime
	local deadline = runtime.now() + timeout
	local interval = 0.25
	--- Observe both explicit cancellation and shared client shutdown between calls and sleeps.
	local function stopped(): Core.Result<Wire.JobReceipt>?
		if state.closed or opts.signal and opts.signal.cancelled then
			return Errors.make("Cancelled", "fields.job", 0, "Job wait cancelled")
		end
		if runtime.now() >= deadline then
			return Errors.make("Timeout", "fields.job", 0, "Job wait deadline exceeded")
		end
		return nil
	end
	while true do
		local stop = stopped()
		if stop then
			return stop
		end
		local result = self:get(id, { deadline = deadline, cacheTtl = 0, retry = 0, signal = opts.signal })
		if not result.ok then
			return result
		end
		stop = stopped()
		if stop then
			return stop
		end
		if opts.onProgress then
			local progress = Cache.freeze(Copy.copy(result.value))
			local ok = pcall(opts.onProgress, progress)
			if not ok then
				return Errors.make("Local", "fields.job", 0, "Progress callback failed")
			end
		end
		stop = stopped()
		if stop then
			return stop
		end
		local status = result.value.state
		if status == "SUCCEEDED" or status == "FAILED" or status == "CANCELLED" then
			return result
		end
		local untilTime = math.min(deadline, runtime.now() + interval)
		while runtime.now() < untilTime do
			stop = stopped()
			if stop then
				return stop
			end
			runtime.wait(math.min(0.1, untilTime - runtime.now()))
		end
		interval = math.min(5, interval * 2)
	end
end
--- Build a schema-checked export request; explicit projections are required above 100 stored fields.
function Jobs.buildExport(self: Client, input: Wire.ExportInput): Core.Result<Wire.ExportInput>
	if self._scope.state.closed then
		return Errors.make("Cancelled", "fields.export", 0, "Client is closed")
	end
	local raw: any = input
	if
		not Control.object(raw, { "universeId", "target", "fields", "reason", "idempotencyKey" })
		or not Control.reason(raw.reason)
		or raw.universeId ~= nil and (not Control.subject(raw.universeId) or tostring(raw.universeId) ~= tostring(
			self._scope.universe
		))
		or raw.idempotencyKey ~= nil and not Control.key(raw.idempotencyKey)
	then
		return System.failure("invalid_request")
	end
	local schema = Helpers.schema(self._scope.state, self._scope.universe)
	local target = Control.target(schema, if raw.target == nil then { kind = "ALL" } else raw.target)
	if not target.ok then
		return target
	end
	local ids: { string } = {}
	if raw.fields ~= nil then
		if not Control.array(raw.fields, 1, 100) then
			return System.failure("invalid_request")
		end
		local seen: { [string]: boolean } = {}
		for _, id in raw.fields do
			if type(id) ~= "string" or seen[id] then
				return System.failure("invalid_request")
			end
			local d = schema:get(id)
			if not d or not schema:validator(id) then
				return System.failure("unknown_field")
			end
			seen[id] = true
			table.insert(ids, id)
		end
	else
		for id in schema:definitions() do
			if schema:validator(id) then
				table.insert(ids, id)
			end
		end
		if #ids > 100 then
			return System.failure("invalid_request")
		end
		table.sort(ids)
	end
	return {
		ok = true,
		value = {
			target = target.value,
			fields = if raw.fields ~= nil then Json.array(ids) else nil,
			reason = raw.reason,
			idempotencyKey = raw.idempotencyKey or Copy.key(self._scope.state.runtime),
		},
	}
end
--- Queue an ADMIN export; even READ_WRITE callers cannot export player data.
function Jobs.export(
	self: Client,
	input: Wire.ExportInput,
	options: Core.CallOptions?
): Core.Result<Wire.JobReceipt>
	local built = self:buildExport(input)
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.export", { body = built.value }, options)
end
--- Validate SET/ADD records through the existing operation TypeSystem and encode bounded NDJSON.
function Jobs.buildImport(self: Client, records: { Types.ImportRecord }): Core.Result<string>
	if self._scope.state.closed then
		return Errors.make("Cancelled", "fields.import", 0, "Client is closed")
	end
	if not Control.array(records, 1, 100000) then
		return System.failure("invalid_request")
	end
	local schema = Helpers.schema(self._scope.state, self._scope.universe)
	if schema:version() == nil then
		return System.failure("schema_unavailable")
	end
	local lines: { string } = table.create(#records)
	local bytes = 0
	for _, record in records do
		local row: any = record
		if
			not Control.object(row, { "subject", "field", "op", "value", "delta", "universeId" })
			or not Control.subject(row.subject)
			or row.universeId ~= nil and (not Control.subject(row.universeId) or tostring(row.universeId) ~= tostring(
				self._scope.universe
			))
			or row.op ~= "SET" and row.op ~= "ADD"
		then
			return System.failure("invalid_request")
		end
		local op: any = table.clone(row)
		op.subject = nil
		op.universeId = nil
		local prepared = Operations.prepare(schema, { op })
		if not prepared.ok then
			return prepared
		end
		local item: any = prepared.value[1]
		item.subject = row.subject
		local ok, line = pcall(Json.encode, item)
		if not ok then
			return System.failure("invalid_request")
		end
		bytes += #line + 1
		if bytes > 16 * 1024 * 1024 then
			return System.failure("invalid_request")
		end
		table.insert(lines, line)
	end
	return { ok = true, value = table.concat(lines, "\n") .. "\n" }
end
--- Default to read-only import validation; apply requires an explicit persistent header key.
function Jobs.import(
	self: Client,
	records: { Types.ImportRecord },
	input: ImportOptions,
	options: Core.CallOptions?
): Core.Result<Wire.ImportValidation | Wire.JobReceipt>
	local raw: any = input
	if
		not Control.object(raw, { "dryRun", "reason", "idempotencyKey" })
		or not Control.reason(raw.reason)
		or raw.dryRun ~= nil and type(raw.dryRun) ~= "boolean"
		or raw.idempotencyKey ~= nil and not Control.key(raw.idempotencyKey)
		or raw.dryRun == false and not Control.key(raw.idempotencyKey)
	then
		return System.failure("invalid_request")
	end
	local built = self:buildImport(records)
	if not built.ok then
		return built
	end
	return Scope.call(self._scope, "fields.import", {
		body = built.value,
		query = { dryRun = raw.dryRun, reason = raw.reason },
		idempotencyKey = raw.idempotencyKey,
	}, options)
end
return table.freeze(Jobs)
