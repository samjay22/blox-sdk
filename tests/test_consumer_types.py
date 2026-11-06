"""Independent Fields consumer contract and negative static typing checks, entirely offline."""
from __future__ import annotations
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ConsumerTypesTests(unittest.TestCase):
    """Check the exact consumer surface, not only self-generated endpoint fixtures."""

    def test_static_board_bindings(self) -> None:
        """Compile valid bindings/previews and reject DELTA keep, bad enums and response types."""
        prelude='''--!strict
local SDK = require("./src/BloxSDK")
local Types = require("./src/Fields/Types")
local Fields = require("./src/Types/Fields")
--- Compile-only public API contract; no service or application starts.
return function(client: SDK.Client, response: Fields.Preview)
 local value: Types.LeaderboardBinding = {board="wins",submit="VALUE",keep="BEST",order="ASC",reset="WEEKLY",displayName="Wins"}
 local delta: Types.LeaderboardBinding = {board="wins",submit="DELTA"}
 local _result = client.fields:previewBoard({body={id="Stats.Wins",type={kind="int"},binding=value}})
 local _bindings: Types.Bindings = {leaderboards={value,delta}}
 local _min: number = response.effectiveSettings.minScore
 if response.willWiden then local _max: number = response.willWiden.maxScore end
'''
        with tempfile.TemporaryDirectory(prefix='board-types-', dir=ROOT/'.test-build') as temporary:
            path=ROOT/(Path(temporary).name+'.luau')
            try:
                for extra, valid in (
                    ('',True),
                    ('local bad: Types.LeaderboardBinding = {board="wins",submit="DELTA",keep="LAST"}',False),
                    ('local bad: Types.LeaderboardBinding = {board="wins",submit="VALUE",order="desc"}',False),
                    ('local bad: Types.LeaderboardBinding = {board="wins",submit="VALUE",reset="YEARLY"}',False),
                    ('local bad: Types.LeaderboardBinding = {board="wins",submit="VALUE",displayName=3}',False),
                    ('client.fields:previewBoard({body={id="Stats.Wins",type={kind="int"}}})',False),
                    ('local bad: string = response.effectiveSettings.minScore',False),
                ):
                    path.write_text(prelude+extra+'\nend\n')
                    result=subprocess.run(['luau-analyze','-j1',str(path)],capture_output=True,text=True)
                    if valid:self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                    else:
                        self.assertNotEqual(result.returncode,0,extra)
                        self.assertIn('TypeError',result.stdout+result.stderr)
            finally:path.unlink(missing_ok=True)

    def test_codes_contract(self) -> None:
        """Awards are direct subject-free lists and redemption contains a required typed receipt."""
        types = json.loads((ROOT/'spec/endpoints.json').read_text())['types']['codes']
        self.assertEqual(set(types['RedeemCodeResponse']['fields']), {
            'redemptionId','codeId','code','universeId','robloxUserId','transaction','replayed','redeemedAt'})
        for info in types['RedeemCodeResponse']['fields'].values():
            self.assertTrue(info['required'])
        for name in ('CreateCodeRequest','UpdateCodeRequest','CodeDto','CodeRedemptionDto'):
            self.assertEqual(types[name]['fields']['award']['java'], 'List<Fields.PlayerOperation>')
        self.assertEqual(types['RedeemCodeResponse']['fields']['transaction']['java'], 'FieldsTransactionResult')
        self.assertEqual(set(types['FieldsTransactionResult']['fields']), {'txId','replayed','results','seq'})
        self.assertIn('pendingRedemptions', types['CodeDto']['fields'])

    def test_postman_award_grammar(self) -> None:
        """Every backend Postman award uses the exact op discriminator and no subject envelope."""
        collection = json.loads((ROOT.parent/'srv/src-roblox-code-service/postman/roblox-code-service.postman_collection.json').read_text())
        def requests(items: list[dict]) -> list[str]:
            """Collect nested request bodies without substituting credentials or running requests."""
            result = []
            for item in items:
                result.extend(requests(item.get('item', [])))
                raw = item.get('request', {}).get('body', {}).get('raw')
                if raw:
                    result.append(raw)
            return result
        import re
        awards = 0
        for raw in requests(collection['item']):
            body = json.loads(re.sub(r'(?<!")\{\{\w+\}\}', '123', raw))
            if 'award' in body:
                awards += 1
                self.assertIsInstance(body['award'], list)
                self.assertEqual(body['maxRedemptionsPerUser'], 1)
                for op in body['award']:
                    self.assertIn('field', op)
                    self.assertIn('op', op)
                    self.assertNotIn('subject', op)
        self.assertGreaterEqual(awards, 3)

    def test_static_awards(self) -> None:
        """Reject subjects, untyped operands and receipt mismatches without weakening public APIs."""
        prelude = '''--!strict
local SDK = require("./src/BloxSDK")
local Fields = require("./src/Fields/Types")
local Codes = require("./src/Types/Codes")
--- Compile only; no client is constructed or requests sent.
return function(client: SDK.Client, receipt: Codes.RedeemCodeResponse)
 local operation: Fields.PlayerOperation = {field="Currency.Gems",op="ADD",delta=10}
 local award = client.codes:Award(123):Add("Currency.Gems",10):MapAdd("Inventory.Items","SWORD",1)
 local _built = award:build()
 local _result = client.codes:createCode({code="WELCOME",award={operation}})
 local _tx: string = receipt.transaction.txId
'''
        with tempfile.TemporaryDirectory(prefix='consumer-types-', dir=ROOT/'.test-build') as temporary:
            path = ROOT/(Path(temporary).name+'.luau')
            try:
                for extra, valid in (
                    ('', True),
                    ('local bad: Fields.PlayerOperation = {field="Currency.Gems",op="ADD",delta="10"}', False),
                    ('local bad: Fields.PlayerOperation = {field="Currency.Gems",op="RESET",subject=7}', False),
                    ('award:Add("Currency.Gems","10")', False),
                    ('local bad: number = receipt.transaction.txId', False),
                ):
                    path.write_text(prelude+extra+'\nend\n')
                    result = subprocess.run(['luau-analyze', '-j1', str(path)], capture_output=True, text=True)
                    if valid:
                        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
                    else:
                        self.assertNotEqual(result.returncode, 0, extra)
                        self.assertIn('TypeError', result.stdout+result.stderr)
            finally:
                path.unlink(missing_ok=True)


if __name__ == '__main__':
    unittest.main()
