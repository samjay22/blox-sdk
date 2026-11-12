# FAQ

**Which ID is the universe?** `game.GameId`, not `game.PlaceId`. State it once in `BloxSDK.new` (default on Roblox).

**Can I use the SDK on the client?** No. It is server-only; keys must never reach a client.

**Is it on Wally?** Not yet. Build with Rojo; the repository version is 7.0.0.

**Why does a `profile:add` not show in the portal at once?** Buffered writes are saved in the background, by default within
about 5 seconds. Use `profile:immediate()` and check the Result when you must confirm.

**What does `lease_lost` mean?** Another server took the player. By default the SDK kicks the player so they rejoin fresh.

**What does HTTP 503 `backpressure` mean?** The universe's unsynced Fields backlog is full (1 GiB by default). It is
retryable: wait with jitter and try again.

**How soon does a config edit reach servers?** About 30 seconds (`pollInterval`, with 20 percent jitter). `namespace:refresh()`
fetches immediately.

**What if ConfigService is down?** Each namespace keeps serving its last good copy; `isStale()` becomes true after
three poll intervals without a successful check.

**Can I store secrets in config?** No. Every server with READ can read every key.

**Does a rotation give random picks or rewards?** No (removed in 7.0.0). It only says which items are active.

**Why is my new leaderboard empty?** Delivery is asynchronous and ranks refresh every minute. A Current value or Best ever
board backfills saved values when linked; a Total gained board starts from zero.

**Should I call `leaderboards:submit`?** Not for a board created from a field: the field feeds it.

**Can a player redeem a code twice?** No. A second try returns `already_redeemed`. If a reply is lost, call `redeem` again.

**How many requests may a server make?** The SDK admits 450 per minute by default and batches up to 100 operations every
0.5 seconds. Gateway plan quotas also apply. On `sdk_rate_limited` back off with jitter.

**What is an idempotency key?** A non-secret label for one logical action; repeating it returns the original outcome.

**How do I see per-player or per-key data usage?** The portal's Players page (Data stored) and API keys page (operations over
30 days); the endpoints are `GET /api/fields/universes/{u}/players/{id}/usage` and `/usage/keys?days=30` (FieldsService READ).
The SDK has no wrapper for them yet.

See also [troubleshooting](TROUBLESHOOTING.md), [errors](ERRORS.md) and the [glossary](GLOSSARY.md).
