--!strict
-- Server enrichment needs FieldsService READ; lb1 also requires Gateway. Criteria accept computed IDs including Stats.Elo.
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Types = require("../src/Types/Matchmaking")
--- Join once, poll at bounded cadence, then remove on cancellation. Handle actual teleport assignment separately.
return function(
	client: SDK.Client,
	userId: string,
	mode: string,
	signal: Core.Signal,
	wait: (number) -> ()
): Core.Result<Types.JoinQueueResultValue>
	local joined = client.matchmaking:joinQueue(
		{ robloxUserIds = { userId }, gameModeName = mode },
		{ priority = "critical", signal = signal }
	)
	if not joined.ok then
		return joined
	end
	while not signal.cancelled do
		local status = client.matchmaking:getPlayerQueueStatus(
			{ query = { userId = userId } },
			{ signal = signal }
		)
		if not status.ok or not status.value.inQueue then
			break
		end
		wait(2)
	end
	-- Cleanup needs a fresh, uncancelled request. Never retry join blindly after an uncertain network failure.
	client.matchmaking:removePlayerPost(
		{ robloxUserId = userId, gameModeName = mode },
		{ priority = "critical" }
	)
	return joined
end
