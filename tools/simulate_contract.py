"""Reviewed F4 wire overlay, retained by the source-refresh and replay workflows."""
from __future__ import annotations

import copy

SOURCE = 'CONTRACT.md#f4-criteria-dry-run'


def record(**fields: str) -> dict:
    """Describe required response fields and optional request selectors explicitly."""
    return {'source': SOURCE, 'fields': {
        name: {'java': java.removesuffix('?'), 'required': not java.endswith('?'), 'notBlank': False}
        for name, java in fields.items()
    }}


def curate_simulation(doc: dict) -> None:
    """Normalize nested Java records/guard inference without changing other endpoints."""
    doc['types']['fields'].update(
        PlayerSample=record(userId='long', values='Map<String, Double>'),
        PlayerSampleResponse=record(universeId='long', sampled='int', players='List<PlayerSample>'),
    )
    coverage = record(present='int', missing='int', min='Double', max='Double', mean='Double', p50='Double', p90='Double')
    for name in ('min', 'max', 'mean', 'p50', 'p90'):
        coverage['fields'][name]['nullable'] = True
    doc['types']['matchmaking'].update(
        CriteriaSimulationRequest=record(universeId='String', placeId='String?', criteria='List<MatchmakingCriteriaDTO>', sampleSize='int'),
        CriteriaFieldCoverage=coverage,
        CriteriaSimulationEstimate=record(groups='int', avgGroupSize='double', unmatchable='int', unmatchablePct='double'),
        CriteriaSimulationResponse=record(sampled='int', fieldCoverage='Map<String, CriteriaFieldCoverage>', estimate='CriteriaSimulationEstimate', warnings='List<String>'),
    )
    for service, name, method, path, body, response, level, template in (
        ('fields', 'samplePlayers', 'GET', '/api/fields/universes/{universeId}/players/sample', None, 'PlayerSampleResponse', 'READ', 'fields.schema'),
        ('matchmaking', 'simulateCriteria', 'POST', '/api/matchmaking/criteria/simulate', 'CriteriaSimulationRequest', 'CriteriaSimulationResponse', 'READ_WRITE', 'matchmaking.createGameMode'),
    ):
        # A dedicated overlay avoids importing unrelated in-flight backend changes and
        # preserves the facade names when controller method names differ from the SDK.
        endpoint = copy.deepcopy(next(e for e in doc['endpoints'] if e['id'] == template))
        endpoint.update(
            id=service+'.'+name, name=name, method=method, path=path, bodyType=body,
            bodyRequired=bool(body), responseJava=response, javaResponse='Mono<'+response+'>',
            responseType=name[0].upper()+name[1:]+'ResultValue', minimumLevel=level,
            statuses=[200], idempotent=True, retryable=method=='GET', cacheable=method=='GET',
            source=SOURCE, guard='', guardNote='Criteria dry-run contract; side-effect free, server validation authoritative.',
        )
        endpoint.pop('requestType', None)
        endpoint.pop('bodyDirect', None)
        if service == 'fields':
            endpoint['queryParams'] = [
                {'name': 'limit', 'java': 'int', 'type': 'number', 'required': False, 'default': '200'},
                {'name': 'fields', 'java': 'String', 'type': 'string', 'required': False},
            ]
        existing = next((i for i, e in enumerate(doc['endpoints']) if e['service'] == service and e['path'] == path and e['method'] == method), None)
        if existing is None:
            doc['endpoints'].append(endpoint)
        else:
            doc['endpoints'][existing] = endpoint
    # Match source refresh ordering even when recreating missing overlay routes.
    doc['endpoints'].sort(key=lambda e: (e['service'], e['path'], e['method']))
