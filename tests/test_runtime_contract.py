"""Independent expectations for the source-audited runtime and control-plane additions."""
from __future__ import annotations

import json
import runpy
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))

# Literal acceptance inventory, not generated from the SDK spec under test.
NEW_METHODS = {
    'auth.assignOwner', 'auth.createMember', 'auth.lookupServiceAccount',
    'fields.createFlag', 'fields.deleteFlag', 'fields.evaluateFlags', 'fields.evaluateFlagsBatch',
    'fields.flag', 'fields.flags', 'fields.gameValueHistory', 'fields.maintenance',
    'fields.putMaintenance', 'fields.rollbackGameValue', 'fields.runtimeSnapshot',
    'fields.scheduleDefinition', 'fields.scheduleRuns', 'fields.updateFlag',
    'leaderboards.ratingLabel', 'leaderboards.ratingScopes',
    'platform.createPlan', 'platform.deletePlan', 'platform.incidents', 'platform.info',
    'platform.liveness', 'platform.metrics', 'platform.readiness',
    'platform.resetKeyRateLimit', 'platform.resetRateLimits', 'platform.updatePlan',
    'codes.liveness', 'codes.readiness',
}


class RuntimeContractTests(unittest.TestCase):
    """Prevent generated fixtures from blessing the same extraction mistake twice."""

    def setUp(self) -> None:
        """Load checked-in artifacts without backend startup or network access."""
        self.doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        self.routes = {e['id']: e for e in self.doc['endpoints']}
        self.types = self.doc['types']

    def test_new_method_wire_goldens_are_complete(self) -> None:
        """Every added method must have a non-generated, explicit request/response wire vector."""
        vectors = json.loads((ROOT / 'tests/vectors/service-contracts.json').read_text())
        ids = {v['endpoint'] for v in vectors}
        self.assertTrue(NEW_METHODS <= ids)
        self.assertTrue(NEW_METHODS <= self.routes.keys())
        for vector in vectors:
            with self.subTest(endpoint=vector['endpoint']):
                self.assertEqual(vector['method'], self.routes[vector['endpoint']]['method'])
                self.assertIn(vector['status'], self.routes[vector['endpoint']]['statuses'])
                self.assertTrue(vector['url'].startswith('https://lb1.blox-api.com/'))

    def test_retired_and_speculative_surfaces_are_absent(self) -> None:
        """No Config compatibility layer, speculative Platform API APIs is exposed."""
        self.assertNotIn('config', self.types)
        for endpoint in self.routes.values():
            self.assertNotEqual(endpoint['service'], 'config')
        for name in ('snapshotEnvironment', 'promoteEnvironment', 'rollbackEnvironment',
                     'liveEvents', 'createLiveEvent', 'evaluateFlags', 'recordExposure'):
            self.assertNotIn('platform.' + name, self.routes)
        self.assertNotIn('matchmaking.environmentResources', self.routes)
        for tree in ('src', 'roblox'):
            self.assertFalse((ROOT / tree / 'Services/Config.luau').exists())
            self.assertFalse((ROOT / tree / 'Types/Config.luau').exists())
        coverage = (ROOT / 'SDK_COVERAGE.md').read_text()
        self.assertNotIn('TODO: Fields generic Rotations', coverage)
        self.assertIn('fields:activeRotation', coverage)
        self.assertIn('current Party controller/DTO parity is unverified', coverage)

    def test_nullable_records_do_not_weaken_request_contracts(self) -> None:
        """Response nulls survive decoding, while equivalent malformed requests remain invalid."""
        fields = self.types['fields']
        self.assertEqual(self.routes['fields.scheduleDefinition']['responseJava'], 'ScheduleDefinition')
        for name in ('universeId', 'end', 'endActions', 'idempotencyKey', 'recurrence'):
            self.assertTrue(fields['ScheduleDefinition']['fields'][name]['nullable'])
            self.assertFalse(fields['ScheduleInput']['fields'][name].get('nullable', False))
        for name in ('universeId', 'displayName'):
            self.assertTrue(self.types['auth']['MemberDetail']['fields'][name]['nullable'])
        for name in ('MemberDetail', 'CreatedMember'):
            self.assertTrue(all(f['required'] for f in self.types['auth'][name]['fields'].values()))
        self.assertTrue(all(f['required'] for f in fields['EnvironmentReplaceInput']['fields'].values()))

    def test_explicit_paths_levels_and_retry_safety(self) -> None:
        """Assert easily confused paths and permissions directly from reviewed source contracts."""
        for endpoint, suffix, level in (
            ('fields.runtimeSnapshot', '/runtime/snapshot', 'READ'),
            ('fields.scheduleRuns', '/schedules/{id}/runs', 'READ'),
            ('fields.scheduleDefinition', '/schedules/{id}/definition', 'ADMIN'),
            ('fields.putMaintenance', '/maintenance', 'ADMIN'),
        ):
            route = self.routes[endpoint]
            self.assertEqual(route['path'], '/api/fields/universes/{universeId}' + suffix)
            self.assertEqual(route['minimumLevel'], level)
        snapshot = self.routes['fields.runtimeSnapshot']
        self.assertEqual(snapshot['statuses'], [200, 304])
        self.assertTrue(snapshot['conditional'])
        self.assertFalse(snapshot['cacheable'])
        for endpoint in NEW_METHODS:
            if self.routes[endpoint]['method'] != 'GET':
                self.assertFalse(self.routes[endpoint]['retryable'])
        self.assertEqual(self.routes['auth.lookupServiceAccount']['authKinds'], ['serviceAccount'])
        self.assertTrue(self.routes['auth.rotateServiceAccount']['bodyRequired'])

    def test_coverage_rejects_speculative_domain_routes(self) -> None:
        """Coverage fails for fabricated routes as well as missing controller routes."""
        checker = runpy.run_path(str(ROOT / 'tools/check-coverage'))
        actual = {(e['service'], e['method'], e['path']) for e in self.routes.values()}
        with self.assertRaises(AssertionError):
            checker['assert_controller_coverage'](actual | {('platform', 'POST', '/api/liveops/events')})
        for name in NEW_METHODS:
            route = self.routes[name]
            with self.subTest(endpoint=name), self.assertRaises(AssertionError):
                checker['assert_controller_coverage'](actual - {(route['service'], route['method'], route['path'])})


if __name__ == '__main__':
    unittest.main()
