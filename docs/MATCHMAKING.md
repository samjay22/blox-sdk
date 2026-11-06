# Matchmaking criteria and Fields

**lb1 requires `Gateway` plus `MatchmakingService`; queue enrichment also needs `FieldsService`
READ access to the same universe. `bsa_` service-account keys cannot switch universes.**

The backend forwards the caller's bearer to
`GET /api/fields/universes/{u}/players/{userId}/fields?limit=200`. Only `computed:true` fields without
an error become per-player metadata, keyed by field ID. Stored values and failed computations are
excluded. Numeric values remain JSON numbers. Queue inputs therefore contain player IDs, universe,
game mode(s) and optional party ID, not caller-controlled metadata.

Criteria `fieldName` accepts **any computed Fields ID**, including namespaced IDs such as
`Stats.Elo` or `Progress.Level`, as well as unnamespaced IDs such as `Elo`. Dots are part of the literal
field ID, not nested metadata traversal. The ID must match the Fields field-id grammar exactly:

```text
^[A-Za-z][A-Za-z0-9_]{0,63}(\.[A-Za-z][A-Za-z0-9_]{0,63}){0,7}$
```

The total length is at most 200 characters: 1–8 dot-separated segments, each 1–64 ASCII characters,
starting with a letter and followed only by letters, digits or underscores. Empty segments, leading
or trailing dots, and segments starting with a digit are invalid. The field must be computed and
its return type must be compatible with the criterion; accepting namespaced IDs does not permit
stored fields or caller-supplied metadata. The DTO retains the same criteria field names and 16
discriminator values, not a new path or schema-version selector. Types are refreshed from that DTO
rather than inferred from example metadata.

```luau
local mode = client.matchmaking:createGameMode({
    universeId = "123", name = "ranked", placeId = "456",
    matchmakingCriteria = {
        {type="TEAM_SIZE", maxPlayers=6},
        {type="SKILL_BASED", fieldName="Stats.Elo", skillRange=200},
    },
})
local joined = client.matchmaking:joinQueue({
    robloxUniverseId="123", robloxUserIds={"7"}, gameModeName="ranked",
})
```

Game-mode mutations require ADMIN. All criteria except TEAM_SIZE require a nonblank fieldName.

## Type-aware field requirements

`client.matchmaking:getCriteriaTypes()` calls `GET /api/matchmaking/criteria-types` with
MatchmakingService READ access, using the same authentication as other read endpoints. It returns an
array of `{type, fieldRequired, allowedReturns, description}` for every CriteriaType. `allowedReturns`
contains only `"int"` and/or `"number"`, the Fields computed `returns` kinds supported by that evaluator.
Use this catalog rather than assuming every numeric computed field works for every criterion:
grouping/equality/bucketing require integers; arithmetic/ranges may accept both kinds. TEAM_SIZE has
`fieldRequired=false` and needs no field.

On create/update, every field-requiring criterion must name an active computed field in the selected
universe's Fields schema, with `returns` included in that type's `allowedReturns`. Stored numeric fields
are not eligible merely because their values are numbers. Save validation is authoritative even if a
client previously loaded the catalog and schema.

Invalid field references fail with HTTP 400 `criteria_field_invalid`, identifying `criteriaIndex`,
`fieldName`, and one of these `reason` values:

| Reason | Remedy |
|---|---|
| unknown_field | Correct the ID or create the field in this universe, then reload its schema. |
| not_computed | Select a computed field, not a stored value. |
| wrong_return_type | Select a computed field whose `returns` is allowed for this criteria type. |
| archived | Restore the field deliberately or select an active computed field. |

If Fields cannot be reached during save, HTTP 503 `fields_unavailable` fails closed: no unvalidated
criteria are saved. Resolve dependency availability before retrying. The SDK preserves these machine
codes as `result.error.code`; backend text, field diagnostics and raw bodies remain redacted.

| Type | Additional fields / constraints |
|---|---|
| RANGE | minValue, maxValue; min ≤ max |
| GROUP_BY, PARTY, EXCLUDE, PRIORITY, FILL | fieldName only |
| TEAM_TOTAL | targetValue, tolerance ≥ 0 |
| THRESHOLD | minValue |
| WEIGHTED | weight in [0,1] |
| CROSS_GROUP | groupCount ≥ 2 |
| TEAM_SIZE | optional maxPlayers ≥ 1, default 12; no fieldName required |
| LATENCY | maxLatencyDiff ≥ 0 |
| REGION | optional allowCrossRegion, default false |
| SKILL_BASED | skillRange ≥ 0 |
| BALANCE | maxDifference ≥ 0 |
| LEVEL_RANGE | bracketSize ≥ 1 |

Enrichment follows at most five pages of 200 fields, counting all listed fields, not just computed
ones. Transport/HTTP/timeout/malformed-response failures discard the entire fetch and produce empty
metadata with a sanitized warning and `matchmaking.fields.fetch.failed` metric. Individual computation
errors are skipped. Enrichment does not propagate fetch failures; subsequent criteria validation can
still reject the queue request. SDK success is not evidence of backend Fields reachability.

## Test criteria without entering a queue

`samplePlayers` requires FieldsService READ. `limit` defaults to 200 (1–500);
`fields` is a comma-separated list of at most 20 computed field IDs. Players are
sampled most recently updated first, not randomly. Missing or errored computed
values are omitted from each player's `values` map, never replaced with zero.

```luau
local sample = client.fields:samplePlayers({
    path = {universeId = 123}, query = {limit = 200, fields = "Rating"},
})
local simulation = client.matchmaking:simulateCriteria({
    universeId = "123",
    sampleSize = 200, -- 10–500; placeId is optional.
    criteria = {
        {type = "TEAM_SIZE", maxPlayers = 6},
        {type = "SKILL_BASED", fieldName = "Rating", skillRange = 200},
    },
})
if simulation.ok then
    print(simulation.value.sampled, simulation.value.estimate.unmatchablePct)
end
```

`simulateCriteria` requires MatchmakingService READ_WRITE and Fields READ for
sampling. It validates criteria like a game-mode save (including computed return
types and dotted field IDs), uses the real grouping/evaluators, and never touches
live queues or saves a game mode. Body `universeId` must be supplied explicitly;
`withUniverse` does not fill body fields. The SDK does not automatically retry
this POST or cache its result.

The response contains `sampled`, `fieldCoverage`, `estimate`, and `warnings`.
Coverage is keyed by field ID with present/missing counts, min/max/mean/p50/p90;
statistics can be null when no values are present. Estimate includes groups,
avgGroupSize, unmatchable, and unmatchablePct (0–100). Treat these as a recent-data
diagnostic, not a queue throughput or wait-time forecast. Inspect warnings and
missing coverage before saving; sparse or biased samples can be misleading.
