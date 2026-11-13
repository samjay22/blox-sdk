"""ConfigService contract (curated from its API.md) and retirement of Fields' UNIVERSE scope, offline."""
from __future__ import annotations
import hashlib

SERVICE = 'config'
SERVICE_NAME = 'ConfigService'
API_DOC = 'svc/config-service/docs/API.md'
CONTROLLERS = 'svc/config-service/src/main/java/sam/tech/controller/'
SOURCE_FILES = (
    API_DOC,
    CONTROLLERS + 'ConfigController.java',
    CONTROLLERS + 'HealthController.java',
    CONTROLLERS + 'ProbeController.java',
    'svc/config-service/src/main/java/sam/tech/dto/ConfigModels.java',
)
BASE = '/api/config/universes/{universeId}/namespaces'
ERROR_STATUSES = [400, 401, 403, 404, 409, 429, 500, 503]
NOTE = 'ConfigService API.md; server validation, limits and version checks are authoritative.'


def field(java: str, required: bool = True) -> dict:
    """One wire field in the same shape the Java extractor produces."""
    return {'java': java, 'notBlank': False, 'required': required}


def types() -> dict:
    """Wire DTOs; optional response members are omitted by the server's non-null JSON inclusion."""
    src = {'source': API_DOC}
    return {
        'ChangeSet': {'fields': {
            'delete': field('List<String>', False),
            'expectedVersion': field('Long', False),
            'set': field('Map<String, EntryPut>', False),
        }, **src},
        'ChangedKeys': {'fields': {'deleted': field('List<String>'), 'set': field('List<String>')}, **src},
        'Entry': {'fields': {
            'description': field('String', False),
            'key': field('String'),
            'namespace': field('String'),
            'universeId': field('long'),
            'updatedAt': field('Instant'),
            'updatedBy': field('String', False),
            'value': field('JsonNode'),
            'version': field('long'),
        }, **src},
        'EntryPut': {'fields': {
            'description': field('String', False),
            'expectedVersion': field('Long', False),
            'value': field('JsonNode'),
        }, **src},
        'History': {'fields': {
            'changedAt': field('Instant'),
            'changedBy': field('String', False),
            'changes': field('ChangedKeys'),
            'namespace': field('String'),
            'op': field('String'),
            'rolledBackTo': field('Long', False),
            'universeId': field('long'),
            'version': field('long'),
        }, **src},
        'KindChange': {'fields': {'kind': field('String')}, **src},
        'Namespace': {'fields': {
            'createdAt': field('Instant'),
            'entryCount': field('int'),
            'kind': field('String'),
            'namespace': field('String'),
            'nextBit': field('int'),
            'universeId': field('long'),
            'updatedAt': field('Instant'),
            'updatedBy': field('String', False),
            'version': field('long'),
        }, **src},
        'Rollback': {'fields': {'toVersion': field('Long')}, **src},
        'Snapshot': {'fields': {
            'entries': field('Map<String, JsonNode>'),
            'kind': field('String'),
            'namespace': field('String'),
            'version': field('long'),
        }, **src},
        'StoredEntry': {'fields': {'description': field('String', False), 'value': field('JsonNode')}, **src},
        'VersionState': {'fields': {
            'entries': field('Map<String, StoredEntry>'),
            'history': field('History'),
        }, **src},
        'HealthComponent': {'fields': {'status': field('String')}},
        'HealthResponse': {'fields': {'status': field('String')}},
    }


def param(name: str, kind: str = 'string', java: str = 'String', required: bool = True, **extra: object) -> dict:
    """A path or query parameter."""
    return {'java': java, 'name': name, 'required': required, 'type': kind, **extra}


def route(name: str, method: str, suffix: str, response: str, *, level: str | None = 'READ',
          path_params: list[dict] | None = None, query: list[dict] | None = None, body: str | None = None,
          statuses: list[int] | None = None, source: str = 'ConfigController.java', **extra: object) -> dict:
    """One generated route; GETs are repeat-safe, writes are never retried implicitly."""
    api = level is not None
    read = method == 'GET'
    return {
        'authKinds': ['serviceAccount', 'user', 'custom', 'scoped'] if api else ['none', 'serviceAccount', 'user', 'custom', 'scoped'],
        'bodyRequired': body is not None,
        'bodyType': body,
        'cacheable': not api,
        'errorStatusNote': NOTE,
        'errorStatuses': ERROR_STATUSES,
        'guard': '',
        'id': f'{SERVICE}.{name}',
        'idempotent': read,
        'javaResponse': response,
        'method': method,
        'minimumLevel': level,
        'name': name,
        'path': (BASE if api else '') + suffix,
        'pathParams': ([param('universeId', 'id', 'long')] + (path_params or [])) if api else [],
        'queryParams': query or [],
        'requiredRole': None,
        'responseFormat': 'json',
        'responseJava': response,
        'responseType': name[0].upper() + name[1:] + 'ResultValue',
        'retryable': read,
        'service': SERVICE,
        'serviceName': SERVICE_NAME,
        'source': CONTROLLERS + source,
        'statuses': statuses or [200],
        **extra,
    }


