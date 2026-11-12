--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
export type Listing = {
	instanceId: string,
	slot: string,
	entryId: string,
	payload: Core.Json,
	initialStock: number?,
}
export type UI = {
	showSale: ({ Listing }, { Wire.RotationStock }?) -> (),
	countdown: (number) -> (),
	purchaseError: (string?) -> (),
}
export type Store = {
	tick: () -> (),
	purchase: (number, Listing, string) -> Core.Result<Wire.RotationClaimResult>,
	destroy: () -> (),
}
--- Show the configured store; the game's existing UI heartbeat calls tick, which never performs HTTP.
return function(client: SDK.Client, ui: UI): Store
	client:runtimeSnapshot(30)
	local rotations = client.fields:rotations()
	local current: Wire.RotationInstance? = nil
	local listings: { Listing } = {}
	local watch = rotations:watch("pack_store", function(instance)
		current = instance
		local nextListings: { Listing } = {}
		for _, pick in instance.result.picks do
			table.insert(nextListings, {
				instanceId = instance.id,
				slot = pick.slot,
				entryId = pick.entryId,
				payload = pick.payload,
				initialStock = pick.rolls.stock,
			})
		end
		listings = nextListings
		-- Initial stock is pinned; fetch live stock only on explicit demand, not every countdown tick.
		ui.showSale(listings, nil)
	end)
	return {
		tick = function()
			ui.countdown(if current then rotations:timeRemaining(current) else 0)
		end,
		purchase = function(
			playerId: number,
			listing: Listing,
			purchaseId: string
		): Core.Result<Wire.RotationClaimResult>
			-- Resolve playerId from the authenticated Roblox Player, not a RemoteEvent argument.
			-- Persist this server-owned listing AND purchaseId per intent; retries must not use a newer head.
			local instance = current
			if not instance then
				return {
					ok = false,
					error = {
						kind = "Local",
						code = "sdk_local",
						endpoint = "fields.claimRotation",
						attempts = 0,
						message = "Store not loaded",
					},
				}
			end
			local result = rotations:claim(
				listing.instanceId,
				listing.slot,
				listing.entryId,
				1,
				{ playerId = playerId, idempotencyKey = purchaseId }
			)
			if result.ok then
				-- A replay is historical. Do not overwrite a different head's UI with it.
				if not current or current.id ~= listing.instanceId then
					return result
				end
				-- Claim already debits Gems and grants the configured pack. Never charge/grant again.
				-- Read live stock explicitly; replay.remaining may describe an old purchase.
				local stock = rotations:getStock(listing.instanceId)
				if current and current.id == listing.instanceId then
					ui.showSale(listings, if stock.ok then stock.value else nil)
				end
			else
				ui.purchaseError(result.error.code)
				if result.error.code == "rotation_expired" then
					watch:refresh()
				end
			end
			return result
		end,
		destroy = function()
			watch:disconnect()
		end,
	}
end
