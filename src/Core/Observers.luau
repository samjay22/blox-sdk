--!strict
local Core = require("../Types/Core")
local Observers = {}
--- Compose metadata-only logging and hooks; isolate each observer so one cannot suppress the other.
function Observers.new(hooks: Core.Hooks?, logger: Core.Logger?): Core.Hooks?
	if not logger then
		return hooks
	end
	local result: { [string]: (Core.Event) -> () } = {}
	for _, name in { "onRequest", "onResponse", "onRetry", "onBreakerChange", "onRateLimited" } do
		local hook = if hooks then (hooks :: any)[name] else nil
		result[name] = function(event: Core.Event)
			pcall(logger, name, event)
			if hook then
				pcall(hook, event)
			end
		end
	end
	return result :: Core.Hooks
end
return table.freeze(Observers)
