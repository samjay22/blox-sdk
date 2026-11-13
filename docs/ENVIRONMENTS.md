# Dev and prod

Every universe has exactly two environments, **`dev`** and **`prod`**. They never share data: Fields definitions and player
data, config namespaces and item lists, history and counters exist once per environment. A new universe starts with an
empty dev; everything that existed before environments is prod.

## The key decides

An API key is bound to one environment for life, and the SDK talks to that environment. There is no environment parameter
on any SDK call and no way to switch a client.

| Prefix | Environment | `client.environment` | Grants it can hold |
|---|---|---|---|
| `bsa_` | prod (all existing keys) | `"prod"` | any service |
| `bsd_` | dev | `"dev"` | `FieldsService`, `ConfigService` and `Gateway` only |

Both are 56 bytes. Any other prefix is rejected by `BloxSDK.new` with `Unknown API key prefix: expected bsa_ (prod) or bsd_
(dev)`. `client.environment` is `nil` for clients built from a user session (portal tooling), because no key is involved.

Create keys in the portal (choose the environment when you create the key). Other services (Matchmaking, Party, Codes,
Audit, Leaderboards, Platform, Auth) do not have environments yet and refuse dev keys, so a dev key only reaches Fields,
Config and the gateway.

```luau
local client = BloxSDK.new({ secretName = "BLOX_DEV_KEY", environment = "dev" })
print(client.environment) -- "dev"
```

A readable `key = "bsd_..."` carries its environment in its prefix, so `environment` is not accepted with `key`. A Roblox
Secret is opaque and cannot be inspected locally: with `secretName` you must say which environment the secret holds
(`environment = "dev"` or `"prod"`). The backend still decides by the real key, so a wrong claim only affects the local
Studio check below, never which data you reach.

## Studio protection

In Roblox Studio (`RunService:IsStudio()`), constructing a client with a prod key fails before a secret is read or a
request exists:

```
prod_key_in_studio: a prod (bsa_) key is not used in Roblox Studio; use a dev (bsd_) key or pass allowProdInStudio = true
```

Dev keys work anywhere. In a live game server both work. To use prod from Studio on purpose (reading a live config while
building, say), opt in explicitly:

```luau
local client = BloxSDK.new({ secretName = "BLOX_KEY", environment = "prod", allowProdInStudio = true })
```

The check also covers a custom `authProvider` that declares `environment = "prod"`.

### Testing the check, and offline mode

The Studio test is injectable like `runtime` and `backend`: pass `isStudio = function() return true end`. Clients that
inject a `runtime` (every offline or mock client, including the ones built on `BloxSDK/Testing`) are never treated as Studio
unless you pass `isStudio`, so unit tests and fake backends keep working with prod-shaped test keys.

```luau
-- fails with prod_key_in_studio
BloxSDK.new({ key = prodKey, universeId = 123, runtime = rt, backend = fake, isStudio = function() return true end })
```

## Recommended pattern

* Studio and test places: a `bsd_` dev key. Build and break things freely; dev has small caps (see below).
* Live servers: a `bsa_` prod key, stored in a Roblox Secret.
* Promote reviewed changes from dev to prod in the portal, on the **Transfer** page. Promotion never happens from the SDK.

## Dev limits

| What | dev | prod |
|---|---|---|
| Field definitions per universe | 100 | unchanged |
| Config namespaces / entries per namespace | 20 / 200 | 100 / 1000 |
| Requests per key per minute | at most 600 | plan limit |

Going over a dev cap is `409 dev_limit_exceeded` (kind `Conflict`, not retried). A dev namespace count over its limit is the
ordinary `limit_exceeded`.

## Universe ids in dev responses

Dev data is stored under the universe id plus 2^60, and some dev responses echo that scope id in `universeId`. The SDK
decodes every `universeId` and `robloxUniverseId` member exactly and hands you the **logical** Roblox universe id (the
echo minus 2^60), as a number or as a string, whichever the wire used. It is never an error, and a prod id passes through
unchanged. `Universe`-level checks in the SDK (`withUniverse`, request/universe mismatch) keep comparing logical ids.

## Not available from the SDK (portal and HTTP only)

Transfer (compare, preflight, apply, history, undo) and dev reset need a signed-in user token with ConfigService and
FieldsService ADMIN; a machine key gets `403 transfer_requires_user`. They are not SDK methods. The SDK also never sends
`X-Blox-Environment`, which only portal routes use; `environment_invalid` and `environment_required` are portal-only
codes, and `environment_mismatch` means a request named an environment other than the key's.

## Usage and billing

Dev usage is recorded with `environment: "dev"` and is never billed. Invoices count prod only. The right-to-erasure
webhook deletes a player's data in both environments.

## Error codes

`dev_limit_exceeded`, `environment_mismatch`, `environment_invalid`, `environment_required` (backend) and
`prod_key_in_studio` (local). None is retried; see [errors](ERRORS.md#environment-codes-dev-and-prod).
