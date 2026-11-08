# Audit

`client.audit:append` / appendBatch write typed events; listPages reads cursor history. Supply an ISO UTC
occurredAt and server-derived actor/resource identity. Omitted idemKey is generated once per logical call.
Persist a supplied key for replay across calls. Retention limits deduplication; audit is not a financial ledger.

Prefer `client:auditWriter({batchSize=25})` for nonblocking gameplay telemetry. enqueue returns false for
closed/invalid/full queues; true means queued, **not delivered**. Inspect pending(), lastError and metrics.
Flushes serialize and batches are at most 500. Native BindToClose integration drains owned writers;
shutdown has a finite budget and cannot guarantee delivery during process loss. Never put secrets or
unnecessary personal data in event metadata. See [API](api/audit.md), [helper API](api/helpers.md),
[native example](../examples/server/audit.server.luau).
