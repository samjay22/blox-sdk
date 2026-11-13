# Troubleshooting

Start with `result.error.code` and `result.error.kind`; branch on those, never on message text. Then check:
`game.GameId` matches the key's universe; the key has Gateway and the service level; the Roblox secret is allowed for
`lb1.blox-api.com`; Allow HTTP Requests is on.

## Connection and credentials

| Symptom | Cause | Fix |
|---|---|---|
| `sdk_unauthorized` (401) | Key missing, revoked, expired | Rotate and store as a secret |
| `sdk_forbidden` (403) | No Gateway or service level, or another universe | Fix grants and universe |
| `sdk_local` naming a permission | `levels` in `BloxSDK.new` omit what the call needs | Add the level or drop the call |
| `sdk_rate_limited` | Local budget or gateway quota | Reduce calls, back off with jitter |
| `sdk_timeout` / `sdk_network` | Backend or network | Retry safe calls with jitter; keep the same idempotency key |
| `BloxSDK.new` fails with `prod_key_in_studio` | A prod (`bsa_`) key in Roblox Studio | Use a `bsd_` dev key in Studio, or pass `allowProdInStudio = true` on purpose |
| `Unknown API key prefix` | The key does not start with `bsa_` or `bsd_` | Copy the key again from the portal; keys are never edited |
| `secretName requires environment` | `secretName` without `environment` | Pass `environment = "dev"` or `"prod"` to match the secret's key |
| `sdk_forbidden` with code `environment_mismatch` | A request named another environment than the key's | Remove custom environment headers; the key decides |
| `sdk_forbidden` from a service other than Fields, Config or Gateway with a dev key | Dev keys only work on services that have environments | Use a prod key for that service, or leave it out of the test place |
| `dev_limit_exceeded` (409) | The dev environment hit its cap (100 definitions, 200 entries per namespace) | Remove items in dev, or reset dev in the portal |
| `sdk_circuit_open` | Repeated failures opened the breaker (10 s) | Wait; the SDK probes again |

## Fields

| Symptom | Fix |
|---|---|
| `unknown_field` | Create the field or fix the spelling |
| `below_min` / `above_max` / `max_delta_exceeded` | The write breaks the field's limits |
| `precondition_failed` | The value changed since you checked: reload and decide again |
| `idempotency_conflict` | Same key, different request: reuse a key only for the identical action |
| `lease_lost` | Another server holds the player: let them rejoin |
| HTTP 503 `backpressure` | Unsynced backlog full: retry later; tell an operator if it persists |
| Write missing in Players | Buffered write pending: wait about 5 s or use `immediate()` |

## Configs

| Symptom | Fix |
|---|---|
| Always the default | `waitReady(10)`, then `isReady()`, `has(key)`, `version()`; check the key spelling |
| `isStale()` | Read `lastError()`; check ConfigService READ and the universe |
| `version_conflict` | Re-read, merge and retry with the new `expectedVersion` |
| `validation_failed` | Bad name, null value or over 64 KiB; delete instead of writing null |
| `limit_exceeded` | Over 1000 keys, 1 MiB or 100 namespaces |
| Slow edits | Lower `pollInterval` (minimum 1 s) or call `refresh()` |

## Item lists

| Symptom | Fix |
|---|---|
| `unknown_member` | The name is not in the list (`error.members`); check spelling and that the config poll has run |
| `member_retired` | Retired members cannot be granted; `unretireMember` or use another member |
| `member_limit` | The field holds its `maxMembers` already; `revoke` first or use `replace` |
| `enum_source_unavailable` | The list has not loaded yet; wait and retry, check ConfigService READ |
| `member_in_use` | Players hold it: read `error.holders` and retire the member instead |
| `holder_check_unavailable` | The holder check could not answer (the removal fails closed); retry later or retire the member |
| `source_immutable` | A field keeps its item list for good; define a new field instead |
| Granted member missing in `activeMembers()` | The list changed on the server; the SDK sees it after the next config poll |

## Leaderboards

| Symptom | Fix |
|---|---|
| Empty after linking | Wait a minute; Total gained boards count only new changes |
| Score changed, rank did not | Ranks refresh every minute; delivery is asynchronous; ask an operator to check the outbox |
| `leaderboard_board_mismatch` (422) | Align order/reset/aggregation or pick a new board name |
| `leaderboard_unavailable` (503) | Retry later; the field definition was not saved |

## Codes and rotations

| Symptom | Fix |
|---|---|
| `redeem` returns `invalid` | Unknown, disabled, deleted or malformed code |
| `redeem` returns `failed` | Read `error.code`: missing Fields write permission or an award that no longer matches the schema |
| `redeem` returns `retry` | Call again; it cannot double grant |
| `rotation_not_found` | No rotation by that name |
| `invalid_definition` | Duplicate item id, `show` above the list size, or a bad `every` |
| Rotation unchanged | Its period has not ended; use `secondsLeft` or `upcoming` |

See [errors](ERRORS.md), [fault tolerance](FAULT-TOLERANCE.md), and the [FAQ](FAQ.md).
