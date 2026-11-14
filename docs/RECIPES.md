# Recipes

Six complete patterns. Each links to a runnable, type-checked example in `examples/server/` (see
[examples/README.md](../examples/README.md)). They assume the [getting started](GETTING-STARTED.md) client.

## Daily reward with a streak

Example: [daily-reward.server.luau](../examples/server/daily-reward.server.luau).

Fields (PLAYER int, default 0, minimum 0): `Currency.Gems`, `Daily.LastClaimDay`, `Daily.Streak` (maximum 7).
Key: `FieldsService READ_WRITE` + Gateway.

```luau
local today = math.floor(os.time() / 86400) -- UTC day number, identical on every server
local result = profile:immediate()
	:expect("Daily.LastClaimDay", { equals = lastClaimDay }) -- refuses if another server claimed first
	:set("Daily.LastClaimDay", today)
	:set("Daily.Streak", nextStreak)
	:add("Currency.Gems", gems)
	:key(`daily-{player.UserId}-{today}`) -- one grant per player per UTC day, even across retries
	:reason("Daily reward")
	:commit()
if not result.ok and result.error.code == "precondition_failed" then -- already claimed
```

All four changes commit together. Limits: 1-100 operations per transaction, idempotency key 1-200 characters
(`A-Z a-z 0-9 . _ -`, permanent and universe-wide), reason at most 500 characters.
Errors: `precondition_failed` (lost a race: treat as claimed), `below_min` / `above_max` / `max_delta_exceeded` (field
limits), `unknown_field`, `lease_lost`.

## Shop paid with currency

Example: [currency-shop.server.luau](../examples/server/currency-shop.server.luau).

Fields `Currency.Gems` (int, minimum 0) and `Inventory.Items` (map of int); config namespace `Shop` with
`Prices = { "SWORD": 100 }`. Keys: `FieldsService READ_WRITE`, `ConfigService READ`.

```luau
local price = shop:get("Prices", {})[itemId]
local result = profile:immediate()
	:add("Currency.Gems", -price)
	:mapAdd("Inventory.Items", itemId, 1)
	:reason("Shop purchase " .. itemId)
	:commit()
```

The price comes from cached server config, never from the client. The minimum 0 on the balance is the real guard: a
concurrent spend fails with `below_min`. The builder keeps one generated identity across the SDK's retries, so a retry
cannot charge twice; after a `sdk_timeout` call the same builder's `commit` again. For Robux items use Products.

## Live tuning with config

Example: [live-tuning.server.luau](../examples/server/live-tuning.server.luau). Full API: [CONFIGS.md](CONFIGS.md).

```luau
local tuning = client.configs:namespace("Tuning")
local xp = tuning:getNumber("XpMultiplier", 1) -- instant, cached
tuning.Changed:connect(function(change) print("version", change.version, table.concat(change.keys, ", ")) end)
if tuning:isStale() then warn(tuning:lastError()) end -- polling is failing; last good values still served
```

Operators (a key with `ConfigService ADMIN`, never a game server):
`tuning:set("XpMultiplier", 2, { description = "Weekend double XP", expectedVersion = 3 })`,
`tuning:setMany({ set = {...}, delete = {...} })` (atomic), `tuning:rollback(4)` (restores version 4 as a new version).
Errors: `version_conflict` (re-read and retry), `validation_failed`, `limit_exceeded`.

## Redeemable code

Example: [codes-redemption.server.luau](../examples/server/codes-redemption.server.luau). Full API: [CODES.md](CODES.md).

```luau
client.codes:create({ code = "WELCOME100", award = client.codes:award():add("Currency.Gems", 100),
	expiresAt = "2026-12-31T00:00:00Z", maxGlobalRedemptions = 5000 })           -- administrator, CodeService ADMIN

local outcome = client.codes:redeem(player, text) -- server only; validate type and length first, rate limit per player
if outcome.status == "granted" then ... elseif outcome.status == "retry" then ... end
```

`retry` is safe to repeat (the same player and code can never be granted twice); `failed` carries `error.code`
(for example a missing Fields write permission) and is not the player's fault. Treat batch exports as secrets.

## Rotating daily shop

Example: [daily-shop.server.luau](../examples/server/daily-shop.server.luau). Full API: [ROTATIONS.md](ROTATIONS.md).

