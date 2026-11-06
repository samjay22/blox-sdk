--!strict
local Core = require("../Types/Core")
local Helpers = require("./Client")
local Universe = require("../Core/Universe")
local Endpoints = require("../Core/Endpoints")
local Errors = require("../Core/Errors")
local Scope = {}
export type Scope = { state: Helpers.State, universe: string | number }
--- Bind a server helper without fetching schema or starting any background work.
function Scope.new(state: Helpers.State, universe: string | number): Scope
	assert(Universe.valid(universe), "Invalid Fields scope")
	return { state = state, universe = universe }
end
--- Preserve shared pipeline authorization, routing, deadlines and client lifetime on every call.
function Scope.call(
	scope: Scope,
	endpoint: string,
	request: unknown,
	options: Core.CallOptions?
): Core.Result<any>
	if scope.state.closed then
		return Errors.make("Cancelled", endpoint, 0, "Client is closed")
	end
	local typed = request :: Core.Request
	local scoped = table.clone(typed)
	local path: { [string]: unknown } = table.clone(typed.path or {})
	path.universeId = scope.universe
	scoped.path = path
	return scope.state.invoke(Endpoints[endpoint], scoped, options, scope.universe)
end
return table.freeze(Scope)
