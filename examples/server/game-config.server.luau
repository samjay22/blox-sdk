--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local snapshot = client:runtimeSnapshot(30)
snapshot.changed:connect(function(value)
	print("Applied config generation", value.version)
	local welcome = snapshot:get("Welcome.Text")
	if type(welcome) == "string" then
		print(welcome)
	end
end)
