--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
--- Compile-check the documented inline configuration shape without constructing a live client.
return function(runtime: Core.Runtime, backend: Core.Backend): SDK.Client
	return SDK.new({
		runtime = runtime,
		backend = backend,
		gatewayUrl = "https://gateway.example",
		batch = { intervalSeconds = 0.5 },
		levels = { PartyService = "READ", MatchmakingService = "READ_WRITE" },
	})
end
