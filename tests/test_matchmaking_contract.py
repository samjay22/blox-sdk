"""Independent shared F1 route and type assertions; no backend or network execution."""
from __future__ import annotations
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MatchmakingContractTests(unittest.TestCase):
    """Keep criteria discovery typed and accessible with the normal read authentication."""

    def test_criteria_catalog_contract(self) -> None:
        """Assert the exact shared route, response and read-only safety metadata."""
        doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        endpoint = next(e for e in doc['endpoints'] if e['id'] == 'matchmaking.getCriteriaTypes')
        self.assertEqual(endpoint['method'], 'GET')
        self.assertEqual(endpoint['path'], '/api/matchmaking/criteria-types')
        self.assertEqual(endpoint['minimumLevel'], 'READ')
        self.assertEqual(endpoint['serviceName'], 'MatchmakingService')
        self.assertEqual(set(endpoint['authKinds']), {'serviceAccount', 'user', 'custom', 'scoped'})
        self.assertEqual(endpoint['statuses'], [200])
        self.assertEqual(endpoint['responseJava'], 'List<CriteriaTypeInfo>')
        self.assertFalse(endpoint['bodyRequired'])
        for flag in ('idempotent', 'retryable', 'cacheable'):
            self.assertTrue(endpoint[flag])
        fields = doc['types']['matchmaking']['CriteriaTypeInfo']['fields']
        self.assertEqual({name: info['java'] for name, info in fields.items()}, {
            'type': 'CriteriaType', 'fieldRequired': 'boolean',
            'allowedReturns': 'List<CriteriaComputedReturn>', 'description': 'String'})
        self.assertTrue(all(info['required'] for info in fields.values()))
        self.assertEqual(doc['types']['matchmaking']['CriteriaComputedReturn']['enum'], ['int', 'number'])

    def test_static_criteria_catalog(self) -> None:
        """Compile the facade and reject unsupported computed return kinds and value types."""
        prelude = '''--!strict
local SDK = require("./src/BloxSDK")
local Types = require("./src/Types/Matchmaking")
--- Compile only; no client construction or service startup.
return function(client: SDK.Client, catalog: Types.GetCriteriaTypesResultValue)
 local _result = client.matchmaking:getCriteriaTypes()
 local _required: boolean = catalog[1].fieldRequired
 local _kind: "int" | "number" = catalog[1].allowedReturns[1]
'''
        with tempfile.NamedTemporaryFile(mode='w', suffix='.luau', prefix='criteria-types-', dir=ROOT) as fixture:
            path = Path(fixture.name)
            for extra, valid in (
                ('', True),
                ('local bad: Types.CriteriaComputedReturn = "string"', False),
                ('local bad: string = catalog[1].fieldRequired', False),
                ('local bad: number = catalog[1].description', False),
            ):
                path.write_text(prelude+extra+'\nend\n')
                result = subprocess.run(['luau-analyze', '-j1', str(path)], capture_output=True, text=True)
                if valid:
                    self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
                else:
                    self.assertNotEqual(result.returncode, 0, extra)
                    self.assertIn('TypeError', result.stdout+result.stderr)


if __name__ == '__main__':
    unittest.main()
