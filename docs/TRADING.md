# Player trading

Let two or more players swap gems and items in one all-or-nothing transaction. This page has the same content as the portal guide Player trading (Docs, Fields). It was checked against SDK 10.0.0; no SDK code changed for it.

## What a trade is here

A trade is one transaction that changes two or more players at once. Anna gives 50 gems and a sword, Ben gives a shield, and either all of it happens or none of it does. There is no moment when Anna has paid and Ben has not been paid.

The platform gives you the safe part:

- All or nothing. One multi-player transaction changes up to 10 players. Their new values, field versions, history records and the saved answer commit together, or none of them do.
- Safe retries. Every transaction has an idempotency key. Send the same key again and you get the first answer back, never a second trade. Keys are remembered for the whole universe, forever.
- Conditions. You can say "only if Anna's items are still at version 12". If anything changed, the service answers `precondition_failed` and applies nothing. Conditions look at the state the transaction started from.
- Bounds. A field's minimum and maximum are checked inside the same transaction. If Anna spent her gems a moment ago, the whole trade fails with `below_min` and nobody changes.
- Many kinds of value. Numbers (`add`), item sets (`grant`, `revoke`), maps and lists all work in the same transaction. See [Item lists](ITEM-LISTS.md).
- A reason on every change. Your reason text and an optional `ref` are recorded with each change in the player's history (the ledger, which is the default history for a field).

## What you build yourself

The platform does not know what a trade is. It only knows how to change several players safely. Everything around that is your game:

- The offer and accept flow, the trade window and its buttons.
- Cancel, timeouts and one open trade per player.
- Rules: which items can be traded (flags), cooldowns, value limits, level limits, scam protection.
- Sending the offer between two servers, if the players are on different servers. The SDK has no trade messages.
- A trade log that players can read. The ledger records each change, but there is no built-in trade history page; see Trade history below for a pattern.

> **No escrow.** Nothing is held between the offer and the commit. Offered items and gems stay with their owner until the one transaction runs. If an owner spends or trades them first, the conditions and bounds make the whole trade fail safely. That is the design: you do not need to give anything back.

## The core recipe: swap gems and items between two players

This module swaps gems and tradeable items between two players, with conditions that stop duplication and stale offers. It runs in two steps. `prepare` reads what the service holds right now and returns an intent. `commit` sends that intent. The intent holds the key and everything the body is built from, so it can be saved before the commit and sent again, byte for byte, after a crash.

