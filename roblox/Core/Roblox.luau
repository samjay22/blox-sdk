--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Json = require(script.Parent.Parent.Core.Json)
local Roblox = {}
export type HttpService = {
	RequestAsync: (self: HttpService, Types.HttpRequest) -> Types.HttpResponse,
	JSONDecode: (self: HttpService, string) -> unknown,
	GenerateGUID: (self: HttpService, boolean) -> string,
	GetSecret: (self: HttpService, string) -> Types.Secret,
}
--- Resolve Roblox services lazily, so requiring the SDK is safe in plain Luau tests.
function Roblox.httpService(): HttpService
	assert(game ~= nil, "Outside Roblox, provide runtime and backend")
	assert(game:GetService("RunService"):IsServer(), "BloxSDK is server-only")
	return game:GetService("HttpService") :: HttpService
end
--- Adapt Roblox scheduling/JSON APIs to the portable runtime contract.
function Roblox.runtime(http: HttpService): Types.Runtime
	return {
		now = os.clock,
		unix = os.time,
		random = math.random,
		guid = function(): string
			return http:GenerateGUID(false)
		end,
		wait = function(seconds: number)
			task.wait(seconds)
		end,
		spawn = function(callback: () -> ()): thread
			return task.spawn(callback)
		end,
		delay = function(seconds: number, callback: () -> ()): thread
			return task.delay(seconds, callback)
		end,
		cancel = function(worker: thread)
			task.cancel(worker)
		end,
		encode = Json.encode,
		decode = function(body: string): unknown
			return http:JSONDecode(body)
		end,
	}
end
--- Construct the default single HTTP choke point without wrapping or stringifying Secrets.
function Roblox.backend(http: HttpService): Types.Backend
	return function(request: Types.HttpRequest): Types.HttpResponse
		return http:RequestAsync(request)
	end
end
--- Register cooperative shutdown only for clients using the native Roblox runtime.
function Roblox.bindToClose(callback: () -> ())
	game:BindToClose(callback)
end
--- Own one native player-removal connection per physical SDK client.
function Roblox.playerRemoving(callback: (number) -> ()): () -> ()
	local connection = game:GetService("Players").PlayerRemoving:Connect(function(player)
		callback(player.UserId)
	end)
	return function()
		connection:Disconnect()
	end
end
return table.freeze(Roblox)
