# Migrating to organization-tenant authentication


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

## Gateway routing change

All eight services now default to `https://lb1.blox-api.com` plus their [service prefix](../README.md#gateway-routing).
Permit `lb1.blox-api.com` in Roblox Secret destination restrictions. Change the gateway once with
`gatewayUrl = "https://gateway.example"`; do not append a service prefix to that option.
For an intentional direct host, replace `hosts = { fields = "https://direct.example" }` with
`services = { fields = { baseUrl = "https://direct.example" } }`. That service's prefix is omitted.
The old `hosts` field is rejected; there are no per-host defaults, aliases or fallback shims.
Config routes through `/remote-config-service`, never the gateway-reserved `/config-service`.
Gateway-routed services now share the same per-origin queue and circuit breaker.

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
- Load `fields:Schema(universeId):Load()` before creating standalone transactions, or use LoadProfile.
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
`idempotencyHint` cannot force unsafe retries or unkeyed mutation replay after 401.

## Fields-backed consumers (breaking, no compatibility layer)

- Replace Code awards with an ordered list of subject-free Fields operations; regenerate callers against
  `Types/Codes`. Load the universe schema, use `codes:Award(u)`, and build/validate before create.
- `maxRedemptionsPerUser` must be 1. Grant identity is backend-owned (`code-<codeId>-<userId>`); retries
  use the same code/player pair. Consume `transaction`, `replayed`, `redeemedAt` and touched subvalues,
  not a player document. History now contains the frozen operation list and receipt.
- Use `fields:validateOps` or an op builder's lower-case `:validate()` for all-diagnostic, read-only
  player-template checks. A transaction's capitalized `:Validate()` remains its full local commit check.
- Matchmaking criteria reference server-fetched Fields computed values. Define top-level computed IDs;
  dotted criteria names are rejected. Stop supplying metadata in queue inputs. See [criteria guide](MATCHMAKING.md).
- Grant **Gateway plus target-service permissions** for lb1. Also grant downstream Fields permissions
  for Codes and Matchmaking. `bsa_` keys remain universe-bound; no client scope setting changes that.

See [Codes](CODES.md) and [award example](../examples/code-award.luau). Refresh generated Roblox modules
with `tools/build-roblox.py`; never edit the projection or generated service/type files by hand.
