# Build an RPG inventory

Step by step: an item catalog, one Inventory field with stackable items, gear with stats and equipped slots, gold and unlocks, plus the server code and a safety checklist.

## What you are building

A player inventory like an RPG has: stackable things (potions, ore) counted by name, individual pieces of gear that each have their own level, durability and stats, a set of equipped slots, gold, and unlocked cosmetics. This guide builds all of that from one item list and four fields, then shows the server code to give, use, equip, sell and trade items safely.

Items item list: what exists -> Inventory field: what the player holds -> Currency.Gold and Unlocks.Cosmetics -> Server code: validate, then one transaction

| Piece | Where it lives | What it holds |
|---|---|---|
| Items | Game config, an Item list | The catalog: every kind of item, with a label, a description and your own details (kind, slot, rarity, tradeable, sellValue). |
| Cosmetics (optional) | Game config, an Item list | A second catalog for things players only ever unlock, such as skins. |
| Inventory.Stacks | Member of the Inventory field | A lookup table: item name -> how many the player has (0 or more). |
| Inventory.Gear | Member of the Inventory field | A lookup table: instance id -> one piece of gear (item, level, durability, stats). Up to 200 pieces. |
| Inventory.Equipped | Member of the Inventory field | One slot each (Weapon, Head, Chest, Boots, Trinket): the instance id worn there, or empty. |
| Currency.Gold | Its own field | A whole number, never below 0, with a history of every change. |
| Unlocks.Cosmetics | Its own Item set field | Which Cosmetics the player has unlocked. |

> **Why one Inventory field.** Equipping needs to check that a piece is owned and set a slot at the same moment, and selling removes a piece and clears its slot. Transactions can span several fields (Gold and Inventory together), so this is not required, but keeping Stacks, Gear and Equipped in one field gives one definition, one starting value and one place to look. The trade-offs are listed in Alternatives and trade-offs.

## Reading the editor

The field editor is where most confusion happens, so here is what its controls mean. A lookup table is a two-column table: the left column is the name (the key), the right column is the value. Think of it as name -> value, like Potion -> 3.

| What you see | What it means |
|---|---|
| Lookup table (map) | A table of name -> value. You choose what the names look like and what each value holds. |
| Values contain | What each value on the RIGHT of the table holds. It does not describe the names on the left. Choices: Whole number, Text, Decimal, On/Off... and Custom (edit in Advanced) when the value is something the simple picker cannot show, such as an object. |
| Contains (List and Collection (set)) | What each entry holds. A set only offers Whole number and Text because its entries must be unique. |
| Names (keys) in a lookup table | Not in the simple view: names are Text (a string) by default. To change that, or to limit their length, open Advanced and use the box titled key (Type key). |
| Custom | A field built from named parts (an object). Choosing it opens Advanced, where you add each part yourself. |
| Advanced > Kind | The shape of that box: int (whole number), number, bool, string (text), enum, object (named parts), list, set, map (lookup table) or nullable (a value that may be empty). |
| Type, Type.Stacks, Type.Stacks value | Boxes inside boxes. The name tells you where you are: Type is the whole field, Type.Stacks is the part called Stacks, Type.Stacks value is what each entry of Stacks holds. |
| Optional (tick box next to a part) | Ticked: the part may be missing. Unticked: the part is required. Every part you add starts ticked, so untick it for parts that must always be there. |
| Explicit member default | A starting value for that part. You can leave it off: lookup tables start empty ({}) and nullable parts start empty (null). |
| nullable, shown as non-null type | A part that is either empty (null) or has a value of the chosen kind. The slot in Equipped is that: empty, or an instance id. |
| pruneZero | Only for a lookup table of numbers: an entry that reaches 0 is removed, so Potion -> 0 disappears. It switches itself off whenever you change the value box above it, so tick it last. |
| The grey code box at the end of Advanced | The JSON of what you built. Compare it with the JSON in this guide; they should match. |

> **There is no JSON paste box.** The field editor builds the type from controls (Kind, Add member, Optional, min, max); you cannot paste JSON into it. The JSON in this guide is exactly what the grey code box shows when you have built the same thing, and what you send if you create fields through the API. If the editor is reworked, the labels in the steps below may change: the JSON stays the same.

## Step 1: create the item lists

