--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local players = game:GetService("Players")
local signals: { [number]: { cancelled: boolean } } = {}
players.PlayerRemoving:Connect(function(player: any)
	local signal = signals[player.UserId]
	if signal then
		signal.cancelled = true
	end
end)
players.PlayerAdded:Connect(function(player: any)
	local signal = { cancelled = false }
	signals[player.UserId] = signal
	local joined = client.matchmaking:joinQueue({
		robloxUniverseId = tostring(game.GameId),
		robloxUserIds = { tostring(player.UserId) },
		gameModeName = "ranked",
	}, { signal = signal, timeout = 5 })
	if joined.ok then
		while not signal.cancelled do
			local status = client.matchmaking:getPlayerQueueStatus(
				{ query = { userId = tostring(player.UserId), universeId = tostring(game.GameId) } },
				{ signal = signal }
			)
			if not status.ok or not status.value.inQueue then
				break
			end
			task.wait(2)
		end
	else
		warn(joined.error.code)
	end
	client.matchmaking:removePlayerPost({
		robloxUserId = tostring(player.UserId),
		robloxUniverseId = tostring(game.GameId),
		gameModeName = "ranked",
	}, { timeout = 5 })
	signals[player.UserId] = nil
end)
