# Feature flags

For a master-switch-only cached read, use `client:runtimeSnapshot(30):isEnabled("double_xp")`.
Before first success or for an unknown flag this returns false. It does **not** apply player rollout rules.

For authoritative user rules, call `fields:evaluateFlags({userId=player.UserId, keys={"double_xp"}})`
or `evaluateFlagsBatch`. Read `result.value.values[key].value` only after result.ok. Values are JSON,
not necessarily booleans; a missing result must fail closed. Never let clients choose another user's ID.
Use the server's configuration tooling for createFlag/updateFlag/deleteFlag; respect version conflicts.
See [native script](../examples/server/flags.server.luau), [API types](api/fields.md).
