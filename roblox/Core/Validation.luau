--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Schemas = require(script.Parent.Parent.Core.Schemas)
local Json = require(script.Parent.Parent.Core.Json)
local Universe = require(script.Parent.Parent.Core.Universe)
local Operations = require(script.Parent.Parent.Fields.Operations)
local Bindings = require(script.Parent.Parent.Fields.Bindings)
local TypeSystem = require(script.Parent.Parent.Fields.TypeSystem)
local Validation = {}
--- Validate untrusted data against the small generated schema language, with bounded recursion.
local function matches(
	value: any,
	schema: Core.Schema,
	definitions: { [string]: Core.Schema },
	depth: number,
	response: boolean
): boolean
	if depth > 64 then
		return false
	end
	local kind = schema.kind
	if kind == "fields" and schema.name == "PlayerOperation" then
		return Operations.wire(value) and matches(value, { kind = "json" }, definitions, depth + 1, response)
	elseif kind == "fields" and schema.name == "PathSegment" then
		return type(value) == "string"
			or type(value) == "number" and value % 1 == 0 and value >= 0 and value <= 2147483647
	elseif kind == "fields" and schema.name == "LeaderboardBinding" then
		return Bindings.board(value)
	elseif kind == "fields" and schema.name == "Bindings" then
		return Bindings.grammar(value)
	end
	if kind == "ref" then
		local target = definitions[schema.name :: string]
		return target ~= nil and matches(value, target, definitions, depth + 1, response)
	elseif kind == "nullable" then
		return value == Json.null
			or matches(value, schema.item :: Core.Schema, definitions, depth + 1, response)
	elseif kind == "nil" then
		return value == nil
	elseif kind == "union" then
		for _, item in schema.items :: { Core.Schema } do
			if matches(value, item, definitions, depth + 1, response) then
				return true
			end
		end
		return false
	elseif kind == "enum" then
		return type(value) == "string" and table.find(schema.values :: { string }, value) ~= nil
	elseif kind == "string" or kind == "boolean" then
		return type(value) == kind
	elseif kind == "decimal" then
		return (type(value) == "number" and value % 1 == 0 and math.abs(value) <= 9007199254740991)
			or (
				type(value) == "string"
				and string.match(value, "^%-?%d+$") ~= nil
				and #string.gsub(value, "^-", "") <= 38
			)
	elseif kind == "number" then
		return type(value) == "number" and value == value and math.abs(value) <= 9007199254740991
	elseif kind == "json" or kind == "fields" then
		if value == nil or value == Json.null then
			return true
		end
		local t = type(value)
		if t == "string" or t == "boolean" then
			return true
		end
		if t == "number" then
			return value == value and math.abs(value) < math.huge
		end
		if t ~= "table" then
			return false
		end
		for key, child in value do
			if type(key) ~= "string" and type(key) ~= "number" then
				return false
			end
			if not matches(child, schema, definitions, depth + 1, response) then
				return false
			end
		end
		return true
	end
	if type(value) ~= "table" or value == Json.null then
		return false
	end
	if kind == "array" then
		if Json.isObject(value) then
			return false
		end
		local count = 0
		for key, item in value do
			if
				type(key) ~= "number"
				or key % 1 ~= 0
				or key < 1
				or key > #value
				or not matches(item, schema.item :: Core.Schema, definitions, depth + 1, response)
			then
				return false
			end
			count += 1
		end
		return count == #value
	elseif kind == "map" then
		for key, item in value do
			if
				type(key) ~= "string"
				or not matches(item, schema.item :: Core.Schema, definitions, depth + 1, response)
			then
				return false
			end
		end
		return true
	elseif kind == "cursorPage" then
		return matches(value.items, { kind = "array", item = schema.item }, definitions, depth + 1, response)
			and (
				value.nextCursor == nil
				or value.nextCursor == Json.null
				or type(value.nextCursor) == "string"
			)
	elseif kind == "page" then
		return type(value.number) == "number"
			and type(value.size) == "number"
			and type(value.totalElements) == "number"
			and type(value.totalPages) == "number"
			and type(value.first) == "boolean"
			and type(value.last) == "boolean"
			and matches(
				value.content,
				{ kind = "array", item = schema.item },
				definitions,
				depth + 1,
				response
			)
	elseif kind == "object" then
		local fields =
			schema.fields :: { [string]: { schema: Core.Schema, required: boolean, notBlank: boolean } }
		for name, field in fields do
			local child = value[name]
			if
				not response
				and child ~= nil
				and (
					name == "idempotencyKey"
					or name == "submissionId"
					or name == "idemKey"
					or name == "matchId"
				)
			then
				local limit = if name == "idemKey" then 256 elseif name == "idempotencyKey" then 200 else 128
				if
					type(child) ~= "string"
					or #child == 0
					or #child > limit
					or string.match(child, "^%s*$")
				then
					return false
				end
				if name == "idempotencyKey" and not string.match(child, "^[A-Za-z0-9._-]+$") then
					return false
				end
			end
			if child == nil then
				if field.required then
					return false
				end
			else
				if
					not response
					and (name == "universeId" or name == "robloxUniverseId")
					and not Universe.valid(child)
				then
					return false
				end
				if not matches(child, field.schema, definitions, depth + 1, response) then
					return false
				end
				if
					not response
					and field.notBlank
					and type(child) == "string"
					and string.match(child, "^%s*$")
				then
					return false
				end
			end
		end
		-- Requests reject unknown fields so typos cannot silently discard data. Responses are forward-compatible.
		if not response then
			for name in value do
				if not fields[name] then
					return false
				end
			end
		end
		return true
	end
	return false
