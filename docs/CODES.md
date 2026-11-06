# Codes: Fields operation awards

**lb1 callers need `Gateway` plus `CodeService` and downstream `FieldsService` permissions.
`bsa_` keys are bound to one universe.** Code administration requires ADMIN; redemption requires
CodeService READ_WRITE and the Fields permissions needed to write each awarded field.

`award` is an ordered list of 1–100 **subject-free Fields operations** (`Fields.PlayerOperation`).
The builder is handwritten in `src/Codes/Award.luau` and composes `src/Fields/OpBuilder.luau`;
its operation constructor and TypeSystem are shared with Fields transactions. Generated route
facades delegate to it without duplicating operation semantics.

```luau
local loaded = client.fields:Schema(123):Load()
if not loaded.ok then return end
local award = client.codes:Award(123)
    :Add("Currency.Gems", 100)
    :MapAdd("Inventory.Items", "SWORD", 1)
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
scoped client's loaded schema; global administrators should use `withUniverse(id)` for that call.
Build failures expose the first diagnostic. Use `:validate()` to collect all failing operations.
Builder methods use the same capitalized names as transaction methods; `:build()` and `:validate()`
are lower-case. There is no subject setter or commit method on an award builder.

Every backend create/update (including metadata-only edits) also validates the effective award
through Fields `/ops/validate` with the caller's bearer. Invalid awards return 422 and all diagnostics;
validation outages fail closed with 503. Local cached-schema validation does not replace that check.

## Redemption and recovery

```luau
local result = client.codes:redeem({universeId=123, code="WELCOME100", robloxUserId=7})
if result.ok then
    local transaction = result.value.transaction
    -- transaction.txId, .results (ordered touched subvalues), .seq, .replayed
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
