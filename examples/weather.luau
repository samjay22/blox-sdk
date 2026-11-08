--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
local Rotations = require("../src/Fields/Rotations")
-- Minimal interface also permits testing without native Lighting Instances.
export type Lighting = { Brightness: number, ClockTime: number, FogEnd: number }
--- Apply the contract's weather/intensity payload to server-owned Roblox Lighting.
local function apply(lighting: Lighting, instance: Wire.RotationInstance)
	for _, pick in instance.result.picks do
		local raw = pick.payload
		local payload = if type(raw) == "table" then raw :: { [string]: Core.Json } else nil
		if payload then
			local weather = payload.weather
			local intensity = if type(payload.intensity) == "number"
				then math.clamp(payload.intensity, 0, 1)
				else 0
			if weather == "RAIN" then
				lighting.Brightness = 2 - intensity
				lighting.ClockTime = 14
				lighting.FogEnd = 1000 - 700 * intensity
			elseif weather == "METEOR" then
				lighting.Brightness = 1
				lighting.ClockTime = 0
				lighting.FogEnd = 1000
			elseif weather == "CLEAR" then
				lighting.Brightness = 2
				lighting.ClockTime = 14
				lighting.FogEnd = 100000
			end
		end
	end
end
--- Start once on the server with game:GetService("Lighting"); disconnect when the system unloads.
return function(client: SDK.Client, universeId: number, lighting: Lighting): Rotations.Watch
	local scoped = client:withUniverse(universeId)
	-- Reuses this facade's existing ETag poller; do not create a second loop for weather.
	scoped:runtimeSnapshot(30)
	return scoped.fields:rotations(universeId):watch("weather", function(instance)
		apply(lighting, instance)
	end)
end
