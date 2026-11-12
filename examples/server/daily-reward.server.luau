--!strict
-- Set this Script's Enabled attribute to true after creating PLAYER int fields Currency.Gems, Daily.LastClaimDay and
-- Daily.Streak (default 0, minimum 0). See docs/RECIPES.md. Server code calls the child ClaimDaily BindableFunction.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local Players = game:GetService("Players")

local DAY = 86400
local BASE_GEMS, STEP_GEMS, MAX_STREAK = 50, 10, 7

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

--- Returns "claimed", "already_claimed" or "unavailable" and the gems granted.
local function claimDaily(player: any): (string, number)
	local profile = profiles[player]
	if not profile then
		return "unavailable", 0
	end
	local last = profile:tryGet("Daily.LastClaimDay")
	local streak = profile:tryGet("Daily.Streak")
	if not last.ok or not streak.ok or type(last.value) ~= "number" or type(streak.value) ~= "number" then
		return "unavailable", 0
	end
	local today = math.floor(os.time() / DAY) -- the UTC day number, identical on every server
	if last.value == today then
		return "already_claimed", 0
	end
	local nextStreak = 1
	if last.value == today - 1 then
		nextStreak = math.min(streak.value + 1, MAX_STREAK)
	end
	local gems = BASE_GEMS + STEP_GEMS * (nextStreak - 1)
	local result = profile
		:immediate()
		:expect("Daily.LastClaimDay", { equals = last.value }) -- another server may have claimed already
		:set("Daily.LastClaimDay", today)
		:set("Daily.Streak", nextStreak)
		:add("Currency.Gems", gems)
		:key(`daily-{player.UserId}-{today}`) -- one grant per player per UTC day, even across retries
		:reason("Daily reward")
		:commit()
	if result.ok then
		return "claimed", gems
	end
	if result.error.code == "precondition_failed" then
		return "already_claimed", 0
	end
	warn(result.error.code)
	return "unavailable", 0
end

local claim = Instance.new("BindableFunction")
claim.Name = "ClaimDaily"
claim.Parent = script
claim.OnInvoke = function(player: any): any
	local status, gems = claimDaily(player)
	return { status = status, gems = gems }
end
