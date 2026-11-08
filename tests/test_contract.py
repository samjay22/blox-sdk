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

    def test_gateway_contract_and_coverage_mutations(self) -> None:
        """Coverage rejects gateway drift, the reserved config route, omissions and double prefixes."""
        checker = runpy.run_path(str(ROOT/'tools/check-coverage'))
        generated = GEN.generate(copy.deepcopy(self.doc))
        routing = generated[ROOT/'src/Core/Routing.luau']
        verify = checker['assert_gateway_coverage']
        verify(self.doc['endpoints'], routing)
        for before, after in (
            ('https://lb1.blox-api.com', 'https://old.example'),
            ('/fields-service', '/wrong-fields-service'),
            ('/code-service', '/codes-service'),
            ('/leaderboard-service', '/leaderboards-service'),
            ('["fields"]', '["unknown"]'),
        ):
            with self.subTest(after=after), self.assertRaises(AssertionError):
                verify(self.doc['endpoints'], routing.replace(before, after))
        endpoints = copy.deepcopy(self.doc['endpoints'])
        endpoints[0]['path'] = '/auth-service' + endpoints[0]['path']
        with self.assertRaises(AssertionError):
            verify(endpoints, routing)
        endpoints = [e for e in self.doc['endpoints'] if e['service'] != 'audit']
        with self.assertRaises(AssertionError):
            verify(endpoints, routing)

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
        expected={'codes.createCode':'ADMIN','codes.redeem':'READ_WRITE','codes.listRedemptions':'ADMIN','matchmaking.createGameMode':'ADMIN','matchmaking.updateGameMode':'ADMIN','matchmaking.getBulkQueueStatus':'READ','matchmaking.validateQueue':'READ','matchmaking.processMatchmaking':'ADMIN','party.getAllParties':'ADMIN'}
        for endpoint,level in expected.items():self.assertEqual(self.routes[endpoint]['minimumLevel'],level)
        for e in self.doc['endpoints']:
            if e['service']=='auth' and '/service-accounts' in e['path'] and '/internal/' not in e['path']:
                self.assertEqual(e['requiredRole'],'IDENTITY');self.assertNotIn('serviceAccount',e['authKinds'])
        self.assertIn('none',self.routes['party.getUpdates']['authKinds'])

    def test_sensitive_and_side_effecting_reads(self) -> None:
        """Ensure online-state mutations and credential endpoints do not become cached GETs."""
        for e in self.doc['endpoints']:
            if '/roblox/keys' in e['path'] or '/service-accounts' in e['path']:self.assertFalse(e['cacheable'])

    def test_wire_field_names(self) -> None:
        """Assert easily-confused backend field names and nested DTOs."""
        types=self.doc['types']
        self.assertEqual(set(types['party']['CreatePartyRequest']['fields']),{'ownerId','placeId'})
        self.assertEqual(set(types['codes']['RedeemCodeRequest']['fields']),{'code','universeId','robloxUserId','placeId'})
        self.assertNotIn('playerMetadata',types['matchmaking']['QueueRequest']['fields'])
        self.assertEqual(set(types['auth']['ServiceAccountPatchRequest']['fields']),{'enabled','description','expiresAt'})

    def test_matchmaking_namespaced_id_guidance(self) -> None:
        """Keep consumer docs and regenerated type comments aligned on literal dotted IDs."""
        generated = GEN.generate(copy.deepcopy(self.doc))[ROOT/'src/Types/Matchmaking.luau']
        self.assertIn('fieldName accepts any computed Fields ID, including namespaced IDs', generated)
        for name in ('README.md', 'docs/MATCHMAKING.md', 'docs/MIGRATION.md', 'docs/SOURCE-AUDIT.md'):
            with self.subTest(path=name):
                text = (ROOT/name).read_text()
                self.assertIn('Stats.Elo', text)
                self.assertNotIn('top-level computed', text)
                self.assertNotIn('dotted criteria names are rejected', text)
                self.assertNotIn('Dotted names are rejected', text)
        guide = (ROOT/'docs/MATCHMAKING.md').read_text()
        self.assertIn(r'^[A-Za-z][A-Za-z0-9_]{0,63}(\.[A-Za-z][A-Za-z0-9_]{0,63}){0,7}$', guide)
        self.assertIn('at most 200 characters', guide)

    def test_alias_statuses_and_safety(self) -> None:
        """Legacy deletion POSTs are never automatically retried; DELETE aliases preserve 204."""
        for e in self.doc['endpoints']:
            if e['service']=='auth' and e['name'].endswith('Rest'):self.assertEqual(e['statuses'],[204])
            if e['method']=='POST' and e['retryable']:
                self.assertTrue(e.get('idempotencyField') or (e['id']=='fields.import' and e.get('idempotencyHeader') and e.get('requestFormat')=='ndjson') or e['id'] in {'matchmaking.validateQueue','matchmaking.getBulkQueueStatus','fields.previewGenerator','fields.simulateGenerator'})

    def test_live_source_contract_is_reproducible(self) -> None:
        """Compare record/route extraction and source hashes without changing workspace files."""
        from service_contracts import refresh, SOURCES
        fresh = refresh(copy.deepcopy(self.doc))
        self.assertEqual(fresh, self.doc)
        self.assertTrue({'Lock', 'LockScope', 'CursorBarrier'}.isdisjoint(self.doc['types']['fields']))
        self.assertIn('svc/fields-service/LOCKING.md', self.doc['sourceHashes'])
        self.assertEqual(set(SOURCES), {'audit','leaderboards','fields','codes','matchmaking','auth','platform'})

    def test_coverage_detects_omission_without_inventory_help(self) -> None:
        """Deleting either a rating or board route fails independently of routes.json."""
        checker = runpy.run_path(str(ROOT/'tools/check-coverage'))
        actual = {(e['service'], e['method'], e['path']) for e in self.doc['endpoints']}
        checker['assert_controller_coverage'](actual)
        for endpoint in ('leaderboards.ratingMatch','leaderboards.rollover','audit.batch','fields.runtimeSnapshot','fields.refund','fields.validateOps','fields.previewBoard','fields.leaderboardBindings'):
            e = self.routes[endpoint]
            with self.assertRaises(AssertionError):
                checker['assert_controller_coverage'](actual-{(e['service'],e['method'],e['path'])})

    def test_fields_board_provisioning_contract(self) -> None:
        """Assert ADMIN routes, unkeyed safety and typed preview/listing boundaries independently."""
        for name, method, path in (
            ('previewBoard','POST','/definitions/preview-board'),
            ('leaderboardBindings','GET','/leaderboard-bindings'),
        ):
            route=self.routes['fields.'+name]
            self.assertEqual(route['path'], '/api/fields/universes/{universeId}'+path)
            self.assertEqual(route['method'], method)
            self.assertEqual(route['minimumLevel'], 'ADMIN')
            self.assertEqual(route['retryable'], method=='GET')
            self.assertEqual(route['cacheable'], method=='GET')
            self.assertFalse(route.get('idempotencyField'))
        types=self.doc['types']['fields']
        candidate=types['PreviewBoardInput']['fields']
        self.assertEqual(set(candidate), {'universeId','id','scope','type','binding'})
        self.assertEqual({k for k,v in candidate.items() if v['required']}, {'id','type','binding'})
        self.assertEqual(candidate['type']['java'], 'Fields.TypeExpr')
        self.assertEqual(candidate['binding']['java'], 'Fields.LeaderboardBinding')
        self.assertEqual(types['BindingView']['fields']['binding']['java'], 'Fields.LeaderboardBinding')
        self.assertEqual(types['Preview']['fields']['conflicts']['java'], 'List<BoardConflict>')
        self.assertEqual({k for k,v in types['Preview']['fields'].items() if v['required']},
                         {'settings','effectiveSettings','status','valid','conflicts'})
        self.assertFalse(types['Preview']['fields']['willWiden']['required'])
        self.assertEqual(set(types['BoardSettings']['fields']),
                         {'name','displayName','sortOrder','aggregation','resetSchedule','minScore','maxScore'})
        self.assertTrue(all(f['required'] for f in types['BoardSettings']['fields'].values()))
        self.assertTrue(all(f['required'] for f in types['ScoreRange']['fields'].values()))

    def test_new_service_contract_exceptions(self) -> None:
        """Test guards, cursor schemas, conditional JSON, decimal amounts and key carriers independently."""
        self.assertEqual(self.routes['leaderboards.ratingConfig']['minimumLevel'], 'ADMIN')
        self.assertEqual(self.routes['fields.evaluateFlags']['minimumLevel'], 'READ')
        self.assertEqual(self.routes['fields.validateOps']['minimumLevel'], 'READ')
        self.assertFalse(self.routes['fields.validateOps']['retryable'])
        self.assertEqual(self.doc['types']['fields']['OpsValidationInput']['fields']['ops']['java'], 'List<Fields.PlayerOperation>')
        self.assertTrue(self.doc['types']['fields']['OpsValidationResult']['fields']['errors']['required'])
        self.assertEqual(self.routes['audit.batch']['statuses'], [202])
        self.assertEqual(self.routes['fields.runtimeSnapshot']['statuses'], [200,304])
        self.assertEqual(self.routes['fields.runtimeSnapshot']['responseFormat'], 'json')
        self.assertFalse(self.routes['leaderboards.rollover']['retryable'])
        for name in ('transaction','multiTransaction','reverseEntry','reverseTransaction','purchase','refund','restoreSnapshot'):
            self.assertEqual(self.routes['fields.'+name]['idempotencyField'], 'idempotencyKey')
        for name in ('user','users','top','config','configure','match'):
            self.assertIn('leaderboards.rating'+name.capitalize(), self.routes)
        self.assertEqual(self.doc['types']['audit']['GroupBy']['enum'], ['action','actor','outcome'])
        for e in self.doc['endpoints']:
            if e['service'] in ('audit','fields','leaderboards') and any(p['name']=='cursor' for p in e['queryParams']):
                self.assertTrue(e['responseJava'].startswith('CursorPage<') or e['responseJava'] in ('Summary','FieldPage','SnapshotDetail','PlayerSearchPage'))

if __name__=='__main__':unittest.main()