```luau
-- ServerScriptService/TradeCommit (ModuleScript). Server only: it uses a key with FieldsService READ_WRITE.
-- Fields (create them once in the portal, see "Make a Tradeable list" and "Trade history"):
--   Currency.Gems    whole number, minimum 0
--   Items.Owned      Item set over your item list, limit 64
--   Items.Tradeable  Item set over the same list: the owned items that may be traded
--   Trade.History    list of objects, at most 50 records
local client = require(script.Parent.Client) -- your shared BloxSDK client, see Getting started
local OWNED, TRADEABLE, GEMS, HISTORY = "Items.Owned", "Items.Tradeable", "Currency.Gems", "Trade.History"
local MAX_HISTORY = 50

export type Side = { userId: number, gems: number, items: { string } }
export type Intent = {
    tradeId: string,
    key: string, -- the idempotency key: save it before you commit
    at: number, -- Unix seconds, fixed once so a retry sends the same body
    sides: { Side }, -- exactly two
    versions: { [string]: number }, -- "userId:field" -> the version the offer was checked against
    trim: { [number]: boolean }, -- userId -> the history list is full, drop the oldest record
}

local TradeCommit = {}

local function slot(userId: number, fieldId: string): string
    return string.format("%d:%s", userId, fieldId)
end

local function summary(side: Side): string
    local parts = {}
    if side.gems > 0 then
        table.insert(parts, string.format("%d gems", side.gems))
    end
    for _, name in side.items do
        table.insert(parts, name)
    end
    return table.concat(parts, ", ")
end

--- Read what the service holds right now and decide whether the offer is allowed.
--- Returns the intent to save and commit, or nil and a reason: "not_owned", "not_tradeable", "retired",
--- "not_enough_gems" or "unavailable". Nothing is changed here.
function TradeCommit.prepare(tradeId: string, attempt: number, a: Side, b: Side, now: number): (Intent?, string)
    local intent: Intent = {
        tradeId = tradeId,
        key = string.format("trade-%s-%d", tradeId, attempt), -- letters, digits, . _ - only; 200 characters at most
        at = now,
        sides = { a, b },
        versions = {},
        trim = {},
    }
    for _, side in intent.sides do
        -- The minimum 0 on Currency.Gems is the real guard. This read only gives the player a clear message.
        local gems = client.fields:field({ path = { userId = side.userId, fieldId = GEMS } })
        if not gems.ok then
            return nil, "unavailable"
        end
        local balance = gems.value.value
        if side.gems > 0 and (type(balance) ~= "number" or balance < side.gems) then
            return nil, "not_enough_gems"
        end
        for _, fieldId in { OWNED, TRADEABLE } do
            local held = client.fields:playerMembers({ path = { userId = side.userId, field = fieldId } })
            if not held.ok then
                return nil, "unavailable"
            end
            intent.versions[slot(side.userId, fieldId)] = held.value.version
            for _, name in side.items do
                if table.find(held.value.retired, name) then
                    return nil, "retired"
                elseif not table.find(held.value.members, name) then
                    return nil, if fieldId == OWNED then "not_owned" else "not_tradeable"
                end
            end
        end
        local history = client.fields:field({ path = { userId = side.userId, fieldId = HISTORY } })
        if not history.ok then
            return nil, "unavailable"
        end
        local records = history.value.value
        intent.trim[side.userId] = type(records) == "table" and #records >= MAX_HISTORY
    end
    return intent, "ok"
end

--- Build the one transaction for an intent. The same intent always builds the same body.
local function build(intent: Intent)
    local tx = client.fields:multiTransactionBuilder()
    local guarded: { [string]: boolean } = {}
    -- A condition: the field must still be at the version we checked, or nothing is applied.
    local function guard(userId: number, fieldId: string)
        local id = slot(userId, fieldId)
        if guarded[id] then
            return
        end
        guarded[id] = true
        tx:subject(userId)
        tx:expect(fieldId, { version = intent.versions[id] })
    end
    for i, giver in intent.sides do
        local receiver = intent.sides[3 - i]
        if giver.gems > 0 then
            tx:subject(giver.userId)
            tx:add(GEMS, -giver.gems) -- fails with below_min if the balance is no longer enough
            tx:subject(receiver.userId)
            tx:add(GEMS, giver.gems)
        end
        if #giver.items > 0 then
            for _, fieldId in { OWNED, TRADEABLE } do
                guard(giver.userId, fieldId)
                guard(receiver.userId, fieldId)
            end
            tx:subject(giver.userId)
            tx:revoke(OWNED, giver.items)
            tx:revoke(TRADEABLE, giver.items)
            tx:subject(receiver.userId)
            tx:grant(OWNED, giver.items)
            tx:grant(TRADEABLE, giver.items)
        end
    end
    for i, side in intent.sides do
        local other = intent.sides[3 - i]
        tx:subject(side.userId)
        if intent.trim[side.userId] then
            tx:removeAt(HISTORY, 0, 1) -- drop the oldest record so the list never passes its maximum
        end
        tx:append(HISTORY, {
            { TradeId = intent.tradeId, At = intent.at, Partner = other.userId, Gave = summary(side), Got = summary(other) },
        })
    end
    tx:key(intent.key)
    tx:reason("Player trade " .. intent.tradeId)
    tx:ref("trade", intent.tradeId)
    return tx
end

--- Send the intent. Safe to call again with the same intent after any failure that is not a clear refusal.
--- Returns the outcome and the full Result:
---   "committed"  both players changed together (value.replayed is true when an earlier attempt got there first)
---   "stale"      a condition failed: nothing changed, the offer is out of date, prepare again
---   "retry"      outcome unknown: call commit again with the same intent, never with a new key
---   "rejected"   the rules refused it (below_min, member_limit, ...): nothing changed
function TradeCommit.commit(intent: Intent): (string, any)
    local result = build(intent):commit()
    if result.ok then
        return "committed", result
    end
    local err = result.error
    if err.code == "precondition_failed" then
        return "stale", result
    end
    local unknown = err.kind == "Timeout" or err.kind == "Network" or err.kind == "Server"
        or err.kind == "CircuitOpen" or err.kind == "RateLimited"
        or err.code == "transaction_send_failed" or err.code == "version_conflict"
    if unknown then
        return "retry", result
    end
    return "rejected", result
end

--- Bring the profiles loaded on THIS server up to date. profiles maps userId to a profile from loadProfile.
function TradeCommit.applyTo(profiles: { [number]: any }, result: any)
    for _, profile in profiles do
        if not profile:apply(result.value) then
            profile:pullChanges() -- could not apply safely: read the service's current state instead
        end
    end
end

return TradeCommit
```

