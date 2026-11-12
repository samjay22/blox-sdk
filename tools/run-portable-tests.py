#!/usr/bin/env python3
"""Run the Python regression suite without the tests that need private backend source checkouts."""
from __future__ import annotations
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# These refresh or cross-check the contract against the backend services' source (BLOX_SOURCE_ROOT/srv and
# svc), which only exists on a developer machine. ./tools/verify still runs them; CI without those
# checkouts cannot.
NEEDS_BACKEND_SOURCE = {
    'test_consumer_types.ConsumerTypesTests.test_postman_award_grammar',
    'test_contract.ContractTests.test_live_source_contract_is_reproducible',
    'test_contract.ContractTests.test_coverage_detects_omission_without_inventory_help',
    'test_platform_contract.PlatformContractTests.test_overlay_is_replayable',
    'test_profile_sync_contract.ProfileSyncContractTests.test_source_refresh_keeps_public_contract_and_legacy_batch',
    'test_auth_contract.AuthContractTests.test_rotation_refresh_curation',
    'test_jobs_contract.JobsContractTests.test_coverage_detects_each_new_omission',
}


def flatten(suite: unittest.TestSuite):
    """Yield every individual test case in a possibly nested suite."""
    for item in suite:
        if isinstance(item, unittest.TestSuite):
            yield from flatten(item)
        else:
            yield item


def main() -> None:
    """Discover tests under tests/, drop the backend-dependent ones, and exit non-zero on any failure."""
    discovered = list(flatten(unittest.defaultTestLoader.discover(str(ROOT / 'tests'), pattern='test_*.py')))
    stale = NEEDS_BACKEND_SOURCE - {test.id() for test in discovered}
    if stale:
        raise SystemExit('Skip list names tests that no longer exist: ' + ', '.join(sorted(stale)))
    selected = [test for test in discovered if test.id() not in NEEDS_BACKEND_SOURCE]
    print(f'Running {len(selected)} Python tests; skipping {len(NEEDS_BACKEND_SOURCE)} that need backend source')
    result = unittest.TextTestRunner(verbosity=1).run(unittest.TestSuite(selected))
    sys.exit(0 if result.wasSuccessful() else 1)


if __name__ == '__main__':
    main()
