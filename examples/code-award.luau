--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Codes = require("../src/Types/Codes")
--- Needs Gateway/CodeService ADMIN and Fields access. The award is validated against the universe schema first.
return function(client: SDK.Client): Core.Result<Codes.CodeDto>
	return client.codes:create({
		code = "WELCOME100",
		award = client.codes:award():add("Currency.Gems", 100):mapAdd("Inventory.Items", "SWORD", 1),
	})
end
