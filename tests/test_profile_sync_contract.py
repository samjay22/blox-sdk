"""Independent assertions for the shared batch wire protocol and source curation."""
from __future__ import annotations

import copy
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from service_contracts import refresh


class ProfileSyncContractTests(unittest.TestCase):
    """Keep backend implementation records out of the public batch contract."""

    def test_batch_protocol(self) -> None:
        """The batch POST is READ, machine-key eligible, repeat-safe and never cached."""
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        endpoint = next(e for e in doc['endpoints'] if e['id'] == 'fields.changesBatch')
        self.assertEqual((endpoint['method'], endpoint['path'], endpoint['minimumLevel']),
                         ('POST', '/api/fields/universes/{universeId}/players/changes/batch', 'READ'))
        self.assertIn('serviceAccount', endpoint['authKinds'])
        self.assertTrue(endpoint['idempotent'] and endpoint['retryable'])
        self.assertFalse(endpoint['cacheable'])
        fields = doc['types']['fields']
        self.assertEqual(set(fields['BatchChangesInput']['fields']), {'players', 'maxEntries'})
        self.assertFalse(fields['BatchChangesInput']['fields']['maxEntries']['required'])
        self.assertEqual(set(fields['PlayerChangesItem']['fields']),
                         {'userId', 'entries', 'latestSeq', 'nextSinceSeq', 'hasMore', 'needsSnapshot'})
        for name in ('PlayerChangesItem', 'BatchChangesResponse'):
            self.assertTrue(all(f['required'] for f in fields[name]['fields'].values()))

    def test_source_refresh_keeps_public_contract_and_legacy_batch(self) -> None:
        """Internal SQL/telemetry records must not replace public Batch or job Kind DTOs."""
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        fresh = refresh(copy.deepcopy(doc))
        self.assertEqual(fresh, doc)
        fields = fresh['types']['fields']
        self.assertEqual(set(fields['Batch']['fields']), {'universeId', 'subjects', 'fields'})
        self.assertIn('BULK', fields['Kind']['enum'])
        self.assertTrue({'ChangeHead', 'ChangeGroup', 'ChangeRange', 'IndexedBatch', 'Lookup'}.isdisjoint(fields))


if __name__ == '__main__':
    unittest.main()
