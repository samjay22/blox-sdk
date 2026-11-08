# Fields: schema-first gameplay

`client.fields` combines every generated FieldsService route with hand-written schema, transaction and
profile helpers. Default origin: `https://lb1.blox-api.com`; stripPrefix `/fields-service`; controller
base `/api/fields/universes/{universeId}`. An explicit direct override may use `https://fields.blox-api.com`.
Permission is **FieldsService** (`READ`, `READ_WRITE`, `ADMIN`). Use trusted server credentials only.

## References and guarded definition changes

The reference registry tracks `GAMEMODE` and `CODE` consumers per universe. The generated methods are:

- `definitionReferences({path={id="Rating"}})` — READ; returns
  `{fieldId="Rating",references={{consumerType="GAMEMODE",consumerId="ranked",label="Ranked 5v5"}}}`.
- `putReferences({path={consumerType="GAMEMODE",consumerId="ranked"},body={label="Ranked 5v5",fields={"Rating","Region"}}})`
  — READ_WRITE; idempotently **replaces** that consumer's entire list. `fields={}` encodes as `[]`
  and behaves like delete. `consumerId` is a string of at most 200 characters; fields must be valid field IDs.
- `deleteReferences({path={consumerType="GAMEMODE",consumerId="ranked"}})` — READ_WRITE; removes that consumer's references.

The registry paths are `/references/{consumerType}/{consumerId}` (PUT/DELETE) and
`/definitions/{id}/references` (GET), relative to the universe base above. The server validates ID grammar,
limits, existence and authorization. Matchmaking maintains its game-mode references on create/update/delete;
Codes maintains award-field references on create/delete. Consumers backfill existing records idempotently at
startup (non-fatal on failure); a registration failure during a write fails it with 503 `fields_unavailable`.

Archiving, deleting or changing the type/computed return of a referenced definition returns HTTP 409
`field_in_use` with `{fieldId,references}`. Update/remove those consumers first. Do not erase live references
to evade the guard. If deliberately overriding, **ADMIN and the existing audit reason are required**.
`archive` takes `body={force=true,reason="Reviewed dependency removal"}`; `update` takes
`query={force=true}` with the reason in `body`. Purge takes
`query={purge=true,reason="Reviewed dependency removal",force=true}` and still requires
an archived definition. Forced operations record the reference list in definition audit/history. Force does
not repair consumers, convert values or bypass other validation.

The SDK exposes `result.error.code == "field_in_use"` and Conflict/409, but deliberately redacts backend
error bodies (including labels/consumer IDs). Fetch `definitionReferences` to inspect the current typed list;
it can differ from the list at the instant the mutation was rejected. Registry reads are not cache eligible.

## Durable jobs and live-ops

`client.fields:Bulk(universeId)`, `:Schedules(universeId)` and `:Jobs(universeId)` compose typed
administrative requests; `:Health(universeId):summary()` exposes compact READ-level health. Bulk ops
reuse the existing operation builder and TypeSystem; target filters and import records validate locally
against an explicitly loaded schema before submission. `Jobs:waitFor` observes durable server work with
a total timeout and bounded backoff; it never cancels, retries or compensates the job automatically.

**All job, migration, bulk, import/export, schedule and alert routes require server/admin-key usage**, even
previews, reads and downloads. READ_WRITE gameplay keys cannot use them. Only `/health/summary` requires
READ. Keep ADMIN keys in trusted server/operator environments, never replicated modules or player input.
Migration conversion deliberately fences ordinary universe reads/writes; cancellation is not a general
undo, and a SUCCEEDED job may have individual failures. Read the [durable jobs guide](JOBS.md) before use.

## Runtime schema and validation

```luau
local cache = client.fields:Schema(universeId)
local loaded = cache:Load() -- Initial synchronous GET /schema; check loaded.ok.
local definitions = cache:Definitions() -- Immutable, includes archived/shared/computed definitions.
local validator = cache:Validator("Currency.Gems")
if validator then
    local checked = validator.Validate(100)
end
```

