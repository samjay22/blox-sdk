#!/usr/bin/env python3
"""Project portable modules to Roblox Instance requires without bundling/erasing types."""
from __future__ import annotations
import argparse
import posixpath
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def outputs() -> dict[Path,str]:
    """Return a deterministic mapping of Roblox package paths to transformed sources."""
    result={}
    for path in sorted((ROOT/'src').rglob('*.luau')):
        if path.name=='init.luau':continue
        rel=path.relative_to(ROOT/'src')
        main=str(rel)=='BloxSDK.luau'
        def replace(match: re.Match[str]) -> str:
            """Resolve a static portable require to an equivalent Instance expression."""
            target=posixpath.normpath(str(rel.parent)+'/'+match[1])
            assert not target.startswith('../'),target
            parts=target.split('/')
            expression='script' if main else 'script'+'.Parent'*len(rel.parts)
            return 'require('+expression+'.'+'.'.join(parts)+')'
        text=re.sub(r'require\("([.][^"\n]+)"\)',replace,path.read_text())
        text=text.replace('--!strict\n','--!strict\n-- Generated Roblox projection; edit src/ and run tools/build-roblox.py.\n',1)
        output=ROOT/'roblox'/('init.luau' if main else rel)
        result[output]=text
    return result

def main() -> None:
    """Write the package or check it byte-for-byte with no filesystem mutation."""
    p=argparse.ArgumentParser();p.add_argument('--check',action='store_true');args=p.parse_args()
    generated=outputs();drift=[]
    for path,text in generated.items():
        if args.check:
            if not path.exists() or path.read_text()!=text:drift.append(str(path.relative_to(ROOT)))
        else:path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
    extras=set((ROOT/'roblox').rglob('*.luau'))-set(generated)
    if extras:drift.extend(str(p.relative_to(ROOT)) for p in extras)
    if drift:raise SystemExit('Roblox projection drift: '+', '.join(drift))
    print(f'{"Verified" if args.check else "Projected"} {len(generated)} Roblox modules')
if __name__=='__main__':main()
