--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Errors = {}
local statusKinds: { [number]: Types.ErrorKind } = {
	[400] = "Validation",
	[401] = "Unauthorized",
	[403] = "Forbidden",
	[404] = "NotFound",
	[409] = "Conflict",
	[422] = "Validation",
	[429] = "RateLimited",
	[408] = "Timeout",
}
table.freeze(statusKinds)
--- Create a safe error without copying backend text, URLs, headers or payloads.
function Errors.make(
	kind: Types.ErrorKind,
	endpoint: string,
	attempts: number,
	message: string,
	status: number?
): Types.Result<any>
	return {
		ok = false,
		error = {
			kind = kind,
			endpoint = endpoint,
			attempts = attempts,
			message = message,
			status = status,
			body = if status then "[redacted]" else nil,
		},
	}
end
--- Map wire status to the stable public error taxonomy.
function Errors.http(status: number, endpoint: string, attempts: number): Types.Result<any>
	local kind: Types.ErrorKind = statusKinds[status] or (if status >= 500 then "Server" else "Validation")
	return Errors.make(kind, endpoint, attempts, "HTTP request failed", status)
end
return table.freeze(Errors)
