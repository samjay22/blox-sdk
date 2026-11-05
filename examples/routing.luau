--!strict
local SDK = require("../src/BloxSDK")
--- Create a server client with optional gateway and direct-data overrides; omitted values use gateway defaults.
return function(
	secretName: string,
	universeId: number,
	gatewayUrl: string?,
	directDataUrl: string?
): SDK.Client
	return SDK.new({
		secretName = secretName,
		universeId = universeId,
		gatewayUrl = gatewayUrl, -- Default: https://lb1.blox-api.com; never include a service prefix here.
		services = if directDataUrl then { data = { baseUrl = directDataUrl } } else nil,
	})
	-- E.g. gatewayUrl="https://gateway.example", directDataUrl="https://direct-data.example".
	-- Config still uses /remote-config-service; the data exception uses only its backend path.
end
