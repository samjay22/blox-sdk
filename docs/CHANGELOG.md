# Changelog

## Gateway routing

- Default all nine services to `https://lb1.blox-api.com` with generated stripPrefix routes, including `/remote-config-service`.
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

## Four-service extension

- Added 84 routes across Audit, Config, Leaderboards (boards and ratings), Economy; 234 total.
- Added retry-stable generated idempotency keys, positive universe validation and exact Economy amounts.
- Added cursor iterators, bounded audit writer with native close integration, and versioned snapshot cache.
- Retry safety can no longer be overridden with idempotencyHint; unkeyed mutation 401 replay is disabled.
- Added independent live-source coverage and contract-parity checks plus offline runtime regressions.
