--!strict
local SDK = require("../src/BloxSDK")
-- Minimal interface also permits testing without native Lighting Instances.
export type Lighting = { Brightness: number, ClockTime: number, FogEnd: number }
--- Apply an item's `data` ({ weather = "RAIN", intensity = 0.7 }) to server-owned Roblox Lighting.
local function apply(lighting: Lighting, item: SDK.RotationItem)
	local data = item.data
	if data == nil then
		return
	end
	local intensity = if type(data.intensity) == "number" then math.clamp(data.intensity, 0, 1) else 0
	if data.weather == "RAIN" then
		lighting.Brightness = 2 - intensity
		lighting.ClockTime = 14
		lighting.FogEnd = 1000 - 700 * intensity
	elseif data.weather == "METEOR" then
		lighting.Brightness = 1
		lighting.ClockTime = 0
		lighting.FogEnd = 1000
	else
		lighting.Brightness = 2
		lighting.ClockTime = 14
		lighting.FogEnd = 100000
	end
end
--- Start once on the server with game:GetService("Lighting"); disconnect when the system unloads.
return function(client: SDK.Client, lighting: Lighting): SDK.RotationWatch
	-- Runs now and again whenever the weather rotation moves on.
	return client.fields:rotations():watch("weather", function(current)
		apply(lighting, current.items[1])
	end)
end
