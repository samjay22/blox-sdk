# Endpoint reference

279 endpoints. `routes.json` coverage is checked independently.

Default gateway: `https://lb1.blox-api.com`. Override once with `gatewayUrl`.

**lb1 requires `Gateway` permission in addition to the target service permission. `bsa_` service-account keys are universe-bound.**

| Service | Gateway stripPrefix |
|---|---|
| `auth` | `/auth-service` |
| `matchmaking` | `/matchmaking-service` |
| `party` | `/party-service` |
| `codes` | `/code-service` |
| `audit` | `/audit-service` |
| `config` | `/remote-config-service` |
| `leaderboards` | `/leaderboard-service` |
| `fields` | `/fields-service` |

Paths below are backend-relative: wire URL = gateway + service prefix + path. Config uses `/remote-config-service`, never `/config-service` (the gateway reserves `/config*`). An explicit `services = { fields = { baseUrl = "https://direct.example" } }` bypasses the gateway and prefix for that service only. See [routing configuration](../README.md#gateway-routing).

Request shapes are exported in `src/Types`. Body-only endpoints accept the DTO directly; mixed endpoints use `{path=..., query=..., body=...}`. Statuses below are controller success/branch statuses, not exhaustive domain errors.

**ADMIN endpoints are server/admin-key usage only.** Keep credentials in trusted server storage; never expose control-plane requests to untrusted game clients. Fields durable jobs, migrations, bulk/import/export, schedules, and alerts require FieldsService ADMIN, including previews and downloads. Only Fields `GET /health/summary` requires READ.

Fields imports accept raw NDJSON in `body` with `query={reason=...,dryRun=...}` and top-level `idempotencyKey` for apply. Downloads return raw NDJSON strings, not decoded JSON.

**Auth IDENTITY means identity authentication, not an automatic capability grant.** Org ADMIN/OWNER gates, delegation caps, quotas and last-owner checks remain server-enforced. Scoped JWTs and machine keys cannot manage orgs/keys. Humans/tools use identity login then `client:scoped(id)` for downstream access; game servers should use `bsa_` keys. See [Auth role templates and error codes](AUTH.md).

| Method | Path | SDK method | Service level / role | Success / branch | Retry by default | Cache eligible |
|---|---|---|---|---|---|---|
| GET | `/actuator/health/liveness` | `audit.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `audit.readiness` | public / authenticated | 200 | yes | yes |
| GET | `/api/audit/actions` | `audit.actions` | READ | 200 | yes | yes |
| GET | `/api/audit/events` | `audit.list` | READ | 200 | yes | yes |
| POST | `/api/audit/events` | `audit.append` | READ_WRITE | 202 | keyed | no |
| POST | `/api/audit/events/batch` | `audit.batch` | READ_WRITE | 202 | keyed | no |
| GET | `/api/audit/events/{id}` | `audit.get` | READ | 200 | yes | yes |
| GET | `/api/audit/retention` | `audit.retention` | ADMIN | 200 | yes | no |
| PUT | `/api/audit/retention` | `audit.putRetention` | ADMIN | 200 | no | no |
| GET | `/api/audit/summary` | `audit.summary` | READ | 200 | yes | yes |
| GET | `/health` | `audit.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/info` | `audit.info` | public / authenticated | 200 | yes | yes |
| GET | `/metrics` | `audit.metrics` | public / authenticated | 200 | yes | yes |
| POST | `/api/auth/accounts` | `auth.createAccount` | public / authenticated | 201 | no | no |
| GET | `/api/auth/accounts/me` | `auth.getCurrentAccount` | IDENTITY | 200 | yes | no |
| PUT | `/api/auth/accounts/me` | `auth.updateCurrentAccount` | IDENTITY | 200 | no | no |
| GET | `/api/auth/health` | `auth.health` | public / authenticated | 200 | yes | no |
| POST | `/api/auth/invitations/accept` | `auth.acceptInvitation` | IDENTITY | 200 | no | no |
| POST | `/api/auth/login` | `auth.login` | public / authenticated | 200 | no | no |
| POST | `/api/auth/logout` | `auth.logout` | public / authenticated | 200 | no | no |
| GET | `/api/auth/me/access` | `auth.getMyAccess` | IDENTITY | 200 | yes | no |
| GET | `/api/auth/orgs` | `auth.listOrgs` | IDENTITY | 200 | yes | no |
| POST | `/api/auth/orgs` | `auth.createOrg` | IDENTITY | 201 | no | no |
| DELETE | `/api/auth/orgs/{org}` | `auth.deleteOrg` | IDENTITY | 204 | no | no |
| GET | `/api/auth/orgs/{org}` | `auth.getOrg` | IDENTITY | 200 | yes | no |
| PATCH | `/api/auth/orgs/{org}` | `auth.patchOrg` | IDENTITY | 200 | no | no |
| GET | `/api/auth/orgs/{org}/access-log` | `auth.getAccessLog` | IDENTITY | 200 | yes | no |
| GET | `/api/auth/orgs/{org}/invitations` | `auth.listInvitations` | IDENTITY | 200 | yes | no |
| POST | `/api/auth/orgs/{org}/invitations` | `auth.createInvitation` | IDENTITY | 201 | no | no |
| DELETE | `/api/auth/orgs/{org}/invitations/{id}` | `auth.revokeInvitation` | IDENTITY | 204 | no | no |
| POST | `/api/auth/orgs/{org}/leave` | `auth.leaveOrg` | IDENTITY | 204 | no | no |
| GET | `/api/auth/orgs/{org}/members` | `auth.listMembers` | IDENTITY | 200 | yes | no |
| POST | `/api/auth/orgs/{org}/members` | `auth.addMember` | IDENTITY | 200 | no | no |
| DELETE | `/api/auth/orgs/{org}/members/{user}` | `auth.removeMember` | IDENTITY | 204 | no | no |
| PATCH | `/api/auth/orgs/{org}/members/{user}` | `auth.patchMember` | IDENTITY | 200 | no | no |
| PUT | `/api/auth/orgs/{org}/plan` | `auth.setOrgPlan` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/auth/orgs/{org}/transfer-ownership` | `auth.transferOwnership` | IDENTITY | 200 | no | no |
| GET | `/api/auth/orgs/{org}/universes` | `auth.listOrgUniverses` | IDENTITY | 200 | yes | no |
| POST | `/api/auth/orgs/{org}/universes` | `auth.createOrgUniverse` | IDENTITY | 200 | no | no |
| GET | `/api/auth/orgs/{org}/universes/{universe}` | `auth.getOrgUniverse` | IDENTITY | 200 | yes | no |
| PATCH | `/api/auth/orgs/{org}/universes/{universe}` | `auth.patchOrgUniverse` | IDENTITY | 200 | no | no |
| POST | `/api/auth/orgs/{org}/universes/{universe}/move` | `auth.moveUniverse` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/auth/password/change` | `auth.changePassword` | IDENTITY | 200 | no | no |
| POST | `/api/auth/password/reset/confirm` | `auth.confirmReset` | public / authenticated | 200 | no | no |
| POST | `/api/auth/password/reset/request` | `auth.requestReset` | public / authenticated | 200 | no | no |
| POST | `/api/auth/refresh` | `auth.refresh` | public / authenticated | 200 | no | no |
| GET | `/api/auth/role-templates` | `auth.listRoleTemplates` | IDENTITY | 200 | yes | no |
| PUT | `/api/auth/role-templates/{role}` | `auth.setRoleTemplate` | SUPER_ADMIN | 200 | no | no |
| GET | `/api/auth/service-accounts` | `auth.listServiceAccounts` | IDENTITY | 200 | yes | no |
| POST | `/api/auth/service-accounts` | `auth.createServiceAccount` | IDENTITY | 201 | no | no |
| DELETE | `/api/auth/service-accounts/{id}` | `auth.revokeServiceAccount` | IDENTITY | 204 | no | no |
| GET | `/api/auth/service-accounts/{id}` | `auth.getServiceAccount` | IDENTITY | 200 | yes | no |
| PATCH | `/api/auth/service-accounts/{id}` | `auth.patchServiceAccount` | IDENTITY | 200 | no | no |
| PUT | `/api/auth/service-accounts/{id}/permissions` | `auth.setServiceAccountPermissions` | IDENTITY | 200 | no | no |
| POST | `/api/auth/service-accounts/{id}/rotate` | `auth.rotateServiceAccount` | IDENTITY | 200 | no | no |
| GET | `/api/auth/services` | `auth.listServices` | public / authenticated | 200 | yes | no |
| POST | `/api/auth/services` | `auth.createService` | SUPER_ADMIN | 201 | no | no |
| DELETE | `/api/auth/services/{name}` | `auth.deleteService` | SUPER_ADMIN | 204 | no | no |
| PUT | `/api/auth/services/{name}` | `auth.updateService` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/auth/token/validate` | `auth.validateToken` | public / authenticated | 200, 401 | no | no |
| GET | `/api/auth/universes/{universeId}/places` | `auth.listPlaces` | READ | 200 | yes | no |
| POST | `/api/auth/universes/{universeId}/places` | `auth.addPlace` | READ_WRITE | 201 | no | no |
| DELETE | `/api/auth/universes/{universeId}/places/{placeId}` | `auth.deletePlaceRest` | READ_WRITE | 204 | no | no |
| GET | `/api/auth/universes/{universeId}/places/{placeId}` | `auth.getPlace` | READ | 200 | yes | no |
| PUT | `/api/auth/universes/{universeId}/places/{placeId}` | `auth.updatePlace` | READ_WRITE | 200 | no | no |
| POST | `/api/auth/universes/{universeId}/places/{placeId}/delete` | `auth.deletePlace` | READ_WRITE | 204 | no | no |
| POST | `/api/auth/universes/{universe}/token` | `auth.exchangeScopedToken` | IDENTITY | 200 | no | no |
| GET | `/health` | `auth.healthProxy` | public / authenticated | 200 | yes | no |
| GET | `/api/codes` | `codes.searchCodes` | READ | 200 | yes | yes |
| POST | `/api/codes` | `codes.createCode` | ADMIN | 201 | no | no |
| GET | `/api/codes/batches/{batchId}/export` | `codes.exportBatch` | ADMIN | 200 | yes | no |
| POST | `/api/codes/bulk` | `codes.bulkCreateCodes` | ADMIN | 201 | keyed apply / dry-run | no |
| POST | `/api/codes/redeem` | `codes.redeem` | READ_WRITE | 200 | no | no |
| DELETE | `/api/codes/{id}` | `codes.deleteCode` | ADMIN | 204 | no | no |
| GET | `/api/codes/{id}` | `codes.getCode` | READ | 200 | yes | yes |
| PUT | `/api/codes/{id}` | `codes.updateCode` | ADMIN | 200 | no | no |
| GET | `/api/codes/{id}/redemptions` | `codes.listRedemptions` | ADMIN | 200 | yes | yes |
| GET | `/health` | `codes.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/info` | `codes.info` | public / authenticated | 200 | yes | yes |
| GET | `/metrics` | `codes.metrics` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/liveness` | `config.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `config.readiness` | public / authenticated | 200 | yes | yes |
| GET | `/api/config/universes/{universeId}/entries` | `config.entries` | READ | 200 | yes | yes |
| DELETE | `/api/config/universes/{universeId}/entries/{key}` | `config.deleteEntry` | READ_WRITE | 204 | no | no |
| GET | `/api/config/universes/{universeId}/entries/{key}` | `config.entry` | READ | 200 | yes | yes |
| PUT | `/api/config/universes/{universeId}/entries/{key}` | `config.putEntry` | READ_WRITE | 200 | no | no |
| POST | `/api/config/universes/{universeId}/evaluate` | `config.evaluate` | READ | 200 | no | no |
| GET | `/api/config/universes/{universeId}/flags` | `config.flags` | READ | 200 | yes | yes |
| DELETE | `/api/config/universes/{universeId}/flags/{key}` | `config.deleteFlag` | READ_WRITE | 204 | no | no |
| GET | `/api/config/universes/{universeId}/flags/{key}` | `config.flag` | READ | 200 | yes | yes |
| PUT | `/api/config/universes/{universeId}/flags/{key}` | `config.putFlag` | READ_WRITE | 200 | no | no |
| POST | `/api/config/universes/{universeId}/flags/{key}/evaluate` | `config.evaluateFlag` | READ | 200 | no | no |
| GET | `/api/config/universes/{universeId}/history` | `config.history` | READ | 200 | yes | yes |
| GET | `/api/config/universes/{universeId}/maintenance` | `config.maintenance` | READ | 200 | yes | yes |
| PUT | `/api/config/universes/{universeId}/maintenance` | `config.putMaintenance` | ADMIN | 200 | no | no |
| POST | `/api/config/universes/{universeId}/rollback` | `config.rollback` | ADMIN | 200 | no | no |
| GET | `/api/config/universes/{universeId}/snapshot` | `config.snapshot` | READ | 200, 304 | yes | no |
| GET | `/health` | `config.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/info` | `config.info` | public / authenticated | 200 | yes | yes |
| GET | `/metrics` | `config.metrics` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/liveness` | `fields.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `fields.readiness` | public / authenticated | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/alerts` | `fields.alerts` | ADMIN | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/alerts/config` | `fields.alertConfig` | ADMIN | 200 | yes | no |
| PUT | `/api/fields/universes/{universeId}/alerts/config` | `fields.putAlertConfig` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/alerts/webhook/test` | `fields.testWebhook` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/alerts/{id}/ack` | `fields.ackAlert` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/bulk` | `fields.bulk` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/bulk/definitions` | `fields.createBulkDefinition` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/bulk/definitions/{id}` | `fields.bulkDefinition` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/bulk/preview` | `fields.bulkPreview` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/bulk/{id}/reverse` | `fields.reverseBulk` | ADMIN | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/definitions` | `fields.definitions` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/definitions` | `fields.create` | ADMIN | 201 | no | no |
| POST | `/api/fields/universes/{universeId}/definitions/preview-board` | `fields.previewBoard` | ADMIN | 200 | no | no |
| DELETE | `/api/fields/universes/{universeId}/definitions/{id}` | `fields.purge` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/definitions/{id}` | `fields.definition` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/definitions/{id}` | `fields.update` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/definitions/{id}/archive` | `fields.archive` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/definitions/{id}/history` | `fields.history` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/definitions/{id}/migrations` | `fields.migrate` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/definitions/{id}/migrations/preview` | `fields.migrationPreview` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/definitions/{id}/unarchive` | `fields.unarchive` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/export` | `fields.export` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/fields/batch-get` | `fields.batch` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/health/summary` | `fields.healthSummary` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/import` | `fields.import` | ADMIN | 200 | keyed apply / dry-run | no |
| GET | `/api/fields/universes/{universeId}/jobs` | `fields.jobs` | ADMIN | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/jobs/{id}` | `fields.job` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/jobs/{id}/cancel` | `fields.cancelJob` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/jobs/{id}/download` | `fields.jobDownload` | ADMIN | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/jobs/{id}/events` | `fields.jobEvents` | ADMIN | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/jobs/{id}/failures` | `fields.jobFailures` | ADMIN | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/jobs/{id}/failures/download` | `fields.jobFailuresDownload` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/jobs/{id}/retry` | `fields.retryJob` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/leaderboard-bindings` | `fields.leaderboardBindings` | ADMIN | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/ledger/{entryId}` | `fields.entry` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/ledger/{entryId}/reverse` | `fields.reverseEntry` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/migrations/{id}/cancel` | `fields.cancelMigration` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/migrations/{id}/rollback` | `fields.rollbackMigration` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/ops/validate` | `fields.validateOps` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/outbox` | `fields.outbox` | ADMIN | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/outbox/{id}/retry` | `fields.retryOutbox` | ADMIN | 200 | no | no |
| DELETE | `/api/fields/universes/{universeId}/players/{userId}` | `fields.deletePlayer` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/changes` | `fields.changes` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{userId}/document` | `fields.document` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/players/{userId}/document` | `fields.putDocument` | READ_WRITE | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/fields` | `fields.fields` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/players/{userId}/fields/batch-get` | `fields.playerBatch` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/fields/{fieldId}` | `fields.field` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{userId}/ledger` | `fields.ledger` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{userId}/presence` | `fields.presence` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/players/{userId}/presence` | `fields.putPresence` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/receipts` | `fields.receipts` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/players/{userId}/transactions` | `fields.transaction` | READ_WRITE | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/presence/batch-get` | `fields.presenceBatch` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/products` | `fields.products` | READ | 200 | yes | yes |
| DELETE | `/api/fields/universes/{universeId}/products/{id}` | `fields.deleteProduct` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/products/{id}` | `fields.product` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/products/{id}` | `fields.putProduct` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/receipts` | `fields.purchase` | READ_WRITE | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/receipts/{purchaseId}` | `fields.receipt` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/receipts/{purchaseId}/refund` | `fields.refund` | ADMIN | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/reconcile` | `fields.reconcile` | ADMIN | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/schedules` | `fields.schedules` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/schedules` | `fields.createSchedule` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/schedules/preview` | `fields.schedulePreview` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/schedules/{id}` | `fields.schedule` | ADMIN | 200 | yes | no |
| PUT | `/api/fields/universes/{universeId}/schedules/{id}` | `fields.editSchedule` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/schedules/{id}/actions` | `fields.scheduleActions` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/schedules/{id}/cancel` | `fields.cancelSchedule` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/schedules/{id}/end-now` | `fields.endSchedule` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/schema` | `fields.schema` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/schema/luau` | `fields.luau` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/schema/typescript` | `fields.typescript` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/snapshots` | `fields.snapshots` | ADMIN | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/snapshots` | `fields.createSnapshot` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/snapshots/policy` | `fields.snapshotPolicy` | ADMIN | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/snapshots/policy` | `fields.putSnapshotPolicy` | ADMIN | 200 | no | no |
| DELETE | `/api/fields/universes/{universeId}/snapshots/{id}` | `fields.deleteSnapshot` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/snapshots/{id}` | `fields.snapshot` | ADMIN | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/snapshots/{id}/restore` | `fields.restoreSnapshot` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/transactions` | `fields.multiTransaction` | READ_WRITE | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/transactions/{txId}/reverse` | `fields.reverseTransaction` | ADMIN | 200 | keyed | no |
| GET | `/health` | `fields.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/info` | `fields.info` | public / authenticated | 200 | yes | yes |
| GET | `/metrics` | `fields.metrics` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/liveness` | `leaderboards.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `leaderboards.readiness` | public / authenticated | 200 | yes | yes |
| POST | `/api/leaderboards/ratings/universes/{universeId}/matches` | `leaderboards.ratingMatch` | READ_WRITE | 200 | keyed | no |
| GET | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/config` | `leaderboards.ratingConfig` | ADMIN | 200 | yes | yes |
| PUT | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/config` | `leaderboards.ratingConfigure` | ADMIN | 200 | no | no |
| GET | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/top` | `leaderboards.ratingTop` | READ | 200 | yes | yes |
| POST | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/users` | `leaderboards.ratingUsers` | READ | 200 | no | no |
| GET | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/users/{userId}` | `leaderboards.ratingUser` | READ | 200 | yes | yes |
| GET | `/api/leaderboards/universes/{universeId}/boards` | `leaderboards.list` | READ | 200 | yes | yes |
| POST | `/api/leaderboards/universes/{universeId}/boards` | `leaderboards.create` | ADMIN | 201 | no | no |
| DELETE | `/api/leaderboards/universes/{universeId}/boards/{name}` | `leaderboards.archive` | ADMIN | 204 | no | no |
| GET | `/api/leaderboards/universes/{universeId}/boards/{name}` | `leaderboards.get` | READ | 200 | yes | yes |
| PATCH | `/api/leaderboards/universes/{universeId}/boards/{name}` | `leaderboards.patch` | ADMIN | 200 | no | no |
| GET | `/api/leaderboards/universes/{universeId}/boards/{name}/around/{userId}` | `leaderboards.around` | READ | 200 | yes | yes |
| GET | `/api/leaderboards/universes/{universeId}/boards/{name}/periods` | `leaderboards.periods` | READ | 200 | yes | yes |
| GET | `/api/leaderboards/universes/{universeId}/boards/{name}/periods/{periodId}/top` | `leaderboards.periodTop` | READ | 200 | yes | yes |
| POST | `/api/leaderboards/universes/{universeId}/boards/{name}/ranks` | `leaderboards.ranks` | READ | 200 | no | no |
| POST | `/api/leaderboards/universes/{universeId}/boards/{name}/rollover` | `leaderboards.rollover` | ADMIN | 200 | no | no |
| POST | `/api/leaderboards/universes/{universeId}/boards/{name}/scores` | `leaderboards.submit` | READ_WRITE | 200 | keyed | no |
| POST | `/api/leaderboards/universes/{universeId}/boards/{name}/scores/batch` | `leaderboards.batch` | READ_WRITE | 200 | keyed | no |
| GET | `/api/leaderboards/universes/{universeId}/boards/{name}/top` | `leaderboards.top` | READ | 200 | yes | yes |
| DELETE | `/api/leaderboards/universes/{universeId}/boards/{name}/users/{userId}` | `leaderboards.remove` | ADMIN | 204 | no | no |
| GET | `/api/leaderboards/universes/{universeId}/boards/{name}/users/{userId}` | `leaderboards.user` | READ | 200 | yes | yes |
| GET | `/health` | `leaderboards.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/info` | `leaderboards.info` | public / authenticated | 200 | yes | yes |
| GET | `/metrics` | `leaderboards.metrics` | public / authenticated | 200 | yes | yes |
| POST | `/api/auth/login` | `matchmaking.login` | public / authenticated | 200 | no | no |
| POST | `/api/auth/logout` | `matchmaking.logout` | public / authenticated | 200 | no | no |
| POST | `/api/auth/refresh` | `matchmaking.refreshToken` | public / authenticated | 200 | no | no |
| GET | `/api/bans` | `matchmaking.getAllBannedPlayers` | ADMIN | 200 | yes | yes |
| POST | `/api/bans` | `matchmaking.banPlayer` | ADMIN | 201 | no | no |
| POST | `/api/bans/bulk` | `matchmaking.bulkBanPlayers` | ADMIN | 201 | no | no |
| GET | `/api/bans/check` | `matchmaking.checkBanStatus` | READ | 200 | yes | yes |
| POST | `/api/bans/cleanup` | `matchmaking.removeExpiredBans` | SUPER_ADMIN | 200 | no | no |
| GET | `/api/bans/universe/{universeId}` | `matchmaking.getBannedPlayersByUniverse` | READ | 200 | yes | yes |
| DELETE | `/api/bans/universe/{universeId}/bulk` | `matchmaking.bulkUnbanPlayers` | ADMIN | 200 | no | no |
| GET | `/api/bans/universe/{universeId}/permanent` | `matchmaking.getPermanentBans` | READ | 200 | yes | yes |
| DELETE | `/api/bans/universe/{universeId}/player/{userId}` | `matchmaking.unbanPlayer` | ADMIN | 200 | no | no |
| GET | `/api/bans/universe/{universeId}/player/{userId}` | `matchmaking.getBannedPlayer` | READ | 200 | yes | yes |
| PUT | `/api/bans/universe/{universeId}/player/{userId}` | `matchmaking.updateBan` | ADMIN | 200 | no | no |
| GET | `/api/bans/universe/{universeId}/temporary` | `matchmaking.getTemporaryBans` | READ | 200 | yes | yes |
| GET | `/api/gamemodes` | `matchmaking.getGameModes` | READ | 200 | yes | yes |
| POST | `/api/gamemodes` | `matchmaking.createGameMode` | ADMIN | 201 | no | no |
| DELETE | `/api/gamemodes/{id}` | `matchmaking.deleteGameMode` | ADMIN | 200 | no | no |
| PUT | `/api/gamemodes/{id}` | `matchmaking.updateGameMode` | ADMIN | 200 | no | no |
| GET | `/api/gamemodes/{id}/criteria/explain` | `matchmaking.explainCriteria` | READ | 200 | yes | yes |
| GET | `/api/gamemodes/{name}` | `matchmaking.getGameModeByName` | READ | 200 | yes | yes |
| POST | `/api/matchmaking/process/{universeId}` | `matchmaking.processMatchmaking` | ADMIN | 200 | no | no |
| DELETE | `/api/matchmaking/queue` | `matchmaking.removePlayer` | READ_WRITE | 200 | no | no |
| POST | `/api/matchmaking/queue` | `matchmaking.joinQueue` | READ_WRITE | 200 | no | no |
| DELETE | `/api/matchmaking/queue/flush` | `matchmaking.flushQueue` | ADMIN | 200 | no | no |
| GET | `/api/matchmaking/queue/metrics` | `matchmaking.getQueueMetrics` | READ | 200 | yes | yes |
| POST | `/api/matchmaking/queue/multi` | `matchmaking.joinQueues` | READ_WRITE | 200 | no | no |
| POST | `/api/matchmaking/queue/remove` | `matchmaking.removePlayerPost` | READ_WRITE | 200 | no | no |
| GET | `/api/matchmaking/queue/status` | `matchmaking.getPlayerQueueStatus` | READ | 200 | yes | yes |
| POST | `/api/matchmaking/queue/status/bulk` | `matchmaking.getBulkQueueStatus` | READ | 200 | yes | no |
| POST | `/api/matchmaking/validate` | `matchmaking.validateQueue` | READ | 200 | yes | no |
| GET | `/api/matchmaking/{universeId}/gamemodes/{gameModeName}/queue/count` | `matchmaking.getQueueCount` | READ | 200 | yes | yes |
| GET | `/api/matchmaking/{universeId}/gamemodes/{gameModeName}/wait-estimate` | `matchmaking.getWaitEstimate` | READ | 200 | yes | yes |
| GET | `/api/roblox/keys` | `matchmaking.getAllApiKeys` | SUPER_ADMIN | 200 | yes | no |
| PATCH | `/api/roblox/keys` | `matchmaking.createOrUpdateApiKey` | ADMIN | 200 | no | no |
| POST | `/api/roblox/keys` | `matchmaking.createApiKey` | ADMIN | 201 | no | no |
| DELETE | `/api/roblox/keys/me` | `matchmaking.deleteApiKeyForCurrentUniverse` | READ_WRITE | 200 | no | no |
| GET | `/api/roblox/keys/me` | `matchmaking.getApiKeyForCurrentUniverse` | READ | 200 | yes | no |
| HEAD | `/api/roblox/keys/me` | `matchmaking.checkApiKeyExistsForCurrentUniverse` | READ | 200, 404 | yes | no |
| PUT | `/api/roblox/keys/me` | `matchmaking.updateApiKeyForCurrentUniverse` | READ_WRITE | 200 | no | no |
| DELETE | `/api/roblox/keys/{universeId}` | `matchmaking.deleteApiKey` | ADMIN | 200 | no | no |
| GET | `/api/roblox/keys/{universeId}` | `matchmaking.getApiKeyByUniverseId` | READ | 200 | yes | no |
| HEAD | `/api/roblox/keys/{universeId}` | `matchmaking.checkApiKeyExists` | READ | 200, 404 | yes | no |
| PUT | `/api/roblox/keys/{universeId}` | `matchmaking.updateApiKey` | ADMIN | 200 | no | no |
| GET | `/api/universes/getAllUniverses` | `matchmaking.getAllUniverses` | SUPER_ADMIN | 200 | yes | yes |
| GET | `/api/universes/me` | `matchmaking.getUniverseInfoForCurrentUniverse` | READ | 200 | yes | yes |
| GET | `/api/universes/{universeId}` | `matchmaking.getUniverseInfo` | ADMIN | 200 | yes | yes |
| GET | `/health` | `matchmaking.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/metrics` | `matchmaking.metrics` | public / authenticated | 200 | yes | yes |
| GET | `/{universeId}/gamemodes/{gameModeName}/wait-estimate` | `matchmaking.getWaitEstimateAlias` | READ | 200 | yes | yes |
| POST | `/api/auth/login` | `party.login` | public / authenticated | 200 | no | no |
| POST | `/api/auth/logout` | `party.logout` | public / authenticated | 200 | no | no |
| POST | `/api/auth/refresh` | `party.refreshToken` | public / authenticated | 200 | no | no |
| GET | `/api/party/all` | `party.getAllParties` | ADMIN | 200 | yes | yes |
| POST | `/api/party/create` | `party.createParty` | READ_WRITE | 201 | no | no |
| POST | `/api/party/delete` | `party.deleteParty` | READ_WRITE | 204 | no | no |
| POST | `/api/party/leadership/transfer` | `party.transferLeadership` | READ_WRITE | 200 | no | no |
| POST | `/api/party/member/add` | `party.addMember` | READ_WRITE | 200 | no | no |
| POST | `/api/party/member/kick` | `party.kickMember` | READ_WRITE | 200 | no | no |
| POST | `/api/party/member/leave` | `party.leaveParty` | READ_WRITE | 200, 204 | no | no |
| POST | `/api/party/member/remove` | `party.removeMember` | READ_WRITE | 200 | no | no |
| GET | `/api/party/owner/{ownerId}` | `party.getPartyByOwner` | READ | 200 | yes | yes |
| GET | `/api/party/{partyId}` | `party.getParty` | READ | 200 | yes | yes |
| GET | `/api/poll/health` | `party.health` | public / authenticated | 200 | yes | no |
| GET | `/api/poll/updates` | `party.getUpdates` | public / authenticated | 200 | yes | no |
| GET | `/health` | `party.healthProxy` | public / authenticated | 200 | yes | yes |