def endpoints() -> list[dict]:
    """The twelve namespace routes plus the root health probes."""
    namespace = param('namespace')
    key = param('key')
    page = [param('cursor', required=False), param('limit', 'number', 'int', False, default='50')]
    ns = [namespace]
    return [
        route('namespaces', 'GET', '', 'CursorPage<Namespace>', query=page),
        route('namespace', 'GET', '/{namespace}', 'Namespace', path_params=ns),
        route('snapshot', 'GET', '/{namespace}/snapshot', 'Snapshot|Void', path_params=ns, statuses=[200, 304], conditional=True),
        route('entries', 'GET', '/{namespace}/entries', 'CursorPage<Entry>', path_params=ns, query=page),
        route('entry', 'GET', '/{namespace}/entries/{key}', 'Entry', path_params=[namespace, key]),
        route('putEntry', 'PUT', '/{namespace}/entries/{key}', 'Entry', level='ADMIN', path_params=[namespace, key], body='EntryPut'),
        route('deleteEntry', 'DELETE', '/{namespace}/entries/{key}', 'Void', level='ADMIN', path_params=[namespace, key], statuses=[204]),
        route('changeEntries', 'PATCH', '/{namespace}/entries', 'Namespace', level='ADMIN', path_params=ns, body='ChangeSet'),
        route('setKind', 'PUT', '/{namespace}/kind', 'Namespace', level='ADMIN', path_params=ns, body='KindChange'),
        route('history', 'GET', '/{namespace}/history', 'CursorPage<History>', path_params=ns, query=page),
        route('version', 'GET', '/{namespace}/history/{version}', 'VersionState', path_params=[namespace, param('version', 'id', 'long')]),
        route('rollback', 'POST', '/{namespace}/rollback', 'Namespace', level='ADMIN', path_params=ns, body='Rollback'),
        route('healthProxy', 'GET', '/health', 'HealthResponse', level=None, source='HealthController.java'),
        route('liveness', 'GET', '/actuator/health/liveness', 'HealthComponent', level=None, source='ProbeController.java'),
        route('readiness', 'GET', '/actuator/health/readiness', 'HealthComponent', level=None, source='ProbeController.java'),
    ]


def apply(doc: dict, source_root=None) -> dict:
    """Replace the Config section of the spec; the contract is curated from API.md, not parsed from Java."""
    doc['endpoints'] = sorted([e for e in doc['endpoints'] if e['service'] != SERVICE] + endpoints(),
                              key=lambda e: (e['service'], e['path'], e['method']))
    doc['types'][SERVICE] = types()
    if source_root is not None:
        for rel in SOURCE_FILES:
            path = source_root / rel
            if path.is_file():
                doc.setdefault('sourceHashes', {})[rel] = hashlib.sha256(path.read_bytes()).hexdigest()
    return doc


FIELDS_TYPES_RETIRED = ('GameValueChange', 'GameValueRollbackInput', 'ConfigType', 'RuntimeValue', 'RuntimeSnapshotKey')
FIELDS_ENDPOINTS_RETIRED = ('fields.gameValueHistory', 'fields.rollbackGameValue')
SOURCES_RETIRED = ('svc/fields-service/src/main/java/sam/tech/controller/GameValueHistoryController.java',
                   'svc/fields-service/src/main/java/sam/tech/fields/GameValueHistoryService.java')


def retire_universe_scope(doc: dict) -> dict:
    """Make the Fields contract player-only: no UNIVERSE scope, game values or SET_CONFIG; idempotent."""
    fields = doc['types']['fields']
    doc['endpoints'] = [e for e in doc['endpoints'] if e['id'] not in FIELDS_ENDPOINTS_RETIRED]
    for name in FIELDS_TYPES_RETIRED:
        fields.pop(name, None)
    for key in SOURCES_RETIRED:
        doc.get('sourceHashes', {}).pop(key, None)
    # Definitions are per-player data; the snapshot scope (PLAYER or UNIVERSE) is a different, retained concept.
    for name in ('Definition', 'DefinitionInput', 'PreviewBoardInput'):
        fields[name]['fields'].pop('scope', None)
    if 'Scope' in fields:
        fields['SnapshotScope'] = fields.pop('Scope')
    for name in ('Snapshot', 'SnapshotInput'):
        fields[name]['fields']['scope']['java'] = 'SnapshotScope'
    for e in doc['endpoints']:
        if e['id'] == 'fields.definitions':
            e['queryParams'] = [q for q in e['queryParams'] if q['name'] != 'scope']
        elif e['id'] == 'fields.snapshots':
            for q in e['queryParams']:
                if q['name'] == 'scope':
                    q['java'] = 'SnapshotScope'
    fields['ActionKind']['enum'] = [v for v in fields['ActionKind']['enum'] if v != 'SET_CONFIG']
    for member in ('type', 'value'):
        fields['ScheduleAction']['fields'].pop(member, None)
    fields['RuntimeSnapshot']['fields'].pop('gameValues', None)
    for name in ('Generated', 'RandomOdds'):
        fields[name]['fields'].pop('resolvedConfig', None)
    for member in ('scope', 'numericGameValue'):
        fields['RandomEditorField']['fields'].pop(member, None)
    return doc
