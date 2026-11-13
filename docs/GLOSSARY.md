# Glossary

| Term | Meaning |
|---|---|
| Organization / universe / place | Studio tenant / one Roblox experience and its isolated data / one destination inside it. `game.GameId` is the universe |
| `bsa_` key | Universe-bound service-account credential for servers, with explicit service levels |
| READ / READ_WRITE / ADMIN | Cumulative service levels; ADMIN adds administration. Config writes need ConfigService ADMIN |
| Gateway | Extra permission required to call through `lb1`, in addition to the service level |
| Field | A named, typed per-player value such as `Currency.Gems`, with limits and write rules |
| Profile | A leased, loaded player document with buffered writes (`loadProfile`) |
| Lease | One server's exclusive hold on a player; `lease_lost` means another server took it |
| Transaction | A group of operations that all commit or none do |
| Idempotency key | Non-secret label for one logical action; repeating it returns the original outcome |
| Ledger / history | Recorded changes with who, why and which transaction |
| Namespace | A named group of config keys in a universe with its own version and history |
| Poller / stale | The cached background refresh of a namespace / not confirmed within `staleAfter` (three intervals) |
| Rotation | A named list of items that take turns on a fixed clock |
| Outcome | The one typed answer of `codes:redeem` (`granted`, `already_redeemed`, `invalid`, `expired`, `not_started`, `exhausted`, `retry`, `failed`) |
| Board / period | A leaderboard / one reset window of it |
| Backfill | Queuing every saved value once when a Current value or Best ever board is linked; Total gained is not backfilled |
| Outbox | Durable work delivered after the source transaction (for example scores to the leaderboard service) |
| Ranking job | Scheduled job that recalculates ranks every minute |
| Backpressure | HTTP 503 when a universe's unsynced Fields backlog is full |
| Batch | Up to 100 operations sent together every 0.5 s through BatchService; `op.service` names the target (`fields`, `config`, ...) |
| Result | `{ ok = true, value }` or `{ ok = false, error }`; `codes:redeem` is the one call returning an outcome |
| Data usage | Raw value bytes per player and successful data requests per API key |
| Item list | A config namespace of named members (`{ bit, label?, description?, meta?, retired? }`) that players can hold through a Fields field. The other kind of namespace is Settings |
| Member | One entry of an item list. Its name is what game code uses; its bit is permanent and never reused |
| Retired member | A member nobody new can get; players who hold it keep it, and `usable` is false for it |
