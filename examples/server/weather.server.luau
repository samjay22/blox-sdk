--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
client:runtimeSnapshot(30)
local lighting = game:GetService("Lighting")
local watch = client.fields:rotations():watch("weather", function(instance)
	for _, pick in instance.result.picks do
		local payload = pick.payload
		if type(payload) == "table" then
			local weather = rawget(payload, "weather")
			lighting.ClockTime = if weather == "METEOR" then 0 else 14
			lighting.FogEnd = if weather == "RAIN" then 300 else 100000
		end
	end
end)
game:BindToClose(function()
	watch:disconnect()
end)
