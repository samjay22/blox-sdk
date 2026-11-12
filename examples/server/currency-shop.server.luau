--!strict
-- Set this Script's Enabled attribute to true after creating PLAYER fields Currency.Gems (int, minimum 0) and
-- Inventory.Items (map of int) and a `Shop` config namespace with Prices = { "SWORD": 100, "SHIELD": 80 }.
-- See docs/RECIPES.md. Server code calls the child Buy BindableFunction with (player, itemId).
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local Players = game:GetService("Players")
local shop = client.configs:namespace("Shop")

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

--- Returns "bought", "unknown_item", "not_enough_gems" or "unavailable".
local function buy(player: any, itemId: string): string
	local prices = shop:get("Prices", {})
	local price = if type(prices) == "table" then (prices :: any)[itemId] else nil
	if type(price) ~= "number" or price <= 0 then
		return "unknown_item"
	end
	local profile = profiles[player]
	if not profile then
		return "unavailable"
	end
	local gems = profile:tryGet("Currency.Gems")
	if not gems.ok or type(gems.value) ~= "number" then
		return "unavailable"
	end
	if gems.value < price then
		return "not_enough_gems"
	end
	-- One transaction: both changes commit or neither does.
	local result = profile
		:immediate()
		:add("Currency.Gems", -price)
		:mapAdd("Inventory.Items", itemId, 1)
		:reason("Shop purchase " .. itemId)
		:commit()
	if result.ok then
		return "bought"
	end
	if result.error.code == "below_min" then
		return "not_enough_gems" -- a concurrent spend won the race
	end
	warn(result.error.code)
	return "unavailable"
end

local buyFunction = Instance.new("BindableFunction")
buyFunction.Name = "Buy"
buyFunction.Parent = script
buyFunction.OnInvoke = function(player: any, itemId: any): any
	if type(itemId) ~= "string" then
		return "unknown_item"
	end
	return buy(player, itemId)
end
