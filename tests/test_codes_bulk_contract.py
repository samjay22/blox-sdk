"""Independent F5 wire-contract, generator and strict consumer typing checks."""
from __future__ import annotations
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))


class BulkCodesTests(unittest.TestCase):
    """Keep the public SDK aligned with the shared bulk/batch contract, offline."""

    def test_wire_contract(self) -> None:
        """Require exact fields, header-only replay keys, ADMIN access and raw CSV exports."""
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        endpoints = {e['id']: e for e in doc['endpoints']}
        bulk = endpoints['codes.bulkCreateCodes']
        self.assertEqual((bulk['method'], bulk['path'], bulk['statuses']), ('POST', '/api/codes/bulk', [201]))
        self.assertEqual(bulk['minimumLevel'], 'ADMIN')
        self.assertTrue(bulk['idempotencyHeader'])
        self.assertFalse(bulk['retryable'])
        self.assertFalse(bulk['cacheable'])
        fields = doc['types']['codes']['BulkCreateCodesRequest']['fields']
        self.assertEqual(set(fields), {'universeId', 'count', 'prefix', 'length', 'name', 'description',
                                       'award', 'maxGlobalRedemptions', 'startsAt', 'expiresAt', 'active', 'metadata'})
        self.assertEqual({name for name, f in fields.items() if f['required']}, {'universeId', 'count', 'name', 'award'})
        self.assertEqual(fields['award']['java'], 'List<Fields.PlayerOperation>')
        self.assertEqual(set(doc['types']['codes']['BulkCreateCodesResponse']['fields']), {'batchId', 'count', 'codes'})
        self.assertEqual(set(doc['types']['codes']['BulkCode']['fields']), {'id', 'code'})
        self.assertIn('batchId', {p['name'] for p in endpoints['codes.searchCodes']['queryParams']})
        self.assertTrue(doc['types']['codes']['CodeDto']['fields']['batchId']['nullable'])
        export = endpoints['codes.exportBatch']
        self.assertEqual((export['method'], export['path']), ('GET', '/api/codes/batches/{batchId}/export'))
        self.assertEqual(export['minimumLevel'], 'ADMIN')
        self.assertEqual((export['responseFormat'], export['responseContentType'], export['responseJava']), ('text', 'text/csv', 'String'))

    def test_shared_contract_overlay_is_repeatable(self) -> None:
        """Source refresh cannot remove F5 or duplicate its routes during concurrent backend work."""
        from codes_bulk_contract import curate
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        first = copy.deepcopy(doc)
        curate(first)
        second = copy.deepcopy(first)
        curate(second)
        self.assertEqual(first, second)
        self.assertEqual(len({(e['service'], e['method'], e['path']) for e in second['endpoints']}), len(second['endpoints']))

    def test_static_bulk_calls(self) -> None:
        """Compile valid batch use and reject missing required fields and incorrect public types."""
        prelude = '''--!strict
local SDK = require("./src/BloxSDK")
local Codes = require("./src/Types/Codes")
--- Compile only; no client startup, credentials or HTTP.
return function(client: SDK.Client, response: Codes.BulkCreateCodesResponse)
 local _result = client.codes:createBatch({count=1,name="Campaign",award=client.codes:award():add("Currency.Gems",100),idempotencyKey="persisted-batch"})
 local _page = client.codes:list({batchId=response.batchId})
 local csv = client.codes:exportBatch(response.batchId)
 if csv.ok then local _text: string = csv.value end
 local _id: number = response.codes[1].id
'''
        (ROOT / '.test-build').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='bulk-code-types-', dir=ROOT / '.test-build') as temporary:
            path = ROOT / (Path(temporary).name + '.luau')
            try:
                for extra, valid in (
                    ('', True),
                    ('client.codes:createBatch({count=1,name="Campaign",award={}})', True),
                    ('client.codes:createBatch({count=1,award={}})', False),
                    ('client.codes:createBatch({count="1",name="Campaign",award={}})', False),
                    ('client.codes:createBatch({count=1,name="Campaign",award={},idempotencyKey=1})', False),
                    ('client.codes:exportBatch(1)', False),
                    ('local bad: string = response.codes[1].id', False),
                ):
                    path.write_text(prelude + extra + '\nend\n')
                    result = subprocess.run(['luau-analyze', '-j1', str(path)], capture_output=True, text=True)
                    if valid:
                        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    else:
                        self.assertNotEqual(result.returncode, 0, extra)
                        self.assertIn('TypeError', result.stdout + result.stderr)
            finally:
                path.unlink(missing_ok=True)


if __name__ == '__main__':
    unittest.main()