1. Open Game data, then Game config, and choose New namespace. Under What are you creating? pick Item list.
2. Name it Items and choose the template Blank. Creating it needs ConfigService ADMIN.
3. Choose Add member for each kind of item. A member name is permanent (letters, digits, '_', '.' or '-', up to 100 characters): use Potion, IronSword, DragonHelm. Fill in Label and Description for people.
4. In Extra details (JSON) put your own details, for example the JSON below. The platform never reads it, but your game does: kind decides whether the item is a stack or a gear piece.
5. Repeat for Cosmetics if you want unlockable skins: create a second Item list named Cosmetics and add members such as GoldenCape.

```json
{
  "kind": "gear",
  "slot": "Weapon",
  "rarity": "rare",
  "tradeable": true,
  "sellValue": 250
}
```

The platform assigns each member a permanent Bit number automatically; you never type it and your code only uses names. Retire a member (do not remove it) when you stop giving it out: players keep it, nobody new gets it. See Item lists for the rules and the 512-member limit.

| Member | Extra details (JSON) |
|---|---|
| Potion | {"kind":"stack","rarity":"common","tradeable":true} |
| IronSword | {"kind":"gear","slot":"Weapon","rarity":"common","tradeable":true,"sellValue":50} |
| DragonHelm | {"kind":"gear","slot":"Head","rarity":"epic","tradeable":false,"sellValue":900} |

## Step 2: create the fields

Open Fields, choose New field, and create the three fields below. Creating fields needs FieldsService ADMIN.

## Currency.Gold

1. Name: Currency.Gold. Under What kind of value? choose Whole number (Currency/Count). Minimum is already 0 and Starts at 0.
2. Tick Keep a history of every change. This stores the field as history LEDGER, so every change records who, why and which transaction.
3. Choose Save field. If it asks for a Reason, it is under Advanced.

```json
{
  "kind": "int",
  "min": 0
}
```

## Inventory

This one cannot be made with the simple picker because it is an object whose parts are lookup tables. Build it in Advanced; every step below is one click or one box.

1. New field. Name: Inventory. Under What kind of value? choose Custom. Advanced opens by itself with a box named Type whose Kind is object and that has no parts yet.
2. In the box Type new member name type Stacks and choose Add member. Untick Optional next to Stacks. In the box named Type.Stacks change Kind from int to map.
3. Still in Type.Stacks: the box Type.Stacks key (Kind string) is the names. Set minLength 1 and maxLength 100. The box Type.Stacks value (Kind int) is what each entry holds: set min 0 and max 999999. Set maxSize to 500. Tick pruneZero last.
4. Add the next part: Type new member name Gear, Add member, untick Optional, change Kind to map. In Type.Gear key set minLength 32, maxLength 32 and Safe pattern ^[0-9A-Fa-f]+$ (a 32 character instance id). Set maxSize to 200.
5. In Type.Gear value change Kind from int to object. It now has its own Add member box. Add item (change Kind to string: minLength 1, maxLength 100), level (Kind int, min 1, max 999) and durability (Kind int, min 0, max 100000). Untick Optional on each of these three.
6. Add stats to Type.Gear value the same way: Kind map, key Kind string with minLength 1 and maxLength 32, value Kind int with min -100000 and max 100000, maxSize 16. Untick Optional on stats.
7. Add the part Equipped (untick Optional, change Kind to object). Inside it add Weapon, Head, Chest, Boots and Trinket. For each: change Kind to nullable, then in its non-null type box set Kind string with minLength 32 and maxLength 32. Untick Optional on each so an empty slot reads as null.
8. Check the grey code box matches the JSON below and that Advanced starting value shows Stacks {}, Gear {} and Equipped with five nulls. Tick Keep a history of every change if you want a record of every inventory change. Choose Save field.

