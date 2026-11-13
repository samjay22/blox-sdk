--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Errors = {}
local statusKinds: { [number]: Types.ErrorKind } = {
	[400] = "Validation",
	[401] = "Unauthorized",
	[403] = "Forbidden",
	[404] = "NotFound",
	[409] = "Conflict",
	[422] = "Validation",
	[429] = "RateLimited",
	[408] = "Timeout",
}
table.freeze(statusKinds)
--- Create a safe error without copying backend text, URLs, headers or payloads.
function Errors.make(
	kind: Types.ErrorKind,
	endpoint: string,
	attempts: number,
	message: string,
	status: number?
): Types.Result<any>
	return {
		ok = false,
		error = {
			kind = kind,
			code = "sdk_" .. string.lower((string.gsub(kind, "(%l)(%u)", "%1_%2"))),
			endpoint = endpoint,
			attempts = attempts,
			message = message,
			status = status,
			body = if status then "[redacted]" else nil,
		},
	}
end
--- Map wire status to the stable public error taxonomy.
function Errors.http(status: number, endpoint: string, attempts: number): Types.Result<any>
	local kind: Types.ErrorKind = statusKinds[status] or (if status >= 500 then "Server" else "Validation")
	return Errors.make(kind, endpoint, attempts, "HTTP request failed", status)
