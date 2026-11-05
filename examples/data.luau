--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Types = require("../src/Types/Data")
--- Read and save a supplied snapshot. Use baseData for the backend's merge semantics when appropriate.
return function(
	client: SDK.Client,
	userId: number,
	snapshot: Core.Json,
	placeId: number
): Core.Result<Types.UpdateUserDataResultValue>
	local loaded = client.data:getUserData({ path = { robloxUserId = userId } })
	if not loaded.ok then
		return loaded
	end
	-- The scoped response is UserDataDto; global admin reads without a universe can return a list.
	local body: Types.CreateUserDataRequest = { jsonData = snapshot, placeId = placeId }
	return client.data:updateUserData(
		{ path = { robloxUserId = userId }, query = { markOffline = true }, body = body },
		{ priority = "critical" }
	)
end
