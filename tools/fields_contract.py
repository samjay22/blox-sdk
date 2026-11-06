"""Reviewed Fields wire exceptions layered on controller/record discovery, entirely offline."""
from __future__ import annotations
from pathlib import Path


def record(**fields: str) -> dict:
    """Construct an explicitly documented response object (question mark means optional)."""
    return {'fields': {k: {'java': v.rstrip('?'), 'required': not v.endswith('?')} for k, v in fields.items()}}


def curate(endpoints: list[dict], definitions: dict, root: Path) -> tuple[list[dict], dict]:
    """Resolve overloads, JsonProperty, dynamic map responses, nulls and operation wire types."""
    del root
    definitions.update({
        'SchemaResponse': record(universeId='long', schemaVersion='long', definitions='List<Definition>'),
        'BatchItem': record(subject='long', field='FieldView'),
        'BatchResponse': record(items='List<BatchItem>'),
        'ChangesResponse': record(items='List<Entry>', latestSeq='long', nextSinceSeq='long'),
        'PresenceResponse': record(items='List<Presence>'),
        'SnapshotDeleted': record(deleted='boolean', items='long'),
        'RestoreReportItem': record(field='String', error='String'),
        'RestoreReport': record(subject='long', restored='long?', skipped='long?', error='String?', items='List<RestoreReportItem>?'),
        'RestoreResponse': record(restoreId='UUID', preRestoreSnapshotId='UUID', restored='long', restoredSubjects='long', skipped='long', failed='long', replayed='boolean', reports='List<RestoreReport>'),
        'HealthResponse': record(status='String', service='String', timestamp='String'),
        'HealthComponent': record(status='String'),
        'MetricsResponse': record(names='List<String>'),
        'BoardConflict': record(code='String', board='String', expected='BoardSettings?',
                                actual='BoardActualSettings?', field='String?', source='String?'),
        'BoardActualSettings': record(sortOrder='String?', aggregation='String?', resetSchedule='String?',
                                      minScore='long?', maxScore='long?', maxDeltaPerSubmit='Long?'),
        'BoardPreviewStatus': {'enum': ['COMPATIBLE','CONFLICT','ARCHIVED','MISSING_OR_ARCHIVED']},
        'BoardSortOrder': {'enum': ['DESC','ASC']},
        'BoardAggregation': {'enum': ['LAST','BEST','SUM']},
        'BoardResetSchedule': {'enum': ['NONE','DAILY','WEEKLY','MONTHLY','SEASONAL']},
    })
    response_optional = {
        'Preview': {'willWiden'},
        'Definition': {'type','default','history','writeLevel','computed','bindings'},
        'DefinitionChange': {'before','after'}, 'FieldView': {'updatedAt','error'},
        'Entry': {'beforeHash','afterHash','refType','refId','reversesId'},
        'Document': {'computed','errors'}, 'Snapshot': {'subjectId'},
        'Presence': {'placeId','sessionId','updatedAt'}, 'Receipt': {'refund','refundedAt'},
        'Mismatch': {'expected','ledgerVersion','entryId'}, 'Item': {'lastError','doneAt'},
    }
    for name in ('Preview','BindingView','BoardSettings','ScoreRange','OpsValidationResult','OpValidationError','Definition','DefinitionChange','Result','ResultItem','FieldView','FieldPage','Document','Entry','Counts','Product','Receipt','ReceiptResult','Mismatch','Snapshot','SnapshotItem','SnapshotDetail','Presence','Policy','Item'):
        for field, info in definitions[name]['fields'].items():
            info['required'] = field not in response_optional.get(name, set())
            if info['java'].startswith('Models.'): info['java'] = info['java'][7:]
    definitions['ResultItem']['fields']['entryId']['java'] = 'String|JsonNode'
    definitions['PreviewBoardInput']['fields']['type']['java'] = 'Fields.TypeExpr'
    definitions['PreviewBoardInput']['fields']['binding']['java'] = 'Fields.LeaderboardBinding'
    definitions['BindingView']['fields']['binding']['java'] = 'Fields.LeaderboardBinding'
    definitions['Preview']['fields']['conflicts']['java'] = 'List<BoardConflict>'
    definitions['Preview']['fields']['status']['java'] = 'BoardPreviewStatus'
    for field, java in {'sortOrder':'BoardSortOrder','aggregation':'BoardAggregation','resetSchedule':'BoardResetSchedule'}.items():
        definitions['BoardSettings']['fields'][field]['java'] = java
    for name in ('Definition','DefinitionInput'):
        definitions[name]['fields']['type']['java'] = 'Fields.TypeExpr'
        definitions[name]['fields']['computed']['java'] = 'Fields.Computed'
        definitions[name]['fields']['bindings']['java'] = 'Fields.Bindings'
    for name in ('TransactionInput','OpsValidationInput','ProductInput','Product'):
        definitions[name]['fields']['ops']['java'] = 'List<Fields.Operation>'
    definitions['OpsValidationInput']['fields']['ops']['java'] = 'List<Fields.PlayerOperation>'
    definitions['TransactionInput']['fields']['conditions']['java'] = 'List<Fields.Condition>'
    for name in ('Entry','ResultItem','OpValidationError'):
        definitions[name]['fields']['path']['java'] = 'List<Fields.PathSegment>'
    for e in endpoints:
        name = e['name']
        controller = Path(e['source']).stem
        if controller == 'SafetyController':
            name = {'create':'createSnapshot','list':'snapshots','detail':'snapshot','delete':'deleteSnapshot',
                    'restore':'restoreSnapshot','presence': 'presenceBatch' if e['method']=='POST' else 'presence','policy': 'putSnapshotPolicy' if e['method']=='PUT' else 'snapshotPolicy'}.get(name,name)
        elif controller == 'CommerceController':
            name = {'put':'putProduct','delete':'deleteProduct'}.get(name,name)
        elif controller == 'OutboxController':
            name = {'list':'outbox','retry':'retryOutbox'}[name]
        response = e['javaResponse']
        while response.startswith(('Mono<','ResponseEntity<')): response=response[response.index('<')+1:-1]
        response=response.replace('Models.','').replace('OutboxService.','').replace('Page<','CursorPage<')
        response = {'schema':'SchemaResponse','playerBatch':'BatchResponse','batch':'BatchResponse','changes':'ChangesResponse',
                    'presenceBatch':'PresenceResponse','deleteSnapshot':'SnapshotDeleted','restoreSnapshot':'RestoreResponse'}.get(name,response)
        e.update(name=name,id='fields.'+name,responseJava=response,responseType=name[0].upper()+name[1:]+'ResultValue',
                 responseFormat='text' if name in ('luau','typescript') else 'json',
                 errorStatuses=[400,401,403,404,409,422,423,429,500,503],
                 errorStatusNote='Fields API_CONTRACT.md; server validation is authoritative.')
        if e['bodyType']: e['bodyType']=e['bodyType'].replace('Models.','')
        guard=e['guard']
        e['minimumLevel']='ADMIN' if 'SERVICE_ADMIN' in guard else 'READ_WRITE' if 'SERVICE_WRITE' in guard else 'READ'
        e['requiredRole']=None
        if not e['path'].startswith('/api/'):
            e.update(minimumLevel=None,authKinds=['none','serviceAccount','user','custom'])
        if e['path']=='/health': e['responseJava']='HealthResponse'
        e['idempotent']=e['retryable']=e['method']=='GET'
        if name in ('create',): e['statuses']=[201]
        if name in ('transaction','multiTransaction','reverseEntry','reverseTransaction','restoreSnapshot','purchase','refund'):
            e.update(idempotencyField='idempotencyKey',idempotent=True,retryable=True)
        # Document saves advance seq even when repeat values are identical; only explicit keys permit retry.
        if name=='putDocument':e.update(idempotencyField='idempotencyKey',optionalKey=True,idempotent=True,retryable=True)
    health=next(e for e in endpoints if e['path']=='/health')
    for name in ('metrics','info'):
        endpoints.append(dict(health,id='fields.'+name,name=name,path='/'+name,
                              responseJava='MetricsResponse' if name=='metrics' else 'Map<String, Object>',
                              responseType=name.capitalize()+'ResultValue'))
    return endpoints, definitions
