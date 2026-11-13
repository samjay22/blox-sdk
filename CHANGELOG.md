# BloxSDK changelog

## 8.0.0 (local, not published)

- Item lists: game configs and Fields bitmap fields are one concept. A config namespace is Settings or an item list of
  named members (`{ bit, label?, description?, meta?, retired? }`, bits assigned by the server, permanent, never reused,
  at most 512). Fields gets the `bitmap` field kind (`{ kind, source, maxMembers }`) with `GRANT`, `REVOKE`, `REPLACE`.
- Profiles and transactions: `grant`, `revoke`, `replace`, `has`, `members`, `usable`. Buffered and saved like every
  profile mutation; grant and revoke are idempotent and order-safe. Checked locally against the cached list when it has
  loaded (fail-closed `enum_source_unavailable`), with a server fallback for reads.
- `client.configs` handle: `kind`, `members`, `activeMembers`, `member`, `addMember`, `updateMember`, `retireMember`,
  `unretireMember`, `removeMember`, `setKind`, `usage`, `holders`. `member_in_use` carries the holders.
- New error codes (`unknown_member`, `member_retired`, `member_limit`, `member_in_use`, `holder_check_unavailable`, ...).
- 374 endpoints (7 new), regenerated Roblox projection, [ITEM-LISTS.md](docs/ITEM-LISTS.md), equipment, event items and admin examples.
- See [migration](MIGRATION.md).

## 7.1.0 (local, not published)

- API keys can be restricted to field prefixes or config namespaces and given per-key rate limits (set in the portal). The SDK
  now recognises the two new backend codes: `scope_denied` (403, kind `Forbidden`; the key may not use that field, namespace or
  route; not retried, fix the key's scope) and `key_rate_limited` (429, kind `RateLimited`; the key's own per-second or daily
  limit). Both appear as `error.code`, and per-operation in batch diagnostics. 429 responses keep `error.retryAfterSeconds`
  from `Retry-After`, and idempotent calls are already retried after that delay within the deadline; a daily limit can have a
  long `retryAfterSeconds`, so treat it as "stop for now" rather than retrying in a loop.
- Additive; no API changes. See [errors](docs/ERRORS.md).

## 7.0.0 (local, not published)

- Breaking: rotations are rewritten around the task. A rotation is a named list of items that take turns on a fixed
  clock (`items`, `every`, optional `show`, `order`, `startsAt`); the game reads it with
  `client.fields:rotations():current(name)`, which returns the active `items`, `endsAt` (Unix seconds), `version` and the
  `next` period. Reads are cached until the period ends (at most 60 s), `secondsLeft`, `upcoming(name, count?)` and
  `watch(name, callback)` complete the helper; saving is `fields:putRotation`.
- Removed: random tables, generators (`client.fields:generators()`), rolls, odds, simulation, pity, costs and grants,
  stock and `claim`, `advance`/`reroll`/`applyNow`, instances and their history, `getAll`, `getStock`, `timeRemaining`, the
  `rotations` member of the runtime snapshot (and `snapshot:getRotations`), the Fields `rotation.started` event, the
  `randomness` player-export section and fourteen `rotation_*` error codes. Only `rotation_not_found` and
  `rotation_version_conflict` remain.
- 367 endpoints (the 31 rotation/generator/table routes became 7), regenerated Roblox projection, docs
  ([ROTATIONS.md](docs/ROTATIONS.md)), examples (weather, daily-shop) and tests.
- See [migration](MIGRATION.md).
- Docs: [getting started](docs/GETTING-STARTED.md), [feature guide](docs/CHOOSING.md), [recipes](docs/RECIPES.md), [FAQ](docs/FAQ.md), [troubleshooting](docs/TROUBLESHOOTING.md), [glossary](docs/GLOSSARY.md), an architecture overview, an expanded [leaderboards guide](docs/LEADERBOARDS.md) and three runnable examples (daily reward, currency shop, live tuning).

## 6.0.0 (local, not published)

