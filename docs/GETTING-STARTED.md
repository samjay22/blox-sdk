# Getting started in 10 minutes

This path takes a test Roblox server from nothing to: a saved player currency, a leaderboard, a live config value and
a redeemable code. Use a disposable test universe. Every step names the permission it needs.

| Step | Where | Needs |
|---|---|---|
| 1. Register the universe | Portal: Organization, Universes | Organization Admin |
| 2. Create an API key | Portal: Organization, API keys | Organization Admin |
| 3. Install the SDK | Your game project | Rojo |
| 4. Read and write a field | Portal: Fields, then a server Script | FieldsService ADMIN to create the field, READ_WRITE in game |
| 5. Add a leaderboard | Portal: Leaderboards | FieldsService ADMIN |
| 6. Tune a config | Portal: Game config | ConfigService ADMIN to edit, READ in game |
| 7. Redeem a code | Portal: Codes | CodeService ADMIN to create, READ_WRITE in game |

## 1. Register the universe

Use the Roblox **universe ID** (`game.GameId`), not a place ID. Add it under Organization, Universes, and select it in
the portal. The SDK states the universe once: on Roblox `BloxSDK.new` defaults to `game.GameId`, and no later call takes a
universe argument (4.0.0).

## 2. Create an API key

Create a service-account key bound to that universe (it is shown once). Grant **Gateway** plus the services you will use:
`FieldsService READ_WRITE`, `LeaderboardService READ`, `ConfigService READ`, `CodeService READ_WRITE`. Store it as a Roblox
secret named `BLOX_SERVICE_ACCOUNT` allowed for `lb1.blox-api.com` and enable Allow HTTP Requests. Keep ADMIN levels
(for example `ConfigService ADMIN`) on a separate key used only by trusted operator tooling.

## 3. Install and create one client

Build the package with Rojo (`rojo build default.project.json -o BloxSDK.rbxm`, see the [README](../README.md#install)),
put the ModuleScript in ServerScriptService, then:

```luau
local BloxSDK = require(game.ServerScriptService.BloxSDK)
local client = BloxSDK.new({ secretName = "BLOX_SERVICE_ACCOUNT", environment = "prod" })

game:BindToClose(function()
	client:flush(20) -- saves buffered writes, releases players, closes admission
	client:destroy()
end)
```

## 4. Create a field, then read and write it

In the portal create `Currency.Gems`: Whole number, Per player, default 0, minimum 0, maximum 1000000, maximum change 1000.

```luau
game:GetService("Players").PlayerAdded:Connect(function(player)
	local loaded = client.fields:loadProfile(player)
	if not loaded.ok then
		warn(loaded.error.code)
		return
	end
	local profile = loaded.value
	local balance = profile:tryGet("Currency.Gems")
	if balance.ok then print(player.Name, balance.value) end
	profile:add("Currency.Gems", 10) -- visible now, saved in the background (about 5 s)
	local confirmed = profile:immediate():add("Currency.Gems", -5):reason("Test spend"):commit()
	if not confirmed.ok then warn(confirmed.error.code) end -- waits for the service's answer
end)
```

Check the player on the portal's Players page. See [Fields](FIELDS.md).

## 5. Turn the field into a leaderboard

On the portal's Leaderboards page choose New board, pick `Currency.Gems` under *Rank players by a field* and save. The board
is created and linked to the field in one step; do not call `leaderboards:submit` for it. A *Current value* or *Best ever*
board backfills every player's saved value once when linked; a *Total gained* board counts only changes made after linking.
Scores are delivered through a durable queue and a ranking job recalculates ranks every minute, so allow up to about a minute.

```luau
local top = client.leaderboards:top({ path = { name = "gems" }, query = { limit = 10 } })
if top.ok then
	for _, standing in top.value.items do print(standing.rank, standing.userId, standing.score) end
end
```

See [Leaderboards](LEADERBOARDS.md).

## 6. Read a setting you can change live

Create a `Shop` namespace with `SwordPrice = 100` on the Game config page.

```luau
local shop = client.configs:namespace("Shop")
shop:waitReady(10) -- optional
print(shop:getNumber("SwordPrice", 100)) -- cached, instant, never throws
shop.Changed:connect(function(change) print("Shop config version", change.version) end)
```

Edits reach every server within about 30 seconds (`pollInterval`). See [Configs](CONFIGS.md).

## 7. Create and redeem a code

Create `WELCOME100` (award: add 100 to `Currency.Gems`) on the Codes page, or from admin tooling with
`client.codes:create`. In the game:

```luau
local outcome = client.codes:redeem(player, text) -- never raises on a bad code
if outcome.status == "granted" then print("rewards", #outcome.rewards)
elseif outcome.status == "already_redeemed" then print("used before")
elseif outcome.status == "retry" then print("busy, try again") end
```

See [Codes](CODES.md).

## Next

[Which feature should I use?](CHOOSING.md) · [Recipes](RECIPES.md) · [Troubleshooting](TROUBLESHOOTING.md) · [FAQ](FAQ.md) ·
[Glossary](GLOSSARY.md) · [Architecture](ARCHITECTURE.md) · [Migration 4.0 to 7.0](../MIGRATION.md).
