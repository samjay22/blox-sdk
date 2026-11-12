--!strict
-- Set this Script's Enabled attribute to true after saving a `daily_shop` rotation (see docs/ROTATIONS.md).
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local rotations = client.fields:rotations()
local offers = Instance.new("BindableFunction")
offers.Name = "GetShopOffers"
offers.Parent = script
offers.OnInvoke = function(): any
	local result = rotations:current("daily_shop")
	if not result.ok then
		warn(result.error.code)
		return nil
	end
	return { items = result.value.items, secondsLeft = rotations:secondsLeft(result.value) }
end
