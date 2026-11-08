--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local result = client.platform:healthProxy()
if not result.ok then
	warn(result.error.code)
end
-- Billing and management operations need a trusted operator identity, never a gameplay remote.
