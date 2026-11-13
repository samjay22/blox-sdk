# BloxSDK

One server-side, strict Luau SDK for **Auth, Matchmaking, Party, Codes, Audit, Leaderboards, Fields, Platform, and Configs**.

**374 typed endpoints, version 8.0.0 (not published):** every route in `routes.json`, including Fields runtime config/flags/maintenance, recurring schedules and run history, rating-scope discovery/labels, tenant Auth, and source-backed Platform APIs. No runtime dependencies or client-side credentials. See [endpoint coverage and evidence](SDK_COVERAGE.md): current Party source parity is unverified; Fields Rotations are covered.

> **Credentials:** game servers should use **`bsa_` service-account keys**, never human logins.
> Humans/tools use **identity login for management, then `client:scoped(universeId)` for downstream calls**.
> See [tenant authentication, role templates and error codes](docs/AUTH.md).
>
> **Gateway permissions:** callers using `lb1` need **`Gateway` in addition to the target service
> permission**. Code redemption also needs Fields write access; Matchmaking enrichment needs Fields
> READ access. **`bsa_` service-account keys are universe-bound.** SDK `levels` are hints, not grants.

## Install

### Wally

After `blox-api/blox-sdk@8.0.0` is published to the Wally index, add this to your game's `wally.toml`:

```toml
[server-dependencies]
BloxSDK = "blox-api/blox-sdk@8.0.0"
```

Run `wally install`, map `ServerPackages` into **ServerScriptService** with Rojo, then require
`game.ServerScriptService.ServerPackages.BloxSDK`. This checkout does **not** publish or claim registry availability.
Until publication, use the checked-in `roblox/` package with Rojo:

```sh
rojo build default.project.json -o BloxSDK.rbxm
```

Insert the resulting ModuleScript into **ServerScriptService** or **ServerStorage**, never ReplicatedStorage. Alternatively, map `roblox/` into your game's Rojo tree. `wally.toml` describes a server-only package; this repository has **not** been published to a registry.

Enable outbound HTTP and configure a Roblox secret permitted for `lb1.blox-api.com` (or your explicit override destinations). This is a server SDK; requiring it does not start a loop or send a request.

```luau
local BloxSDK = require(game.ServerScriptService.BloxSDK)
local client = BloxSDK.new({
    secretName = "BLOX_SERVICE_ACCOUNT",
    levels = { -- Optional deployment metadata, not an authorization grant.
        FieldsService = "READ_WRITE",
        MatchmakingService = "READ_WRITE",
        PartyService = "READ_WRITE",
        CodeService = "READ_WRITE",
    },
})

local loaded = client.fields:loadProfile(123456)
if loaded.ok then
    local profile = loaded.value
    local committed = profile:immediate():add("Currency.Gems", 10):reason("Quest reward"):commit()
    if not committed.ok then warn(committed.error.code) end
end

game:BindToClose(function()
    -- Finish issuing your saves before flush: flush closes admission permanently.
    client:flush(20)
    client:destroy()
end)
```

`secret:AddPrefix("Bearer ")` is passed directly as the header value. The secret is never coerced to a string. Plain `key = "bsa_..."` is supported for Studio/tests; supply it securely, never hardcode it. Readable keys are validated against the backend's exact 56-character format. Opaque Secrets cannot be inspected locally.

## Leased profiles and buffered writes (3.0)

Native clients with `universeId` load joining/existing players automatically. Explicit loads join that work:

```luau
local loaded = client.fields:loadProfile(player)
if loaded.ok then
    local profile = loaded.value -- Ready only after acquire grants a validated snapshot.
    local queued = profile:add("Currency.Coins", 5) -- Immediate local update; not durable yet.
    if not queued.ok then warn(queued.error.code) end
    -- Purchases/codes/trades/rolls stay synchronous, never buffered:
    -- profile:immediate():add(...):reason(...):key(...):commit()
end
client.LeaseLost:connect(function(event) warn("Lease lost", event.userId, event.code) end)
client.CommitRejected:connect(function(event) warn("Commit rejected", event.userId, event.code) end)
```

