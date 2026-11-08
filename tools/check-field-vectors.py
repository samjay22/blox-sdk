#!/usr/bin/env python3
"""Cross-check shared JSON vectors against freshly compiled actual server TypeSystem sources offline."""
from __future__ import annotations
import argparse
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


def cached(group: str, artifact: str, version: str) -> Path:
    """Require a concrete cached artifact; never invoke Maven or resolve/download dependencies."""
    file=Path.home()/'.m2/repository'/group/artifact/version/f'{artifact}-{version}.jar'
    if not file.is_file(): raise FileNotFoundError(f'Offline oracle requires cached {artifact} {version}: {file}')
    return file


def main() -> None:
    """Compile pure backend validators in a temporary directory and compare every shared vector."""
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backend',type=Path,default=Path(os.environ.get('BLOX_SOURCE_ROOT', str(ROOT.parent)))/'svc/fields-service')
    args=parser.parse_args()
    java=shutil.which('java') or '/opt/homebrew/opt/openjdk/bin/java'
    javac=shutil.which('javac') or '/opt/homebrew/opt/openjdk/bin/javac'
    # macOS system java can be a launcher stub; use installed Homebrew explicitly when present.
    if Path('/opt/homebrew/opt/openjdk/bin/javac').is_file():
        java='/opt/homebrew/opt/openjdk/bin/java';javac='/opt/homebrew/opt/openjdk/bin/javac'
    jars=[cached('com/fasterxml/jackson/core',a,'2.18.2') for a in ('jackson-core','jackson-databind','jackson-annotations')]
    jars += [cached('org/springframework','spring-web','6.2.1')]
    jars += [cached('jakarta/validation','jakarta.validation-api','3.0.2')]
    sources=[args.backend/'src/main/java/sam/tech/fields'/f'{name}.java' for name in ('TypeSystem','FieldsException','JsonSupport','Models','integrations/IntegrationBindings')]
    # Models references pure Jackson helpers; include them when present in the backend checkout.
    for name in ('ReferenceStringDeserializer', 'StrictLongDeserializer'):
        deserializer = args.backend/'src/main/java/sam/tech/fields'/f'{name}.java'
        if deserializer.is_file(): sources.append(deserializer)
    for source in sources:
        if not source.is_file(): raise FileNotFoundError(source)
    vectors=[ROOT/'tests/vectors'/name for name in ('type-system.json','bindings.json')]
    with tempfile.TemporaryDirectory(prefix='blox-fields-vectors-',dir='/private/tmp') as directory:
        cp=os.pathsep.join(map(str,jars))
        subprocess.run([javac,'-Xlint:all','-proc:none','-cp',cp,'-d',directory,*map(str,sources),str(ROOT/'tools/java/FieldsVectors.java')],check=True,capture_output=True,text=True)
        for vector in vectors:
            result=subprocess.run([java,'-cp',directory+os.pathsep+cp,'FieldsVectors',str(vector)],check=True,capture_output=True,text=True)
            actual=json.loads(result.stdout);cases=json.loads(vector.read_text())
            assert len(actual)==len(cases)
            for case,value in zip(cases,actual,strict=True):
                assert value['name']==case['name']
                expected={'code':case['code']} if 'code' in case else {'value':case['expected']}
                observed={k:v for k,v in value.items() if k!='name'}
                assert observed==expected, f'{case["name"]}: expected {expected!r}, got {observed!r}'
            print(f'PASS {len(cases)} shared {vector.stem} JSON vectors against actual freshly compiled server validators (offline; no service startup)')

if __name__=='__main__':main()
