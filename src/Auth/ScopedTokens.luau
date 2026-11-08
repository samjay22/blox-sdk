--!strict
local Core = require("../Types/Core")
local Auth = require("../Types/Auth")
local Session = require("./UserSession")
local Universe = require("../Core/Universe")
local Errors = require("../Core/Errors")
local Cache = require("../Core/Cache")
local ScopedTokens = {}
export type Provider = Core.AuthProvider & {
	get: (number?, Core.Signal?) -> Core.Result<Auth.Token>,
}
type Flight = { done: boolean, result: Core.Result<Auth.Token>?, epoch: number }

--- Cache one universe credential; exchanges use the identity session, never a scoped refresh token.
function ScopedTokens.new(
	runtime: Core.Runtime,
	session: Session.Session,
	universe: string | number,
	exchange: () -> Core.Result<Auth.Token>
): Provider
	assert(Universe.valid(universe), "Invalid universeId")
	local token: Auth.Token? = nil
	local refreshAt, expiresAt, epoch, version = 0, 0, session.epoch(), 0
	local flight: Flight? = nil
	local failure: Core.Result<Auth.Token>? = nil
	local retryAt = 0
	local closed = false
	--- Invalidate all scope material across identity replacement, logout, or destruction.
	local function synchronize()
		if epoch ~= session.epoch() then
			epoch = session.epoch()
			token, flight, failure = nil, nil, nil
			version += 1
		end
	end
	--- Bound each waiter independently while retaining a single exchange per universe/identity epoch.
	local function get(deadline: number?, signal: Core.Signal?): Core.Result<Auth.Token>
		synchronize()
		if closed then
			return Errors.make("Cancelled", "auth.exchangeScopedToken", 0, "Client is closed")
		end
		if flight and flight.done then
			flight = nil
		end
		if signal and signal.cancelled then
			return Errors.make("Cancelled", "auth.exchangeScopedToken", 0, "Call cancelled")
		end
		if deadline and runtime.now() >= deadline then
			return Errors.make("Timeout", "auth.exchangeScopedToken", 0, "Call deadline exceeded")
		end
		if not session.active() then
			return Errors.make("Unauthorized", "auth.exchangeScopedToken", 0, "Identity login required")
		end
		if token and runtime.now() < refreshAt then
			return { ok = true, value = token }
		end
		if failure and runtime.now() < retryAt then
			return failure
		end
		if not flight then
			local owned: Flight = { done = false, epoch = epoch }
			flight = owned
			runtime.spawn(function()
				-- Measure TTL from dispatch start so transport latency never extends credential life.
				local started = runtime.now()
				local ok, result = pcall(exchange)
				if not ok then
					result = Errors.make("Network", "auth.exchangeScopedToken", 0, "Exchange failed")
				end
				synchronize()
				if closed or owned.epoch ~= epoch or not session.active() then
					result =
						Errors.make("Cancelled", "auth.exchangeScopedToken", 0, "Identity session changed")
				elseif result.ok then
					local value = result.value
					if
						type(value) ~= "table"
						or type(value.accessToken) ~= "string"
						or value.accessToken == ""
						or value.tokenType ~= "Bearer"
						or type(value.expiresIn) ~= "number"
						or value.expiresIn % 1 ~= 0
						or value.expiresIn < 1
						or value.expiresIn > 3600
						or started + value.expiresIn <= runtime.now()
					then
						result = Errors.make(
							"Network",
							"auth.exchangeScopedToken",
							0,
							"Invalid scoped token response"
						)
					else
						token = Cache.freeze(value)
						expiresAt = started + value.expiresIn
						refreshAt = expiresAt - math.min(30, value.expiresIn * 0.1)
						version += 1
					end
				end
				if flight == owned then
					if not result.ok then
						token = nil -- Never fall back to stale or revoked authority after an exchange failure.
						failure, retryAt = result, runtime.now() + 1
					else
						failure = nil
					end
				end
				owned.result, owned.done = result, true
			end)
		end
		local pending = flight :: Flight
		while not pending.done do
			if closed or session.epoch() ~= pending.epoch or not session.active() then
				return Errors.make("Cancelled", "auth.exchangeScopedToken", 0, "Identity session changed")
			end
			if signal and signal.cancelled then
				return Errors.make("Cancelled", "auth.exchangeScopedToken", 0, "Call cancelled")
			end
			if deadline and runtime.now() >= deadline then
				return Errors.make("Timeout", "auth.exchangeScopedToken", 0, "Call deadline exceeded")
			end
			runtime.wait(0.01)
		end
		if flight == pending then
			flight = nil
		end
		if closed or session.epoch() ~= pending.epoch then
			return Errors.make("Cancelled", "auth.exchangeScopedToken", 0, "Identity session changed")
		end
		return pending.result :: Core.Result<Auth.Token>
	end
	return {
		kind = "scoped",
		universeId = universe,
		get = get,
		ready = get,
		invalidate = function(observed: number?)
			synchronize()
			-- A late failure must not evict a newer token installed by another caller.
			if observed == version then
				token = nil
				version += 1
			end
		end,
		destroy = function()
			closed = true
			token, flight, failure = nil, nil, nil
			version += 1
		end,
		version = function(): number
			synchronize()
			return version
		end,
		apply = function(headers: Core.Headers)
			synchronize()
			local current = token
			assert(
				current
					and type(current.accessToken) == "string"
					and not closed
					and session.active()
					and runtime.now() < expiresAt,
				"Scoped credential unavailable"
			)
			headers.Authorization = "Bearer " .. (current.accessToken :: string)
		end,
		onUnauthorized = function(observed: number?, deadline: number?, signal: Core.Signal?): boolean
			synchronize()
			if observed ~= version then
				return get(deadline, signal).ok
			end
			token = nil
			return get(deadline, signal).ok
		end,
	}
end
return table.freeze(ScopedTokens)
