# BloxSDK

One server-side, strict Luau SDK for **auth, player data, matchmaking, parties, codes, audit, config, leaderboards, and economy**.

**234 typed endpoints:** all 218 routes in `routes.json`, plus 16 controller-defined auth routes (service accounts, service catalog, DELETE aliases, and universe enable/disable). No runtime dependencies or client-side credentials.

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
        DataService = "READ_WRITE",
        MatchmakingService = "READ_WRITE",
        PartyService = "READ_WRITE",
        CodeService = "READ_WRITE",
    },
})

local result = client.data:getUserData({ path = { robloxUserId = 123456 } })
if result.ok then
    -- Use result.value; global-admin unscoped reads can return a list.
else
    warn(result.error.kind, result.error.endpoint, result.error.status)
end

game:BindToClose(function()
    -- Finish issuing your saves before flush: flush closes admission permanently.
    client:flush(20)
    client:destroy()
end)
```

`secret:AddPrefix("Bearer ")` is passed directly as the header value. The secret is never coerced to a string. Plain `key = "bsa_..."` is supported for Studio/tests; supply it securely, never hardcode it. Readable keys are validated against the backend's exact 56-character format. Opaque Secrets cannot be inspected locally.

## Calls and results

The nine facades are `client.auth`, `.data`, `.matchmaking`, `.party`, `.codes`, `.audit`, `.config`, `.leaderboards`, and `.economy`. All wrappers are generated from `spec/endpoints.json`.

- Body-only endpoints take the DTO directly: `client.party:createParty({ownerId=123, placeId=456})`.
- Mixed endpoints take `{path=..., query=..., body=...}`. Path and query values are separately encoded.
- Optional requests can be omitted: `client.codes:searchCodes()`.
- `client:withUniverse(id)` shares the original client's auth, queue, rate budget, breakers, cache, and lifetime. It fills **declared path/query universe parameters** and implied Audit event universes, not arbitrary body fields. Supply other required body universe fields explicitly. Universe IDs must be positive exact integers. A service key cannot switch universes.
- `client:health()` checks `<service-prefix>/health` on the gateway for all nine services (or `/health` on an explicit direct host) and returns `{result, latency}` per service. HTTP status is on `result.status` or `result.error.status`; backend health is in `result.value`.
- `client:metrics()` returns an immutable counter/histogram snapshot.

```luau
local joined = client.matchmaking:joinQueue({
    robloxUniverseId = tostring(game.GameId),
    robloxUserIds = { tostring(player.UserId) },
    gameModeName = "ranked",
    metadata = { skill = 1200 }, -- Actual fields depend on your game-mode criteria.
}, { priority = "critical", deadline = os.clock() + 5 })
```

`Result<T>` is `{ok=true,value:T,status?,stale?}` or `{ok=false,error:BloxError}`. HTTP/network failures return results rather than throwing. Invalid construction config throws a value-free assertion. Errors include kind, HTTP status when available, endpoint ID, attempt count, and a **fully redacted** error body. There is deliberately no raw-response debug logging.

`CallOptions`: absolute monotonic `deadline`, `priority` (`critical`/`bulk`), maximum `retry` count, explicit `idempotencyHint`, optional `cacheTtl` in seconds, and `signal={cancelled=false}`. `idempotencyHint` is retained for compatibility but cannot bypass retry safety. Non-idempotent mutations are never automatically retried.

Responses shared by cache/single-flight are recursively frozen. Clone before editing. `BloxSDK.null` represents an explicit JSON null (e.g. clearing service-account expiration). `BloxSDK.array({})` marks an empty array in arbitrary JSON; declared DTO array fields are encoded correctly automatically.

## New service helpers

- `client:auditWriter(...)`: bounded, nonblocking enqueue/flush; max 500 events per batch, interval flush and native Roblox BindToClose integration.
- `client:configSnapshot(30)`: conditional snapshot polling, synchronous `Get`/`IsEnabled`, `Changed` signal, last-good-state retention. `IsEnabled` reads the master switch, not per-user rollout rules.
- Cursor endpoints expose `<method>Pages(...)` iterators returning page Results.
- Economy operations, leaderboard submissions and audit events generate omitted idempotency keys **once per logical call and reuse them across retries**. Persist caller-supplied keys for retries across separate calls/restarts.
- Economy supports exact integer strings and preserves large response amounts without floating-point rounding.

See [new-service guide](docs/NEW-SERVICES.md) and the four new service examples for lifecycle and safety details.

## User-token administration

```luau
local admin = BloxSDK.new({ userSession = {} })
local login = admin.auth:login({ username = suppliedUsername, password = suppliedPassword })
if login.ok then
    local accounts = admin.auth:listServiceAccounts()
    -- Do not log login, createServiceAccount, or rotateServiceAccount responses.
