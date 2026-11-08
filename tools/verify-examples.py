#!/usr/bin/env python3
"""Type-check native Roblox scripts by changing only their Instance require expressions."""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def project(source: str) -> str:
    """Resolve the two documented native imports to the identical portable modules."""
    source = source.replace('require(game.ServerStorage.BloxSDK)', 'require("../../src/BloxSDK")')
    source = source.replace('require(script.Parent.Client)', 'require("./Client")')
    if re.search(r'require\((?:game|script)\b', source):
        raise ValueError('Unmapped native import in server example')
    return source


def main() -> None:
    """Analyze every native example against the real SDK signatures without running any script."""
    directory = ROOT/'.test-build/server-examples'
    directory.mkdir(parents=True, exist_ok=True)
    paths = []
    for path in sorted((ROOT/'examples/server').glob('*.luau')):
        target = directory/path.name
        target.write_text(project(path.read_text()))
        paths.append(str(target))
    subprocess.run(['luau-analyze', '-j1', *paths], cwd=ROOT, check=True)
    print(f'Type-checked {len(paths)} native server examples (import-only projection)')


if __name__ == '__main__':
    main()
