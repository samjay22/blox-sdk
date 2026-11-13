"""Independent static accessor goldens and negative Luau compilation checks (offline)."""
from __future__ import annotations
import copy
import json
import re
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from gen_field_types import generate


class FieldCodegenTests(unittest.TestCase):
    """Exercise deterministic schema specialization and prove typed accessors reject misuse."""
    def setUp(self) -> None:
        """Load the saved contract schema without network or service access."""
        self.schema=json.loads((ROOT/'tests/vectors/schema.json').read_text())

    def test_golden(self) -> None:
        """Compare every generated file, including accessor methods, with independent checked-in goldens."""
        files=generate(self.schema,'../../../src')
        golden=ROOT/'tests/golden/fields'
        self.assertEqual(set(files),{str(p.relative_to(golden)) for p in golden.rglob('*.luau')})
        for name,text in files.items():self.assertEqual(text,(golden/name).read_text(),name)
        self.assertEqual(files,generate(copy.deepcopy(self.schema),'../../../src'))

    def test_lifecycle_selection(self) -> None:
        """Archived aliases remain visible but accessors and document omit them."""
        files=generate(self.schema,'../../../src')
        self.assertIn('export type Field_Old',files['FieldTypes.luau'])
        self.assertNotIn('Accessor_Field_Old',files['Typed.luau'])
        self.assertNotIn('function Accessor.Set',files['Accessors/Field_Total.luau'])
        self.assertIn('function Accessor.mapAdd',files['Accessors/Field_Inventory_D_Items.luau'])
        self.assertIn('function Accessor.append',files['Accessors/Field_Characters.luau'])

    def test_item_list_field(self) -> None:
        """A bitmap field is a stored hex string with grant/revoke/replace accessors, and no list accessors."""
        schema=copy.deepcopy(self.schema)
        schema['definitions'].append({'id':'Gear.Owned','status':'ACTIVE','type':{'kind':'bitmap','source':'Equipment','maxMembers':64}})
        files=generate(schema,'../../../src')
        self.assertIn('export type Field_Gear_D_Owned = string',files['FieldTypes.luau'])
        accessor=files['Accessors/Field_Gear_D_Owned.luau']
        for method in ('grant','revoke','replace'):
            self.assertIn(f'function Accessor.{method}(_self: unknown, tx: Transaction.Transaction, members: {{string}})',accessor)
            self.assertIn(f'tx:{method}("Gear.Owned",members)',accessor)
        for absent in ('append','setAdd','mapAdd','add'):
            self.assertNotIn(f'function Accessor.{absent}(',accessor)
        self.assertEqual(generate(schema,'../../../src'),generate(copy.deepcopy(schema),'../../../src'))

    def test_bindings_do_not_change_field_value_types(self) -> None:
        """Binding DTO metadata does not alter schema-specialized value/accessor declarations."""
        original=generate(self.schema,'../../../src')
        for definition in self.schema['definitions']:
            if definition.get('type',{}).get('kind')=='int':
                definition['bindings']={'leaderboards':[{'board':'wins','submit':'VALUE','keep':'BEST',
                    'order':'DESC','reset':'WEEKLY','displayName':'Wins'}]}
        updated=generate(self.schema,'../../../src')
        self.assertEqual(set(original),set(updated))
        for name in original:
            # Provenance must change with metadata, but value/accessor declarations must not.
            self.assertEqual(re.sub(r'sha256=[0-9a-f]{64}', 'sha256=HASH', original[name]),
                             re.sub(r'sha256=[0-9a-f]{64}', 'sha256=HASH', updated[name]))

    def test_collisions_and_injection(self) -> None:
        """Invalid identifiers cannot inject source or silently replace namespaces."""
        for identifier in ('Currency','Currency.Gems','Bad";error(1)','Bad..Name'):
            schema=copy.deepcopy(self.schema)
            schema['definitions'].append({'id':identifier,'type':{'kind':'int'}})
            with self.assertRaises(ValueError):generate(schema,'../../../src')

    def test_roblox_projection(self) -> None:
        """Emit Instance requires without evaluating arbitrary expressions from a schema or option."""
        files=generate(self.schema,'../../../src','game.ServerScriptService.BloxSDK')
        self.assertIn('require(script.Parent.Accessors.Field_Currency_D_Gems)',files['Typed.luau'])
        self.assertIn('require(script.Parent.Parent.FieldTypes)',files['Accessors/Field_Currency_D_Gems.luau'])
        self.assertIn('require(game.ServerScriptService.BloxSDK.Fields.Transaction)',files['Accessors/Field_Currency_D_Gems.luau'])
        with self.assertRaises(ValueError):generate(self.schema,'../../../src','game;error("injection")')
        schema=copy.deepcopy(self.schema);schema['universeId']='123\nerror("injection")'
        with self.assertRaises(ValueError):generate(schema,'../../../src')

    def test_static_negative_and_positive(self) -> None:
        """Wrong accessor operand types fail luau-analyze, while valid typed code compiles cleanly."""
        prelude='''--!strict
local Typed = require("./tests/golden/fields/Typed")
local Transaction = require("./src/Fields/Transaction")
local Profile = require("./src/Fields/Profile")
--- Exercise schema-specialized public APIs without executing any request.
return function(tx: Transaction.Transaction, profile: Profile.Profile)
 local gems: number = Typed.Currency.Gems:get(profile)
'''
        with tempfile.TemporaryDirectory(prefix='field-types-',dir=ROOT/'.test-build') as temp:
            # Relative require resolution must originate at the repository root.
            path=ROOT/(Path(temp).name+'.luau')
            try:
                valid=' Typed.Currency.Gems:add(tx,gems)\n Typed.Inventory.Items:mapAdd(tx,"SWORD",1)\n Typed.Characters:append(tx,{{Id=1,Level=2,Rarity="COMMON"}})\nend\n'
                path.write_text(prelude+valid)
                result=subprocess.run(['luau-analyze','-j1',str(path)],capture_output=True,text=True)
                self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                for bad in ('Typed.Currency.Gems:add(tx,"bad")','Typed.Inventory.Items:mapAdd(tx,"BOW",1)','Typed.Characters:append(tx,{{Id="bad"}})','local wrong: string = Typed.Currency.Gems:get(profile)'):
                    path.write_text(prelude+' local _use=gems\n '+bad+'\nend\n')
                    result=subprocess.run(['luau-analyze','-j1',str(path)],capture_output=True,text=True)
                    self.assertNotEqual(result.returncode,0,bad)
                    self.assertIn('TypeError',result.stdout+result.stderr,bad)
            finally:path.unlink(missing_ok=True)

if __name__=='__main__':unittest.main()
