# Authentication: organizations, identities and scoped credentials

**Game servers should use `bsa_` service-account keys. They are universe-bound and need the case-sensitive
`Gateway` permission in addition to target service permissions when using lb1.** Store keys in Roblox Secrets,
never ReplicatedStorage, attributes, source strings or client remotes. SDK `levels` are hints, not grants.

**Humans/tools use identity login for management, then scoped tokens for downstream service calls.**
The source of truth is `~/work/srv/src-gas/API_CONTRACT.md` and README; backend authorization remains authoritative.

## Identity and scope

Persisted identity `accountType` is `USER | SUPER_ADMIN`. A USER identity token has no downstream service access;
SUPER_ADMIN identity tokens retain platform/global bypass. Both identity types exchange via
`POST /api/auth/universes/{universe}/token`. Scoped JWTs and machine keys validate downstream as
`UNIVERSE_ACCOUNT`, including scopes minted by SUPER_ADMIN: **no global bypass or management authority**.

```luau
local client = BloxSDK.new({ userSession = {} })
local login = client.auth:login({ username = username, password = password })
if login.ok then
    local access = client.auth:getMyAccess() -- [] is a valid empty portal, not a pending state.
    local keys = client.auth:listServiceAccounts({ query = { orgId = selectedOrgId } })
    local gameScope = client:scoped(selectedUniverseId)
    local schema = gameScope.fields:schema()
end
client:logout()
client:destroy()
```

`client:scoped(id)` is lazy: first protected call exchanges using the root identity. Keep/reuse the returned
facade. The handwritten `src/Auth/ScopedTokens.luau` caches per universe, shared across repeated facades,
and refreshes at `expiresIn - min(30 seconds, 10% of TTL)` measured from exchange start. Backend default TTL
is 600 seconds (configurable 1–3600). Exchange is single-flight per universe and identity epoch; different
universes remain isolated. A short deadline or cancellation stops only that waiter, not shared exchange work.

Exchange failures fail closed (no expired/stale fallback) and share a one-second failure cooldown. A safe,
idempotent downstream 401 can re-exchange/replay once; a second 401 stops. Unkeyed mutations never replay.
Exchange is an unkeyed POST and is not blindly retried. Identity access-token refresh uses its own refresh
rotation; scoped JWTs never acquire a refresh token. Login replacement, logout and destroy fence stale
exchanges. Scoped calls share the root routing, queue, rate budget, breakers and lifetime, but not its authority.
Destroying/flushing any facade affects the whole client. Scoped Fields helpers use the scoped invoker too.

Use the root client for org/key/template management. A scoped facade rejects identity-only operations locally.
It cannot switch universes via `withUniverse`; obtain another scope from the root. `withUniverse` on an identity
client only fills declared universe parameters; **it does not exchange credentials**. For membership operations,
omitted optional query `universeId` always means org-wide, even on a universe facade.

The raw generated `auth:exchangeScopedToken({path={universe=id}})` remains available for manual integrations;
it does not populate the helper cache. Do not log or persist its token response.

## Tenant roles and effective permissions

Org roles apply to every org universe. Optional universe grants combine by maximum with org grants. A scope-only
contractor has no org role. Disabled org membership denies all scopes; disabled universe grants do not erase an
active org grant. Suspended orgs and disabled universes deny scoped credentials. Universe moves revoke old
keys/invitations and invalidate old scoped JWTs; re-enabling does not undo explicit revocation.

Initial role templates (operators may replace them; query `listRoleTemplates` for current values):

| Role | Initial service grants |
|---|---|
| OWNER / ADMIN | ADMIN on every catalog service, including AuthService and Gateway |
| DEVELOPER | ADMIN on FieldsService, LeaderboardService, CodeService, ConfigService, MatchmakingService, PartyService; READ on AuditService; no AuthService/Gateway |
| VIEWER | READ on every catalog service except AuthService/Gateway |

New catalog services initially give OWNER/ADMIN ADMIN and VIEWER READ. Explicit member overrides replace levels
for named services; unspecified services keep defaults. Universe overrides take precedence over org overrides.
Omit `overrides` to preserve them; `overrides={}` clears them (wire `[]`). Service levels are READ < READ_WRITE < ADMIN.
**DEVELOPER/VIEWER defaults cannot use lb1 without an explicit Gateway grant/template change.** Direct origins
bypass only the gateway, not service authorization. Place operations require scoped AuthService READ/READ_WRITE.
Codes redemption additionally needs Fields write access; Matchmaking enrichment needs Fields READ.

