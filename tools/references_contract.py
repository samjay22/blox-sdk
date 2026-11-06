"""Apply the shared F2 reference contract without refreshing unrelated service work."""
from __future__ import annotations

import copy

BASE = '/api/fields/universes/{universeId}'


def curate(endpoints: list[dict], definitions: dict) -> tuple[list[dict], dict]:
    """Describe references and guarded mutations; server semantic validation stays authoritative."""
    from fields_contract import record

    definitions.update({
        'ReferenceConsumerType': {'enum': ['GAMEMODE', 'CODE']},
        'FieldReferenceInput': record(label='String', fields='List<String>'),
        'FieldReference': record(consumerType='ReferenceConsumerType', consumerId='String', label='String'),
        'FieldReferences': record(fieldId='String', references='List<FieldReference>'),
    })
    definitions['DefinitionChange']['fields']['references'] = {
        'java': 'List<FieldReference>', 'required': False,
    }
    template = next(e for e in endpoints if e['id'] == 'fields.definition')
    routes = (
        ('definitionReferences', 'GET', '/definitions/{id}/references', 'READ', None, 'FieldReferences'),
        ('putReferences', 'PUT', '/references/{consumerType}/{consumerId}', 'READ_WRITE', 'FieldReferenceInput', 'Void'),
        ('deleteReferences', 'DELETE', '/references/{consumerType}/{consumerId}', 'READ_WRITE', None, 'Void'),
    )
    # Replace discovered versions too, so future source refreshes retain stable SDK method names.
    paths = {(method, BASE + suffix) for _, method, suffix, *_ in routes}
    endpoints = [e for e in endpoints if (e['method'], e['path']) not in paths]
    for name, method, suffix, level, body, response in routes:
        endpoint = copy.deepcopy(template)
        params = [copy.deepcopy(template['pathParams'][0])]
        if method == 'GET':
            params.append({'name': 'id', 'java': 'String', 'type': 'string', 'required': True})
        else:
            params.extend([
                {'name': 'consumerType', 'java': 'String', 'type': 'string',
                 'luauType': 'ReferenceConsumerType', 'required': True},
                {'name': 'consumerId', 'java': 'String', 'type': 'string', 'required': True},
            ])
        endpoint.update(
            id='fields.' + name, name=name, method=method, path=BASE + suffix,
            pathParams=params, queryParams=[], minimumLevel=level,
            guard="hasRole('SERVICE_READ')" if method == 'GET' else "hasRole('SERVICE_WRITE')",
            bodyType=body, bodyRequired=body is not None,
            javaResponse='Mono<' + response + '>', responseJava=response,
            responseType=name[0].upper() + name[1:] + 'ResultValue',
            idempotent=True, retryable=True, cacheable=False,
            source='svc/fields-service/src/main/java/sam/tech/controller/FieldsController.java',
            statuses=[200] if method == 'GET' else [204],
            errorStatusNote='Shared CONTRACT.md F2; Fields validates consumer IDs (<=200) and field IDs.',
        )
        endpoints.append(endpoint)
    for endpoint in endpoints:
        if endpoint['id'] in ('fields.update', 'fields.purge'):
            if not any(p['name'] == 'force' for p in endpoint['queryParams']):
                endpoint['queryParams'].append({
                    'name': 'force', 'java': 'boolean', 'type': 'boolean',
                    'required': False, 'default': 'false',
                })
    return endpoints, definitions
