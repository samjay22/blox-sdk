--!strict
local Core = require("../Types/Core")
local Types = require("../Types/Codes")
local Fields = require("../Fields/Client")
local OpBuilder = require("../Fields/OpBuilder")
local Operations = require("../Fields/Operations")
local System = require("../Fields/TypeSystem")
local Copy = require("../Core/Idempotency")
local Universe = require("../Core/Universe")
local Award = {}
export type Builder = OpBuilder.Builder
--- Compose the Fields op builder; awards have no subject, conditions, reason or caller key.
function Award.new(state: Fields.State, universeId: string | number): Builder
	return Fields.operations(state, universeId)
end
--- Validate against the same universe schema before any CodeService create request.
function Award.create(
	state: Fields.State,
	req: Types.CreateCodeRequest,
	universeId: (string | number)?
): Core.Result<Types.CreateCodeRequest>
	if state.closed then
		return System.failure("client_closed")
	end
	if type(req) ~= "table" then
		return System.failure("invalid_request")
	end
	if req.maxRedemptionsPerUser ~= nil and req.maxRedemptionsPerUser ~= 1 then
		return System.failure("invalid_request")
	end
	local scope = req.universeId or universeId
	if not Universe.valid(scope) then
		return System.failure("invalid_request")
	end
	local prepared = Operations.prepare(Fields.schema(state, scope :: string | number), req.award)
	if not prepared.ok then
		return prepared
	end
	local copied, result = pcall(Copy.copy, req)
	if not copied then
		return System.failure("invalid_request")
	end
	result.award = prepared.value
	return { ok = true, value = result }
end
--- Validate replacement awards for scoped updates; the backend revalidates unchanged awards too.
function Award.update(
	state: Fields.State,
	req: Types.UpdateCodeCall,
	universeId: (string | number)?
): Core.Result<Types.UpdateCodeCall>
	if state.closed then
		return System.failure("client_closed")
	end
	if type(req) ~= "table" or type(req.body) ~= "table" then
		return System.failure("invalid_request")
	end
	if req.body.maxRedemptionsPerUser ~= nil and req.body.maxRedemptionsPerUser ~= 1 then
		return System.failure("invalid_request")
	end
	if req.body.award == nil then
		return { ok = true, value = req }
	end
	if not Universe.valid(universeId) then
		return System.failure("invalid_request")
	end
	local prepared = Operations.prepare(Fields.schema(state, universeId :: string | number), req.body.award)
	if not prepared.ok then
		return prepared
	end
	local copied, result = pcall(Copy.copy, req)
	if not copied then
		return System.failure("invalid_request")
	end
	result.body.award = prepared.value
	return { ok = true, value = result }
end
return table.freeze(Award)