- Breaking: dynamic game configuration is its own service, `client.configs`, backed by ConfigService. A namespace is
  a named group of JSON values under the client's universe (never passed per call): `client.configs:namespace("Shop")`
  returns a handle with instant cached reads `get(key, default?)`, `getString`, `getNumber`, `getBoolean`, `has`,
  `keys`, `snapshot`, plus `version`, `isReady`, `waitReady`, `lastRefreshedAt`, `isStale`, `lastError` and a `Changed`
  signal carrying the new version and changed keys.
- The cache is refreshed by one jittered, ETag-conditional poller per namespace (default 30 s, `configs = { pollInterval,
  jitter, staleAfter }`); a failed refresh keeps the last good snapshot. `client:destroy()`/`flush()` stop every poller.
- Admin calls on the handle: `set`, `setMany` (atomic), `delete`, `info`, `entries`, `entry`, `history`, `at`, `rollback`,
  and `client.configs:namespaces()`. Per-key and namespace `expectedVersion` guards; ConfigService error codes
  `namespace_not_found`, `key_not_found`, `version_not_found`, `version_conflict`, `validation_failed`,
  `limit_exceeded` are preserved.
- Breaking: Fields no longer has universe-scoped values. Removed: UNIVERSE scope and `scope` on definitions,
  `fields:gameValueHistory`/`rollbackGameValue`, `gameValues` in the runtime snapshot (and `snapshot:get`), subject `0`,
  the `SET_CONFIG` schedule action, `maxDeltaConfigKey` bindings, `resolvedConfig`/`numericGameValue` and the
  `game_field_not_found`, `game_version_not_found`, `scope_immutable` and `field_scope_mismatch` codes.
- Health reports nine services; `ServiceLevels` gains `ConfigService`. The batch `op.service` for configs is `config`.
- 391 endpoints (14 new `config.*`), regenerated Roblox projection, docs ([CONFIGS.md](docs/CONFIGS.md)), examples and tests.
- See [migration](MIGRATION.md).

## 5.0.0 (local, not published)

- Breaking: `client.codes` is rewritten around the task. Redeeming is `client.codes:redeem(player, code)`, which
  takes a `Player` or user ID and returns one typed outcome instead of a `Result` of the raw receipt:
  `granted`, `already_redeemed`, `invalid`, `expired`, `not_started`, `exhausted`, `retry` or `failed`. A game
  switches on `outcome.status`; only `retry` and `failed` carry an `error`. `granted` and `already_redeemed`
  carry `rewards` (the touched fields with `before`/`after`).
- Breaking: administration is `create`, `createBatch`, `list`, `get`, `update`, `delete`, `redemptions` and
  `exportBatch`, replacing `createCode`, `bulkCreateCodes`, `searchCodes`, `getCode`, `updateCode`,
  `deleteCode`, `listRedemptions` and the `{ path, query, body }` request envelopes. IDs and the batch ID are
  plain arguments. The health calls take only options.
- `award` on `create`, `createBatch` and `update` accepts a `codes:award()` builder or an operation list. The
  schema now loads on first use, so the load/build/validate sequence before create is gone.
