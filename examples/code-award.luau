--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Codes = require("../src/Types/Codes")
--- Require Gateway/CodeService/FieldsService grants; preflight a subject-free award before creation.
return function(client: SDK.Client): Core.Result<Codes.CodeDto>
	local loaded = client.fields:schemaCache():load()
	if not loaded.ok then
		return loaded
	end
	local award = client.codes:award():add("Currency.Gems", 100):mapAdd("Inventory.Items", "SWORD", 1)
	local checked = award:validate()
	if not checked.ok then
		return checked
	end
	if not checked.value.valid then
		return {
			ok = false,
			error = {
				kind = "Validation",
				message = "Award validation failed",
				endpoint = "codes.createCode",
				attempts = 0,
				code = "sdk_validation",
			},
		}
	end
	local built = award:build()
	if not built.ok then
		return built
	end
	return client.codes:createCode({
		code = "WELCOME100",
		award = built.value,
		maxRedemptionsPerUser = 1,
	})
end
