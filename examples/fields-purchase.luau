--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Fields = require("../src/Types/Fields")
--- Call only from a trusted server receipt callback; acknowledge delivery only after result.ok.
return function(
	client: SDK.Client,
	universeId: number,
	purchaseId: string,
	userId: number,
	productId: number,
	robuxSpent: number
): Core.Result<Fields.ReceiptResult>
	return client.fields:processReceipt(
		universeId,
		{ purchaseId = purchaseId, userId = userId, productId = productId, robuxSpent = robuxSpent }
	)
	-- On uncertainty, retry this same purchaseId and payload. Never accept grant quantities from clients.
end