## Why an intent, not just a key

A retry must send the same transaction as the first attempt. The key identifies the request, and the service compares the body. If the first attempt did commit but the answer was lost, and you rebuild the transaction from fresh reads, the versions in the conditions have moved on. The body differs and the service answers `idempotency_conflict`, although the trade did happen.

So the example saves the whole intent (key, time, the offer and the versions it was checked against) and builds the transaction from it every time. Keep these rules:

- Save the intent first, commit second. If the save fails, do not commit.
- Never edit a saved intent. A different offer is a different trade with a new key (the example adds an attempt number).
- Use the same intent after a timeout, a network error or a server error. A new key after an uncertain failure can charge twice.
- When the service answers `precondition_failed` or a clear refusal, nothing was applied, so a new `prepare` with a new key is correct.

## Handling every outcome

| Outcome | What it means | What to do |
|---|---|---|
| committed | Both players changed together. `value.replayed` is true when an earlier attempt already did it. | Apply the result to loaded profiles, show success, mark the saved intent finished. |
| stale | A condition failed (`precondition_failed`). Nothing changed. Someone's items moved after you checked. | Reopen the trade. Both players look at the offer again and lock again. The next commit prepares fresh versions and a new key. |
| retry | The outcome is unknown: a timeout, a network or server error, a rate limit, or the SDK could not send. | Commit the same saved intent again. Wait a little longer each time. If you give up, leave the intent saved and let a recovery job finish it. |
| rejected | The rules refused it: `below_min`, `above_max`, `max_delta_exceeded`, `member_limit`, `member_retired`, `unknown_member`, `above_max_size`, `forbidden`, `scope_denied`, `invalid_request`. Nothing changed. | Tell the players why (see the errors table), mark the intent finished, cancel or reopen the trade. |

> **How the SDK classifies errors.** `error.kind` says what happened. Timeout, Network, Server, CircuitOpen and RateLimited can leave the outcome unknown, so the example retries those with the same key. Conflict (like `precondition_failed`), Validation, Forbidden and Local mean the request was refused or never sent. The service source can also answer 409 `version_conflict` when its fast path keeps losing a race under heavy load. The API contract does not list that code, so this page treats it as "retry with the same key" and flags it as not documented.

## Live profiles and other servers

A multi-player transaction is a plain Fields transaction. It goes to the Fields service, not to a game server, and the request carries no server id and no lease epoch, so it neither takes nor checks a player's session lease. The contract lists trades among the "non-owner writers" that use these immediate transaction routes. This is what the code and the contract say:

- The multi-player builder does not update loaded profiles for you. After a successful commit, call `profile:apply(result.value)` on each profile loaded on this server. It reads only that player's entries and ignores versions it already has, so a replayed result never rolls anything back.
- If `apply` returns false the profile could not be updated safely (it is marked stale). Call `profile:pullChanges()`, which reads the service's current state. The example does this.
- A player who is loaded on a different server is updated by that server's own sync: it asks the service which of its players changed elsewhere, about every tick, and re-reads every leased player every 30 seconds by default (`profileSync.resyncSeconds`). The service's notice to the owner is best effort (a failed notice is only logged), so the 30 second re-read is the safety net.
- Two players on the same server and two players on different servers use the same code. The result is the same in the service. Only how fast the local copy of a profile catches up differs, and the docs promise nothing faster than the sync interval.
- The service owns the truth. The owner server's buffered writes are ADD and SET operations evaluated against the service's current values, and the service documents that they cannot overwrite a concurrent trade. A stale local copy can still make your game show an item the player no longer has until it syncs, so check ownership on the server at the moment of an action, not only from the cached profile.
- Buffered profile changes reach the service within about five seconds. A trade reads the service, so an item granted a moment ago can be refused as not owned for a few seconds. Ask the player to try again.

## A trade service: offers, locks and confirmations

The core module only commits. Players need a flow around it, and the flow decides when a commit is allowed. This service keeps one `Trade` table per pair of players in server memory and moves it through these states:

open: offers change -> locked: both locked -> committing: both confirmed -> committed or cancelled

