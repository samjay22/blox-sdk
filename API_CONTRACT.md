# BloxSDK 4.0.0 session contract

Binding wire authority: `../scale/CONTRACT.md` v1, sections 1, 2 and 6. No compatibility aliases or wire extensions. Four new Fields POST operations use the existing BatchService envelope and internal paths `/api/fields/universes/{universeId}/…`:

| SDK method | Suffix | Body |
|---|---|---|
| `acquireSessions` | `sessions/acquire` | `{serverId, ttlMs, players:[{userId, steal}]}` |
| `renewSessions` | `sessions/renew` | `{serverId, ttlMs, leases:[{userId, epoch}]}` |
| `releaseSessions` | `sessions/release` | `{serverId, leases:[{userId, epoch}]}` |
| `commitSession` | `commits` | `{serverId, commitId, players:[{userId, epoch, ops}]}` |
| `pollSessions` | `sessions/poll` | `{serverId, cursor}` |

READ_WRITE game-key authorization; universe path scope is mandatory. Each list has 1–200 distinct players. Server ID is Roblox JobId (1–64 characters); Studio/injected runtimes generate a session ID lazily, or explicitly configure `sessions.serverId`. TTL is 10,000–300,000 ms, default 60,000. Commit limits: 4,000 total ops and 1 MiB body; the coordinator uses a conservative 950,000-byte body limit to leave batch-envelope room. Each player's buffered list is capped at 4,000 ops / 900,000 bytes; excess admission returns `buffer_full` without changing local state. Overflow across players is drained in subsequent serialized commits, immediately during shutdown/removal.

Acquire returns ordered `{items:[{userId,status:"granted",epoch,expiresAt,snapshot:{seq,fields,versions}} | {userId,status:"held",owner,expiresAt,retryAfterMs}]}`. Snapshot `fields` becomes the profile's document data; it is **not** renamed on the wire. Same-owner acquire retains epoch. Released epochs are never reused by Fields.

Poll returns `{cursor, reset, more, players:[userId]}`: the leased players another writer changed since the caller's inbox cursor. Sending a cursor acknowledges every earlier notice. `reset:true` means the inbox expired and cannot say what was missed, so the caller re-reads every leased player's change feed. `more:true` means another page follows at the returned cursor. The owner's own commits never appear.

Renew returns ordered `{items:[{userId,status:"renewed"|"lost",expiresAt?}]}`; release returns `{items:[{userId,status:"released"|"lost"}]}`. Commit returns `{commitId,items:[{userId,status:"committed",seq,versions,expiresAt} | {userId,status:"lease_lost"} | {userId,status:"rejected",error:{code,field?}}]}`. Session results are matched by request order and user ID; malformed/ambiguous commit acknowledgements retain the entire detached request for retry.

## Lifecycle and scheduling

- Native server clients with `universeId` subscribe to PlayerAdded (including existing players). Loads share the schema fetch and queue acquire on the normal 0.5-second batch clock. Explicit `fields:loadProfile(userId)` joins a concurrent load or returns the same ready handle. Injected runtimes use explicit loads and removal calls in tests.
- Readiness requires a granted lease **and a validated coherent snapshot**. Held acquisitions honor backoff (at least 0.5 s), request `steal:true` after 15 s, and stop after `sessions.acquireTimeout` (default 60 s). Cancellation after an in-flight acquire releases a late grant. Default load-failure kick is configurable.
- `profile:add`, `profile:set`, and `profile:mutate(ops)` validate and apply locally without yielding; success means **buffered, not durable**. Only adjacent ADDs at identical field/path targets coalesce; SETs and other operations retain order. Local state never carries authoritative version increments.
- One server coordinator detaches immutable per-player buffers every `sessions.flushInterval` (default 5 s). One commit operation rides the normal batch. A module-wide monotonic counter prevents ID collisions across SDK clients in the same VM: `JobId:counter`. Retries retain the same ID and exact body; later writes use fresh buffers. Even an application timeout cannot permit a replacement commit until native HTTP has physically completed.
- Within 20 seconds of expiration dirty data flushes; idle leases renew in bounded batched groups. Successful commits renew the included players implicitly. Failed controls back off; expired leases cannot admit new buffered writes.
- PlayerRemoving closes mutation admission, flushes detached and subsequent buffers, then releases. BindToClose / `client:flush(timeout)` drains all leases before closing pipeline admission. A finite deadline returns false if durability/release is unconfirmed; uncertain commits are never replaced or released early. `client:destroy()` does not save: call flush first.
- Change-feed polling remains on every batch tick. Authoritative versions apply to the server base, then pending local ops replay on top. While own commits are ambiguous, feed application/cursor advancement pauses, not feed polling. Because commit acknowledgements contain versions but no values, successful and rejected commits use a fresh coherent document barrier before rebasing remaining ops. This also handles NONE history and external writers; snapshot sequence and per-field version floors reject older snapshots. Confirmed-success snapshot barriers continue admitting optimistic mutations and replay the newest pending buffer atomically; they do not stall gameplay writes. Rejections refresh the shared schema once per recovery wave before re-sync. Recovery failures retain pending ops and stale state, retrying with backoff.
- `lease_lost` drops all that player's detached and pending ops, invalidates the handle and fires `client.LeaseLost({userId,universeId,code})`; kick defaults on (`sessions.kickOnLeaseLost=false` disables). `rejected` drops only the rejected detached ops, fires `client.CommitRejected({userId,universeId,code,field?})`, and re-syncs before admitting further mutations.
- Purchases, codes, trades and rolls remain direct synchronous transactions. `profile:immediate()` is the explicit transaction builder; `fields:transactionBuilder`, transaction endpoints, purchases and redemption calls are unchanged. Preconditions/reasons/keys belong to immediate transactions, not buffered commits. Flush ordinary buffered writes before a critical business flow when it needs to observe their durable effects; do not interpret optimistic state as purchase authority.

## Configuration

```luau
sessions = {
    -- serverId defaults to JobId; override only for Studio/injected tests.
    ttlMs = 60000,
    flushInterval = 5,
    acquireTimeout = 60,
    kickOnFailure = true,
    kickOnLeaseLost = true,
}
```

All HTTP remains behind BatchService: default 2 requests/s, at most 8 in any rolling second across native clients sharing the server budget. Default rolling-minute budget is 450 (configuration maximum 480). No direct HTTP, extra flush timers, live smoke execution or deployment is part of offline verification. Backend implementations are landing in parallel; wire compatibility is tested offline, not claimed live-verified.
