"""Reviewed Rotations wire envelopes, expanded literal controller resources and nullability."""
from __future__ import annotations
import copy
from fields_contract import record


def curate(endpoints: list[dict], definitions: dict, raw: list[dict]) -> tuple[list[dict], dict]:
    """Keep random DTO names isolated from ordinary Fields Definition/Result/Input records."""
    definitions.update({
        'RotationKind': {'enum':['TABLE','GENERATOR','ROTATION']},
        'RandomDefinition': record(kind='RotationKind', key='String', version='long', definition='JsonNode'),
        'RandomDefinitionInput': record(universeId='Long?', key='String?', definition='JsonNode', expectedVersion='Long?', reason='String', applyNow='Boolean?'),
        'RandomAction': record(universeId='Long?', reason='String'),
        'RandomErase': record(universeId='Long?', confirmUniverseId='long', reason='String'),
        'GeneratorRollInput': record(universeId='Long?', generator='String', playerId='long', idempotencyKey='String?', count='Integer?'),
        'GeneratorPreviewInput': record(universeId='Long?', generator='String', playerId='Long?', count='Integer?'),
        'GeneratorSimulationInput': record(universeId='Long?', generator='String', playerId='Long?', iterations='Integer?'),
        'RotationClaimInput': record(universeId='Long?', instanceId='UUID', slot='String', entryId='String', quantity='int', idempotencyKey='String?', playerId='long'),
        'GeneratorPick': record(slot='String', index='int', table='String', entryId='String', path='List<String>', tags='List<String>', payload='JsonNode', rolls='Map<String,Long>', durationSeconds='Long', grants='List<Fields.PlayerOperation>'),
        'Generated': record(picks='List<GeneratorPick>', cost='List<Fields.PlayerOperation>', pityAfter='Long'),
        'RotationInstance': record(id='UUID', key='String', sequence='long', startsAt='Instant', endsAt='Instant', definitionVersions='Map<String,Long>', result='Generated'),
        'RotationActive': record(current='RotationInstance', next='RotationInstance', enabled='boolean'),
        'GeneratorRollResult': record(id='UUID', generator='String', playerId='long', results='List<Generated>', definitionVersions='Map<String,Long>', transaction='Result', createdAt='Instant'),
        'RotationClaimResult': record(id='UUID', instanceId='UUID', slot='String', entryId='String', quantity='int', remaining='long', transaction='Result', createdAt='Instant'),
        'RotationStock': record(slot='String', entryId='String', remaining='long'),
        'RandomOdds': record(entryProbabilities='Map<String,Double>', probabilities='Map<String,Double>'),
        'GeneratorSimulationResult': record(iterations='int', picks='long', entryCounts='Map<String,Long>', appearanceProbabilities='Map<String,Double>', pityMode='String'),
        'RandomHistory': record(counter='long', data='JsonNode'),
        'RandomEditorField': record(field='String', path='String', type='Fields.TypeExpr', validOps='List<String>'),
    })
    for name, fields in {'GeneratorPick':['payload','durationSeconds'], 'Generated':['pityAfter'], 'RotationActive':['current','next']}.items():
        for field in fields: definitions[name]['fields'][field]['nullable'] = True
    bodies = {'erase':'RandomErase', 'create':'RandomDefinitionInput', 'put':'RandomDefinitionInput', 'delete':'RandomAction', 'advance':'RandomAction', 'reroll':'RandomAction', 'roll':'GeneratorRollInput', 'claim':'RotationClaimInput', 'preview':'GeneratorPreviewInput', 'simulate':'GeneratorSimulationInput'}
    responses = {'schema':'JsonNode', 'editorFields':'List<RandomEditorField>', 'erase':'boolean', 'list':'List<RandomDefinition>', 'get':'RandomDefinition', 'create':'RandomDefinition', 'put':'RandomDefinition', 'delete':'boolean', 'active':'RotationActive', 'odds':'RandomOdds', 'preview':'List<Generated>', 'simulate':'GeneratorSimulationResult', 'roll':'GeneratorRollResult', 'claim':'RotationClaimResult', 'stock':'List<RotationStock>', 'advance':'RotationActive', 'reroll':'RotationActive', 'definitionsHistory':'CursorPage<RandomHistory>', 'instancesHistory':'CursorPage<RandomHistory>', 'playerHistory':'CursorPage<RandomHistory>'}
    names = {'schema':'randomnessSchema', 'editorFields':'randomnessFields', 'erase':'eraseRandomness', 'active':'activeRotation', 'odds':'tableOdds', 'preview':'previewGenerator', 'simulate':'simulateGenerator', 'roll':'rollGenerator', 'claim':'claimRotation', 'stock':'rotationStock', 'advance':'advanceRotation', 'reroll':'rerollRotation', 'definitionsHistory':'randomDefinitionHistory', 'instancesHistory':'rotationHistory'}
    for original in raw:
        method_name = original['name']
        resources = [('random-tables','RandomTable'), ('generators','Generator'), ('rotations','Rotation')] if '{resource:' in original['path'] else [('','')]
        if method_name == 'playerHistory': resources = [('rolls','Roll'), ('claims','Claim')]
        for resource, title in resources:
            e = copy.deepcopy(original)
            e['path'] = e['path'].replace('{resource:random-tables|generators|rotations}',resource).replace('{type:rolls|claims}',resource)
            e['pathParams'] = [p for p in e['pathParams'] if p['name'] not in ('resource','type')]
            name = names.get(method_name, method_name)
            if method_name in ('list','get','create','put','delete'):
                name = {'list':'list','get':'get','create':'create','put':'put','delete':'delete'}[method_name]+title+('s' if method_name=='list' else '')
            if method_name == 'playerHistory': name = 'player'+title+'History'
            level = 'ADMIN' if 'SERVICE_ADMIN' in e['guard'] else 'READ_WRITE' if 'SERVICE_WRITE' in e['guard'] else 'READ'
            e.update(name=name, id='fields.'+name, responseJava=responses[method_name], responseType=name[0].upper()+name[1:]+'ResultValue', bodyType=bodies.get(method_name), minimumLevel=level, requiredRole=None, statuses=[200], responseFormat='json', cacheable=False, retryable=e['method']=='GET', idempotent=e['method']=='GET', errorStatuses=[400,401,403,404,409,422,423,429,500,503], errorStatusNote='Fields API_CONTRACT.md Rotations & Generators; server rules are authoritative.')
            if method_name in ('roll','claim'): e.update(idempotencyField='idempotencyKey', idempotent=True, retryable=True)
            if method_name in ('preview','simulate'): e.update(idempotent=True, retryable=True)
            endpoints.append(e)
    return endpoints, definitions
