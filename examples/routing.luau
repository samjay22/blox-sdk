--!strict
-- lb1 requires Gateway AND target-service grants; bsa_ keys are bound to one universe.
local SDK = require("../src/BloxSDK")
--- Create a server client with optional gateway and direct-fields overrides; omitted values use gateway defaults.
return function(
	secretName: string,
	universeId: number,
	gatewayUrl: string?,
	directFieldsUrl: string?
): SDK.Client
	return SDK.new({
		secretName = secretName,
		universeId = universeId,
		gatewayUrl = gatewayUrl, -- Default: https://lb1.blox-api.com; never include a service prefix here.
		services = if directFieldsUrl then { fields = { baseUrl = directFieldsUrl } } else nil,
	})
	-- E.g. gatewayUrl="https://gateway.example", directFieldsUrl="https://direct-fields.example".
	-- Config still uses /remote-config-service; the fields exception uses only its backend path.
end
