# Source audit and evidence boundary

`spec/endpoints.json` is the input to reproducible generation. `gen.py --refresh-sources` refreshes the GAS tenant controllers/DTOs, four record-based services and Codes/Matchmaking consumer contracts directly from local Java sources and documented wire exceptions. It includes Java request/response field types, requiredness, parameter location/names/defaults, controller provenance, guards, reviewed service/level metadata, statuses, and safety flags. `routes.json` contains 281 routes across the eight current services. `spec/provenance.json` records hashes of inspected local source files; source contents and credentials are not copied into the SDK.

| Service | Inventory | Exposed |
|---|---:|---:|
| Auth | 55 | 55 |
| Matchmaking | 51 | 51 |
| Party | 16 | 16 |
| Codes | 10 | 10 |
| Audit | 13 | 13 |
| Config | 20 | 20 |
| Leaderboards | 26 | 26 |
| Fields | 90 | 90 |
| **Total** | **281 (100%)** | **281** |

Fields includes all 85 domain routes, controller health/probe routes and documented metrics/info routes.
Auth coverage is exact against current controllers: removed routes fail coverage as well as missing routes.
Coverage independently scans seven refreshed backend trees, so stale inventory cannot hide omissions.

## Reviewed exceptions

- F1 criteria-type discovery is declared from the authoritative shared `rbac/f/CONTRACT.md`, ahead of its parallel backend implementation. Its typed array and READ auth match that contract; local backend hashes do not certify this new route's implementation. The SDK preserves `criteria_field_invalid` and `fields_unavailable` while retaining its existing raw-body redaction policy.
- `tools/references_contract.py` layers the authoritative shared F2 contract onto Fields discovery, adding the reference registry, forced-change query flags and audited reference-list types. Archive retains the existing `Action.force` body property; update and purge use `force` in the query. PUT/DELETE reference mutations return 204. This layer is replayed on refresh; the older source hashes do not certify deployment of the new F2 behavior. SDK errors retain only `field_in_use`, not raw reference labels/IDs; fetch `definitionReferences` for a current typed list.
- GameModeController's `requireUniverseWriteAccess` actually calls `isAdminForUniverse`: **create, update, and delete game modes require ADMIN**, despite the helper's name. The generic method-derived READ_WRITE heuristic is not used for this route.
- Codes create/update/delete and redemption-history listing require CodeService ADMIN. Redeeming requires READ_WRITE.
- Matchmaking validation and bulk status are read-only POSTs. Process/flush and ban mutation require ADMIN.
- Auth key management requires identity plus org ADMIN/OWNER (or SUPER_ADMIN). Catalog reads accept identity/scoped tokens; mutations are platform-only. Org capabilities remain server-enforced. Place operations retain AuthService guards.
- Party `/api/poll/**` is public in the checked-in security configuration. The SDK records this rather than inventing an auth requirement. Do not treat possession of a serverId as a security boundary; review deployment policy before relying on this feed.
- Queue DTOs inherit player IDs and retain the documented singular/comma-separated ID inputs. Caller metadata is not exposed: the service replaces it with Fields computed values. The criteria DTO wire fields are unchanged; fieldName accepts any computed Fields ID, including namespaced IDs such as `Stats.Elo`, with the Fields field-id grammar and 200-character maximum. Dots are literal ID separators, not metadata traversal.
- ServiceAccountPatchRequest distinguishes absent from explicit null. Only enabled/description/expiresAt are accepted. Creation/rotation can return a one-time key and are never cached.
- Leave-party may return 204. HEAD key-existence checks may return 200/404. The metrics and polling-health responses are text.

## Re-audit workflow

`tools/import_contract.py` reads only the designated local controller/DTO trees and writes a scratch import to `.test-build/`. `tools/curate_contract.py` applies documented corrections to produce a *candidate* contract. It is an audit aid, **not a substitute for source review**. Never run it over a curated spec without reviewing the diff. Plain generation does not access sibling repositories. Source-refresh, contract-parity tests and the independent route-coverage checker require the seven local sibling backend trees. Missing sources fail coverage rather than silently skipping it. `sourceHashes` in the spec records their Java/contract evidence.

New-service record extraction handles nested packages, generic/type-use annotations, nullable fields, cursor pages and Fields typed-operation boundaries; snapshot JSON/304 and overloaded controller method names are explicitly reviewed. Coverage independently scans all in-scope controller mappings, including literal route-array aliases, so a missing route cannot hide behind a stale inventory.