The cache is shared by universe across client facades. Loading starts serial 30-second background
refreshes. Equal `schemaVersion` reuses compiled validators; malformed, failed or regressing refreshes
keep the last good generation. `Refresh`, `Version`, `Get`, and `LastError` expose its state. Shared
`flush`/`destroy` stops pollers; requiring/constructing the SDK makes no requests.

`BloxSDK.Fields.TypeSystem` exposes `compile(TypeExpr)`, `validate(type,value)`, `default(type,explicit?)`,
`apply(type,current,fieldDefault,op,args,path?)`, `targetType`, and `checkOperation`. It implements closed
objects, explicit member defaults, natural defaults, enums, lists, sorted unique sets, typed maps,
pruneZero, nullable values, bounds/cardinality/UTF-8 limits and every contract operation. Results are
ordinary SDK Results; typed failures carry `code` and the original zero-based operation `path` (the
server does not add a nested-validation breadcrumb). Builders add `field` and zero-based `opIndex`.
Unknown properties are not silently ignored. Inputs are copied rather than mutated.

### Representation and precision

- Runtime values and raw wrappers use **wire-shaped sets (arrays) and string map keys**. Generated
  accessors convert sets to `{[T]: true}` and int map keys to numbers at the domain boundary.
- `BloxSDK.null` means present JSON null; nil means absent. Nullable generated types explicitly include
  `Core.Null`, not just `T?`, preserving a present null inside lists/objects/maps. Fields responses use
  a strict decoder preserving null and empty-array identity, including Roblox where native JSONDecode
  would otherwise drop null members.
- Luau cannot represent every signed int64 exactly. This SDK **fails closed outside ±(2^53−1)** with
  local `unsafe_integer`; values outside signed int64 return `int64_overflow`. Unsafe wire integer tokens
  fail before decoding and produce Network results, not rounded values or string coercion. The same
  safe-integer restriction applies to numeric schema bounds and integer map keys. Do not use strings
  as an int field value: the server rejects them. Restrict game field/ID ranges accordingly.
- Safe integral Luau numbers serialize as integer tokens, never `1.0`/exponents. A Lua value has no
  integer-versus-floating-token tag: literal `1.0` in Luau equals `1`; JSON test vectors retain that
  distinction only on the server oracle. Unmarked empty caller tables are accepted as list inputs;
  canonicalization emits `[]`. Mark explicit arrays with `BloxSDK.array` and objects with `BloxSDK.object` when needed. The decoder and JSON vectors preserve both identities.
- String patterns are full matches, Unicode-code-point lengths and a 4096 UTF-16-unit input cap.
  The portable matcher supports literal/class/range/negated-class atoms, `.`, anchors, ASCII
  `\d/\w/\s` and complements, escaped punctuation/control/hex/Unicode literals, and at most one
  `*`, `+`, or `?` quantifier. Unsupported Java-specific escapes fail schema compilation rather than
  being misinterpreted as Lua patterns. Groups/alternation/counting/repeated quantifiers are rejected.

## Validated transactions

```luau
local result = client.fields:Transaction(universeId, userId)
    :Add("Currency.Gems", -50)
    :MapAdd("Inventory.Items", "SWORD", 1)
    :Expect("Inventory.Items", {exists=false}, {"SWORD"})
    :Reason("Buy sword from shop")
    :Ref("shop", "sword")
    :Commit()
```

Load Schema first (or use LoadProfile). An unloaded cache returns `schema_unavailable` **without HTTP**;
Commit never fetches a schema to disguise local validation. Every op and condition validates against
one cached generation before dispatch: unknown/archived/computed/scope errors, argument types, nested
target types, delta caps, explicit values, keys and known collection constraints. Balance-dependent
bounds, actual path existence, final collection sizes and preconditions require the server's locked
state; the builder does **not** pretend a player's current balance equals its default. The server
revalidates current schema, authority, runtime flags and values atomically.

