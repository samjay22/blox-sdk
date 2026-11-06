# BloxSDK changelog

## Unreleased — Wave 2 platform

- Add PlatformService methods for metering, plans, rate limits, webhooks, environments, LiveOps, analytics, flags and developer tools.
- Add player administration overview, indexed search, compensating reverts and privacy export/erase.
- Platform calls use the shared scoped-token, validation, retry and routing pipeline. Unkeyed mutations are not automatically retried.
- Breaking change: erasure requires a JSON body containing reason and confirmUserId; the confirmation must match the player path.

This entry documents local implementation, not a published SDK release.