```json
{
  "kind": "object",
  "members": {
    "Stacks": {
      "type": {
        "kind": "map",
        "key": {
          "kind": "string",
          "minLength": 1,
          "maxLength": 100
        },
        "value": {
          "kind": "int",
          "min": 0,
          "max": 999999
        },
        "maxSize": 500,
        "pruneZero": true
      }
    },
    "Gear": {
      "type": {
        "kind": "map",
        "key": {
          "kind": "string",
          "minLength": 32,
          "maxLength": 32,
          "pattern": "^[0-9A-Fa-f]+$"
        },
        "value": {
          "kind": "object",
          "members": {
            "item": {
              "type": {
                "kind": "string",
                "minLength": 1,
                "maxLength": 100
              }
            },
            "level": {
              "type": {
                "kind": "int",
                "min": 1,
                "max": 999
              }
            },
            "durability": {
              "type": {
                "kind": "int",
                "min": 0,
                "max": 100000
              }
            },
            "stats": {
              "type": {
                "kind": "map",
                "key": {
                  "kind": "string",
                  "minLength": 1,
                  "maxLength": 32
                },
                "value": {
                  "kind": "int",
                  "min": -100000,
                  "max": 100000
                },
                "maxSize": 16
              }
            }
          }
        },
        "maxSize": 200
      }
    },
    "Equipped": {
      "type": {
        "kind": "object",
        "members": {
          "Weapon": {
            "type": {
              "kind": "nullable",
              "of": {
                "kind": "string",
                "minLength": 32,
                "maxLength": 32
              }
            }
          },
          "Head": {
            "type": {
              "kind": "nullable",
              "of": {
                "kind": "string",
                "minLength": 32,
                "maxLength": 32
              }
            }
          },
          "Chest": {
            "type": {
              "kind": "nullable",
              "of": {
                "kind": "string",
                "minLength": 32,
                "maxLength": 32
              }
            }
          },
          "Boots": {
            "type": {
              "kind": "nullable",
              "of": {
                "kind": "string",
                "minLength": 32,
                "maxLength": 32
              }
            }
          },
          "Trinket": {
            "type": {
              "kind": "nullable",
              "of": {
                "kind": "string",
                "minLength": 32,
                "maxLength": 32
              }
            }
          }
        }
      }
    }
  }
}
```

- Writes use the default write level (READ_WRITE), so a normal server key can change Inventory. Tick Only admins can change this only if you want to block ordinary server keys.
- Object parts allow at most 64 names made of letters, digits and underscores, starting with a letter; nesting can go 8 levels deep. This design uses 5.
- A lookup table holds at most 1000 entries by default and 10000 at most; the whole field value is limited to 256 KiB. With these limits the worst case is about 160 KiB.

## Unlocks.Cosmetics

1. New field. Name: Unlocks.Cosmetics. Choose Item set (from an item list). Pick the Item list Cosmetics. Set an optional Limit of 64 members. Save field.

```json
{
  "kind": "bitmap",
  "source": "Cosmetics",
  "maxMembers": 64
}
```

> **Item sets cannot be nested.** An Item set must be a whole field of its own. It cannot be a part of Inventory or the value of a lookup table, which is why cosmetics are a separate field. In code use profile:grant("Unlocks.Cosmetics", { "GoldenCape" }); see Item lists.

## Step 3: try it in dev first, then promote

1. Switch the Environment dropdown next to the universe selector to Dev. Everything above (Items, Cosmetics, the fields) can be created there first; dev starts empty and is never billed.
2. Test with a development key (bsd_) in a test place: run the code below, then open Players and look at the Inventory value.
3. When it behaves, open Game data, then Transfer. It compares dev with prod. Tick the fields and the item lists, choose Check, then Apply to prod with a reason.
4. Transfer copies structure only. It never copies player data, so no dev test items can appear in prod.

## Step 4: the server code

Everything runs on the server. Never let a RemoteEvent choose a field, an operation, a price, an amount or an item name without checking it: the client asks ("equip this piece"), the server decides. Each block builds on the previous one. Every write is one transaction, which either fully happens or does not happen at all.

## Load the profile

```luau
local BloxSDK = require(game.ServerScriptService.BloxSDK)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- "client" is the BloxSDK client you created at startup (see Installation).
local INVENTORY, GOLD = "Inventory", "Currency.Gold"
local SLOTS = { "Weapon", "Head", "Chest", "Boots", "Trinket" }

-- Start the shared live copy of the Items list now; profiles also wait briefly for it.
local items = client.configs:namespace("Items")
items:waitReady(5)

local profiles = {}
Players.PlayerAdded:Connect(function(player)
    local loaded = client.fields:loadProfile(player)
    if loaded.ok then
        profiles[player] = loaded.value
    else
        warn(loaded.error.code)
    end
end)
Players.PlayerRemoving:Connect(function(player)
    profiles[player] = nil
end)

-- A nullable slot that is empty reads as BloxSDK.null (a present JSON null), never as nil.
local function slotValue(equipped, slot)
    local value = equipped[slot]
    if value == nil or value == BloxSDK.null then
        return nil
    end
    return value
end

-- Turn a failed Result into a short word your game can act on.
local function outcome(result): string
    if result.ok then
        return "ok"
    end
    local code = result.error.code
    if code == "below_min" then return "not_enough" end
    if code == "above_max_size" or code == "value_too_large" then return "inventory_full" end
    if code == "above_max" then return "stack_full" end
    if code == "precondition_failed" then return "changed" end
    warn(code)
    return "unavailable"
end
```

