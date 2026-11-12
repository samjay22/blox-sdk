--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
-- A live event is Fields configuration/flags plus a rotation or schedule, not a separate service.
client:runtimeSnapshot(30)
local watch = client.fields:rotations():watch("live_event", function(instance)
	game:SetAttribute("LiveEventInstance", instance.id)
	game:SetAttribute("LiveEventEndsAt", instance.endsAt)
end)
game:BindToClose(function()
	watch:disconnect()
end)
