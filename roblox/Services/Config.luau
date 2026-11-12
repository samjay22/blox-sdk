--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
-- Hand-written facade over ConfigService: dynamic game configuration, grouped into namespaces of JSON values.
-- The universe is the client's, so no method takes one. tools/gen.py generates the wire types and endpoint
-- metadata this file uses; tools/check-coverage verifies that every ConfigService route is reachable.
local Core = require(script.Parent.Parent.Types.Core)
local Config = require(script.Parent.Parent.Core.Config)
local Endpoints = require(script.Parent.Parent.Core.Endpoints)
local Pagination = require(script.Parent.Parent.Core.Pagination)
local Namespace = require(script.Parent.Parent.Configs.Namespace)
local Types = require(script.Parent.Parent.Types.Config)
local Service = {}
Service.__index = Service
export type Namespace = Namespace.Namespace
export type Change = Namespace.Change
export type Snapshot = Namespace.Snapshot
export type Options = Namespace.Options
export type WriteOptions = Namespace.WriteOptions
export type Changes = Namespace.Changes
export type Page = Namespace.Page
--- What the facade needs from the client that owns it: the shared handle registry, defaults and lifecycle.
export type Host = {
	runtime: Core.Runtime,
	handles: { [string]: Namespace.Namespace },
	defaults: Config.ConfigsConfig?,
	closing: () -> boolean,
	onUse: () -> (),
}
export type Service = typeof(setmetatable(
	{} :: { _invoke: Core.Invoke, _universe: (string | number)?, _host: Host },
	Service
))
--- Bind the ConfigService facade to the shared pipeline.
function Service.new(invoke: Core.Invoke, universe: (string | number)?, host: Host): Service
	return setmetatable({ _invoke = invoke, _universe = universe, _host = host }, Service)
end
--- The live view of one namespace, e.g. `client.configs:namespace("Shop")`. The first call starts that
--- namespace's single poller (every 30 seconds by default, jittered); later calls return the same handle, and
--- `options` only apply to the call that creates it. Use `:waitReady()` before the first read if defaults are
--- not acceptable at startup. Pollers stop on `client:flush()` and `client:destroy()`.
function Service.namespace(self: Service, name: string, options: Options?): Namespace.Namespace
	local host = self._host
	assert(Namespace.validName(name), "Invalid namespace name")
	assert(not host.closing(), "Client is closing")
	local key = tostring(self._universe) .. "/" .. name
	local existing = host.handles[key]
	if existing and not existing:isDestroyed() then
		return existing
	end
	host.onUse()
	local created: Namespace.Namespace? = nil
	local handle = Namespace.new(
		name,
		self._invoke,
		self._universe,
		host.runtime,
		host.defaults,
		options,
		function()
			if host.handles[key] == created then
				host.handles[key] = nil
			end
		end
	)
	created = handle
	host.handles[key] = handle
	return handle
end
--- List this universe's namespaces by name, with version and entry count.
--- GET /remote-config-service/api/config/universes/{universeId}/namespaces via gateway; access: READ.
function Service.namespaces(
	self: Service,
	page: Page?,
	opts: Core.CallOptions?
): Core.Result<Types.CursorPage<Types.Namespace>>
	return self._invoke(Endpoints["config.namespaces"], { query = page }, opts, self._universe)
end
--- Lazily iterate every namespace page; errors are yielded once and end the iteration.
function Service.namespacesPages(
	self: Service,
	page: Page?,
	opts: Core.CallOptions?,
	maximum: number?
): () -> Core.Result<Types.CursorPage<Types.Namespace>>?
	local query: Page = table.clone(page or {})
	return Pagination.cursor(function(cursor: string?)
		query.cursor = cursor
		return Service.namespaces(self, query, opts)
	end, function(result: Types.CursorPage<Types.Namespace>)
		return result.nextCursor
	end, maximum, query.cursor)
end
--- GET /remote-config-service/actuator/health/liveness via gateway; access: public/authenticated.
function Service.liveness(self: Service, opts: Core.CallOptions?): Core.Result<Types.HealthComponent>
	return self._invoke(Endpoints["config.liveness"], {}, opts, self._universe)
end
--- GET /remote-config-service/actuator/health/readiness via gateway; access: public/authenticated.
function Service.readiness(self: Service, opts: Core.CallOptions?): Core.Result<Types.HealthComponent>
	return self._invoke(Endpoints["config.readiness"], {}, opts, self._universe)
end
--- GET /remote-config-service/health via gateway; access: public/authenticated.
function Service.healthProxy(self: Service, opts: Core.CallOptions?): Core.Result<Types.HealthResponse>
	return self._invoke(Endpoints["config.healthProxy"], {}, opts, self._universe)
end
return table.freeze(Service)
