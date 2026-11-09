# Migrating BloxSDK

## 2.0.0 to 3.0.0 — leased profiles and optimistic writes

Deploy the exact session/commit protocol in [API_CONTRACT.md](API_CONTRACT.md) before upgrading; no fallback exists.
`loadProfile` requires READ_WRITE and now waits for batched acquire + snapshot, not a plain document GET.
Native clients load joining players automatically and share concurrent loads/one handle per player.
Use `profile:add/set/mutate` for optimistic buffered gameplay writes (default durability interval 5 s).
Replace `profile:transaction()` with `profile:immediate()` for synchronous critical transactions; direct
transactionBuilder, purchase/redemption/roll endpoints remain synchronous and unchanged. Update callers,
not aliases. Never authorize purchases from optimistic values. `LeaseLost` and `CommitRejected` expose
failures; kicks default on and are configurable through `sessions`. Manual `profile:release()` now drains
buffers and releases the fenced lease. Call `client:flush(timeout)` before destroy; false means durability
or release remains unconfirmed. PlayerRemoving and native BindToClose do this automatically.

Ordinary bodies remain 256 KiB; commit bodies support 1 MiB (the coordinator leaves envelope headroom).
The physical HTTP budget additionally caps any rolling second at eight; `requestsPerMinute` maximum is
480, default 450. Update injected runtimes/mocks to provide exact acquire/renew/commit/release responses,
including snapshot `fields` (not document `data`), epochs, ordered IDs and ISO expiration timestamps.

## 1.2.0 to 2.0.0 — batch-only transport, public calls unchanged

All SDK network traffic now uses `POST {gatewayUrl}/batch-service/api/batch`. Deploy a compatible
BatchService before upgrading. There is no compatibility shim, direct-call fallback or automatic retry
to a service host. Existing yielding method signatures and Result shapes are unchanged.

- Configure `batch = { intervalSeconds = 0.5 }` (minimum 0.25). Queued calls add up to a tick of latency,
  plus overflow/in-flight/backoff waits. Concurrent independent calls coalesce; sequential loops do not.
- Every envelope is limited to 100 ops / 1 MiB, each encoded op body to 256 KiB. Larger payloads now fail
  locally, including previously allowed large NDJSON imports; partition them explicitly. NDJSON is carried
  as an exact string in `op.body`; text responses must be JSON strings in the batch result.
- Replace direct `services.*.baseUrl` overrides with a BatchService gateway. Direct overrides are rejected.
  Custom backends must accept only the batch endpoint and return the new results envelope, not raw
  endpoint responses. Test fixtures must model per-operation IDs/status/headers/body.
- Profile polls piggyback every available tick in chunks ≤200 players/op. Batch cadence replaces the old
  `profileSync.intervalSeconds` (now rejected) / server `pollAfterMs` schedule. Use `batch.intervalSeconds`; sync apply, signals and recovery stay intact.
- Budgets count physical envelopes, not logical operations: default ≤120/min/client, minimum interval
  ≤240/min; rolling safety cap remains 450/min. All facades share one native in-flight slot; `concurrency`
  cannot increase it. Default logical queue capacity is now 10,000 instead of 64.
- Timeouts include tick/queue waits. Cancellation before dispatch sends nothing; in-flight cancellation
  cannot abort the shared native HTTP request. Player ordering remains held across retry backoff.
- Health queues eight ops together. Authorization is applied on the outer envelope, including public ops;
  distinct credential scopes use different envelopes with no serialized credentials in op bodies.

See the batching and performance guides for detailed limits, ordering and the platform sizing target.

## 1.0.0 to 1.1.0 — behavior change, no API break

Fields locks are now per `(player, field)`. `subject_seq` is removed; mutation `seq` values are sparse
database-wide allocation tokens, not complete player watermarks. Different fields may commit/arrive
out of order. Profile acknowledgement application now uses per-field versions and never advances
`profile.seq`; older or duplicate field results never regress the cache. No API names, aliases or shims
are added or removed in 1.1.0.

Keep `sinceSeq` only from complete snapshots/documents or feeds, and paginate with `nextSinceSeq`, not
`latestSeq` on partial pages. Use the complete snapshot's watermark for `expectedSeq`, never a purchase,
refund, transaction, reversal, roll or claim token. Refresh before a document save incorporating local
acknowledgements. Existing persisted snapshot/feed cursors remain valid. Sparse token gaps alone no
longer make profiles stale; missing versions, schema changes and incomplete path state still require
`pullChanges()` (feed drain then snapshot). Profile sync reads bypass older cached/coalesced responses.
See [Fields guide](docs/FIELDS.md#allocation-tokens-versus-sync-watermarks-110).

## 0.x to 1.0.0

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
