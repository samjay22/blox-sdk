--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Types = require("../src/Types/Codes")
--- Retry the same code/player pair; CodeService owns the permanent code-<codeId>-<userId> key.
return function(client: SDK.Client, userId: number, code: string): Core.Result<Types.RedeemResultValue>
	return client.codes:redeem({ code = code, robloxUserId = userId }, { priority = "critical" })
end
