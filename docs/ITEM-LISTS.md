# Item lists

An **item list** is a named list of things a game can hand out: swords, hats, badges, unlocked levels, event rewards.
Each entry is a **member**. A player holds some of the members, and the game grants or takes them away by name.

Item lists are one idea with two halves:

- **The list** lives in `client.configs`. A config namespace is either **Settings** (free-form keys with JSON values,
  see [CONFIGS.md](CONFIGS.md)) or an **Item list** (named members). You make a namespace an item list once.
- **What a player holds** lives in a Fields field of type **Item set** (kind `bitmap`) that points at the list, see
  [FIELDS.md](FIELDS.md).

A member is `{ bit, label?, description?, meta?, retired? }`. The server assigns `bit` when the member is created. Bits
are permanent: they never change and are never reused, even after the member is removed. A list has at most 512 members
(removed and retired ones still count). `label` (100 characters), `description` (500) and `meta` (a JSON object of your
own) are for people and tools; the game logic only ever uses the member name.

## Quickstart

Create the list once, from an admin script or the portal (needs ConfigService ADMIN):

```luau
local items = client.configs:namespace("Items")
items:setKind("items")
items:addMember("Sword", { label = "Iron Sword" })
items:addMember("Shield", { label = "Wooden Shield" })
```

Define the field once (needs FieldsService ADMIN). `source` names the list and can never change; `maxMembers` is how many
members one player may hold in this field (1 to 512, and `1` means "exactly one choice", like an equipped slot):

```json
{ "id": "Owned", "type": { "kind": "bitmap", "source": "Items", "maxMembers": 64 } }
```

Use it in game code, with names only:

```luau
local loaded = client.fields:loadProfile(player) -- Result<Profile>, check loaded.ok
local profile = loaded.value
profile:grant("Owned", { "Sword" })        -- gain
profile:revoke("Owned", { "Sword" })       -- lose; revoking something not held does nothing
profile:replace("Equipped", { "Shield" })  -- the whole set, may be {}
if profile:has("Owned", "Sword").value then ... end
local all = profile:members("Owned")        -- Result<{ string }>, sorted
local usable = profile:usable("Events.Halloween")   -- Result<{ string }>: held and still active, sorted
-- "Is Pumpkin_Hat usable?" is table.find(usable.value, "Pumpkin_Hat") ~= nil
```

Everything on the profile behaves like any other profile mutation: changes are applied locally at once, buffered, and
saved with the next flush; a failed save is retried with the same commit id, so a grant is never applied twice. `grant`
and `revoke` are idempotent and order-safe (grant then revoke, in that order, always ends without the member).
Runnable versions: [equipment](../examples/server/equipment.server.luau),
[event items](../examples/server/event-items.server.luau), [admin](../examples/item-lists-admin.luau).

## Reading the list

`client.configs:namespace("Items")` is a cached handle (see [CONFIGS.md](CONFIGS.md)). For an item list it also has
`kind()`, `members()` (name to `{ bit, label?, description?, meta?, retired? }`), `activeMembers()` (the same without
retired ones) and `member(name)`. Fields reads those cached members to check a grant before it is sent.

## Recipes

- **Equipment slot.** An `Owned` field (`maxMembers = 64`) and an `Equipped` field (`maxMembers = 1`) over the same list.
  `replace("Equipped", { name })` swaps the item; `replace("Equipped", {})` unequips. Require `has("Owned", name)` first.
- **Event-only items.** Put the items in their own list (`Event_Halloween`). When the event ends, retire the members
  you no longer want to give out. `usable("Events.Halloween")` leaves a retired member out, so players keep it (`has` stays true) but it is no longer usable.
- **Badges and unlocks.** One list, one field with `maxMembers = 512`, `grant` once, `has` to check.
- **Retire a seasonal item.** `items:retireMember("Pumpkin_Hat")`; nothing is lost and nobody new can get it.
- **Trade items between players.** `revoke` of an item that is not held does nothing, so a trade needs an `expect` version
  condition on the item set of every player whose items move. See [player trading](TRADING.md).