end
local authCodes: { [string]: boolean } = table.freeze({
	resource_not_found = true,
	access_denied = true,
	permission_cap = true,
	cannot_change_own_role = true,
	last_owner = true,
	org_universe_limit = true,
	org_member_limit = true,
	org_service_account_limit = true,
	org_creation_limit = true,
	org_not_empty = true,
	member_exists = true,
	exactly_one_identifier_required = true,
	platform_admin_cannot_join_org = true,
	slug_exhausted = true,
	resource_conflict = true,
	invalid_invitation = true,
	invalid_invitation_expiry = true,
	invalid_permissions = true,
	invalid_cursor = true,
	invalid_page = true,
	UNKNOWN_SERVICE = true,
	RATE_LIMITED = true,
	VALIDATION_ERROR = true,
	INVALID_REQUEST = true,
	WEAK_PASSWORD = true,
	INVALID_CREDENTIALS = true,
	ACCOUNT_DISABLED = true,
	USERNAME_EXISTS = true,
	EMAIL_EXISTS = true,
	TOKEN_EXPIRED = true,
	INVALID_TOKEN = true,
	INVALID_TOKEN_TYPE = true,
	INVALID_SERVICE_ACCOUNT = true,
	SERVICE_ACCOUNT_NOT_FOUND = true,
	SERVICE_ACCOUNT_REVOKED = true,
	SERVICE_ACCOUNT_CONFLICT = true,
	SERVICE_NOT_FOUND = true,
	SERVICE_EXISTS = true,
	SERVICE_CONFLICT = true,
	INTERNAL_ERROR = true,
})
-- ConfigService error codes; the 409 `version_conflict` means an expectedVersion check failed.
local configCodes: { [string]: boolean } = table.freeze({
	namespace_not_found = true,
	key_not_found = true,
	version_not_found = true,
	version_conflict = true,
	validation_failed = true,
	limit_exceeded = true,
	-- Item lists (namespaces of kind `items`).
	invalid_member = true,
	bit_immutable = true,
	bit_taken = true,
	kind_immutable = true,
	member_in_use = true,
	holder_check_unavailable = true,
	rollback_invalid = true,
})
local codes = table.freeze({
	rotation_not_found = true,
	rotation_version_conflict = true,
	insufficient_funds = true,
	code_expired = true,
	code_not_started = true,
	code_exhausted = true,
	code_inactive = true,

	alert_config_unavailable = true,
	alert_not_found = true,
	bulk_definition_not_found = true,
	conversion_clamp = true,
	conversion_parse = true,
	conversion_unsupported = true,
	environment_changed = true,
	export_schema_changed = true,
	export_size_limit = true,
	filter_schema_changed = true,
	flag_not_found = true,
	flag_version_conflict = true,
	invalid_job_input = true,
	invalid_ops = true,
	job_download_expired = true,
	job_download_not_ready = true,
	job_lease_lost = true,
	job_not_failed = true,
	job_not_found = true,
	job_not_reversible = true,
	migration_in_progress = true,
	migration_not_complete = true,
	migration_requires_active_stored_field = true,
	migration_snapshot_not_found = true,
	migration_unconverted = true,
	rollback_cannot_cancel = true,
	schedule_action_already_done = true,
	schedule_already_started = true,
	schedule_not_active = true,
	schedule_not_found = true,
	webhook_delivery_failed = true,
	webhook_not_configured = true,

	leaderboard_requires_int = true,
	leaderboard_score_range = true,
	leaderboard_board_mismatch = true,
	leaderboard_board_archived = true,
	leaderboard_unavailable = true,
	invalid_award = true,
	criteria_field_invalid = true,
	fields_unavailable = true,
	session_conflict = true,
	unauthorized = true,
	forbidden = true,
	invalid_request = true,
	bad_request = true,
	invalid_definition = true,
	field_not_found = true,
	entry_not_found = true,
	transaction_not_found = true,
	path_not_found = true,
	field_exists = true,
	field_prefix_conflict = true,
	definition_version_conflict = true,
	incompatible_type = true,
	incompatible_member = true,
	member_removed = true,
	new_member_requires_default = true,
	stored_value_conflict = true,
	already_reversed = true,
	reverse_conflict = true,
	snapshot_unavailable = true,
	incomplete_history = true,
	field_not_archived = true,
	field_in_use = true,
	conflict = true,
	missing_value = true,
	default_required = true,
	non_finite_number = true,
	below_min_length = true,
	above_max_length = true,
	pattern_mismatch = true,
	pattern_input_too_long = true,
	below_min_size = true,
	above_max_size = true,
	duplicate_element = true,
	invalid_map_key = true,
	null_path = true,
	value_too_large = true,
	snapshot_not_found = true,
	receipt_not_found = true,
	outbox_not_found = true,
	computed_dependency = true,
	snapshot_in_use = true,
	outbox_already_done = true,
	internal_server_error = true,
	precondition_failed = true,
	seq_conflict = true,
	idempotency_conflict = true,
	purchase_id_conflict = true,
	field_archived = true,
	field_computed = true,
	invalid_subject = true,
	unknown_field = true,
	below_min = true,
	above_max = true,
	int64_overflow = true,
	max_delta_exceeded = true,
	zero_delta = true,
	wrong_type = true,
	missing_member = true,
	unknown_member = true,
	member_retired = true,
	member_limit = true,
	member_not_found = true,
	invalid_member_name = true,
	invalid_bitmap = true,
	enum_source_unavailable = true,
	source_immutable = true,
	invalid_enum = true,
	not_found = true,
	invalid_path = true,
	invalid_index = true,
	op_not_applicable = true,
	field_disabled = true,
	maintenance = true,
	product_disabled = true,
	product_not_found = true,
	already_refunded = true,
	refund_blocked = true,
	idempotency_data_deleted = true,
	-- API-key restrictions: the key's field scope refuses the request, or the key's own rate limit is exhausted.
	scope_denied = true,
	key_rate_limited = true,
})
--- Accept only bounded diagnostic coordinates and known machine codes, never server text/payloads.
local function diagnostic(value: any): Types.OperationDiagnostic?
	if
		type(value) ~= "table"
		or type(value.code) ~= "string"
		or not codes[value.code]
		or type(value.opIndex) ~= "number"
		or value.opIndex % 1 ~= 0
		or value.opIndex < 0
		or value.opIndex > 99
		or type(value.field) ~= "string"
		or #value.field > 200
		or not string.match(value.field, "^[A-Za-z][A-Za-z0-9_.]*$")
		or type(value.path) ~= "table"
		or #value.path > 8
	then
		return nil
	end
	local path: { string | number } = {}
	for i, part in value.path do
		if type(i) ~= "number" or i % 1 ~= 0 or i < 1 or i > #value.path then
			return nil
		end
		if type(part) == "string" then
			if #part > 200 then
				return nil
			end
		elseif type(part) ~= "number" or part % 1 ~= 0 or part < 0 or part > 2147483647 then
			return nil
		end
		path[i] = part
	end
	return { opIndex = value.opIndex, field = value.field, path = path, code = value.code }
