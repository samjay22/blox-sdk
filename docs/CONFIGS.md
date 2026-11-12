# Dynamic game configuration

`client.configs` reads and writes **dynamic configuration**: JSON values grouped into named *namespaces* inside your
universe, changeable without publishing a new place version. It is backed by ConfigService and is separate from
Fields (player data) and from flags/maintenance (the Fields runtime snapshot). You never pass a universe ID: it is the
one given to `BloxSDK.new`.

```luau
local shop = client.configs:namespace("Shop")   -- starts one background poller for this namespace
shop:waitReady()                                  -- optional: yield until the first load
local price = shop:getNumber("SwordPrice", 100)   -- instant, never yields, never throws
shop.Changed:connect(function(change)
	print(change.namespace, change.version, table.concat(change.keys, ", "))
end)
```

## Reading (every server)

A namespace handle keeps a cached copy of the whole namespace and refreshes it with a conditional `GET .../snapshot`
using the server's strong `ETag`; an unchanged namespace costs a `304` with no body. Reads touch memory only.

| Call | Result |
|---|---|
| `:get(key, default?)` | cached JSON value, or `default` (nil) when missing or not loaded yet. Values are frozen; copy before editing. |
| `:getString(key, default)` / `:getNumber` / `:getBoolean` | the value if it has that type, else `default` |
| `:has(key)`, `:keys()`, `:snapshot()` | membership, sorted keys, and `{ namespace, version, entries }` (frozen) |
| `:version()` | cached namespace version; `0` before the first load or when the namespace has never been written |
| `:isReady()`, `:waitReady(timeout?)` | first load done; `waitReady` yields up to `timeout` seconds (default 10) and returns whether it is ready |
| `:lastRefreshedAt()`, `:isStale()`, `:lastError()` | unix time of the last successful check, whether it is older than `staleAfter`, the latest failure |
| `.Changed:connect(fn)` | `fn(change)` with `{ namespace, version, previousVersion, keys, set, deleted }`; fires on the first load and each new version, never on a `304`; listener errors are isolated. Returns a connection with `:disconnect()` |
| `:refresh()` | fetch now (yields); returns whether the cache is confirmed current |
| `:destroy()` | stop the poller and listeners; cached values stay readable |

A namespace that has never been written is an empty namespace at version 0 (the server answers `namespace_not_found`,
which the handle treats as "ready and empty"). If a refresh fails, the last good snapshot keeps being served,
`lastError()` says why, and `isStale()` turns true once the last successful check is older than `staleAfter`. A snapshot
whose version is lower than the cached one is ignored.

`client.configs:namespace(name, options?)` returns the same handle for the same name, so any script may call it.
Options (per call or `configs = {...}` in `BloxSDK.new`), in seconds: `pollInterval` (default 30, 1-3600), `jitter`
(default 0.2, a fraction of the interval, 0-0.5) and `staleAfter` (default three intervals). One poller runs per
namespace; polls are low priority and join the normal batch, retry and rate-limit machinery. `client:destroy()` and
`client:flush()` stop every poller.

## Writing (admin tooling; needs ConfigService ADMIN)

Keep write access out of game servers: use a separate key with `levels = { ConfigService = "ADMIN" }`.

```luau
local shop = client.configs:namespace("Shop")
shop:set("SwordPrice", 120, { description = "Spring sale", expectedVersion = 3 })
shop:setMany({ set = { SwordPrice = 120, ShieldPrice = 90 }, delete = { "OldKey" }, expectedVersion = 7 })
shop:delete("OldKey")
for result in shop:historyPages() do ... end
shop:rollback(5)  -- restores version 5 as a NEW version; history is never rewritten
```

| Call | Notes |
|---|---|
| `:set(key, value, opts?)` | any JSON except null, at most 64 KiB. `expectedVersion` is the key's version (`0` = create only). Writing an unchanged value is a no-op. |
| `:setMany({ set?, delete?, expectedVersion?, expectedVersions?, descriptions? })` | one atomic change under one new namespace version; nothing is written if any check fails. `expectedVersion` is the namespace version. |
| `:delete(key)` | a missing key is `key_not_found` |
| `:info()`, `:entries(page?)`, `:entry(key)` | uncached reads with versions and descriptions (`entriesPages` iterates) |
| `:history(page?)`, `:at(version)` | newest first, last 500 versions retained; `at` returns the full content of one version |
| `:rollback(version)` | `0` empties the namespace; an expired version is `version_not_found` |
| `client.configs:namespaces()` | the universe's namespaces with version and entry count |

Writes are never retried automatically. After a successful write the handle refreshes itself so this server sees its
change quickly. Arguments are checked locally (key and namespace grammar, non-null value, size) before any request.

## Errors

Failures are normal `Result` errors. ConfigService adds these `error.code` values: `namespace_not_found`,
`key_not_found`, `version_not_found`, `version_conflict` (an `expectedVersion` check failed: read again and retry),
`validation_failed` and `limit_exceeded`. Local refusals use `sdk_validation` and, for a missing permission,
`sdk_local`. See [errors](ERRORS.md).

Limits: namespace name up to 64 characters (`A-Z a-z 0-9 _ -`), key up to 100 (`A-Z a-z 0-9 _ . -`), 64 KiB per value.