## Check names against the catalog and read the inventory

```luau
-- "ok", or why the name cannot be used. Never trust a name sent by a client.
local function checkItem(name: string, kind: string): string
    if not items:waitReady(5) then
        return "catalog_unavailable"
    end
    local member = items:member(name)
    if not member then return "unknown_item" end
    if member.retired then return "retired" end
    local meta = member.meta
    if not meta or meta.kind ~= kind then return "wrong_kind" end
    return "ok"
end

local function isTradeable(name: string): boolean
    local member = items:member(name)
    return member ~= nil and not member.retired and member.meta ~= nil and member.meta.tradeable == true
end

-- A list that is friendly to a UI: stacks with labels, gear pieces and what is equipped.
local function inventorySummary(player)
    local profile = profiles[player]
    if not profile then return nil end
    local read = profile:tryGet(INVENTORY)
    if not read.ok then return nil end
    local inventory = read.value

    local stacks = {}
    for name, count in inventory.Stacks do
        local member = items:member(name)
        table.insert(stacks, { name = name, label = member and member.label or name, count = count })
    end
    table.sort(stacks, function(a, b) return a.name < b.name end)

    local gear = {}
    for id, piece in inventory.Gear do
        table.insert(gear, { id = id, item = piece.item, level = piece.level, durability = piece.durability })
    end
    table.sort(gear, function(a, b) return a.id < b.id end)

    local equipped = {}
    for _, slot in SLOTS do
        equipped[slot] = slotValue(inventory.Equipped, slot) -- an instance id or nil
    end
    return { stacks = stacks, gear = gear, equipped = equipped }
end
```

- items:member(name) reads the cached Items list: it returns nil for a name that does not exist, and the member has label, meta (your Extra details) and retired. Only activeMembers() leaves retired members out.
- The list reaches a game server within one config poll (30 seconds by default), so a member you just added may be unknown for a moment.

## Give and use stackable items

```luau
-- Give a stackable item. Returns "ok", "unknown_item", "retired", "wrong_kind",
-- "inventory_full", "stack_full", "changed" or "unavailable".
-- Pass an intentKey you persisted (for example "quest-7-" .. player.UserId) so a retry after a crash
-- cannot grant twice: the same key returns the original result.
local function giveStack(player, name: string, count: number, reason: string, intentKey: string?)
    local profile = profiles[player]
    if not profile then return "unavailable" end
    if count < 1 or count ~= math.floor(count) then return "bad_count" end
    local status = checkItem(name, "stack")
    if status ~= "ok" then return status end
    local transaction = profile:immediate()
        :mapAdd(INVENTORY, name, count, { "Stacks" })
        :reason(reason)
    if intentKey then
        transaction:key(intentKey)
    end
    return outcome(transaction:commit())
end

-- Use up some of a stack. The field's minimum of 0 is the guard: if the player holds fewer than
-- "count", the server refuses the whole transaction with below_min and nothing changes.
local function consumeStack(player, name: string, count: number, reason: string)
    local profile = profiles[player]
    if not profile then return "unavailable" end
    if count < 1 or count ~= math.floor(count) then return "bad_count" end
    local result = profile:immediate()
        :mapAdd(INVENTORY, name, -count, { "Stacks" })
        :reason(reason)
        :commit()
    return outcome(result) -- "not_enough" when the player had too few
end
```

There is no condition that says count >= 1: conditions can only test equality, existence or the whole field's version. The correct supported way is the field's own bound. The value minimum of 0 makes a decrease below zero fail with below_min, and the server applies that check atomically on its locked copy, so two quick uses cannot spend the same potion twice.

## Create a piece of gear

