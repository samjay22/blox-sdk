--!strict
local SDK = require(game.ServerStorage.BloxSDK)
local client = SDK.new({ secretName = "BLOX_SERVICE_ACCOUNT", universeId = game.GameId })
game:BindToClose(function()
	client:flush(20)
	client:destroy()
end)
return client
