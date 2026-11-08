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
	local saved = profile:transaction():add("Smoke.Counter", 1):reason("Server example"):commit()
	if not saved.ok then
		warn(saved.error.code)
	end
	profile:destroy()
end)
