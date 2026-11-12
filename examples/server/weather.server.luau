--!strict
-- Set this Script's Enabled attribute to true after saving a `weather` rotation (see docs/ROTATIONS.md).
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local lighting = game:GetService("Lighting")
local watch = client.fields:rotations():watch("weather", function(current)
	local data = current.items[1].data
	local weather = if data then data.weather else nil
	lighting.ClockTime = if weather == "METEOR" then 0 else 14
	lighting.FogEnd = if weather == "RAIN" then 300 else 100000
end)
game:BindToClose(function()
	watch:disconnect()
end)
