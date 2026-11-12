# Runnable Roblox server examples

`server/` contains 16 complete Roblox server scripts and one shared Client ModuleScript. They use the
real SDK, not fake backends. Root-level `.luau` modules are portable, composable/tested gameplay helpers;
they are not standalone Scripts. Native scripts are strictly analyzed against the same SDK by replacing
only Instance require expressions with equivalent portable imports (`tools/verify-examples.py`).

## Setup

1. Map/build `roblox/` as **ServerStorage.BloxSDK** (or adjust Client.luau to your server Wally package).
2. Map `examples/server/` into ServerScriptService as a Folder. `Client.luau` is a ModuleScript;
   `.server.luau` files are Scripts. Never place these or credentials in ReplicatedStorage.
3. Enable HttpService and configure the server Secret **BLOX_SERVICE_ACCOUNT**, with Gateway and the
   required downstream grants. The Client reads GetSecret; no plaintext key is needed.
4. Provision the fixtures below in a disposable development universe. Set the desired Script's custom
   **Enabled attribute** to true. All scripts are opt-in and otherwise do nothing. Enable one at a time;
   they share the same client, limiter, poller lifecycle and shutdown hooks.
5. Play on a Roblox server. Inspect machine error codes; do not log credentials or raw auth responses.

| Script | Fixture / behavior |
|---|---|
| fields | PLAYER int `Smoke.Counter`; increments once per joining player |
| purchases | Fields products matching Marketplace product IDs; owns the single ProcessReceipt callback |
| configs | namespace `Shop` key `SwordPrice`; observes ETag-polled changes |
| flags | `double_xp` flag; authoritative player evaluation |
| live-events | enabled `live_event` rotation with current head |
| weather | `weather` rotation; each item's data carries weather values RAIN/METEOR/CLEAR; `watch` applies it |
| daily-shop | `daily_shop` rotation; `current` for the offers and a countdown (server: child GetShopOffers BindableFunction) |
| leaderboard | dedicated `sdk_smoke` board; reads around/top |
| ratings | discovers configured rating scopes; no untrusted rating deltas |
| matchmaking-queue | provision `ranked` mode; joins, polls, removes on completion/cancellation |
| codes-redemption | set Code attribute to a disposable code; redemption may grant rewards |
| party | lists this universe's parties |
| audit | enqueues one server-start event; drains on shutdown |
| auth / platform | service health reads, not human login or billing |

Pack/card BindableFunctions are server-only integration points, not public remotes. Pass an authenticated
player ID and a persisted server-owned intent ID; pack purchases must pin instance/slot/entry from the
server's current catalog. On uncertainty replay that same intent/payload, not a fresh head or key.
The authoritative backend applies costs/grants; never duplicate them locally. UI/teleport integration
is experience-specific and intentionally not an undocumented, insecure RemoteFunction shortcut.

No native Studio session or real purchase was executed by offline verification. See the
[opt-in gateway smoke runner](../docs/LIVE-SMOKE.md) and [API](../docs/api/README.md).

- `profile-leaderstats.luau`: initialize leaderstats and refresh them from `Profile.Changed`, including live admin edits. Release the returned profile when no longer needed. The native `server/fields.server.luau` example keeps its profile loaded until PlayerRemoving.