```luau
-- A new instance id: 32 hex characters, generated on the server, never taken from a client.
local function newInstanceId(): string
    return (string.gsub(HttpService:GenerateGUID(false), "-", ""))
end

-- Create one piece of gear. Returns the outcome and the instance id.
-- To retry after an uncertain failure, call again with the SAME instanceId: the same id gives the
-- same idempotency key, so the server returns the first result instead of making a second piece.
local function giveGear(player, name: string, level: number, stats, reason: string, instanceId: string?)
    local profile = profiles[player]
    if not profile then return "unavailable", nil end
    local status = checkItem(name, "gear")
    if status ~= "ok" then return status, nil end
    local id = instanceId or newInstanceId()
    local result = profile:immediate()
        :mapPut(INVENTORY, { [id] = { item = name, level = level, durability = 100, stats = stats or {} } }, { "Gear" })
        :expect(INVENTORY, { exists = false }, { "Gear", id }) -- refuse to overwrite an existing piece
        :reason(reason)
        :key("gear-" .. id)
        :commit()
    return outcome(result), id
end
```

## Equip and unequip

```luau
-- Equip a gear instance into the slot its catalog entry names.
-- Returns "ok", "not_owned", "wrong_slot", "retired", "changed" or "unavailable".
local function equip(player, instanceId: string)
    local profile = profiles[player]
    if not profile then return "unavailable" end
    local read = profile:tryGet(INVENTORY)
    if not read.ok then return "unavailable" end
    local inventory = read.value

    local piece = inventory.Gear[instanceId]
    if not piece then return "not_owned" end
    local member = items:member(piece.item)
    if not member or member.retired then return "retired" end
    local slot = member.meta and member.meta.slot
    if not slot or not table.find(SLOTS, slot) then return "wrong_slot" end

    local current = slotValue(inventory.Equipped, slot)
    local result = profile:immediate()
        :set(INVENTORY, instanceId, { "Equipped", slot })
        :expect(INVENTORY, { exists = true }, { "Gear", instanceId }) -- still owned
        :expect(INVENTORY, { equals = piece.item }, { "Gear", instanceId, "item" }) -- still that item
        :expect(INVENTORY, { equals = current or BloxSDK.null }, { "Equipped", slot }) -- slot is as we read it
        :reason("equip")
        :commit()
    return outcome(result)
end

local function unequip(player, slot: string)
    local profile = profiles[player]
    if not profile then return "unavailable" end
    local read = profile:tryGet(INVENTORY)
    if not read.ok then return "unavailable" end
    local current = slotValue(read.value.Equipped, slot)
    if current == nil then return "ok" end -- already empty
    local result = profile:immediate()
        :set(INVENTORY, BloxSDK.null, { "Equipped", slot })
        :expect(INVENTORY, { equals = current }, { "Equipped", slot })
        :reason("unequip")
        :commit()
    return outcome(result)
end
```

The three expect lines are the safety net: the piece must still exist, still be that item, and the slot must still hold what you read. If another server action changed any of them first, the whole transaction is refused with precondition_failed and you can read again and retry.

## Destroy or sell gear

```luau
-- Sell a gear instance for gold in ONE transaction. The price comes from the server's catalog
-- (meta.sellValue), never from the client. Returns "ok", "not_owned", "retired", "changed" or "unavailable".
local function sell(player, instanceId: string)
    local profile = profiles[player]
    if not profile then return "unavailable" end
    local read = profile:tryGet(INVENTORY)
    if not read.ok then return "unavailable" end
    local inventory = read.value

    local piece = inventory.Gear[instanceId]
    if not piece then return "not_owned" end
    local member = items:member(piece.item)
    local price = member and member.meta and member.meta.sellValue
    if type(price) ~= "number" or price < 1 then return "retired" end

    local transaction = profile:immediate()
        :mapRemove(INVENTORY, { instanceId }, { "Gear" })
        :add(GOLD, price)
        :expect(INVENTORY, { exists = true }, { "Gear", instanceId })
        :reason("sell gear")
    -- If it is equipped, clear that slot in the same transaction.
    for _, slot in SLOTS do
        if slotValue(inventory.Equipped, slot) == instanceId then
            transaction
                :set(INVENTORY, BloxSDK.null, { "Equipped", slot })
                :expect(INVENTORY, { equals = instanceId }, { "Equipped", slot })
        end
    end
    return outcome(transaction:commit())
end
```

Removing the piece, paying gold and clearing the slot are one transaction, so there is no moment where the player has both the gold and the gear, or neither.

## Swap gear between two players

