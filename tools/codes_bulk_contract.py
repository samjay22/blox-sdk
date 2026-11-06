"""Curate the shared F5 bulk-code contract while sibling backend work is in flight."""
from __future__ import annotations
import copy


def field(java: str, required: bool = False, not_blank: bool = False) -> dict:
    """Describe an exact shared-contract wire field for deterministic generation."""
    return {'java': java, 'required': required, 'notBlank': not_blank}


def curate(doc: dict) -> None:
    """Overlay only F5 routes/DTOs; preserve all unrelated imported service behavior."""
    definitions = doc['types']['codes']
    definitions['BulkCreateCodesRequest'] = {'fields': {
        'universeId': field('Long', True),
        'count': field('int', True),
        'prefix': field('String'),
        'length': field('Integer'),
        'name': field('String', True, True),
        'description': field('String'),
        'award': field('List<Fields.PlayerOperation>', True),
        'maxGlobalRedemptions': field('Long'),
        'startsAt': field('String'),
        'expiresAt': field('String'),
        'active': field('Boolean'),
        'metadata': field('Map<String, Object>'),
    }}
    definitions['BulkCode'] = {'fields': {'id': field('Long', True), 'code': field('String', True)}}
    definitions['BulkCreateCodesResponse'] = {'fields': {
        'batchId': field('String', True), 'count': field('int', True),
        'codes': field('List<BulkCode>', True),
    }}
    definitions['CodeDto']['fields']['batchId'] = dict(field('String'), nullable=True)
    endpoints = doc['endpoints']
    search = next(e for e in endpoints if e['id'] == 'codes.searchCodes')
    search['queryParams'] = [p for p in search['queryParams'] if p['name'] != 'batchId']
    search['queryParams'].append({'java': 'String', 'name': 'batchId', 'required': False, 'type': 'string'})
    search['queryParams'].sort(key=lambda p: p['name'])
    source = 'docs/CODES.md#bulk-generation-and-batches'
    bulk = copy.deepcopy(next(e for e in endpoints if e['id'] == 'codes.createCode'))
    bulk.update(id='codes.bulkCreateCodes', name='bulkCreateCodes', path='/api/codes/bulk',
                source=source, bodyType='BulkCreateCodesRequest',
                javaResponse='Mono<ResponseEntity<BulkCreateCodesResponse>>',
                responseJava='BulkCreateCodesResponse', responseType='BulkCreateCodesResultValue',
                idempotencyHeader=True, optionalKey=True)
    # Even keyed mutations stay conservative: explicit replay is supported, not automatic retry.
    bulk.update(idempotent=False, retryable=False)
    export = copy.deepcopy(next(e for e in endpoints if e['id'] == 'codes.listRedemptions'))
    export.update(id='codes.exportBatch', name='exportBatch',
                  path='/api/codes/batches/{batchId}/export', source=source,
                  pathParams=[{'java': 'String', 'name': 'batchId', 'required': True, 'type': 'string'}],
                  queryParams=[], javaResponse='Mono<ResponseEntity<String>>', responseJava='String',
                  responseType='ExportBatchResultValue', responseFormat='text',
                  responseContentType='text/csv', cacheable=False)
    paths = {bulk['path'], export['path']}
    doc['endpoints'] = [e for e in endpoints if e['service'] != 'codes' or e['path'] not in paths]
    doc['endpoints'].extend((bulk, export))
