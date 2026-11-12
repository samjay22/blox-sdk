--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Wire = require("../src/Types/Fields")
export type UI = {
	showResults: ({ Wire.GeneratorPick }, number?, Wire.Result) -> (),
	showOdds: (Wire.RandomOdds, string) -> (),
}
--- Open one configured five-card pack and supply accurate, explicitly labeled table odds UI data.
return function(
	client: SDK.Client,
	playerId: number,
	openingId: string,
	ui: UI
): Core.Result<Wire.GeneratorRollResult>
	local generators = client.fields:generators()
	-- This is the example's root table, not a fabricated generator-odds endpoint.
	local odds = generators:getOdds("rarity", playerId)
	if not odds.ok then
		return odds
	end -- Fail closed if this experience requires odds disclosure.
	ui.showOdds(
		odds.value,
		"Base single-table odds; pack guarantees, uniqueness and pity change final outcomes"
	)
	-- openingId belongs to one authenticated player's persisted opening intent, not the animation.
	local rolled = generators:roll("card_pack", playerId, { count = 1, idempotencyKey = openingId })
	if not rolled.ok then
		return rolled
	end
	for _, pack in rolled.value.results do
		-- Grants and cost were already applied by Fields. Only animate these picks; never regrant.
		local pity = if type(pack.pityAfter) == "number" then pack.pityAfter else nil
		ui.showResults(pack.picks, pity, rolled.value.transaction)
	end
	return rolled
end
