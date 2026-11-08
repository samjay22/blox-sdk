"""Offline extraction of the four record-based service contracts; no backend execution."""
from __future__ import annotations
import hashlib
import copy
import re
import os
from pathlib import Path
import import_contract as java

ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = Path(os.environ.get('BLOX_SOURCE_ROOT', str(ROOT.parent)))
SOURCES = {name: SOURCE_ROOT / 'svc' / directory for name, directory in {
    'audit': 'audit-service',
    'leaderboards': 'leaderboard-service', 'fields': 'fields-service',
}.items()}
CATALOG = {'audit': 'AuditService', 'leaderboards': 'LeaderboardService', 'fields': 'FieldsService'}
SOURCES.update(codes=SOURCE_ROOT/'srv/src-roblox-code-service', matchmaking=SOURCE_ROOT/'srv/src-mm')
SOURCES['platform'] = SOURCE_ROOT/'svc/platform-service'
SOURCES['auth'] = SOURCE_ROOT/'srv/src-gas/global-auth-service'


def strip_annotations(text: str) -> str:
    """Remove balanced annotations, including regex strings and type-use annotations."""
    while match := re.search(r'@[\w.]+', text):
        end = match.end()
        if text[end:end+1] == '(':
            _, end = java.balanced(text, end)
        text = text[:match.start()] + text[end:]
    return re.sub(r'\s+', ' ', text).strip()


def records(root: Path) -> dict:
    """Extract records/enums from all source packages, including nested submission DTOs."""
    result = {}
    from runtime_contract import RECORD_NAMES, wire_type
    for file in sorted(root.glob('src/main/java/**/*.java')):
        if '/rotations/' in str(file) or file.stem.startswith('Rotation'): continue  # Internal engine records are curated with isolated public DTO names in rotations_contract.
        text = java.clean(file.read_text())
        for match in re.finditer(r'\b(enum|record)\s+(\w+)\s*(?:<[^>]+>)?\s*([({])', text):
            kind, name, opening = match.groups()
            owner = file.stem
            name = RECORD_NAMES.get(owner, {}).get(name, name)
            if name == 'Page':
                continue  # New services use CursorPage, not Spring's Page.
            body, _ = java.balanced(text, match.end()-1, opening, ')' if opening == '(' else '}')
            source = str(file.relative_to(SOURCE_ROOT))
            if kind == 'enum':
                result[name] = {'enum': [x.strip() for x in body.split(';')[0].split(',')], 'source': source}
                continue
            fields = {}
            for item in java.split(body):
                typ, field = strip_annotations(item).rsplit(' ', 1)
                # Nested element @NotNull does not make an optional collection required.
                prefix = item.split('<')[0]
                required = bool(re.search(r'@(NotNull|NotBlank|NotEmpty)\b', prefix)) or typ in ('long','int','boolean','double')
                wire = re.search(r'@JsonProperty\("([^"]+)"\)', item)
                if wire: field = wire[1]
                fields[field] = {'java': wire_type(typ, owner), 'required': required, 'notBlank': '@NotBlank' in prefix}
            result[name] = {'fields': fields, 'source': source}
    return result


