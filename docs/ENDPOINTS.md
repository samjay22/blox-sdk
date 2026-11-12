# Endpoint reference

379 endpoints. `routes.json` coverage is checked independently.

Default gateway: `https://lb1.blox-api.com`. Override once with `gatewayUrl`.

**lb1 requires `Gateway` permission in addition to the target service permission. `bsa_` service-account keys are universe-bound.**

| Service | Gateway stripPrefix |
|---|---|
| `auth` | `/auth-service` |
| `matchmaking` | `/matchmaking-service` |
| `party` | `/party-service` |
| `codes` | `/code-service` |
| `audit` | `/audit-service` |
| `leaderboards` | `/leaderboard-service` |
| `fields` | `/fields-service` |
| `platform` | `/platform-service` |

Paths below are backend-relative operation paths: all wire HTTP uses `POST {gatewayUrl}/batch-service/api/batch`. Service prefixes shown above are gateway inventory, not prefixes on op paths. Direct-host overrides are rejected. See [batch transport](BATCHING.md).

Request shapes are exported in `src/Types`. Body-only endpoints accept the DTO directly; mixed endpoints use `{path=..., query=..., body=...}`. Statuses below are controller success/branch statuses, not exhaustive domain errors.

**ADMIN endpoints are server/admin-key usage only.** Keep credentials in trusted server storage; never expose control-plane requests to untrusted game clients. Fields durable jobs, migrations, bulk/import/export, schedule controls, and alerts require FieldsService ADMIN, including previews and downloads. Fields health summary and schedule run history require READ.

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
| POST | `/api/auth/internal/orgs/{org}/sandboxes` | `auth.provisionSandbox` | ADMIN | 200 | no | no |
| DELETE | `/api/auth/internal/orgs/{org}/sandboxes/{id}` | `auth.cancelSandbox` | ADMIN | 200 | no | no |
| POST | `/api/auth/internal/orgs/{org}/sandboxes/{id}/ready` | `auth.finalizeSandbox` | ADMIN | 200 | no | no |
| GET | `/api/auth/internal/orgs/{org}/service-accounts/{id}` | `auth.lookupServiceAccount` | READ | 200, 404 | yes | no |
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
| POST | `/api/auth/orgs/{org}/members/new` | `auth.createMember` | IDENTITY | 201 | no | no |
| DELETE | `/api/auth/orgs/{org}/members/{user}` | `auth.removeMember` | IDENTITY | 204 | no | no |
| PATCH | `/api/auth/orgs/{org}/members/{user}` | `auth.patchMember` | IDENTITY | 200 | no | no |
| POST | `/api/auth/orgs/{org}/owner` | `auth.assignOwner` | IDENTITY | 200 | no | no |
| PUT | `/api/auth/orgs/{org}/plan` | `auth.setOrgPlan` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/auth/orgs/{org}/service-accounts/{id}/rotate` | `auth.rotateServiceAccount` | IDENTITY | 200 | no | no |
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
| GET | `/v3/api-docs` | `auth.openApiSpec` | READ | 200 | yes | no |
| GET | `/actuator/health/liveness` | `codes.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `codes.readiness` | public / authenticated | 200 | yes | yes |
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
| GET | `/actuator/health/liveness` | `fields.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `fields.readiness` | public / authenticated | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/alerts` | `fields.alerts` | ADMIN | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/alerts/config` | `fields.alertConfig` | ADMIN | 200 | yes | no |
| PUT | `/api/fields/universes/{universeId}/alerts/config` | `fields.putAlertConfig` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/alerts/webhook/test` | `fields.testWebhook` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/alerts/{id}/ack` | `fields.ackAlert` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/analytics/daily` | `fields.dailyAnalytics` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/bulk` | `fields.bulk` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/bulk/definitions` | `fields.createBulkDefinition` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/bulk/definitions/{id}` | `fields.bulkDefinition` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/bulk/preview` | `fields.bulkPreview` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/bulk/{id}/reverse` | `fields.reverseBulk` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/commits` | `fields.commitSession` | READ_WRITE | 200 | no | no |
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
| GET | `/api/fields/universes/{universeId}/definitions/{id}/references` | `fields.definitionReferences` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/definitions/{id}/unarchive` | `fields.unarchive` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/environments/{env}/resources` | `fields.environmentResources` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/environments/{env}/resources` | `fields.replaceEnvironmentResources` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/export` | `fields.export` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/fields/batch-get` | `fields.batch` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/flags` | `fields.flags` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/flags` | `fields.createFlag` | READ_WRITE | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/flags/evaluate` | `fields.evaluateFlags` | READ | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/flags/evaluate-batch` | `fields.evaluateFlagsBatch` | READ | 200 | no | no |
| DELETE | `/api/fields/universes/{universeId}/flags/{key}` | `fields.deleteFlag` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/flags/{key}` | `fields.flag` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/flags/{key}` | `fields.updateFlag` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/game-values/{fieldPath}/history` | `fields.gameValueHistory` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/game-values/{fieldPath}/rollback` | `fields.rollbackGameValue` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/generators` | `fields.listGenerators` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/generators` | `fields.createGenerator` | READ_WRITE | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/generators/preview` | `fields.previewGenerator` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/generators/roll` | `fields.rollGenerator` | READ_WRITE | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/generators/simulate` | `fields.simulateGenerator` | READ | 200 | yes | no |
| DELETE | `/api/fields/universes/{universeId}/generators/{key}` | `fields.deleteGenerator` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/generators/{key}` | `fields.getGenerator` | READ | 200 | yes | no |
| PUT | `/api/fields/universes/{universeId}/generators/{key}` | `fields.putGenerator` | READ_WRITE | 200 | no | no |
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
| GET | `/api/fields/universes/{universeId}/maintenance` | `fields.maintenance` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/maintenance` | `fields.putMaintenance` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/migrations/{id}/cancel` | `fields.cancelMigration` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/migrations/{id}/rollback` | `fields.rollbackMigration` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/ops/validate` | `fields.validateOps` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/outbox` | `fields.outbox` | ADMIN | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/outbox/{id}/retry` | `fields.retryOutbox` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/players/changes/batch` | `fields.changesBatch` | READ | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/players/sample` | `fields.samplePlayers` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/search` | `fields.searchPlayers` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{playerId}/randomness/claims` | `fields.playerClaimHistory` | READ | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/players/{playerId}/randomness/rolls` | `fields.playerRollHistory` | READ | 200 | yes | no |
| DELETE | `/api/fields/universes/{universeId}/players/{userId}` | `fields.deletePlayer` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/changes` | `fields.changes` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{userId}/document` | `fields.document` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/players/{userId}/document` | `fields.putDocument` | READ_WRITE | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/export` | `fields.exportPlayer` | READ | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/fields` | `fields.fields` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/players/{userId}/fields/batch-get` | `fields.playerBatch` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/fields/{fieldId}` | `fields.field` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{userId}/ledger` | `fields.ledger` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{userId}/overview` | `fields.playerOverview` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/players/{userId}/presence` | `fields.presence` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/players/{userId}/presence` | `fields.putPresence` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/players/{userId}/receipts` | `fields.receipts` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/players/{userId}/revert` | `fields.revertPlayer` | ADMIN | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/players/{userId}/transactions` | `fields.transaction` | READ_WRITE | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/presence/batch-get` | `fields.presenceBatch` | READ | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/products` | `fields.products` | READ | 200 | yes | yes |
| DELETE | `/api/fields/universes/{universeId}/products/{id}` | `fields.deleteProduct` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/products/{id}` | `fields.product` | READ | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/products/{id}` | `fields.putProduct` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/random-tables` | `fields.listRandomTables` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/random-tables` | `fields.createRandomTable` | READ_WRITE | 200 | no | no |
| DELETE | `/api/fields/universes/{universeId}/random-tables/{key}` | `fields.deleteRandomTable` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/random-tables/{key}` | `fields.getRandomTable` | READ | 200 | yes | no |
| PUT | `/api/fields/universes/{universeId}/random-tables/{key}` | `fields.putRandomTable` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/random-tables/{key}/odds` | `fields.tableOdds` | READ | 200 | yes | no |
| DELETE | `/api/fields/universes/{universeId}/randomness` | `fields.eraseRandomness` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/randomness/definitions/{key}/history` | `fields.randomDefinitionHistory` | READ | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/randomness/fields` | `fields.randomnessFields` | READ | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/randomness/schema` | `fields.randomnessSchema` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/receipts` | `fields.purchase` | READ_WRITE | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/receipts/{purchaseId}` | `fields.receipt` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/receipts/{purchaseId}/refund` | `fields.refund` | ADMIN | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/reconcile` | `fields.reconcile` | ADMIN | 200 | yes | yes |
| PUT | `/api/fields/universes/{universeId}/references/{consumerType}` | `fields.replaceReferencesBatch` | READ_WRITE | 204 | no | no |
| DELETE | `/api/fields/universes/{universeId}/references/{consumerType}/{consumerId}` | `fields.deleteReferences` | READ_WRITE | 204 | yes | no |
| PUT | `/api/fields/universes/{universeId}/references/{consumerType}/{consumerId}` | `fields.putReferences` | READ_WRITE | 204 | yes | no |
| GET | `/api/fields/universes/{universeId}/rotations` | `fields.listRotations` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/rotations` | `fields.createRotation` | READ_WRITE | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/rotations/claim` | `fields.claimRotation` | READ_WRITE | 200 | keyed | no |
| GET | `/api/fields/universes/{universeId}/rotations/instances/{id}/stock` | `fields.rotationStock` | READ | 200 | yes | no |
| DELETE | `/api/fields/universes/{universeId}/rotations/{key}` | `fields.deleteRotation` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/rotations/{key}` | `fields.getRotation` | READ | 200 | yes | no |
| PUT | `/api/fields/universes/{universeId}/rotations/{key}` | `fields.putRotation` | READ_WRITE | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/rotations/{key}/active` | `fields.activeRotation` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/rotations/{key}/advance` | `fields.advanceRotation` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/rotations/{key}/history` | `fields.rotationHistory` | READ | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/rotations/{key}/reroll` | `fields.rerollRotation` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/runtime/snapshot` | `fields.runtimeSnapshot` | READ | 200, 304 | yes | no |
| GET | `/api/fields/universes/{universeId}/schedules` | `fields.schedules` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/schedules` | `fields.createSchedule` | ADMIN | 200 | keyed | no |
| POST | `/api/fields/universes/{universeId}/schedules/preview` | `fields.schedulePreview` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/schedules/{id}` | `fields.schedule` | ADMIN | 200 | yes | no |
| PUT | `/api/fields/universes/{universeId}/schedules/{id}` | `fields.editSchedule` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/schedules/{id}/actions` | `fields.scheduleActions` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/schedules/{id}/cancel` | `fields.cancelSchedule` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/schedules/{id}/definition` | `fields.scheduleDefinition` | ADMIN | 200 | yes | no |
| POST | `/api/fields/universes/{universeId}/schedules/{id}/end-now` | `fields.endSchedule` | ADMIN | 200 | no | no |
| GET | `/api/fields/universes/{universeId}/schedules/{id}/runs` | `fields.scheduleRuns` | READ | 200 | yes | no |
| GET | `/api/fields/universes/{universeId}/schema` | `fields.schema` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/schema/luau` | `fields.luau` | READ | 200 | yes | yes |
| GET | `/api/fields/universes/{universeId}/schema/typescript` | `fields.typescript` | READ | 200 | yes | yes |
| POST | `/api/fields/universes/{universeId}/sessions/acquire` | `fields.acquireSessions` | READ_WRITE | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/sessions/poll` | `fields.pollSessions` | READ_WRITE | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/sessions/release` | `fields.releaseSessions` | READ_WRITE | 200 | no | no |
| POST | `/api/fields/universes/{universeId}/sessions/renew` | `fields.renewSessions` | READ_WRITE | 200 | no | no |
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
| GET | `/v3/api-docs` | `fields.openApiSpec` | READ | 200 | yes | no |
| GET | `/actuator/health/liveness` | `leaderboards.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `leaderboards.readiness` | public / authenticated | 200 | yes | yes |
| POST | `/api/leaderboards/ratings/universes/{universeId}/matches` | `leaderboards.ratingMatch` | READ_WRITE | 200 | keyed | no |
| GET | `/api/leaderboards/ratings/universes/{universeId}/ratings` | `leaderboards.ratingScopes` | READ | 200 | yes | yes |
| GET | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/config` | `leaderboards.ratingConfig` | ADMIN | 200 | yes | yes |
| PUT | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/config` | `leaderboards.ratingConfigure` | ADMIN | 200 | no | no |
| PUT | `/api/leaderboards/ratings/universes/{universeId}/ratings/{scope}/label` | `leaderboards.ratingLabel` | ADMIN | 200 | no | no |
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
| GET | `/api/matchmaking/criteria-types` | `matchmaking.getCriteriaTypes` | READ | 200 | yes | yes |
| POST | `/api/matchmaking/criteria/simulate` | `matchmaking.simulateCriteria` | READ_WRITE | 200 | no | no |
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
| GET | `/actuator/health/liveness` | `platform.liveness` | public / authenticated | 200 | yes | no |
| GET | `/actuator/health/readiness` | `platform.readiness` | public / authenticated | 200 | yes | no |
| POST | `/api/metering/events` | `platform.ingestUsage` | READ_WRITE | 200 | no | no |
| GET | `/api/openapi.json` | `platform.openapi` | READ | 200 | yes | no |
| GET | `/api/orgs/{org}/invoices` | `platform.invoices` | IDENTITY | 200 | yes | no |
| GET | `/api/orgs/{org}/limits` | `platform.limits` | IDENTITY | 200 | yes | no |
| GET | `/api/orgs/{org}/plan` | `platform.orgPlan` | IDENTITY | 200 | yes | no |
| PUT | `/api/orgs/{org}/plan` | `platform.setOrgPlan` | IDENTITY | 200 | no | no |
| DELETE | `/api/orgs/{org}/ratelimits` | `platform.resetRateLimits` | SUPER_ADMIN | 204 | no | no |
| GET | `/api/orgs/{org}/ratelimits` | `platform.rateLimits` | IDENTITY | 200 | yes | no |
| PUT | `/api/orgs/{org}/ratelimits` | `platform.setRateLimits` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/orgs/{org}/sandbox` | `platform.sandbox` | IDENTITY | 201 | no | no |
| DELETE | `/api/orgs/{org}/service-accounts/{id}/ratelimit` | `platform.resetKeyRateLimit` | SUPER_ADMIN | 204 | no | no |
| PUT | `/api/orgs/{org}/service-accounts/{id}/ratelimit` | `platform.setKeyRateLimit` | SUPER_ADMIN | 200 | no | no |
| GET | `/api/orgs/{org}/usage` | `platform.usage` | IDENTITY | 200 | yes | no |
| GET | `/api/ping` | `platform.ping` | READ | 200 | yes | no |
| GET | `/api/plans` | `platform.plans` | public / authenticated | 200 | yes | no |
| POST | `/api/plans` | `platform.createPlan` | SUPER_ADMIN | 201 | no | no |
| PUT | `/api/plans` | `platform.putPlan` | SUPER_ADMIN | 200 | no | no |
| DELETE | `/api/plans/{name}` | `platform.deletePlan` | SUPER_ADMIN | 204 | no | no |
| PUT | `/api/plans/{name}` | `platform.updatePlan` | SUPER_ADMIN | 200 | no | no |
| GET | `/api/status` | `platform.status` | public / authenticated | 200 | yes | no |
| GET | `/api/status/incidents` | `platform.incidents` | SUPER_ADMIN | 200 | yes | no |
| POST | `/api/status/incidents` | `platform.createIncident` | SUPER_ADMIN | 201 | no | no |
| DELETE | `/api/status/incidents/{id}` | `platform.deleteIncident` | SUPER_ADMIN | 204 | no | no |
| PUT | `/api/status/incidents/{id}` | `platform.updateIncident` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/universes/{universeId}/analytics/backfill` | `platform.backfillAnalytics` | ADMIN | 200 | no | no |
| GET | `/api/universes/{universeId}/analytics/economy` | `platform.analyticsEconomy` | READ | 200 | yes | no |
| GET | `/api/universes/{universeId}/analytics/summary` | `platform.analyticsSummary` | READ | 200 | yes | no |
| GET | `/api/universes/{universeId}/analytics/timeseries` | `platform.analyticsTimeseries` | READ | 200 | yes | no |
| GET | `/api/universes/{universeId}/webhooks` | `platform.webhooks` | READ | 200 | yes | no |
| POST | `/api/universes/{universeId}/webhooks` | `platform.createWebhook` | READ_WRITE | 201 | no | no |
| DELETE | `/api/universes/{universeId}/webhooks/{id}` | `platform.deleteWebhook` | READ_WRITE | 204 | no | no |
| GET | `/api/universes/{universeId}/webhooks/{id}` | `platform.webhook` | READ | 200 | yes | no |
| PUT | `/api/universes/{universeId}/webhooks/{id}` | `platform.updateWebhook` | READ_WRITE | 200 | no | no |
| GET | `/api/universes/{universeId}/webhooks/{id}/deliveries` | `platform.webhookDeliveries` | READ | 200 | yes | no |
| POST | `/api/universes/{universeId}/webhooks/{id}/deliveries/{deliveryId}/redeliver` | `platform.redeliverWebhook` | READ_WRITE | 200 | no | no |
| POST | `/api/universes/{universeId}/webhooks/{id}/test` | `platform.testWebhook` | READ_WRITE | 200 | no | no |
| GET | `/health` | `platform.healthProxy` | public / authenticated | 200 | yes | no |
| GET | `/info` | `platform.info` | public / authenticated | 200 | yes | no |
| POST | `/internal/events` | `platform.publishEvent` | READ_WRITE | 200 | no | no |
| GET | `/internal/ratelimits/{orgId}` | `platform.gatewayRateLimits` | READ | 200 | yes | no |
| GET | `/metrics` | `platform.metrics` | public / authenticated | 200 | yes | no |
