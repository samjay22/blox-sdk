"""Independent offline integrity checks for the declarative contract and generator."""
from __future__ import annotations
import copy
import importlib.util
import json
import unittest
import sys
import runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
SPEC=importlib.util.spec_from_file_location('generator',ROOT/'tools/gen.py')
assert SPEC and SPEC.loader
GEN=importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GEN)

class ContractTests(unittest.TestCase):
    """Catch contract regressions that a generated Luau fixture cannot discover by itself."""
    def setUp(self) -> None:
        """Reload the authoritative spec before each independent assertion."""
        self.doc=json.loads((ROOT/'spec/endpoints.json').read_text())
        self.routes={e['id']:e for e in self.doc['endpoints']}

    def test_deterministic(self) -> None:
        """Generation does not depend on time, external repositories or input object identity."""
        self.assertEqual(GEN.generate(copy.deepcopy(self.doc)),GEN.generate(copy.deepcopy(self.doc)))

    def test_every_inventory_route_exactly_once(self) -> None:
        """Coverage keys include service so the five /health paths cannot mask omissions."""
        routes=json.loads((ROOT/'routes.json').read_text())
        actual=[(e['service'],e['method'],e['path']) for e in self.doc['endpoints']]
        self.assertEqual(len(actual),len(set(actual)))
        for r in routes:
            service={'mm':'matchmaking','code':'codes'}.get(r['svc'],r['svc'])
            self.assertEqual(actual.count((service,r['method'],r['path'])),1)

    def test_controller_specific_access(self) -> None:
        """Assert reviewed exceptions rather than merely testing method-based heuristics."""
        expected={'codes.createCode':'ADMIN','codes.redeem':'READ_WRITE','codes.listRedemptions':'ADMIN','matchmaking.createGameMode':'ADMIN','matchmaking.updateGameMode':'ADMIN','matchmaking.getBulkQueueStatus':'READ','matchmaking.validateQueue':'READ','matchmaking.processMatchmaking':'ADMIN','data.createOrUpdateSchema':'ADMIN','party.getAllParties':'ADMIN'}
        for endpoint,level in expected.items():self.assertEqual(self.routes[endpoint]['minimumLevel'],level)
        for e in self.doc['endpoints']:
            if '/service-accounts' in e['path']:
                self.assertEqual(e['requiredRole'],'SUPER_ADMIN');self.assertNotIn('serviceAccount',e['authKinds'])
        self.assertIn('none',self.routes['party.getUpdates']['authKinds'])

    def test_sensitive_and_side_effecting_reads(self) -> None:
        """Ensure online-state mutations and credential endpoints do not become cached GETs."""
        data=self.routes['data.getUserData']
        self.assertFalse(data['cacheable']);self.assertFalse(data['retryable']);self.assertFalse(data['idempotent'])
        for e in self.doc['endpoints']:
            if '/roblox/keys' in e['path'] or '/service-accounts' in e['path']:self.assertFalse(e['cacheable'])

    def test_wire_field_names(self) -> None:
        """Assert easily-confused backend field names and nested DTOs."""
        types=self.doc['types']
        self.assertEqual(set(types['party']['CreatePartyRequest']['fields']),{'ownerId','placeId'})
        self.assertEqual(set(types['codes']['RedeemCodeRequest']['fields']),{'code','universeId','robloxUserId','placeId','redemptionKey'})
        self.assertIn('baseData',types['data']['CreateUserDataRequest']['fields'])
        self.assertIn('playerMetadata',types['matchmaking']['QueueRequest']['fields'])
        self.assertEqual(set(types['auth']['ServiceAccountPatchRequest']['fields']),{'enabled','description','expiresAt'})
        self.assertEqual(self.routes['data.createManualSnapshot']['bodyType'],None)
        self.assertIn('universeId',{p['name'] for p in self.routes['data.createManualSnapshot']['queryParams']})

    def test_alias_statuses_and_safety(self) -> None:
        """Legacy deletion POSTs are never automatically retried; DELETE aliases preserve 204."""
        for e in self.doc['endpoints']:
            if e['service']=='auth' and e['name'].endswith('Rest'):self.assertEqual(e['statuses'],[204])
            if e['method']=='POST' and e['retryable']:
                self.assertTrue(e.get('idempotencyField') or e['id'] in {'matchmaking.validateQueue','matchmaking.getBulkQueueStatus'})

    def test_live_source_contract_is_reproducible(self) -> None:
        """Compare record/route extraction and source hashes without changing workspace files."""
        from service_contracts import refresh, SOURCES
        fresh = refresh(copy.deepcopy(self.doc))
        self.assertEqual(fresh, self.doc)
        self.assertEqual(set(SOURCES), {'audit','config','leaderboards','economy'})

    def test_coverage_detects_omission_without_inventory_help(self) -> None:
        """Deleting either a rating or board route fails independently of routes.json."""
        checker = runpy.run_path(str(ROOT/'tools/check-coverage'))
        actual = {(e['service'], e['method'], e['path']) for e in self.doc['endpoints']}
        checker['assert_controller_coverage'](actual)
        for endpoint in ('leaderboards.ratingMatch','leaderboards.rollover','audit.batch','config.snapshot','economy.refund'):
            e = self.routes[endpoint]
            with self.assertRaises(AssertionError):
                checker['assert_controller_coverage'](actual-{(e['service'],e['method'],e['path'])})

    def test_new_service_contract_exceptions(self) -> None:
        """Test guards, cursor schemas, conditional JSON, decimal amounts and key carriers independently."""
        self.assertEqual(self.routes['leaderboards.ratingConfig']['minimumLevel'], 'ADMIN')
        self.assertEqual(self.routes['config.evaluate']['minimumLevel'], 'READ')
        self.assertEqual(self.routes['audit.batch']['statuses'], [202])
        self.assertEqual(self.routes['config.snapshot']['statuses'], [200,304])
        self.assertEqual(self.routes['config.snapshot']['responseFormat'], 'json')
        self.assertFalse(self.routes['leaderboards.rollover']['retryable'])
        for name in ('grant','spend','transfer','adjust','reverse','receipt','refund'):
            self.assertEqual(self.routes['economy.'+name]['idempotencyField'], 'idempotencyKey')
        for name in ('user','users','top','config','configure','match'):
            self.assertIn('leaderboards.rating'+name.capitalize(), self.routes)
        self.assertEqual(self.doc['types']['audit']['GroupBy']['enum'], ['action','actor','outcome'])
        self.assertFalse(self.doc['types']['config']['Rules']['fields']['allowUserIds']['required'])
        self.assertEqual(self.doc['types']['economy']['AmountInput']['fields']['amount']['java'], 'BigDecimal')
        for e in self.doc['endpoints']:
            if e['service'] in ('audit','config','economy','leaderboards') and any(p['name']=='cursor' for p in e['queryParams']):
                self.assertTrue(e['responseJava'].startswith('CursorPage<') or e['responseJava']=='Summary')

if __name__=='__main__':unittest.main()
