--!strict
-- Set this Script's Enabled attribute to true after creating the config namespace `Equipment` as an item list
-- (members such as Iron_Sword and Wooden_Shield) and two PLAYER bitmap fields that point at it:
-- Equipment.Owned (maxMembers 64: everything the player owns) and Equipment.Equipped (maxMembers 1: a single
-- choice). See docs/ITEM-LISTS.md. Server code calls the child Give and Equip BindableFunctions.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local Players = game:GetService("Players")

local OWNED, EQUIPPED = "Equipment.Owned", "Equipment.Equipped"

-- Start the shared live view of the item list now; profiles also wait briefly for it when they load.
client.configs:namespace("Equipment"):waitReady(5)

local profiles: { [any]: any } = {}
Players.PlayerAdded:Connect(function(player: any)
	local loaded = client.fields:loadProfile(player)
	if loaded.ok then
		profiles[player] = loaded.value
	else
		warn(loaded.error.code)
	end
end)
Players.PlayerRemoving:Connect(function(player: any)
	profiles[player] = nil
end)

--- Returns "granted", or the refusal: "unknown_item", "retired", "full" or "unavailable".
local function give(player: any, item: string): string
	local profile = profiles[player]
	if not profile then
		return "unavailable"
	end
	-- Idempotent: granting an item the player owns changes nothing, so a retried purchase is safe.
	local result = profile:grant(OWNED, { item })
	if result.ok then
		return "granted"
	end
	local code = result.error.code
	if code == "unknown_member" then
		return "unknown_item"
	elseif code == "member_retired" then
		return "retired"
	elseif code == "member_limit" then
		return "full"
	end
	warn(code)
	return "unavailable"
end

--- Returns "equipped", or the refusal: "not_owned", "retired" or "unavailable".
local function equip(player: any, item: string): string
	local profile = profiles[player]
	if not profile then
		return "unavailable"
	end
	local usable = profile:usable(OWNED) -- owned and still active in the list: a retired item stays owned
	if not usable.ok then
		return "unavailable"
	end
	if not table.find(usable.value, item) then
		local owned = profile:has(OWNED, item)
		return if owned.ok and owned.value then "retired" else "not_owned"
	end
	-- Equipped holds at most one member, so REPLACE swaps the choice in one step.
	local result = profile:replace(EQUIPPED, { item })
	if result.ok then
		return "equipped"
	end
	warn(result.error.code)
	return "unavailable"
end

local giveFunction = Instance.new("BindableFunction")
giveFunction.Name = "Give"
giveFunction.Parent = script
giveFunction.OnInvoke = function(player: any, item: string): any
	return give(player, item)
end

local equipFunction = Instance.new("BindableFunction")
equipFunction.Name = "Equip"
equipFunction.Parent = script
equipFunction.OnInvoke = function(player: any, item: string): any
	return equip(player, item)
end
