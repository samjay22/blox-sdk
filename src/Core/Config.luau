--!strict
local Types = require("../Types/Core")
local Session = require("../Auth/UserSession")
local Universe = require("./Universe")
local Config = {}
export type Config = {
	backend: Types.Backend?,
	runtime: Types.Runtime?,
	authProvider: Types.AuthProvider?,
	key: string?,
	secretName: string?,
	universeId: (string | number)?,
	levels: Types.ServiceLevels?,
	userSession: { store: Session.TokenStore?, role: string? }?,
	hosts: { [string]: string }?,
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
}
Config.hosts = table.freeze({
	auth = "https://security.blox-api.com",
	data = "https://data.blox-api.com",
	matchmaking = "https://matchmaking.blox-api.com",
	party = "https://party.blox-api.com",
	codes = "https://codes.blox-api.com",
	audit = "https://audit.blox-api.com",
	config = "https://config.blox-api.com",
	leaderboards = "https://leaderboards.blox-api.com",
	economy = "https://economy.blox-api.com",
})
local known = table.freeze({
	backend = true,
	runtime = true,
	authProvider = true,
	key = true,
	secretName = true,
	universeId = true,
	levels = true,
	userSession = true,
	hosts = true,
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
})
--- Validate structural configuration without rendering values or credentials in messages.
function Config.validate(config: Config)
	for name in config :: any do
		assert(known[name], "Unknown config field")
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
--- Enforce HTTPS origins only, preventing userinfo/query/header-injection credential leaks.
function Config.origins(overrides: { [string]: string }?): { [string]: string }
	local hosts = table.clone(Config.hosts) :: { [string]: string }
	if overrides then
		for service, origin in overrides do
			assert(hosts[service] ~= nil, "Unknown host service")
			assert(type(origin) == "string", "Hosts must be HTTPS origins")
			local hostname, port = string.match(origin, "^https://([A-Za-z0-9][A-Za-z0-9%.%-]*):(%d+)$")
			if not hostname then
				hostname = string.match(origin, "^https://([A-Za-z0-9][A-Za-z0-9%.%-]*)$")
			end
			assert(hostname ~= nil, "Hosts must be HTTPS origins without paths or credentials")
			if port then
				local number = tonumber(port)
				assert(number ~= nil and number >= 1 and number <= 65535, "Invalid HTTPS port")
				port = if number == 443 then nil else tostring(number)
			end
			origin = "https://" .. string.lower(hostname) .. (if port then ":" .. port else "")
			hosts[service] = origin
		end
	end
	return table.freeze(hosts)
end
return table.freeze(Config)
