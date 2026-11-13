"""Item list routes of FieldsService (who holds a member, bitmap field reads), curated offline and idempotent.

The Fields Java extractor reads the older fields-service tree; these routes exist only in fields-service-redis
(ItemListsController, PlayerMembersController), so they are curated here from those controllers and applied
after extraction, the same way config_contract applies the ConfigService contract.
"""
from __future__ import annotations

SERVICE = 'fields'
CONTROLLERS = 'svc/fields-service-redis/src/main/java/sam/tech/controller/'
BASE = '/api/fields/universes/{universeId}'
NOTE = 'Fields item list contract; server validation is authoritative.'
ERROR_STATUSES = [400, 401, 403, 404, 409, 422, 423, 429, 500, 503]


def field(java: str, required: bool = True) -> dict:
    """One wire field in the extractor's shape; optional response members are omitted when absent."""
    info = {'java': java, 'notBlank': False, 'required': required}
    if not required:
        info.update(responseNullable=True, responseRequired=False)
    return info


def types() -> dict:
    """Wire DTOs of the item list routes."""
    src = {'source': CONTROLLERS + 'ItemListsController.java'}
    return {
        'ItemListLink': {'fields': {'field': field('String'), 'status': field('String'), 'maxMembers': field('int')}, **src},
        'ItemListUsage': {'fields': {
            'namespace': field('String'),
            'fields': field('List<ItemListLink>'),
            'holders': field('Map<String, Long>'),
            'configVersion': field('long'),
        }, **src},
        'ItemListMemberHolders': {'fields': {
            'member': field('String'),
            'bit': field('int'),
            'retired': field('boolean'),
            'count': field('long'),
            'byField': field('Map<String, Long>'),
            'samplePlayers': field('List<Long>'),
        }, **src},
        'ItemListMemberRef': {'fields': {'name': field('String'), 'bit': field('int')}, **src},
        'ItemListRemovalInput': {'fields': {'members': field('List<ItemListMemberRef>')}, **src},
        'ItemListHolder': {'fields': {
            'member': field('String'),
            'bit': field('int'),
            'count': field('long'),
            'samplePlayers': field('List<Long>'),
        }, **src},
        'ItemListRemovalCheck': {'fields': {
            'allowed': field('boolean'),
            'holders': field('List<ItemListHolder>', False),
        }, **src},
        'ItemListDrift': {'fields': {
            'field': field('String'),
            'bit': field('int'),
            'counted': field('long'),
            'actual': field('long'),
        }, **src},
        'ItemListVerify': {'fields': {
            'namespace': field('String'),
            'fields': field('List<String>'),
            'consistent': field('boolean'),
            'drift': field('List<ItemListDrift>'),
            'repaired': field('boolean'),
        }, **src},
        'ItemListSourceStatus': {'fields': {
            'universe': field('long'),
            'namespace': field('String'),
            'loaded': field('boolean'),
            'version': field('long', False),
            'ageSeconds': field('long', False),
            'lastError': field('String', False),
        }, **src},
        'PlayerMembers': {'fields': {
            'field': field('String'),
            'source': field('String'),
            'members': field('List<String>'),
            'retired': field('List<String>'),
            'bits': field('List<Integer>'),
            'value': field('String'),
            'version': field('long'),
            'configVersion': field('long'),
        }, 'source': CONTROLLERS + 'PlayerMembersController.java'},
    }


def param(name: str, kind: str = 'string', java: str = 'String', required: bool = True) -> dict:
    """A path or query parameter."""
    return {'java': java, 'name': name, 'required': required, 'type': kind}


def route(name: str, method: str, suffix: str, response: str, *, level: str, path_params: list[dict],
          query: list[dict] | None = None, body: str | None = None, controller: str = 'ItemListsController.java') -> dict:
    """One route; GETs are repeat-safe, writes are never retried implicitly, nothing is cached."""
    return {
        'authKinds': ['serviceAccount', 'user', 'custom', 'scoped'],
        'bodyRequired': body is not None,
        'bodyType': body,
        'cacheable': False,
        'errorStatusNote': NOTE,
        'errorStatuses': ERROR_STATUSES,
        'guard': "hasRole('SERVICE_ADMIN')" if level == 'ADMIN' else "hasRole('SERVICE_READ')",
        'id': f'{SERVICE}.{name}',
        'idempotent': method == 'GET',
        'javaResponse': response,
        'method': method,
        'minimumLevel': level,
        'name': name,
        'path': BASE + suffix,
        'pathParams': [param('universeId', 'id', 'long')] + path_params,
        'queryParams': query or [],
        'requiredRole': None,
        'responseFormat': 'json',
        'responseJava': response,
        'responseType': name[0].upper() + name[1:] + 'ResultValue',
        'retryable': method == 'GET',
        'service': SERVICE,
        'serviceName': 'FieldsService',
        'source': CONTROLLERS + controller,
        'statuses': [200],
    }


def endpoints() -> list[dict]:
    """The five item list routes and the player's members read."""
    namespace = param('namespace')
    base = '/item-lists/{namespace}'
    return [
        route('itemListUsage', 'GET', base + '/usage', 'ItemListUsage', level='READ', path_params=[namespace]),
        route('itemListHolders', 'GET', base + '/members/{member}/holders', 'ItemListMemberHolders', level='READ',
              path_params=[namespace, param('member')]),
        route('itemListRemovalCheck', 'POST', base + '/removal-check', 'ItemListRemovalCheck', level='ADMIN',
              path_params=[namespace], body='ItemListRemovalInput'),
        route('itemListVerifyHolders', 'POST', base + '/holders/verify', 'ItemListVerify', level='ADMIN',
              path_params=[namespace], query=[param('repair', 'boolean', 'boolean', False)]),
        route('itemListSource', 'GET', base + '/source', 'List<ItemListSourceStatus>', level='READ', path_params=[namespace]),
        route('playerMembers', 'GET', '/players/{userId}/members/{field}', 'PlayerMembers', level='READ',
              path_params=[param('userId', 'id', 'long'), param('field')], controller='PlayerMembersController.java'),
    ]


def apply(doc: dict) -> dict:
    """Add the item list routes and DTOs to the Fields section of the spec; safe to run repeatedly."""
    ids = {e['id'] for e in endpoints()}
    doc['endpoints'] = sorted([e for e in doc['endpoints'] if e['id'] not in ids] + endpoints(),
                              key=lambda e: (e['service'], e['path'], e['method']))
    doc['types'][SERVICE].update(types())
    return doc
