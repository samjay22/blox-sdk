"""Guard the native HTTP boundary independently of endpoint fixtures."""
from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class BatchBoundaryTests(unittest.TestCase):
    """Fail if production modules gain a second backend or direct-request call site."""

    def test_only_batcher_dispatches_the_backend(self) -> None:
        """Adapters expose native HTTP; only Batcher may invoke a Backend."""
        calls = []
        for path in (ROOT / 'src').rglob('*.luau'):
            if 'Testing' in path.parts:
                continue
            for match in re.finditer(r'(?:self\.|config\.)?backend\s*\(', path.read_text()):
                # The constructor obtains the adapter; this is not a native send.
                if path.name == 'BloxSDK.luau':
                    continue
                if path.name == 'Roblox.luau' and 'function Roblox.' in path.read_text()[max(0, match.start()-20):match.start()]:
                    continue
                calls.append(path.relative_to(ROOT).as_posix())
        self.assertEqual(calls, ['src/Core/Batcher.luau'])
        source = (ROOT / 'src/Core/Batcher.luau').read_text()
        self.assertIn('Url = self.url', source)
        self.assertIn('"/batch-service/api/batch"', (ROOT / 'src/BloxSDK.luau').read_text())
        self.assertNotIn('backend(', (ROOT / 'src/Core/Transport.luau').read_text())

    def test_smoke_keeps_header_normalization_and_sdk_transport(self) -> None:
        """The real smoke adapter retains Lune's repeated-header normalization."""
        source = (ROOT / 'tools/live-smoke.luau').read_text()
        self.assertEqual(source.count('net.request('), 1)
        self.assertIn('url = request.Url', source)
        self.assertIn('table.concat(value, ", ")', source)
        self.assertIn('pcall(SDK.new', source)


if __name__ == '__main__':
    unittest.main()
