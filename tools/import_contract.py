#!/usr/bin/env python3
"""Import local Java contracts for review. Not used by the reproducible generator/CI."""
from __future__ import annotations
import json
import re
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORK = Path(os.environ.get('BLOX_SOURCE_ROOT', str(ROOT.parent)))
SOURCES = {'auth': WORK / 'srv/src-gas/global-auth-service', 'matchmaking': WORK / 'srv/src-mm', 'codes': WORK / 'srv/src-roblox-code-service', 'party': WORK / 'party'}
CATALOG = dict(zip(SOURCES, ['AuthService', 'MatchmakingService', 'CodeService', 'PartyService']))

def clean(text: str) -> str:
    """Remove Java comments while preserving literals."""
    return re.sub(r'"(?:\\.|[^"\\])*"|/\*.*?\*/|//[^\n]*', lambda m: m[0] if m[0].startswith('"') else '', text, flags=re.S)

def balanced(text: str, start: int, left: str = '(', right: str = ')') -> tuple[str, int]:
    """Read a balanced Java group, ignoring delimiters inside strings."""
    depth, quoted, escaped = 0, False, False
    for i in range(start, len(text)):
        c = text[i]
        if quoted:
            if escaped: escaped = False
            elif c == '\\': escaped = True
            elif c == '"': quoted = False
            continue
        if c == '"': quoted = True
        elif c == left: depth += 1
        elif c == right:
            depth -= 1
            if depth == 0: return text[start + 1:i], i + 1
    raise ValueError('Unbalanced group')

def split(text: str) -> list[str]:
    """Split top-level generic/annotation parameter commas."""
    parts, start, depth, quoted = [], 0, 0, False
    for i, c in enumerate(text):
        if c == '"' and (i == 0 or text[i - 1] != '\\'): quoted = not quoted
        if quoted: continue
        if c in '(<{': depth += 1
        elif c in ')>}': depth -= 1
        elif c == ',' and depth == 0: parts.append(text[start:i].strip()); start = i + 1
    if text[start:].strip(): parts.append(text[start:].strip())
    return parts

def annotations(text: str) -> str:
    """Remove annotations, including nested validation arguments."""
    return re.sub(r'@[\w.]+(?:\([^()]*\))?\s*', '', text)

def scalar(java: str) -> str:
    """Map controller scalar parameters to exact JSON wire categories."""
    if java in ('Boolean', 'boolean'): return 'boolean'
    if java in ('Long', 'long'): return 'id'
    if java in ('Integer', 'int', 'Double', 'double'): return 'number'
    return 'string'

def types_for(service: str, root: Path) -> dict:
    """Extract DTOs, records and nested response classes; retain Java types as provenance."""
    files = list(root.glob('src/main/java/**/dto/*.java'))
    if service != 'auth': files += list((WORK/'srv/src-gas/global-auth-client').glob('src/main/java/**/dto/*.java'))
    else: files = list((WORK/'srv/src-gas/global-auth-client').glob('src/main/java/**/dto/*.java')) + files
    files += list(root.glob('src/main/java/**/abstracts/BaseQueueRequest.java'))
    definitions = {}
    for file in sorted(files):
        text = clean(file.read_text())
        for match in re.finditer(r'(?:class|record|enum)\s+(\w+)(?:\s+extends\s+(\w+))?', text):
            name, parent = match.groups()
            if name.startswith("DataService"): continue  # Unused downstream DTOs are not SDK services.
            if match[0].startswith('enum'):
                b = text.index('{', match.end()); body, _ = balanced(text, b, '{', '}')
                definitions[name] = {'enum': re.findall(r'\b[A-Z][A-Z_]+\b', body.split(';')[0])}; continue
            fields = {}
            if match[0].startswith('record'):
                pos = text.index('(', match.end()); body, _ = balanced(text, pos)
                items = split(body)
            else:
                pos = text.index('{', match.end()); body, _ = balanced(text, pos, '{', '}')
                # Strip method/nested bodies so fields cannot leak into enclosing DTOs.
                top, depth, quote = [], 0, False
                for c in body:
                    if c == '"': quote = not quote
                    if not quote and c == '{': depth += 1
                    if depth == 0: top.append(c)
                    if not quote and c == '}': depth -= 1; top.append('\n' if depth == 0 else '')
                items = re.findall(r'((?:@[\w.]+(?:\([^\n]*?\))?\s*)*private\s+(?!static)(?:transient\s+)?[\w<>?, .@]+\s+\w+\s*(?:=[^;]+)?);', ''.join(top))
            for item in items:
                stripped = annotations(item).replace('private ', '').replace('transient ', '').split('=')[0].strip()
                m = re.match(r'(.+?)\s+(\w+)$', stripped, re.S)
                if not m: raise ValueError((file, item))
                java, field = m.groups()
                if '@JsonIgnore' in item or field.endswith('Present'): continue
                fields[field] = {'java': re.sub(r'\s+', ' ', java.strip()), 'required': bool(re.search(r'@(NotNull|NotBlank|NotEmpty)', item)), 'notBlank': '@NotBlank' in item}
            definitions[name] = {'fields': fields, 'parent': parent, 'source': str(file.relative_to(WORK))}
    return definitions

