# Changelog

## Field-owned leaderboard provisioning

- Refreshed local contracts: 238 endpoints, including ADMIN previewBoard and leaderboardBindings.
- Added strict VALUE/DELTA binding types, optional order/reset/keep/displayName, int-only preflight,
  typed preview/conflict/range metadata and all five new safe leaderboard error codes.
- Preserve empty binding removal arrays; server provisions boards, with no duplicate game-side submission.
- Added 103 Java/Luau binding vectors, negative type fixtures and offline route/error regression coverage.

## Fields-backed consumers

- Added typed Fields operation dry runs, all-diagnostic preflight and subject-free builders.
- Regenerated Codes awards and typed transaction receipts; added schema-validated award composition.
- Refreshed Matchmaking criteria/queue inputs for server-side Fields enrichment.
- Documented Gateway grants and universe-bound service keys; refreshed source provenance and coverage.

## Gateway routing

- Default all eight services to `https://lb1.blox-api.com` with generated stripPrefix routes, including `/remote-config-service`.
- Add one `gatewayUrl` override and optional `services[service].baseUrl` direct-host overrides; remove old per-host defaults and `hosts`.
- Preserve per-origin admission/breakers, update generated facades and Roblox projection, and verify gateway/direct URLs offline.

## 0.1.0 — 2026-11-05 (unreleased)

- Unified server-side SDK: 134/134 inventory routes plus 16 additive auth routes.
- Deterministic typed services, DTO/schema validation, access metadata, route coverage and generated drift checks.
- Secret-preserving service-account auth; managed user sessions with versioned single-flight refresh and token-store integration.
- Bounded priority admission, shared rate reserve, earned retry budget, full jitter, Retry-After, rolling per-origin circuits, deadlines and cancellation.
- Eligible GET coalescing/cache/stale grace; write/auth epoch isolation; safe lifecycle draining and value-free telemetry.
- Offline fake backend and virtual scheduler, portable/projection tests, source audits, examples and preprovisioned-runner CI.
- Production deployment, Studio/Secret integration, external Claude review and registry publication are not certified by this release.

## Fields replacement — unreleased

- Eight services, 234 endpoints; all 52 Fields controller/probe/operational routes represented.
- Closed TypeExpr validation/defaults/local operations, schema cache, validated transaction and multi-subject
  builders, profile/changes/presence lifecycle and shared BindToClose integration.
- Offline schema-specialized field aliases, nested documents, literal IDs and typed accessor modules.
- Shared JSON vectors cross-checked against the actual pure backend TypeSystem and Luau; accessor goldens
  and positive/negative compiler fixtures. No live network, deployment or external consultation claimed.
- Explicit-null-preserving Fields JSON boundary and fail-closed exact integer handling.
- Stable keyed retries; unkeyed document saves remain single-attempt.
