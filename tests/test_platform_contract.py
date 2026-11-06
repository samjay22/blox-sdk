"""Independent offline wave-2 curation, permissions and privacy contract checks."""
from __future__ import annotations
import copy
import json
import sys
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
from platform_contract import apply


class PlatformContractTests(unittest.TestCase):
    """Keep the new service reproducible without startup, git, deployment or network access."""

    def test_overlay_is_replayable(self) -> None:
        """Repeated curation cannot duplicate or reorder endpoints."""
        doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        self.assertEqual(apply(copy.deepcopy(doc)), doc)
        reversed_doc = copy.deepcopy(doc)
        reversed_doc['endpoints'].reverse()
        self.assertEqual(apply(reversed_doc), doc)

    def test_permissions_and_unkeyed_writes(self) -> None:
        """Machine-only and SUPER_ADMIN endpoints never borrow a scoped human identity."""
        endpoints = {e['id']: e for e in json.loads((ROOT/'spec/endpoints.json').read_text())['endpoints']}
        self.assertEqual(endpoints['platform.evaluateFlags']['minimumLevel'], 'READ')
        for name in ('publishEvent','ingestUsage','gatewayRateLimits'):
            self.assertEqual(endpoints['platform.'+name]['authKinds'], ['serviceAccount'])
        for name in ('putPlan','createIncident','updateIncident','deleteIncident'):
            self.assertEqual(endpoints['platform.'+name]['requiredRole'], 'SUPER_ADMIN')
            self.assertNotIn('scoped', endpoints['platform.'+name]['authKinds'])
        for endpoint in endpoints.values():
            if endpoint['service'] == 'platform' and endpoint['method'] == 'POST':
                self.assertFalse(endpoint['retryable'])
                self.assertFalse(endpoint['cacheable'])

    def test_privacy_is_a_breaking_body_contract(self) -> None:
        """No query-only reason survives, and the response is an erasure tombstone."""
        doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        endpoint = next(e for e in doc['endpoints'] if e['id'] == 'fields.deletePlayer')
        self.assertEqual(endpoint['queryParams'], [])
        self.assertTrue(endpoint['bodyRequired'])
        self.assertEqual(endpoint['responseJava'], 'PlayerEraseResult')
        self.assertFalse(endpoint['retryable'])
        fields = doc['types']['fields']['PlayerEraseInput']['fields']
        self.assertEqual(set(fields), {'reason','confirmUserId'})
        self.assertTrue(all(field['required'] for field in fields.values()))


if __name__ == '__main__':
    unittest.main()
