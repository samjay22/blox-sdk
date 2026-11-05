--!strict
local SDK = require("../src/BloxSDK")
--- Supply a persisted business-operation key to deduplicate across server restarts, not only SDK retries.
return function(client: SDK.Client, userId: number, rewardId: string)
	return client.economy:grant({
		path = { userId = userId },
		body = { currency = "COIN", amount = "100", reason = "Daily reward", idempotencyKey = rewardId },
	})
	-- Receipt processing uses client.economy:receipt; acknowledge Roblox purchase delivery only after success.
end