Methods: `Set(id,value,path?)`, `Add(id,delta,path?)`, `Min/Max(id,value,path?)`, `Reset(id,path?)`,
`Append(id,items,path?)`, `Insert(id,index,items,path?)`, `RemoveAt(id,index,count?,path?)`,
`RemoveValue(id,value,path?)`, `SetAdd/SetRemove(id,items,path?)`, `MapPut(id,entries,path?)`,
`MapRemove(id,keys,path?)`, `MapAdd(id,key,delta,path?)`. Paths have at most eight segments; list indexes
are **zero-based**, numeric map keys stay strings. `Expect(id,{version=n}|{equals=value}|{exists=bool},path?)`
accepts exactly one discriminator. Reasons are required; ADMIN-field reasons need five characters.

A transaction creates its key once. `IdempotencyKey()` exposes it; `Key(persistedKey)` overrides it before
commit. First dispatch seals the payload; automatic retries, 401 replays and later Commit attempts after
uncertain failure reuse the same body/key. Successful repeated Commit returns the cached acknowledgement.
Do not change a sealed builder; create a new logical transaction only when a new operation is intended.
Keys deduplicate within the whole universe, forever. Persist keys for restart recovery. Never blindly
replace an uncertain key. Raw `putDocument` retries **only if an explicit key was supplied**; no automatic
key is invented for document saves. Other required-key wrappers generate omitted keys before retry.

```luau
local transfer = client.fields:MultiTransaction(universeId)
    :Subject(senderId):Add("Currency.Gems", -10)
    :Subject(receiverId):Add("Currency.Gems", 10)
    :Subject(0):Add("Global.Trades", 1) -- UNIVERSE field
    :Reason("Player-approved trade")
    :Commit()
```

The limit of ten subjects includes conditions. At most 100 ops and 100 conditions. Single-player
transactions reject UNIVERSE fields. Multi-subject defaults to subject zero until Subject is selected.

## Profile and presence

`fields:LoadProfile(universeId,userId)` returns `Result<Profile>` after schema + complete document loads.
`profile:Get(id)` returns an immutable wire-shaped value and throws a value-free code for unknown,
archived, shared, stale or missing ids; `TryGet(id)` returns a Result instead. `Versions` and `Seq` expose
immutable field versions and subject watermark. Use generated accessors for compile-time field/value types.

`profile:Transaction()` owns a commit callback. After success it applies returned authoritative **after
subvalues**, not a second arithmetic delta. Duplicate/replayed acknowledgements never double-apply.
Sequence gaps or missing local containers mark the profile stale rather than fabricate a coherent snapshot.
Computed fields are refreshed from the server, never evaluated locally as write authority. A raw
`fields:Transaction` can be applied explicitly with `profile:Apply(result.value)`.

`Refresh()` validates a whole snapshot and rejects old/concurrently overtaken reads. `PullChanges()`
follows `nextSinceSeq`, not `latestSeq`, through complete sequence groups, then refreshes the document
when state advanced. This intentionally covers NONE-history writes, privacy deletions, hash-only ledger
values and computed fields; a feed-only replay cannot reconstruct these. Cursor failures are visible.

`StartPresence(placeId,sessionId?,heartbeatSeconds?)` acquires a session before scheduling heartbeats
(default 30s, range 1–60s). An omitted ID is generated once. `Heartbeat` and `StopPresence` retain it.
409 `session_conflict` remains a Conflict Result with `error.code`; it is not retried or taken over.
Automatic heartbeat conflicts stop the loop; `LastError` remains observable. Presence is a lease marker,
not a lock or authorization credential. Keep game gameplay session policy separate.

The first native Fields helper registers the same single BindToClose callback used by audit writers.
SDK `flush` stops schema polling, releases profile presence within the total shutdown deadline, drains
writers and closes pipeline admission. Transactions are synchronous: **there is no hidden write-behind
profile save queue**. Issue and await final transactions before flush. Custom runtimes must call
flush/destroy explicitly. A failed flush is not proof that an in-flight mutation failed to commit.