## Retire or remove

| | `retireMember` | `removeMember` |
|---|---|---|
| New grants | refused (`member_retired`) | refused (`unknown_member`) |
| Players who hold it | keep it, `has` stays true, `usable` leaves it out | not allowed while anyone holds it |
| Bit | kept | kept forever, never reused |
| Undo | `unretireMember` | create it again: it gets its old bit |
| Held by players | always allowed | `409 member_in_use` |

Deleting, patch-deleting or rolling back a member that any player holds fails with `member_in_use`. The error carries
`holders`: for each member the holder `count` and up to 5 `samplePlayers`, plus a hint to retire instead. If the holder
check cannot answer, the removal is refused with `503 holder_check_unavailable` (it fails closed). Retire is always
allowed. `items:usage()` gives holder counts per member (fast, from counters); `items:holders("Sword")` scans real
values for one member (slow, exact).

## Errors

All on the Fields write path unless noted; see [ERRORS.md](ERRORS.md) for the full table and recovery.

| Code | Meaning |
|---|---|
| `unknown_member` | a name is not in the list (`members` lists up to 20) |
| `member_retired` | grant or replace of a retired member |
| `member_limit` | the result would hold more than the field's `maxMembers` |
| `invalid_member_name` | a name is not `[A-Za-z0-9_][A-Za-z0-9_.-]*` or up to 100 characters |
| `enum_source_unavailable` | the list has never loaded (first use or config service down); retry |
| `member_in_use`, `holder_check_unavailable` | removal refused (config namespace) |
| `kind_immutable`, `invalid_member`, `bit_immutable`, `bit_taken` | admin shape errors (config namespace) |

## Limits

512 members per list, 512 per field value, 20 names in an error, 5 sample players per holder, 100 characters for a
label, 500 for a description. One list can back many fields; a field's `source` cannot be changed after it is created.

## Caching and staleness

The SDK checks grants locally against the cached list when it has loaded, so a typo fails immediately and without a
request. The server is always the authority: a member added or retired in the portal takes up to about 5 seconds on the
server and one config poll (30 s by default) in the SDK. If the local cache is behind, the server's answer wins and the
local profile is corrected. Until the list has loaded, grants fail closed with `enum_source_unavailable` instead of
guessing, and `has`, `members` and `usable` ask the server (`GET .../players/{userId}/members/{field}`) so they still
return the truth. `usable` always needs the current list, so it is the one to use when "retired" matters.

## Operations calls

Most games only need the profile calls above. Operators also have these `client.fields` calls (HTTP routes in
[ENDPOINTS.md](ENDPOINTS.md)): `itemListUsage` (the same data as `items:usage()`), `itemListHolders`, `itemListSource` (how fresh
the Fields copy of the list is: `version`, `ageSeconds`, `lastError`), `itemListVerifyHolders` (ADMIN; compares and optionally
repairs the holder counters) and `playerMembers` (what the profile reads fall back to). `itemListRemovalCheck` is called by
ConfigService before a removal; game and admin code never need it. Per-player data usage, per-key usage and the right-to-erasure
webhook are HTTP-only: the SDK has no wrapper for them.

| Task | Key level |
|---|---|
| Create or edit a list (`setKind`, `addMember`, `retireMember`, `removeMember`, ...) | ConfigService ADMIN |
| Read the list (`members`, `activeMembers`) | ConfigService READ |
| `grant`, `revoke`, `replace` | FieldsService READ_WRITE |
| `has`, `members`, `usable`, `usage()`, `holders()` | FieldsService READ |
| `itemListVerifyHolders` | FieldsService ADMIN |

## Technical note

The stored field value is a canonical lowercase hex little-endian bitmap (bit `b` is byte `b/8`, mask `1 << (b % 8)`,
trailing zero bytes trimmed, `""` is empty, at most 64 bytes), `SET` accepts it for restore tools. Game code should not
compute bits.