Org ADMIN/OWNER manage universes, keys, invitations and lower-role members and read access logs. Only OWNER
(or SUPER_ADMIN) manages ADMIN/OWNER memberships, transfers ownership, or deletes an empty org. Management is
org-level: a universe-only ADMIN is not an org administrator. No self-role/override edits; the final active org
OWNER cannot leave/be removed/disabled/demoted, including by SUPER_ADMIN. Transfer promotes an existing active
org member first; the old owner then explicitly leaves if desired. Delegations cannot exceed the actor's grants.
Foreign resources return 404. Plan changes, org suspension, universe moves and template edits are platform-only.

## Typed management API

- Orgs: `createOrg`, `listOrgs`, `getOrg`, `patchOrg`, `setOrgPlan`, `deleteOrg`, `transferOwnership`.
- Org/universe members and overrides: `listMembers`, `addMember`, `patchMember`, `removeMember`, `leaveOrg`.
  Add scoped members with body `universeId`; patch/remove/leave scoped grants with query `universeId`.
- Portal access: `getMyAccess` returns organizations, explicit memberships and effective universe permissions.
- Universes: `createOrgUniverse`, `listOrgUniverses`, `getOrgUniverse`, `patchOrgUniverse`, `moveUniverse`.
- Invitations: `createInvitation`, `listInvitations`, `revokeInvitation`, `acceptInvitation`. Creation returns
  a one-time secret and copyable `acceptPath` with a URL fragment, not a query token. No email delivery exists.
  Expiry is 1–14 days (default 7); acceptance is single-use and rechecks current inviter capabilities/quotas.
- Templates: `listRoleTemplates`, `setRoleTemplate`; catalog: `listServices`, `createService`, `updateService`, `deleteService`.
- Access log: `getAccessLog`, `getAccessLogPages`, descending org-bound cursor, limit 1–200 (default 50).
  These are transactional immutable GAS logs, not AuditService events.

Plan fields use `BloxSDK.null` for unlimited; new org defaults are 3 universes, 10 distinct members, 20 non-revoked
keys. Disabled members and disabled/expired non-revoked keys still consume slots. Quotas include SUPER_ADMIN.
Self-service org creation is off by default; when enabled, verified USER identities can create within their limit.
There is no invented verification/email transport. See [endpoint reference](ENDPOINTS.md) for exact typed shapes.

## Service-account keys

Management requires an **identity token + org ADMIN/OWNER (or SUPER_ADMIN)**, not a SUPER_ADMIN-only global API.
Scoped JWTs and machine keys cannot manage keys, even with AuthService ADMIN. Listing requires `orgId`, with an
optional universe filter. Create requires universeId and permissions; org ownership is derived server-side.
Metadata includes orgId/createdBy. Name/scope are immutable. PATCH accepts description/enabled/expiresAt only; explicit null clears description/expiration,
not enabled. DELETE irreversibly revokes. Empty permission arrays remove all grants.

### Expiry and rotation

Create accepts optional `expiresAt`, an ISO UTC instant strictly in the future and at most 365 days out.
An expired key receives the same HTTP 401 as a revoked key on every authentication path; expiry is not a warning-only setting.
Create/get/list/rotate metadata includes optional `expiresAt`, `rotatedAt`, `previousKeyExpiresAt`, and required
`status`: `ACTIVE | EXPIRING_SOON | EXPIRED | REVOKED`. `EXPIRING_SOON` means within seven days of
`expiresAt` or `previousKeyExpiresAt`; it does not mean the current key is already rejected.

`auth:rotateServiceAccount` uses **POST `/api/auth/orgs/{org}/service-accounts/{id}/rotate`**. The optional
body accepts `gracePeriodSeconds`, an integer from 0 to 604800 (seven days), default 3600. Rotation reveals
the new secret once and keeps the old secret valid until `previousKeyExpiresAt` (or the account's earlier
expiry/revocation). Zero grace invalidates it immediately. Only one previous key is retained: rotating again
revokes the earlier previous secret immediately, even if its original grace deadline has not passed.
Rotation does not extend `expiresAt`. Rotation and expiry append organization access-log entries.

```luau
-- Trusted management tool with an identity session, never a gameplay/scoped client.
local rotated = admin.auth:rotateServiceAccount({
    path = { org = selectedOrgId, id = selectedKeyId },
    body = { gracePeriodSeconds = 300 },
})
if not rotated.ok then
    warn(rotated.error.code) -- Never print the result or secret-bearing response.
end
```

**Client helper note:** the management call does not replace credentials in existing gameplay clients,
Roblox Secrets or your secret store. Securely save the one-time `rotated.value.key`, update server secret
configuration, and construct replacement clients using the new credential before grace ends. Drain/flush
old clients and destroy them only after their work finishes. `withUniverse` shares the existing credential;
it is not a rotation helper. Do not retry a rotation after an uncertain response: it is non-idempotent and
the lost one-time secret cannot be retrieved with GET/list. An intentional recovery rotation also drops
the earlier previous key. Caches must honor expiry/rotation within 60 seconds, not a full token-cache TTL.
The SDK does not validate keys on its own or cache successful authentication grants.

