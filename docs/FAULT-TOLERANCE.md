# Fault tolerance

## Retry policy

Only explicitly retryable, idempotent endpoints retry by default. Safe GET/HEAD reads qualify. Matchmaking validation and bulk status POSTs are explicitly read-only and qualify. PUT/DELETE methods are not assumed repeat-safe solely because HTTP defines them as idempotent: backend side effects and return semantics matter. Keyed Fields, leaderboard score/rating and Audit mutations generate stable keys per logical call and qualify. All other mutations have **no automatic retry**.

NDJSON import is an explicit exception to automatic key generation: apply (`dryRun=false`) requires a
caller-supplied `Idempotency-Key`, binding the exact UTF-8 bytes and reason across retries. Missing keys
fail locally; the SDK never generates a replacement. Import dry runs (including omitted `dryRun`, which
defaults true) are read-only and retry-eligible without a key. Both remain subject to retry budgets and
deadlines. The batch op carries NDJSON as a JSON string; its decoded bytes are unchanged. The 256 KiB encoded-body limit applies.

Eligible transient failures are Network, Server (5xx), and RateLimited. Eligible safe/idempotent calls receiving Unauthorized get one strategy-mediated replay, separately from transient retry accounting. Forbidden/validation/conflict/not-found/cancellation/deadline errors do not retry. A successful mutation with a lost response may already have executed; never interpret a Network/Timeout result as proof that it did not.

Full jitter: `random[0,1] * min(8, 0.25 * 2^(retryIndex-1))`. Delta seconds and IMF-fixdate `Retry-After` are supported on 429 and all 5xx. The larger of jitter and server delay is used, bounded by the original deadline. Sleeps are interruptible. No hedged reads.

Each actually dispatched original logical request earns `retryRatio` credits (default 0.2), up to 10. Retries spend one credit and never replenish it. There are no initial credits, so a fresh client can fail fast on its first transient error. Cache hits, coalesced followers and rejected queue submissions cannot mint retries. Authorization refresh/replay is accounted separately. `retry` reduces/increases the configured per-call maximum up to 10, but does not bypass safety or budget. Removed `idempotencyHint` and unknown options fail locally.

## Admission and circuits

The batcher has stable critical/bulk/low FIFO lanes and bounded logical admission. It sends at most
100 operations / 1 MiB per tick, with one native envelope in flight; overflow waits for another tick.
Logical player-order locks span retries; multi-subject writes share all affected lanes. Priority never
overtakes a dependent predecessor. The rolling limiter charges one physical envelope. Whole-batch
429 pauses every operation's dispatch with Retry-After/backoff plus jitter. Batch 401/403 fail every
selected op; endpoint-specific schemas and retries remain per op. See [batching](BATCHING.md).

Breakers share the gateway origin. They inspect the last 20 logical outcomes within 30 seconds; five
Network/Timeout/Server failures open for 10 seconds. Half-open probes and generation fencing retain
the existing behavior. Auth/validation/rate errors are not outage samples. There are no direct-host
exceptions or fallback requests. Default-runtime clients share the first client's rolling limiter;
unrelated scripts and duplicated ModuleScripts remain outside its measurements.

## Deadlines and native HTTP

`deadline` is an **absolute `runtime.now()`/`os.clock()` timestamp**, covering queue wait, rate wait, refresh wait, transport, retry sleep, and replay. `timeout` sets the default relative budget. Set `signal.cancelled=true` to stop a caller.

Roblox `RequestAsync` cannot abort native HTTP. Cancellation/expiry returns to the individual caller
and drops its late result, while the batcher retains the single physical slot and signal native counts
until completion. Other operations in the same envelope are not cancelled. Before dispatch, cancelled
or expired entries are ineligible. There are no per-call native workers or timeout-triggered fallback
requests. At most one native request per client can remain outstanding, even through destroy.

`Jobs:waitFor` requires a positive timeout (default 60 seconds, maximum 3600), covering HTTP and bounded
poll sleeps with one deadline. It disables caching, never retries a mutation, and returns FAILED/CANCELLED
receipts as successful transport Results. Progress callbacks must return promptly: arbitrary callback
code cannot be preempted. Callback exceptions return a redacted `Local` error. Local timeout/cancellation
stops observation, not the durable job. See [job polling](JOBS.md#job-observation-and-bounded-polling).

## Cache and single-flight

Only marked GETs can be cached. `cacheTtl` defaults off; `staleIfError` is an additional global grace period. Stale values are served only for server/network/open-circuit errors, never 401/403, validation, or cancellation. Credential endpoints, polling are ineligible. Cache is bounded FIFO, not an unbounded memoizer. Successful mutations invalidate all cached data. Responses are frozen to prevent one caller corrupting others.

Identical safe GETs share a flight only when retry/priority/cache policies match and there is no explicit deadline or cancellation signal. Independent policies dispatch independently rather than inheriting a leader's cancellation. Refresh single-flight separately handles caller-local deadlines/signals.

## Shutdown

Owned audit writers drain before admission closes; snapshot/schema pollers stop and Fields presence leases are released. Native audit writers and Fields helpers register one shared BindToClose automatically. See [new-service lifecycle](NEW-SERVICES.md). Issue final saves first. Call `flush(seconds)` in `BindToClose`; it closes admission and returns whether physical/logical work drained in time. Then `destroy()`. Destroy is idempotent and affects every universe facade. Closing does not silently enqueue new saves, accept fresh calls, or replay native mutations later.

## Error taxonomy

`Unauthorized` (401), `Forbidden` (403), `NotFound` (404), `Conflict` (409), `Validation` (400/422 and other unsupported 4xx), `RateLimited` (429/local backpressure), `Server` (5xx), `Network` (backend exceptions or invalid wire success payload), `Timeout` (408/deadline), `CircuitOpen`, `Cancelled`, and `Local` (client misuse). Status is absent when no trustworthy HTTP response exists. Bodies are `[redacted]`, not partially sanitized strings. Fields preserves allowlisted machine codes such as `session_conflict`; never raw backend messages.
