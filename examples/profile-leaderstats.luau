--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Profile = require("../src/Fields/Profile")
--- Mirror a field into a caller-owned leaderstat; release the returned profile when finished.
return function(client: SDK.Client, userId: number, gemsStat: { Value: number }): Core.Result<Profile.Profile>
	local loaded = client.fields:loadProfile(userId)
	if not loaded.ok then
		return loaded
	end
	local profile = loaded.value
	local current = profile:get("Currency.Gems")
	if type(current) == "number" then
		gemsStat.Value = current
	end
	profile.Changed:connect(function(change)
		local gems = change.values["Currency.Gems"]
		if type(gems) == "number" then
			-- Both acknowledged local awards and external admin edits update the stat.
			gemsStat.Value = gems
		end
	end)
	return loaded
end
