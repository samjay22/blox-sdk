--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Types = require("../src/Types/Party")
--- Create a party, add a member and poll within the backend's 30-second retention window.
return function(
	client: SDK.Client,
	ownerId: number,
	memberId: number,
	placeId: number,
	serverId: string,
	signal: Core.Signal,
	wait: (number) -> (),
	onUpdate: (Types.PartyUpdate) -> ()
): Core.Result<Types.CreatePartyResultValue>
	local created = client.party:createParty(
		{ ownerId = ownerId, placeId = placeId },
		{ priority = "critical" }
	)
	if not created.ok then
		return created
	end
	local partyId = created.value.id
	if not partyId then
		return created
	end
	client.party:addMember({ partyId = partyId, requesterId = ownerId, userId = memberId })
	while not signal.cancelled do
		local polled = client.party:getUpdates({ query = { serverId = serverId } }, { signal = signal })
		if not polled.ok then
			break
		end
		local updates: { Types.PartyUpdate } = polled.value.updates or {}
		-- Polling is non-destructive: handlers must be idempotent; the same update may arrive more than once.
		for i = 1, #updates do
			onUpdate(updates[i])
		end
		wait(2)
	end
	client.party:deleteParty({ partyId = partyId, ownerId = ownerId }, { priority = "critical" })
	return created
end
