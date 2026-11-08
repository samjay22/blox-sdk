--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local parties = client.party:getAllParties()
if not parties.ok then
	warn(parties.error.code)
end
-- Party creation and membership changes belong in authenticated server handlers, not client arguments.