## Schema-specialized static accessors (offline build)

1. In an authorized environment, fetch **GET /schema** with a scoped server credential and save the
   JSON response. Use `client.fields:schema` or your approved secret-aware API tooling. Do not embed a
   credential in generated code. No fetch is performed by the generator or verification suite.
2. Run Python with a relative SDK require root suited to your project:

```sh
python3 tools/gen-field-types saved-schema.json --out game/GeneratedFields --sdk ../../roblox
# Deterministic CI drift check:
python3 tools/gen-field-types saved-schema.json --out game/GeneratedFields --sdk ../../roblox --check
```

3. Require the generated `Typed` module and use the separately exported `FieldTypes` module for types:

```luau
local Typed = require("./GeneratedFields/Typed")
local FieldTypes = require("./GeneratedFields/FieldTypes")
type PlayerDocument = FieldTypes.PlayerDocument
local gems: number = Typed.Currency.Gems:Get(profile)
local tx = profile:Transaction():Reason("Quest completion")
Typed.Currency.Gems:Add(tx, 10)
Typed.Inventory.Items:MapAdd(tx, "SWORD", 1) -- enum/string key + numeric delta
Typed.Characters:Append(tx, {{Id=42, Level=1, Rarity="COMMON"}})
local committed = tx:Commit()
```

Output: one `FieldTypes.luau`, one nested `Typed.luau`, and per-field `Accessors/*.luau`. Aliases use
reversible `_D_`/`_U_` escaping; FieldId/FieldValues include all definitions, PlayerDocument/accessors only
ACTIVE PLAYER definitions. Computed accessors are Get-only. Enums, object members, list item types and
map key/value types are statically constrained. Runtime constraints still go through the validated
builder. Generated accessors do not bypass it. The generator uses Python's standard library only and
never installs tools, imports a backend, executes downloaded text, or uses network.

Regenerate on schemaVersion/hash change, and typecheck your game. Saved `/schema/luau` text alone does
not contain bounds/default metadata required for validation: this tool takes the complete JSON schema.
The backend's generated text remains available through `fields:luau` if only server type declarations
are wanted. Explicit-null types and sparse enum maps in this generator describe the SDK domain exactly.

For Roblox, generate Instance requires directly and map the output folder with Rojo:

```sh
python3 tools/gen-field-types saved-schema.json --out game/GeneratedFields \
  --roblox-root game.ServerScriptService.BloxSDK
```

Then `require(game.ServerScriptService.GeneratedFields.Typed)` (adjust your Rojo placement). The SDK
root option accepts only a dotted `game` Instance path, not arbitrary source. Its child modules remain
server-only. The portable output uses relative string requires for CLI/static tests.

## Commerce, operations and pagination

`ProcessReceipt(universeId,{purchaseId,userId,productId,robuxSpent,idempotencyKey?})` calls generated
`purchase`. The backend's durable **purchaseId identity** prevents double grants across calls/restarts,
even after product edits/deletion/refund. A changed payload conflicts. Acknowledge Roblox delivery only
after success; on uncertainty retry the same trusted purchase payload, never fabricate a new purchaseId.
The SDK/backend does not verify payment with Roblox. A Fields refund compensates fields; it is not a
payment-provider refund. Never allow untrusted clients to choose grant quantities or catalog operations.

`validateOps({path={universeId=...},body={ops={...}}})` is the separate READ-only server
static-template check (HTTP 200 `{valid,errors}`). It is never called automatically by Commit;
invalid local builders still make zero network calls. Added from current controller sources.

Generated wrappers cover products/receipts/refunds, snapshots/policies/restores, ledger/reversal, outbox
and reconciliation. They preserve ADMIN requirements, permanent keys and partial restore reports;
reconciliation never repairs. Every cursor route has `<method>Pages` (including `ledgerPages`,
`productsPages`, `receiptsPages`, `snapshotsPages`, `snapshotPages`, `outboxPages`, `reconcilePages`).
Iterators retain scope/filters, stop on null nextCursor and yield errors once; never change filters mid-page.
## Field-owned leaderboard boards

