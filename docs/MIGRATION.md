Current migration: [6.0.0 to 7.0.0, rotations simplified](../MIGRATION.md#600-to-700--rotations-simplified).

# 3.0 leased profiles

See the binding [2.0 to 3.0 migration](../MIGRATION.md#200-to-300--leased-profiles-and-optimistic-writes). The historical tenant-auth context below does not override 3.0 lifecycle, buffering or HTTP limits.

# 1.1.0 Fields synchronization

See [1.0 to 1.1 migration](../MIGRATION.md): no API break. Mutation `seq` values are sparse allocation
tokens, not feed cursors or `expectedSeq`. Profiles reconcile by per-field version, retain snapshot
watermarks until refresh, and resync only for actual missing state/schema changes, not token gaps.

[1.0 breaking migration](../MIGRATION.md) supersedes helper names below; this file retains tenant-auth migration context.

# Migrating to organization-tenant authentication


## 1.2.0 to 2.0.0 — batch-only transport, public calls unchanged

All SDK network traffic now uses `POST {gatewayUrl}/batch-service/api/batch`. Deploy a compatible
BatchService before upgrading. There is no compatibility shim, direct-call fallback or automatic retry
to a service host. Existing yielding method signatures and Result shapes are unchanged.

- Configure `batch = { intervalSeconds = 0.5 }` (minimum 0.25). Queued calls add up to a tick of latency,
  plus overflow/in-flight/backoff waits. Concurrent independent calls coalesce; sequential loops do not.
- Every envelope is limited to 100 ops / 1 MiB, each encoded op body to 256 KiB. Larger payloads now fail
  locally, including previously allowed large NDJSON imports; partition them explicitly. NDJSON is carried
  as an exact string in `op.body`; text responses must be JSON strings in the batch result.
- Replace direct `services.*.baseUrl` overrides with a BatchService gateway. Direct overrides are rejected.
  Custom backends must accept only the batch endpoint and return the new results envelope, not raw
  endpoint responses. Test fixtures must model per-operation IDs/status/headers/body.
- Profile polls piggyback every available tick in chunks ≤200 players/op. Batch cadence replaces the old
  `profileSync.intervalSeconds` (now rejected) / server `pollAfterMs` schedule. Use `batch.intervalSeconds`; sync apply, signals and recovery stay intact.
- Budgets count physical envelopes, not logical operations: default ≤120/min/client, minimum interval
  ≤240/min; rolling safety cap remains 450/min. All facades share one native in-flight slot; `concurrency`
  cannot increase it. Default logical queue capacity is now 10,000 instead of 64.
- Timeouts include tick/queue waits. Cancellation before dispatch sends nothing; in-flight cancellation
  cannot abort the shared native HTTP request. Player ordering remains held across retry backoff.
- Health queues eight ops together. Authorization is applied on the outer envelope, including public ops;
  distinct credential scopes use different envelopes with no serialized credentials in op bodies.

See the batching and performance guides for detailed limits, ordering and the platform sizing target.

## Breaking Auth migration

The source of truth is `~/work/srv/src-gas/API_CONTRACT.md` and its README. Refresh with
`python3 tools/gen.py --refresh-sources`; never patch generated modules/types by hand.

- Persisted identities are `USER | SUPER_ADMIN`. Registration accepts only username/password/email/metadata.
  Removed: account-admin creation, promotion, per-account permissions, global enumeration/enable/delete,
  `UNIVERSE_ACCOUNT` creation and `PENDING` flows. No compatibility methods remain.
- Replace global account management with `listOrgs`, `getMyAccess`, `addMember`, `patchMember`,
  `removeMember`, `leaveOrg` and `transferOwnership`. For scope-only contractors, supply `universeId`
  without also granting an org role. Optional membership query selectors are **never** filled from `withUniverse`.
- Replace unowned universe create/list/update/delete with `createOrgUniverse`, `listOrgUniverses`,
  `getOrgUniverse`, `patchOrgUniverse`; moves are platform-only. Place routes remain.
- Use `createInvitation` / `acceptInvitation`; no email delivery or verification transport is implied.
- Key listing now requires `{query={orgId=...}}`; metadata includes orgId/createdBy. Keys remain universe-bound.
  Add `Gateway` plus the target service grants when using lb1; `levels` is not an access grant.
- Humans/tools: login on the root client, manage orgs/keys there, and use `client:scoped(id)` for services.
  `withUniverse` does not mint a token. Scoped exchange uses identity credentials and never a scoped refresh flow.
  Old `type:access` JWTs are rejected; existing refresh tokens rotate into identity tokens, or log in again.
- Identity login returns no universe or service-permission list. `UNIVERSE_ACCOUNT` remains only the
  downstream validation wire accountType for scoped JWTs and machine keys, not an identity creation option.
- Template defaults, override precedence, quota/last-owner errors and credential handling are in [AUTH](AUTH.md).
  Account roles and service permission levels both use ADMIN vocabulary but are not interchangeable.

Backend data migration/cutover is operator work, not an SDK action. Do not run old and new auth writers together.
Inventory Fields internal-login identities before cutover: an integration still requiring global ADMIN cannot
silently migrate to USER. This SDK does not upgrade downstream Java DTO artifacts, promote credentials, migrate
production data, or certify live deployments.

## Gateway routing

In 2.0 all eight services use `POST {gatewayUrl}/batch-service/api/batch`. Permit the gateway host in
Roblox Secret restrictions, and configure an HTTPS origin without a service prefix. Previous `hosts`
and `services.*.baseUrl` direct-host configurations are rejected; see the 2.0 section above.

## Service-account keys

1. Audit the game server's actual endpoints against `ENDPOINTS.md`. Most gameplay paths need READ_WRITE; schema changes, code administration, ban management and game-mode management require the service's ADMIN level. Organization/key management is identity-token-only; catalog mutation is SUPER_ADMIN-only.
2. With an identity token and org ADMIN/OWNER membership (or SUPER_ADMIN), create one universe-scoped service account using `auth:createServiceAccount`. Supply only necessary case-sensitive service permissions. Creation returns the key once; do not log the result.
3. Store that key in Roblox Secrets with appropriate destination restrictions. Do not put it in a ModuleScript string, ReplicatedStorage, attributes, or client remotes. Service accounts cannot be reassigned to another universe.
4. Replace login/password/refresh loops with `BloxSDK.new({secretName="...", universeId=game.GameId, levels={...}})`. No refresh timer is needed for machine identities.
5. Replace handwritten URL code with generated methods. Body-only methods accept DTOs directly; mixed path/query/body calls are explicit. String matchmaking IDs remain strings. Keep request field names such as `robloxUniverseId`, `robloxUserIds`, `ownerId`, and `code` exactly as typed.
6. Handle `Result` rather than wrapping every call in `pcall`. Check `ok` before accessing `value`. Do not blindly retry joins, redemptions, party mutations, schema writes, snapshot captures, or account operations after uncertain failures.
7. Add finite shutdown handling: finish issuing saves, `flush`, then `destroy`. A timeout is not proof that a write did not reach the server.
8. Validate in a private server against the intended deployment. Only then retire the old account credentials and rotate/revoke unnecessary access. The SDK does not perform this operational migration for you.

Only the retained place-deletion POST and DELETE alias remain (`deletePlace` / `deletePlaceRest`). Removed account and unowned-universe deletion APIs have no aliases. They preserve route/status behavior; they are not silently substituted for legacy methods. New service-account management methods use descriptive names: create/list/get/patch/rotate/revokeServiceAccount and setServiceAccountPermissions.

For admin tools, retain `userSession={}` and a secure TokenStore if needed. Do not give a game server a super-admin login to work around a local key rejection. A supplied `role` or `levels` field changes local diagnostics only; it cannot grant backend access.

## Breaking Fields replacement

Data and Economy modules, types, routes, generator entries and examples are removed. There are no aliases,
compatibility shims or legacy data migrations in this SDK. No game depends on those old modules.
Provision explicit Fields definitions before gameplay; balances are int fields, inventories are typed maps,
player blobs become declared document leaves, backups become snapshots, and online flags become presence.

- Grant `FieldsService` and allow `lb1.blox-api.com`; route via `/fields-service` (direct host optional).
- Load `fields:schemaCache():load()` before creating standalone transactions, or use LoadProfile.
- Replace opaque writes with builder operations and required audit reasons; preserve operation keys across
  uncertain outcomes and restarts. Document saves without keys do not retry automatically.
- Use zero-based list path indexes, wire-string map keys and explicit BloxSDK.null. Keep all int fields,
  numeric identifiers and int bounds within the exact Luau safe-integer range; unsafe values fail closed.
- Generate field-specific types/accessors from a saved schema and compile the game against each schema update.
- Use profile-owned transactions for local acknowledgement application. PullChanges follows nextSinceSeq and
  refreshes the whole document for non-ledgered/deleted/computed state. It is not a durable local write queue.
- Start/stop session presence explicitly. Native Fields helpers share one BindToClose flush with audit writers;
  finish issuing final transactions before SDK admission closes.
- Submit trusted purchaseId/product/user/robuxSpent values through ProcessReceipt. Never acknowledge purchase
  delivery on failure or treat a field compensation as a Roblox refund.

See [Fields workflow and boundaries](FIELDS.md) and `examples/fields-*.luau`. The SDK does not contact a live
backend or move production data during generation, testing or migration. Universe identifiers remain exact;
`idempotencyHint` is removed and rejected. No option can force unsafe retries or unkeyed mutation replay after 401.

## Fields-backed consumers (breaking, no compatibility layer)

- Replace Code awards with an ordered list of subject-free Fields operations; regenerate callers against
  `Types/Codes`. Use `codes:award()` (or an op list) with `codes:create`; the schema loads and validates on use.
- `maxRedemptionsPerUser` must be 1. Grant identity is backend-owned (`code-<codeId>-<userId>`); retries
  use the same code/player pair. Consume `transaction`, `replayed`, `redeemedAt` and touched subvalues,
  not a player document. History now contains the frozen operation list and receipt.
- Use `fields:validateOps` or an op builder's lower-case `:validate()` for all-diagnostic, read-only
  player-template checks. A transaction's capitalized `:validate()` remains its full local commit check.
- Matchmaking criteria reference server-fetched Fields computed values. `fieldName` accepts any computed
  Fields ID, including namespaced IDs such as `Stats.Elo`, using the Fields field-id grammar (at most
  200 characters). Dots are literal ID separators, not metadata traversal. Stop supplying metadata in
  queue inputs. See [criteria guide and exact grammar](MATCHMAKING.md).
- Grant **Gateway plus target-service permissions** for lb1. Also grant downstream Fields permissions
  for Codes and Matchmaking. `bsa_` keys remain universe-bound; no client scope setting changes that.

See [Codes](CODES.md) and [award example](../examples/code-award.luau). Refresh generated Roblox modules
with `tools/build-roblox.py`; never edit the projection or generated service/type files by hand.
