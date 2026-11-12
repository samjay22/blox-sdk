--!strict
-- Hand-written facade over CodeService. tools/gen.py generates the wire types and endpoint metadata
-- this file uses; tools/check-coverage verifies that every CodeService route is reachable from here.
local Core = require("../Types/Core")
local Helpers = require("../Fields/Client")
local Award = require("../Codes/Award")
local Universe = require("../Core/Universe")
local Types = require("../Types/Codes")
local Endpoints = require("../Core/Endpoints")
local Service = {}
Service.__index = Service
export type Service = typeof(setmetatable(
	{} :: { _invoke: Core.Invoke, _universe: (string | number)?, _fields: Helpers.State? },
	Service
))
export type Award = Award.Award
--- One field a redemption changed for the player, with its value before and after.
export type Reward = {
	field: string,
	op: Types.Op,
	path: { string | number },
	before: Core.Json?,
	after: Core.Json?,
}
--- The code worked and this call granted its award.
export type Granted = { status: "granted", code: string, rewards: { Reward }, redeemedAt: string? }
--- The player already redeemed this code; `rewards` is the original grant and nothing new was given.
export type AlreadyRedeemed = {
	status: "already_redeemed",
	code: string,
	rewards: { Reward },
	redeemedAt: string?,
}
--- The code cannot be redeemed: unknown or disabled (`invalid`), past its end (`expired`), before its
--- start (`not_started`), or fully claimed (`exhausted`). Nothing was granted.
export type Refused = { status: "invalid" | "expired" | "not_started" | "exhausted" }
--- Nothing was confirmed: a timeout, outage or rate limit. Calling `redeem` again for the same player
--- and code is always safe; at most one grant ever happens.
export type Retry = { status: "retry", error: Core.BloxError }
--- Redemption was rejected for a reason the player cannot fix, such as missing permissions or an
--- award that no longer matches the schema. Log `error.code`; do not retry blindly.
export type Failed = { status: "failed", error: Core.BloxError }
export type Outcome = Granted | AlreadyRedeemed | Refused | Retry | Failed
--- Fields for a new code. The universe is the client's; each player can redeem a code once.
export type NewCode = {
	code: string,
	award: Award,
	name: string?,
	description: string?,
	startsAt: string?,
	expiresAt: string?,
	maxGlobalRedemptions: number?,
	active: boolean?,
	metadata: Core.Json?,
}
--- Fields for a batch of random codes sharing one award. `maxGlobalRedemptions` applies to each code.
--- Persist `idempotencyKey` before sending so a lost reply can be repeated safely.
export type NewBatch = {
	name: string,
	count: number,
	award: Award,
	prefix: string?,
	length: number?,
	description: string?,
	startsAt: string?,
	expiresAt: string?,
	maxGlobalRedemptions: number?,
	active: boolean?,
	metadata: { [string]: Core.Json }?,
	idempotencyKey: string?,
}
--- Fields to change on an existing code; omitted fields stay as they are.
export type CodeChanges = {
	code: string?,
	award: Award?,
	name: string?,
	description: string?,
	startsAt: string?,
	expiresAt: string?,
	maxGlobalRedemptions: number?,
	active: boolean?,
	metadata: Core.Json?,
}
export type CodeFilter = { active: boolean?, batchId: string?, page: number?, size: number? }
export type PageRequest = { page: number?, size: number? }
local RETRYABLE: { [Core.ErrorKind]: boolean } = {
	Network = true,
	Timeout = true,
	CircuitOpen = true,
	RateLimited = true,
	Server = true,
}
--- Bind the CodeService facade to the shared pipeline.
function Service.new(invoke: Core.Invoke, universe: (string | number)?, helpers: Helpers.State?): Service
	return setmetatable({ _invoke = invoke, _universe = universe, _fields = helpers }, Service)
end
--- Reduce a typed receipt to the fields it touched.
local function rewards(response: Types.RedeemCodeResponse): { Reward }
	local list: { Reward } = {}
	local transaction = response.transaction
	local results = if type(transaction) == "table" then (transaction :: any).results else nil
	if type(results) ~= "table" then
		return list
	end
	for _, item in results :: { Types.Result } do
		if type(item.field) == "string" and type(item.op) == "string" then
			local path: { string | number } = if type(item.path) == "table" then item.path :: any else {}
			table.insert(list, {
				field = item.field,
				op = item.op :: Types.Op,
				path = path,
				before = item.before :: Core.Json?,
				after = item.after :: Core.Json?,
			})
		end
	end
	return list
