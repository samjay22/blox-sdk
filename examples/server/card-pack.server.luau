--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local open = Instance.new("BindableFunction")
open.Name = "OpenCardPack"
open.Parent = script
open.OnInvoke = function(playerId: number, openingId: string)
	-- Call only from a trusted server with a persisted intent, not arbitrary RemoteFunction arguments.
	local result =
		client.fields:generators():roll("card_pack", playerId, { count = 1, idempotencyKey = openingId })
	if not result.ok then
		warn(result.error.code)
	end
	return result
end
local preview = client.fields:generators():preview("card_pack", nil, 1)
if not preview.ok then
	warn(preview.error.code)
end
