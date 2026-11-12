# Live events

Live events compose `client.configs` namespaces, Fields flags, schedules and rotations; there is no fabricated
LiveEvents service. Publish an event definition on the backend, use a `live_event` rotation for the
active event, and a feature flag for authoritative player eligibility.

Call `fields:rotations():watch("live_event", callback)`. The callback receives the active items and `endsAt`;
countdowns are display-only, not authority to grant rewards. Disconnect on unload. Use keyed transactions for one-time event rewards.
Schedule publishing and administrative state changes remain operator work, not an in-game timer loop.
See [native event script](../examples/server/live-events.server.luau), [rotations](ROTATIONS.md), [jobs/schedules](JOBS.md).
