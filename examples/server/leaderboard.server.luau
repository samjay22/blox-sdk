--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
game:GetService("Players").PlayerAdded:Connect(function(player: any)
	local standing = client.leaderboards:around({
		path = { name = "sdk_smoke", userId = player.UserId },
		query = { radius = 3 },
	})
	if not standing.ok then
		warn(standing.error.code)
	end
end)
local pages = client.leaderboards:topPages({ path = { name = "sdk_smoke" }, query = { limit = 10 } }, nil, 1)
local first = pages()
if first and not first.ok then
	warn(first.error.code)
end
