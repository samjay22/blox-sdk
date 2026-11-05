--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Types = require("../src/Types/Codes")
--- Redeem once using a stable operation identifier persisted by the caller, never a new ID per retry.
return function(
	client: SDK.Client,
	userId: number,
	code: string,
	redemptionKey: string
): Core.Result<Types.RedeemResultValue>
	return client.codes:redeem(
		{ code = code, robloxUserId = userId, redemptionKey = redemptionKey },
		{ priority = "critical" }
	)
end
