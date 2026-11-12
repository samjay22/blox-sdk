--!strict
local Core = require("../Types/Core")
local FieldTypes = require("../Fields/Types")
local Fields = require("../Fields/Client")
local OpBuilder = require("../Fields/OpBuilder")
local Operations = require("../Fields/Operations")
local System = require("../Fields/TypeSystem")
local Universe = require("../Core/Universe")
local Award = {}
export type Builder = OpBuilder.Builder
--- What a code grants: a builder from `codes:award()` or a plain list of subject-free Fields operations.
export type Award = Builder | { FieldTypes.PlayerOperation }
--- Compose the Fields op builder; awards have no subject, conditions, reason or caller key.
function Award.new(state: Fields.State, universeId: string | number): Builder
	return Fields.operations(state, universeId)
end
--- Builders carry a `build` method through their metatable; an operation list never does.
local function isBuilder(award: unknown): boolean
	return type(award) == "table"
		and rawget(award :: any, 1) == nil
		and type((award :: any).build) == "function"
end
--- Resolve an award to a canonical private operation list, loading the universe schema on first use.
function Award.prepare(
	state: Fields.State,
	universeId: (string | number)?,
	award: Award
): Core.Result<{ FieldTypes.PlayerOperation }>
	if state.closed then
		return System.failure("client_closed")
	end
	if type(award) ~= "table" or not Universe.valid(universeId) then
		return System.failure("invalid_request")
	end
	if isBuilder(award) then
		local builder = award :: Builder
		local loaded = builder._schema:load()
		if not loaded.ok then
			return loaded
		end
		return builder:build()
	end
	local schema = Fields.schema(state, universeId :: string | number)
	local loaded = schema:load()
	if not loaded.ok then
		return loaded
	end
	return Operations.prepare(schema, award :: { FieldTypes.PlayerOperation })
end
return table.freeze(Award)
