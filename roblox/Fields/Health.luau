--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Core = require(script.Parent.Parent.Types.Core)
local Wire = require(script.Parent.Parent.Types.Fields)
local Helpers = require(script.Parent.Parent.Fields.Client)
local Scope = require(script.Parent.Parent.Fields.Scope)
local Health = {}
Health.__index = Health
export type Client = typeof(setmetatable({} :: { _scope: Scope.Scope }, Health))
--- Bind the READ-only compact health facade without starting any polling.
function Health.new(state: Helpers.State, universe: string | number): Client
	return setmetatable({ _scope = Scope.new(state, universe) }, Health)
end
--- Fetch aggregate counts; acknowledged unresolved alerts remain included.
function Health.summary(self: Client, options: Core.CallOptions?): Core.Result<Wire.HealthSummary>
	return Scope.call(self._scope, "fields.healthSummary", {}, options)
end
return table.freeze(Health)
