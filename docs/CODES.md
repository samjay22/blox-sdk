# Codes: Fields operation awards

**lb1 callers need `Gateway` plus `CodeService` and downstream `FieldsService` permissions.
`bsa_` keys are bound to one universe.** Code administration requires ADMIN; redemption requires
CodeService READ_WRITE and the Fields permissions needed to write each awarded field.

`award` is an ordered list of 1–100 **subject-free Fields operations** (`Fields.PlayerOperation`).
The builder is handwritten in `src/Codes/Award.luau` and composes `src/Fields/OpBuilder.luau`;
its operation constructor and TypeSystem are shared with Fields transactions. Generated route
facades delegate to it without duplicating operation semantics.

```luau
local loaded = client.fields:schemaCache(123):load()
if not loaded.ok then return end
local award = client.codes:award(123)
    :add("Currency.Gems", 100)
    :mapAdd("Inventory.Items", "SWORD", 1)
local checked = award:validate() -- Local preflight, then Fields /ops/validate if locally valid.
if not checked.ok or not checked.value.valid then return end
local built = award:build() -- Canonical private snapshot; never commits a transaction.
if not built.ok then return end
local created = client.codes:createCode({
    universeId = 123,
    code = "WELCOME100",
    award = built.value,
    maxRedemptionsPerUser = 1,
})
```

Load the universe schema explicitly before building or creating; unloaded caches return
`schema_unavailable` without an implicit request. `createCode` pre-validates even raw typed award
lists, not just builder output. `updateCode` pre-validates supplied replacement awards using the
scoped client's loaded schema; human tools should use `client:scoped(id)` for that call.
Build failures expose the first diagnostic. Use `:validate()` to collect all failing operations.
Builder methods use the same capitalized names as transaction methods; `:build()` and `:validate()`
are lower-case. There is no subject setter or commit method on an award builder.

Every backend create/update (including metadata-only edits) also validates the effective award
through Fields `/ops/validate` with the caller's bearer. Invalid awards return 422 and all diagnostics;
validation outages fail closed with 503. Local cached-schema validation does not replace that check.

## Bulk generation and batches

`client.codes:bulkCreateCodes({body=..., idempotencyKey=...})` wraps ADMIN
`POST /api/codes/bulk`. Keep this in trusted administrator tooling, never a player-controlled
request. Use the same loaded schema and typed `award` builder as single create. The SDK preflights
the award once; the backend validates it once through Fields and creates the entire batch in one
transaction (all or nothing). Generation itself grants nothing to players.

```luau
-- Load Schema(123) and build the award as above before this request.
local batch = client.codes:bulkCreateCodes({
    idempotencyKey = "summer-2026-batch-001", -- Persist a unique key for this logical batch.
    body = {
        universeId = 123,
        count = 100,
        prefix = "SUMMER",
        length = 10,
        name = "Summer campaign",
        award = built.value,
        maxGlobalRedemptions = 1,
        active = true,
        metadata = { campaign = "summer-2026" },
    },
})
if batch.ok then
    local batchId = batch.value.batchId
    local page = client.codes:searchCodes({ query = { batchId = batchId, page = 0, size = 100 } })
    local csv = client.codes:exportBatch({ path = { batchId = batchId } })
    -- csv.value is raw CSV text on success, not JSON or a download URL. Store it securely.
end
```

Required body fields: `universeId`, `count` (integer 1–1000), nonblank `name`, and `award` (1–100
subject-free typed operations). `prefix`, `length` (integer 8–16, default 10), `description`,
`maxGlobalRedemptions`, `startsAt`, `expiresAt`, `active`, and object `metadata` are optional.
`length` is the random suffix length, excluding the prefix and separator. The server uses SecureRandom,
uppercase unambiguous characters (no `0/O/1/I/L`), and retries uniqueness collisions; e.g.
`SUMMER-K7M2XQ9PDA`. `maxGlobalRedemptions` applies to **each code**, not the whole batch;
per-player redemption remains once per code. Do not send single-create `code` or
`maxRedemptionsPerUser` fields in this DTO.

201 returns `{batchId="uuid", count=N, codes={{id=...,code="..."},...}}`, not full CodeDto items.
The top-level optional `idempotencyKey` becomes the `Idempotency-Key` header, never a JSON body field.
Persist the key and original request before sending. After a lost reply, explicitly repeat the same
request with the same key to retrieve the original response; changing keys can create another batch.
No key is generated for you, and bulk mutations are not automatically retried, even with a key.
Without a key, do not blindly repeat an uncertain creation.

`searchCodes` supports `query.batchId` alongside its existing universe/active/pagination filters
(`GET /api/codes?batchId=...`). `CodeDto.batchId` is optional/nullable for older or single-created codes.
`exportBatch` uses ADMIN `GET /api/codes/batches/{batchId}/export` with `Accept: text/csv` and returns
the original text. Columns are `code,name,universeId,expiresAt,maxGlobalRedemptions`. The server escapes
CSV and protects cells against spreadsheet formula injection; preserve the downloaded text rather
than rebuilding unsafe CSV from names/metadata. Treat codes and exports as redeemable campaign assets:
do not log them or expose the ADMIN credential. There is no separate batch-list endpoint.

## Redemption and recovery

```luau
local result = client.codes:redeem({universeId=123, code="WELCOME100", robloxUserId=7})
if result.ok then
    local transaction = result.value.transaction
    -- transaction.txId, .results (ordered touched subvalues), .seq (allocation tokens, NOT cursors), .replayed
    -- result.value.replayed and .redeemedAt describe the CodeService redemption.
end
```

The backend applies the entire award as **one atomic Fields transaction**, permanently deduplicated
by `code-<codeId>-<userId>`. There is no caller-supplied grant identity. `maxRedemptionsPerUser`
defaults to 1 and must equal 1; the SDK rejects other supplied values before HTTP.
Retry the same code/player after uncertainty, never create another grant identity. The SDK keeps
redemption POSTs non-automatically-retryable; the backend owns its bounded downstream retries.

Pending intents reserve global capacity before HTTP and retain the original operation list through
crashes, expiry and edits. Successful pairs replay their original receipt. `pendingRedemptions`
and `remainingGlobalRedemptions` describe this reservation accounting. Award changes affect future
admissions, not pending grants. A conflict is not proof of success. `grantPending=true` in a safe error
means the backend retained an uncertain reservation; reconcile or retry, do not force a second grant.

`transaction` is a typed receipt, not a player document. `before`/`after` are touched subvalues;
explicit null and nullable `entryId` are preserved as `BloxSDK.null`. Top-level `replayed` can differ
from the stored transaction's flag. Redemption history includes the frozen award and transaction.
Errors retain only allowlisted machine codes and bounded diagnostics, not raw backend messages.

Static validation does not check current balances, collection lengths/membership, field write
authority or runtime policies. It reserves nothing; Fields revalidates actual state at redemption.
