--!strict
local SDK = require("../src/BloxSDK")
local Types = require("../src/Fields/Types")
local Core = require("../src/Types/Core")
local Fields = require("../src/Types/Fields")
--- Provision with ADMIN during setup, not per player. Fields writes enqueue the leaderboard submission.
return function(
	client: SDK.Client,
	universeId: number
): Core.Result<Fields.Preview> | Core.Result<Fields.Definition>
	local binding: Types.LeaderboardBinding = {
		board = "wins",
		submit = "VALUE",
		order = "DESC",
		reset = "NONE",
		keep = "LAST",
		displayName = "Wins",
	}
	local preview = client.fields:previewBoard({
		path = { universeId = universeId },
		body = { id = "Stats.Wins", type = { kind = "int", min = 0 }, binding = binding },
	})
	if not preview.ok or not preview.value.valid then
		return preview -- Inspect safe conflicts; preview makes no writes and reserves nothing.
	end
	-- MISSING_OR_ARCHIVED is not proof the board name is available. Creation remains authoritative.
	-- Fields provisions the board from this definition. Do not create it or submit its score separately.
	-- Gameplay: profile:immediate():add("Stats.Wins",1):reason("Match victory"):commit().
	-- Inspect outboxPages for asynchronous delivery failures after committed field writes.
	return client.fields:create({
		path = { universeId = universeId },
		body = {
			id = "Stats.Wins",
			scope = "PLAYER",
			type = { kind = "int", min = 0 },
			default = 0,
			history = "LEDGER",
			writeLevel = "READ_WRITE",
			status = "ACTIVE",
			reason = "Provision wins leaderboard field",
			bindings = { leaderboards = { binding } },
		},
	})
end