- open: either player can change their offer. Any change clears every lock and confirmation.
- locked: both players locked the offer they see. Now each one confirms. Changing an offer sends the trade back to open.
- committing: the second confirmation arrived. The state changes before anything yields, so a late offer change or a double click cannot slip in. Now `prepare` reads fresh versions, the intent is saved, then the commit runs.
- committed: done, and the loaded profiles were updated.
- cancelled: a player cancelled, left, or the trade timed out. Nothing was moved before the commit, so there is nothing to give back.

```luau
-- ServerScriptService/TradeService (ModuleScript). One Trade table per pair of players, kept in server memory.
-- The platform has no trade object: everything in this file is your own game logic.
local TradeCommit = require(script.Parent.TradeCommit) -- the first example

local TradeService = {}
local OFFER_LIMIT = 8 -- items per side: your rule, not the platform's
local TRADE_SECONDS = 120 -- idle time before an open trade is cancelled: your rule

export type Offer = { gems: number, items: { string }, locked: boolean, confirmed: boolean }
export type Trade = {
    id: string,
    state: string, -- "open", "locked", "committing", "committed" or "cancelled"
    players: { number },
    offers: { [number]: Offer },
    expiresAt: number,
    attempts: number,
}
-- You provide these three with a DataStore, a MemoryStore or your own database. The SDK has no store for them.
export type Store = {
    save: (intent: TradeCommit.Intent) -> boolean, -- true only once the intent is durably written
    finish: (intent: TradeCommit.Intent, outcome: string) -> (),
    pending: () -> { TradeCommit.Intent }, -- saved intents nobody has finished yet
}

local function emptyOffer(): Offer
    return { gems = 0, items = {}, locked = false, confirmed = false }
end

function TradeService.open(id: string, a: number, b: number, now: number): Trade?
    if a == b then
        return nil
    end
    return {
        id = id,
        state = "open",
        players = { a, b },
        offers = { [a] = emptyOffer(), [b] = emptyOffer() },
        expiresAt = now + TRADE_SECONDS,
        attempts = 0,
    }
end

-- Changing an offer clears every lock and confirmation, so nobody confirms something that has moved.
function TradeService.setOffer(trade: Trade, userId: number, gems: number, items: { string }, now: number): string
    local offer = trade.offers[userId]
    if not offer or (trade.state ~= "open" and trade.state ~= "locked") then
        return "not_open"
    end
    if type(gems) ~= "number" or gems ~= math.floor(gems) or gems < 0 or #items > OFFER_LIMIT then
        return "bad_offer"
    end
    local seen: { [string]: boolean } = {}
    for _, name in items do
        if type(name) ~= "string" or seen[name] then
            return "bad_offer"
        end
        seen[name] = true
    end
    offer.gems = gems
    offer.items = table.clone(items)
    for _, each in trade.offers do
        each.locked = false
        each.confirmed = false
    end
    trade.state = "open"
    trade.expiresAt = now + TRADE_SECONDS
    return "ok"
end

-- Step 1: each player locks the offer they see. Both locked moves the trade to "locked".
function TradeService.lock(trade: Trade, userId: number): string
    local offer = trade.offers[userId]
    if not offer or trade.state ~= "open" then
        return "not_open"
    end
    offer.locked = true
    for _, each in trade.offers do
        if not each.locked then
            return "waiting"
        end
    end
    local empty = true
    for _, each in trade.offers do
        if each.gems > 0 or #each.items > 0 then
            empty = false
        end
    end
    if empty then
        offer.locked = false
        return "empty_trade"
    end
    trade.state = "locked"
    return "locked"
end

-- Step 2: each player confirms. The second confirmation is the only place a commit starts.
function TradeService.confirm(trade: Trade, userId: number, now: number, store: Store, profiles: { [number]: any }): string
    local offer = trade.offers[userId]
    if not offer or trade.state ~= "locked" then
        return "not_locked"
    end
    offer.confirmed = true
    for _, each in trade.offers do
        if not each.confirmed then
            return "waiting"
        end
    end
    return TradeService.settle(trade, now, store, profiles)
end

function TradeService.settle(trade: Trade, now: number, store: Store, profiles: { [number]: any }): string
    -- Change the state before anything yields, so no offer change or second confirm can slip in.
    trade.state = "committing"
    trade.attempts += 1
    local a, b = trade.players[1], trade.players[2]
    local intent, reason = TradeCommit.prepare(
        trade.id,
        trade.attempts,
        { userId = a, gems = trade.offers[a].gems, items = trade.offers[a].items },
        { userId = b, gems = trade.offers[b].gems, items = trade.offers[b].items },
        now
    )
    if not intent then
        trade.state = "cancelled"
        return reason
    end
    -- Save the key and the exact body BEFORE committing, so a crash can be finished later.
    if not store.save(intent) then
        trade.state = "cancelled"
        return "unavailable"
    end
    local outcome, result = TradeCommit.commit(intent)
    for wait = 1, 3 do
        if outcome ~= "retry" then
            break
        end
        task.wait(wait)
        outcome, result = TradeCommit.commit(intent) -- the same intent, so the same key and body
    end
    if outcome == "retry" then
        return "pending" -- still unknown: leave it saved, TradeService.recover finishes it later
    end
    store.finish(intent, outcome)
    if outcome == "committed" then
        trade.state = "committed"
        TradeCommit.applyTo({ [a] = profiles[a], [b] = profiles[b] }, result)
        return "committed"
    elseif outcome == "stale" then
        trade.state = "open" -- something changed under the offer: both players look again and re-lock
        for _, each in trade.offers do
            each.locked = false
            each.confirmed = false
        end
        return "stale"
    end
    trade.state = "cancelled"
    return string.format("rejected:%s", result.error.code)
end

function TradeService.cancel(trade: Trade, userId: number): string
    if not trade.offers[userId] then
        return "not_in_trade"
    end
    if trade.state == "committing" or trade.state == "committed" then
        return "too_late"
    end
    trade.state = "cancelled" -- nothing was moved before the commit, so there is nothing to give back
    return "cancelled"
end

function TradeService.expire(trade: Trade, now: number): boolean
    if (trade.state == "open" or trade.state == "locked") and now >= trade.expiresAt then
        trade.state = "cancelled"
        return true
    end
    return false
end

-- Run once when the server starts and then every minute or so: finish intents a crash left behind.
function TradeService.recover(store: Store, profiles: { [number]: any }): number
    local finished = 0
    for _, intent in store.pending() do
        local outcome, result = TradeCommit.commit(intent) -- saved intent: same key, same body
        if outcome == "retry" then
            continue
        end
        store.finish(intent, outcome)
        if outcome == "committed" then
            local a, b = intent.sides[1].userId, intent.sides[2].userId
            TradeCommit.applyTo({ [a] = profiles[a], [b] = profiles[b] }, result)
        end
        finished += 1
    end
    return finished
end

return TradeService
```

