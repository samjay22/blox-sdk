--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Signal = {}
export type Change = {
	userId: number,
	universeId: string?,
	fieldIds: { string },
	values: { [string]: Core.Json },
	source: "external" | "local",
}
export type Connection = { disconnect: (Connection) -> () }
export type Signal = {
	connect: (Signal, (Change) -> ()) -> Connection,
	fire: (Signal, Change) -> (),
	destroy: (Signal) -> (),
}
--- Isolate asynchronous listeners; disconnect/destroy also suppress queued notifications.
function Signal.new(runtime: Core.Runtime): Signal
	local listeners: { [(Change) -> ()]: boolean } = {}
	local closed = false
	return {
		connect = function(_self, callback)
			if not closed then
				listeners[callback] = true
			end
			return {
				disconnect = function(_connection)
					listeners[callback] = nil
				end,
			}
		end,
		fire = function(_self, change)
			for callback in listeners do
				runtime.spawn(function()
					if not closed and listeners[callback] then
						pcall(callback, change)
					end
				end)
			end
		end,
		destroy = function(_self)
			closed = true
			table.clear(listeners)
		end,
	}
end
return table.freeze(Signal)