- Removed redundant parameters: `universeId` (the client's), `maxRedemptionsPerUser` (always 1) and the
  `Types/Codes` request/result aliases such as `RedeemCall` and `CreateCodeCall`. Wire DTOs remain.
- CodeService refusals are now machine codes: `code_expired`, `code_not_started`, `code_exhausted` and
  `code_inactive` (mapped from the service's fixed 409 texts; no other backend text is copied).
- `src/Services/Codes.luau` is hand-written; `tools/gen.py` still generates its wire types and endpoint
  metadata, and `tools/check-coverage` verifies every CodeService route is reachable.

## 4.0.0 (local, not published)

- Breaking: the universe is stated once, in `BloxSDK.new`. On Roblox it defaults to `game.GameId`, so
  `BloxSDK.new({ secretName = "..." })` is a complete setup. No helper takes a universe argument any more:
  `loadProfile(user)`, `transactionBuilder(user)`, `multiTransactionBuilder()`, `schemaCache()`,
  `processReceipt(receipt)`, `bulkBuilder()`, `scheduleClient()`, `jobClient()`, `healthClient()`,
  `rotations()`, `generators()`, `operations()` and `codes:award()`.
- Breaking: a call whose path names only the universe takes its body directly, like every other body-only
  call: `client.fields:createFlag({ ... })`, not `{ path = { universeId = id }, body = { ... } }`. This
  applies to 40 endpoints outside Auth.
- Request bodies that carry a universe (`robloxUniverseId` in Matchmaking, `universeId` in Codes, Audit,
  Platform events) are filled from the client when omitted; those fields are now optional in the types.
- `loadProfile` and `transactionBuilder` accept a user ID or anything with `UserId`, such as a `Player`.
- `client:withUniverse(id)` remains the one way to address a different universe. Auth endpoints are
  unchanged because the universe is their subject, not their scope. No aliases for the old signatures.

## 3.1.0 (local, not published)

- Profile sync now polls a per-server inbox: each batch tick sends one `sessions/poll` for the server and
  reads change feeds only for the players the inbox names, instead of polling every loaded player every tick.
- Safety net: every leased player is still re-read on a jittered `profileSync.resyncSeconds` interval
  (default 30, range 5..300) and immediately after an inbox reset, so a missed notification self-heals.
- Players loaded without a lease keep the previous every-tick change poll. No public API removed.
- Requires a Fields service that serves `POST /api/fields/universes/{u}/sessions/poll`; no fallback exists.
- 379 endpoints; adds `Fields.pollSessions` with `PollInput` / `PollResponse` types.

## 3.0.0 (local, not published)

- Breaking leased-profile lifecycle: batched acquire/snapshot readiness, held/steal backoff, expiry renewal, flush-then-release on leave and shutdown.
- Optimistic `Profile.add/set/mutate` with bounded, coalesced per-player buffers; default 5-second commits on the existing 0.5-second batch, immutable `JobId:counter` retries, one physical commit in flight per server VM.
- `Profile.immediate()` replaces `Profile.transaction()` for synchronous critical builders; purchases, codes, trades and rolls retain immediate transaction semantics. No alias or wire shim.
- `LeaseLost` / `CommitRejected` signals, configurable kicks, conservative versioned snapshot rebasing, native PlayerAdded integration and shared concurrent loads.
- Exact scale-contract DTOs, endpoint typings, 1-MiB commit-body support, rolling-second HTTP ceiling (8/s), docs, offline Lune regressions and opt-in acquire/commit/release smoke coverage. No publish/deploy or live verification claimed.

## 2.0.0 (local, not published)

- **Breaking transport behavior; public method/Result API unchanged:** all requests use BatchService;
  no direct-call fallback or service-host overrides. Configurable 0.5s ticks (minimum 0.25), max 100 ops,
  1 MiB envelopes / 256 KiB bodies, bounded priority FIFO queue, one native batch in flight per client.
- Profile change polls piggyback loaded profiles in ≤200-player ops. Existing cursor/version application,
  notifications and snapshot recovery are retained, including fencing polls covered by a newer snapshot.
- Preserve endpoint validation, idempotency, ETags, per-op errors/retries, enqueue deadlines and cancellation.
  Player and multi-subject logical ordering spans retries; whole-batch 429 pauses dispatch with jitter.
- Charge the rolling limiter per physical envelope; default cadence costs at most 120/min/client.
  Health coalesces all services; the live-smoke runner uses batch transport and keeps Lune header normalization.
- Add fake-clock batch protocol, limit, routing, priority, auth, retry, in-flight and lifecycle regressions;
  document batching, migration, performance limits and platform-wide 10k/s sizing without benchmark claims.

## 1.2.0 — 2026-11-08 (unpublished)

- Add automatic per-client loaded-profile batch synchronization, chunked at 200 distinct players.
- Apply complete ledger groups by per-field version and advance only safe `nextSinceSeq` cursors;
  recover NONE-history, hash-only, erased/restored/replaced and schema-migration state via bounded,
  staggered, deduplicated snapshot reloads with in-flight read fencing.
- Add `Profile.Changed`, `client.ProfileChanged`, explicit `profile:release()`, immediate registry
  cleanup on release/player leave, and cancellation on flush/destroy/native BindToClose.
- Add a LOW limiter lane, rolling-minute budget threshold, server poll hints, jitter, fast `hasMore`
  drains, and exponential Retry-After-aware backoff without concurrent physical batch requests.
- Document live-sync configuration, request budgets and leaderstats notifications. Batch support is
  based on the shared contract; deployed backend support and native Roblox behavior are not live-certified.

## 1.1.0 — 2026-11-08 (unpublished)

- Behavior change, no API break: reconcile Fields acknowledgements by per-field version; concurrent
  disjoint-field results converge out of order without regressing cached values or versions.
- Treat mutation `seq` values (including purchase/refund/reversal/roll/claim) as sparse database-wide
  allocation tokens, never sync cursors. Profile watermarks advance only from complete documents.
- Retain feed drain via `nextSinceSeq` then snapshot recovery for real version/schema gaps, partial-path
  state, NONE history and computed/hash-only changes. Bypass cached/coalesced older sync reads.
- Add portable golden vectors and regressions for sparse tokens, same-field ordering, repeated paths,
  snapshot races, actual gap recovery and cache isolation. Update Fields and migration guidance.

## 1.0.0 — 2026-11-08 (unpublished)

- Stabilize all 372 typed routes and lowerCamelCase gameplay helpers; remove internal root exports with no shims.
- Export public client/helper/result/error types; require stable error codes and shared timeout/idempotency options.
- Enforce a bounded rolling-minute limiter below Roblox's 500-request ceiling, including bursts and retries.
- Add metadata-only pluggable logging and reject client-side require/custom-adapter bypasses.
- Retain deadline-aware jitter retries/Retry-After, bounded queues, circuit breakers and ETag snapshot polling.
- Generate checked-in source API references with a CI drift gate; add feature, error, limits and 0.x migration guides.
- Add 16 opt-in, type-checked native Roblox server scripts and an explicitly authorized Lune net live smoke runner.
- This checkout is not published; offline verification is not a real-gateway/Studio certification.

## 0.3.0 — 2026-11-08 (unpublished)

- Add all 31 Fields Rotations/Generators/Tables routes (372 total) and strict game-server result types.
- Add `Rotations:Get/GetAll/Watch/TimeRemaining/GetStock/Claim` and `Generators:Roll/Preview/GetOdds`.
- Share ETag snapshot polling with rotation watches, including head-only ETag updates at the same config version; otherwise schedule one end-edge refresh with jitter, never a busy poll.
- Generate mutation idempotency keys once per logical call and preserve permanent replay bodies and redacted sold-out/expired conflicts.
- Add weather, pack-store and card-pack server examples, wire goldens and fake-clock/lifecycle/retry tests. Preserve the unpublished 0.2.0 coverage work.

## 0.2.0 — 2026-11-07 (unpublished)

- Audit current service sources; inventory all 341 SDK routes in SDK_COVERAGE.md, with explicit access,
  operational exclusions, unavailable requested Party sources, and deferred Fields Rotations.
- Remove retired Config routes/client/types and speculative Platform LiveOps/environment/flag/exposure
  and Matchmaking environment APIs. No compatibility aliases or automatic redirects.
- Add Fields runtime snapshots with opaque ETags/304 polling, flags/evaluation, maintenance, game-value
  history/rollback, recurring schedule definitions and run history; rating-scope discovery/labels;
  Auth owner/member/key lookup; current Platform plan CRUD, limit resets and probes.
- Refresh source-backed Platform DTOs/paths/statuses, webhook and metering bodies, analytics queries,
  Fields environments/player administration and privacy erasure, Auth member nullability and required
  key-rotation body. Fractional plan prices accept numbers or decimal strings.
- Honor Retry-After on 429 and every 5xx, preserving stable keyed retries and finite deadlines. Remove
  idempotencyHint; reject unknown options/request fields. Preserve null/array identity and reject unsafe
  integer tokens for every JSON service. Keep Result success/error conventions unchanged.
- Accept Codes' nonblank freeform idempotency header keys with exact UTF-16 length/control checks,
  without weakening the narrower Fields key grammar.
- Add independent wire golden vectors and transport/contract regressions; regenerate portable and
  Roblox packages, endpoint references, migration guidance and examples.

Offline checks do not certify deployment, native Roblox networking, external webhook delivery or Party
unavailable. No registry publication, deployment or commit is part of this version.

See [historical changes](docs/CHANGELOG.md).
