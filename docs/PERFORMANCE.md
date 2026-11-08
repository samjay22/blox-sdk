# Performance and capacity

Hot-path scheduling/path/backoff modules use `--!strict`, `--!native`, and `--!optimize 2`. This enables Roblox optimization; it is **not** a claim of measured native throughput.

- Path templates are pre-split by the generator. Runtime joins encoded segments once with `table.concat`; byte escapes are precomputed. No per-call path `gsub`/`string.format` template parsing.
- Queue enqueue/dequeue/interior cancellation is O(1), never `table.remove(t,1)`. The deterministic *test scheduler* intentionally uses a simpler array, not the production queue.
- Middleware state is constructed once. Generated methods contain no reflection or route lookup by URL.
- Each attempt has a fresh header table. Pooling secrets while native requests can complete late is not worth the cross-request contamination risk.
- Encoding occurs once per body-bearing attempt; no body is encoded for empty requests. Successful JSON is decoded once; HEAD/204/empty responses bypass decode. Legacy metrics/polling-health formats are preserved; the four new Boot metrics endpoints are JSON.
- Response schemas validate once at the transport boundary. Recursive JSON work is bounded to depth 64; nonfinite and unsafe typed numeric values are rejected.
- Body/schema validation, JSON serialization and shared-result freezing are O(payload size). This deliberate integrity cost is not advertised as zero-allocation.
- Async HTTP and deadline workers necessarily allocate a small fixed number of closures per attempt. There is no per-call middleware-chain construction. No claims of literally zero per-call allocations.
- Breaker storage is fixed at 20 samples per origin. Cache capacity is configurable (default 128), with O(1) FIFO eviction. Flights exist only while calls are active.
- Optional hooks allocate no event tables when absent. Counters and six latency buckets are always maintained; metrics are not claimed to be free. Bounds are 50ms, 100ms, 250ms, 500ms, 1s, and above 1s; buckets are disjoint, not cumulative. `latencySum` is attempt time, not total logical latency.
- Timings use `os.clock`; Unix time is used for JWT scheduling, HTTP-date Retry-After and injected-runtime key generation. Clock, random, and scheduling are injectable for deterministic tests.

Default-runtime clients from one module share a token bucket; its configuration is set by the first default-runtime client. Prefer one client with universe facades and configure it deliberately. Injected-runtime clients intentionally own isolated budgets for tests/advanced integration. Auth credentials and cache entries never cross distinct clients.

No Roblox load benchmark was run. Before deployment, measure heap, frame time, p50/p95/p99 latency, quota consumption, and queue rejection rates under realistic payload sizes and concurrency. Increase concurrency only with evidence; higher concurrency cannot increase the server's HTTP quota. Batch endpoints reduce request count; only keyed/idempotent writes are retry eligible. Audit queues and cursor history are bounded; snapshot reads use constant-time key/flag maps.

## HTTP budget, back-pressure and connection reuse

Roblox documents a [500 external HTTP requests/minute/server limit](https://create.roblox.com/docs/reference/engine/classes/HttpService).
The SDK defaults to **450 admissions in every rolling 60 seconds** (integer configurable 1–499), with
15 burst tokens and 3 critical-reserve tokens. Both constraints must admit a request. Retries, token
refreshes, health reads and polling count too. A bounded timestamp ring uses O(1) amortized admission
and at most 499 entries; a burst can never bypass the rolling-minute cap.

Budget waits consume the caller's timeout/deadline and emit onRateLimited metadata. Per-origin queues
are bounded (64 pending, 6 physical requests by default); a full queue returns RateLimited /
sdk_rate_limited immediately, not an unbounded task backlog. Bulk traffic cannot spend critical reserve.
The default-runtime shared limiter is scoped to one required ModuleScript and its first client's policy.
Do not duplicate the package, create isolated custom runtimes, or increase limits to evade this boundary.
Reserve additional headroom for unrelated scripts: the SDK cannot observe or budget their HTTP traffic.

Reuse a long-lived client, its universe facades, the same HttpService adapter, and a common gateway
origin. Batch operations and use one ETag snapshot poller per universe instead of per-player polling.
Roblox owns native connection pooling/TLS; the SDK cannot set a socket pool or promise keep-alive reuse.
Do not force Connection: close or spawn per-call HTTP clients in a custom backend. Lune smoke uses
one @lune/net module/transport. No connection-level benchmark or real-gateway throughput is claimed.

`timeout` is relative seconds per call or client default (15); the earlier of a supplied deadline and
relative timeout wins. Native RequestAsync cannot be cancelled: a late physical operation retains its
concurrency slot until completion, even after the caller receives Timeout. Never blindly retry an
uncertain non-idempotent mutation. See [fault tolerance](FAULT-TOLERANCE.md) and [errors](ERRORS.md).
