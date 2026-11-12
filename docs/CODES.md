# Codes: redeem and administer

**lb1 callers need `Gateway` plus `CodeService` and downstream `FieldsService` permissions.
`bsa_` keys are bound to one universe.** Redemption requires CodeService READ_WRITE and the Fields
permissions needed to write each awarded field; administration requires ADMIN. The universe is the
client's (see `BloxSDK.new`); no call names it.

## Redeeming a code

```luau
local outcome = client.codes:redeem(player, text) -- a Player or a user ID; one call, never raises on a bad code
if outcome.status == "granted" then
    print("rewards:", #outcome.rewards)
elseif outcome.status == "already_redeemed" then
    print("already used")
elseif outcome.status == "expired" then
    print("too late")
elseif outcome.status == "retry" then
    print("busy, try again") -- safe: the same player and code can never be granted twice
end
```

`outcome.status` is the whole answer. Nothing else needs decoding.

| `status` | Meaning | Extra fields |
|---|---|---|
| `granted` | This call granted the award. | `code`, `rewards`, `redeemedAt?` |
| `already_redeemed` | The player redeemed it before; nothing new was granted. | `code`, `rewards` (the original grant), `redeemedAt?` |
| `invalid` | Unknown, deleted, disabled or malformed code. | |
| `expired` | Past its `expiresAt`. | |
| `not_started` | Before its `startsAt`. | |
| `exhausted` | Its global redemption limit is used up. | |
| `retry` | Timeout, outage, rate limit or open circuit; nothing was confirmed. Call again. | `error` |
| `failed` | Rejected for a reason a retry will not fix: missing permission, an award that no longer matches the schema, a Fields conflict. Log `error.code`. | `error` |

`rewards` lists what the award changed for the player: `{ field, op, path, before, after }` per touched
subvalue. They are receipts, not a player document, and an explicit server null stays `BloxSDK.null`.
If an earlier attempt was granted but its reply was lost, the retry returns `already_redeemed` with the same
rewards; treat both statuses as success if you only care that the player has the award.

The backend applies the award as **one atomic Fields transaction**, permanently deduplicated by
`code-<codeId>-<userId>`. Each player can redeem each code once. The SDK never retries a redemption by
itself, sends it at `critical` priority by default and trims whitespace; blank or over-long text is `invalid`
without a request. `grantPending=true` on `error` means the backend kept an uncertain reservation: call
`redeem` again, never grant by hand. Backend messages are never copied; only allowlisted machine codes remain.

## Creating codes

```luau
client.codes:create({
    code = "WELCOME100",
    award = client.codes:award():add("Currency.Gems", 100):mapAdd("Inventory.Items", "SWORD", 1),
    expiresAt = "2026-12-31T00:00:00Z", -- optional; also startsAt, maxGlobalRedemptions, name, description, active, metadata
})
```

`award` is a `codes:award()` builder or a plain list of 1-100 subject-free Fields operations
(`Fields.PlayerOperation`). The universe schema loads on first use and the award is validated locally
before any request; an invalid award returns `unknown_field`, `max_delta_exceeded` and similar codes
without touching CodeService. The builder uses the transaction method names (`add`, `set`, `mapAdd`, ...);
it has no subject and no commit. `:build()` and `:validate()` remain available for previews.
The backend validates the effective award again through Fields on every create and update.

Static validation does not check current balances, collection lengths, field write authority or runtime
policy; Fields revalidates real state at redemption.

## Batches

```luau
local batch = client.codes:createBatch({
    name = "Summer campaign",
    count = 100,                         -- 1-1000
    prefix = "SUMMER",                   -- optional; random suffix of `length` 8-16 (default 10)
    award = client.codes:award():add("Currency.Gems", 100),
    maxGlobalRedemptions = 1,            -- per code, not per batch
    idempotencyKey = "summer-2026-001",  -- persist this before sending
})
if batch.ok then
    local csv = client.codes:exportBatch(batch.value.batchId) -- raw CSV text; treat as a secret
end
```

Generation is all-or-nothing and grants nothing to players. It returns `{ batchId, count, codes = {{id, code}} }`.
Persist `idempotencyKey` and the request first; after a lost reply, repeat the same call with the same key to get
the original response. Changing keys can create another batch, and bulk calls are never retried automatically.
Codes look like `SUMMER-K7M2XQ9PDA` (uppercase, no `0/O/1/I/L`). Keep this in trusted administrator tooling.
Export columns are `code,name,universeId,expiresAt,maxGlobalRedemptions`; the server protects cells against
spreadsheet formula injection, so keep the downloaded text instead of rebuilding it. Do not log codes or exports.

## Looking up and changing codes

| Call | Does |
|---|---|
| `codes:list({ active?, batchId?, page?, size? })` | One page of this universe's codes, newest first. |
| `codes:get(id)` | One code with `timesRedeemed`, `pendingRedemptions`, `remainingGlobalRedemptions`, `redeemableNow`. |
| `codes:update(id, changes)` | Change any create field; a new `award` affects future redemptions only. |
| `codes:delete(id)` | Delete a code that has no pending grants. |
| `codes:redemptions(id, { page?, size? })` | Who redeemed it, with the frozen award and receipt. |
| `codes:exportBatch(batchId)` | CSV text for a batch. |

`id` is the numeric ID from `create`/`list`, not the code text. Admin calls return `Core.Result`; `redeem` is the only
call that returns an outcome instead. Pending intents reserve global capacity before the grant, so
`pendingRedemptions` and `remainingGlobalRedemptions` include in-flight redemptions. The health calls
(`liveness`, `readiness`, `healthProxy`, `info`, `metrics`) exist for operations tooling.
