# Migrating game servers to service-account keys

1. Audit the game server's actual endpoints against `ENDPOINTS.md`. Most gameplay paths need READ_WRITE; schema changes, code administration, ban management and game-mode management require the service's ADMIN level. Global account/catalog/service-account administration is user-token-only.
2. With a SUPER_ADMIN user token, create one universe-scoped service account using `auth:createServiceAccount`. Supply only necessary case-sensitive service permissions. Creation returns the key once; do not log the result.
3. Store that key in Roblox Secrets with appropriate destination restrictions. Do not put it in a ModuleScript string, ReplicatedStorage, attributes, or client remotes. Service accounts cannot be reassigned to another universe.
4. Replace login/password/refresh loops with `BloxSDK.new({secretName="...", universeId=game.GameId, levels={...}})`. No refresh timer is needed for machine identities.
5. Replace handwritten URL code with generated methods. Body-only methods accept DTOs directly; mixed path/query/body calls are explicit. String matchmaking IDs remain strings. Keep request field names such as `robloxUniverseId`, `robloxUserIds`, `jsonData`, `ownerId`, and `redemptionKey` exactly as typed.
6. Handle `Result` rather than wrapping every call in `pcall`. Check `ok` before accessing `value`. Do not blindly retry joins, redemptions, party mutations, schema writes, bulk saves, backups, or account operations after uncertain failures.
7. Add finite shutdown handling: finish issuing saves, `flush`, then `destroy`. A timeout is not proof that a write did not reach the server.
8. Validate in a private server against the intended deployment. Only then retire the old account credentials and rotate/revoke unnecessary access. The SDK does not perform this operational migration for you.

Legacy POST deletion endpoints remain exposed under their controller names. New DELETE aliases have `Rest` suffixes (e.g. `deletePlaceRest`). They preserve route/status behavior; they are not silently substituted for legacy methods. New service-account management methods use descriptive names: create/list/get/patch/rotate/revokeServiceAccount and setServiceAccountPermissions.

For admin tools, retain `userSession={}` and a secure TokenStore if needed. Do not give a game server a super-admin login to work around a local key rejection. A supplied `role` or `levels` field changes local diagnostics only; it cannot grant backend access.

## Four-service extension

The original five facades remain. New helpers are opt-in; see [new services](NEW-SERVICES.md).
Universe IDs now reject zero, negatives, fractions and nonnumeric strings. `idempotencyHint` no longer
forces unsafe retries, and unkeyed mutations are not replayed after 401. Refresh credentials before
retrying such calls manually and first establish whether the original operation committed.