end
admin:logout() -- Uses the latest rotated refresh token and clears the local session.
admin:destroy()
```

Session refresh is versioned and single-flight, including concurrent 401s and proactive expiry refresh. A caller can time out without cancelling another caller's shared refresh. Custom synchronous TokenStores are supported; see [AUTH](docs/AUTH.md).

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
| `data` | `/data-service` |
| `matchmaking` | `/matchmaking-service` |
| `party` | `/party-service` |
| `codes` | `/code-service` |
| `audit` | `/audit-service` |
| `config` | `/remote-config-service` |
| `leaderboards` | `/leaderboard-service` |
| `economy` | `/economy-service` |

Config must use `/remote-config-service`, **not `/config-service`**: the gateway reserves `/config*`.

```luau
local client = BloxSDK.new({
    secretName = "BLOX_SERVICE_ACCOUNT",
    universeId = game.GameId,
    gatewayUrl = "https://gateway.example", -- Optional: replaces the gateway for all services.
    services = {
        data = { baseUrl = "https://direct-data.example" }, -- Optional: bypasses gateway AND prefix.
    },
})
```

Both `gatewayUrl` and each `baseUrl` must be HTTPS origins without paths, userinfo, fragments, or queries; one trailing slash is accepted and removed. Hostnames and ports are canonicalized. A `baseUrl` overrides only its named service; other services still use the gateway. Unknown service keys/options are rejected. The old `hosts` option and per-host defaults are removed, with no automatic fallback. Roblox secrets must permit every configured destination.

Default wire examples:

- Audit events: `GET https://lb1.blox-api.com/audit-service/api/audit/events` (a scoped client adds `?universeId=...`).
- Config snapshot: `GET https://lb1.blox-api.com/remote-config-service/api/config/universes/{id}/snapshot`.
- Economy grant: `POST https://lb1.blox-api.com/economy-service/api/economy/universes/{id}/users/{uid}/grant`.

Admission queues and circuit breakers remain **per origin**, so all gateway services share them; direct hosts have separate state unless they resolve to the same canonical origin. URL prefixes remain in cache/single-flight keys. `withUniverse`, authentication refresh/logout, health checks, pagination and helper requests all retain the same routing configuration.

`tools/gen.py` declares the gateway and prefix table once and generates `src/Core/Routing.luau`, service route comments and the [endpoint reference](docs/ENDPOINTS.md). `sdk.yml` is the Selene standard-library definition, not client routing configuration. See [configuration example](examples/routing.luau).

## Development / verification (offline)

```sh
export PATH=/opt/homebrew/bin:$HOME/.aftman/bin:$PATH
python3 tools/gen.py --refresh-sources # Reads the four local ~/work/svc backend trees
python3 tools/gen.py                  # Deterministic replay from the checked-in spec
python3 tools/build-roblox.py
./tools/verify
```

Pinned `aftman.toml` selects already-installed tools; verification never installs dependencies. The complete suite runs under both `luau` and `lune`, and again against the generated Roblox Instance-require package. It checks strict analysis, StyLua, Selene, deterministic generation, route coverage, builds a Rojo model, and checks every module is included in the local Wally archive. CI targets a preprovisioned macOS ARM64 runner.

### Layout

- `src/Core/`: portable transport, admission, retry/breaker/cache, validation, codecs, configuration.
- `src/Auth/`: service keys and versioned user sessions.
- `src/Services/`, `src/Types/`: generated typed facades and DTOs.
- `src/BloxSDK.luau`: portable client composition; `src/init.luau`: Luau CLI package entry.
- `roblox/`: generated, type-preserving Roblox import projection; its `init.luau` is the game entry.
- `spec/`: authoritative contracts and local Java source hashes.
- `tools/`: generator, checks, importer (audit-only), packaging projection.
- `tests/`: deterministic scheduler, fault/race tests, independent contract tests.
- `examples/`: all nine services, cursor pagination, buffered audit and snapshot caching.

See [endpoint reference](docs/ENDPOINTS.md), [architecture](docs/ARCHITECTURE.md), [fault tolerance](docs/FAULT-TOLERANCE.md), [performance](docs/PERFORMANCE.md), and [migration](docs/MIGRATION.md).

## Verification boundary

This is an offline-verified implementation, **not a live-deployment certification**. No backend requests or Studio play sessions were used. Actual Roblox Secret permissions, native HTTP timing/quotas, deployed backend parity, and live throughput remain unverified. Java semantic validation (authorization ownership, business rules, size constraints) remains authoritative. Endpoint error-status lists are service-wide guidance, not exhaustive per-route exception proofs. See [source audit](docs/SOURCE-AUDIT.md).