end
-- CodeService refuses a redemption with a 409 whose only signal is fixed text; map exactly those texts to codes.
local redeemRefusals = table.freeze({
	["Code has expired"] = "code_expired",
	["Code is not active yet"] = "code_not_started",
	["Code is not active"] = "code_inactive",
	["Code redemption limit reached (including pending grants)"] = "code_exhausted",
})
--- Copy at most `limit` strings of a decoded array; anything else yields nil.
local function strings(value: unknown, limit: number): { string }?
	if type(value) ~= "table" then
		return nil
	end
	local list: { string } = {}
	for index, item in value :: { unknown } do
		if type(index) ~= "number" or index > limit or type(item) ~= "string" or #item > 200 then
			return nil
		end
		list[index] = item
	end
	return list
end
--- Copy the holders that block removing an item list member (`details.holders`), bounded and validated.
local function holders(value: unknown): { Types.MemberHolders }?
	if type(value) ~= "table" then
		return nil
	end
	local list: { Types.MemberHolders } = {}
	for index, item in value :: { unknown } do
		if type(index) ~= "number" or index > 512 or type(item) ~= "table" then
			return nil
		end
		local row = item :: { [string]: unknown }
		local samples: { number } = {}
		if
			type(row.member) ~= "string"
			or type(row.count) ~= "number"
			or type(row.samplePlayers) ~= "table"
		then
			return nil
		end
		for position, id in row.samplePlayers :: { unknown } do
			if type(position) ~= "number" or position > 5 or type(id) ~= "number" then
				return nil
			end
			samples[position] = id
		end
		list[index] = { member = row.member, count = row.count, samplePlayers = samples }
	end
	return list
end
--- Item list details: the member names behind `unknown_member`/`member_retired`, the list, the cap, the holders.
local function memberDetails(error: Types.BloxError, body: { [string]: unknown })
	error.members = strings(body.members, 20)
	if type(body.source) == "string" and #body.source <= 64 then
		error.source = body.source
	end
	if type(body.maxMembers) == "number" then
		error.maxMembers = body.maxMembers
	end
	local details = body.details
	if type(details) == "table" then
		error.holders = holders((details :: { [string]: unknown }).holders)
	end
end
--- Preserve only allowlisted machine codes, never backend messages or raw error bodies.
function Errors.domain(status: number, endpoint: string, attempts: number, value: unknown): Types.Result<any>
	local result = Errors.http(status, endpoint, attempts)
	if not result.ok and type(value) == "table" then
		local body = value :: { [string]: unknown }
		if string.sub(endpoint, 1, 5) == "auth." then
			local code = body.errorCode or body.error
			if type(code) == "string" and authCodes[code] then
				result.error.code = string.lower(code)
			end
		end
		if type(body.errors) == "table" then
			local list: { Types.OperationDiagnostic } = {}
			local seen = 0
			for _, item in body.errors :: { unknown } do
				seen += 1
				if seen > 100 then
					break
				end
				local safe = diagnostic(item)
				if safe then
					table.insert(list, safe)
				end
			end
			if #list > 0 then
				result.error.errors = list
			end
		end
		if
			string.sub(endpoint, 1, 7) == "config."
			and type(body.code) == "string"
			and configCodes[body.code]
		then
			result.error.code = body.code
		end
		if endpoint == "codes.redeem" and status == 409 and type(body.message) == "string" then
			result.error.code = redeemRefusals[body.message] or result.error.code
		end
		if string.sub(endpoint, 1, 7) == "fields." or string.sub(endpoint, 1, 7) == "config." then
			memberDetails(result.error, body)
		end
		if type(body.grantPending) == "boolean" then
			result.error.grantPending = body.grantPending
		end
		-- Matchmaking uses errorCode; Fields and Codes use code. Never copy arbitrary server text.
		local code = if string.sub(endpoint, 1, 12) == "matchmaking."
			then body.errorCode or body.code
			else body.code
		if type(code) == "string" and codes[code] then
			result.error.code = string.lower(code)
			if
				body.code == "session_conflict"
				and type(body.placeId) == "number"
				and body.placeId % 1 == 0
				and body.placeId > 0
				and body.placeId <= 9007199254740991
			then
				result.error.placeId = body.placeId
			end
		end
	end
	return result
end
return table.freeze(Errors)