def extract(service: str, root: Path) -> tuple[list[dict], dict]:
    """Apply contract-documented wire and safety exceptions to controller/record extraction."""
    java.CATALOG.update(CATALOG)
    if service == 'platform':
        from platform_contract import extract as extract_platform
        return extract_platform(root)
    if service == 'auth':
        from auth_contract import extract as extract_auth
        return extract_auth(root)
    endpoints = java.endpoints_for(service, root)
    definitions = records(root)
    if service == 'fields':
        from fields_contract import curate
        return curate(endpoints, definitions, root)
    # Response references are required unless the documented nullable field is listed here.
    nullable = {
        'audit': {'Event': {'actorName','ipHash','requestId','metadata','idemKey'}, 'Summary': {'nextCursor'}},
        'leaderboards': {'Board': {'maxDeltaPerSubmit'}, 'Period': {'closedAt'}, 'Submission': {'displayName'}},
    }[service]
    response_names = {
        'audit': 'Retention Receipt Count Summary Event Submission',
        'leaderboards': 'Board Entry ScoreResult Submission Standing Period Rating RatingScope RatingChange MatchResult',
    }[service].split()
    for name in response_names:
        for field, info in definitions[name]['fields'].items():
            info['required'] = field not in nullable.get(name, set())
            if field in nullable.get(name, set()): info['nullable'] = True
    definitions['HealthResponse'] = {'fields': {k: {'java':'String','required':True} for k in ('status','service','timestamp')}}
    definitions['HealthComponent'] = {'fields': {'status': {'java':'String','required':True}}}
    for endpoint in endpoints:
        name = endpoint['name']
        if service == 'audit' and name == 'retention' and endpoint['method'] == 'PUT':
            name = 'putRetention'
        if service == 'leaderboards' and endpoint['source'].endswith('/RatingController.java'):
            name = 'rating' + name[0].upper() + name[1:]
        response = endpoint['javaResponse']
        while re.match(r'^(Mono|ResponseEntity)<.*>$', response):
            response = response[response.index('<')+1:-1]
        response = response.replace('Page<', 'CursorPage<')
        endpoint.update(name=name, id=service+'.'+name, responseJava=response,
                        responseType=name[0].upper()+name[1:]+'ResultValue', responseFormat='json',
                        errorStatuses=[400,401,403,404,409,429,500,503],
                        errorStatusNote='Common framework/service errors; domain rules remain authoritative.')
        guard = endpoint['guard']
        if 'SERVICE_ADMIN' in guard: endpoint['minimumLevel'] = 'ADMIN'
        elif 'SERVICE_READ' in guard: endpoint['minimumLevel'] = 'READ'
        if not endpoint['path'].startswith('/api/'):
            endpoint.update(minimumLevel=None, requiredRole=None, authKinds=['none','serviceAccount','user','custom'])
        if endpoint['path'] == '/health': endpoint['responseJava'] = 'HealthResponse'
        if endpoint['method'] == 'POST' and name in ('create','createCurrency'): endpoint['statuses'] = [201]
        if service == 'audit' and name in ('append','batch'): endpoint['statuses'] = [202]
        # No mutation is inferred repeat-safe from PUT/DELETE alone.
        endpoint['idempotent'] = endpoint['method'] == 'GET'
        endpoint['retryable'] = endpoint['method'] == 'GET'
        if service == 'audit' and name == 'retention': endpoint['cacheable'] = False
        key = None
        batch = None
        if service == 'leaderboards' and name in ('submit','batch'): key = 'submissionId'; batch = 'scores' if name == 'batch' else None
        if service == 'leaderboards' and name == 'ratingMatch': key = 'matchId'
        if service == 'audit' and name in ('append','batch'): key = 'idemKey'; batch = 'events' if name == 'batch' else None
        if key:
            endpoint.update(idempotencyField=key, idempotencyItems=batch, idempotent=True, retryable=True)
            dto = {'scores':'ScoreInput','events':'EventInput'}.get(batch, endpoint['bodyType'])
            definitions[dto]['fields'][key]['required'] = False
        # Audit scope selectors are read directly from ServerWebExchange on these routes.
        if service == 'audit' and name == 'get':
            endpoint['queryParams'].append({'name':'universeId','java':'Long','type':'id','required':False})
    definitions['MetricsResponse'] = {'fields': {'names': {'java':'List<String>','required':True}}}
    # Boot exposes these documented routes without Java controller methods.
    for name in ('metrics','info'):
        endpoint = dict(next(e for e in endpoints if e['path']=='/health'))
        endpoint.update(id=service+'.'+name, name=name, path='/'+name,
                        responseJava='MetricsResponse' if name=='metrics' else 'Map<String, Object>',
                        responseType=name.capitalize()+'ResultValue', source=str((root/'API_CONTRACT.md').relative_to(SOURCE_ROOT)))
        endpoints.append(endpoint)
    return endpoints, definitions


