"""Independent source-backed acceptance checks for the new random gameplay contracts."""
from __future__ import annotations
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RotationsContractTests(unittest.TestCase):
    """Keep paths, authority, safety, request shape and exact replay envelopes explicit."""

    def setUp(self) -> None:
        """Read checked-in contracts without HTTP or backend startup."""
        self.doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        self.routes = {e['name']:e for e in self.doc['endpoints'] if e['service']=='fields'}
        self.types = self.doc['types']['fields']
        self.vectors = json.loads((ROOT/'tests/vectors/rotations.json').read_text())

    def test_complete_controller_inventory_has_independent_wire_goldens(self) -> None:
        """All three literal resources and non-resource routes must have explicit fixtures."""
        names = {verb+resource+('s' if verb=='list' else '')
                 for verb in ('list','get','create','put','delete')
                 for resource in ('RandomTable','Generator','Rotation')}
        names |= {'activeRotation','tableOdds','previewGenerator','simulateGenerator','rollGenerator',
                  'claimRotation','rotationStock','advanceRotation','rerollRotation','randomDefinitionHistory',
                  'rotationHistory','playerRollHistory','playerClaimHistory','randomnessSchema','randomnessFields','eraseRandomness'}
        actual = {e['name'] for e in self.routes.values() if e['source'].endswith('/RotationsController.java')}
        self.assertEqual(actual,names)
        self.assertEqual({v['endpoint'] for v in self.vectors['vectors']},{'fields.'+n for n in names})
        self.assertEqual(len(names),31)
        for name in names:
            route=self.routes[name]
            self.assertEqual(route['statuses'],[200])
            self.assertFalse(route['cacheable'])
            self.assertNotIn('|',route['path'])

    def test_literal_game_server_endpoints_levels_and_idempotency(self) -> None:
        """Do not infer a nonexistent generator-odds or all-active endpoint."""
        for name,verb,suffix,level in (
            ('activeRotation','GET','/rotations/{key}/active','READ'),
            ('tableOdds','GET','/random-tables/{key}/odds','READ'),
            ('rollGenerator','POST','/generators/roll','READ_WRITE'),
            ('previewGenerator','POST','/generators/preview','READ'),
            ('claimRotation','POST','/rotations/claim','READ_WRITE'),
            ('rotationStock','GET','/rotations/instances/{id}/stock','READ'),
        ):
            route=self.routes[name]
            self.assertEqual((route['method'],route['path'],route['minimumLevel']),
                             (verb,'/api/fields/universes/{universeId}'+suffix,level))
        for name in ('rollGenerator','claimRotation'):
            self.assertEqual(self.routes[name]['idempotencyField'],'idempotencyKey')
            self.assertTrue(self.routes[name]['retryable'])
        for name in ('advanceRotation','rerollRotation'):
            self.assertEqual(self.routes[name]['minimumLevel'],'ADMIN')
            self.assertFalse(self.routes[name]['retryable'])

    def test_strong_gameplay_envelopes_and_explicit_json_nulls(self) -> None:
        """Picks, applied transaction and pity must not collapse into opaque JsonNode results."""
        self.assertEqual(self.routes['rollGenerator']['responseJava'],'GeneratorRollResult')
        self.assertEqual(self.routes['claimRotation']['responseJava'],'RotationClaimResult')
        self.assertEqual(self.types['Generated']['fields']['picks']['java'],'List<GeneratorPick>')
        self.assertEqual(self.types['Generated']['fields']['cost']['java'],'List<Fields.PlayerOperation>')
        for name,field in (('Generated','pityAfter'),('GeneratorPick','durationSeconds'),('GeneratorPick','payload'),('RotationActive','current'),('RotationActive','next')):
            self.assertTrue(self.types[name]['fields'][field]['nullable'])
            self.assertTrue(self.types[name]['fields'][field]['required'])
        rotations=self.types['RuntimeSnapshot']['fields']['rotations']
        self.assertFalse(rotations['required'])
        self.assertEqual(rotations['java'],'List<RotationActive>')
        for name in ('GeneratorRollResult','RotationClaimResult'):
            self.assertEqual(self.types[name]['fields']['transaction']['java'],'Result')

    def test_authoritative_engine_examples_are_not_abbreviated_or_rewritten(self) -> None:
        """Golden outputs preserve the full five-card pack, nulls and original replay indicator."""
        source=ROOT.parent/'svc/fields-service/API_CONTRACT.md'
        if not source.is_file(): self.skipTest('Fields source unavailable')
        text=source.read_text()
        for name in ('active','roll','claim'):
            match=re.search(r'<!-- rotation-'+name+r'-response -->\s*```json\s*(.*?)```',text,re.S)
            self.assertIsNotNone(match)
            self.assertEqual(self.vectors[name],json.loads(match[1]))
        self.assertEqual(len(self.vectors['roll']['results'][0]['picks']),5)
        self.assertFalse(self.vectors['claim']['transaction']['replayed'])

    def test_no_deferral_and_release_metadata(self) -> None:
        """Regeneration must retain new coverage and the unpublished 0.2.0 work."""
        coverage=(ROOT/'SDK_COVERAGE.md').read_text()
        self.assertNotIn('TODO: Fields generic Rotations',coverage)
        self.assertIn('378',coverage)
        self.assertIn('version = "3.1.0"',(ROOT/'wally.toml').read_text())
        for file in ('CHANGELOG.md','docs/CHANGELOG.md'):
            text=(ROOT/file).read_text()
            self.assertIn('## 0.3.0',text)
            self.assertIn('## 0.2.0',text)


if __name__=='__main__':
    unittest.main()
