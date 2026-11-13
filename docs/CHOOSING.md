# Which feature should I use?

| If the thing is... | Use | Why |
|---|---|---|
| Different for every player and kept between sessions (balance, level, inventory) | **Fields** | Typed, validated, transactional, with history and backups |
| The same for every player and changed by your team (prices, drop rates, event text) | **Configs** | Versioned, cached on every server, editable without publishing |
| A list of items taking turns on a clock (daily shop, weekly character, hourly weather) | **Rotations** | Every server computes the same answer from the list and the clock |
| Typed in by a player to receive an award once | **Codes** | Once per player, atomic, typed outcome |
| A ranking of players by a number | **Leaderboards** (from a field) | A board linked to a field is fed automatically |
| A switch to flip quickly (kill switch, gradual rollout) | **Feature flags** | Evaluated by the service |
| A Robux item with a receipt and refund | **Products** | Idempotent purchases, reversible |
| A timed change that starts and ends itself | **Live events / schedules** | UTC windows that enable flags and run bulk jobs |

## Fields or configs?

Ask whose value it is. A field belongs to a player; a config value belongs to the universe.

| | Fields | Configs |
|---|---|---|
| Written by | Gameplay servers (READ_WRITE) and operators | Operators only (ConfigService ADMIN) |
| Read by | The server holding the player | Every server, from a local cache |
| Change speed | Immediate for the holding server | About 30 seconds to every server |
| Safety | Types, min/max, transactions, idempotency, history | Any JSON except null, 64 KiB per value, versions, rollback |
| Scale | Millions of rows | 100 namespaces, 1000 keys, 1 MiB per namespace |

## Settings or item list?

A config namespace is **Settings** when its values are numbers, text and tables the game reads (prices, tuning). It is an
**item list** when the game hands out named things that players hold (swords, hats, badges): pair it with a Fields field
of kind `bitmap`. See [item lists](ITEM-LISTS.md).

## Configs or rotations?

Use a rotation when content should change by itself on a schedule and every server must agree. Use a config when a person
decides when the value changes. They pair well: a rotation says *which* items are on offer, a config namespace holds prices.

## Codes or direct awards?

Use a code when the player brings the secret. Use a transaction in server code when the game decides to give the reward (a
quest, a daily login). A player redeems each code once, so codes are wrong for repeatable rewards.

## Leaderboard modes

| Rank by | Pick it when | Remember |
|---|---|---|
| Current value | You want the live balance or score | Spending lowers the rank |
| Best ever | You want a personal best | Lower later values never replace it |
| Total gained | You want a period total (weekly wins) | Net change; boards created later do not include earlier history |

## Patterns to avoid

- Secrets or per-player data in config: every server with READ can read every key.
- Polling fields for global settings, or reading configs per action through the network: read the cached namespace.
- A rotation as a random reward table: it has no odds, stock or rewards (removed in 7.0.0); build randomness with transactions.
- `leaderboards:submit` for a field-linked board: it counts twice.
- A code for something repeatable.

See [recipes](RECIPES.md) for complete examples of each.
