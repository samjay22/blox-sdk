# Fields Rotations & Generators (0.3.0, unpublished)

Use a universe-bound `bsa_` server key (Fields READ for active heads, stock, preview and odds;
READ_WRITE for rolls/claims). Never expose credentials or these server modules to game clients.
Definitions are server-authoritative Tables, Generators and Rotations—not separate Weather/Shop/Card APIs.
The Fields service `API_CONTRACT.md` and `RotationsController` are the wire source of truth.

```luau
local rotations = client.fields:Rotations(game.GameId)
local generators = client.fields:Generators(game.GameId)
local active = rotations:Get("weather") -- Result<RotationActive>: enabled, current, next
local all = rotations:GetAll() -- Result<{RotationActive}>
local snapshot = client:runtimeSnapshot(30) -- start/reuse the universe's ETag poller
local watch = rotations:Watch("weather", function(instance, activeHeads)
    print(instance.id, instance.result.picks, rotations:TimeRemaining(instance))
end)
-- Later: watch:Disconnect(); client:destroy() disconnects all watches too.
```

## Watch and time

`Watch(key, callback)` returns immediately and delivers the current instance asynchronously, then
**once per previously unseen authoritative current instance ID**, even if snapshot config changes.
Callback arguments are `(RotationInstance, RotationActive)`. Callback errors are isolated. Multiple
watches are independent subscriptions. No callback fires for a predicted next, disabled/null current,
or an omitted/inactive head. `Refresh()` manually resumes/rechecks a watch; `LastError` holds a
fallback fetch error. `Disconnect()` is idempotent and cancels its timer, in-flight signal and listeners.
Client flush/destroy also owns this lifecycle.

When a same-universe runtime snapshot supplies `rotations` (including `[]`), Watch consumes its
existing Changed signal: **zero added HTTP requests and zero rotation timers**. Start the snapshot
before Watch to avoid an initial active fetch. Existing watches switch when a snapshot starts later;
when it stops they fall back to active reads. Repeated `runtimeSnapshot(interval)` calls reuse that
universe/auth-context's poller; the first interval wins. Head-generation ETag changes are observed
even if the config `version` is unchanged. 304 and failures preserve last-good state; stock claims do
not change the snapshot ETag. Snapshot mode freshness is its configured polling interval, not instant
notification at an edge. Use one shared poller for weather, shop and game config.

Without a snapshot rotations member (or without a snapshot), Watch reads `/rotations/{key}/active`
once, then schedules **one** refresh at current `endsAt` plus 50–250ms jitter using injected Unix time.
It does not poll definitions or stock, nor repeatedly refresh for unrelated legacy snapshot changes.
No current/future end, a disabled resource, or a failed fallback read stops the timer rather than
busy-polling: call `Refresh()` explicitly to resume after recovery/re-enabling. Existing pipeline
bounded transient retries still apply inside one refresh. A pending initial snapshot is awaited;
its own LastError reports failures until it supplies data. Clocks must be synchronized: countdowns
are display hints; DB time and the current head decide claim validity.

`TimeRemaining(instance)` returns clamped seconds (including fractions), using the injected Unix
clock; it sends no HTTP. Never locally promote `next` into a claimable head.

`GetAll()` uses cached snapshot rotations if supplied (fully inactive heads are omitted by the
service); otherwise it lists the bounded rotation definition catalog and fetches each active head,
including disabled envelopes. There is no invented “all active” HTTP route. A fallback partial
failure returns that failure rather than an incomplete success. Cache reads retain last-good state.

## Claims, purchases and stock

```luau
local stock = rotations:GetStock(instanceId) -- Result<{slot,entryId,remaining}>
local claimed = rotations:Claim(instanceId, "packs:0", "starter_pack", 1, {
    playerId = player.UserId,
    idempotencyKey = persistedPurchaseId, -- optional; auto-generated once if omitted
})
```

Only outputs with a named `stock` roll can be claimed. Quantity is 1–100. Claim atomically decrements
live stock and applies the pinned generator cost and entry grants; **do not debit or grant again**.
`result.rolls.stock` is the instance's initial stock; the stock endpoint returns live inventory.
`ClaimResult.remaining` is the historical post-claim value, not live stock on a later replay.
Identical successful claims and rolls replay the **exact saved body**, including the original
`transaction.replayed` value; expiry does not invalidate a successful replay.