Where the commit happens: only in `settle`, called from the second `confirm`. Both players confirm immediately before it, because any change to an offer clears the confirmations, and `settle` itself reads the service again. What the players confirmed is therefore what the commit checks.

If the server crashes: before `store.save` nothing happened and the trade is lost with no harm. After `save`, the next run of `recover` sends the saved intent with the same key. The transaction is atomic, so it either happened (you get the original answer back with `replayed` true) or it did not (it commits now, or fails a condition, which finishes the intent as stale).

The glue below connects Roblox events to the service. The player always comes from the event, never from the payload.

```luau
-- ServerScriptService/Trading (Script). Glue between your RemoteEvents, the trade service and the profiles.
local Players = game:GetService("Players")
local client = require(script.Parent.Client)
local TradeService = require(script.Parent.TradeService)
local store = require(script.Parent.TradeStore) -- your save, finish and pending functions
local offerRemote = game:GetService("ReplicatedStorage"):WaitForChild("TradeOffer")
local confirmRemote = game:GetService("ReplicatedStorage"):WaitForChild("TradeConfirm")

local profiles: { [number]: any } = {} -- userId -> profile from loadProfile
local tradeOf: { [number]: any } = {} -- userId -> the trade that player is in

local function refreshTradeWindow(trade: any, outcome: string)
    -- Tell both players' windows what the trade looks like now. This part is your UI.
end

Players.PlayerAdded:Connect(function(player: any)
    local loaded = client.fields:loadProfile(player.UserId)
    if loaded.ok then
        profiles[player.UserId] = loaded.value
    else
        warn(loaded.error.code)
    end
end)

Players.PlayerRemoving:Connect(function(player: any)
    local trade = tradeOf[player.UserId]
    if trade then
        refreshTradeWindow(trade, TradeService.cancel(trade, player.UserId)) -- too_late once committing
    end
    tradeOf[player.UserId] = nil
    profiles[player.UserId] = nil
end)

-- The player is the Roblox Player the event came from, never an id in the payload.
offerRemote.OnServerEvent:Connect(function(player: any, gems: any, items: any)
    local trade = tradeOf[player.UserId]
    if not trade or type(items) ~= "table" then
        return
    end
    -- The names are only checked for shape here. Ownership is checked when the service prepares the commit.
    refreshTradeWindow(trade, TradeService.setOffer(trade, player.UserId, gems, items, os.time()))
end)

confirmRemote.OnServerEvent:Connect(function(player: any)
    local trade = tradeOf[player.UserId]
    if trade then
        refreshTradeWindow(trade, TradeService.confirm(trade, player.UserId, os.time(), store, profiles))
    end
end)

-- When both players accept an invitation (your UI), start a trade with a new unique id (letters, digits, dashes):
--   local trade = TradeService.open(newId(), playerA.UserId, playerB.UserId, os.time())
--   tradeOf[playerA.UserId], tradeOf[playerB.UserId] = trade, trade

-- Finish anything a crash left half done, now and then every minute.
task.spawn(function()
    while true do
        TradeService.recover(store, profiles)
        task.wait(60)
    end
end)
```

