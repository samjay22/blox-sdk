# Audit, Leaderboards and Fields

These facades share Bearer service-account/user-session authentication, admission limits,
error results, retry budget and backoff. All use `https://lb1.blox-api.com`, with prefixes
`/audit-service`, `/leaderboard-service` and `/fields-service`, respectively.
Config is retired; runtime configuration belongs to Fields, with no alias or fallback.
See the [complete prefix table and overrides](../README.md#gateway-routing).
Exact permission names: `AuditService`,
`LeaderboardService` (singular), `FieldsService`.

Use `universeId` on client construction or `withUniverse(id)`. Universe selectors must be positive
integers: numbers must be exactly representable (at most 2^53-1); canonical decimal strings support
path/query IDs up to Java's signed 64-bit maximum. DTO numeric IDs remain limited to safe Luau integers.
Audit has implied/query scope; writes fill a missing event universe from the client scope.
Leaderboards and Fields use path universes. Explicit contradictory body scope is rejected locally;
the backend is always the authorization authority. Arbitrary metadata fields are not scope selectors.

## Idempotency and retries

The SDK privately copies each logical request and generates omitted keys **before** dispatch:

- Fields transaction, reversal, restore, purchase and refund: `idempotencyKey`.
- Leaderboard submissions: `submissionId`, one per score in a batch; rating matches: `matchId`.
- Audit append/batch: `idemKey`, one per event.

The exact body/key is reused across automatic retries and eligible authorization replays. Caller
inputs are not mutated. Separate calls generate different keys. Native Roblox uses `GenerateGUID(false)`;
injected runtimes can supply `guid`, otherwise timestamp, sequence and random components are used.
Keys are not credentials. Supply/persist your own keys when replaying across calls, restarts or uncertain
failures. Fields keys are universe-wide and durable; Audit deduplication ends when retention deletes
the event. Reusing a key for a different payload is not a safe retry (Fields/Leaderboards return 409).

Only contract-declared safe/idempotent operations retry, using the existing earned budget and full-jitter
backoff. GETs with side effects remain excluded. Manual leaderboard rollover, game-value rollback and other
unkeyed mutations **never** retry automatically, including on 401. Removed `idempotencyHint`
is rejected, not ignored. Read-only POSTs in the new services are
conservatively single-attempt. A Network/Timeout result never proves that a write did not commit.

## Cursor pagination

Every cursor-bearing method has a generated `<method>Pages(request?, options?, maximum?)` helper, e.g.
`client.audit:listPages`, `client.leaderboards:ratingScopesPages`, `client.leaderboards:ratingTopPages`, and
`client.fields:ledgerPages`. Mixed requests retain their path, body and filters. No request is made until
the returned iterator is called. Each call yields a **Result containing a whole page**, then nil at the
end. Missing/null/empty `nextCursor` ends iteration; failures yield once, rather than hiding incomplete
results. Cursor cycles and the default 10,000-page bound produce a terminal Local error. These are live
keyset views, not frozen multi-request snapshots. Do not change filters or scope during iteration.

## Buffered audit

`client:auditWriter({batchSize=100, interval=5, capacity=2000})` returns an owned writer:

- `:Enqueue(event)` never yields or performs HTTP. False means invalid input, full queue or closed writer.
- `:Flush()` starts one background worker and returns immediately; batches use POST `/events/batch`.
- `:Pending()` includes unacknowledged/in-flight events. `LastError` exposes the last failed delivery.
- Each request has 1–500 events. Size/interval flushes serialize; no overlapping workers or unbounded queue.
- Failures retain the batch and its original keys for the next interval/explicit flush. A partial receipt
  does not discard events. This is an in-memory, bounded queue, **not durable delivery**; permanent bad
  events can hold up the queue and require application handling.
- `:Close(seconds)` stops admission and cooperatively waits within a finite budget, returning false if
  undelivered. `:Destroy()` stops timers/cancels observers, without undoing native in-flight requests.

Native-runtime clients register **one BindToClose callback per shared client** when the first writer is
created. It drains writers (20-second total budget), then closes the pipeline and destroys the client.
Custom runtimes must invoke `client:flush`/`destroy` themselves. Explicit `client:flush` drains writers
before pipeline admission closes. Shutdown waits yield cooperatively; normal enqueue/flush never waits
on HTTP. Avoid multiple competing shutdown callbacks; finish application saves before final SDK flush.
Do not put credentials/PII in audit metadata; backend sensitive-key validation remains authoritative.

## Fields runtime snapshot cache

`client:runtimeSnapshot(intervalSeconds?)` starts an asynchronous initial poll (default interval 30s),
then serial polls after each completion. It requests Fields `/runtime/snapshot`, reusing the exact
opaque response ETag in `If-None-Match`, never synthesizing one from a version. Raw calls accept
`fields:runtimeSnapshot({etag='"opaque-validator"'})`; the Result exposes `etag`.
A 304 has no body and retains the cached state. Errors, malformed responses and
version regressions retain the last good snapshot; `LastError` is observable. No generic TTL cache is
used for these requests.

`:Get(key)` reads a literal UNIVERSE field ID from `gameValues` and returns an immutable value or nil;
`:IsEnabled(flag)` returns the cached **master enabled
switch only**, false when missing/unloaded. It does **not** evaluate user-specific rollout percentage,
attributes or rules. Use `client.fields:evaluateFlags({body={userId=7,keys={"double_xp"}}})` or
`evaluateFlagsBatch({body={userIds={7,8}}})` for service-authoritative decisions. These read-only POSTs
are conservatively single-attempt. `fields:maintenance()` / `putMaintenance` handle independent
maintenance policy; writes require ADMIN. `flags` / `flag` read definitions; `createFlag` / `updateFlag`
require WRITE, and updates require the current version; `deleteFlag` requires ADMIN.

Game configuration is stored in UNIVERSE-scoped Fields definitions at subject 0. Use Fields transactions
for writes, `gameValueHistoryPages` to read changes, and ADMIN-only `rollbackGameValue` for an unkeyed
compensation to a prior version. It is not safe to automatically retry that rollback.

`:Version()` reports the last successful generation. `Changed:Connect(callback)` returns a connection
with `:Disconnect()`; callbacks run asynchronously on first load and each changed generation, not on
304/equal versions. Listener exceptions are isolated. `:Destroy()` stops polling and disconnects
listeners. Shared client flush/destroy stops owned caches. No polling starts merely by requiring the SDK.

`leaderboards:ratingScopesPages()` discovers persisted rating scopes without creating them;
`ratingLabel({path={scope="ranked"},body={displayName="Ranked"}})` sets an ADMIN-only display label.
These are distinct from board names and rating-match submission.

## Fields typed gameplay

See [Fields](FIELDS.md) for TypeExpr validation, schema caches, transactions, profiles, presence,
products/receipts, snapshots/outbox/reconcile, generated accessors and exactness limits.
`putDocument` does not invent a key; it retries only with an explicit key. Failed local transaction
validation performs no network call. See `examples/fields-*.luau` and [endpoint reference](ENDPOINTS.md).
