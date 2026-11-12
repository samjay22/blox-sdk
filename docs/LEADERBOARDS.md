# Leaderboards and ratings

Both live on `client.leaderboards`. Most games never call `submit`: a board **created from a field** on the portal's
Leaderboards page is fed by that field automatically. Use `submit` only for boards that have no field behind them.

## Boards fed by a field (recommended)

1. Create the stored Whole number PLAYER field (for example `Currency.Gems`) on the Fields page.
2. On the Leaderboards page choose New board and pick the field under *Rank players by a field*. The board is created and
   **linked to the field in the same step** (needs FieldsService ADMIN). Name, mode, order and reset are under Advanced.
3. Read standings from the game; never submit the same score yourself, because that counts twice.

| Rank by | Stores | Backfilled on link? |
|---|---|---|
| Current value (VALUE + LAST) | The latest field value | **Yes**: every player's saved value is queued once |
| Best ever (VALUE + BEST) | The best value for the board's order and period | **Yes**: same |
| Total gained (DELTA / SUM) | The sum of submitted changes, negative ones included | **No**: only changes made after linking count |

*Total gained* is net change: gaining 10 and spending 4 is +6. For lifetime earnings use a dedicated increasing counter.
A reset starts a new board period; it never resets the field. For weekly wins rank a lifetime wins counter by Total gained
with a weekly reset. Decimal and calculated fields cannot rank. A field can feed at most 32 boards; board names are 1-64
letters, digits, `_` or `-`. Archived board names stay reserved.

### How fresh are standings?

```
field change -> durable outbox row (same step as the write) -> dispatcher -> leaderboard service -> ranking job -> reads
```

Delivery is asynchronous, and the **ranking job runs every minute**, so a change can take up to about a minute (plus delivery
time) to appear. A saved field change is not proof that the standing is visible. Cache a standings screen for about a minute.

## Reading standings

```luau
local top = client.leaderboards:top({ path = { name = "gems" }, query = { limit = 10 } })
if top.ok then
	for _, standing in top.value.items do print(standing.rank, standing.userId, standing.score) end
end
local mine = client.leaderboards:user({ path = { name = "gems", userId = player.UserId } }) -- rank, score, percentile, total
local near = client.leaderboards:around({ path = { name = "gems", userId = player.UserId } }) -- neighbours
```

Use `topPages`, `listPages`, `periodsPages` for bounded lazy cursor iteration. Every yielded page is a Result; stop on error
rather than treating an incomplete list as success. Reads need `LeaderboardService READ` plus Gateway.

## Boards without a field (manual submit)

Provision a board with trusted administration, then
`submit({path={name="wins"},body={userId=player.UserId,score=score}}, {idempotencyKey=persistedIntent})`.
The option maps to wire `submissionId`. Never reuse an intent for a different score. Batch submission needs one key per item;
a single common key option is rejected for batch operations. Do not double-submit to a field-linked board.

## Ratings

Ratings use `ratingScopes`, `ratingConfig`, `ratingUser`, `ratingTopPages` and `ratingMatch`. Match results must come from a
trusted completed match, with one persisted `matchId` for replay. The backend computes ratings (Elo); never accept a rating
delta from a client.

## Errors

| Code | Meaning |
|---|---|
| `leaderboard_board_mismatch` (422) | Order, reset or aggregation conflicts with another field on the board |
| `leaderboard_board_archived` (422) | The name is reserved by an archived board |
| `leaderboard_score_range` (422) | Explicit VALUE bounds are unsupported |
| `leaderboard_unavailable` (503) | The leaderboard service could not be reached; the field definition was not saved |
| `NotFound` on `user` | The player has no score on the board |

## Troubleshooting

| Symptom | Fix |
|---|---|
| Board empty after linking | Wait a minute; a Total gained board has no backfill |
| Field saved, rank unchanged | Ranks refresh every minute and delivery is asynchronous; ask an operator to check outbox health |
| Weekly board looks cumulative | Current value resubmits the lifetime value; use Total gained with a weekly reset |

See [API](api/leaderboards.md), [native leaderboard](../examples/server/leaderboard.server.luau),
[ratings](../examples/server/ratings.server.luau), [recipes](RECIPES.md) and [choosing a feature](CHOOSING.md).