end
--- Sort a failed call into the few answers a game can act on.
local function classify(error: Core.BloxError): Outcome
	if error.code == "code_expired" then
		return { status = "expired" }
	elseif error.code == "code_not_started" then
		return { status = "not_started" }
	elseif error.code == "code_exhausted" then
		return { status = "exhausted" }
	elseif error.code == "code_inactive" then
		return { status = "invalid" }
	end
	if
		error.kind == "NotFound"
		or error.status == 400
		or (error.kind == "Validation" and error.status == nil)
	then
		local invalid: Refused = { status = "invalid" }
		return invalid
	end
	if RETRYABLE[error.kind] then
		return { status = "retry", error = error }
	end
	return { status = "failed", error = error }
end
--- Redeem `code` for a player, given a Player or user ID. Never raises on a bad code or backend failure:
--- switch on `outcome.status`. Requires CodeService READ_WRITE and Fields write access to the awarded fields.
--- POST /code-service/api/codes/redeem via gateway; access: READ_WRITE.
function Service.redeem(self: Service, user: Core.User, code: string, opts: Core.CallOptions?): Outcome
	local userId = assert(Universe.user(user), "Invalid user")
	local text = if type(code) == "string" then string.match(code, "^%s*(.-)%s*$") else nil
	if text == nil or text == "" or #text > 128 then
		local invalid: Refused = { status = "invalid" }
		return invalid
	end
	local options: Core.CallOptions = table.clone(opts or {})
	options.priority = options.priority or "critical"
	local result = self._invoke(
		Endpoints["codes.redeem"],
		{ body = { code = text, robloxUserId = userId } },
		options,
		self._universe
	)
	if not result.ok then
		return classify(result.error)
	end
	local value: Types.RedeemCodeResponse = result.value
	local granted = rewards(value)
	local name = if type(value.code) == "string" then value.code else text
	local at = if type(value.redeemedAt) == "string" then value.redeemedAt else nil
	if value.replayed then
		return { status = "already_redeemed", code = name, rewards = granted, redeemedAt = at }
	end
	return { status = "granted", code = name, rewards = granted, redeemedAt = at }
end
--- Start an award for a new code: `codes:award():add("Currency.Gems", 100):mapAdd("Inventory.Items", "SWORD", 1)`.
--- Pass the builder (or a plain operation list) as `award`; the schema loads and validates on use.
function Service.award(self: Service): Award.Builder
	return Award.new(assert(self._fields, "Fields helpers unavailable"), Universe.bound(self._universe))
end
--- Resolve `award` and place it in a copy of the caller's request fields.
local function withAward<T>(self: Service, fields: T, award: Award?): Core.Result<T>
	local body: any = table.clone(fields :: any)
	if award ~= nil then
		local prepared =
			Award.prepare(assert(self._fields, "Fields helpers unavailable"), self._universe, award)
		if not prepared.ok then
			return prepared
		end
		body.award = prepared.value
	end
	return { ok = true, value = body }
end
--- Create one code. `award` may be a `codes:award()` builder or an operation list; it is validated first.
--- POST /code-service/api/codes via gateway; access: ADMIN.
function Service.create(self: Service, spec: NewCode, opts: Core.CallOptions?): Core.Result<Types.CodeDto>
	local body = withAward(self, spec, spec.award)
	if not body.ok then
		return body
	end
	return self._invoke(Endpoints["codes.createCode"], { body = body.value }, opts, self._universe)
end
--- Create `count` random codes that share one award, all or nothing. Keep this in trusted admin tooling.
--- POST /code-service/api/codes/bulk via gateway; access: ADMIN.
function Service.createBatch(
	self: Service,
	spec: NewBatch,
	opts: Core.CallOptions?
): Core.Result<Types.BulkCreateCodesResponse>
	local body = withAward(self, spec, spec.award)
	if not body.ok then
		return body
	end
	local fields: any = body.value
	local key = fields.idempotencyKey
	fields.idempotencyKey = nil
	return self._invoke(
		Endpoints["codes.bulkCreateCodes"],
		{ idempotencyKey = key, body = fields },
		opts,
		self._universe
	)