## How the conditions protect you

Think of a plain trade without conditions: take the sword from Anna, give it to Ben. `revoke` of an item the player no longer holds does nothing, and `grant` to Ben still happens. If Anna traded the sword away a second earlier, Ben gets a sword out of thin air. That is a duplication bug, and the transaction alone does not stop it.

The fix is a condition on the item set of every player whose items move: `expect("Items.Owned", { version = n })`. Item set fields are whole-field values, so a member-level condition is not available. The condition only passes if the field is exactly as you read it, and the whole transaction fails otherwise. Currency needs no condition: its minimum of 0 is the guard, and a balance that dropped fails with `below_min`. Version conditions on a currency would make the trade fail every time the player earned a coin.

## Anti-dupe and safety checklist

1. One transaction per trade, with conditions on every item set field that changes. Never two separate player transactions, and never a `revoke` without a condition.
2. Save the key and the exact inputs before you commit, and retry with the same ones. A new key after an uncertain failure can run the trade twice.
3. Never trust the client. The Player comes from the Roblox event. Item names from a client are only names: check that the service holds them, that they are tradeable and not retired. Gem amounts are whole numbers you validate. Prices and values come from server config.
4. A retired member can still be taken away but not given to anyone: `member_retired` fails the whole trade. Check `retired` when you prepare and refuse the offer with a clear message.
5. If an item can be equipped, take it off in the same transaction (`revoke` it from the Equipped field) or refuse to trade equipped items.
6. Keep to the limits: at most 10 players, 100 operations and 100 conditions in one transaction. Count a player who only has a condition.
7. Allow one open trade per player, and block the player's shop and other economy actions while a trade is locked. The platform does not lock them for you. The conditions and bounds make a clash fail safely, but a clean message is kinder.
8. Rate limit your own offers and invitations (a cooldown per player). Keys can also be rate limited by the platform (`key_rate_limited`): back off, do not loop.
9. Apply the result to the loaded profiles, and mark the saved intent finished.
10. Test in the Dev environment with a dev key first. Promote only structure (field definitions and item lists) with Transfer. Player data, including trade history, is never transferred.

## Make a Tradeable list with item lists

Not every item should be tradeable. Starter gifts and quest rewards are often bound to the player. A simple pattern uses two Item set fields over the same item list:

- Items.Owned: everything the player has.
- Items.Tradeable: the owned items that may be traded. An item granted as bound goes into Owned only.
- Keep Tradeable inside Owned: grant and revoke both in one transaction, as the trade does.

Create the list once (needs ConfigService ADMIN), then the fields in the portal under Fields, type Item set (needs FieldsService ADMIN):

```luau
-- Admin tooling only: a key with ConfigService ADMIN, never a game server.
local items = client.configs:namespace("Items")
items:setKind("items") -- once; an item list never goes back to Settings
items:addMember("IronSword", { label = "Iron Sword" })
items:addMember("StarterBadge", { label = "Starter Badge" })
```

```json
[
  { "id": "Items.Owned", "type": { "kind": "bitmap", "source": "Items", "maxMembers": 64 } },
  { "id": "Items.Tradeable", "type": { "kind": "bitmap", "source": "Items", "maxMembers": 64 } },
  { "id": "Currency.Gems", "type": { "kind": "int", "min": 0 } }
]
```

