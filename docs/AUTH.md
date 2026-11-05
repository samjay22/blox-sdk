# Authentication

## Service account keys (game servers)

Use `secretName` with `universeId`, optionally supplying deployment-known `levels` under case-sensitive catalog names: AuthService, DataService, MatchmakingService, PartyService, CodeService, AuditService, ConfigService, LeaderboardService, EconomyService. These are local preflight hints, not grants; the backend is always authoritative. A missing levels table means unknown grants, not full access. A present table without the called service causes a local denial.

Readable key format is exactly `bsa_[A-Za-z0-9_-]{8}_[A-Za-z0-9_-]{43}` (56 bytes), matching `ServiceAccountKeys.java`. The key is captured in a private provider closure. No login, refresh, JWT decoding, JSON serialization, or error formatting is performed on it.

Roblox `HttpService:GetSecret(name)` returns an opaque Secret. Its contents cannot be validated or read locally. The provider calls `secret:AddPrefix("Bearer ")` and preserves the returned Secret object in `RequestAsync.Headers.Authorization`. Never concatenate a Secret or call `tostring` on it. String keys are validated before provider construction.

Service-account management requires a **SUPER_ADMIN user token**, even when the key has AuthService ADMIN. The SDK rejects these calls locally with `requires super-admin user token`. Global admin endpoints likewise reject known machine identities. A service key's universe cannot be changed with `withUniverse` or a conflicting path/query/body universe field (including nested Audit/score batches). Backend checks still enforce resource ownership and nested/bulk scopes.

## Managed user sessions

Construct `BloxSDK.new({userSession={}})`, then call `client.auth:login({username=...,password=...})`. Successful login atomically installs access + refresh tokens. `client:logout()` uses the current refresh token and clears the local store; direct `client.auth:logout(req)` remains available as the raw route wrapper.

Before protected calls, an expiry within 30 seconds triggers refresh. A readable JWT payload's numeric `exp` is used for scheduling only; it is **not** signature verification or trusted role discovery. The login/refresh `expiresIn` value is the fallback.

A version counter distinguishes tokens used by in-flight calls. Concurrent 401s join one refresh; a late 401 from an old version replays using the already-rotated version. Each safe/idempotent original request gets at most one authorization replay; unkeyed mutations do not replay. A failed refresh is remembered for that version, preventing sequential storms. A new explicit login replaces the failed generation. Do not expect retries to recover a revoked refresh token.

A shared refresh owns its finite client timeout. Short-deadline/cancelled callers can stop waiting without invalidating other callers. Login/logout/destroy advance the generation; a stale refresh cannot resurrect cleared credentials. Public login/refresh/logout routes never recursively invoke the auth strategy or send existing Authorization headers.

### TokenStore

```luau
local store = {
    get = function(): {accessToken: string, refreshToken: string, expiresAt: number?}?
        return currentTokens
    end,
    set = function(tokens)
        currentTokens = tokens
    end,
}
local client = BloxSDK.new({userSession={store=store}})
```

The default store is private in-memory state. Custom stores must be synchronous, non-yielding, atomic, and non-throwing. If persistence is required, arrange secure storage outside the call path; do not put tokens in attributes, replicated objects, telemetry, or DataStore keys. Share a managed client rather than sharing one mutable TokenStore across independently refreshing clients.

Optional `userSession.role` is a caller-supplied preflight hint, never proof of privilege. Role and permission revocation is enforced server-side, not through unverified JWT payloads.

## Custom providers

Supply `authProvider={kind="custom", apply=function(headers) ... end, onUnauthorized=function() return false end}`. `apply` mutates headers without logging/serializing credentials. `onUnauthorized` returns whether one replay is appropriate. Built-in extensions accept optional observed-version, deadline, and signal arguments; custom Lua functions may ignore these. Optional `prepare`, `version`, `destroy`, scope, role, and levels support advanced providers.

Custom provider/store callbacks are trusted integration code: make synchronous phases non-yielding, callbacks non-throwing, and refresh bounded. Built-in auth is tested independently. `BloxSDK.Auth.serviceAccount`, `.userSession`, and `.memoryTokenStore` expose factories for advanced integrations; an independently constructed user session needs its `bind` refresh sender wired explicitly. Prefer the managed `userSession` config.

## Sensitive responses

Login, refresh, service-account create/rotate, and unmasked Roblox API-key responses may contain credentials. They are never cached or sent to hooks. Application code must not print or persist them accidentally. Error bodies and transport exceptions are completely redacted, including when a server reflects secrets. Generated DTO optional fields do not imply a response is safe to log.

Explicit null PATCH fields use `BloxSDK.null`; Lua `nil` means omission. `enabled=null` is rejected by both the schema and backend. An empty permissions list removes every grant and is encoded as `[]`.
