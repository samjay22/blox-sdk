--!strict
-- Set this Script's Enabled attribute to true after provisioning the documented fixtures.
if script:GetAttribute("Enabled") ~= true then
	return
end
local client = require(script.Parent.Client)
local scopes = client.leaderboards:ratingScopes({ query = { limit = 10 } })
if not scopes.ok then
	warn(scopes.error.code)
end
-- Submit ratingMatch only from your trusted match-completion handler, with a persisted matchId.
