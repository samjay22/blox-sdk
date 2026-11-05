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
