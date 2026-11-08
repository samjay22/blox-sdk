--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local result = client.auth:health()
if not result.ok then
	warn(result.error.code)
end
-- Service-account auth is applied by Client.luau using GetSecret. Never login human users in-game.