```luau
client.fields:putRotation({ path = { key = "daily_shop" }, body = {
	items = { { id = "SWORD", data = { price = 100 } }, { id = "SHIELD", data = { price = 80 } }, { id = "BOW" } },
	every = "1d", show = 2, order = "shuffled" } })
local rotations = client.fields:rotations()
local current = rotations:current("daily_shop") -- cached until the period ends (at most 60 s)
-- Before selling, confirm the item id is in current.value.items; never trust an id sent by a client.
```

A rotation only says which items are active: it has no prices, stock or rewards. Charge with a transaction.

## Top 10 and my rank

Example: [leaderboard.server.luau](../examples/server/leaderboard.server.luau). Full guide: [LEADERBOARDS.md](LEADERBOARDS.md).

```luau
local top = client.leaderboards:top({ path = { name = "gems" }, query = { limit = 10 } }) -- cache it about a minute
local mine = client.leaderboards:user({ path = { name = "gems", userId = player.UserId } }) -- rank, score, total
```

Ranks are recalculated every minute, so caching for a minute loses nothing. A `NotFound` for a player means no score yet.

## Equipment and event-only items

Keep what a player owns in one item set field and what is equipped in a second field with `maxMembers = 1`; for event
items, give each event its own list and check `usable`. See [item lists](ITEM-LISTS.md), the
[equipment](../examples/server/equipment.server.luau) and [event items](../examples/server/event-items.server.luau) examples.

## Player trade

(No runnable example script; the code below is type-checked against the SDK.)

Fields `Items.Owned` (Item set over an `Items` list, limit 64) and `Currency.Gems` (int, minimum 0). Key: `FieldsService READ_WRITE`.
Load the field list once (`client.fields:schemaCache():load()`, or load a profile).

```luau
local client = require(script.Parent.Client) -- your shared BloxSDK client
local OWNED, GEMS = "Items.Owned", "Currency.Gems"

-- The buyer pays gems, the seller hands over one item. Returns "traded", "changed", "refused",
-- "retry" (nothing was sent) or "unknown" (sent, outcome not known: ask again with the same tradeId).
local function swap(tradeId: string, buyer: number, seller: number, gems: number, item: string): string
    local sellerItems = client.fields:playerMembers({ path = { userId = seller, field = OWNED } })
    local buyerItems = client.fields:playerMembers({ path = { userId = buyer, field = OWNED } })
    if not sellerItems.ok or not buyerItems.ok then
        return "retry"
    end
    if not table.find(sellerItems.value.members, item) or table.find(sellerItems.value.retired, item) then
        return "refused" -- the seller does not own it, or it was retired
    end

    local tx = client.fields:multiTransactionBuilder()
    tx:subject(seller)
    tx:expect(OWNED, { version = sellerItems.value.version }) -- stops the item being sold twice
    tx:revoke(OWNED, { item })
    tx:add(GEMS, gems)
    tx:subject(buyer)
    tx:expect(OWNED, { version = buyerItems.value.version })
    tx:grant(OWNED, { item })
    tx:add(GEMS, -gems) -- the field's minimum 0 refuses this when the buyer cannot pay
    tx:key("trade-" .. tradeId) -- save the id before this call; the same id always means the same trade
    tx:reason("Player trade " .. tradeId)

    for attempt = 1, 3 do
        local result = tx:commit() -- a repeat call sends the same sealed body with the same key
        if result.ok then
            return "traded"
        end
        local err = result.error
        if err.code == "precondition_failed" then
            return "changed" -- someone's items changed since the check: nothing moved, start again
        end
        if err.kind ~= "Timeout" and err.kind ~= "Network" and err.kind ~= "Server" and err.kind ~= "CircuitOpen" then
            return "refused" -- below_min, member_limit, member_retired and the like: nothing moved
        end
        task.wait(attempt)
    end
    return "unknown"
end
```

The `expect` lines stop duplication: `revoke` of an item the seller no longer holds does nothing, so without them the
buyer could receive an item the seller never lost. The buyer's minimum 0 on `Currency.Gems` is the payment guard
(`below_min`). Calling `commit` again on the same builder resends the same sealed body with the same key, so a retry
cannot charge twice. After a restart you cannot rebuild the body from fresh reads (the versions have moved on), so save
the inputs with the trade: see [player trading](TRADING.md) for the full flow, crash recovery, history and the errors.
