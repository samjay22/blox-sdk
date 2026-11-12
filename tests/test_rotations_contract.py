"""Acceptance checks for the rotations contract: seven plain routes, no stored state, no snapshot member."""
from __future__ import annotations
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = '/api/fields/universes/{universeId}/rotations'


class RotationsContractTests(unittest.TestCase):
    """Keep the small surface explicit so it cannot quietly grow back."""

    def setUp(self) -> None:
        """Read checked-in contracts without HTTP or backend startup."""
        self.doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        self.routes = {e['name']: e for e in self.doc['endpoints'] if e['service'] == 'fields' and '/rotations' in e['path']}
        self.types = self.doc['types']['fields']
        self.vectors = json.loads((ROOT/'tests/vectors/rotations.json').read_text())

    def test_exactly_seven_routes_with_levels_and_methods(self) -> None:
        """List/get/put/delete, current, schedule and a read-only preview; nothing else mentions rotations."""
        expected = {
            'listRotations': ('GET', BASE, 'READ'),
            'getRotation': ('GET', BASE+'/{key}', 'READ'),
            'putRotation': ('PUT', BASE+'/{key}', 'READ_WRITE'),
            'deleteRotation': ('DELETE', BASE+'/{key}', 'READ_WRITE'),
            'currentRotation': ('GET', BASE+'/{key}/current', 'READ'),
            'rotationSchedule': ('GET', BASE+'/{key}/schedule', 'READ'),
            'previewRotation': ('POST', BASE+'/preview', 'READ'),
        }
        self.assertEqual({k: (v['method'], v['path'], v['minimumLevel']) for k, v in self.routes.items()}, expected)
        for name, route in self.routes.items():
            self.assertEqual(route['statuses'], [200], name)
            self.assertFalse(route['cacheable'], name)
            self.assertNotIn('|', route['path'])
        self.assertEqual({v['endpoint'] for v in self.vectors['vectors']}, {'fields.'+n for n in expected})

    def test_retired_randomness_surface_is_gone(self) -> None:
        """Tables, generators, rolls, claims, stock and history no longer exist anywhere in the contract."""
        for e in self.doc['endpoints']:
            if e['service'] != 'fields': continue
            for word in ('random', 'generator', 'claim', 'stock', 'advance', 'reroll', 'odds'):
                self.assertNotIn(word, e['path'].lower(), e['id'])
        for name in self.types:
            for word in ('Random', 'Generator', 'Pick', 'Claim', 'Stock', 'RotationActive', 'RotationInstance', 'RotationKind'):
                self.assertNotIn(word, name, name)
        self.assertNotIn('rotations', self.types['RuntimeSnapshot']['fields'])

    def test_read_routes_retry_and_the_preview_is_safe_to_retry(self) -> None:
        """Reads and the pure preview are idempotent; saves and deletes are not retried blindly."""
        for name in ('listRotations', 'getRotation', 'currentRotation', 'rotationSchedule', 'previewRotation'):
            self.assertTrue(self.routes[name]['retryable'], name)
        for name in ('putRotation', 'deleteRotation'):
            self.assertFalse(self.routes[name]['retryable'], name)

    def test_wire_types_match_the_documented_definition(self) -> None:
        """Only the documented fields exist, with defaults filled in on responses."""
        def fields(name: str) -> dict:
            return {k: v['required'] for k, v in self.types[name]['fields'].items()}
        self.assertEqual(fields('RotationInput'), {'universeId': False, 'items': True, 'every': True, 'show': False, 'order': False, 'startsAt': False, 'expectedVersion': False})
        self.assertEqual(fields('RotationPreviewInput'), {'universeId': False, 'key': True, 'items': True, 'every': True, 'show': False, 'order': False, 'startsAt': False, 'count': False})
        self.assertEqual(fields('Rotation'), {k: True for k in ('key', 'version', 'items', 'every', 'show', 'order', 'startsAt', 'updatedAt', 'current')})
        self.assertEqual(fields('RotationCurrent'), {k: True for k in ('key', 'version', 'current', 'next')})
        self.assertEqual(fields('RotationPeriod'), {k: True for k in ('startsAt', 'endsAt', 'items')})
        self.assertEqual(fields('RotationItem'), {'id': True, 'data': False})
        self.assertEqual(self.types['RotationOrder'], {'enum': ['inOrder', 'shuffled']})

    def test_goldens_are_internally_consistent(self) -> None:
        """The shared vectors describe contiguous periods and agree between current, schedule and rotation."""
        current, schedule, rotation = self.vectors['current'], self.vectors['schedule'], self.vectors['rotation']
        self.assertEqual(current['current']['endsAt'], current['next']['startsAt'])
        periods = schedule['periods']
        for a, b in zip(periods, periods[1:]):
            self.assertEqual(a['endsAt'], b['startsAt'])
        self.assertEqual(periods[0], current['current'])
        self.assertEqual(rotation['current'], current['current'])
        self.assertEqual(rotation['version'], current['version'])
        self.assertEqual(rotation['every'], '1h')


if __name__ == '__main__':
    unittest.main()