def refresh(doc: dict) -> dict:
    """Refresh local contracts, retaining reviewed map-built Matchmaking envelopes."""
    from consumer_contracts import refresh_consumers
    doc['endpoints'] = [e for e in doc['endpoints'] if e['service'] != 'config']
    doc['types'].pop('config', None)
    refresh_consumers(doc)
    records_only = {k:v for k,v in SOURCES.items() if k not in ('codes','matchmaking')}
    doc['endpoints'] = [e for e in doc['endpoints'] if e['service'] not in records_only]
    provenance = {}
    for service, root in SOURCES.items():
        if not root.is_dir(): raise FileNotFoundError(root)
        if service in records_only:
            endpoints, definitions = extract(service, root)
            doc['endpoints'].extend(endpoints)
            doc['types'][service] = definitions
        evidence = sorted(root.glob('src/main/java/**/*.java'))
        evidence += [p for p in (root/'API_CONTRACT.md', root/'README.md', root/'FRONTEND_INTEGRATION_GUIDE.md') if p.is_file()]
        evidence += sorted(root.glob('postman/*.json'))
        evidence += sorted(root.glob('src/main/resources/application.properties'))
        if service == 'auth':
            evidence += sorted((root.parent/'global-auth-client').glob('src/main/java/**/*.java'))
            evidence += [root.parent/'API_CONTRACT.md', root.parent/'README.md']
        for path in evidence:
            provenance[str(path.relative_to(SOURCE_ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    doc['sourceHashes'] = provenance
    from simulate_contract import curate_simulation
    curate_simulation(doc)
    for endpoint in doc['endpoints']:
        if endpoint['service'] != 'auth':
            # Legacy downstream global-ADMIN guards still exist, but GAS now gives
            # global bypass only to SUPER_ADMIN identity tokens, never scoped ones.
            if endpoint['requiredRole'] == 'ADMIN': endpoint['requiredRole'] = 'SUPER_ADMIN'
            if endpoint['requiredRole']:
                endpoint['authKinds'] = [kind for kind in endpoint['authKinds'] if kind != 'scoped']
            elif 'scoped' not in endpoint['authKinds'] and endpoint['authKinds'] != ['serviceAccount']:
                endpoint['authKinds'].append('scoped')
    # Proxy login responses carry current identity data; do not retain retired grants
    # in SDK types. This does not upgrade or edit downstream Java DTO artifacts.
    for service in ('party','matchmaking','codes'):
        definitions = doc['types'][service]
        for name in ('LoginResponse','RefreshResponse','AccountType'):
            definitions[name] = copy.deepcopy(doc['types']['auth'][name])
        from gen import schema
        needed: set[str] = set()
        def visit(value: dict) -> None:
            """Drop unreachable imported auth DTOs instead of carrying removed APIs in the spec."""
            if value['kind']=='ref':
                name = value['name']
                if name in needed: return
                needed.add(name)
                definition = definitions[name]
                if definition.get('parent'): visit(schema(definition['parent']))
                for field in definition.get('fields', {}).values(): visit(schema(field['java']))
            if 'item' in value: visit(value['item'])
            for item in value.get('items', []): visit(item)
        for endpoint in doc['endpoints']:
            if endpoint['service'] != service: continue
            visit(schema(endpoint['responseJava']))
            if endpoint['bodyType']: visit(schema(endpoint['bodyType']))
        doc['types'][service] = {name:definitions[name] for name in sorted(needed)}
    doc['endpoints'].sort(key=lambda e:(e['service'],e['path'],e['method']))
    from response_contract import curate_reads
    curate_reads(doc)
    return doc
