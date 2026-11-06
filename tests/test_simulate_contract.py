"""Independent offline assertions for F4 sample/simulation wire contracts."""
from __future__ import annotations

import json
import copy
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from simulate_contract import curate_simulation


class SimulateContractTests(unittest.TestCase):
    """Prevent generated fixtures from hiding authorization or response-shape drift."""

    def test_refresh_overlay_preserves_the_reviewed_contract(self) -> None:
        """Source refresh must not lose facades or weaken numeric/nullable wire types."""
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        fresh = copy.deepcopy(doc)
        curate_simulation(fresh)
        self.assertEqual(fresh, doc)
        fresh['endpoints'] = [e for e in fresh['endpoints'] if e['id'] not in ('fields.samplePlayers', 'matchmaking.simulateCriteria')]
        for service, names in (('fields', ('PlayerSample', 'PlayerSampleResponse')), ('matchmaking', ('CriteriaSimulationRequest', 'CriteriaFieldCoverage', 'CriteriaSimulationEstimate', 'CriteriaSimulationResponse'))):
            for name in names:
                fresh['types'][service].pop(name)
        curate_simulation(fresh)
        self.assertEqual(fresh, doc)

    def test_overlay_is_independent_of_endpoint_order(self) -> None:
        """Canonical replay must preserve both merge sides regardless of insertion order."""
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        fresh = copy.deepcopy(doc)
        fresh['endpoints'].reverse()
        curate_simulation(fresh)
        self.assertEqual(fresh, doc)
        curate_simulation(fresh)
        self.assertEqual(fresh, doc)

    def test_routes_and_shapes(self) -> None:
        """Require exact F4 routes, required body fields, typed maps and permissions."""
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        endpoints = {e['id']: e for e in doc['endpoints']}
        sample = endpoints['fields.samplePlayers']
        simulate = endpoints['matchmaking.simulateCriteria']
        self.assertEqual((sample['method'], sample['path'], sample['minimumLevel']),
                         ('GET', '/api/fields/universes/{universeId}/players/sample', 'READ'))
        self.assertEqual([(p['name'], p['type']) for p in sample['queryParams']], [('limit', 'number'), ('fields', 'string')])
        self.assertEqual((simulate['method'], simulate['path'], simulate['minimumLevel']),
                         ('POST', '/api/matchmaking/criteria/simulate', 'READ_WRITE'))
        self.assertFalse(simulate['retryable'])
        self.assertFalse(simulate['cacheable'])
        fields = doc['types']['fields']
        mm = doc['types']['matchmaking']
        self.assertEqual(set(fields['PlayerSampleResponse']['fields']), {'universeId', 'sampled', 'players'})
        self.assertEqual(fields['PlayerSample']['fields']['values']['java'], 'Map<String, Double>')
        request = mm['CriteriaSimulationRequest']['fields']
        self.assertEqual({k for k, v in request.items() if v['required']}, {'universeId', 'criteria', 'sampleSize'})
        self.assertEqual(request['criteria']['java'], 'List<MatchmakingCriteriaDTO>')
        self.assertEqual(set(mm['CriteriaSimulationResponse']['fields']), {'sampled', 'fieldCoverage', 'estimate', 'warnings'})
        self.assertEqual(set(mm['CriteriaFieldCoverage']['fields']), {'present', 'missing', 'min', 'max', 'mean', 'p50', 'p90'})
        self.assertEqual(set(mm['CriteriaSimulationEstimate']['fields']), {'groups', 'avgGroupSize', 'unmatchable', 'unmatchablePct'})


if __name__ == '__main__':
    unittest.main()