The shared `CONTRACT.md` F6 surface is curated in `tools/auth_contract.py` while independent GAS worktrees
converge; it supersedes the older non-org rotate route in the local GAS source snapshot. No legacy route alias exists.

Readable format is exactly `bsa_[A-Za-z0-9_-]{8}_[A-Za-z0-9_-]{43}` (56 bytes). For opaque Roblox Secrets,
`secret:AddPrefix("Bearer ")` is preserved directly in the header; never concatenate or stringify it.
Service keys use no login, token refresh, JWT parsing or scoped exchange. `withUniverse` cannot expand scope.

## Identity session lifecycle and TokenStore

Successful `auth:login` atomically installs access + refresh tokens. Identity expiry within 30 seconds triggers
single-flight refresh. JWT `exp` is used only for scheduling, never signature verification or trusted privilege
inference; `expiresIn` is the fallback. Concurrent safe 401s join one refresh. Failed refresh is remembered for
that token version; a new login replaces it. `client:logout()` uses the latest rotated refresh token and clears
locally even on server failure. Public login/refresh/logout do not recursively prepare auth or send bearer headers.

The default TokenStore is private in-memory state. Custom `{get=...,set=...}` stores must be synchronous,
non-yielding, atomic and non-throwing. Do not mutate them behind a live client's back: use login/logout for identity
replacement so the epoch invalidates scoped credentials. Do not share one store across independently refreshing
clients. `userSession.role` is only a preflight hint, never proof of privilege.

Advanced integrations may use `BloxSDK.Auth.userSession`, `.memoryTokenStore`, `.serviceAccount`, or a custom
AuthProvider. Custom callbacks are trusted code and must not log credentials. `apply` is synchronous;
`onUnauthorized` returns whether replay is appropriate. A custom provider must use `kind="scoped"` when it holds
only a scoped JWT; `kind="custom"` cannot establish authority and the backend still rejects misuse.

## Errors and sensitive data

GAS domain errors use `{timestamp,status,error,message,errorCode,path}`; pre-controller errors use `{error,message}`;
validation failure is HTTP 401 `{valid:false,error}`. The SDK maps HTTP status to `error.kind`, preserves known
GAS machine codes as `error.code`, and redacts **all backend messages/bodies**. Unknown codes are discarded.

| error.code | HTTP | Meaning |
|---|---|---|
| resource_not_found | 404 | Missing or foreign org/member/universe/invitation/key |
| access_denied | 403 | Missing capability, suspended org, or identity required |
| permission_cap | 403 | Delegation exceeds actor grants |
| cannot_change_own_role | 403 | Self-role/override edit |
| last_owner | 409 | Would remove/disable/demote final active owner |
| org_universe_limit / org_member_limit / org_service_account_limit | 409 | Org quota exceeded |
| org_creation_limit / org_not_empty | 409 | Self-service limit / org still owns universes |
| member_exists / resource_conflict | 409 | Existing grant or persistence conflict |
| invalid_invitation | 400 | Invalid, expired, consumed, revoked or wrong-recipient invite |
| invalid_invitation_expiry / invalid_permissions / invalid_cursor / invalid_page | 400 | Invalid domain input |
| UNKNOWN_SERVICE | 400 | Unknown permission catalog service |
| RATE_LIMITED | 429 | Login, exchange (60/user/minute), or invitation throttling |
| VALIDATION_ERROR / INVALID_REQUEST | 400 | Invalid DTO, JSON, unknown fields or parameters |

Existing codes remain: WEAK_PASSWORD, INVALID_CREDENTIALS, ACCOUNT_DISABLED, USERNAME_EXISTS, EMAIL_EXISTS,
TOKEN_EXPIRED, INVALID_TOKEN, INVALID_TOKEN_TYPE, INVALID_SERVICE_ACCOUNT, SERVICE_ACCOUNT_NOT_FOUND,
SERVICE_ACCOUNT_REVOKED, SERVICE_ACCOUNT_CONFLICT, SERVICE_NOT_FOUND, SERVICE_EXISTS, SERVICE_CONFLICT,
INTERNAL_ERROR (unexpected failure, HTTP 500).

Login/refresh/scoped exchange, invitation creation and key creation/rotation return secrets. They are not stored
in the general response cache or sent to hooks. Never print those results. Scoped tokens are retained only in
the private helper cache. `BloxSDK.null` preserves explicit JSON null; nil is omission. Offline tests do not
certify live gateway grants, server state, revocation timing or Roblox Secret destinations.
