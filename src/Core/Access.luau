--!strict
local Types = require("../Types/Core")
local Access = {}
local levels = table.freeze({ READ = 1, READ_WRITE = 2, ADMIN = 3 })
--- Reject only known incompatibilities; the backend remains the authorization authority.
function Access.check(
	auth: Types.AuthProvider,
	spec: Types.Endpoint,
	request: Types.Request,
	universe: (string | number)?
): string?
	if not table.find(spec.authKinds, auth.kind) then
		if spec.requiredRole == "SUPER_ADMIN" then
			return "requires super-admin user token"
		end
		return "requires identity user token"
	end
	if auth.kind == "none" and not table.find(spec.authKinds, "none") then
		return "Authentication required"
	end
	if spec.requiredRole == "SUPER_ADMIN" and auth.role and auth.role ~= "SUPER_ADMIN" then
		return "requires super-admin user token"
	end
	if spec.minimumLevel and auth.levels then
		local granted = auth.levels[spec.serviceName]
		if not granted or (levels[granted] or 0) < (levels[spec.minimumLevel] or 0) then
			return "Insufficient " .. spec.serviceName .. " level: requires " .. spec.minimumLevel
		end
	end
	-- Canonical path/body universes must agree even for global users; check nested keyed batches.
	local body = request.body
	local canonical = if request.path and request.path.universeId ~= nil
		then request.path.universeId
		else universe
	if type(body) == "table" then
		local fields = body :: { [string]: any }
		if
			canonical ~= nil
			and fields.universeId ~= nil
			and tostring(canonical) ~= tostring(fields.universeId)
		then
			return "Universe mismatch"
		end
		local items = if spec.idempotencyItems then fields[spec.idempotencyItems] else nil
		if type(items) == "table" then
			for _, item in items do
				if
					type(item) == "table"
					and item.universeId ~= nil
					and canonical ~= nil
					and tostring(item.universeId) ~= tostring(canonical)
				then
					return "Universe mismatch"
				end
			end
		end
	end
	if auth.universeId then
		local expected = tostring(auth.universeId)
		if universe and tostring(universe) ~= expected then
			return "Service account is scoped to one universe"
		end
		local inputs: { unknown } = { request.path or {}, request.query or {}, request.body or {} }
		for i = 1, #inputs do
			local value = inputs[i]
			if type(value) == "table" then
				local fields = value :: { [string]: unknown }
				for _, name in { "universeId", "robloxUniverseId" } do
					if fields[name] ~= nil and tostring(fields[name]) ~= expected then
						return "Service account is scoped to one universe"
					end
				end
			end
		end
	end
	return nil
end
return table.freeze(Access)
