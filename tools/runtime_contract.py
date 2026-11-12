"""Resolve Fields-owned runtime records without colliding with player/transaction DTOs."""
from __future__ import annotations
import re

RECORD_NAMES: dict[str, dict[str, str]] = {
    'NewMemberService': {'Created':'CreatedMember'},
    'RuntimeSnapshotService': {'Snapshot':'RuntimeSnapshot','Result':'RuntimeSnapshotResult','Key':'RuntimeSnapshotKey','Value':'RuntimeValue'},
    'MaintenanceService': {'Input':'MaintenanceInput','State':'MaintenanceState'},
    'FlagService': {'Input':'FlagInput','Definition':'FlagDefinition'},
    'FlagEvaluationService': {'Request':'FlagEvaluateInput','Batch':'FlagEvaluateBatchInput'},
    'FlagEvaluator': {'Value':'FlagEvaluationValue'},
    'FlagModels': {name:'Flag'+name for name in ('Match','Rule','Variant','Put','Evaluate','Exposure')},
    'EnvironmentDefinitionsService': {'Replace':'EnvironmentReplaceInput'},
}


def wire_type(value: str, owner: str = '') -> str:
    """Resolve qualified nested records first, then the owning file's local record names."""
    for cls, names in RECORD_NAMES.items():
        for name, alias in names.items():
            value = re.sub(r'\b'+cls+r'\.'+name+r'\b', alias, value)
    for name, alias in RECORD_NAMES.get(owner, {}).items():
        value = re.sub(r'(?<![\w.])'+name+r'\b', alias, value)
    return value


def curate(endpoints: list[dict], definitions: dict) -> None:
    """Apply reviewed runtime JSON, requiredness, response and naming contracts in place."""
    from fields_contract import record
    # Java imports are unqualified; explicit aliases keep the shared schema namespace closed.
    for name in ('FlagInput',):
        for field in definitions[name]['fields'].values():
            field['java'] = field['java'].replace('Rule','FlagRule').replace('Variant','FlagVariant')
    definitions['FlagEvaluation'] = record(values='Map<String,FlagEvaluationValue>')
    definitions['FlagBatchItem'] = record(userId='long', values='Map<String,FlagEvaluationValue>')
    definitions['FlagBatchEvaluation'] = record(items='List<FlagBatchItem>')
    definitions['PlayerSearchPage'] = record(items='List<JsonNode>', nextCursor='String?')
    definitions['PlayerEraseResult'] = record(erased='boolean', tombstoneId='UUID')
    definitions['PlayerEraseInput'] = record(reason='String', confirmUserId='long')
    definitions['PlayerRevertInput'] = record(reason='String', ledgerEntryIds='List<UUID>')
    for name in ('RuntimeSnapshot','MaintenanceState','FlagDefinition','FlagMatch','FlagRule','FlagVariant','FlagEvaluationValue'):
        for field in definitions[name]['fields'].values(): field['required'] = True
    for name, fields in {'FlagRule':['match'], 'FlagDefinition':['rolloutPct'], 'FlagEvaluationValue':['variant']}.items():
        for field in fields:
            definitions[name]['fields'][field]['nullable'] = True
            if name in ('FlagRule','FlagDefinition','FlagEvaluationValue'): definitions[name]['fields'][field]['required'] = False
    # Evaluation DTOs have service-level validation rather than Jakarta annotations.
    definitions['FlagEvaluateBatchInput']['fields']['userIds']['required'] = True
    for field in definitions['EnvironmentReplaceInput']['fields'].values(): field['required'] = True
    names = {
        'RuntimeSnapshotController': {'snapshot':'runtimeSnapshot'},
        'FlagsController': {'list':'flags','get':'flag','create':'createFlag','update':'updateFlag','delete':'deleteFlag','evaluate':'evaluateFlags','evaluateBatch':'evaluateFlagsBatch'},
        'MaintenanceController': {'read':'maintenance','put':'putMaintenance'},
    }
    for e in endpoints:
        owner = e['source'].rsplit('/',1)[-1].removesuffix('.java')
        name = names.get(owner,{}).get(e['name'], e['name'])
        e.update(name=name, id='fields.'+name, responseType=name[0].upper()+name[1:]+'ResultValue')
        e['responseJava'] = wire_type(e['responseJava'])
        if e['responseJava'].startswith('Flux<'): e['responseJava'] = 'List<'+e['responseJava'][5:]
        if e['bodyType']: e['bodyType'] = wire_type(e['bodyType'])
        if name == 'runtimeSnapshot':
            e.update(responseJava='RuntimeSnapshot|Void', responseFormat='json', conditional=True, cacheable=False, statuses=[200,304])
        elif name == 'evaluateFlags': e['responseJava'] = 'FlagEvaluation'
        elif name == 'evaluateFlagsBatch': e['responseJava'] = 'FlagBatchEvaluation'
        elif name == 'searchPlayers': e['responseJava'] = 'PlayerSearchPage'
        elif name == 'deletePlayer': e.update(bodyType='PlayerEraseInput', responseJava='PlayerEraseResult', cacheable=False)
        elif name == 'revertPlayer': e['bodyType'] = 'PlayerRevertInput'
        elif name == 'exportPlayer': e.update(responseJava='JsonNode', cacheable=False)
        elif name == 'dailyAnalytics': e['responseJava'] = 'JsonNode'
        if name in ('createFlag','deleteFlag'): e['statuses'] = [200]  # Mono<Void>, no ResponseStatus.
