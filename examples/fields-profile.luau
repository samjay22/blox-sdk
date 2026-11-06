--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
local Profile = require("../src/Fields/Profile")
--- Load the document, acquire presence, and commit a trusted reward before returning the profile.
return function(
	client: SDK.Client,
	universeId: number,
	userId: number,
	placeId: number
): Core.Result<Profile.Profile>
	local loaded = client.fields:LoadProfile(universeId, userId)
	if not loaded.ok then
		return loaded
	end
	local profile = loaded.value
	local presence = profile:StartPresence(placeId)
	if not presence.ok then
		profile:Destroy()
		return presence
	end
	local result = profile:Transaction():Add("Currency.Gems", 10):Reason("Quest completion"):Commit()
	if not result.ok then
		return result
	end
	-- Generated Typed.Currency.Gems:Get(profile) gives number; plain Get is wire-shaped Core.Json.
	return loaded
end
