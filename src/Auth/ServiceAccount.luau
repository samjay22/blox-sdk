--!strict
local Types = require("../Types/Core")
local Universe = require("../Core/Universe")
local ServiceAccount = {}
--- The environment a readable key is bound to: `bsa_` is prod, `bsd_` is dev; nil for any other prefix.
function ServiceAccount.environment(key: string): Types.Environment?
	local prefix = string.sub(key, 1, 4)
	if prefix == "bsa_" then
		return "prod"
	elseif prefix == "bsd_" then
		return "dev"
	end
	return nil
end
--- Validate only readable keys; opaque Roblox Secrets cannot be inspected locally.
function ServiceAccount.valid(key: string): boolean
	if #key ~= 56 then
		return false
	end
	local prefix, suffix = string.match(key, "^bs[ad]_([A-Za-z0-9_-]+)_([A-Za-z0-9_-]+)$")
	-- Fixed offsets avoid greedy underscore matching in base64url material.
	return prefix ~= nil
		and suffix ~= nil
		and string.sub(key, 13, 13) == "_"
		and string.match(string.sub(key, 5, 12), "^[A-Za-z0-9_-]+$") ~= nil
		and string.match(string.sub(key, 14), "^[A-Za-z0-9_-]+$") ~= nil
end
--- Capture the credential privately; provider tables and errors never contain it.
function ServiceAccount.new(
	key: string | Types.Secret,
	universeId: string | number,
	levels: Types.ServiceLevels?,
	environment: Types.Environment?
): Types.AuthProvider
	assert(Universe.valid(universeId), "Invalid universeId")
	local bound = environment
	if type(key) == "string" then
		assert(
			ServiceAccount.environment(key) ~= nil,
			"Unknown API key prefix: expected bsa_ (prod) or bsd_ (dev)"
		)
		assert(ServiceAccount.valid(key), "Invalid service account key format")
		bound = ServiceAccount.environment(key)
	end
	assert(bound == "dev" or bound == "prod", 'A Roblox Secret key needs environment = "dev" or "prod"')
	-- Bearer headers are immutable. Build once without retaining the unprefixed credential.
	local credential: (string | Types.Secret)? = if type(key) == "string"
		then "Bearer " .. key
		else key:AddPrefix("Bearer ")
	local grants: { [string]: Types.Level }? = nil
	if levels then
		local normalized: { [string]: Types.Level } = {}
		for name, level in levels do
			assert(
				type(name) == "string" and (level == "READ" or level == "READ_WRITE" or level == "ADMIN"),
				"Invalid service access level"
			)
			if level then
				normalized[name] = level
			end
		end
		grants = table.freeze(normalized)
	end
	local provider: Types.AuthProvider = {
		kind = "serviceAccount",
		universeId = universeId,
		environment = bound,
		levels = grants,
		apply = function(headers: Types.Headers)
			local current = credential
			assert(current ~= nil, "Auth provider destroyed")
			headers.Authorization = current
		end,
		onUnauthorized = function(_version: number?): boolean
			return false
		end,
		destroy = function()
			credential = nil
		end,
	}
	return table.freeze(provider)
end
return table.freeze(ServiceAccount)