In game code, show only what can be offered, and grant tradeable items to both fields in one transaction:

```luau
local OWNED, TRADEABLE = "Items.Owned", "Items.Tradeable"

-- What to show in the offer window: owned, tradeable and still active. A display filter only:
-- the commit checks the service again, so a stale screen can never move an item.
local function offerable(profile): { string }
    local owned = profile:usable(OWNED)
    local tradeable = profile:usable(TRADEABLE)
    local names = {}
    if owned.ok and tradeable.ok then
        for _, name in tradeable.value do
            if table.find(owned.value, name) then
                table.insert(names, name)
            end
        end
    end
    return names
end

-- An item that may be traded goes into both fields in one transaction. A bound item goes into Owned only.
local function giveTradeable(profile, name: string, why: string)
    return profile:immediate():grant(OWNED, { name }):grant(TRADEABLE, { name }):reason(why):commit()
end
```

- Set or single choice. A normal `maxMembers` (here 64) is a set: any mix up to the limit. `maxMembers = 1` is a single choice, such as an equipped slot. Trade out of a single choice field by revoking the member; trade into it only if the slot is empty, otherwise `member_limit` fails the trade.
- `usable` leaves retired members out, so retired items drop out of the offer window. `has` stays true for a held retired item.
- Another way to mark items is a rule in your code or in a Settings namespace: for example a `NoTrade` key listing item names. Use a field when each player's copy can differ (bound or tradeable), and a global list when the item itself decides. See [Item lists](ITEM-LISTS.md).

## Trade history pattern

Append one record to each player's list in the same transaction. If the history cannot be written, the trade does not happen. The list must have a maximum so it cannot grow forever. The field type is:

```json
{
  "id": "Trade.History",
  "type": {
    "kind": "list",
    "maxSize": 50,
    "item": {
      "kind": "object",
      "members": {
        "TradeId": { "type": { "kind": "string", "maxLength": 64 } },
        "At": { "type": { "kind": "int", "min": 0 } },
        "Partner": { "type": { "kind": "int", "min": 1 } },
        "Gave": { "type": { "kind": "string", "maxLength": 1000 } },
        "Got": { "type": { "kind": "string", "maxLength": 1000 } }
      }
    }
  }
}
```

- `list` takes `item`, `minSize` (default 0) and `maxSize` (default 1000, hard maximum 10000). Here the maximum is 50.
- An `object` has at most 64 members. A member is required unless it is `optional` or has a `default`. Strings count Unicode characters; the default maximum is 256 and the hard maximum 65536.
- When a list is full, `append` fails with `above_max_size`. So the example reads the length when it prepares, and sends `removeAt("Trade.History", 0, 1)` before the `append` when the list is full. Both operations are in the same transaction. If two trades race for the last slot, the second fails and is prepared again.
- New records are at the end. Read them with `client.fields:field` and show the last few.

```luau
-- The most recent records are at the end of the list (new records are appended).
local function recentTrades(userId: number)
    local read = client.fields:field({ path = { userId = userId, fieldId = "Trade.History" } })
    if not read.ok or type(read.value.value) ~= "table" then
        return {}
    end
    return read.value.value
end
```

> **History is for players, the ledger is for you.** The field's own ledger records every change with your reason and the trade `ref`. The bounded list is what a player can see in the game. Neither is a trade log page: the platform has no built-in one.

## Limits and performance

| Limit | Value |
|---|---|
| Players in one transaction | 10 (counting players who only appear in a condition) |
| Operations | 1 to 100 |
| Conditions | At most 100 |
| Path segments | At most 8 |
| Subject | A positive player id on every operation and condition. There are no universe-wide values. |
| Reason | Required, 1 to 500 characters (at least 5 for ADMIN level fields) |
| Idempotency key | 1 to 200 characters, A-Z a-z 0-9 . _ - ; permanent and shared by the whole universe |
| Reference (`ref`) | Optional: type up to 100 characters, id up to 200 |
| Item set field | Up to 512 members per field, `maxMembers` 1 to 512; an item list has up to 512 members |
| Access | FieldsService READ_WRITE to commit, READ to read versions and members |

The docs publish no latency or throughput numbers for multi-player transactions, so this page gives none. Every trade touches all of its players at once, so keep trades small, allow one open trade per player, and measure in the Dev environment.

## Errors and fixes

