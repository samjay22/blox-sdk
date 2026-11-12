"""Release metadata, public documentation and native-example verification regressions."""
from __future__ import annotations

import re
import os
import runpy
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = runpy.run_path(str(ROOT/'tools/gen-docs'))
EXAMPLES = runpy.run_path(str(ROOT/'tools/verify-examples.py'))


class ReleaseTests(unittest.TestCase):
    """Verify independently observable release contracts without network or application startup."""

    def test_version(self) -> None:
        """The package, runtime and release documentation agree on 7.0.0."""
        metadata = tomllib.loads((ROOT/'wally.toml').read_text())
        self.assertEqual(metadata['package']['version'], '7.0.0')
        self.assertEqual(metadata['package']['realm'], 'server')
        self.assertIn('SDK.version = "7.0.0"', (ROOT/'src/BloxSDK.luau').read_text())
        for name in ('CHANGELOG.md', 'docs/CHANGELOG.md'):
            self.assertIn('## 7.0.0', (ROOT/name).read_text())

    def test_documented_service_methods(self) -> None:
        """Every source method and exported DTO alias is represented in its generated page."""
        pages = DOCS['outputs']()
        self.assertEqual(pages, DOCS['outputs']())
        for path in (ROOT/'src/Services').glob('*.luau'):
            page = pages[ROOT/f'docs/api/{path.stem.lower()}.md']
            methods = re.findall(r'^function Service\.(\w+)\(', path.read_text(), re.M)
            self.assertEqual(len(methods), len(set(methods)), path.name)
            for method in methods:
                self.assertTrue(method[0].islower(), method)
                if method != 'new':
                    self.assertIn(f'### `Service.{method}`', page)
            for alias in re.findall(r'^export type (\w+)', (ROOT/'src/Types'/path.name).read_text(), re.M):
                self.assertIn(f'export type {alias}', page)

    def test_drift_is_read_only_and_detects_extras(self) -> None:
        """Missing, changed and extra documentation fails check mode without silent overwrites."""
        sync = DOCS['synchronize']
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            path = directory/'api.md'
            self.assertEqual(sync({path: 'expected'}, directory, True), [path])
            self.assertFalse(path.exists())
            self.assertEqual(sync({path: 'expected'}, directory, False), [])
            self.assertEqual(sync({path: 'expected'}, directory, True), [])
            path.write_text('modified')
            self.assertEqual(sync({path: 'expected'}, directory, True), [path])
            self.assertEqual(path.read_text(), 'modified')
            extra = directory/'extra.md'
            extra.write_text('untracked page')
            self.assertIn(extra, sync({path: 'expected'}, directory, True))

    def test_signature_extraction(self) -> None:
        """Nested callback signatures are preserved, not truncated at their inner parenthesis."""
        source = '--- Observe changes.\nfunction Client.watch(self: Client, callback: (number) -> ()): Connection\n return nil\nend\n'
        declarations = DOCS['declarations'](source)
        self.assertEqual(declarations, [('Client.watch', 'Client.watch(self: Client, callback: (number) -> ()): Connection', 'Observe changes.')])
        generic = '--- Keep element types.\nfunction Json.array<T>(value: {T}): {T}\n return value\nend\n'
        self.assertEqual(DOCS['declarations'](generic)[0][1], 'Json.array<T>(value: {T}): {T}')
        root_page = DOCS['outputs']()[ROOT/'docs/api/client.md']
        for name in ('array', 'object', 'pages', 'cursorPages', 'serviceAccount', 'userSession', 'memoryTokenStore'):
            self.assertIn(f'### `SDK.{name}`', root_page)

    def test_native_import_projection(self) -> None:
        """Only import syntax changes during native script type checking; unknown imports fail closed."""
        source = 'local SDK = require(game.ServerStorage.BloxSDK)\nlocal client = require(script.Parent.Client)\nclient.fields:schema()\n'
        expected = 'local SDK = require("../../src/BloxSDK")\nlocal client = require("./Client")\nclient.fields:schema()\n'
        self.assertEqual(EXAMPLES['project'](source), expected)
        with self.assertRaises(ValueError):
            EXAMPLES['project']('local bad = require(script.Parent.Unmapped)')

    def test_pinned_lune_cli_refuses_without_live_inputs(self) -> None:
        """The actual pinned CLI forwards consent after its separator and refuses missing env offline."""
        env = {key: value for key, value in os.environ.items() if not key.startswith('BLOX_')}
        for args, expected in (([], 'explicit --yes-live required'), (['--', '--yes-live'], 'missing BLOX_BASE_URL')):
            result = subprocess.run(['lune', 'run', 'tools/live-smoke.luau', *args], cwd=ROOT, env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
            self.assertIn(expected, result.stdout)
            self.assertIn('no requests sent', result.stdout)


if __name__ == '__main__':
    unittest.main()
