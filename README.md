# BloxSDK

One server-side, strict Luau SDK for **Auth, Matchmaking, Party, Codes, Audit, Config, Leaderboards, and Fields**.

**279 typed endpoints:** every route in `routes.json`, including the organization-tenant Auth API and bulk Codes generation/batch export. Includes 33 durable Fields job, migration, bulk/import/export, schedule, alert and health routes. No runtime dependencies or client-side credentials.

> **Credentials:** game servers should use **`bsa_` service-account keys**, never human logins.
> Humans/tools use **identity login for management, then `client:scoped(universeId)` for downstream calls**.
> See [tenant authentication, role templates and error codes](docs/AUTH.md).
>
> **Gateway permissions:** callers using `lb1` need **`Gateway` in addition to the target service
> permission**. Code redemption also needs Fields write access; Matchmaking enrichment needs Fields
> READ access. **`bsa_` service-account keys are universe-bound.** SDK `levels` are hints, not grants.

## Install

Use the checked-in `roblox/` package with Rojo:

```sh
rojo build default.project.json -o BloxSDK.rbxm
```

Insert the resulting ModuleScript into **ServerScriptService** or **ServerStorage**, never ReplicatedStorage. Alternatively, map `roblox/` into your game's Rojo tree. `wally.toml` describes a server-only package; this repository has **not** been published to a registry.

Enable outbound HTTP and configure a Roblox secret permitted for `lb1.blox-api.com` (or your explicit override destinations). This is a server SDK; requiring it does not start a loop or send a request.

```luau
local BloxSDK = require(game.ServerScriptService.BloxSDK)
local client = BloxSDK.new({
    secretName = "BLOX_SERVICE_ACCOUNT",
    universeId = game.GameId,
    levels = { -- Optional deployment metadata, not an authorization grant.
        FieldsService = "READ_WRITE",
        MatchmakingService = "READ_WRITE",
        PartyService = "READ_WRITE",
        CodeService = "READ_WRITE",
    },
})

local loaded = client.fields:LoadProfile(game.GameId, 123456)
if loaded.ok then
    local profile = loaded.value
    local committed = profile:Transaction():Add("Currency.Gems", 10):Reason("Quest reward"):Commit()
    if not committed.ok then warn(committed.error.code) end
end

game:BindToClose(function()
    -- Finish issuing your saves before flush: flush closes admission permanently.
    client:flush(20)
    client:destroy()
end)
```

`secret:AddPrefix("Bearer ")` is passed directly as the header value. The secret is never coerced to a string. Plain `key = "bsa_..."` is supported for Studio/tests; supply it securely, never hardcode it. Readable keys are validated against the backend's exact 56-character format. Opaque Secrets cannot be inspected locally.

## Calls and results

The eight facades are `client.auth`, `.matchmaking`, `.party`, `.codes`, `.audit`, `.config`, `.leaderboards`, and `.fields`. All route wrappers are generated from `spec/endpoints.json`; Fields gameplay helpers, the Codes award builder and the scoped-token cache are hand-written.

- Body-only endpoints take the DTO directly: `client.party:createParty({ownerId=123, placeId=456})`.
- Mixed endpoints take `{path=..., query=..., body=...}`. Path and query values are separately encoded.
- Optional requests can be omitted: `client.codes:searchCodes()`.
- `client:withUniverse(id)` shares the original client's auth, queue, rate budget, breakers, cache, and lifetime. It fills **declared path/query universe parameters** and implied Audit event universes, not arbitrary body fields. Supply other required body universe fields explicitly. Universe IDs must be positive exact integers. A service key cannot switch universes.
- `client:health()` checks `<service-prefix>/health` on the gateway for all eight services (or `/health` on an explicit direct host) and returns `{result, latency}` per service. HTTP status is on `result.status` or `result.error.status`; backend health is in `result.value`.
- `client:metrics()` returns an immutable counter/histogram snapshot.

```luau
local joined = client.matchmaking:joinQueue({
    robloxUniverseId = tostring(game.GameId),
    robloxUserIds = { tostring(player.UserId) },
    gameModeName = "ranked",
}, { priority = "critical", deadline = os.clock() + 5 })
```

`Result<T>` is `{ok=true,value:T,status?,stale?}` or `{ok=false,error:BloxError}`. HTTP/network failures return results rather than throwing. Invalid construction config throws a value-free assertion. Errors include kind, HTTP status when available, endpoint ID, attempt count, and a **fully redacted** error body. There is deliberately no raw-response debug logging.

`CallOptions`: absolute monotonic `deadline`, `priority` (`critical`/`bulk`), maximum `retry` count, explicit `idempotencyHint`, optional `cacheTtl` in seconds, and `signal={cancelled=false}`. `idempotencyHint` is retained for compatibility but cannot bypass retry safety. Unkeyed non-idempotent mutations are never automatically retried.

Responses shared by cache/single-flight are recursively frozen. Clone before editing. `BloxSDK.null` represents an explicit JSON null (e.g. clearing service-account expiration). `BloxSDK.array({})` marks an empty array in arbitrary JSON; declared DTO array fields are encoded correctly automatically.

