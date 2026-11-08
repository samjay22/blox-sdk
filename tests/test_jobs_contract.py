"""Independent offline checks for durable Fields administrative endpoint coverage."""
from __future__ import annotations

import json
import runpy
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
BASE = '/api/fields/universes/{universeId}'
# Deliberately independent of the generator/controller scanner: API_CONTRACT.md expectations.
EXPECTED = {
    ('POST', '/definitions/{id}/migrations/preview'),
    ('POST', '/definitions/{id}/migrations'),
    ('POST', '/migrations/{id}/cancel'),
    ('POST', '/migrations/{id}/rollback'),
    ('POST', '/bulk/preview'), ('POST', '/bulk'), ('POST', '/bulk/definitions'),
    ('GET', '/bulk/definitions/{id}'), ('POST', '/bulk/{id}/reverse'),
    ('POST', '/export'), ('POST', '/import'),
    ('GET', '/jobs'), ('GET', '/jobs/{id}'), ('GET', '/jobs/{id}/events'),
    ('GET', '/jobs/{id}/failures'), ('GET', '/jobs/{id}/failures/download'),
    ('GET', '/jobs/{id}/download'), ('POST', '/jobs/{id}/cancel'),
    ('POST', '/jobs/{id}/retry'),
    ('POST', '/schedules/preview'), ('POST', '/schedules'), ('GET', '/schedules'),
    ('GET', '/schedules/{id}'), ('GET', '/schedules/{id}/actions'),
    ('PUT', '/schedules/{id}'), ('POST', '/schedules/{id}/cancel'),
    ('POST', '/schedules/{id}/end-now'),
    ('GET', '/alerts/config'), ('PUT', '/alerts/config'), ('GET', '/alerts'),
    ('POST', '/alerts/{id}/ack'), ('POST', '/alerts/webhook/test'),
    ('GET', '/health/summary'),
}


class JobsContractTests(unittest.TestCase):
    """Prevent generated fixtures from concealing missing routes or authorization drift."""

    def setUp(self) -> None:
        """Read generated contracts and the independent coverage implementation."""
        self.doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        self.endpoints = self.doc['endpoints']
        self.routes = {(e['method'], e['path']): e for e in self.endpoints if e['service'] == 'fields'}
        self.checker = runpy.run_path(str(ROOT / 'tools/check-coverage'))

    def test_all_new_routes_and_authorization(self) -> None:
        """Every new endpoint is ADMIN, including reads/previews, except READ health summary."""
        self.assertEqual(len(EXPECTED), 33)
        inventory = json.loads((ROOT / 'routes.json').read_text())
        documented = (ROOT / 'docs/ENDPOINTS.md').read_text()
        for method, suffix in EXPECTED:
            with self.subTest(method=method, suffix=suffix):
                route = self.routes[(method, BASE + suffix)]
                self.assertEqual(route['minimumLevel'], 'READ' if suffix == '/health/summary' else 'ADMIN')
                self.assertEqual(route['statuses'], [200])
                self.assertEqual(sum(r['svc'] == 'fields' and r['method'] == method
                                     and r['path'] == BASE + suffix for r in inventory), 1)
                self.assertIn(BASE + suffix, documented)

    def test_coverage_detects_each_new_omission(self) -> None:
        """A missing route must fail even if its inventory entry was also removed."""
        actual = {(e['service'], e['method'], e['path']) for e in self.endpoints}
        verify = self.checker['assert_controller_coverage']
        verify(actual)
        for method, suffix in EXPECTED:
            with self.subTest(method=method, suffix=suffix), self.assertRaises(AssertionError):
                verify(actual - {('fields', method, BASE + suffix)})

    def test_mapping_arrays_fail_closed(self) -> None:
        """Expand both array aliases while rejecting constants, concatenation and mixed expressions."""
        parse = self.checker['mapping_paths']
        self.assertEqual(parse(''), [''])
        self.assertEqual(parse('"/one"'), ['/one'])
        self.assertEqual(parse('{"/jobs/{id}", "/schedules/{id}"}'),
                         ['/jobs/{id}', '/schedules/{id}'])
        self.assertEqual(parse('path = {"/a", "/b"}, produces="application/json"'), ['/a', '/b'])
        self.assertEqual(parse('value="/import", consumes={"application/x-ndjson","text/plain"}'), ['/import'])
        for value in ('PATH', '{PATH}', '{"/a", PATH}', '{}', '"/a" + PATH',
                      '{"/a" + PATH}', '{"/a",}', 'value={"/a", PATH}, produces="text/plain"'):
            with self.subTest(value=value), self.assertRaises(AssertionError):
                parse(value)

    def test_ndjson_and_retry_metadata(self) -> None:
        """Uploads stay raw NDJSON with explicit header keys; downloads never JSON-decode the stream."""
        upload = self.routes[('POST', BASE + '/import')]
        self.assertEqual(upload['bodyType'], 'String')
        self.assertEqual(upload['requestFormat'], 'ndjson')
        self.assertTrue(upload['idempotencyHeader'])
        self.assertTrue(upload['optionalKey'])
        self.assertFalse(upload.get('idempotencyField'))
        self.assertEqual(upload['responseJava'], 'ImportValidation|JobReceipt')
        self.assertEqual({p['name'] for p in upload['queryParams']}, {'dryRun', 'reason'})
        for suffix in ('/jobs/{id}/download', '/jobs/{id}/failures/download'):
            route = self.routes[('GET', BASE + suffix)]
            self.assertEqual(route['responseFormat'], 'text')
            self.assertEqual(route['responseJava'], 'String')
        self.assertIn(410, self.routes[('GET', BASE + '/jobs/{id}/download')]['errorStatuses'])
        for method, suffix in EXPECTED:
            route = self.routes[(method, BASE + suffix)]
            self.assertFalse(route['cacheable'], (method, suffix))
        for suffix in ('/bulk', '/export', '/definitions/{id}/migrations',
                       '/migrations/{id}/rollback', '/bulk/{id}/reverse', '/schedules'):
            route = self.routes[('POST', BASE + suffix)]
            self.assertEqual(route['idempotencyField'], 'idempotencyKey')
            self.assertTrue(route['retryable'])

    def test_safe_operational_response_dtos(self) -> None:
        """Health and receipts expose typed progress, not uploaded values or webhook credentials."""
        types = self.doc['types']['fields']
        self.assertEqual(set(types['HealthSummary']['fields']),
                         {'openAlerts', 'runningJobs', 'upcomingSchedules'})
        self.assertEqual(set(types['OpenAlertCounts']['fields']), {'WARNING', 'CRITICAL'})
        self.assertEqual(set(types['JobState']['enum']),
                         {'QUEUED', 'RUNNING', 'SUCCEEDED', 'CANCELLED', 'FAILED'})
        self.assertEqual(set(types['JobReceipt']['fields']),
                         {'id', 'kind', 'state', 'total', 'succeeded', 'failed', 'prepared',
                          'cancelRequested', 'attempts', 'updatedAt', 'error', 'phase', 'snapshotId', 'recurrence'})
        self.assertNotIn('webhook', types['AlertConfigResponse']['fields'])
        self.assertIn('webhookConfigured', types['AlertConfigResponse']['fields'])
        self.assertEqual(types['BulkInput']['fields']['ops']['java'], 'List<Fields.PlayerOperation>')
        self.assertEqual(types['BulkInput']['fields']['target']['java'], 'Fields.BulkTarget')


if __name__ == '__main__':
    unittest.main()