```luau
-- Swap one tradeable piece from "a" to "b" (an approved, server-checked trade). Both players must be
-- in this server. Players cannot trade a piece that is equipped: unequip it first.
local function giveGearTo(a, b, instanceId: string)
    local profileA, profileB = profiles[a], profiles[b]
    if not profileA or not profileB then return "unavailable" end
    local read = profileA:tryGet(INVENTORY)
    if not read.ok then return "unavailable" end
    local piece = read.value.Gear[instanceId]
    if not piece then return "not_owned" end
    if not isTradeable(piece.item) then return "not_tradeable" end
    for _, slot in SLOTS do
        if slotValue(read.value.Equipped, slot) == instanceId then return "equipped" end
    end
    local result = client.fields:multiTransactionBuilder()
        :subject(a.UserId)
        :mapRemove(INVENTORY, { instanceId }, { "Gear" })
        :expect(INVENTORY, { exists = true }, { "Gear", instanceId })
        :subject(b.UserId)
        :mapPut(INVENTORY, { [instanceId] = piece }, { "Gear" })
        :expect(INVENTORY, { exists = false }, { "Gear", instanceId })
        :reason("trade gear")
        :commit()
    if result.ok then
        profileA:refresh() -- raw transactions do not update loaded profiles by themselves
        profileB:refresh()
    end
    return outcome(result)
end
```

A multi-player transaction changes both inventories or neither, with at most 10 players per transaction. This is a one-way gift to show the shape; a full two-sided trade with an approval step is described in Player trading (TRADING.md).

## What can come back

| Result word | Meaning and what to do |
|---|---|
| ok | It happened. |
| unknown_item / retired / wrong_kind | The name is not in Items, was retired, or is a gear item used as a stack (or the reverse). Do not retry. |
| not_enough | A stack was too small (below_min). Tell the player. |
| inventory_full | A table is at its maxSize or the field would pass 256 KiB (above_max_size, value_too_large). Ask the player to sell something. |
| not_owned | The instance id is not in Gear (maybe sold already). Refresh the UI. |
| changed | Another change got there first (precondition_failed). Read again and retry once. |
| unavailable | The profile is not loaded, or a service error (check the logged code). Safe to retry with the same key. |

## Anti-dupe and safety checklist

- Only the server writes. A RemoteEvent carries intent (an instance id to equip), never an item name to give, a count, a price or a field name.
- Check every item name against the Items catalog before writing, and check meta.kind and meta.tradeable.
- Make instance ids on the server with HttpService:GenerateGUID(false), remove the dashes, and write them with mapPut plus expect exists = false.
- Use profile:immediate() for anything valuable and check result.ok. Buffered writes (profile:add and profile:set) are saved up to five seconds later and are not proof of durability.
- Give each logical action one idempotency key and reuse it on retry (:key(...)). A new key means a new action, so never generate a fresh key to retry.
- Spend before you give: consume the ingredient and grant the result in the same transaction rather than in two calls.
- Sell, trade and craft in one transaction (removal plus payment), never one call after another.
- Add expect conditions on the exact values you read (the slot, the piece). They stop two actions racing on the same inventory.
- Keep history on for gold and inventory so you can see exactly who changed what, when and why.
- Retire catalog items, do not remove them; removing is refused while anyone holds the item.

## Limits and when to split

| Limit | Value | What to do near it |
|---|---|---|
| Whole field value | 256 KiB (value_too_large) | Split gear into its own field, or lower maxSize and the number of stats. |
| Lookup table entries | 1000 by default, 10000 at most (above_max_size) | Choose a maxSize that matches your design; 200 gear and 500 stacks here. |
| Object parts | 64, names letters, digits and underscores | Group related parts into nested objects. |
| Nesting depth | 8 levels | Inventory > Gear > piece > stats > number uses 5. |
| Operations per transaction | 100 operations, 100 conditions, 10 players | Batch less per call. |
| Item list | 512 members ever (including retired) | One list per event; see Item lists. |

## Alternatives and trade-offs

The fully split layout puts each piece in its own field: Inventory.Stacks (a lookup table), Inventory.Gear (a lookup table of objects), Inventory.Equipped (an object) and Currency.Gold. In that layout the simple editor can build Inventory.Stacks directly: Lookup table (map), Values contain: Whole number. For Inventory.Gear, Values contain shows Custom (edit in Advanced) because the values are objects, and you set them in the same Advanced boxes as above.

