# Platform and owning-service APIs

`client.platform` shares authentication, scoped tokens, queues, deadlines, validation and retries.
Game servers use universe-bound service-account keys with PlatformService and Gateway access.
Human tools retain identity credentials for org APIs and use scoped facades for universe APIs.
Permissions never substitute for org roles. See [coverage](../SDK_COVERAGE.md) for every source-backed route.

## Current Platform surface

- Metering ingestion and machine event publication; org-bound internal effective rate-limit lookup.
- Authenticated plan catalog; SUPER_ADMIN plan create/update/delete and org/key rate-limit reset/write.
- Identity/org-role-gated plan assignment, usage, limits, invoice data and sandbox creation.
- Universe-scoped webhook CRUD, delivery history, explicit test/redelivery; analytics summary,
  timeseries, optional field/date economy queries and ADMIN backfill.
- OpenAPI, authenticated ping, public status, SUPER_ADMIN incident administration and operational probes.

Plans take `monthlyLimits`, `rateLimit={requestsPerSecond,burst,dailyRequests}` and `overagePrices`.
Prices accept finite numbers or plain decimal strings (e.g. `"0.00000001"`); prefer strings when exact
precision matters. Backend nonnegative/12-integer/8-fraction-digit validation is authoritative.
`createPlan` takes the DTO directly and returns 201; `updatePlan` takes `{path={name=...},body=...}`.
Resetting org/key rate-limit overrides returns 204 and never resets usage counters.

Webhook lists return arrays with explicit `after`/`limit` selectors, not a `nextCursor` envelope.
Tests/redelivery and other unkeyed mutations never automatically replay, including after 401/429/5xx.
Webhook secrets and sandbox keys are one-time disclosures: never log them. Invoice endpoints are
data-only; the SDK does not initiate payments.

Platform controllers retain `/platform-service/api/...` and `/platform-service/internal/...` on direct
hosts as well as gateway calls. Operational `/health`, `/metrics`, `/info` and probes are root-relative
on direct hosts. Supply only an HTTPS origin in `services.platform.baseUrl`.

## Fields owns game runtime state

There are no current Platform LiveOps, environment promotion, flag or exposure controllers in the
provided sources. Speculative SDK methods were removed, not redirected or shimmed. Use Fields
environments, schedules, flags and runtime snapshots where those APIs exist. Fields [Rotations & Generators](ROTATIONS.md) provide gameplay rotation/roll helpers.

```luau
local result = client.fields:evaluateFlags({
    body = { userId = player.UserId, keys = { "double_xp" } },
})
if result.ok then
    local flag = result.value.values.double_xp
    -- Apply the service-authoritative value; no exposure endpoint is invented.
end
```

`client.fields:playerOverview`, `searchPlayers`, `revertPlayer` and `exportPlayer` are Fields-owned.
Privacy deletion requires `deletePlayer({path={userId=...},body={reason=...,confirmUserId=...}})`.
Reverts and erasure require ADMIN; JSON export requires READ. Never forward untrusted player input
to administrative routes. Keep keys only in trusted server storage.

These contracts are offline-verified, not deployment or webhook-delivery certification.
