# Performance and limits

BloxSDK 2.0 uses a single [batch-only transport](BATCHING.md). No deployed BatchService throughput or
Roblox load benchmark is claimed; verification uses mock HTTP and an injected fake clock.

| Limit / policy | Default / bound | Effect |
|---|---|---|
| Tick interval | 0.5s; configurable 0.25–300s | One physical request at most per tick |
| Native batches in flight | 1 per client | Busy ticks skip; no completion-triggered burst |
| Operations per envelope | 1–100 | Overflow carries FIFO within priority lanes |
| Encoded envelope bytes | ≤1 MiB | Includes JSON metadata and delimiters |
| Encoded operation body | ≤256 KiB | Oversize fails locally; no direct upload fallback |
| Logical admission | 10,000 calls; configurable 0–10,000 | Includes player-order waiters; full returns RateLimited |
| Profile poll chunk | ≤200 distinct players per universe/provider/op | Piggybacks, adding no separate HTTP request |
| Default physical budget | ≤120 batches/min/client | At minimum interval: ≤240/min |
| Roblox server budget supplied for this design | 500 external HTTP requests/min | Shared with unrelated scripts |
| Rolling safety limiter | 450/min; configurable integer 1–499 | Counts physical batches, including retries/polls/auth |
| Burst / reserve configuration | 15 / 3 | Batch admission uses critical capacity; priority is per op |
| End-to-end call timeout | 15s, maximum 300s | Queue/tick/auth/backoff/response wait included |
| Per-op retries | At most 3; 20% earned credits, initially empty | Only eligible idempotent operations; cap 10 credits |
| Response cache | Disabled per call; 128 entries maximum by default | Frozen shared values; mutation invalidation |
| Circuit history | 20 logical outcomes, 5 failures in 30s | Gateway-wide breaker; 10s cooldown |

The `concurrency` configuration cannot raise the one-native-batch cap. At 0.5s with full 100-op envelopes,
the theoretical ceiling is **200 independent operations/second/client**, not 10,000. Sequential dependent
calls are slower because they need result and retry ordering. Profile chunks, body bytes, latency,
credential partitioning and server throttling reduce the usable ceiling.

## Platform target: 10k requests/second

Do not increase per-server HTTP traffic to meet a platform-wide target. If “10k req/s” denotes logical
service calls, at least 50 saturated clients at the default cadence are needed theoretically (100 at
50% utilization); practical capacity must be measured. If it denotes physical BatchService requests,
10k/s corresponds to 5,000 active clients at 2 envelopes/s and up to 1 million contained ops/s. These are
sizing arithmetic, **not** achieved benchmark results or a server-side capacity guarantee. BatchService
must independently bound concurrency, ordered sequences, downstream database work and tenant quotas.

## Complexity and operation

- Queue insertion is amortized O(1); stable priority selection, expiry compaction and splitting are O(n)
  per tick, bounded by queue capacity. No sorting of the saturated op queue or per-call HTTP workers.
- Player-lane admission is client-local and held through retries; multi-subject lane keys are sorted
  once for deterministic wire identity. Independent players are not globally serialized.
- Endpoint validation, schema-aware body encoding and freezing are O(payload size); bodies are encoded
  once per attempt, then assembled as raw JSON fragments. No repeated whole-envelope encoding to fit bytes.
- The whole envelope is decoded once; exact JSON-number validation and endpoint schemas remain enforced.
  Responses and request operations necessarily allocate bounded tables. There is no zero-allocation claim.
- One timestamp ring (at most 499 slots) gives amortized O(1) rolling-minute admission. Default-runtime
  clients from one required ModuleScript share the first client's limiter; injected test runtimes do not.
- Existing metrics count logical requests/attempts/retries, not physical envelopes. Attempt latency includes
  queued tick time. Six disjoint histogram buckets are 50/100/250/500/1000ms and above 1s.
- Native HTTP connection/TLS pooling belongs to Roblox or the injected adapter. Reuse one client,
  HttpService adapter and gateway. Unrelated scripts and duplicated ModuleScripts are not observable.

Before deployment measure queue rejection, envelope fill, encoded bytes, p50/p95/p99 end-to-end latency,
Lua heap/frame cost, physical quota consumption and downstream contention. Keep headroom for unrelated
HTTP. Timeouts/cancellation cannot abort native HTTP; one hung request deliberately stalls that client's
next batch rather than starting overlapping requests.