## New service helpers

- `client:auditWriter(...)`: bounded, nonblocking enqueue/flush; max 500 events per batch, interval flush and native Roblox BindToClose integration.
- `client:configSnapshot(30)`: conditional snapshot polling, synchronous `Get`/`IsEnabled`, `Changed` signal, last-good-state retention. `IsEnabled` reads the master switch, not per-user rollout rules.
- Cursor endpoints expose `<method>Pages(...)` iterators returning page Results.
- Fields required-key operations, leaderboard submissions and audit events generate omitted idempotency keys **once per logical call and reuse them across retries**. Persist caller-supplied keys for retries across separate calls/restarts.
- Fields includes a strict TypeSystem, schema cache, validated transactions, profile/presence lifecycle and offline schema-specialized typed accessor codegen. Unsafe int64 values fail closed, never round. See [Fields guide](docs/FIELDS.md).
- Fields `Bulk`, `Schedules`, and `Jobs` helpers add typed request validation and bounded `Jobs:waitFor` polling. **Server/admin-key usage only**, including previews, job reads and export/downloads; `Health:summary()` alone needs READ. Never expose an ADMIN key or these controls to game clients. See [durable jobs guide](docs/JOBS.md) and [game-server example](examples/fields-jobs.luau).

See [new-service guide](docs/NEW-SERVICES.md) and the Fields examples for lifecycle and safety details.

## Fields validation and Code awards

`client.fields:validateOps({body={ops=...}})` accepts 1–100 subject-free operations after explicitly
loading `client.fields:Schema(universeId):Load()`. It pre-validates through TypeSystem, collects every
failing op with zero-based `opIndex/field/path/code`, and sends locally valid lists to Fields for current
validation. `client.fields:Operations(universeId):Add("Currency.Gems",100):validate()` and player
transaction `:validate()` provide dry runs without a reason, key or commit. No player state is read.

Codes now take `award` directly as a list of Fields operations. Use
`client.codes:Award(universeId):Add("Currency.Gems",100):build()` for a typed canonical snapshot;
`createCode` also pre-validates raw lists. Redemption returns `transaction`, `replayed`, `redeemedAt`;
CodeService applies one atomic transaction using `code-<codeId>-<userId>`. The per-user maximum must be 1.
See [Codes guide](docs/CODES.md), [award example](examples/code-award.luau), and [Fields guide](docs/FIELDS.md).

Matchmaking criteria read server-fetched Fields computed values. Use top-level computed IDs (`Elo`,
`Level`), not dotted paths or caller-supplied metadata. See [criteria and failure semantics](docs/MATCHMAKING.md).

## Static field types

Save an authorized `GET /schema` response, then run the offline standard-library-only generator:

```sh
python3 tools/gen-field-types saved-schema.json --out game/GeneratedFields --sdk ../../roblox
```

Require generated `Typed` and `FieldTypes` modules. `Typed.Currency.Gems:Get(profile)` is `number`,
`:Add(tx, delta)` requires a number, map/list accessors enforce their schema's key/item types.
Every accessor queues through the validated transaction builder. See [complete workflow, Roblox
projection, null/set conversion, int64 limits and examples](docs/FIELDS.md).

## Human/tool identity and organization administration

```luau
local admin = BloxSDK.new({ userSession = {} })
local login = admin.auth:login({ username = suppliedUsername, password = suppliedPassword })
if login.ok then
    local access = admin.auth:getMyAccess()
    local accounts = admin.auth:listServiceAccounts({ query = { orgId = selectedOrgId } })
    local scoped = admin:scoped(selectedUniverseId)
    local schema = scoped.fields:schema() -- Exchanges once; caches and refreshes early.
    -- Do not log login, createServiceAccount, or rotateServiceAccount responses.
end
admin:logout() -- Uses the latest rotated refresh token and clears the local session.
admin:destroy()
```

Identity refresh and per-universe scoped exchange are separate, versioned and single-flight. `scoped(id)` returns a lazy downstream facade sharing routing, rate budget and lifetime; keep the root client for management. `withUniverse(id)` only fills route parameters and does not exchange credentials. Scoped JWTs cannot manage organizations or keys. A caller can time out without cancelling another caller's shared refresh. Custom synchronous TokenStores are supported; see [AUTH](docs/AUTH.md).

## Defaults

| Policy | Default |
|---|---|
| Gateway | `https://lb1.blox-api.com` + per-service prefix below |
| Timeout | 15 seconds, end-to-end |
| Concurrency / pending queue | 6 / 64 per origin |
| Rate / burst / critical reserve | 450 per minute / 15 / 3 |
| Transient retries | At most 3; 20% earned retry budget, initially empty |
| Backoff | Full jitter, 0.25-second base, 8-second cap |
| Circuit | 5 failures in last 20 samples within 30 seconds; 10-second cooldown |
| Cache | Off per call unless `cacheTtl` is supplied; max 128 entries |
| Stale-if-error | Off (`staleIfError=0`) |

