--!strict
local SDK = require("../src/BloxSDK")
--- Submit once; automatic retries reuse a generated submissionId. Persist your own ID for cross-call replay.
return function(client: SDK.Client, userId: number, score: number)
	local submitted =
		client.leaderboards:submit({ path = { name = "wins" }, body = { userId = userId, score = score } })
	local pages = client.leaderboards:topPages({ path = { name = "wins" }, query = { limit = 50 } })
	-- Call pages() to fetch each page; nil ends iteration, a failed Result terminates with an error.
	-- Ratings share this facade: ratingMatch, ratingUser, ratingUsers, ratingTopPages, ratingConfig.
	return submitted, pages
end
