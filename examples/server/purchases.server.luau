--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local marketplace = game:GetService("MarketplaceService")
-- This must be the experience's only ProcessReceipt handler. Provision Fields product grants first.
marketplace.ProcessReceipt = function(receipt: any)
	local result = client.fields:processReceipt(game.GameId, {
		purchaseId = receipt.PurchaseId,
		userId = receipt.PlayerId,
		productId = receipt.ProductId,
		robuxSpent = receipt.CurrencySpent,
	})
	if result.ok then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	warn(result.error.code)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
