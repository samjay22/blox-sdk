--!strict
local Types = require("../Types/Core")
local Session = {}
local Errors = require("../Core/Errors")
export type Tokens = { accessToken: string, refreshToken: string, expiresAt: number? }
export type TokenStore = { get: () -> Tokens?, set: (Tokens?) -> () }
export type Session = Types.AuthProvider & {
	accept: (unknown) -> boolean,
	clear: () -> (),
	logout: () -> Types.Result<any>,
	bind: ((string, unknown) -> Types.Result<any>) -> (),
}
--- Make a private in-memory store; persistence is a caller-supplied security decision.
function Session.memoryStore(): TokenStore
	local tokens: Tokens? = nil
	return {
		get = function(): Tokens?
			return tokens
		end,
		set = function(value: Tokens?)
			tokens = value
		end,
	}
end
--- Read only the numeric exp claim. This is scheduling, never signature/role verification.
function Session.exp(token: string): number?
	local payload = string.match(token, "^[^.]+%.([A-Za-z0-9_-]+)%.[^.]*$")
	if not payload or #payload > 16384 then
		return nil
	end
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
	local bytes: { string } = table.create(math.floor(#payload * 3 / 4))
	local acc, bits = 0, 0
	for i = 1, #payload do
		local index = string.find(alphabet, string.sub(payload, i, i), 1, true)
		if not index then
			return nil
		end
		acc = acc * 64 + index - 1
		bits += 6
		if bits >= 8 then
			bits -= 8
			bytes[#bytes + 1] = string.char(math.floor(acc / 2 ^ bits))
			acc %= 2 ^ bits
		end
	end
	return tonumber(string.match(table.concat(bytes), '"exp"%s*:%s*(%d+)'))
end
--- Build a versioned, single-flight session. One refresh/replay per original authorization epoch.
function Session.new(runtime: Types.Runtime, store: TokenStore?, role: string?): Session
	local tokenStore = store or Session.memoryStore()
	local version, busy, failedVersion = 0, false, -1
	local sender: ((string, unknown) -> Types.Result<any>)? = nil
	local closed = false
	local provider: Session
	--- Atomically replace a complete token pair; do not partially rotate refresh credentials.
	local function accept(value: unknown): boolean
		if type(value) ~= "table" then
			return false
		end
		local body = value :: { [string]: unknown }
		if
			type(body.accessToken) ~= "string"
			or type(body.refreshToken) ~= "string"
			or body.accessToken == ""
			or body.refreshToken == ""
		then
			return false
		end
		local expiresAt = Session.exp(body.accessToken)
		if not expiresAt and type(body.expiresIn) == "number" then
			expiresAt = runtime.unix() + body.expiresIn
		end
		tokenStore.set({
			accessToken = body.accessToken,
			refreshToken = body.refreshToken,
			expiresAt = expiresAt,
		})
		version += 1
		failedVersion = -1
		return true
	end
	--- Join the current refresh or perform the only refresh for this token generation.
	local function refresh(observed: number?, deadline: number?, signal: Types.Signal?): boolean
		local expected = observed or version
		if closed then
			return false
		end
		if expected ~= version then
			return tokenStore.get() ~= nil
		end
		if failedVersion == version then
			return false
		end
		local send = sender
		local current = tokenStore.get()
		if not send or not current then
			return false
		end
		if not busy then
			busy = true
			-- The shared refresh owns its own deadline. Each caller may stop waiting independently.
			runtime.spawn(function()
				local result = send("refresh", { refreshToken = current.refreshToken })
				local success = not closed and expected == version and result.ok and accept(result.value)
				if not success and expected == version then
					failedVersion = version
				end
				busy = false
			end)
		end
		while busy and not closed do
			if (signal and signal.cancelled) or (deadline and runtime.now() >= deadline) then
				return false
			end
			runtime.wait(0.01)
		end
		return not closed and version ~= expected and tokenStore.get() ~= nil
	end
	provider = {
		kind = "user",
		role = role,
		accept = accept,
		onUnauthorized = refresh,
		version = function(): number
			return version
		end,
		bind = function(send: (string, unknown) -> Types.Result<any>)
			sender = send
		end,
		logout = function(): Types.Result<any>
			local current = tokenStore.get()
			version += 1
			tokenStore.set(nil)
			local send = sender
			if not current or not send then
				return Errors.make("Local", "auth.logout", 0, "No active user session")
			end
			return send("logout", { refreshToken = current.refreshToken })
		end,
		clear = function()
			version += 1
			tokenStore.set(nil)
		end,
		destroy = function()
			closed = true
			version += 1
			tokenStore.set(nil)
			sender = nil
		end,
		prepare = function(deadline: number?, signal: Types.Signal?)
			local current = tokenStore.get()
			if current and current.expiresAt and current.expiresAt - runtime.unix() <= 30 then
				refresh(version, deadline, signal)
			end
		end,
		apply = function(headers: Types.Headers)
			local current = tokenStore.get()
			if current then
				headers.Authorization = "Bearer " .. current.accessToken
			end
		end,
	}
	return provider
end
return table.freeze(Session)
