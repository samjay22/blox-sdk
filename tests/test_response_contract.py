"""Independent response-nullability audit and read/write codegen regression tests."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import gen
from response_contract import curate_reads, members, type_inclusions


class ResponseContractTests(unittest.TestCase):
    """Protect tolerant reads without permitting nullable or unknown request members."""

    def test_java_nullability_and_inclusion(self) -> None:
        """Distinguish primitives, wrappers, nested annotations and Jackson ALWAYS overrides."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / 'Response.java'
            path.write_text('''public record Response(boolean active, Long count,
                @NotNull List<@NotNull String> names, List<@NotNull String> labels,
                @JsonInclude(JsonInclude.Include.ALWAYS) String explicit,
                @NonNull String guaranteed) {}''')
            self.assertEqual(set(members(path)['Response']), {'active','count','names','labels','explicit','guaranteed'})
            resource = root / 'src/main/resources'
            resource.mkdir(parents=True)
            properties = resource / 'application.properties'
            properties.write_text('spring.jackson.default-property-inclusion=non_null\n')
            fields = {name: {'java': typ, 'required': True} for name, typ in {
                'active': 'boolean', 'count': 'Long', 'names': 'List<String>',
                'labels': 'List<String>', 'explicit': 'String', 'guaranteed': 'String',
            }.items()}
            doc = {'types': {'test': {'Response': {'source': 'Response.java', 'fields': fields}}},
                   'endpoints': [{'service': 'test', 'name': 'get', 'responseJava': 'Response'}]}
            with patch('service_contracts.SOURCE_ROOT', root), patch('service_contracts.SOURCES', {'test': root}):
                curate_reads(doc)
                self.assertTrue(fields['count']['responseNullable'])
                self.assertFalse(fields['count']['responseRequired'])
                self.assertFalse(fields['labels']['responseRequired'])
                self.assertTrue(fields['explicit']['responseNullable'])
                self.assertNotIn('responseRequired', fields['explicit'])
                for name in ('active','names','guaranteed'):
                    self.assertNotIn('responseNullable', fields[name])
                snapshot = copy.deepcopy(doc)
                curate_reads(doc)
                self.assertEqual(doc, snapshot)

    def test_shared_read_type_does_not_weaken_writes(self) -> None:
        """Compile nullable response scope, rejecting null/unknown write fields and wrong id types."""
        source = '''--!strict
local Core = require("./src/Types/Core")
local Json = require("./src/Core/Json")
local SDK = require("./src/BloxSDK")
local Types = require("./src/Types/Leaderboards")
local MM = require("./src/Types/Matchmaking")
--- Compile only; never create a client or issue requests.
return function(client: SDK.Client, status: MM.PlayerQueueStatusResponse)
 local _read: Types.RatingConfigRead = {kFactor=1,initialRating=1,floor=0,universeId=Json.null}
 local _id: string = status.userId
 local _time: number | Core.Null = status.queuedAt
 local _modes: {string} | Core.Null = status.gameModeNames
'''
        cases = (
            ('', True),
            ('client.leaderboards:ratingConfigure({path={scope="ranked"},body={kFactor=1,initialRating=1,floor=0,universeId=Json.null}})', False),
            ('local bad: number = status.userId', False),
            ('local bad: number = status.queuedAt', False),
        )
        with tempfile.NamedTemporaryFile(mode='w', suffix='.luau', prefix='read-types-', dir=ROOT) as temporary:
            path = Path(temporary.name)
            for extra, valid in cases:
                path.write_text(source + extra + '\nend\n')
                result = subprocess.run(['luau-analyze','-j1',str(path)], capture_output=True, text=True)
                self.assertEqual(result.returncode == 0, valid, extra + '\n' + result.stdout + result.stderr)

    def test_type_inclusion_is_not_inferred_from_a_different_dto(self) -> None:
        """Class ALWAYS overrides global NON_NULL; member NON_NULL cannot taint sibling records."""
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'Mixed.java'
            path.write_text('''class Mixed {
                @JsonInclude(JsonInclude.Include.ALWAYS)
                public record Always(String value) {}
                public record Ordinary(@JsonInclude(JsonInclude.Include.NON_NULL) String value) {}
                @JsonInclude(JsonInclude.Include.NON_NULL)
                public record Omitted(String value) {}
            }''')
            self.assertEqual(type_inclusions(path), {'Mixed': None, 'Always': 'ALWAYS', 'Ordinary': None, 'Omitted': 'NON_NULL'})
        self.assertEqual(gen.schema('Optional<Long>'), {'kind': 'nullable', 'item': {'kind': 'number'}})

    def test_all_health_contracts_and_queue_dto_evidence(self) -> None:
        """Assert one minimal health contract and independently known queue wire types/nulls."""
        doc = json.loads((ROOT / 'spec/endpoints.json').read_text())
        for service, definitions in doc['types'].items():
            self.assertEqual(definitions['HealthResponse'], {'fields': {'status': {'java': 'String', 'required': True}}})
            endpoint = next(e for e in doc['endpoints'] if e['id'] == service + '.healthProxy')
            self.assertEqual(endpoint['responseJava'], 'HealthResponse')
        fields = doc['types']['matchmaking']['PlayerQueueStatusResponse']['fields']
        self.assertEqual({n: f['java'] for n, f in fields.items()}, {
            'userId':'String','universeId':'String','inQueue':'boolean','gameModeName':'String',
            'gameModeNames':'List<String>','partyId':'String','queuedAt':'Long'})
        self.assertTrue(all(f['responseRequired'] for f in fields.values()))
        self.assertEqual({n for n, f in fields.items() if f['responseNullable']},
                         {'gameModeName','gameModeNames','partyId','queuedAt'})
        generated = gen.generate(copy.deepcopy(doc))[ROOT / 'src/Types/Leaderboards.luau']
        self.assertIn('export type RatingConfigRead', generated)
        self.assertIn('export type RatingConfigResultValue = RatingConfigRead', generated)


if __name__ == '__main__':
    unittest.main()
