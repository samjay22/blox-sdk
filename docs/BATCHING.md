# Batch-only transport (2.0)

Every operation that needs the network is queued. There is **no direct-call fallback**: all nine
facades, health checks, authentication refresh/exchange/logout, pagination, helper writes, and profile
sync use `POST {gatewayUrl}/batch-service/api/batch`. Cache hits, local validation and singleflight
followers need no new operation. Requiring or constructing the SDK sends nothing.

```luau
local client = BloxSDK.new({
    secretName = "BLOX_SERVICE_ACCOUNT",
    universeId = game.GameId,
    batch = { intervalSeconds = 0.5 }, -- minimum 0.25 seconds
})
-- Same yielding methods and Result shapes as before.
local result = client.fields:schema()
```

## Cadence, capacity and backpressure

The first queued call or registered profile arms a tick. Each tick can send **one** envelope, never
multiple split requests in a burst. Empty ticks send nothing. There is one native request in flight
per client, shared by all its facades and credential scopes. A busy tick is skipped; physical completion
does not trigger an immediate flush. Overflow waits for a later tick. Cadence is client-local, not
wall-clock synchronized across the platform.

The bounded queue defaults to 10,000 logical calls (`queueCapacity`); full admission returns
`RateLimited`. Critical calls precede bulk, then low; each lane is FIFO. A large head operation is
not bypassed to fill leftover bytes. There is no fairness promotion over sustained critical traffic.
End-to-end timeouts include admission, credential preparation, queued ticks, retries and response wait.
A deadline shorter than the next tick can expire **without any HTTP**.

Limits are measured on encoded UTF-8 JSON: at most 100 operations, 1 MiB including envelope, metadata,
commas and braces, and 256 KiB per encoded operation body. Overlarge operation bodies fail locally with
`Validation`; they are never truncated. Smaller operations are split across ticks. NDJSON import bytes
are preserved as a JSON string in `op.body`, with `Content-Type: application/x-ndjson` on that operation;
downloaded text must be returned as a JSON string. The 256 KiB limit applies after JSON escaping too.

## Wire and credentials

An operation has a unique client-local ID, service, method, internal path, optional decoded scalar query
map, body, headers and sequence. Paths contain no gateway prefix. The facade-to-service mapping is:

| Facade | `op.service` |
|---|---|
| fields | fields |
| leaderboards | leaderboard |
| codes | codes |
| matchmaking | matchmaking |
| party | party |
| audit | audit |
| platform | platform |
| auth | auth |
| configs | config |

Authorization belongs only on the **outer request**. Service-account strings and opaque Roblox Secrets
are applied as before; Secrets are never JSON encoded. Public endpoints use the root SDK credential,
without forcing a scoped-token exchange. Prepared scoped calls use that scope's credential. Different
credential providers cannot share one Authorization header, so the highest-priority FIFO provider is
selected and incompatible operations carry over. Refresh and scoped-token exchanges themselves queue
through the same batcher; no tick waits for a credential refresh while holding physical admission.
Direct-host `services` overrides are rejected; configure the gateway instead.

Per-operation idempotency and conditional headers are preserved. The entire response ID set is validated
before delivery: missing, duplicate or unknown IDs invalidate the envelope. Result order is irrelevant.
Each successful operation then passes its existing endpoint response validator. Conditional 304 and ETag
handling, machine-code mapping and error redaction are unchanged. The batch envelope's `serverTimeMs`
is validated but does not replace the injected monotonic deadline clock.

## Ordering, retries and cancellation

Player-targeted operations carry universe-qualified sequence keys. The SDK additionally holds FIFO
logical player locks through retry backoff, so a later write cannot overtake a retry or a profile read.
Multi-subject writes acquire all their player lanes atomically, avoiding cross-subject races or deadlocks;
independent players remain eligible together. The consequence is that dependent calls may need later
ticks even when the current envelope has room. Submit independent work concurrently to coalesce it;
a sequential loop necessarily waits for each preceding result.

Per-operation retryable failures re-enter a **later tick**, subject to the existing idempotency rules,
earned retry budget and original deadline. Retry-After seconds/HTTP dates are floors on 429/5xx backoff.
Unkeyed non-idempotent mutations are not replayed. Batch-level 401/403 fail every selected operation
with the appropriate auth Result (managed auth may perform its existing single safe refresh/replay).
Batch-level 400 is a malformed-batch validation failure. Whole-batch 429 also pauses all dispatch until
Retry-After/backoff **plus jitter** has elapsed; newly arriving calls cannot bypass that pause.

Queued cancellation/deadline expiry removes dispatch eligibility. In-flight cancellation stops only that
caller, not other operations in the envelope. Roblox cannot abort native HTTP: the physical slot and
signal's native-operation count remain held until completion, even after a logical timeout. Late results
are ignored by abandoned callers. Timeout/Network is never evidence that a mutation did not execute.
`flush` still closes admission and waits within its budget; it does not bypass tick spacing.

## Profile sync and HTTP budget

Each available tick appends LOW-priority changes polls for loaded profiles, grouped by credential and
universe and deduplicated by player with the minimum safe cursor. Each op contains at most 200 players.
All chunks are queued together, not separate HTTP calls. Unfinished chunks are not duplicated on the
next tick. Envelope limits, priority, credential compatibility and in-flight exclusion can defer chunks;
there cannot be an unlimited number of polls in a single envelope.

Sync response validation, complete ledger groups, per-field versions, signals and conservative snapshot
recovery remain in place. A snapshot covering an older in-flight poll cannot be re-invalidated by that
poll. `profileSync.enabled=false` disables automatic polling. With leased profiles a tick normally carries one
`sessions/poll` op per universe instead of a changes op per 200 players; full-roster changes reads run every
`profileSync.resyncSeconds` (default 30) and after an inbox reset. Poll failures back off with Retry-After;
recovery remains staggered and bounded by `maxConcurrentReloads`, with its budget threshold. Batch
cadence replaces the removed profile `intervalSeconds` option (now rejected) and server `pollAfterMs` scheduling hint.

At the default 0.5-second cadence there are **at most 120 physical requests/minute/client**, including
polls, retries, refreshes and health. At the 0.25-second minimum there are at most 240. Both are below the
specified Roblox 500/minute server budget, but multiple clients and unrelated scripts share that budget.
The shared rolling-minute limiter remains a safety net (default 450, configurable 1–480), charging **one
admission per physical batch**, not per op. Use one long-lived client and its facades. See the
[performance and limits table](PERFORMANCE.md).

## 3.0 leased commits

Session acquire/renew/release and one buffered commit share this tick. Commit bodies alone support up to 1 MiB; all envelopes still cap at 1 MiB, so the coordinator leaves headroom. At most eight physical envelopes are admitted per rolling second across native clients sharing the required module, in addition to the minute budget. See [binding contract](../API_CONTRACT.md).
