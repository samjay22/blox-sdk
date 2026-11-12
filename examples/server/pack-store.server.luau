--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local rotations = client.fields:rotations()
local purchase = Instance.new("BindableFunction")
purchase.Name = "PurchasePack"
purchase.Parent = script
purchase.OnInvoke = function(
	playerId: number,
	instanceId: string,
	slot: string,
	entryId: string,
	purchaseId: string
)
	-- Trusted server handlers pin these values from :get("pack_store"). Persist all values per intent.
	local result =
		rotations:claim(instanceId, slot, entryId, 1, { playerId = playerId, idempotencyKey = purchaseId })
	if not result.ok then
		warn(result.error.code)
	end
	return result
end
local active = rotations:get("pack_store")
if not active.ok then
	warn(active.error.code)
end
