--!strict
-- Gateway and target-service grants are required; bsa_ keys are bound to one universe.
local SDK = require("../src/BloxSDK")
--- Create a batch-only server client; omitted gateway and cadence use SDK defaults.
return function(secretName: string, universeId: number, gatewayUrl: string?): SDK.Client
	return SDK.new({
		secretName = secretName,
		universeId = universeId,
		gatewayUrl = gatewayUrl, -- HTTPS origin only; no service prefix or direct-service override.
		batch = { intervalSeconds = 0.5 },
	})
end
