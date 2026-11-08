# Opt-in real-gateway smoke test

Run `lune run tools/live-smoke.luau -- --yes-live`. All four environment variables are required:
BLOX_BASE_URL (HTTPS origin, no path), BLOX_API_KEY (service-account key), BLOX_UNIVERSE_ID,
BLOX_PLAYER_ID (positive exact integers). Load credentials privately from your environment; never paste
keys into command arguments, source files or logs. Without explicit --yes-live it refuses before sending HTTP.
The adapter uses Lune 0.8.9 `@lune/net.request`, not Roblox APIs or shell HTTP clients.

**Use a disposable test universe/player.** Provide gateway and downstream read/write grants. Auth and
Platform are health reads because management routes require an identity, not a game service key.
It checks every facade, additional domain reads, a same-value optimistic field transaction, a score-zero
leaderboard submission, rotation get/watch-once, and generator preview. Failures print fixed labels and
the SDK's safe machine error code, never raw payloads/exceptions/environment values. Party, Audit and
Platform **health reads only** report SKIP with a scope/identity reason on HTTP 401/403; network errors,
5xx responses, and authorization failures for other checks remain FAIL. A skipped health check does not
establish service health. Exit 0 means all non-skipped checks passed, 1 means a check failed, and 2 means
refusal/preflight failure. The Lune adapter normalizes repeated response-header arrays to strings.

Provision these fixtures first (the runner never creates definitions):

| Optional variable | Default | Requirement |
|---|---|---|
| BLOX_FIELD_ID | Smoke.Counter | Active, stored PLAYER field present in the document; write permitted |
| BLOX_BOARD | sdk_smoke | Dedicated test leaderboard; score 0 must be legal |
| BLOX_ROTATION | weather | Enabled rotation with a current instance |
| BLOX_GENERATOR | card_pack | Valid generator accepting read-only preview |
| BLOX_CODE | absent | Only when supplied: redeem this test code for BLOX_PLAYER_ID |

The field transaction records history/sequence even though its value is unchanged; version conditions
prevent overwriting concurrent changes. The leaderboard write can change that test player's score.
Code redemption can grant configured rewards. No generator roll, rotation claim, billing, purchase,
definition creation, or cleanup/delete is attempted. Nothing here certifies production backend parity.
The full offline gate checks refusals and mock behavior; it does not run against a real gateway.
