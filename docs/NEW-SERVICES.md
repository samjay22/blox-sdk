# Audit, Config, Leaderboards and Economy

All four facades share the existing Bearer service-account/user-session authentication, admission limits,
error results, retry budget and backoff. Hosts are `audit`, `config`, `leaderboards` and `economy` at
`https://<host>.blox-api.com`. Exact permission names: `AuditService`, `ConfigService`,
`LeaderboardService` (singular), `EconomyService`.

Use `universeId` on client construction or `withUniverse(id)`. Universe selectors must be positive
integers: numbers must be exactly representable (at most 2^53-1); canonical decimal strings support
path/query IDs up to Java's signed 64-bit maximum. DTO numeric IDs remain limited to safe Luau integers.
Audit has implied/query scope; writes fill a missing event universe from the client scope. Config,
Leaderboards and Economy use path universes. Explicit contradictory body scope is rejected locally;
the backend is always the authorization authority. Arbitrary metadata fields are not scope selectors.

## Idempotency and retries

The SDK privately copies each logical request and generates omitted keys **before** dispatch:

- Economy grant, spend, transfer, adjust, reverse, receipt and refund: `idempotencyKey`.
- Leaderboard submissions: `submissionId`, one per score in a batch; rating matches: `matchId`.
- Audit append/batch: `idemKey`, one per event.

The exact body/key is reused across automatic retries and eligible authorization replays. Caller
inputs are not mutated. Separate calls generate different keys. Native Roblox uses `GenerateGUID(false)`;
injected runtimes can supply `guid`, otherwise timestamp, sequence and random components are used.
Keys are not credentials. Supply/persist your own keys when replaying across calls, restarts or uncertain
failures. Economy keys are universe-wide and durable; Audit deduplication ends when retention deletes
the event. Reusing a key for a different payload is not a safe retry (Economy/Leaderboards return 409).

Only contract-declared safe/idempotent operations retry, using the existing earned budget and full-jitter
backoff. GETs with side effects remain excluded. Manual leaderboard rollover, config rollback and other
unkeyed mutations **never** retry automatically, including on 401. The legacy `idempotencyHint` option
is accepted for compatibility but no longer overrides safety. Read-only POSTs in the new services are
conservatively single-attempt. A Network/Timeout result never proves that a write did not commit.

## Cursor pagination

Every cursor-bearing method has a generated `<method>Pages(request?, options?, maximum?)` helper, e.g.
`client.audit:listPages`, `client.config:entriesPages`, `client.leaderboards:ratingTopPages`, and
`client.economy:ledgerPages`. Mixed requests retain their path, body and filters. No request is made until
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

## Config snapshot cache

`client:configSnapshot(intervalSeconds?)` starts an asynchronous initial poll (default interval 30s),
then serial polls after each completion. It requests `/snapshot` with `If-None-Match: "<version>"` after
a successful snapshot. A 304 has no body and retains the cached state. Errors, malformed responses and
version regressions retain the last good snapshot; `LastError` is observable. No generic TTL cache is
used for these requests.

`:Get(key)` returns an immutable value or nil; `:IsEnabled(flag)` returns the cached **master enabled
switch only**, false when missing/unloaded. It does **not** evaluate user-specific rollout percentage,
allow/deny lists, attributes, or schedules. Use `client.config:evaluate` / `evaluateFlag` for those
contract-defined decisions. Maintenance is independent of flag enablement.

`:Version()` reports the last successful generation. `Changed:Connect(callback)` returns a connection
with `:Disconnect()`; callbacks run asynchronously on first load and each changed generation, not on
304/equal versions. Listener exceptions are isolated. `:Destroy()` stops polling and disconnects
listeners. Shared client flush/destroy stops owned caches. No polling starts merely by requiring the SDK.

## Economy exact amounts

Amounts are integer smallest units. DTOs accept safe integral numbers or decimal strings (up to 38
digits); send strings when precision matters. Before decoding Economy JSON, unsafe integer numeric
tokens are preserved as strings, so a 38-digit ledger balance is never silently rounded by the runtime.
Unsafe exponential/fractional forms fail closed. Large response IDs that cannot satisfy their numeric
DTO schema also fail closed. Do not call `tonumber` on large balance strings or do floating-point ledger
arithmetic. Backend asset limits, positive amounts, zero-delta rejection and business rules still apply.

See `examples/audit.luau`, `config.luau`, `leaderboards.luau`, `economy.luau`, exported `src/Types/*`,
and the generated [endpoint reference](ENDPOINTS.md) for exact method names and request shapes.