Only stored **int PLAYER** fields may bind leaderboards, not `number`, computed or UNIVERSE fields.
Create/update definitions with ADMIN credentials; **Fields provisions boards server-side**. Do not create
the board first or also submit the same score from game code. Field writes produce durable outbox entries;
provisioning does not backfill existing values. See [setup example](../examples/fields-leaderboard.luau).

`Fields/Types.LeaderboardBinding` has this closed grammar:

```text
{board, submit: VALUE|DELTA, order?: DESC|ASC,
 reset?: NONE|DAILY|WEEKLY|MONTHLY|SEASONAL,
 keep?: LAST|BEST, displayName?: string}
```

Only `board` and `submit` are required. Board names match `[A-Za-z0-9_-]{1,64}`; at most 32 unique boards
per field. Unknown members, explicit null options, incorrect case and `DELTA` with **any** `keep` are
rejected locally before HTTP. `displayName` must be nonblank, at most 100 UTF-16 code units (server length
semantics); by default the server humanizes the last field-ID segment (`Stats.TotalWins` → `Total Wins`).
Order defaults DESC, reset NONE. Defaults/derived settings are server-owned, not inserted by the SDK.

| Binding | Derived aggregation | Required score range |
|---|---|---|
| VALUE, keep omitted/LAST | LAST | Field int min/max; missing bounds use ±9007199254740991 |
| VALUE, keep BEST | BEST, respecting order | Same as VALUE |
| DELTA, keep forbidden | SUM | Always ±9007199254740991, permitting negative deltas |

Field `maxDelta` is not copied to board `maxDeltaPerSubmit`. Safe score/delta/accumulated SUM limits still
apply downstream; the SDK rejects unsafe integer bounds rather than rounding them. Other schema,
shared-board compatibility, current board state and authorization checks remain server-authoritative.
Omitting bindings on update retains them; `bindings={leaderboards={}}` explicitly serializes as `[]` to
remove leaderboard bindings. Removing/archiving/purging fields never deletes their boards.

### ADMIN preview and saved bindings

`client.fields:previewBoard({body={id="Stats.TotalWins",type={kind="int",min=0,max=100},
binding={board="wins",submit="VALUE",keep="BEST",reset="WEEKLY"}}})` posts to
`/api/fields/universes/{universeId}/definitions/preview-board`. Use a scoped client or supply `path`;
optional body `universeId` must match. Optional scope defaults PLAYER. No reason or idempotency key.

The typed response includes `settings`, peer-unioned `effectiveSettings`, `status`, `valid`, and safe
`conflicts` (`code`, `board`, optional `expected`, `actual`, `field`, `source`), and optional
`willWiden={minScore,maxScore}` for a planned server-side range widening. Status is
COMPATIBLE, CONFLICT, ARCHIVED or MISSING_OR_ARCHIVED. HTTP 200 with `valid=false` is a successful preview
report, not an SDK transport error. A receiver GET 404 cannot distinguish missing from archived names;
MISSING_OR_ARCHIVED can have `valid=true`. Preview only reads: **it neither provisions nor reserves a board**.
Range-only differences return COMPATIBLE with the `willWiden` hint: the eventual definition write may
widen min/max to the union of existing and required bounds, never narrow them or replace board modes,
labels or caps. The hint is absent when no widening is needed; preview never applies the PATCH.

`client.fields:leaderboardBindings()` GETs `/leaderboard-bindings` and returns typed
`{field,status,binding,settings}` entries, including archived fields, without a server-to-leaderboard call.
`/schema` retains raw declarations. Schema-generated Luau/TypeScript describe field **values**, so binding
metadata does not change value/accessor types (schema hashes can change). This SDK has no generated
TypeScript binding DTO artifact; its `typescript` endpoint returns server-generated text unchanged.

