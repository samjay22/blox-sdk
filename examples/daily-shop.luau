--!strict
local SDK = require("../src/BloxSDK")
--- Shop UI data from a rotation saved as { items = { { id = "sword", data = { price = 100 } }, ... }, every = "1d", show = 3 }.
export type ShopView = { offers: { SDK.RotationItem }, secondsLeft: number, tomorrow: { SDK.RotationItem } }
--- Read what the shop offers right now; cheap to call on every UI refresh (cached until the shop changes).
return function(client: SDK.Client): ShopView?
	local rotations = client.fields:rotations()
	local result = rotations:current("daily_shop")
	if not result.ok then
		warn(result.error.code)
		return nil
	end
	local shop = result.value
	return { offers = shop.items, secondsLeft = rotations:secondsLeft(shop), tomorrow = shop.next.items }
end
