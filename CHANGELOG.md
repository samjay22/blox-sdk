# BloxSDK changelog

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
source parity. Claude consultation/review was attempted with exact 5.5 model IDs but authentication was
unavailable. No registry publication, deployment or commit is part of this version.

See [historical changes](docs/CHANGELOG.md).