| Server error | Meaning |
|---|---|
| 422 `leaderboard_requires_int` | A bound root is not int, including legacy number bindings |
| 422 `leaderboard_score_range` | Explicit VALUE bounds exceed the receiver safe-integer range |
| 422 `leaderboard_board_mismatch` | Incompatible board semantics, shared bindings or submission caps |
| 422 `leaderboard_board_archived` | Archived/reserved name prevents provisioning |
| 503 `leaderboard_unavailable` | Disabled integrations or dependency/auth/timeout failure; definition not saved |

The SDK preserves these `error.code` values and HTTP status, but redacts backend messages and details.
Local malformed candidates return a Validation result with no HTTP. Create/update/preview are unkeyed
and not automatically retried. On dependency recovery, inspect the outcome before explicitly retrying
the same candidate/version: external board provisioning and the Fields DB are not one atomic transaction,
so remote boards may survive a later definition failure. Subsequent score delivery remains asynchronous;
inspect outbox failures instead of assuming a committed field write proves leaderboard delivery.

## Verification evidence

`tests/vectors/type-system.json` contains contract examples and boundary vectors. The Luau suite consumes
its checked-in, drift-checked fixture projection. `tools/check-field-vectors.py` independently compiles
and runs the actual backend TypeSystem/JsonSupport/FieldsException Java sources with **cached** Jackson
2.18.2 and Spring Web 6.2.1, using a temporary directory. The same harness checks 103 shared
`bindings.json` vectors against actual IntegrationBindings/Models sources with cached Jakarta Validation
3.0.2. It starts no application or network client. Binding vectors run identically in Java and Luau.
All server vectors run; Luau has an explicit representation note for the float-token
case, plus stricter safe-integer expectations. Goldens and positive/negative luau-analyze
fixtures verify accessor typing. No live database, gateway, Roblox purchase or Studio runtime is certified.

## Subject-free operation dry runs

Load `client.fields:Schema(universeId):Load()` first. Then call
`client.fields:validateOps({path={universeId=universeId},body={ops=ops}})` or use
`client.fields:Operations(universeId):Add("Currency.Gems",100):validate()`.
A scoped client may omit `path`. The optional body `universeId` must match the path.
Requests accept only `ops` (1–100) and optional `universeId`; operations must omit `subject`, including null.
No reason, conditions, ref or idempotency key is accepted. READ is sufficient even for ADMIN-write fields.

The SDK parses the whole structure first, rejects malformed requests without HTTP, then checks the cached
schema with TypeSystem. It returns every local failure as `ok=true,value={valid=false,errors={...}}`,
with one first diagnostic per failing op, in order, and zero-based `opIndex`, supplied `field`, original
`path` (empty array when omitted), and `code`. These local results have no HTTP status. For locally valid
ops it sends the canonical list to `/ops/validate` and returns the server's complete result unchanged.
Refresh stale schemas explicitly; a cached rejection is not proof the current server rejects it.

`:build()` on an op builder returns a private canonical list or the first failure. All operation methods
match the Fields transaction builder, including typed operands and zero-based paths. No default player
balance is invented; negative ADD can be valid. Each op is checked independently; earlier ops do not
create state for later ones. Schema eligibility, paths, operands and statically knowable bounds are checked;
actual state, write authority and runtime policies remain server-authoritative.

Player `Transaction:validate()` dry-runs **only ops**, without sealing the transaction or requiring a reason
or key. Existing capitalized `Transaction:Validate()` checks the full transaction locally, including
reason, key, scope and conditions; `:Commit()` still uses that full check. Multi-subject dry runs are rejected
because this endpoint is player-template-only. Neither validation method reserves or writes anything.
The [Codes builder](CODES.md) composes the same operation builder and TypeSystem.

## Rotations, generators and table odds

See [Rotations & Generators](ROTATIONS.md) for current/next heads, snapshot-backed Watch, countdowns, live stock, atomic claims, player rolls/previews and explicitly labeled table odds. All use this SDK's shared Result/pipeline and universe/auth lifetime.
