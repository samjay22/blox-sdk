--!strict
local SDK = require("../src/BloxSDK")
--- Read dynamic configuration from a cached namespace and react to changes.
return function(client: SDK.Client)
	local shop = client.configs:namespace("Shop")
	local connection = shop.Changed:connect(function(change)
		print("Shop config is now version", change.version, "changed:", table.concat(change.keys, ", "))
	end)
	-- Optional: wait for the first load. Reads never yield, so before it they simply return the default.
	if not shop:waitReady(5) then
		warn("Using defaults; config not loaded yet")
	end
	local price = shop:getNumber("SwordPrice", 100)
	local banner = shop:getString("Banner", "")
	local sale = shop:getBoolean("SaleActive", false)
	return shop, connection, price, banner, sale
end