def endpoints_for(service: str, root: Path) -> list[dict]:
    """Extract mappings, controller guards, request parameters and declared success statuses."""
    result = []
    for file in sorted(root.glob('src/main/java/**/*.java')):
        text = clean(file.read_text())
        if not re.search(r'@(RestController|Controller)\b', text): continue
        cls = text.index('class ')
        head = text[:cls]
        base_match = re.search(r'@RequestMapping\s*\(\s*"([^"]*)"', head)
        base = base_match[1] if base_match else ''
        class_guard = re.search(r'@PreAuthorize\("([^"]+)"\)', head)
        for match in re.finditer(r'@(Get|Post|Put|Patch|Delete|Request)Mapping\b', text[cls:]):
            start = cls + match.end()
            args, end = balanced(text, start) if text[start:start+1] == '(' else ('', start)
            method = match[1].upper()
            if method == 'REQUEST':
                mm = re.search(r'RequestMethod\.(\w+)', args)
                if not mm: continue
                method = mm[1]
            pm = re.search(r'"([^"\n]*)"', args)
            path = base + (pm[1] if pm else '')
            sig = re.search(r'public\s+([\w<>?, .]+?)\s+(\w+)\s*\(', text[end:])
            if not sig: raise ValueError((file, path))
            response, name = sig.groups()
            params, sigend = balanced(text, end + sig.end() - 1)
            blockstart = text.index('{', sigend)
            body, _ = balanced(text, blockstart, '{', '}')
            guard_match = re.search(r'@PreAuthorize\("([^"]+)"\)', text[end:end + sig.start()])
            guard = guard_match[1] if guard_match else class_guard[1] if class_guard else ''
            route = dict(id=service+'.'+name, name=name, service=service, serviceName=CATALOG[service], method=method, path=path, pathParams=[], queryParams=[], bodyType=None, bodyRequired=False, javaResponse=response.strip(), source=str(file.relative_to(WORK)), guard=guard)
            for param in split(params):
                a = re.search(r'@(PathVariable|RequestParam|RequestBody)\b', param)
                if not a: continue
                astart = a.end()
                aa, _ = balanced(param, astart) if param[astart:astart+1] == '(' else ('', astart)
                from service_contracts import strip_annotations
                stripped = strip_annotations(param)
                typ, var = stripped.rsplit(' ', 1)
                if a[1] == 'RequestBody':
                    route['bodyType'] = typ; route['bodyRequired'] = not re.search(r'required\s*=\s*false', aa)
                else:
                    wire = re.search(r'(?:value\s*=\s*|name\s*=\s*|^)"([^"]+)"', aa)
                    wire_name = wire[1] if wire else var
                    required = a[1] == 'PathVariable' or (not re.search(r'required\s*=\s*false', aa) and 'defaultValue' not in aa)
                    info = dict(name=wire_name, type=scalar(typ), required=required, java=typ)
                    default = re.search(r'defaultValue\s*=\s*"([^"]*)"', aa)
                    if default: info['default'] = default[1]
                    route['pathParams' if a[1] == 'PathVariable' else 'queryParams'].append(info)
            public = path in ('/health','/metrics','/api/auth/health','/api/auth/login','/api/auth/logout','/api/auth/refresh','/api/auth/token/validate','/api/auth/password/reset/request','/api/auth/password/reset/confirm') or (service=='auth' and path=='/api/auth/accounts' and method=='POST')
            level = 'READ' if method in ('GET','HEAD') or path in ('/api/matchmaking/queue/status/bulk','/api/matchmaking/validate') else 'READ_WRITE'
            role = None
            if 'SUPER_ADMIN' in guard: role='SUPER_ADMIN'
            elif 'UNIVERSE_ADMIN' in guard and "'UNIVERSE'" not in guard and 'SERVICE_' not in guard: level='ADMIN'
            elif "'ADMIN'" in guard and 'UNIVERSE' not in guard and 'SERVICE_' not in guard: role='ADMIN'
            if service=='matchmaking' and (name in ('updateGameMode','deleteGameMode','processMatchmaking')): level='ADMIN'
            if service=='auth' and ('/accounts' in path or '/password/change' in path) and not public: role = role or 'USER'
            route.update(minimumLevel=None if public or role else level, requiredRole=role, authKinds=['none','serviceAccount','user','custom'] if public else ['user','custom'] if role else ['serviceAccount','user','custom'], idempotent=method in ('GET','HEAD','PUT','DELETE'), retryable=method in ('GET','HEAD'), cacheable=method=='GET', responseFormat='text' if response.strip() in ('String','ResponseEntity<String>') else 'json')
            if '/roblox/keys' in path or service=='auth' and '/universes' not in path: route['cacheable']=False
            if service=='party' and '/poll/' in path: route['cacheable']=False
            statuses = [201 if 'HttpStatus.CREATED' in body else 200]
            if 'noContent()' in body: statuses = ([200,204] if 'ResponseEntity.ok(' in body else [204])
            if 'notFound()' in body: statuses += [404]
            route['statuses'] = sorted(set(statuses)); route['responseType'] = name[0].upper()+name[1:]+'Response'
            route['queryParams'].sort(key=lambda p:p['name'])
            result.append(route)
    return result

def main() -> None:
    """Write an auditable initial spec; curated amendments are applied separately."""
    all_routes = []
    all_types = {}
    for service, root in SOURCES.items():
        all_routes.extend(endpoints_for(service, root)); all_types[service] = types_for(service, root)
    (ROOT/'.test-build').mkdir(exist_ok=True)
    (ROOT/'.test-build/imported.json').write_text(json.dumps({'endpoints':all_routes,'types':all_types}, indent=2)+'\n')
    for e in all_routes:
        print(e['id'], e['method'],e['path'],e['bodyType'],e['javaResponse'],e['minimumLevel'],e['requiredRole'],','.join(p['name'] for p in e['queryParams']))
if __name__ == '__main__': main()
