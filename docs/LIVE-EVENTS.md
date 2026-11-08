# Live events

Live events compose Fields UNIVERSE configuration, flags, schedules and rotations; there is no fabricated
LiveEvents service. Publish an event definition on the backend, use a `live_event` rotation for its
current instance, and a feature flag for authoritative player eligibility.

Start one runtimeSnapshot per universe and `fields:rotations(id):watch("live_event", callback)`.
Use the instance's pinned result and endsAt; countdowns are display-only, not authority to grant rewards
or promote the next head. Disconnect on unload. Use keyed transactions for one-time event rewards.
Schedule publishing and administrative state changes remain operator work, not an in-game timer loop.
See [native event script](../examples/server/live-events.server.luau), [rotations](ROTATIONS.md), [jobs/schedules](JOBS.md).