One immutable commit every `sessions.flushInterval` (default 5 s) carries all dirty players on the normal
0.5 s batch. Adjacent ADDs coalesce; retries reuse `JobId:counter` and never absorb later ops. Lease renewal,
PlayerRemoving and BindToClose are automatic. Default load-failure/lease-loss kicks are controlled by
`sessions.kickOnFailure` / `sessions.kickOnLeaseLost`. `profile:release()` saves then releases;
`client:flush(timeout)` saves/releases all and permanently closes admission. `destroy()` alone is not a save.
Versioned feed reconciliation rebases pending ops; acknowledgements use a fresh snapshot barrier because
commit responses carry no values. See [binding SDK contract](API_CONTRACT.md), [Fields guide](docs/FIELDS.md)
and [migration](MIGRATION.md). Live backend support must be deployed separately.

## Calls and results

The nine facades are `client.auth`, `.matchmaking`, `.party`, `.codes`, `.audit`, `.leaderboards`, `.fields`, `.platform` and `.configs`. Route wrappers are generated from `spec/endpoints.json`; Fields gameplay helpers, the Codes and Configs facades and the scoped-token cache are hand-written. Dynamic game configuration is `client.configs` (namespaced JSON values with a cached, ETag-polled copy); Fields no longer has universe-scoped values. See [docs/CONFIGS.md](docs/CONFIGS.md).

- Body-only endpoints take the DTO directly: `client.party:createParty({ownerId=123, placeId=456})`.
- Endpoints with other path or query parameters take `{path=..., query=..., body=...}`. Path and query values are separately encoded.
- Optional requests can be omitted: `client.audit:list()`.
- The universe comes from `BloxSDK.new` (on Roblox it defaults to `game.GameId`) and is filled into every path, query and body that declares one. A path that names only the universe disappears from the call, so those endpoints take their body directly. `client:withUniverse(id)` returns a facade for a different universe that shares the original client's auth, queue, rate budget, breakers, cache and lifetime.
- `client:health()` queues `/health` for all eight services in one batch and returns `{result, latency}` per service. HTTP status is on `result.status` or `result.error.status`; backend health is in `result.value`.
- `client:metrics()` returns an immutable counter/histogram snapshot.

```luau
local joined = client.matchmaking:joinQueue({
    robloxUserIds = { tostring(player.UserId) },
    gameModeName = "ranked",
}, { priority = "critical", deadline = os.clock() + 5 })
```

`Result<T>` is `{ok=true,value:T,status?,stale?}` or `{ok=false,error:BloxError}`. HTTP/network failures return results rather than throwing. Invalid construction config throws a value-free assertion. Errors include kind, HTTP status when available, endpoint ID, attempt count, and a **fully redacted** error body. There is deliberately no raw-response debug logging.

`CallOptions`: relative `timeout` (seconds), absolute monotonic `deadline` (the earlier bound wins), optional `idempotencyKey` for single-key operations, `priority` (`critical`/`bulk`/`low`), maximum `retry` count, optional `cacheTtl` in seconds, and `signal={cancelled=false}`. Removed options such as `idempotencyHint` are rejected, not shimmed. Unkeyed non-idempotent mutations are never automatically retried. Retry-After seconds/HTTP dates are honored for 429 and all 5xx within the original deadline and earned retry budget.

Responses shared by cache/single-flight are recursively frozen. Clone before editing. `BloxSDK.null` represents an explicit JSON null (e.g. clearing service-account expiration). `BloxSDK.array({})` marks an empty array in arbitrary JSON; declared DTO array fields are encoded correctly automatically.

## Platform tools

Current Platform methods and Fields-owned player administration are documented in [PLATFORM.md](docs/PLATFORM.md). Planned Platform LiveOps, environments and flags have no current controllers and are not fabricated SDK methods. The [changelog](CHANGELOG.md) describes local changes, not a published release.

## New service helpers

