--!strict
-- Set this Script's Enabled attribute to true after creating the `Shop` namespace (see docs/CONFIGS.md).
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local shop = client.configs:namespace("Shop")
shop.Changed:connect(function(change)
	print("Applied Shop config version", change.version, table.concat(change.keys, ", "))
	print("SwordPrice is", shop:getNumber("SwordPrice", 100))
end)
