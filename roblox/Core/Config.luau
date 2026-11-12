--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Session = require(script.Parent.Parent.Auth.UserSession)
local Auth = require(script.Parent.Parent.Types.Auth)
local Universe = require(script.Parent.Parent.Core.Universe)
local Routing = require(script.Parent.Parent.Core.Routing)
local Config = {}
export type ServiceConfig = { baseUrl: string? }
export type ProfileSyncConfig = {
	enabled: boolean?,
	budgetThreshold: number?,
	maxConcurrentReloads: number?,
	resyncSeconds: number?,
}
export type SessionConfig = {
	serverId: string?,
	ttlMs: number?,
	flushInterval: number?,
	acquireTimeout: number?,
	kickOnFailure: boolean?,
	kickOnLeaseLost: boolean?,
}
export type Config = {
	sessions: SessionConfig?,
	batch: { intervalSeconds: number? }?,
	profileSync: ProfileSyncConfig?,
	backend: Types.Backend?,
	runtime: Types.Runtime?,
	authProvider: Types.AuthProvider?,
	key: string?,
	secretName: string?,
	universeId: (string | number)?,
	levels: Types.ServiceLevels?,
	userSession: { store: Session.TokenStore?, role: Auth.AccountType? }?,
	gatewayUrl: string?,
	services: { [string]: ServiceConfig }?,
	concurrency: number?,
	queueCapacity: number?,
	requestsPerMinute: number?,
	burst: number?,
	criticalReserve: number?,
	retries: number?,
	retryRatio: number?,
	timeout: number?,
	cacheCapacity: number?,
	staleIfError: number?,
	hooks: Types.Hooks?,
	logger: Types.Logger?,
}
local known = table.freeze({
	sessions = true,
	batch = true,
	profileSync = true,
	backend = true,
	runtime = true,
	authProvider = true,
	key = true,
	secretName = true,
	universeId = true,
	levels = true,
	userSession = true,
	gatewayUrl = true,
	services = true,
	concurrency = true,
	queueCapacity = true,
	requestsPerMinute = true,
	burst = true,
	criticalReserve = true,
	retries = true,
	retryRatio = true,
	timeout = true,
	cacheCapacity = true,
	staleIfError = true,
	hooks = true,
	logger = true,
})
--- Validate structural configuration without rendering values or credentials in messages.
function Config.validate(config: Config)
	for name in config :: any do
		assert(known[name], "Unknown config field")
	end
	assert(config.logger == nil or type(config.logger) == "function", "logger must be callable")
	if config.hooks ~= nil then
		assert(type(config.hooks) == "table", "hooks must be a table")
		for name, hook in config.hooks :: any do
			assert(
				table.find({ "onRequest", "onResponse", "onRetry", "onBreakerChange", "onRateLimited" }, name)
						~= nil
					and type(hook) == "function",
				"Invalid hook"
			)
		end
	end
	if config.batch ~= nil then
		assert(type(config.batch) == "table", "batch must be a table")
		for name in config.batch :: any do
			assert(name == "intervalSeconds", "Unknown batch field")
		end
	end
	if config.profileSync ~= nil then
		assert(type(config.profileSync) == "table", "profileSync must be a table")
		for name in config.profileSync :: any do
			assert(
				table.find({ "enabled", "budgetThreshold", "maxConcurrentReloads", "resyncSeconds" }, name),
				"Unknown profileSync field"
			)
		end
		assert(
			config.profileSync.enabled == nil or type(config.profileSync.enabled) == "boolean",
			"Invalid profileSync enabled"
		)
	end
	if config.sessions ~= nil then
		assert(type(config.sessions) == "table", "sessions must be a table")
		for name in config.sessions :: any do
			assert(
				table.find({
					"serverId",
					"ttlMs",
					"flushInterval",
					"acquireTimeout",
					"kickOnFailure",
					"kickOnLeaseLost",
				}, name),
				"Unknown sessions field"
			)
		end
		for _, name in { "kickOnFailure", "kickOnLeaseLost" } do
			local value = (config.sessions :: any)[name]
			assert(value == nil or type(value) == "boolean", "Invalid sessions kick policy")
		end
	end
	if config.key ~= nil then
		assert(type(config.key) == "string", "key must be a string")
	end
	if config.secretName ~= nil then
		assert(
			type(config.secretName) == "string" and #config.secretName > 0,
			"secretName must be a nonempty string"
		)
	end
	if config.universeId ~= nil then
		assert(Universe.valid(config.universeId), "Invalid universeId")
	end
	if config.backend then
		assert(type(config.backend) == "function", "backend must be callable")
	end
	if config.runtime then
		for _, name in { "now", "unix", "random", "wait", "spawn", "delay", "cancel", "encode", "decode" } do
			assert(
				type((config.runtime :: any)[name]) == "function",
				"Runtime is missing a required function"
			)
		end
	end
	if config.levels then
		assert(type(config.levels) == "table", "levels must be a table")
		for _, level in config.levels do
			assert(
				level == "READ" or level == "READ_WRITE" or level == "ADMIN",
				"Invalid service access level"
			)
		end
	end
	if config.authProvider then
		assert(
			type(config.authProvider) == "table"
				and type(config.authProvider.apply) == "function"
				and type(config.authProvider.onUnauthorized) == "function",
			"Invalid AuthProvider"
		)
	end
	if config.userSession then
		assert(type(config.userSession) == "table", "userSession must be a table")
	end
end
--- Validate numeric policy before allocating state; errors include field names, never values.
function Config.number(
	value: number?,
	default: number,
	minimum: number,
	maximum: number,
	name: string,
	integer: boolean?
): number
	local resolved = if value == nil then default else value
	assert(
		type(resolved) == "number"
			and resolved == resolved
			and resolved >= minimum
			and resolved <= maximum
			and (not integer or resolved % 1 == 0),
		"Invalid config: " .. name
	)
	return resolved
end
--- Normalize HTTPS origins without exposing values; allow one optional trailing slash.
local function origin(value: string): string
	assert(type(value) == "string", "URL must be an HTTPS origin")
	value = string.gsub(value, "/$", "")
	local hostname, port = string.match(value, "^https://([A-Za-z0-9][A-Za-z0-9%.%-]*):(%d+)$")
	if not hostname then
		hostname = string.match(value, "^https://([A-Za-z0-9][A-Za-z0-9%.%-]*)$")
	end
	assert(hostname ~= nil, "URL must be an HTTPS origin without paths or credentials")
	if port then
		local number = tonumber(port)
		assert(number ~= nil and number >= 1 and number <= 65535, "Invalid HTTPS port")
		port = if number == 443 then nil else tostring(number)
	end
	return "https://" .. string.lower(hostname) .. (if port then ":" .. port else "")
end
--- Resolve one immutable gateway origin for all operations; direct-service destinations are forbidden.
function Config.resolve(config: Config): { [string]: string }
	local gateway = origin(if config.gatewayUrl == nil then Routing.gatewayUrl else config.gatewayUrl)
	local origins: { [string]: string } = {}
	for service in Routing.prefixes do
		origins[service] = gateway
	end
	assert(config.services == nil, "services overrides removed; configure gatewayUrl for BatchService")
	return table.freeze(origins)
end
return table.freeze(Config)
