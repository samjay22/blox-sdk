--!strict
-- Set this Script's Enabled attribute to true after creating the config namespace `Event_Halloween` as an item list
-- (members such as Pumpkin_Hat and Ghost_Trail) and a PLAYER bitmap field Events.Halloween that points at it.
-- Players keep what they earned; when the event ends an admin retires the members (examples/item-lists-admin.luau)
-- and they leave `usable` without anyone losing them. See docs/ITEM-LISTS.md.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local Players = game:GetService("Players")

local FIELD = "Events.Halloween"
local event = client.configs:namespace("Event_Halloween")

local profiles: { [any]: any } = {}
Players.PlayerAdded:Connect(function(player: any)
	local loaded = client.fields:loadProfile(player)
	if not loaded.ok then
		warn(loaded.error.code)
		return
	end
	profiles[player] = loaded.value
	-- What this player can use right now: what they hold, minus items the event has retired.
	local usable = loaded.value:usable(FIELD)
	if usable.ok then
		player:SetAttribute("HalloweenItems", table.concat(usable.value, ","))
	end
end)
Players.PlayerRemoving:Connect(function(player: any)
	profiles[player] = nil
end)

--- Reward an event item. Returns "granted", "event_over" (the item is retired) or "unavailable".
local function reward(player: any, item: string): string
	local profile = profiles[player]
	if not profile then
		return "unavailable"
	end
	local result = profile:grant(FIELD, { item })
	if result.ok then
		return "granted"
	end
	if result.error.code == "member_retired" then
		return "event_over"
	end
	warn(result.error.code)
	return "unavailable"
end

-- The cached list tells which items are still on offer; it refreshes by itself every 30 seconds.
event.Changed:connect(function(change)
	print("Halloween items changed in version", change.version, table.concat(change.keys, ", "))
end)

local rewardFunction = Instance.new("BindableFunction")
rewardFunction.Name = "Reward"
rewardFunction.Parent = script
rewardFunction.OnInvoke = function(player: any, item: string): any
	return reward(player, item)
end
