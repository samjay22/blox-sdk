# Fields durable jobs: trusted server/admin-key usage

All paths below are relative to `/api/fields/universes/{universeId}`. The gateway adds `/fields-service`.
**Job, migration, bulk, import/export, schedule controls and alert endpoints require FieldsService ADMIN**,
including previews, definition reads and downloads. `GET /health/summary` and schedule run history
(`GET /schedules/{id}/runs`) permit READ. Gateway callers also
need Gateway permission. Universe-bound service keys cannot switch universes; SDK `levels` do not grant
authority. Keep admin credentials and controls in trusted game-server/operator code, never LocalScripts,
replicated modules or arbitrary player-request handlers. Normal gameplay should retain READ_WRITE keys.

The generated facade covers 35 durable-control endpoints; [ENDPOINTS](ENDPOINTS.md) lists exact method names,
request DTOs and permissions. Typed helpers provide preflight only; raw generated wrappers retain
server-authoritative semantic validation. Neither adds new backend authority.

## Bulk: typed operations and target filters

Explicitly load `client.fields:schemaCache(universeId):load()` and check its Result before building. No helper
silently fetches schema to mask local validation failure. Helpers reject unknown DTO properties, invalid
types, unsafe integers and unsupported filter grammar before sending. Current state, runtime limits,
authority and schema changes remain server-authoritative; previews reserve nothing.

```luau
local bulk = client.fields:bulkBuilder(universeId)
bulk.ops:add("Currency.Gems", 10) -- The shared subject-free typed operation builder.
bulk:target({kind="SUBJECTS", subjects={7, 8}})
    :reason("Grant event attendance bonus")
    :idempotencyKey("attendance-event-2026-11-05")
local request = bulk:build() -- Result<BulkInput>; private canonical payload, no HTTP.
local preview = bulk:preview() -- Explicit ADMIN read-only server preview.
-- Inspect preview.ok, preview.value.validation and samples before deciding to submit.
-- local submitted = bulk:submit()
-- local definition = bulk:saveDefinition() -- Immutable reusable definition for RUN_BULK.
```

Targets: `{kind="ALL"}` selects positive subjects with stored data; `{kind="SUBJECTS",subjects={...}}`
accepts 1–100000 distinct positive IDs, including never-written players; `{kind="WHERE",where=filter}`
selects players with data. Subject 0 is never a bulk/import/export target. Operations are the existing
1–100 subject-free `/ops/validate` grammar, including nested paths; no conditions or caller refs.

Filters are closed trees: leaves `{op="EQ"|"NE"|"LT"|"LE"|"GT"|"GE"|"IN"|"EXISTS",field=...,value=...}`;
logical nodes `{op="AND"|"OR",clauses={...}}` and `{op="NOT",clause=...}`. Only stored PLAYER scalar
int/number/bool/string/enum roots are allowed; no paths, SQL or scripts. IN takes 1–100 typed values,
EXISTS a boolean. Maximum depth 4 and 16 comparison leaves across the tree. Missing rows never match
comparisons, even NE; EXISTS false matches them and NOT explicitly negates the result.

Preview provides matchedCount, validation and at most 20 samples. Worker preparation freezes a manifest
before execution, but is not one global MVCC snapshot: later preparation batches may see concurrent
changes, so preview counts can differ. Subjects commit independently; failures do not undo other subjects.
Bulk/import writes are ledgered even with NONE history. Generated `reverseBulk` queues compensation for
a terminal source BULK; it reverses successful transactions under current bounds/conflict rules, without
force. Cancellation retains completed writes/compensations.

## Job observation and bounded polling

Submissions return HTTP **200 JobReceipt**, meaning durable work was queued, not completed. States are
QUEUED, RUNNING, SUCCEEDED, CANCELLED and FAILED. `prepared=false` means enumeration is incomplete and
`total` can grow. Import counts are line items; schedule counts are actions. **SUCCEEDED can still have
`failed > 0`** for bulk/import/reverse. Inspect counters and failure reports before declaring success.

```luau
local jobs = client.fields:jobClient(universeId)
local completed = jobs:waitFor(jobId, {
    timeout = 60,
    onProgress = function(receipt)
        print(receipt.state, receipt.succeeded, receipt.failed) -- No field values or credentials.
    end,
})
if completed.ok then
    -- Transport success includes terminal FAILED/CANCELLED; inspect state and failed count.
    print(completed.value.state, completed.value.failed)
end
```