For backend changes: inspect controller, DTO, security filter/config, and authorization helpers; edit the authoritative spec; regenerate; review generated signatures and endpoint metadata; add independent contract tests; run `tools/verify`. Route coverage alone does not establish correct schema/access/safety.

`statuses` lists controller success/explicit branch statuses. `errorStatuses` is common service/framework guidance, not an exhaustive endpoint-specific exception call graph. Business validation, ownership checks, catalog constraints, deployment policies and HTTP intermediaries remain backend-authoritative. Nullable Java response fields are optional unless requiredness is directly established. Offline synthetic fixtures test consistency; independent controller-specific assertions catch selected extraction mistakes. No live response-contract parity test was possible under the no-network constraint.

## Fields evidence and review boundary

Fields extraction reads all controller mappings and DTO records, including JsonProperty default renames,
controller overload disambiguation, typed dynamic-map response envelopes, schema text content types,
per-route guards and optional-key document saves. `tools/fields_contract.py` records reviewed wire exceptions.
The TypeSystem oracle compiles actual sibling Java sources into a temporary directory with cached jars;
it does not run Spring, a service, or database. See [Fields verification](FIELDS.md#verification-evidence).

Claude Code 2.1.286 is installed. The exact Opus 5.5 consultation and second-opinion requests, and Sonnet 5.5 bounded test-review request, failed with
`Not logged in`. No consultation or second opinion succeeded, and no model substitution/upgrade occurred.
Independent offline checks are the verification evidence, not a claim of Claude review.

## Consumer refresh evidence

`tools/consumer_contracts.py` extracts current CodeController/DTOs and MatchmakingCriteriaDTO, with
reviewed Code receipt requiredness, subject-free operation union, and queue-enrichment input boundaries.
Codes includes documented `/metrics` and `/info`; actuator deployment probes stay outside its inventory.
The source hashes cover README/contracts, Java and the Code Postman collection. Generated provenance
replaces obsolete consumer hashes instead of retaining deleted DTO paths.

The 134 existing shared TypeSystem vectors remain the Java/Luau baseline (one documented JSON-number
representation exception in Luau). Additional `ops-validation.json` vectors cover the subject-free API
and local static-template diagnostics; these are separate Luau fixtures, not additional Java-oracle claims.
No backend service, network, deployment, package publication or git write is part of verification.

## Field-owned board refresh

Both ADMIN board routes are controller-discovered. Preview/listing records have reviewed requiredness,
closed binding types, safe conflict settings and optional `willWiden` ranges. The 103 additional shared
binding vectors compile actual IntegrationBindings/Models sources using cached Jakarta Validation 3.0.2;
no remote provisioning behavior is executed or claimed. Static negative fixtures retain strict checks.
Verification uses `luau-analyze -j1` because the installed 0.703 analyzer intermittently SIGTRAPs in its
parallel workers; serial analysis changes no validation rules. No compiler installation or upgrade occurred.

## Durable Fields control-plane refresh

All 33 new routes are checked independently against explicit contract expectations, including the three
additional array-mapping aliases. `tools/jobs_contract.py` records reviewed response envelopes, ADMIN
guards (READ only for health summary), raw NDJSON import/download metadata and header-key retry safety.
Typed helpers validate operations/filters against cached schema; raw generated wrappers do not replace
server semantic validation. Offline tests verify polling, transport, typing and package projections, not
live worker execution, database fencing, webhook delivery or remote scheduling behavior. See [Jobs](JOBS.md).

## Tenant Auth refresh

`tools/auth_contract.py` replaces Auth from GAS controllers, client DTOs, tenant records and API_CONTRACT wire
semantics; unreachable imported auth DTOs are pruned. Sources include both GAS Java modules and contract/README
hashes. Generated paths retain controller parameter names (e.g. `{universe}` for exchange). Role-template path
roles are statically typed. Null record fields and nullable plan replacement are represented explicitly.
Legacy downstream global-ADMIN guards are represented as SUPER_ADMIN identity-only access: scoped tokens
do not inherit global bypass. No downstream binaries or DTO artifacts are changed.
The handwritten scope cache is exercised with deterministic concurrency, cancellation, expiry, epoch changes,
malformed responses, credential separation and 401 tests. No backend artifacts were upgraded or executed.