| Question | One Inventory object | Split into separate fields |
|---|---|---|
| Versions and conflicts | One version for the whole field: expect version fails on any change to Inventory. Path conditions (equals, exists) only fail when the specific value changed. | Each field has its own version, so unrelated changes (a potion and an equip) do not conflict. |
| Size cap | 256 KiB is shared by Stacks, Gear and Equipped. | 256 KiB each. |
| Who can write | One write level for all of it. | Each field can have its own: for example admin-only Gear. |
| History | One ledger setting for all of it; each entry shows the touched part. | A ledger per field, so you can keep history for Gear and skip it for Stacks. |
| Changing the structure later | A new part must be optional or have a default; parts cannot be removed; kinds cannot change through the editor. | Same rules, but a migration or a type change affects only the one field. |
| Several parts in one action | One transaction, one field. | Still one transaction: a transaction can span many fields, but the equip check across fields (is it owned?) needs a condition on each field. |
| Cost of a write | The service validates the whole Inventory value on every change, including a change to one stack. It is not guaranteed to be cheaper for a small path. | Smaller values to validate for a small change. |

## FAQ

| Question | Answer |
|---|---|
| Can I add a new part to Inventory later? | Yes: a new part (for example Bank) must be optional or have a default, because existing players already have a stored value. You cannot remove a part or change its kind through the editor; the field's change-type migration covers kind changes. |
| Can I add a new slot to Equipped? | Yes, the same way: a new nullable slot has no stored value for existing players, so give it Optional ticked or an explicit default. |
| Does a path write rewrite the whole value? | The service always validates the whole field after a change. Whether it stores less is not guaranteed, so plan for the whole value. |
| Why can a path be at most 8 long, and how are numbers written? | Paths are at most 8 segments. List positions are numbers starting at 0; lookup table names are always text, even if they look like numbers ("42"). |
| Why not make Stacks keys an enum? | An enum lists names inside the field definition, so every new item would need a definition change. Keep the names in the Items list instead. |

## Common errors and fixes

| Code or HTTP status | Next action |
|---|---|
| below_min | A value would drop under its minimum: a stack below 0, durability below 0, level below 1. Check the count first or treat it as not_enough. |
| above_max_size | A lookup table reached its maxSize (500 stacks or 200 gear). Remove entries or raise maxSize in the definition. |
| value_too_large | The whole Inventory value would pass 256 KiB. Lower sizes or split the field. |
| missing_member | A piece of gear was written without a required part (item, level, durability or stats). Send all four; use stats = {} when there are none. |
| unknown_member | A name that is not a part of the object (for example Equipped.Shield, or a typo in a gear part). Check the spelling against the definition. |
| precondition_failed | An expect condition no longer holds (the piece was sold, the slot changed, the id already exists). Read the profile again, decide again and use a new key for the new decision. |
| invalid_map_key | A lookup table name breaks its key rules: for Gear it must be 32 hex characters. Generate the id with GenerateGUID(false) and remove the dashes. |
| pattern_mismatch | The text does not match the key pattern (an instance id with dashes or braces). |
| above_max_length | A name is longer than its maxLength (an item name over 100 characters, an instance id over 32). |
| op_not_applicable | The operation does not fit the target: mapAdd needs the path of a lookup table of numbers ({ "Stacks" }), set targets a part. |
| null_path | The path goes through an empty (null) value. Use the part itself, for example { "Equipped", slot }, not a path inside an empty slot. |
| invalid_path | A path segment is wrong for its place: a number for an object part, a missing part name. Paths are part names and lookup names, at most 8. |
| not_found | The entry you addressed is not there. |
| new_member_requires_default | You added a required part to a saved object. Make the new part Optional or give it an explicit default. |
| member_removed | A saved field's parts cannot be removed. Leave it unused, or migrate. |
| incompatible_type | A saved part cannot change its kind in the editor. Use Change type safely or add a new part. |

See also: [Full error index](ERRORS.md), Retry and idempotency rules

See also: [Item lists](ITEM-LISTS.md), [Choose and create fields](FIELDS.md), [Player trading](TRADING.md), [Validated transactions](TRANSACTIONS.md), [Recipe: equipment with an equipped slot](RECIPES.md), [Environments and transfer](ENVIRONMENTS.md), [Error index](ERRORS.md)