`waitFor` returns `Result<JobReceipt>`, polls immediately, then waits 0.25, 0.5, 1, 2, 4, and at most
5 seconds between reads. Timeout must be positive, defaults to 60 seconds, maximum 3600; the total
deadline includes HTTP and sleeps, and each request disables caching. Optional `signal={cancelled=false}` cancels the local wait, **not** the
durable job. Timeout/transport errors are Results, not proof the job failed. No implicit submit, retry,
cancel or reversal occurs. Explicit `get`, `list`, `events`, `failures`, `download`, `downloadFailures`,
`cancel` and `retry` retain normal SDK request options and authorization.
Progress callbacks receive an immutable receipt snapshot and must return promptly; the helper cannot
preempt arbitrary callback code. Callback exceptions return a redacted `Local` error.

Jobs list uses bounded limit/offset, **not a cursor page** (limit 1–200; offset 0–100000). Events use
`after` event ID and return up to 200; failures use `after` ordinal and limit 1–500. `retry` only resumes
FAILED jobs from the checkpoint. A cancel request may let the in-flight item finish; it is not rollback.
Dedicated workers must be enabled for execution. Polling cannot make a disabled worker run.

Reasons are 5–500 trimmed characters. Job submissions use permanent universe-wide idempotency keys;
identical requests return the same job/current progress, changed payloads conflict. Persist caller keys
for restart recovery; never replace an uncertain key just to retry. Generated required-key wrappers
create omitted keys once per logical call, not per transport attempt.

## NDJSON export and import

`jobs:buildExport(input)` returns a schema-validated ExportInput without HTTP;
`jobs:export({target=...,fields={...},reason=...,idempotencyKey=...})` validates target/filter and field
selection against loaded schema, then queues an export. Retain the built request/key for retries across
separate calls. Target omission means ALL. Fields are 1–100
distinct stored PLAYER IDs; omission selects all eligible definitions only when at most 100. Output
contains SET records, including virtual defaults: `{"subject":7,"field":"Currency.Gems","op":"SET","value":50}`.
`jobs:download(jobId)` returns raw NDJSON text, not a JSON array or public URL. The server streams; SDK
HTTP adapters return a buffered string, not a streaming iterator. Budget server memory accordingly.
Export is per-subject consistent, not a restore-grade global backup. Downloads require EXPORT/SUCCEEDED
(otherwise 409); artifacts expire 24 hours after completion (410). Use snapshots for restore-grade work.

`jobs:buildImport(records)` returns validated canonical NDJSON without HTTP. `jobs:import(records,
{reason=...,dryRun=true})` dry-runs by default. An explicit apply uses `dryRun=false` and a persisted
`idempotencyKey`, carried as **Idempotency-Key**; identity binds the exact UTF-8 bytes and reason.
Raw generated `fields:import({body=ndjson,query={reason=...,dryRun=false},idempotencyKey=...})` exposes
the same wire protocol without the typed record builder. Content-Type is `application/x-ndjson`, not JSON.

Records allow only positive `subject`, stored PLAYER `field`, SET+`value` or ADD+`delta`, and optional
matching `universeId`. No paths or arbitrary documents. Limits: 16 MiB UTF-8 and 100000 records; a final
newline is allowed, internal blank lines are errors. Invalid apply returns an ImportValidation report
and queues **no job**; valid apply returns JobReceipt. Inspect which response was returned. Errors use
one-based input line numbers; wrong-universe records fail authorization rather than become skippable
errors. Every line is validated before anything is queued; workers then commit lines independently in
input order per subject. Later state/schema changes become execution failures. Failure-download `line`
is a manifest ordinal (subject ID for bulk), not universally an import line number.

## UTC schedules

`client.fields:scheduleClient(universeId)` provides `build(input)`, `preview`, `create`, `edit`, `get`,
`actions`, `cancel`, and `endNow`. Builds validate closed action grammar before HTTP. Input is a named
UTC `start` and optional `end`, 1–32 startActions, at most 32 endActions, reason and idempotency key.
Helpers accept the explicit UTC subset `YYYY-MM-DDTHH:mm:ss[.1-9 digits]Z`; the service's Instant parser
may accept broader representations. Unsupported forms fail local preflight rather than being coerced.
Use `["end"]=...` in Luau because `end` is reserved. Actions: SET_CONFIG `{key,type,value}`, ENABLE_FLAG
or DISABLE_FLAG `{key}`, RUN_BULK `{bulkDefinitionId}`. Config types STRING/NUMBER/BOOLEAN/JSON are
schedule scalar labels, **not Fields TypeExpr**. Actions operate on Fields-owned runtime state.
Referenced resources must already exist; keys within each
edge must be unique within their config-entry or flag namespace. An entry and flag with the same name
are valid together. There is no runtime-definition rebinding or arbitrary script action.