end
--- Validate declared DTOs without including values in errors.
function Validation.body(endpoint: string, value: unknown): boolean
	local schema = Schemas.endpoints[endpoint]
	if not schema or not schema.body then
		return value == nil
	end
	if value == nil then
		return true
	end
	if not matches(value, schema.body, Schemas.definitions[schema.service], 0, false) then
		return false
	end
	local body = value :: any
	if endpoint == "codes.bulkCreateCodes" then
		return body.count % 1 == 0
			and body.count >= 1
			and body.count <= 1000
			and (body.length == nil or body.length % 1 == 0 and body.length >= 8 and body.length <= 16)
			and #body.award >= 1
			and #body.award <= 100
	end
	if endpoint == "fields.previewBoard" then
		return TypeSystem.compile(body.type).ok
			and Bindings.validate({ leaderboards = { body.binding } }, body.scope, body.type, false).ok
	elseif endpoint == "fields.create" or endpoint == "fields.update" then
		if
			not Bindings.validate(
				body.bindings,
				body.scope,
				body.type,
				body.computed ~= nil and body.computed ~= Json.null
			).ok
		then
			return false
		end
		if
			body.bindings
			and body.bindings ~= Json.null
			and body.bindings.leaderboards
			and #body.bindings.leaderboards > 0
		then
			return TypeSystem.compile(body.type).ok
		end
	end
	if endpoint == "codes.createCode" or endpoint == "codes.updateCode" then
		if body.maxRedemptionsPerUser ~= nil and body.maxRedemptionsPerUser ~= 1 then
			return false
		end
		if body.award ~= nil and (#body.award < 1 or #body.award > 100) then
			return false
		end
	end
	if endpoint == "audit.batch" then
		return #body.events >= 1 and #body.events <= 500
	end
	if endpoint == "leaderboards.batch" then
		return #body.scores >= 1 and #body.scores <= 200
	end
	return true
end
--- Verify successful responses before exposing generated static types.
function Validation.response(endpoint: string, value: unknown, status: number?): boolean
	if status == 204 then
		return value == nil
	end
	local schema = Schemas.endpoints[endpoint]
	if not schema or not matches(value, schema.response, Schemas.definitions[schema.service], 0, true) then
		return false
	end
	if endpoint == "fields.validateOps" then
		local report: any = value
		if #report.errors > 100 or report.valid ~= (#report.errors == 0) then
			return false
		end
		local previous = -1
		for _, issue in report.errors do
			if
				issue.opIndex % 1 ~= 0
				or issue.opIndex <= previous
				or issue.opIndex > 99
				or #issue.path > 8
			then
				return false
			end
			previous = issue.opIndex
		end
	end
	return true
end
return table.freeze(Validation)
