# Migrating BloxSDK 0.x to 1.0.0

This is a breaking cleanup with **no aliases or compatibility shims**. Update code and generated accessors together.

| 0.x | 1.0 |
|---|---|
| Fields:Schema(id) | fields:schemaCache(id) (wire fields:schema() is unchanged) |
| Fields:Transaction(id,user) | fields:transactionBuilder(id,user) |
| Fields:MultiTransaction(id) | fields:multiTransactionBuilder(id) |
| Fields:Bulk / Schedules / Jobs / Health | fields:bulkBuilder / scheduleClient / jobClient / healthClient |
| Fields:LoadProfile / ProcessReceipt | fields:loadProfile / processReceipt |
| Fields:Rotations / Generators / Operations, Codes:Award | fields:rotations / generators / operations, codes:award |
| profile:Get / Transaction / Refresh / Destroy | profile:get / transaction / refresh / destroy |
| builder:Set / Add / Reason / Key / Commit | builder:set / add / reason / key / commit |
| transaction:Validate() | transaction:validateLocal(); validate() remains the backend operation-only dry run |
| Changed:Connect / connection:Disconnect / LastError | changed:connect / connection:disconnect / lastError |
| Profile.Seq / Versions, Bulk.Ops | profile.seq / versions, bulk.ops |
| SDK.Auth factories | SDK.serviceAccount / userSession / memoryTokenStore |
| SDK.endpoints / Testing / Fields.TypeSystem | Removed; no internal module tables on the root |

All remaining SDK helper methods lower their initial letter. DTO field names, enum values and native Roblox
methods keep their wire/engine spelling. Regenerate static field accessors with tools/gen-field-types.
Use `Types/*` and `Fields/Types` for public wire/domain types; root exports Client, Config, Result, BloxError,
all facade client types and common helper handles. Underscore properties are unsupported private state.

CallOptions now accepts timeout (relative seconds) and idempotencyKey (single-key endpoints, mapped to the
service's wire key). The earlier deadline/relative timeout wins. Conflicting option/body keys and unsupported
key options fail before HTTP. Batch items still need individual keys. Existing wire key fields remain
canonical endpoint contracts, not compatibility shims. Unknown/removed options are rejected.

Every error now has a code: recognized backend machine codes are normalized to lowercase snake_case, otherwise sdk_<lowercase kind>.
Switch on error.kind for cross-service categories. Never parse message text. Raw bodies and exceptions remain redacted.
requestsPerMinute is an integer 1–499. The shared rolling-minute cap includes bursts and retries; queue-full
returns sdk_rate_limited, and time waiting for capacity counts toward the end-to-end timeout.

Requiring on a Roblox client fails immediately, including with custom adapters. Keep the package in ServerStorage
or ServerScriptService; configure secretName for HttpService:GetSecret or supply explicit trusted config. Do not
store keys or modules in ReplicatedStorage. Review [limits](docs/PERFORMANCE.md) before changing defaults.

For earlier 0.x tenant-auth/routing/data migrations, see [historical details](docs/MIGRATION.md).
