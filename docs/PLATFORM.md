# Wave-2 PlatformService

`client.platform` shares the SDK's auth, scoped-token provider, queues, request budget, validation and retry policy. Human tools use `client:scoped(universeId)`; game servers use their universe-bound service-account key. Grant PlatformService and Gateway access as needed. Service permissions never substitute for org roles.

Typed methods cover plans, usage/invoices/limits, org/key rate limits, webhooks and deliveries, environment snapshots/diffs/promotions/rollback, LiveOps schedules/runs/manual controls, analytics, flags/experiments, OpenAPI, sandbox and public status/incidents. See the generated `ENDPOINTS.md` for every request type and permission level. Internal gateway/producers methods are service-account-only, not general-user APIs.

```luau
local result = client.platform:evaluateFlags({
    path = { universeId = game.GameId },
    body = { userId = player.UserId, keys = { "double_xp" } },
})
if result.ok then
    local flag = result.value.values.double_xp
    -- Only log an exposure when the player actually sees the variant.
end
```

Explicit `recordExposure` takes `userId,key,variant,eventId,occurredAt`. Persist and reuse eventId when retrying the same logical exposure. Unkeyed POST mutations are never automatically replayed. Pagination uses `after` for platform resource arrays, and `cursor` for the player-search envelope. LiveOps event keys are `event:<id>`, promotion keys are `promotion:<id>`, and run keys are `run:<eventId>:<occurrence>`; use the complete key as the next `after` value.

`client.fields:playerOverview`, `searchPlayers`, `revertPlayer` and `exportPlayer` implement the new player-admin routes. Privacy deletion is a breaking replacement: `deletePlayer` requires `body={reason=...,confirmUserId=...}` matching the path; a query-only reason is not supported. Reversals and erasure are administrative operations; JSON export requires READ. Keep administrative keys out of player input and client scripts.

Webhook secrets and sandbox keys are one-time disclosures. Do not log or persist them in analytics. Billing and invoice endpoints are data-only: no payment processor is connected. Local tests do not verify backend deployment, gateway enforcement, webhook delivery, or production interoperability.
