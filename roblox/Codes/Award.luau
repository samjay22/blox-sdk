--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Types = require(script.Parent.Parent.Types.Codes)
local Fields = require(script.Parent.Parent.Fields.Client)
local OpBuilder = require(script.Parent.Parent.Fields.OpBuilder)
local Operations = require(script.Parent.Parent.Fields.Operations)
local System = require(script.Parent.Parent.Fields.TypeSystem)
local Copy = require(script.Parent.Parent.Core.Idempotency)
local Universe = require(script.Parent.Parent.Core.Universe)
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
