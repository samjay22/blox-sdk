--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
game:GetService("Players").PlayerAdded:Connect(function(player: any)
	local evaluated = client.fields:evaluateFlags({ userId = player.UserId, keys = { "double_xp" } })
	if not evaluated.ok then
		warn(evaluated.error.code)
		return
	end
	local flag = evaluated.value.values.double_xp
	player:SetAttribute("DoubleXP", flag ~= nil and flag.value == true)
end)
