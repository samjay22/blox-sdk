--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Types = require("../src/Types/Auth")
--- Use a client constructed with userSession={}; never log token-bearing login/create/rotate responses.
return function(
	client: SDK.Client,
	username: string,
	password: string,
	orgId: string
): Core.Result<Types.ListServiceAccountsResultValue>
	local login = client.auth:login({ username = username, password = password })
	if not login.ok then
		return login
	end
	local accounts = client.auth:listServiceAccounts({ query = { orgId = orgId } })
	client:logout() -- Uses the latest rotated refresh token, not the original login response.
	return accounts
end
