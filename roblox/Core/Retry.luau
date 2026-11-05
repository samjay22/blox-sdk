--!strict
-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.
--!native
--!optimize 2
local Retry = {}
--- Full jitter in [0, min(cap, base*2^(attempt-1))].
function Retry.backoff(attempt: number, random: number, base: number, cap: number): number
	return math.clamp(random, 0, 1) * math.min(cap, base * 2 ^ math.min(attempt - 1, 30))
end
--- Parse delta seconds or RFC7231 IMF-fixdate without locale/platform dependencies.
function Retry.after(value: string?, unix: number): number?
	if not value then
		return nil
	end
	local seconds = tonumber(value)
	if seconds and seconds >= 0 and seconds < math.huge then
		return seconds
	end
	local day, month, year, hour, minute, second =
		string.match(value, "^%a%a%a, (%d%d) (%a%a%a) (%d%d%d%d) (%d%d):(%d%d):(%d%d) GMT$")
	if not day then
		return nil
	end
	local months = {
		Jan = 1,
		Feb = 2,
		Mar = 3,
		Apr = 4,
		May = 5,
		Jun = 6,
		Jul = 7,
		Aug = 8,
		Sep = 9,
		Oct = 10,
		Nov = 11,
		Dec = 12,
	}
	local m = months[month]
	if not m then
		return nil
	end
	local y = tonumber(year) :: number
	y -= if m <= 2 then 1 else 0
	local era = math.floor(y / 400)
	local yo = y - era * 400
	local doy = math.floor((153 * (m + (if m > 2 then -3 else 9)) + 2) / 5) + (tonumber(day) :: number) - 1
	local days = era * 146097 + yo * 365 + math.floor(yo / 4) - math.floor(yo / 100) + doy - 719468
	return math.max(
		0,
		days * 86400
			+ (tonumber(hour) :: number) * 3600
			+ (tonumber(minute) :: number) * 60
			+ (tonumber(second) :: number)
			- unix
	)
end
return table.freeze(Retry)
