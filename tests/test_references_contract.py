"""Independent shared F2 route, generation and static typing regressions."""
from __future__ import annotations

import copy
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from references_contract import curate


class ReferencesContractTests(unittest.TestCase):
    """Check contract literals independently of generated Luau schemas."""

    def setUp(self) -> None:
        """Load the authoritative checked-in spec without consulting live services."""
        self.doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        self.endpoints = {e['id']: e for e in self.doc['endpoints']}

    def test_routes_permissions_and_wire_types(self) -> None:
        """All three reference routes use the exact F2 paths, levels and typed envelopes."""
        base = '/api/fields/universes/{universeId}'
        for name, method, suffix, level in (
            ('definitionReferences', 'GET', '/definitions/{id}/references', 'READ'),
            ('putReferences', 'PUT', '/references/{consumerType}/{consumerId}', 'READ_WRITE'),
            ('deleteReferences', 'DELETE', '/references/{consumerType}/{consumerId}', 'READ_WRITE'),
        ):
            route = self.endpoints['fields.' + name]
            self.assertEqual((route['method'], route['path'], route['minimumLevel']),
                             (method, base + suffix, level))
            self.assertTrue(route['idempotent'])
            self.assertTrue(route['retryable'])
            self.assertFalse(route['cacheable'])
            self.assertEqual(route['statuses'], [200] if method == 'GET' else [204])
        types = self.doc['types']['fields']
        self.assertEqual(types['ReferenceConsumerType']['enum'], ['GAMEMODE', 'CODE'])
        self.assertEqual(set(types['FieldReferenceInput']['fields']), {'label', 'fields'})
        self.assertTrue(types['FieldReferenceInput']['fields']['fields']['required'])
        self.assertEqual(types['FieldReferenceInput']['fields']['fields']['java'], 'List<String>')
        self.assertEqual(set(types['FieldReferences']['fields']), {'fieldId', 'references'})
        self.assertEqual(set(types['FieldReference']['fields']), {'consumerType', 'consumerId', 'label'})

    def test_curating_is_idempotent_and_retains_audit_reasons(self) -> None:
        """Refresh cannot duplicate routes, drop force or make guarded writes retryable."""
        fields = [copy.deepcopy(e) for e in self.doc['endpoints'] if e['service'] == 'fields']
        definitions = copy.deepcopy(self.doc['types']['fields'])
        first = curate(fields, definitions)
        self.assertEqual(curate(copy.deepcopy(first[0]), copy.deepcopy(first[1])), first)
        self.assertIn('force', definitions['Action']['fields'])
        self.assertTrue(definitions['Action']['fields']['reason']['required'])
        for name in ('update', 'purge'):
            route = self.endpoints['fields.' + name]
            self.assertEqual(route['minimumLevel'], 'ADMIN')
            force = [p for p in route['queryParams'] if p['name'] == 'force']
            self.assertEqual(len(force), 1)
            self.assertEqual((force[0]['type'], force[0]['required'], force[0]['default']),
                             ('boolean', False, 'false'))
            self.assertFalse(route['retryable'])
            if name == 'purge':
                self.assertTrue(next(p for p in route['queryParams'] if p['name'] == 'reason')['required'])
            else:
                self.assertTrue(definitions[route['bodyType']]['fields']['reason']['required'])

    def test_strict_reference_calls(self) -> None:
        """Compile supported calls and reject invalid consumer kinds or malformed bodies."""
        prefix = '''--!strict
local SDK = require("./src/BloxSDK")
local Types = require("./src/Types/Fields")
--- Compile only: this fixture never starts a client or sends a request.
return function(client: SDK.Client)
 local _consumer: Types.ReferenceConsumerType = "GAMEMODE"
 client.fields:definitionReferences({path={id="Stats.Rating"}})
 client.fields:putReferences({path={consumerType="CODE",consumerId="welcome"},body={label="Welcome",fields={}}})
 client.fields:deleteReferences({path={consumerType="GAMEMODE",consumerId="ranked"}})
 client.fields:archive({path={id="Rating"},body={force=true,reason="Reviewed dependencies"}})
'''
        with tempfile.NamedTemporaryFile(prefix='references-types-', suffix='.luau', dir=ROOT, mode='w') as file:
            path = Path(file.name)
            for statement, valid in (
                ('', True),
                ('local bad: Types.ReferenceConsumerType = "PARTY"', False),
                ('client.fields:deleteReferences({path={consumerType="PARTY",consumerId="p"}})', False),
                ('client.fields:putReferences({path={consumerType="CODE",consumerId="c"},body={label="c"}})', False),
                ('client.fields:putReferences({path={consumerType="CODE",consumerId="c"},body={label="c",fields={1}}})', False),
                ('client.fields:archive({path={id="Rating"},body={force="true",reason="Reviewed dependencies"}})', False),
            ):
                path.write_text(prefix + statement + '\nend\n')
                result = subprocess.run(['luau-analyze', '-j1', str(path)], capture_output=True, text=True)
                if valid:
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                else:
                    self.assertNotEqual(result.returncode, 0, statement)
                    self.assertIn('TypeError', result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
