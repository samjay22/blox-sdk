--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
-- A live event is Fields configuration/flags plus a rotation or schedule, not a separate service.
local watch = client.fields:rotations():watch("live_event", function(current)
	game:SetAttribute("LiveEventId", current.items[1].id)
	game:SetAttribute("LiveEventEndsAt", current.endsAt)
end)
game:BindToClose(function()
	watch:disconnect()
end)
