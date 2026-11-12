--!strict
local SDK = require("../src/BloxSDK")
local Core = require("../src/Types/Core")
--- Redeem a code a player typed. One call, one outcome: nothing to decode, nothing to retry by hand.
return function(client: SDK.Client, user: Core.User, text: string): string
	local outcome = client.codes:redeem(user, text)
	if outcome.status == "granted" then
		return `Redeemed! You received {#outcome.rewards} reward(s).`
	elseif outcome.status == "already_redeemed" then
		return "You already redeemed this code."
	elseif outcome.status == "expired" then
		return "This code has expired."
	elseif outcome.status == "not_started" then
		return "This code is not active yet."
	elseif outcome.status == "exhausted" then
		return "This code has been fully claimed."
	elseif outcome.status == "retry" then
		return "Redemption is busy. Please try again in a moment." -- Safe to call again; never double-grants.
	elseif outcome.status == "failed" then
		warn("code redemption failed", outcome.error.code)
		return "Something went wrong redeeming that code."
	end
	return "That code is not valid."
end
