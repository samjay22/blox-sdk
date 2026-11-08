--!strict
local SDK = require("../src/BloxSDK")
--- Poll asynchronously; retain the last good snapshot across service outages.
return function(client: SDK.Client)
	local snapshot = client:runtimeSnapshot(30)
	local connection = snapshot.changed:connect(function(value)
		print("Config generation", value.version)
	end)
	-- Synchronous reads: nil/false until loaded. IsEnabled is the master toggle only.
	-- For user-specific rollout, schedules and rules, call client.fields:evaluateFlags(...).
	local welcome = snapshot:get("Welcome.Text")
	local enabled = snapshot:isEnabled("double_xp")
	return snapshot, connection, welcome, enabled
end
