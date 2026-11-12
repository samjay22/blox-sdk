--!strict
local SDK = require("../src/BloxSDK")
--- Poll flags asynchronously; retain the last good snapshot across service outages.
return function(client: SDK.Client)
	local snapshot = client:runtimeSnapshot(30)
	local connection = snapshot.changed:connect(function(value)
		print("Runtime snapshot generation", value.version)
	end)
	-- Synchronous reads: false until loaded. isEnabled is the master toggle only.
	-- For user-specific rollout, schedules and rules, call client.fields:evaluateFlags(...).
	local enabled = snapshot:isEnabled("double_xp")
	return snapshot, connection, enabled
end
