# Leaderboards and ratings

Both live on `client.leaderboards`. Provision a board with trusted administration, then call
`submit({path={name="wins"},body={userId=player.UserId,score=score}}, {idempotencyKey=persistedIntent})`.
The option maps to wire submissionId. Never reuse an intent for a different score. Batch submission
needs one key per item; a single common key option is rejected for batch operations.

Use topPages/listPages/periodsPages for bounded lazy cursor iteration. Every yielded page is a Result;
stop on error rather than treating an incomplete list as success. around reads a player's neighborhood.
Fields stored-int board bindings can submit authoritative scores transactionally; do not double-submit.

Ratings use ratingScopes, ratingConfig, ratingUser, ratingTopPages and ratingMatch. Match results must
come from a trusted completed match, with one persisted matchId for replay. The backend computes ratings;
never accept a rating delta from a client. See [API](api/leaderboards.md), [native leaderboard](../examples/server/leaderboard.server.luau)
and [ratings](../examples/server/ratings.server.luau).