Auto keys survive automatic retries, not independent logical calls/restarts. Persist the same key
**and original complete request (including instance ID)** for an uncertain-outcome retry. Never
change an intent to a new head with its old key. A new purchase/opening needs a new key.

Failures remain `Result` errors. 409 `rotation_out_of_stock`, `rotation_expired`, `insufficient_funds`
and `idempotency_conflict` retain their allowlisted code, Conflict kind and HTTP status; no automatic
retry, regrant, debit or key replacement occurs. Raw backend messages/body stay redacted. Refresh UI
on expiry; do not silently buy a different item. Match player identity to the authenticated Roblox
Player; enforce game-side intent authorization/rate limits before server calls.

## Rolls, previews and odds

```luau
local opened = generators:Roll("card_pack", player.UserId, {
    count = 1, idempotencyKey = persistedOpeningId,
})
local dryRun = generators:Preview("card_pack", player.UserId, 1)
local odds = generators:GetOdds("rarity", player.UserId)
```

Count is **packs**, 1–10 (default 1), not card count. All packs succeed together: `GeneratorRollResult`
contains `results: {Generated}`, each with `picks`, `cost`, `pityAfter` (number or `BloxSDK.null`) and
`resolvedConfig`; plus `transaction`, `definitionVersions`, ID, generator, player ID and createdAt.
Picks expose slot/index/table/entryId/path/tags/payload/rolls/durationSeconds/grants. The transaction
records the applied costs/grants and final pity writes. Custom payloads/config remain `Core.Json`;
inspect their structure before using game properties. Results follow existing immutable Result conventions.

Preview is available to servers with READ, accepts an optional player ID/count, returns `{Generated}`,
and performs **no** debits, grants, stored-pack consumption or pity writes. Playerless previews of
pity-dependent generators may fail; supply the player context. No key is needed for a dry run.
All HTTP methods/helpers accept a final `Core.CallOptions` argument for deadlines/retries/cancellation.

**GetOdds takes a table key, not a generator key.** `RandomOdds` includes root `entryProbabilities`,
terminal-identity `probabilities` and `resolvedConfig`. They are exact analytical hierarchical
probabilities under current conditions/flags and optional player context. They are **not** final pack
odds after uniqueness, guarantees or pity. Label in-game odds accordingly; the API has no analytical
final-generator odds endpoint. The raw `fields:simulateGenerator` is read-only independent-trial
simulation, not an evolving economy calculation or an exact disclosure substitute.

## Lower-level routes and types

All 31 controller routes are available through `client.fields`, including table/generator/rotation
catalog/create/get/replace/delete, history, editor hints/schema, advance/reroll and confirmed subsystem
erasure. See [route inventory](ENDPOINTS.md) and [coverage](../SDK_COVERAGE.md). Admin controls are not
silently retried; definition writes with `applyNow=true` additionally require ADMIN. Requests use
ordinary `{path,query,body}` wrappers and existing scope/retry/idempotency conventions. Public engine
envelopes have isolated `Random*`/`Rotation*`/`Generator*` names, not aliases for ordinary Fields DTOs.
Definition JSON is the service's closed schema (discoverable with `randomnessSchema`), not arbitrary
client-defined operations. `grants`/`cost` reuse the existing typed `PlayerOperation` vocabulary,
including **MAP_ADD**, never an invented MAP_INCREMENT alias.

Examples use the service's complete Weather/30-minute Pack store/Card pack setup bundle. Install
those definitions/configs/flags via their respective APIs first; the SDK does not create demo data:
[weather lighting](../examples/weather.luau), [pack-store UI and Claim](../examples/pack-store.luau),
[card-pack Roll and odds UI data](../examples/card-pack.luau). Opening the bundle's card pack charges
its configured Gems cost; it does not implicitly consume `Inventory.Packs`. Change the configured
cost if the game requires stored-pack consumption. All examples run on trusted servers.
