--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local code = script:GetAttribute("Code")
assert(type(code) == "string" and #code > 0, "Set a configured test Code attribute")
game:GetService("Players").PlayerAdded:Connect(function(player: any)
	local outcome = client.codes:redeem(player, code)
	if outcome.status == "failed" then
		warn(outcome.error.code)
	end
	-- Fields already granted the award atomically; never grant it again here.
end)