Default-runtime clients from the same required ModuleScript share a server token bucket; use one client and universe facades. This SDK cannot observe unrelated scripts' HTTP usage.

## Gateway routing

All services default to **`https://lb1.blox-api.com`**. The gateway strips the following prefix before forwarding the unchanged backend route:

| Service facade / override key | Prefix |
|---|---|
| `auth` | `/auth-service` |
| `matchmaking` | `/matchmaking-service` |
| `party` | `/party-service` |
| `codes` | `/code-service` |
| `audit` | `/audit-service` |
| `config` | `/remote-config-service` |
| `leaderboards` | `/leaderboard-service` |
| `fields` | `/fields-service` |

Config must use `/remote-config-service`, **not `/config-service`**: the gateway reserves `/config*`.

```luau
local client = BloxSDK.new({
    secretName = "BLOX_SERVICE_ACCOUNT",
    universeId = game.GameId,
    gatewayUrl = "https://gateway.example", -- Optional: replaces the gateway for all services.
    services = {
        fields = { baseUrl = "https://fields.blox-api.com" }, -- Optional: bypasses gateway AND prefix.
    },
})
```

Both `gatewayUrl` and each `baseUrl` must be HTTPS origins without paths, userinfo, fragments, or queries; one trailing slash is accepted and removed. Hostnames and ports are canonicalized. A `baseUrl` overrides only its named service; other services still use the gateway. Unknown service keys/options are rejected. The old `hosts` option and per-host defaults are removed, with no automatic fallback. Roblox secrets must permit every configured destination.

Default wire examples:

- Audit events: `GET https://lb1.blox-api.com/audit-service/api/audit/events` (a scoped client adds `?universeId=...`).
- Config snapshot: `GET https://lb1.blox-api.com/remote-config-service/api/config/universes/{id}/snapshot`.
- Fields transaction: `POST https://lb1.blox-api.com/fields-service/api/fields/universes/{id}/players/{uid}/transactions`.

Admission queues and circuit breakers remain **per origin**, so all gateway services share them; direct hosts have separate state unless they resolve to the same canonical origin. URL prefixes remain in cache/single-flight keys. `withUniverse`, authentication refresh/logout, health checks, pagination and helper requests all retain the same routing configuration.

`tools/gen.py` declares the gateway and prefix table once and generates `src/Core/Routing.luau`, service route comments and the [endpoint reference](docs/ENDPOINTS.md). `sdk.yml` is the Selene standard-library definition, not client routing configuration. See [configuration example](examples/routing.luau).

## Development / verification (offline)

```sh
export PATH=/opt/homebrew/bin:$HOME/.aftman/bin:$PATH
python3 tools/gen.py --refresh-sources # Reads local svc backends plus GAS/Codes/Matchmaking under ~/work/srv
python3 tools/gen.py                  # Deterministic replay from the checked-in spec
python3 tools/build-roblox.py
./tools/verify
```

Pinned `aftman.toml` selects already-installed tools; verification never installs dependencies. The complete suite runs under both `luau` and `lune`, and again against the generated Roblox Instance-require package. It checks strict analysis, StyLua, Selene, deterministic generation, route coverage, builds a Rojo model, and checks every module is included in the local Wally archive. CI targets a preprovisioned macOS ARM64 runner.

### Layout

- `src/Core/`: portable transport, admission, retry/breaker/cache, validation, codecs, configuration.
- `src/Fields/`: hand-written TypeSystem, schema, transaction/profile helpers and domain wire conversion.
- `src/Codes/`: handwritten award builder composition and schema preflight.
- `src/Auth/`: service keys, identity sessions and the hand-written scoped-token cache.
- `src/Services/`, `src/Types/`: generated typed facades and DTOs.
- `src/BloxSDK.luau`: portable client composition; `src/init.luau`: Luau CLI package entry.
- `roblox/`: generated, type-preserving Roblox import projection; its `init.luau` is the game entry.
- `spec/`: authoritative contracts and local Java source hashes.
- `tools/`: generator, checks, importer (audit-only), packaging projection.
- `tests/`: deterministic scheduler, fault/race tests, independent contract tests.
- `examples/`: all eight services, cursor pagination, buffered audit and snapshot caching.

See [endpoint reference](docs/ENDPOINTS.md), [architecture](docs/ARCHITECTURE.md), [fault tolerance](docs/FAULT-TOLERANCE.md), [performance](docs/PERFORMANCE.md), and [migration](docs/MIGRATION.md).

## Verification boundary

This is an offline-verified implementation, **not a live-deployment certification**. No backend requests or Studio play sessions were used. Actual Roblox Secret permissions, native HTTP timing/quotas, deployed backend parity, and live throughput remain unverified. Java semantic validation (authorization ownership, business rules, size constraints) remains authoritative. Endpoint error-status lists are service-wide guidance, not exhaustive per-route exception proofs. See [source audit](docs/SOURCE-AUDIT.md).
