--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
local Types = require(script.Parent.Parent.Types.Core)
local Options = {}
local known = table.freeze({
	deadline = true,
	timeout = true,
	idempotencyKey = true,
	priority = true,
	retry = true,
	cacheTtl = true,
	signal = true,
})
--- Validate user options before arithmetic or yielding; malformed values become Local results.
function Options.valid(opts: Types.CallOptions): boolean
	if type(opts) ~= "table" then
		return false
	end
	for name in opts :: any do
		if not known[name] then
			return false
		end
	end
	if
		opts.timeout ~= nil
		and (
			type(opts.timeout) ~= "number"
			or opts.timeout ~= opts.timeout
			or opts.timeout < 0.01
			or opts.timeout > 300
		)
	then
		return false
	end
	if
		opts.idempotencyKey ~= nil
		and (type(opts.idempotencyKey) ~= "string" or #opts.idempotencyKey == 0 or #opts.idempotencyKey > 800)
	then
		return false
	end
	if opts.priority ~= nil and opts.priority ~= "critical" and opts.priority ~= "bulk" then
		return false
	end
	if
		opts.retry ~= nil
		and (type(opts.retry) ~= "number" or opts.retry % 1 ~= 0 or opts.retry < 0 or opts.retry > 10)
	then
		return false
	end
	if
		opts.deadline ~= nil
		and (
			type(opts.deadline) ~= "number"
			or opts.deadline ~= opts.deadline
			or math.abs(opts.deadline) == math.huge
		)
	then
		return false
	end
	if
		opts.cacheTtl ~= nil
		and (
			type(opts.cacheTtl) ~= "number"
			or opts.cacheTtl ~= opts.cacheTtl
			or opts.cacheTtl < 0
			or opts.cacheTtl > 3600
		)
	then
		return false
	end
	if opts.signal ~= nil and (type(opts.signal) ~= "table" or type(opts.signal.cancelled) ~= "boolean") then
		return false
	end
	return true
end
return table.freeze(Options)