- `client:auditWriter(...)`: bounded, nonblocking enqueue/flush; max 500 events per batch, interval flush and native Roblox BindToClose integration.
- `client:runtimeSnapshot(30)`: Fields conditional snapshot polling with opaque ETags, synchronous `isEnabled`, `Changed` signal, last-good-state retention; `isEnabled` reads the master switch, not per-user rollout rules. Use `client.fields:evaluateFlags` / `evaluateFlagsBatch` for player evaluation. See [runtime example](examples/runtime-config.luau).
- Cursor endpoints expose `<method>Pages(...)` iterators returning page Results.
- Fields required-key operations, leaderboard submissions and audit events generate omitted idempotency keys **once per logical call and reuse them across retries**. Persist caller-supplied keys for retries across separate calls/restarts.
- Loaded profiles automatically share low-priority batch sync (up to 200 players/op) and expose `Profile.Changed` / `client.ProfileChanged` for admin edits. Configure `profileSync` or disable it; see [Admin edits & live sync](docs/FIELDS.md#admin-edits--live-sync).
- Fields includes a strict TypeSystem, schema cache, validated transactions, profile/presence lifecycle and offline schema-specialized typed accessor codegen. Unsafe int64 values fail closed, never round. See [Fields guide](docs/FIELDS.md).
- Fields `Bulk`, `Schedules`, and `Jobs` helpers add typed request validation and bounded `Jobs:waitFor` polling. **Server/admin-key usage only**, including previews, job reads and export/downloads; health summary and schedule run history need READ. Never expose an ADMIN key or these controls to game clients. See [durable jobs guide](docs/JOBS.md) and [game-server example](examples/fields-jobs.luau).

- Item lists: a config namespace of named members (`client.configs:namespace("Items"):setKind("items")`) that players hold through Fields `bitmap` fields, with `profile:grant/revoke/replace/has/members/usable`. See [Item lists](docs/ITEM-LISTS.md) and the [equipment](examples/server/equipment.server.luau) and [event items](examples/server/event-items.server.luau) examples.
- Fields `rotations()` is a named list of items that take turns on a fixed clock: `current(name)` returns the active items, when they change and the next ones (cached), with `secondsLeft`, `upcoming` and `watch`. See [Rotations](docs/ROTATIONS.md) and the [weather](examples/weather.luau) and [daily shop](examples/daily-shop.luau) examples.

See [new-service guide](docs/NEW-SERVICES.md) and the Fields examples for lifecycle and safety details.

## Fields validation and Code awards

`client.fields:validateOps({ops=...})` accepts 1–100 subject-free operations after explicitly
loading `client.fields:schemaCache():load()`. It pre-validates through TypeSystem, collects every
failing op with zero-based `opIndex/field/path/code`, and sends locally valid lists to Fields for current
validation. `client.fields:operations():add("Currency.Gems",100):validate()` and player
transaction `:validate()` provide dry runs without a reason, key or commit. No player state is read.

Codes are redeemed in one call and answered with one typed outcome:

```luau
local outcome = client.codes:redeem(player, text) -- Player or user ID
if outcome.status == "granted" then
    print("rewards", #outcome.rewards)
elseif outcome.status == "already_redeemed" or outcome.status == "expired" then
    -- also: invalid, not_started, exhausted; "retry" and "failed" carry outcome.error
end
```

Administrators create codes with `client.codes:create({ code = "WELCOME100", award = client.codes:award():add("Currency.Gems", 100) })`;
the schema loads and the award validates on use. CodeService applies one atomic transaction using `code-<codeId>-<userId>`,
so each player redeems each code once. See [Codes guide](docs/CODES.md), [redeem example](examples/redeem.luau),
[award example](examples/code-award.luau), and [Fields guide](docs/FIELDS.md).

Matchmaking criteria read server-fetched Fields computed values. `fieldName` accepts any computed
Fields ID, including namespaced IDs (`Stats.Elo`, `Progress.Level`), as a literal ID, not a nested
metadata path or caller-supplied metadata. See [field ID grammar, criteria and failure semantics](docs/MATCHMAKING.md).

## Static field types

Save an authorized `GET /schema` response, then run the offline standard-library-only generator:

```sh
python3 tools/gen-field-types saved-schema.json --out game/GeneratedFields --sdk ../../roblox
```

Require generated `Typed` and `FieldTypes` modules. `Typed.Currency.Gems:get(profile)` is `number`,
`:add(tx, delta)` requires a number, map/list accessors enforce their schema's key/item types.
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
    local schema = scoped.fields:schemaCache() -- Exchanges once; caches and refreshes early.
    -- Do not log login, createServiceAccount, or rotateServiceAccount responses.
end
admin:logout() -- Uses the latest rotated refresh token and clears the local session.
admin:destroy()
```

Identity refresh and per-universe scoped exchange are separate, versioned and single-flight. `scoped(id)` returns a lazy downstream facade sharing routing, rate budget and lifetime; keep the root client for management. `withUniverse(id)` only fills route parameters and does not exchange credentials. Scoped JWTs cannot manage organizations or keys. A caller can time out without cancelling another caller's shared refresh. Custom synchronous TokenStores are supported; see [AUTH](docs/AUTH.md).

## Defaults

| Policy | Default |
|---|---|
| Gateway | `https://lb1.blox-api.com/batch-service/api/batch` |
| Timeout | 15 seconds, end-to-end |
| Batch cadence / native requests in flight | 0.5 seconds / 1 per client |
| Envelope / op body / logical queue | 100 ops, 1 MiB / 256 KiB (commits: 1 MiB) / 10,000 calls |
| Rate / burst / critical reserve | 450 per rolling minute / 15 / 3 |
| Lease TTL / buffered flush | 60 seconds / 5 seconds |
| Physical rolling-second ceiling | 8 requests/server |
| Transient retries | At most 3; 20% earned retry budget, initially empty |
| Backoff | Full jitter, 0.25-second base, 8-second cap |
| Circuit | 5 failures in last 20 samples within 30 seconds; 10-second cooldown |
| Cache | Off per call unless `cacheTtl` is supplied; max 128 entries |
| Stale-if-error | Off (`staleIfError=0`) |

Every physical attempt (including retries) consumes a token and a rolling-window admission. `requestsPerMinute` is an integer 1–480; bursts never bypass that window. Default-runtime clients from the same required ModuleScript share this limiter; use one client and universe facades. This SDK cannot observe unrelated scripts' HTTP usage.

## Batch-only gateway transport

All network operations queue for `POST {gatewayUrl}/batch-service/api/batch`; none call a service
URL directly. This includes health, managed auth, helper operations and loaded-profile sync. Calls
still yield and return the same Result shapes. Empty ticks send nothing; overflow waits for a later
tick. There is no direct fallback or service-host override.

```luau
local client = BloxSDK.new({
    secretName = "BLOX_SERVICE_ACCOUNT",
    universeId = game.GameId,
    gatewayUrl = "https://gateway.example", -- Optional HTTPS origin, no path/credentials/query.
    batch = { intervalSeconds = 0.5 },      -- Minimum 0.25 seconds.
})
```

The batcher carries internal service paths without gateway prefixes; `leaderboards` maps to service
`leaderboard`. At default cadence, ≤120 physical requests/minute include gameplay, auth, retries and
sync, guarded by the shared rolling limiter. Independent calls issued concurrently can coalesce;
dependent player calls remain ordered through retries. Timeouts start with the logical call, so a
short deadline can expire before dispatch. `services` direct-host overrides are rejected in 2.0.

See the [transport/batching guide](docs/BATCHING.md), [performance and limits](docs/PERFORMANCE.md),
and [migration notes](MIGRATION.md). The theoretical 200 independent ops/s/client is not a measured
10k/s Roblox benchmark; platform-wide capacity is discussed in the performance guide.

## Development / verification (offline)

```sh
export PATH=/opt/homebrew/bin:$HOME/.aftman/bin:$PATH
python3 tools/gen.py --refresh-sources # Reads local svc backends plus GAS/Codes/Matchmaking under ~/work/srv
python3 tools/gen.py                  # Deterministic replay from the checked-in spec
python3 tools/build-roblox.py
./tools/verify
```

In a worktree without sibling backend checkouts, set `BLOX_SOURCE_ROOT` to the local directory
containing `srv/` and `svc/` for source refresh and controller coverage. Deterministic replay needs no backends.

Pinned `aftman.toml` selects already-installed tools; verification never installs dependencies. The complete suite runs under both `luau` and `lune`, and again against the generated Roblox Instance-require package. It checks strict analysis, StyLua, Selene, deterministic generation, route coverage, builds a Rojo model, and checks every module is included in the local Wally archive. CI targets a preprovisioned macOS ARM64 runner.

### Layout

- `src/Core/`: portable transport, admission, retry/breaker/cache, validation, codecs, configuration.
- `src/Fields/`: hand-written TypeSystem, schema, transaction/profile helpers and domain wire conversion.
- `src/Codes/`: handwritten award resolution (builder or op list, schema loaded on use); `Services/Codes` is the hand-written facade.
- `src/Auth/`: service keys, identity sessions and the hand-written scoped-token cache.
- `src/Services/`, `src/Types/`: generated typed facades and DTOs.
- `src/BloxSDK.luau`: portable client composition; `src/init.luau`: Luau CLI package entry.
- `roblox/`: generated, type-preserving Roblox import projection; its `init.luau` is the game entry.
- `spec/`: authoritative contracts and local Java source hashes.
- `tools/`: generator, checks, importer (audit-only), packaging projection.
- `tests/`: deterministic scheduler, fault/race tests, independent contract tests.
- `examples/`: gameplay services, cursor pagination, buffered audit and Fields runtime snapshot caching.

See [endpoint reference](docs/ENDPOINTS.md), [architecture](docs/ARCHITECTURE.md), [fault tolerance](docs/FAULT-TOLERANCE.md), [performance](docs/PERFORMANCE.md), and [migration](docs/MIGRATION.md).

## Verification boundary

This is an offline-verified implementation, **not a live-deployment certification**. No backend requests or Studio play sessions were used. Actual Roblox Secret permissions, native HTTP timing/quotas, deployed backend parity, and live throughput remain unverified. Java semantic validation (authorization ownership, business rules, size constraints) remains authoritative. Endpoint error-status lists are service-wide guidance, not exhaustive per-route exception proofs. See [source audit](docs/SOURCE-AUDIT.md).


## 1.0 guides and public API

All SDK methods/properties use **lowerCamelCase** (native Roblox APIs retain engine casing).
Route DTO wire names/enums are unchanged. Helper names are distinct from route calls:
`fields:schema()` fetches a wire response; `fields:schemaCache()` owns a schema cache;
`fields:transactionBuilder(user)` creates a builder; `fields:transaction(request)` submits a wire DTO.
Underscore members and `Core`, `Services`, `Auth`, `Testing` modules are private, unsupported implementation details.
The root exports no internal module tables. `Types/*` and `Fields/Types` are public type-contract modules.

- [Generated API and Luau types](docs/api/README.md) — regenerate with `tools/gen-docs`; CI rejects drift.
- [Getting started in 10 minutes](docs/GETTING-STARTED.md), [which feature should I use](docs/CHOOSING.md), [recipes](docs/RECIPES.md), [FAQ](docs/FAQ.md), [troubleshooting](docs/TROUBLESHOOTING.md), [glossary](docs/GLOSSARY.md).
- [Fields](docs/FIELDS.md), [transactions/products](docs/TRANSACTIONS.md), [dynamic configs](docs/CONFIGS.md), [flags](docs/FLAGS.md), [live events](docs/LIVE-EVENTS.md).
- [Item lists](docs/ITEM-LISTS.md), [Rotations](docs/ROTATIONS.md), [leaderboards/ratings](docs/LEADERBOARDS.md), [matchmaking](docs/MATCHMAKING.md).
- [Codes](docs/CODES.md), [party](docs/PARTY.md), [audit](docs/AUDIT.md), [platform](docs/PLATFORM.md), [authentication](docs/AUTH.md).
- [Error codes](docs/ERRORS.md), [performance/limits](docs/PERFORMANCE.md), [0.x migration](MIGRATION.md), [1.0 changelog](CHANGELOG.md).
- [Runnable Roblox server scripts](examples/README.md) — 16 opt-in scripts, type-checked by an import-only projection.
- [Live smoke](docs/LIVE-SMOKE.md) — explicit consent, isolated test fixtures, no credentials in output.

### Pluggable logging

```luau
local client = BloxSDK.new({
    secretName = "BLOX_SERVICE_ACCOUNT",
    universeId = game.GameId,
    logger = function(eventName, event)
        print(eventName, event.endpoint, event.status) -- metadata only
    end,
})
```

Logger and hooks receive frozen allowlisted metadata, never request/response bodies, query strings,
headers, credentials or raw exceptions. Observer exceptions are isolated. Do not capture secrets in your own logger.
`onRateLimited` reports local budget waits; queue rejection returns `RateLimited` / `sdk_rate_limited`.
