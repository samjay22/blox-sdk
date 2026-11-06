"""Reviewed Fields consumers extracted from local Java sources, without network or execution."""
from __future__ import annotations
import import_contract as java
from fields_contract import record


def refresh_consumers(doc: dict) -> None:
    """Replace retired Codes DTOs and refresh criteria from their authoritative sources."""
    root = java.SOURCES['codes']
    definitions = java.types_for('codes', root)
    for definition in definitions.values():
        for field in definition.get('fields', {}).values():
            field['java'] = field['java'].replace('java.util.', '')
            field['java'] = field['java'].replace('FieldOperation', 'Fields.PlayerOperation')
    for name in ('CodeDto', 'CodeRedemptionDto', 'RedeemCodeResponse', 'FieldsTransactionResult', 'Result'):
        optional = {
            'CodeDto': {'name','description','metadata','maxGlobalRedemptions','remainingGlobalRedemptions','startsAt','expiresAt'},
            'CodeRedemptionDto': {'placeId','requestId','redeemedByAccountId'},
        }.get(name, set())
        for field, info in definitions[name]['fields'].items():
            info['required'] = field not in optional
    definitions['FieldsTransactionResult']['fields']['results']['java'] = 'List<Result>'
    definitions['Result']['fields']['path']['java'] = 'List<Fields.PathSegment>'
    definitions['Result']['fields']['op']['java'] = 'Op'
    definitions['Result']['fields']['entryId']['java'] = 'String|JsonNode'
    definitions['HealthResponse'] = record(status='String', timestamp='String?', database='String?')
    definitions['MetricsResponse'] = record(names='List<String>')
    # FieldOperation is a @JsonValue closed union, not its private implementation members.
    definitions.pop('FieldOperation', None)
    endpoints = []
    for e in java.endpoints_for('codes', root):
        if e['path'].startswith('/actuator/'):
            continue  # Deployment probes are outside the SDK inventory.
        response = e['javaResponse']
        while response.startswith(('Mono<','ResponseEntity<')):
            response = response[response.index('<')+1:-1]
        e.update(responseJava='HealthResponse' if e['path']=='/health' else response,
                 responseType=e['name'][0].upper()+e['name'][1:]+'ResultValue',
                 errorStatuses=[400,401,403,404,409,422,423,429,500,503],
                 errorStatusNote='CodeService API_CONTRACT.md; Fields remains authoritative.')
        e['retryable'] = e['idempotent'] = e['method']=='GET'
        endpoints.append(e)
    health = next(e for e in endpoints if e['path']=='/health')
    for name in ('metrics','info'):
        endpoints.append(dict(health, id='codes.'+name, name=name, path='/'+name,
                              responseJava='MetricsResponse' if name=='metrics' else 'Map<String, Object>',
                              responseType=name.capitalize()+'ResultValue'))
    doc['endpoints'] = [e for e in doc['endpoints'] if e['service']!='codes'] + endpoints
    doc['types']['codes'] = definitions
    from codes_bulk_contract import curate as curate_bulk_codes
    curate_bulk_codes(doc)
    mm = java.types_for('matchmaking', java.SOURCES['matchmaking'])
    doc['types']['matchmaking']['MatchmakingCriteriaDTO'] = mm['MatchmakingCriteriaDTO']
    # Queue metadata is supplied by Fields enrichment, not caller authority.
    for name in ('QueueRequest', 'MultiQueueRequest'):
        for field in ('metadata','playerMetadata','queuedAt'):
            doc['types']['matchmaking'][name]['fields'].pop(field, None)
