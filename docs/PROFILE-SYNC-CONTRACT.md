# Shared player batch changes contract

This route is an explicit backend/SDK contract supplied for 1.2.0, not evidence of a deployed
controller. Only the SDK is changed in this repository. Backend query shape, retention/visibility
rules, authorization and fair-share enforcement remain backend obligations and are not certified by
offline SDK tests. The current local controller is covered by the source inventory.

`POST /api/fields/universes/{universeId}/players/changes/batch` (Fields READ; game-server machine keys allowed).

```json
{"players":[{"userId":7,"sinceSeq":41},{"userId":8,"sinceSeq":0}],"maxEntries":500}
```

- `players`: 1–200 distinct positive exact integer user IDs; nonnegative integer `sinceSeq` from
  the last applied snapshot or `nextSinceSeq`.
- `maxEntries`: optional integer 1–1000, default 500, **total** across the response.

```json
{"items":[{"userId":7,"entries":[],"latestSeq":41,"nextSinceSeq":41,"hasMore":false,"needsSnapshot":false},{"userId":8,"entries":[],"latestSeq":0,"nextSinceSeq":0,"hasMore":false,"needsSnapshot":false}],"pollAfterMs":15000}
```

Exactly one item per requested player, in request order. `entries` uses the same `Entry`/ledger
shape as `GET /players/{userId}/changes`. Never split a sequence group or publish a watermark past
an unsafe/in-flight sequence. Split the entry budget fairly among changed players; undelivered groups
leave `hasMore=true` and `nextSinceSeq` at the last complete group delivered. `latestSeq` is not a
pagination cursor.

Set `needsSnapshot=true` for NONE-history changes/deletions, required hash-only (>16 KiB) snapshots,
erased/restored/replaced players, field schema/type migration, or a cursor older than retention.
The caller must reload that player's snapshot, not advance its watermark over missing state.

`pollAfterMs`: default 15000; may increase under load/maintenance, never below 5000.
400: invalid body/count/IDs/duplicates/cursors/budget; 401/403: normal auth; 429: existing rate limiting
with Retry-After. Unchanged players should cost one indexed lookup. The backend must use set-based
queries in one database round trip where feasible, not per-player N+1 calls.

See [live sync](FIELDS.md#admin-edits--live-sync) for the SDK's lifecycle, application and budget policy.
