--!strict
-- Set this Script's Enabled attribute to true after creating a `Tuning` config namespace with XpMultiplier (number)
-- and EventBanner (string). See docs/RECIPES.md. Server code reads the current values from the child GetTuning BindableFunction.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local tuning = client.configs:namespace("Tuning")

local state = { xpMultiplier = 1, banner = "" }
local function apply()
	state.xpMultiplier = tuning:getNumber("XpMultiplier", 1)
	state.banner = tuning:getString("EventBanner", "")
end
apply()
tuning.Changed:connect(function(change)
	apply()
	print("Tuning is now version", change.version, "changed:", table.concat(change.keys, ", "))
end)

local read = Instance.new("BindableFunction")
read.Name = "GetTuning"
read.Parent = script
read.OnInvoke = function(): any
	return state
end

task.spawn(function()
	while true do
		task.wait(60)
		if tuning:isStale() then
			local failure = tuning:lastError()
			warn("Tuning config is stale:", if failure then failure.code else "no error recorded")
		end
	end
end)
