--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
--- Run an event's item list from trusted admin tooling (a client with ConfigService and FieldsService ADMIN).
--- Returns the result of the final removal attempt: it fails with `member_in_use` while any player holds the item.
return function(client: SDK.Client): Core.Result<nil>
	local items = client.configs:namespace("Event_Halloween")
	-- Make the namespace an item list once. It cannot be turned back into plain settings.
	items:setKind("items")
	-- The server assigns each member's permanent bit; the label is only for people.
	items:addMember("Pumpkin_Hat", { label = "Pumpkin Hat" })
	items:addMember("Ghost_Trail", { label = "Ghost Trail", meta = { rarity = "rare" } })
	items:updateMember("Pumpkin_Hat", { description = "Only during Halloween" })
	-- The event ends: nobody new can get the hat, players who have it keep it.
	items:retireMember("Pumpkin_Hat")
	local usage = items:usage()
	if usage.ok then
		print("Players holding Pumpkin_Hat:", usage.value.holders.Pumpkin_Hat)
	end
	-- Removing is final and refused while someone holds the item; the error says who.
	local removed = items:removeMember("Pumpkin_Hat")
	if not removed.ok and removed.error.code == "member_in_use" then
		for _, held in (removed.error.holders :: any) or {} do
			print(
				held.member,
				"is held by",
				held.count,
				"players, for example",
				table.concat(held.samplePlayers, ", ")
			)
		end
	end
	return removed
end
