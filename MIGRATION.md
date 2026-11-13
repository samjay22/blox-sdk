# Migrating BloxSDK

## 7.0.0 to 8.0.0 — item lists

Game configs and bitmap fields became one idea: a config namespace is either Settings or an **item list** that players
hold through a Fields `bitmap` field. Nothing is renamed, so existing games keep working; the new surface is additive,
except that the config namespace responses now carry `kind` and `nextBit`.

| Before | After |
|---|---|
| A numeric bit mask in an `int` field, with your own bit-to-item table | An item list (`configs:namespace("Items"):setKind("items")`) plus a field `{ kind = "bitmap", source = "Items", maxMembers = 64 }` |
| `profile:set("Owned", bits)` and bit arithmetic in game code | `profile:grant("Owned", { "Sword" })`, `revoke`, `replace` |
| Reading the number and testing bits yourself | `profile:has("Owned", "Sword")`, `members("Owned")`, `usable("Owned", "Sword")` |
| Deleting an item from a config table and hoping nobody holds it | `items:retireMember("Sword")`, or `removeMember` (refused with `member_in_use` while held) |
| A hand-kept "single choice" value | A `bitmap` field with `maxMembers = 1` |
| 367 endpoints | 374: item list admin routes (`setKind`, usage, holders, removal check, verify, source, player members) |

New error codes: `unknown_member`, `member_retired`, `member_limit`, `member_in_use`, `holder_check_unavailable`,
`enum_source_unavailable`, `kind_immutable` and friends (see [ERRORS.md](docs/ERRORS.md)). `BloxSDK.version` is `8.0.0`.
Existing data does not need converting. Start with [ITEM-LISTS.md](docs/ITEM-LISTS.md).

## 6.0.0 to 7.0.0 — rotations simplified

Rotations are now one idea: a named list of items that take turns on a fixed clock. Tables, generators, rolls, stock and
claims are gone, with no aliases. If a game needs gacha rolls or limited stock, build it on Fields transactions.

| Before | After |
|---|---|
| Save a table, a generator and a rotation (three JSON definitions with a save reason each) | `fields:putRotation{ path = { key = "daily_shop" }, body = { items = { { id = "sword", data = { price = 100 } } }, every = "1d" } }` |
| `rotations:get(name)` -> `RotationActive` (`current.result.picks[1].payload`) | `rotations:current(name)` -> `{ items, endsAt, next }`; `items[1].data` is what the pick's `payload` was |
| `rotations:timeRemaining(instance)` | `rotations:secondsLeft(current)` |
| `rotations:watch(key, function(instance, active) ... end)` (snapshot-backed) | `rotations:watch(name, function(current) ... end)`; no `client:runtimeSnapshot` needed, the runtime snapshot no longer carries rotations |
| `rotations:getAll()` / `getStock` / `claim`, `fields:advanceRotation` / `rerollRotation` / `rotationHistory` | removed; list with `fields:listRotations`, preview with `fields:previewRotation` |
| `client.fields:generators():roll/preview/getOdds`, tables and odds, pity | removed |
| Weighted outcomes (70/25/5 weather) | removed: every item gets an equal turn, in list order or `shuffled` |
| Cadence `INTERVAL { everySeconds }` / `ENTRY_DURATION` | `every = "30m"` (`m`, `h`, `d`, `w`); every item lasts the same time |
| Error codes `rotation_definition_not_found`, `rotation_out_of_stock`, ... | `rotation_not_found`, `rotation_version_conflict`; definition problems are `invalid_definition` with a message |

`BloxSDK.version` is `7.0.0` and the SDK had 367 endpoints. Existing rotation data was empty, so nothing needed converting.

## 5.0.0 to 6.0.0 — configs split out of Fields

Game configuration moved out of Fields into `client.configs`. No aliases remain.

| Before | After |
|---|---|
| UNIVERSE field `Welcome.Text` read with `client:runtimeSnapshot(30):get("Welcome.Text")` | `client.configs:namespace("Game"):getString("WelcomeText", "")` (a namespace plus a key; any JSON value) |
| `runtimeSnapshot` for flags and maintenance | unchanged, but `snapshot:get` and `gameValues` are gone; `isEnabled`, `version`, `Changed` remain |
| writing config through a Fields transaction at `:subject(0)` | `client.configs:namespace(n):set(key, value, { expectedVersion = v })` or `:setMany{...}` (admin key) |
| `fields:gameValueHistory{ path = { fieldPath = k } }` / `gameValueHistoryPages` | `namespace:history(page?)` / `namespace:historyPages()` (per namespace version, not per field) |
| `fields:rollbackGameValue{ path = { fieldPath = k }, body = { version = v } }` | `namespace:rollback(v)` (restores a whole namespace version as a new version) |
| `definition.scope = "UNIVERSE"` / `"PLAYER"`, `scope` filter on `fields:definitions` | removed: every definition is per player; omit `scope` |
| `multiTransactionBuilder():subject(0)...`, conditions on subject 0 | removed: every op and condition needs a positive subject |
| schedule action `{ kind = "SET_CONFIG", key, type, value }` | removed; schedules enable or disable flags and run bulk jobs only (drive config from your own admin tooling) |
| `bindings.runtime.maxDeltaConfigKey`, `$config` references, `resolvedConfig`/`numericGameValue` | removed |
| error codes `game_field_not_found`, `game_version_not_found`, `scope_immutable`, `field_scope_mismatch` | `key_not_found` / `version_not_found` / `namespace_not_found` for configs; `invalid_subject` for subjects |
| no polling control for config | `configs = { pollInterval = 30, jitter = 0.2, staleAfter = 90 }` in `BloxSDK.new`, or per `namespace(name, opts)` |

