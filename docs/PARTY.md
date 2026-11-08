# Party

`client.party` supports createParty, getAllParties/getParty, membership/leadership changes and getUpdates.
Derive owner/requester/user IDs from authenticated server context. Recheck authorization on every action;
SDK hints are not grants. Unkeyed creates/mutations are not automatically retried after ambiguous failure.

Use a stable serverId for getUpdates, poll at bounded cadence, deduplicate updates, and cancel on shutdown.
Polling is non-destructive and updates may be repeated. Apply effects idempotently. Do not spin at frame rate.
See [portable lifecycle example](../examples/party.luau), [native read script](../examples/server/party.server.luau),
[typed API](api/party.md). Current sibling Party source parity remains unverified; mocks are not deployment proof.
