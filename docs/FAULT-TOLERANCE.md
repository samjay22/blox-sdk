# Fault tolerance

## Retry policy

Only explicitly retryable, idempotent endpoints retry by default. Safe GET/HEAD reads qualify. Matchmaking validation and bulk status POSTs are explicitly read-only and qualify. PUT/DELETE methods are not assumed repeat-safe solely because HTTP defines them as idempotent: backend side effects and return semantics matter. Keyed Fields, leaderboard score/rating and Audit mutations generate stable keys per logical call and qualify. All other mutations have **no automatic retry**.

Eligible transient failures are Network, Server (5xx), and RateLimited. Eligible safe/idempotent calls receiving Unauthorized get one strategy-mediated replay, separately from transient retry accounting. Forbidden/validation/conflict/not-found/cancellation/deadline errors do not retry. A successful mutation with a lost response may already have executed; never interpret a Network/Timeout result as proof that it did not.

Full jitter: `random[0,1] * min(8, 0.25 * 2^(retryIndex-1))`. Delta seconds and IMF-fixdate `Retry-After` are supported on 429/503. The larger of jitter and server delay is used, bounded by the original deadline. Sleeps are interruptible. No hedged reads.

Each actually dispatched original logical request earns `retryRatio` credits (default 0.2), up to 10. Retries spend one credit and never replenish it. There are no initial credits, so a fresh client can fail fast on its first transient error. Cache hits, coalesced followers and rejected queue submissions cannot mint retries. Authorization refresh/replay is accounted separately. `retry` reduces/increases the configured per-call maximum up to 10, but does not bypass safety or budget. `idempotencyHint` is retained for compatibility but cannot bypass the contract safety policy.

## Admission and circuits

The per-origin concurrency gate has two O(1) doubly-linked FIFO lanes. Critical work is selected first, with one bulk grant after three critical grants when both lanes are populated. The queue is bounded; overflow returns `RateLimited` with a local message and zero wire attempts. Cancellation unlinks an interior ticket in O(1).

Rate-waiting calls retain their admission ticket, so token starvation cannot create an unbounded external wait queue. The shared token bucket reserves tokens for critical traffic. Defaults are deliberately below the approximate Roblox shared limit, but other scripts and duplicated SDK modules are not observable. All retries, auth refreshes, and health requests consume tokens. Use one required ModuleScript instance and one client per credential.

Breakers are per origin, including shared custom origins. They inspect the last 20 outcomes within 30 seconds; five Network/Timeout/Server failures open the circuit for 10 seconds. Only one half-open probe is admitted. A successful probe closes/reset samples; failure reopens. Admission generations prevent a late pre-open request from closing a newer half-open circuit. Auth/validation/rate errors are not outage samples.

All services now default to one load-balancer origin, so both the gate and breaker are shared across service prefixes.
A gateway outage can open the circuit for every gateway-routed service. Explicit direct-host `baseUrl` overrides use
their own origin state; the client-wide rate/retry budgets remain shared.

## Deadlines and native HTTP

`deadline` is an **absolute `runtime.now()`/`os.clock()` timestamp**, covering queue wait, rate wait, refresh wait, transport, retry sleep, and replay. `timeout` sets the default relative budget. Set `signal.cancelled=true` to stop a caller.

Roblox `RequestAsync` does not expose a cancellable native HTTP request or timeout parameter. The SDK uses an owned worker and a cancellable timer; deadline/cancellation returns promptly, drops late results, and never prematurely recycles request headers. The worker keeps its concurrency slot until physical completion. Thus there are no abandoned timer tasks or unbounded spawned requests, but a native HTTP operation cannot be killed by `destroy()`. At most the configured number per host can remain physically outstanding. This is intentional backpressure, not a claim of native network cancellation.

## Cache and single-flight

Only marked GETs can be cached. `cacheTtl` defaults off; `staleIfError` is an additional global grace period. Stale values are served only for server/network/open-circuit errors, never 401/403, validation, or cancellation. Credential endpoints, polling are ineligible. Cache is bounded FIFO, not an unbounded memoizer. Successful mutations invalidate all cached data. Responses are frozen to prevent one caller corrupting others.

Identical safe GETs share a flight only when retry/priority/cache policies match and there is no explicit deadline or cancellation signal. Independent policies dispatch independently rather than inheriting a leader's cancellation. Refresh single-flight separately handles caller-local deadlines/signals.

## Shutdown

Owned audit writers drain before admission closes; snapshot/schema pollers stop and Fields presence leases are released. Native audit writers and Fields helpers register one shared BindToClose automatically. See [new-service lifecycle](NEW-SERVICES.md). Issue final saves first. Call `flush(seconds)` in `BindToClose`; it closes admission and returns whether physical/logical work drained in time. Then `destroy()`. Destroy is idempotent and affects every universe facade. Closing does not silently enqueue new saves, accept fresh calls, or replay native mutations later.

## Error taxonomy

`Unauthorized` (401), `Forbidden` (403), `NotFound` (404), `Conflict` (409), `Validation` (400/422 and other unsupported 4xx), `RateLimited` (429/local backpressure), `Server` (5xx), `Network` (backend exceptions or invalid wire success payload), `Timeout` (408/deadline), `CircuitOpen`, `Cancelled`, and `Local` (client misuse). Status is absent when no trustworthy HTTP response exists. Bodies are `[redacted]`, not partially sanitized strings. Fields preserves allowlisted machine codes such as `session_conflict`; never raw backend messages.
