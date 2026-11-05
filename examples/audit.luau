--!strict
local SDK = require("../src/BloxSDK")
--- Create a nonblocking writer; native Roblox clients automatically drain it in BindToClose.
return function(client: SDK.Client, userId: number, occurredAt: string)
	local writer = client:auditWriter({ batchSize = 100, interval = 5, capacity = 2000 })
	local accepted = writer:Enqueue({
		occurredAt = occurredAt,
		actorType = "USER",
		actorId = tostring(userId),
		action = "player.session.start",
		resourceType = "player",
		resourceId = tostring(userId),
		outcome = "SUCCESS",
	})
	-- False means locally rejected (closed, invalid or full), not delivered. Pending/LastError expose delivery state.
	return writer, accepted
end
