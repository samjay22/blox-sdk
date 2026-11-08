--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Auth = require("../src/Types/Auth")

--- Use an already logged-in identity client; game servers should instead use bsa_ Secrets.
return function(
	client: SDK.Client,
	orgId: string,
	universeId: number,
	username: string
): Core.Result<Auth.Member>
	-- A scope-only contractor gets no org-wide membership. Omit overrides to retain template defaults.
	local member = client.auth:addMember({
		path = { org = orgId },
		body = { username = username, role = "DEVELOPER", universeId = universeId },
	})
	if not member.ok then
		return member
	end
	local memberId = member.value.userId
	if type(memberId) ~= "string" then
		return member
	end
	-- Explicit query selects a universe override; {} encodes [] and clears explicit overrides.
	local updated = client.auth:patchMember({
		path = { org = orgId, user = memberId },
		query = { universeId = universeId },
		body = { overrides = {} },
	})
	if not updated.ok then
		return updated
	end
	-- This caller's scoped facade uses cached/early-refreshed JWTs, not the invited member's authority.
	-- lb1 needs Gateway too; DEVELOPER's initial template has no Gateway or AuthService grant.
	local scoped = client:scoped(universeId)
	local schema = scoped.fields:schema()
	if not schema.ok then
		return schema
	end
	return updated
end
