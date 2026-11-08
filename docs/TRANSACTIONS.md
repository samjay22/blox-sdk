# Transactions, products and purchases

Load a schema cache or `fields:loadProfile(universeId, userId)` first. Transactions are built with
`fields:transactionBuilder(...)` or `profile:transaction()`. Chain `set`, `add`, `expect`, `reason`,
`key`, then `commit`. Every write is validated; no automatic schema fetch hides an invalid transaction.
`validateLocal()` checks a complete transaction locally; `validate()` is the backend operation-only dry run.

Use `expect(field, {version=profile.versions[field]})` to prevent lost concurrent updates.
Generate/persist one key per logical intent and reuse it after uncertainty. A new key means a new operation.
Never trust player IDs, prices, grant operations, or quantities supplied by a RemoteEvent.

Developer-product grants belong in Fields product definitions. In the experience's single
`MarketplaceService.ProcessReceipt` handler, call `fields:processReceipt` with PurchaseId, PlayerId,
ProductId and CurrencySpent from Roblox. Return PurchaseGranted **only** on result.ok; otherwise
NotProcessedYet. The purchaseId is the durable deduplication boundary. Do not regrant the response.
See [native purchases script](../examples/server/purchases.server.luau), [Fields](FIELDS.md),
and [wire/API types](api/fields.md). Refund/reversal and product administration require server-side authorization.
