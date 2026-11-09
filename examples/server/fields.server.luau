--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
game:GetService("Players").PlayerAdded:Connect(function(player: any)
	local loaded = client.fields:loadProfile(game.GameId, player.UserId)
	if not loaded.ok then
		warn(loaded.error.code)
		return
	end
	local profile = loaded.value
	local counter = profile:tryGet("Smoke.Counter")
	if not counter.ok then
		warn(counter.error.code)
		profile:destroy()
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local stat = leaderstats:FindFirstChild("Counter") or Instance.new("IntValue")
	stat.Name = "Counter"
	stat.Parent = leaderstats
	if type(counter.value) == "number" then
		stat.Value = counter.value
	end
	profile.Changed:connect(function(change)
		local value = change.values["Smoke.Counter"]
		if type(value) == "number" then
			stat.Value = value
		end
	end)
	local saved = profile:immediate():add("Smoke.Counter", 1):reason("Server example"):commit()
	if not saved.ok then
		warn(saved.error.code)
	end
	-- Keep the profile loaded for automatic admin-edit sync. Native PlayerRemoving unregisters it.
end)