`restorePrevious=true` excludes nonempty endActions; it restores captured config/flag preimages in reverse
order. RUN_BULK queues a child job; action completion does not mean its subjects succeeded and has no
implicit inverse. Cancel stops future actions without cleanup; ACTIVE-only endNow runs the end edge once.
Edits fully replace only unstarted/unclaimed schedules. Durable phases are SCHEDULED → STARTING → ACTIVE
→ ENDING → ENDED or CANCELLED. Database UTC time drives workers (default 15-second polls), not SDK timers.
Past edges catch up after restart. Captured versions prevent overwriting conflicting external edits;
`schedule_config_conflict` requires operator resolution, not blind repeated retry.

## Schema migration safety

Generated `migrationPreview`, `migrate`, `cancelMigration`, and `rollbackMigration` expose the explicit
kind-change workflow. Ordinary definition PUT remains strict. Supply full TypeExpr, required
expectedDefinitionVersion, validated default when needed, and a closed converter; preview may omit
reason/key. Converter kinds include IDENTITY, CLAMP, INT_TO_NUMBER, NUMBER_TO_INT (rounding required),
STRING_TO_INT/NUMBER, TO_STRING, BOOL_TO_INT, ENUM_RENAME, WRAP/UNWRAP_NULLABLE, LIST_TO_SET,
SET_TO_LIST and recursive MAP_VALUE. No scripts. Failure policy is FAIL, USE_DEFAULT or CLAMP.

Preview scans with bounded samples and complete failure counts; the worker rechecks under the write lock.
A complete pinned snapshot plus old/new definitions precede cutover. **Ordinary universe data reads,
writes and schema scans return 409 `migration_in_progress` while conversion is fenced.** Job controls
and alert health stay available. Plan maintenance; this trades availability for type consistency.
Conversion failure retains the fence: retry or cancel to compensate. Failed restoration must be retried;
rollback cannot be cancelled. Explicit post-completion rollback rejects intervening definition changes
and deliberately overwrites later field values/reset newly materialized subjects. Definitions/ledger
versions never run backwards; migration snapshots remain pinned indefinitely.

## Alerts and compact READ health

Generated alert methods expose threshold configuration, list, acknowledgement and queued webhook test.
Acknowledgement suppresses neither the underlying incident nor retries; healthy scans resolve and later
incidents reopen. Failed jobs/outbox remain unhealthy until repaired. Threshold replacement resets
omitted thresholds to defaults. Webhooks are write-only: omission/null preserves, empty string removes.
Never log webhook URLs; the backend does not encrypt them at rest. Tests are limited to one per universe
per 15-minute bucket. Monitoring/webhook delivery is best-effort, not transactional exactly-once delivery.

`client.fields:healthClient(universeId):summary()` returns typed `{openAlerts={WARNING,CRITICAL},runningJobs,
upcomingSchedules}` with READ access. Open includes acknowledged-but-unresolved alerts; no captured
values or webhook information is returned. This differs from `client:health()` process/service probes.

## Recurring schedule definitions and runs

`ScheduleInput.recurrence` is optional: `{type="NONE"|"DAILY"|"WEEKLY",daysOfWeek={...},timezone="America/Chicago"}`.
Weekdays use uppercase Java names (e.g. `"SATURDAY"`); only WEEKLY has a nonempty distinct weekday list.
DAILY/WEEKLY require an end time. IANA zone validity, DST and catch-up behavior remain server checks.
The helper preserves `daysOfWeek={}` as `[]`. Omit recurrence for a one-time schedule.

`scheduleDefinition({path={id=...}})` reads the original input plan (ADMIN), not captured prior values.
`scheduleRuns({path={id=...},query={before="9223372036854775807",limit=64}})` reads safe outcomes (READ).
Pass the smallest returned run ID as `before` for older runs; use a decimal string for int64 cursors beyond
Luau's exact range. `scheduleActions` pages forward using `after` ordinals (initial `-1`) and `limit`.
Action results include optional/null `skipped` and `skipReason`; run `finishedAt` and `error` can be null.
