# Source audit and evidence boundary

`spec/endpoints.json` is the input to reproducible generation. `gen.py --refresh-sources` refreshes the four record-based services directly from local Java sources and documented wire exceptions. It includes Java request/response field types, requiredness, parameter location/names/defaults, controller provenance, guards, reviewed service/level metadata, statuses, and safety flags. `routes.json` retains the 134 legacy entries and adds 84 new-service routes. `spec/provenance.json` records hashes of inspected local source files; source contents and credentials are not copied into the SDK.

| Service | Inventory | Exposed |
|---|---:|---:|
| Auth | 33 | 49 |
| Data | 27 | 27 |
| Matchmaking | 50 | 50 |
| Party | 16 | 16 |
| Codes | 8 | 8 |
| Audit | 13 | 13 |
| Config | 20 | 20 |
| Leaderboards | 26 | 26 |
| Economy | 25 | 25 |
| **Total** | **218 (100%)** | **234** |

Additional auth endpoints: four DELETE aliases, seven service-account operations, four service-catalog operations, and universe lifecycle PATCH. The four new services include all controller health probes plus contract-documented Boot metrics/info routes. Legacy probe exclusions are unchanged; client health checks use `/health`.

## Reviewed exceptions

- GameModeController's `requireUniverseWriteAccess` actually calls `isAdminForUniverse`: **create, update, and delete game modes require ADMIN**, despite the helper's name. The generic method-derived READ_WRITE heuristic is not used for this route.
- Codes create/update/delete and redemption-history listing require CodeService ADMIN. Redeeming requires READ_WRITE.
- Matchmaking validation and bulk status are read-only POSTs. Process/flush and ban mutation require ADMIN.
- Auth service-account CRUD/rotation/permission replacement requires SUPER_ADMIN. Auth catalog listing requires a non-PENDING authenticated identity, not an AuthService grant. Universe/place reads and writes use the actual service guards.
- Party `/api/poll/**` is public in the checked-in security configuration. The SDK records this rather than inventing an auth requirement. Do not treat possession of a serverId as a security boundary; review deployment policy before relying on this feed.
- Individual data GET can update online state; it is neither cached, retried automatically, nor coalesced. Admin-unscoped variants can return lists instead of one DTO.
- Queue DTOs inherit player IDs and accept legacy singular/comma-separated ID aliases and metadata shorthands through Jackson setters. The reviewed schema includes those wire inputs, not just private fields.
- ServiceAccountPatchRequest distinguishes absent from explicit null. Only enabled/description/expiresAt are accepted. Creation/rotation can return a one-time key and are never cached.
- Leave-party may return 204. HEAD key-existence checks may return 200/404. The metrics and polling-health responses are text.

## Re-audit workflow

`tools/import_contract.py` reads only the designated local controller/DTO trees and writes a scratch import to `.test-build/`. `tools/curate_contract.py` applies documented corrections to produce a *candidate* contract. It is an audit aid, **not a substitute for source review**. Never run it over a curated spec without reviewing the diff. Plain generation does not access sibling repositories. Source-refresh, contract-parity tests and the independent route-coverage checker require the four local sibling backend trees. Missing sources fail coverage rather than silently skipping it. `sourceHashes` in the spec records their Java/contract evidence.

New-service record extraction handles nested packages, generic/type-use annotations, nullable fields, cursor pages and exact decimal amounts; snapshot JSON/304 and overloaded controller method names are explicitly reviewed. Coverage independently scans all 76 controller mappings, so a missing route cannot hide behind a stale inventory.

For backend changes: inspect controller, DTO, security filter/config, and authorization helpers; edit the authoritative spec; regenerate; review generated signatures and endpoint metadata; add independent contract tests; run `tools/verify`. Route coverage alone does not establish correct schema/access/safety.

`statuses` lists controller success/explicit branch statuses. `errorStatuses` is common service/framework guidance, not an exhaustive endpoint-specific exception call graph. Business validation, ownership checks, catalog constraints, deployment policies and HTTP intermediaries remain backend-authoritative. Nullable Java response fields are optional unless requiredness is directly established. Offline synthetic fixtures test consistency; independent controller-specific assertions catch selected extraction mistakes. No live response-contract parity test was possible under the no-network constraint.

## External review / commits

Claude Code 2.1.286 was discovered. The exact Opus 5.5 consultation was requested through a network-denying sandbox wrapper, but macOS denied `sandbox_apply` before Claude started. The bounded Sonnet 5.5 review and final Opus 5.5 second-opinion requests met the same sandbox failure. No consultation, delegation result, or independent Claude opinion is claimed; no model alias or online fallback was used.

No Git-writing commands are used for this extension; the owner will commit. No network requests, backend application startup or live deployment validation are performed.