| Code | What it means in a trade | Fix |
|---|---|---|
| precondition_failed | A condition failed: someone's items changed since you checked. Nothing moved. | Prepare again with fresh reads and a new key. Ask both players to look and lock again. |
| below_min | A player no longer has enough of a currency. | Refuse the trade and say who is short. Nothing moved. |
| above_max | A player would end above a maximum (a capped currency). | Lower the amount or change the cap on purpose. |
| max_delta_exceeded | One `add` is bigger than the field's maximum change. | Lower the trade limit. Do not split an amount to get around the rule. |
| member_limit | A player's item set is full, or a single choice slot is taken. | Ask them to free a slot. Check space before offering. |
| member_retired | An offered item was retired: nobody new can receive it. | Remove it from the offer. |
| unknown_member | A name is not in the item list. | Fix the spelling. A member added a moment ago takes about 5 seconds to reach Fields. |
| above_max_size | A list would pass its maximum, usually a full history list. | Drop the oldest record in the same transaction, as the example does. |
| idempotency_conflict | The key was used before with a different body. | Never change a saved intent. Recover the original; use a new key only for a genuinely new trade. |
| idempotency_data_deleted | Privacy deletion removed the old answer for this key. | Do not replace the key to force a second trade. |
| invalid_request | Checked on the server before sending: no player selected, more than 10 players, more than 100 operations or conditions, an empty reason, or a key with bad characters. | Fix the builder. Nothing was sent. |
| schema_unavailable | The field list has not loaded, so nothing was sent. | Call `client.fields:schemaCache():load()` once at start, or load a profile first. |
| unknown_field | A field id is not defined. | Check the field names in the portal. |
| forbidden | The key lacks FieldsService READ_WRITE, or a field needs ADMIN. | Fix the key's grants. |
| scope_denied | The key is restricted and may not use a field. | Widen the key's scope in the portal. |
| key_rate_limited | The key used up its rate limit. | Wait for the Retry-After delay and back off. |

Timeouts and network errors (`sdk_timeout` and similar) mean the outcome is unknown. Commit the same intent again. See the [error index](ERRORS.md) for every code.

## Questions

| Question | Answer |
|---|---|
| Can three players trade? | Yes, up to 10 players. Every player needs a `subject` selection for their operations and conditions, and every player counts toward the 10. The example handles two sides: repeat the flows for more. |
| Can a trade span servers? | The commit can, because it goes to the Fields service. Your offer and accept messages must reach both servers some other way (for example Roblox's MessagingService), because the SDK has no trade messages. Each player's own server catches up through profile sync within its interval. See Live profiles and other servers. |
| What if the server crashes mid-trade? | The transaction is atomic: it either happened or it did not. Save the intent first, and after a restart send it again with the same key. You get the original answer if it happened. |
| Can the same item be offered in two trades? | Yes, the platform reserves nothing. The first commit wins. The second fails its condition and nothing moves. |
| Can I undo a trade? | Not from game code. Operators have ledger tools, and reversal needs ADMIN. This page has not verified how a reversal behaves for a multi-player transaction, so test it in Dev before you promise players an undo. |
| Do players need to be online? | The transaction only needs player ids. Whether offline trades are allowed is your rule. |
| Is there a built-in trade window or trade log? | No. There is no trade UI, no escrow and no trade log. Build them as shown. |

## What this page checked, and what it does not promise

- Checked in the SDK source: the multi-player builder methods, the 10 player, 100 operation and 100 condition limits, the key rules, the sealed body on retries, `expect` with `version`, `equals` or `exists`, and `profile:apply`. The Luau on this page type-checks against the SDK in strict mode, but it was not run against a live service.
- Checked in the Fields contract and source: atomic commit, the original answer replayed for the same key and body, `precondition_failed` against the initial state, item set conditions on whole fields only, and that these routes carry no lease.
- Not verified: latency numbers, how fast another server's profile catches up (only the documented intervals), how an operator reversal treats a multi-player transaction, and the `version_conflict` code, which the service source can return but the contract does not list.
- Not provided by the platform: a trade window, escrow, a trade log, cross-server trade messages, cooldowns and value rules.

See also: [Item lists](ITEM-LISTS.md), [Transactions and safe retries](TRANSACTIONS.md), [Fields](FIELDS.md), [Recipe: player trade](RECIPES.md#player-trade), [Environments and transfer](ENVIRONMENTS.md), [Which feature should I use?](CHOOSING.md), [Error index](ERRORS.md).
