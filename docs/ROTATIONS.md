# Rotations (7.0.0)

A rotation is a **named list of items that take turns on a fixed clock**: a daily shop, a weekly featured
character, hourly weather. The game asks which items are active now and gets them back with the time of the
next change. Nothing else is stored; the answer is worked out from the saved list and the clock.

Use a universe-bound `bsa_` server key (Fields READ to read, READ_WRITE to save or delete). Keep it on the
server. The Fields `API_CONTRACT.md` (Rotations) is the wire source of truth.

## Quickstart

1. Save a rotation (once, from the portal's Rotations page, or in code with a READ_WRITE key):

```luau
client.fields:putRotation({
    path = { key = "daily_shop" },
    body = {
        items = {
            { id = "sword", data = { price = 100 } },
            { id = "shield", data = { price = 80 } },
            { id = "potion", data = { price = 15 } },
        },
        every = "1d",   -- "30m", "6h", "1d", "1w"
        show = 2,       -- optional: how many at once (default 1)
        order = "inOrder", -- optional: or "shuffled" (default "inOrder")
    },
})
```

2. Read it in the game:

```luau
local rotations = client.fields:rotations()
local result = rotations:current("daily_shop")
if result.ok then
    local shop = result.value
    for _, item in shop.items do
        print(item.id, item.data and item.data.price)
    end
    print("changes in", rotations:secondsLeft(shop), "seconds; next:", shop.next.items[1].id)
end
```

3. React when it changes (optional):

```luau
local watch = rotations:watch("daily_shop", function(shop)
    refreshShopUi(shop.items, shop.endsAt)
end)
-- later: watch:disconnect()   (client:destroy() stops every watch)
```

## The few settings

| Setting | Default | Meaning |
|---|---|---|
| `items` | required | `{ id, data? }`, 1 to 200. `data` is any JSON object (up to 4 KB) you want to read back |
| `every` | required | How often it changes: a number and `m`, `h`, `d` or `w`. 1 minute to 366 days |
| `show` | `1` | How many items are active at once |
| `order` | `inOrder` | `inOrder` walks the list and wraps. `shuffled` deals the items out in random order, none repeating until everyone had a turn; every server sees the same order |
| `startsAt` | Monday 2024-01-01 00:00 UTC | When the first period began. The default makes `1d` change at UTC midnight and `1w` on Mondays |

Editing a rotation changes what is active immediately. Pass `expectedVersion` to `putRotation` to refuse
overwriting someone else's newer edit (`0` means "must not exist yet").

## SDK reference

| Call | Returns |
|---|---|
| `rotations:current(name)` | `Result<Current>`: `items` (active now), `startsAt`, `endsAt` (Unix seconds), `version`, `next = { items, startsAt, endsAt }` |
| `rotations:secondsLeft(current)` | Seconds until the items change (display only, never negative) |
| `rotations:upcoming(name, count?)` | `Result<{ Period }>`: the next `count` (1 to 50, default 5) periods, starting with the active one |
| `rotations:watch(name, callback)` | Calls `callback(current)` now and whenever the active items change; returns a `Watch` with `disconnect()` and `lastError` |

`current` is cached per client until the period ends (and for at most 60 seconds so edits show up), so calling it
on every UI refresh costs nothing. If a refresh fails while the cached period is still running, the cached answer is
returned. An unknown name is a `NotFound` error with code `rotation_not_found`.

Saving, listing, reading, deleting and previewing a draft are plain generated calls:
`fields:putRotation`, `listRotations`, `getRotation`, `deleteRotation`, `previewRotation`
(`{ body = { key, items, every, show?, order?, startsAt?, count? } }`, read-only), `rotationSchedule`.

## Errors

`invalid_definition` (the message says which rule: duplicate item id, `show` larger than the list, a bad `every`...),
`rotation_not_found`, `rotation_version_conflict`.

## Examples

[Weather lighting](../examples/weather.luau) (a `watch`), [daily shop UI data](../examples/daily-shop.luau),
[live event](../examples/server/live-events.server.luau).
