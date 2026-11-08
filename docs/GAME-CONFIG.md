# Game configuration

Fields owns configuration; there is no Config client or compatibility facade. Configure UNIVERSE-scoped (subject 0)
stored fields through trusted administration, then call `client:runtimeSnapshot(30)` once per universe.
`snapshot:get("Welcome.Text")` reads a literal gameValues ID synchronously. It returns nil before initial load.
`changed:connect(callback)` observes immutable applied snapshots; disconnect and destroy on unload.

The poller sends opaque If-None-Match ETags, handles 304, jitters intervals, never overlaps requests,
and retains last-good data across errors or version regression. Check `lastError` to distinguish stale
last-good values from fresh values; it does not imply per-user flag evaluation. `refresh()` is available
for explicit refreshes, not a frame loop. Polling and retries share the server's request budget.
See [native script](../examples/server/game-config.server.luau), [helper API](api/helpers.md).
