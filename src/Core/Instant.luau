--!strict
local Control = require("../Fields/Control")
local Instant = {}
--- Convert a validated UTC ISO instant to Unix seconds without platform-specific date APIs.
function Instant.unix(value: string): number?
	if not Control.instant(value) then
		return nil
	end
	local y, m, d, h, n, s, fraction = string.match(value, "^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)(.*)$")
	local year, month = tonumber(y) :: number, tonumber(m) :: number
	-- Gregorian civil-date decomposition handles leap centuries and pre-epoch timestamps.
	year -= if month <= 2 then 1 else 0
	local era = math.floor(year / 400)
	local yearOfEra = year - era * 400
	local dayOfYear = math.floor((153 * (month + (if month > 2 then -3 else 9)) + 2) / 5)
		+ (tonumber(d) :: number)
		- 1
	local days = era * 146097
		+ yearOfEra * 365
		+ math.floor(yearOfEra / 4)
		- math.floor(yearOfEra / 100)
		+ dayOfYear
		- 719468
	local decimal = if fraction == "Z" then 0 else tonumber("0" .. string.sub(fraction :: string, 1, -2)) or 0
	return days * 86400
		+ (tonumber(h) :: number) * 3600
		+ (tonumber(n) :: number) * 60
		+ (tonumber(s) :: number)
		+ decimal
end
return table.freeze(Instant)