Values do not migrate by themselves: recreate game values as namespace entries (for example with `setMany`) using an
ADMIN key (`levels = { ConfigService = "ADMIN" }`), keeping that key off game servers. Namespace names allow
`A-Z a-z 0-9 _ -` (up to 64 characters), keys `A-Z a-z 0-9 _ . -` (up to 100), values any non-null JSON up to 64 KiB.
`BloxSDK.version` is `6.0.0`, health covers nine services, and the batch envelope uses `op.service = "config"`, which the
batch service must accept before `client.configs` can be used in a deployment.

## 4.0.0 to 5.0.0 — codes simplified

`client.codes` is reorganized around redeeming and administering codes. No aliases remain.

| Before | After |
|---|---|
| `client.codes:redeem({ code = c, robloxUserId = player.UserId })` returning a `Result` of a receipt | `client.codes:redeem(player, c)` returning an outcome; switch on `outcome.status` |
| `if not r.ok then warn(r.error.code)` for expired, unknown or used-up codes | `outcome.status == "expired"` / `"invalid"` / `"not_started"` / `"exhausted"` |
| `r.value.replayed` | `outcome.status == "already_redeemed"` |
| `r.value.transaction.results` | `outcome.rewards` (`field`, `op`, `path`, `before`, `after`) |
| `r.error` on a timeout or outage | `outcome.status == "retry"` (`outcome.error`); call again |
| `client.fields:schemaCache():load()` then `codes:award()...:build()` then `createCode` | `codes:create({ code = c, award = codes:award()... })` |
| `createCode({ code, award, maxRedemptionsPerUser = 1, universeId })` | `create({ code, award })` |
| `bulkCreateCodes({ body = { count, name, award }, idempotencyKey = k })` | `createBatch({ count, name, award, idempotencyKey = k })` |
| `searchCodes({ query = { batchId = b, page = 0 } })` | `list({ batchId = b, page = 0 })` |
| `getCode({ path = { id = i } })` | `get(i)` |
| `updateCode({ path = { id = i }, body = changes })` | `update(i, changes)` |
| `deleteCode({ path = { id = i } })` | `delete(i)` |
| `listRedemptions({ path = { id = i }, query = page })` | `redemptions(i, page)` |
| `exportBatch({ path = { batchId = b } })` | `exportBatch(b)` |
| `liveness({})`, `readiness({})`, `healthProxy({})`, `info({})`, `metrics({})` | the same calls with no request, or just options |

`Types/Codes` no longer exports `RedeemCall`, `RedeemResultValue`, `CreateCodeCall` and the other per-route
aliases; the wire DTOs (`CodeDto`, `RedeemCodeResponse`, `BulkCreateCodesResponse`, ...) are unchanged, and the new
facade types (`Outcome`, `Reward`, `NewCode`, `NewBatch`, `CodeChanges`) are exported from `BloxSDK` as
`CodeOutcome`, `CodeReward` and `CodeAward`. Per-user limits are always one, so `maxRedemptionsPerUser` is gone.
A failed `redeem` never raises: only a value that is neither a `Player` nor a user ID does.

## 3.1.0 to 4.0.0 — one universe, stated once

Delete the universe argument from every helper call and from request bodies; the client supplies it.

| Before | After |
|---|---|
| `BloxSDK.new({ secretName = s, universeId = game.GameId })` | `BloxSDK.new({ secretName = s })` on Roblox; `universeId` is still accepted |
| `client.fields:loadProfile(game.GameId, player.UserId)` | `client.fields:loadProfile(player)` |
| `client.fields:transactionBuilder(id, userId)` | `client.fields:transactionBuilder(userId)` |
| `client.fields:schemaCache(id)`, `:rotations(id)`, `:generators(id)`, `:jobClient(id)` ... | the same call with no argument |
| `client.fields:processReceipt(id, receipt)` | `client.fields:processReceipt(receipt)` |
| `client.codes:award(id)` | `client.codes:award()` |
| `client.fields:createFlag({ path = { universeId = id }, body = flag })` | `client.fields:createFlag(flag)` |
| `joinQueue({ robloxUniverseId = tostring(game.GameId), ... })` | `joinQueue({ ... })` |

Calls with other path or query parameters keep `{ path = ..., query = ..., body = ... }`; their universe was
already optional. To work on another universe, call `client:withUniverse(id)` and use the facade it returns.
A helper called on a client that has no universe raises an error naming the fix instead of guessing.

## 3.0.0 to 3.1.0 — inbox-driven profile sync

Deploy a Fields service that serves `POST /api/fields/universes/{u}/sessions/poll` before upgrading; no
fallback exists. No code changes are needed in games. Each tick the SDK polls the server's inbox, reads
change feeds only for the players it names, and re-reads the whole roster every
`profileSync.resyncSeconds` (default 30) or after an inbox reset. External writes to a leased player
therefore still arrive within about one tick; only a lost notification waits for the next resync.

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
