"""Reviewed Rotations wire envelopes: a named list of items that take turns on a fixed clock."""
from __future__ import annotations
from fields_contract import record

NAMES = {'list': 'listRotations', 'get': 'getRotation', 'put': 'putRotation', 'delete': 'deleteRotation',
         'current': 'currentRotation', 'schedule': 'rotationSchedule', 'preview': 'previewRotation'}
BODIES = {'put': 'RotationInput', 'preview': 'RotationPreviewInput'}
RESPONSES = {'list': 'List<Rotation>', 'get': 'Rotation', 'put': 'Rotation', 'delete': 'boolean',
             'current': 'RotationCurrent', 'schedule': 'RotationSchedule', 'preview': 'RotationSchedule'}


def curate(endpoints: list[dict], definitions: dict, raw: list[dict]) -> tuple[list[dict], dict]:
    """Name the seven controller routes and isolate their DTOs from ordinary Fields records."""
    definitions.update({
        'RotationOrder': {'enum': ['inOrder', 'shuffled']},
        'RotationItem': record(id='String', data='JsonNode?'),
        'RotationPeriod': record(startsAt='Instant', endsAt='Instant', items='List<RotationItem>'),
        'Rotation': record(key='String', version='long', items='List<RotationItem>', every='String', show='int',
                           order='RotationOrder', startsAt='Instant', updatedAt='Instant', current='RotationPeriod'),
        'RotationCurrent': record(key='String', version='long', current='RotationPeriod', next='RotationPeriod'),
        'RotationSchedule': record(periods='List<RotationPeriod>'),
        'RotationInput': record(universeId='Long?', items='List<RotationItem>', every='String', show='Integer?',
                                order='RotationOrder?', startsAt='Instant?', expectedVersion='Long?'),
        'RotationPreviewInput': record(universeId='Long?', key='String', items='List<RotationItem>', every='String',
                                       show='Integer?', order='RotationOrder?', startsAt='Instant?', count='Integer?'),
    })
    definitions['RotationItem']['fields']['data']['responseNullable'] = True
    for original in raw:
        method = original['name']
        name = NAMES[method]
        level = 'READ_WRITE' if 'SERVICE_WRITE' in original['guard'] else 'READ'
        original.update(
            name=name, id='fields.' + name, responseJava=RESPONSES[method], responseType=name[0].upper() + name[1:] + 'ResultValue',
            bodyType=BODIES.get(method), minimumLevel=level, requiredRole=None, statuses=[200], responseFormat='json',
            cacheable=False, retryable=original['method'] == 'GET' or method == 'preview',
            idempotent=original['method'] == 'GET' or method == 'preview',
            errorStatuses=[400, 401, 403, 404, 409, 422, 423, 429, 500, 503],
            errorStatusNote='Fields API_CONTRACT.md Rotations; server validation is authoritative.')
        endpoints.append(original)
    return endpoints, definitions
