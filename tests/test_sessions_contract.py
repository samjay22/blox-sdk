"""Independent assertions for the binding SDK 3.0 session wire contract."""
from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from sessions_contract import curate


class SessionsContractTests(unittest.TestCase):
    """Protect public lease/commit DTOs from source extraction and internal-record collisions."""

    def setUp(self) -> None:
        """Read the checked-in contract without requiring sibling services to be stationary."""
        self.doc = json.loads((ROOT / 'spec/endpoints.json').read_text())

    def test_exact_routes_and_access(self) -> None:
        """Only the four binding routes use the session coordinator's wire DTOs."""
        endpoints = {endpoint['id']: endpoint for endpoint in self.doc['endpoints']}
        for name, suffix in (
            ('acquireSessions', 'sessions/acquire'), ('renewSessions', 'sessions/renew'),
            ('releaseSessions', 'sessions/release'), ('commitSession', 'commits'),
        ):
            endpoint = endpoints['fields.' + name]
            self.assertEqual((endpoint['method'], endpoint['path'], endpoint['minimumLevel']),
                             ('POST', '/api/fields/universes/{universeId}/' + suffix, 'READ_WRITE'))
            self.assertIn('serviceAccount', endpoint['authKinds'])
            self.assertFalse(endpoint['cacheable'] or endpoint['retryable'])

    def test_exact_envelopes_and_snapshot_fields(self) -> None:
        """Do not add transaction-only metadata, rename fields to data, or expose server internals."""
        types = self.doc['types']['fields']
        for name, fields in {
            'AcquireInput': {'serverId', 'ttlMs', 'players'},
            'ReleaseInput': {'serverId', 'leases'},
            'RenewInput': {'serverId', 'ttlMs', 'leases'},
            'CommitInput': {'serverId', 'commitId', 'players'},
            'CommitPlayer': {'userId', 'epoch', 'ops'},
            'SessionSnapshot': {'seq', 'fields', 'versions'},
            'CommitResponse': {'commitId', 'items'},
        }.items():
            self.assertEqual(set(types[name]['fields']), fields)
        self.assertEqual(types['CommitPlayer']['fields']['ops']['java'], 'List<Fields.PlayerOperation>')
        self.assertTrue(all(types['SessionSnapshot']['fields'][name]['required']
                            for name in ('seq', 'fields', 'versions')))

    def test_curation_is_idempotent_and_replaces_java_names_by_wire_identity(self) -> None:
        """A parallel Java controller's method names must never create duplicate SDK routes."""
        fresh = copy.deepcopy(self.doc)
        endpoint = next(item for item in fresh['endpoints'] if item['id'] == 'fields.commitSession')
        endpoint['id'], endpoint['name'] = 'fields.commit', 'commit'
        curate(fresh)
        curate(fresh)
        routes = [item for item in fresh['endpoints'] if item['path'].endswith('/commits')]
        self.assertEqual(len(routes), 1)
        self.assertEqual(routes[0]['id'], 'fields.commitSession')
        for name in ('AcquireInput', 'SessionResponse', 'CommitInput', 'CommitResponse'):
            self.assertEqual(fresh['types']['fields'][name], self.doc['types']['fields'][name])

    def test_critical_transactions_remain_distinct(self) -> None:
        """Buffered commits must not change the established synchronous transaction request."""
        types = self.doc['types']['fields']
        self.assertEqual(set(types['TransactionInput']['fields']),
                         {'conditions', 'idempotencyKey', 'ops', 'reason', 'ref', 'universeId'})
        endpoints = {endpoint['id']: endpoint for endpoint in self.doc['endpoints']}
        self.assertEqual(endpoints['fields.transaction']['bodyType'], 'TransactionInput')
        self.assertNotEqual(endpoints['fields.commitSession']['bodyType'], 'TransactionInput')


if __name__ == '__main__':
    unittest.main()
