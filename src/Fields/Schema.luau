--!strict
local Core = require("../Types/Core")
local Types = require("../Types/Fields")
local TypeSystem = require("./TypeSystem")
local Cache = require("../Core/Cache")
local Copy = require("../Core/Idempotency")
local Json = require("../Core/Json")
local Config = require("../Core/Config")
local Schema = {}
Schema.__index = Schema
export type Schema = typeof(setmetatable(
	{} :: {
		_runtime: Core.Runtime,
		_fetch: (Core.CallOptions) -> Core.Result<Types.SchemaResponse>,
		_version: number?,
		_definitions: { [string]: Types.Definition },
		_validators: { [string]: TypeSystem.Validator },
		_signal: Core.Signal,
		_busy: boolean,
		_timer: thread?,
		_interval: number,
		LastError: Core.BloxError?,
	},
	Schema
))
--- Schedule one refresh after the previous request completes; no overlapping background workers.
local function schedule(self: Schema)
	self._timer = self._runtime.delay(self._interval, function()
		self._timer = nil
		if not self._signal.cancelled then
			self:Refresh()
		end
	end)
end
--- Create a lazy cache; Load/Refresh performs the first request and starts bounded polling.
function Schema.new(
	runtime: Core.Runtime,
	fetch: (Core.CallOptions) -> Core.Result<Types.SchemaResponse>,
	interval: number?
): Schema
	return setmetatable({
		_runtime = runtime,
		_fetch = fetch,
		_version = nil,
		_definitions = {},
		_validators = {},
		_signal = { cancelled = false },
		_busy = false,
		_timer = nil,
		_interval = Config.number(interval, 30, 0.01, 3600, "schema interval"),
		LastError = nil,
	}, Schema)
end
--- Enforce the server identifier grammar before constructing nested document namespaces.
local function validId(id: string): boolean
	if #id > 200 then
		return false
	end
	local parts = string.split(id, ".")
	if #parts > 8 then
		return false
	end
	for _, part in parts do
		if #part > 64 or not string.match(part, "^[A-Za-z][A-Za-z0-9_]*$") then
			return false
		end
	end
	return true
end
--- Atomically publish a complete validated generation, keeping last-good on every failure.
function Schema.Refresh(self: Schema): Core.Result<number>
	if self._signal.cancelled then
		return TypeSystem.failure("schema_closed")
	end
	while self._busy and not self._signal.cancelled do
		self._runtime.wait(0.01)
	end
	if self._signal.cancelled then
		return TypeSystem.failure("schema_closed")
	end
	self._busy = true
	local ok, result = pcall(self._fetch, { signal = self._signal, cacheTtl = 0 })
	local response: Core.Result<Types.SchemaResponse> = if ok
		then result
		else TypeSystem.failure("schema_unavailable")
	if response.ok then
		local value = response.value
		if
			value.schemaVersion % 1 ~= 0
			or value.schemaVersion < 0
			or value.schemaVersion > 9007199254740991
			or self._version and value.schemaVersion < self._version
		then
			response = TypeSystem.failure("invalid_schema")
		elseif self._version ~= value.schemaVersion then
			local defs: { [string]: Types.Definition } = {}
			local validators: { [string]: TypeSystem.Validator } = {}
			for _, definition in value.definitions do
				if defs[definition.id] or not validId(definition.id) then
					response = TypeSystem.failure("invalid_schema")
					break
				end
				local hasType = definition.type ~= nil and (definition.type :: any) ~= Json.null
				local hasComputed = definition.computed ~= nil and (definition.computed :: any) ~= Json.null
				if hasType == hasComputed then
					response = TypeSystem.failure("invalid_schema")
					break
				end
				if
					hasComputed
					and (
						type((definition.computed :: any).expression) ~= "string"
						or not table.find({ "int", "number" }, (definition.computed :: any).returns)
					)
				then
					response = TypeSystem.failure("invalid_schema")
					break
				end
				defs[definition.id] = definition
				if definition.type ~= nil and (definition.type :: any) ~= Json.null then
					local compiled = TypeSystem.compile(definition.type)
					if not compiled.ok then
						response = compiled
						break
					end
					local default = compiled.value.Default(definition.default)
					if not default.ok then
						response = default
						break
					end
					validators[definition.id] = compiled.value
				elseif not definition.computed or (definition.computed :: any) == Json.null then
					response = TypeSystem.failure("invalid_schema")
					break
				end
			end
			local ids: { string } = {}
			for id in defs do
				table.insert(ids, id)
			end
			table.sort(ids)
			for i = 2, #ids do
				if string.sub(ids[i], 1, #ids[i - 1] + 1) == ids[i - 1] .. "." then
					response = TypeSystem.failure("invalid_schema")
					break
				end
			end
			if response.ok and not self._signal.cancelled then
				self._definitions = Cache.freeze(Copy.copy(defs))
				self._validators = Cache.freeze(validators)
				self._version = value.schemaVersion
			end
		end
	end
	self._busy = false
	if not self._timer and not self._signal.cancelled then
		schedule(self)
	end
	if not response.ok then
		self.LastError = response.error
		return response
	end
	if self._signal.cancelled then
		return TypeSystem.failure("schema_closed")
	end
	self.LastError = nil
	return { ok = true, value = self._version :: number }
end
--- Return the cached generation, or synchronously load the first one (never discard last-good).
function Schema.Load(self: Schema): Core.Result<number>
	if self._version ~= nil and not self._signal.cancelled then
		return { ok = true, value = self._version }
	end
	return self:Refresh()
end
--- Expose immutable definitions, including archived/computed/shared metadata.
function Schema.Definitions(self: Schema): { [string]: Types.Definition }
	return self._definitions
end
--- Resolve a definition without implicitly fetching or masking unknown ids.
function Schema.Get(self: Schema, id: string): Types.Definition?
	return self._definitions[id]
end
--- Return the compiled validator for a stored field only.
function Schema.Validator(self: Schema, id: string): TypeSystem.Validator?
	return self._validators[id]
end
--- Report the last successfully applied schema watermark.
function Schema.Version(self: Schema): number?
	return self._version
end
--- Stop timers and prevent late HTTP completions from publishing state.
function Schema.Destroy(self: Schema)
	self._signal.cancelled = true
	if self._timer then
		self._runtime.cancel(self._timer)
		self._timer = nil
	end
end
return table.freeze(Schema)
