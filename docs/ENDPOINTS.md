# Endpoint reference

234 endpoints. `routes.json` coverage is checked independently.

Default gateway: `https://lb1.blox-api.com`. Override once with `gatewayUrl`.

| Service | Gateway stripPrefix |
|---|---|
| `auth` | `/auth-service` |
| `data` | `/data-service` |
| `matchmaking` | `/matchmaking-service` |
| `party` | `/party-service` |
| `codes` | `/code-service` |
| `audit` | `/audit-service` |
| `config` | `/remote-config-service` |
| `leaderboards` | `/leaderboard-service` |
| `economy` | `/economy-service` |

Paths below are backend-relative: wire URL = gateway + service prefix + path. Config uses `/remote-config-service`, never `/config-service` (the gateway reserves `/config*`). An explicit `services = { data = { baseUrl = "https://direct.example" } }` bypasses the gateway and prefix for that service only. See [routing configuration](../README.md#gateway-routing).

Request shapes are exported in `src/Types`. Body-only endpoints accept the DTO directly; mixed endpoints use `{path=..., query=..., body=...}`. Statuses below are controller success/branch statuses, not exhaustive domain errors.

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
| GET | `/api/auth/accounts` | `auth.getAllAccounts` | ADMIN | 200 | yes | no |
| POST | `/api/auth/accounts` | `auth.createAccount` | public / authenticated | 201 | no | no |
| POST | `/api/auth/accounts/admin` | `auth.createAdminAccount` | SUPER_ADMIN | 201 | no | no |
| GET | `/api/auth/accounts/me` | `auth.getMe` | USER | 200 | yes | no |
| POST | `/api/auth/accounts/universe-account` | `auth.createUniverseAccount` | ADMIN | 201 | no | no |
| GET | `/api/auth/accounts/username/{username}` | `auth.getAccountByUsername` | ADMIN | 200 | yes | no |
| DELETE | `/api/auth/accounts/{accountId}` | `auth.deleteAccountRest` | USER | 204 | no | no |
| GET | `/api/auth/accounts/{accountId}` | `auth.getAccountById` | USER | 200 | yes | no |
| PUT | `/api/auth/accounts/{accountId}` | `auth.updateAccount` | USER | 200 | no | no |
| POST | `/api/auth/accounts/{accountId}/delete` | `auth.deleteAccount` | USER | 204 | no | no |
| PATCH | `/api/auth/accounts/{accountId}/enable` | `auth.enableAccount` | ADMIN | 200 | no | no |
| GET | `/api/auth/accounts/{accountId}/permissions` | `auth.listPermissions` | ADMIN | 200 | yes | no |
| PUT | `/api/auth/accounts/{accountId}/permissions` | `auth.upsertPermission` | ADMIN | 200 | no | no |
| DELETE | `/api/auth/accounts/{accountId}/permissions/{serviceName}` | `auth.deletePermissionRest` | ADMIN | 204 | no | no |
| POST | `/api/auth/accounts/{accountId}/permissions/{serviceName}/delete` | `auth.deletePermission` | ADMIN | 204 | no | no |
| PATCH | `/api/auth/accounts/{accountId}/promote` | `auth.promoteAccount` | ADMIN | 200 | no | no |
| GET | `/api/auth/health` | `auth.health` | public / authenticated | 200 | yes | no |
| POST | `/api/auth/login` | `auth.login` | public / authenticated | 200 | no | no |
| POST | `/api/auth/logout` | `auth.logout` | public / authenticated | 200 | no | no |
| POST | `/api/auth/password/change` | `auth.changePassword` | USER | 200 | no | no |
| POST | `/api/auth/password/reset/confirm` | `auth.confirmReset` | public / authenticated | 200 | no | no |
| POST | `/api/auth/password/reset/request` | `auth.requestReset` | public / authenticated | 200 | no | no |
| POST | `/api/auth/refresh` | `auth.refresh` | public / authenticated | 200 | no | no |
| GET | `/api/auth/service-accounts` | `auth.listServiceAccounts` | SUPER_ADMIN | 200 | yes | no |
| POST | `/api/auth/service-accounts` | `auth.createServiceAccount` | SUPER_ADMIN | 201 | no | no |
| DELETE | `/api/auth/service-accounts/{id}` | `auth.revokeServiceAccount` | SUPER_ADMIN | 204 | no | no |
| GET | `/api/auth/service-accounts/{id}` | `auth.getServiceAccount` | SUPER_ADMIN | 200 | yes | no |
| PATCH | `/api/auth/service-accounts/{id}` | `auth.patchServiceAccount` | SUPER_ADMIN | 200 | no | no |
| PUT | `/api/auth/service-accounts/{id}/permissions` | `auth.setServiceAccountPermissions` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/auth/service-accounts/{id}/rotate` | `auth.rotateServiceAccount` | SUPER_ADMIN | 200 | no | no |
| GET | `/api/auth/services` | `auth.listServices` | public / authenticated | 200 | yes | no |
| POST | `/api/auth/services` | `auth.createService` | SUPER_ADMIN | 201 | no | no |
| DELETE | `/api/auth/services/{name}` | `auth.deleteService` | SUPER_ADMIN | 204 | no | no |
| PUT | `/api/auth/services/{name}` | `auth.updateService` | SUPER_ADMIN | 200 | no | no |
| POST | `/api/auth/token/validate` | `auth.validateToken` | public / authenticated | 200, 401 | no | no |
| GET | `/api/auth/universes` | `auth.getUniverses` | ADMIN | 200 | yes | yes |
| POST | `/api/auth/universes` | `auth.createUniverse` | ADMIN | 201 | no | no |
| DELETE | `/api/auth/universes/{universeId}` | `auth.deleteUniverseRest` | ADMIN | 204 | no | no |
| GET | `/api/auth/universes/{universeId}` | `auth.getUniverse` | READ | 200 | yes | yes |
| PATCH | `/api/auth/universes/{universeId}` | `auth.setEnabled` | ADMIN | 204 | no | no |
| PUT | `/api/auth/universes/{universeId}` | `auth.updateUniverse` | ADMIN | 200 | no | no |
| POST | `/api/auth/universes/{universeId}/delete` | `auth.deleteUniverse` | ADMIN | 204 | no | no |
| GET | `/api/auth/universes/{universeId}/places` | `auth.listPlaces` | READ | 200 | yes | yes |
| POST | `/api/auth/universes/{universeId}/places` | `auth.addPlace` | READ_WRITE | 201 | no | no |
| DELETE | `/api/auth/universes/{universeId}/places/{placeId}` | `auth.deletePlaceRest` | READ_WRITE | 204 | no | no |
| GET | `/api/auth/universes/{universeId}/places/{placeId}` | `auth.getPlace` | READ | 200 | yes | yes |
| PUT | `/api/auth/universes/{universeId}/places/{placeId}` | `auth.updatePlace` | READ_WRITE | 200 | no | no |
| POST | `/api/auth/universes/{universeId}/places/{placeId}/delete` | `auth.deletePlace` | READ_WRITE | 204 | no | no |
| GET | `/health` | `auth.healthProxy` | public / authenticated | 200 | yes | no |
| GET | `/api/codes` | `codes.searchCodes` | READ | 200 | yes | yes |
| POST | `/api/codes` | `codes.createCode` | ADMIN | 201 | no | no |
| POST | `/api/codes/redeem` | `codes.redeem` | READ_WRITE | 200 | no | no |
| DELETE | `/api/codes/{id}` | `codes.deleteCode` | ADMIN | 204 | no | no |
| GET | `/api/codes/{id}` | `codes.getCode` | READ | 200 | yes | yes |
| PUT | `/api/codes/{id}` | `codes.updateCode` | ADMIN | 200 | no | no |
| GET | `/api/codes/{id}/redemptions` | `codes.listRedemptions` | ADMIN | 200 | yes | yes |
| GET | `/health` | `codes.healthProxy` | public / authenticated | 200 | yes | yes |
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
| GET | `/api/admin/backups` | `data.listSnapshots` | ADMIN | 200 | yes | yes |
| POST | `/api/admin/backups` | `data.createManualSnapshot` | ADMIN | 200 | no | no |
| POST | `/api/admin/backups/trigger-all` | `data.triggerScheduledBackup` | ADMIN | 200 | no | no |
| GET | `/api/admin/backups/universe/{universeId}` | `data.getSnapshotsByUniverse` | ADMIN | 200 | yes | yes |
| DELETE | `/api/admin/backups/{snapshotId}` | `data.deleteSnapshot` | ADMIN | 200 | no | no |
| GET | `/api/admin/backups/{snapshotId}` | `data.getSnapshot` | ADMIN | 200 | yes | yes |
| POST | `/api/admin/backups/{snapshotId}/rollback` | `data.rollbackToSnapshot` | ADMIN | 200 | no | no |
| GET | `/api/admin/pending-updates` | `data.getPendingUpdates` | ADMIN | 200 | yes | yes |
| GET | `/api/admin/schema-migrations` | `data.getAllSchemaMigrations` | ADMIN | 200 | yes | yes |
| GET | `/api/admin/schema-versions` | `data.getAllSchemaVersions` | ADMIN | 200 | yes | yes |
| GET | `/api/admin/user-data` | `data.getAllUserData` | ADMIN | 200 | yes | yes |
| GET | `/api/admin/user-data/grouped` | `data.getAllUserDataGroupedByUniverse` | ADMIN | 200 | yes | yes |
| GET | `/api/admin/users/{robloxUserId}/data` | `data.getUserDataByRobloxUserId` | ADMIN | 200 | yes | yes |
| POST | `/api/auth/login` | `data.login` | public / authenticated | 200 | no | no |
| POST | `/api/auth/logout` | `data.logout` | public / authenticated | 200 | no | no |
| POST | `/api/auth/refresh` | `data.refreshToken` | public / authenticated | 200 | no | no |
| POST | `/api/universes/schema` | `data.createOrUpdateSchema` | ADMIN | 201 | no | no |
| GET | `/api/universes/schema/defaults` | `data.getSchemaDefaults` | READ | 200 | yes | yes |
| GET | `/api/universes/schema/versions` | `data.getSchemaVersions` | READ | 200 | yes | yes |
| GET | `/api/universes/users/data` | `data.getAllUserDataForUniverse` | READ | 200 | yes | yes |
| PUT | `/api/universes/users/data/bulk` | `data.bulkUpdateUserData` | READ_WRITE | 200 | no | no |
| POST | `/api/universes/users/data/sync` | `data.syncUserDataBatch` | READ_WRITE | 200 | no | no |
| DELETE | `/api/universes/users/{robloxUserId}/data` | `data.deleteUserData` | READ_WRITE | 204 | no | no |
| GET | `/api/universes/users/{robloxUserId}/data` | `data.getUserData` | READ | 200 | no | no |
| POST | `/api/universes/users/{robloxUserId}/data` | `data.createUserData` | READ_WRITE | 201 | no | no |
| PUT | `/api/universes/users/{robloxUserId}/data` | `data.updateUserData` | READ_WRITE | 200 | no | no |
| GET | `/health` | `data.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/liveness` | `economy.liveness` | public / authenticated | 200 | yes | yes |
| GET | `/actuator/health/readiness` | `economy.readiness` | public / authenticated | 200 | yes | yes |
| POST | `/api/economy/universes/{universeId}/balances/batch` | `economy.batch` | READ | 200 | no | no |
| GET | `/api/economy/universes/{universeId}/currencies` | `economy.currencies` | READ | 200 | yes | yes |
| PATCH | `/api/economy/universes/{universeId}/currencies` | `economy.patchCurrency` | ADMIN | 200 | no | no |
| POST | `/api/economy/universes/{universeId}/currencies` | `economy.createCurrency` | ADMIN | 201 | no | no |
| GET | `/api/economy/universes/{universeId}/ledger/{entryId}` | `economy.entry` | READ | 200 | yes | yes |
| POST | `/api/economy/universes/{universeId}/ledger/{entryId}/reverse` | `economy.reverse` | ADMIN | 200 | keyed | no |
| GET | `/api/economy/universes/{universeId}/products` | `economy.products` | READ | 200 | yes | yes |
| DELETE | `/api/economy/universes/{universeId}/products/{robloxProductId}` | `economy.deleteProduct` | ADMIN | 204 | no | no |
| GET | `/api/economy/universes/{universeId}/products/{robloxProductId}` | `economy.product` | READ | 200 | yes | yes |
| PUT | `/api/economy/universes/{universeId}/products/{robloxProductId}` | `economy.putProduct` | ADMIN | 200 | no | no |
| POST | `/api/economy/universes/{universeId}/receipts` | `economy.receipt` | READ_WRITE | 200 | keyed | no |
| POST | `/api/economy/universes/{universeId}/receipts/{purchaseId}/refund` | `economy.refund` | ADMIN | 200 | keyed | no |
| GET | `/api/economy/universes/{universeId}/reconcile` | `economy.reconcile` | ADMIN | 200 | yes | yes |
| POST | `/api/economy/universes/{universeId}/transfer` | `economy.transfer` | READ_WRITE | 200 | keyed | no |
| POST | `/api/economy/universes/{universeId}/users/{userId}/adjust` | `economy.adjust` | ADMIN | 200 | keyed | no |
| GET | `/api/economy/universes/{universeId}/users/{userId}/balances` | `economy.balances` | READ | 200 | yes | yes |
| GET | `/api/economy/universes/{universeId}/users/{userId}/balances/{code}` | `economy.balance` | READ | 200 | yes | yes |
| POST | `/api/economy/universes/{universeId}/users/{userId}/grant` | `economy.grant` | READ_WRITE | 200 | keyed | no |
| GET | `/api/economy/universes/{universeId}/users/{userId}/ledger` | `economy.ledger` | READ | 200 | yes | yes |
| POST | `/api/economy/universes/{universeId}/users/{userId}/spend` | `economy.spend` | READ_WRITE | 200 | keyed | no |
| GET | `/health` | `economy.healthProxy` | public / authenticated | 200 | yes | yes |
| GET | `/info` | `economy.info` | public / authenticated | 200 | yes | yes |
| GET | `/metrics` | `economy.metrics` | public / authenticated | 200 | yes | yes |
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
| POST | `/api/bans/cleanup` | `matchmaking.removeExpiredBans` | ADMIN | 200 | no | no |
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
| GET | `/api/roblox/keys` | `matchmaking.getAllApiKeys` | ADMIN | 200 | yes | no |
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
| GET | `/api/universes/getAllUniverses` | `matchmaking.getAllUniverses` | ADMIN | 200 | yes | yes |
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