end
--- Download a batch's codes as CSV text; treat it as a secret and never log it.
--- GET /code-service/api/codes/batches/{batchId}/export via gateway; access: ADMIN.
function Service.exportBatch(self: Service, batchId: string, opts: Core.CallOptions?): Core.Result<string>
	return self._invoke(
		Endpoints["codes.exportBatch"],
		{ path = { batchId = batchId } },
		opts,
		self._universe
	)
end
--- List this universe's codes, newest first; filter by `active` or `batchId`.
--- GET /code-service/api/codes via gateway; access: READ.
function Service.list(
	self: Service,
	filter: CodeFilter?,
	opts: Core.CallOptions?
): Core.Result<Types.Page<Types.CodeDto>>
	return self._invoke(Endpoints["codes.searchCodes"], { query = filter }, opts, self._universe)
end
--- Read one code by its numeric ID, including remaining capacity and `redeemableNow`.
--- GET /code-service/api/codes/{id} via gateway; access: READ.
function Service.get(self: Service, id: number | string, opts: Core.CallOptions?): Core.Result<Types.CodeDto>
	return self._invoke(Endpoints["codes.getCode"], { path = { id = id } }, opts, self._universe)
end
--- Change a code; a new `award` only affects future redemptions.
--- PUT /code-service/api/codes/{id} via gateway; access: ADMIN.
function Service.update(
	self: Service,
	id: number | string,
	changes: CodeChanges,
	opts: Core.CallOptions?
): Core.Result<Types.CodeDto>
	local body = withAward(self, changes, changes.award)
	if not body.ok then
		return body
	end
	return self._invoke(
		Endpoints["codes.updateCode"],
		{ path = { id = id }, body = body.value },
		opts,
		self._universe
	)
end
--- Delete a code that has no pending grants.
--- DELETE /code-service/api/codes/{id} via gateway; access: ADMIN.
function Service.delete(self: Service, id: number | string, opts: Core.CallOptions?): Core.Result<nil>
	return self._invoke(Endpoints["codes.deleteCode"], { path = { id = id } }, opts, self._universe)
end
--- Page through who redeemed a code, newest first.
--- GET /code-service/api/codes/{id}/redemptions via gateway; access: ADMIN.
function Service.redemptions(
	self: Service,
	id: number | string,
	page: PageRequest?,
	opts: Core.CallOptions?
): Core.Result<Types.Page<Types.CodeRedemptionDto>>
	return self._invoke(
		Endpoints["codes.listRedemptions"],
		{ path = { id = id }, query = page },
		opts,
		self._universe
	)
end
--- GET /code-service/actuator/health/liveness via gateway; access: public/authenticated.
function Service.liveness(self: Service, opts: Core.CallOptions?): Core.Result<Types.HealthComponent>
	return self._invoke(Endpoints["codes.liveness"], {}, opts, self._universe)
end
--- GET /code-service/actuator/health/readiness via gateway; access: public/authenticated.
function Service.readiness(self: Service, opts: Core.CallOptions?): Core.Result<Types.HealthComponent>
	return self._invoke(Endpoints["codes.readiness"], {}, opts, self._universe)
end
--- GET /code-service/health via gateway; access: public/authenticated.
function Service.healthProxy(self: Service, opts: Core.CallOptions?): Core.Result<Types.HealthResponse>
	return self._invoke(Endpoints["codes.healthProxy"], {}, opts, self._universe)
end
--- GET /code-service/info via gateway; access: public/authenticated.
function Service.info(self: Service, opts: Core.CallOptions?): Core.Result<{ [string]: Core.Json }>
	return self._invoke(Endpoints["codes.info"], {}, opts, self._universe)
end
--- GET /code-service/metrics via gateway; access: public/authenticated.
function Service.metrics(self: Service, opts: Core.CallOptions?): Core.Result<Types.MetricsResponse>
	return self._invoke(Endpoints["codes.metrics"], {}, opts, self._universe)
end
return table.freeze(Service)
