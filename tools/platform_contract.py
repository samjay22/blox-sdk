"""Curate wave-2 SDK routes from the authoritative platform contract, offline and without git."""
from __future__ import annotations
import json
import hashlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def record(fields: dict[str, str], optional: tuple[str, ...] = ()) -> dict:
    """Build a strict generated DTO with explicit optional fields."""
    return {'fields': {key: {'java': value, 'required': key not in optional} for key, value in fields.items()}, 'source': 'rbac/f/CONTRACT2.md'}


def apply(doc: dict) -> dict:
    """Replace platform and player administration routes; never keep legacy deletion aliases."""
    types = {
        'RateLimit': record({'requestsPerSecond': 'int', 'burst': 'int', 'dailyRequests': 'long'}),
        'PlanInput': record({'name': 'String', 'monthlyLimits': 'Map<String,Long>', 'rateLimit': 'RateLimit', 'overagePrices': 'Map<String,BigDecimal>'}),
        'PlanChange': record({'plan': 'String'}),
        'UsageEvent': record({'orgId': 'String', 'universeId': 'Long', 'service': 'String', 'metric': 'String', 'count': 'long', 'at': 'Instant'}, ('universeId',)),
        'PlatformEvent': record({'universeId': 'long', 'orgId': 'String', 'type': 'String', 'data': 'JsonNode', 'occurredAt': 'Instant', 'eventId': 'String'}),
        'EnvironmentReplaceInput': record({'resources': 'List<JsonNode>', 'reason': 'String', 'operationId': 'String'}),
        'UsageBatch': record({'batchId': 'UUID', 'events': 'List<UsageEvent>'}),
        'WebhookInput': record({'url': 'String', 'events': 'List<String>', 'secret': 'String', 'enabled': 'boolean'}, ('secret',)),
        'PromotionInput': record({'from': 'String', 'to': 'String', 'resources': 'List<String>', 'reason': 'String', 'dryRun': 'boolean'}, ('dryRun',)),
        'DateRange': record({'from': 'String', 'to': 'String'}),
        'LiveAction': record({'type': 'String', 'key': 'String', 'value': 'JsonNode', 'codeId': 'Long', 'flag': 'String'}, ('key', 'value', 'codeId', 'flag')),
        'LiveEventInput': record({'name': 'String', 'startsAt': 'Instant', 'endsAt': 'Instant', 'timezone': 'String', 'recurrence': 'String', 'actions': 'List<LiveAction>'}, ('recurrence',)),
        'FlagMatch': record({'field': 'String', 'op': 'String', 'value': 'JsonNode'}),
        'FlagRule': record({'match': 'FlagMatch', 'rolloutPct': 'double', 'value': 'JsonNode'}),
        'Variant': record({'name': 'String', 'weightPct': 'double', 'value': 'JsonNode'}),
        'FlagInput': record({'key': 'String', 'type': 'String', 'defaultValue': 'JsonNode', 'rules': 'List<FlagRule>', 'enabled': 'boolean', 'variants': 'List<Variant>', 'sticky': 'boolean'}, ('variants', 'sticky')),
        'EvaluateInput': record({'userId': 'long', 'keys': 'List<String>'}, ('keys',)),
        'ExposureInput': record({'userId': 'long', 'key': 'String', 'variant': 'String', 'eventId': 'String', 'occurredAt': 'Instant'}),
        'EvaluationValue': record({'value': 'JsonNode', 'reason': 'String', 'variant': 'String'}, ('variant',)),
        'Evaluation': record({'values': 'Map<String,EvaluationValue>'}),
        'IncidentInput': record({'message': 'String', 'severity': 'String', 'resolved': 'boolean'}),
    }
    doc['types']['platform'] = types
    endpoints: list[dict] = [entry for entry in doc['endpoints'] if entry['service'] != 'platform' and entry['name'] not in ('playerOverview', 'searchPlayers', 'revertPlayer', 'exportPlayer', 'environmentResources', 'replaceEnvironmentResources', 'dailyAnalytics')]

    def add(name: str, method: str, path: str, body: str | None = None, result: str = 'JsonNode', level: str | None = 'READ', query: dict[str, tuple[str, bool]] | None = None, machine: bool = False, role: str | None = None) -> None:
        """Describe one backend-relative route with conservative non-idempotent retry metadata."""
        path_params = [{'name': key, 'type': 'id' if key in ('universeId', 'userId') else 'string', 'required': True} for key in re.findall(r'{([^}]+)}', path)]
        params = [{'name': key, 'type': kind, 'required': required} for key, (kind, required) in (query or {}).items()]
        endpoints.append({'id': f'platform.{name}', 'name': name, 'service': 'platform', 'serviceName': 'PlatformService', 'method': method, 'path': path, 'pathParams': path_params, 'queryParams': params, 'bodyType': body, 'bodyRequired': body is not None, 'responseJava': result, 'responseType': name[0].upper()+name[1:]+'ResultValue', 'responseFormat': 'json', 'authKinds': ['user', 'custom'] if role == 'SUPER_ADMIN' else ['serviceAccount'] if machine else ['none', 'serviceAccount', 'user', 'custom', 'scoped'] if level is None else ['serviceAccount', 'user', 'custom', 'scoped'], 'minimumLevel': level, 'requiredRole': role, 'cacheable': False, 'idempotent': method in ('GET', 'PUT', 'DELETE'), 'retryable': method in ('GET', 'PUT', 'DELETE'), 'source': 'rbac/f/CONTRACT2.md', 'statuses': [204 if result == 'Void' else 200], 'errorStatuses': [400, 401, 403, 404, 409, 429, 503], 'guard': '', 'javaResponse': result, 'errorStatusNote': 'Authoritative wave-2 contract; backend enforces scope and DTO rules.'})

    page = {'after': ('string', False), 'limit': ('number', False)}
    org = '/api/orgs/{org}'
    u = '/api/universes/{universeId}'
    add('publishEvent', 'POST', '/internal/events', 'PlatformEvent', level='READ_WRITE', machine=True)
    add('gatewayRateLimits', 'GET', '/internal/ratelimits/{orgId}', machine=True)
    add('ping', 'GET', '/api/ping')
    add('ingestUsage', 'POST', '/api/metering/events', 'UsageBatch', level='READ_WRITE', machine=True)
    add('plans', 'GET', '/api/plans', result='List<PlanInput>')
    add('putPlan', 'PUT', '/api/plans', 'PlanInput', query={'universeId': ('id', True)}, level='ADMIN', role='SUPER_ADMIN')
    add('orgPlan', 'GET', org+'/plan')
    add('setOrgPlan', 'PUT', org+'/plan', 'PlanChange', level='READ_WRITE')
    add('usage', 'GET', org+'/usage', result='List<JsonNode>', query={'from': ('string', True), 'to': ('string', True), 'groupBy': ('string', False)})
    add('invoices', 'GET', org+'/invoices', result='List<JsonNode>', query={'limit': ('number', False)})
    add('limits', 'GET', org+'/limits')
    add('rateLimits', 'GET', org+'/ratelimits')
    add('setRateLimits', 'PUT', org+'/ratelimits', 'RateLimit', level='READ_WRITE')
    add('setKeyRateLimit', 'PUT', org+'/service-accounts/{id}/ratelimit', 'RateLimit', level='READ_WRITE')
    add('webhooks', 'GET', u+'/webhooks', result='List<JsonNode>', query=page)
    add('webhook', 'GET', u+'/webhooks/{id}')
    add('createWebhook', 'POST', u+'/webhooks', 'WebhookInput', level='READ_WRITE')
    add('updateWebhook', 'PUT', u+'/webhooks/{id}', 'WebhookInput', level='READ_WRITE')
    add('deleteWebhook', 'DELETE', u+'/webhooks/{id}', result='Void', level='READ_WRITE')
    add('webhookDeliveries', 'GET', u+'/webhooks/{id}/deliveries', result='List<JsonNode>', query={'limit': ('number', False)})
    add('testWebhook', 'POST', u+'/webhooks/{id}/test', level='READ_WRITE')
    add('redeliverWebhook', 'POST', u+'/webhooks/{id}/deliveries/{deliveryId}/redeliver', level='READ_WRITE')
    add('snapshotEnvironment', 'POST', u+'/environments/{env}/snapshot', level='ADMIN')
    add('environmentDiff', 'GET', u+'/environments/diff', query={'from': ('string', True), 'to': ('string', True)})
    add('promoteEnvironment', 'POST', u+'/environments/promote', 'PromotionInput', level='ADMIN')
    add('rollbackEnvironment', 'POST', u+'/environments/rollback/{promotionId}', level='ADMIN')
    add('promotions', 'GET', u+'/environments/promotions', result='List<JsonNode>', query=page)
    add('liveEvents', 'GET', u+'/liveops/events', result='List<JsonNode>', query=page)
    add('createLiveEvent', 'POST', u+'/liveops/events', 'LiveEventInput', level='ADMIN')
    add('updateLiveEvent', 'PUT', u+'/liveops/events/{id}', 'LiveEventInput', level='ADMIN')
    add('deleteLiveEvent', 'DELETE', u+'/liveops/events/{id}', result='Void', level='ADMIN')
    add('liveEvent', 'GET', u+'/liveops/events/{id}')
    add('liveEventOccurrences', 'GET', u+'/liveops/events/{id}/preview', result='List<JsonNode>')
    add('liveEventRuns', 'GET', u+'/liveops/events/{id}/runs', result='List<JsonNode>')
    add('startLiveEvent', 'POST', u+'/liveops/events/{id}/start', level='ADMIN')
    add('stopLiveEvent', 'POST', u+'/liveops/events/{id}/stop', level='ADMIN')
    add('analyticsSummary', 'GET', u+'/analytics/summary', query={'from': ('string', True), 'to': ('string', True)})
    add('analyticsTimeseries', 'GET', u+'/analytics/timeseries', result='List<JsonNode>', query={'metric': ('string', True), 'from': ('string', True), 'to': ('string', True)})
    add('analyticsEconomy', 'GET', u+'/analytics/economy', result='List<JsonNode>', query={'field': ('string', True)})
    add('backfillAnalytics', 'POST', u+'/analytics/backfill', 'DateRange', level='ADMIN')
    add('flags', 'GET', u+'/flags', result='List<FlagInput>', query=page)
    add('flag', 'GET', u+'/flags/{key}', result='FlagInput')
    add('createFlag', 'POST', u+'/flags', 'FlagInput', level='READ_WRITE')
    add('updateFlag', 'PUT', u+'/flags/{key}', 'FlagInput', level='READ_WRITE')
    add('deleteFlag', 'DELETE', u+'/flags/{key}', result='Void', level='READ_WRITE')
    add('evaluateFlags', 'POST', u+'/flags/evaluate', 'EvaluateInput', result='Evaluation')
    add('recordExposure', 'POST', u+'/experiments/exposure', 'ExposureInput', level='READ_WRITE')
    add('openapi', 'GET', '/api/openapi.json')
    add('sandbox', 'POST', org+'/sandbox', level='READ_WRITE')
    add('status', 'GET', '/api/status', level=None)
    add('createIncident', 'POST', '/api/status/incidents', 'IncidentInput', query={'universeId': ('id', True)}, level='ADMIN', role='SUPER_ADMIN')
    add('updateIncident', 'PUT', '/api/status/incidents/{id}', 'IncidentInput', query={'universeId': ('id', True)}, level='ADMIN', role='SUPER_ADMIN')
    add('deleteIncident', 'DELETE', '/api/status/incidents/{id}', result='Void', query={'universeId': ('id', True)}, level='ADMIN', role='SUPER_ADMIN')
    add('healthProxy', 'GET', '/health', level=None)

    # Player administration stays in FieldsService; the wave-2 privacy body replaces query-only deletion.
    fields = doc['types']['fields']
    fields['PlayerSearchPage'] = record({'items': 'List<JsonNode>', 'nextCursor': 'String'}, ('nextCursor',))
    fields['PlayerEraseResult'] = record({'erased': 'boolean', 'tombstoneId': 'UUID'})
    fields['PlayerEraseInput'] = record({'reason': 'String', 'confirmUserId': 'long'})
    fields['PlayerRevertInput'] = record({'reason': 'String', 'ledgerEntryIds': 'List<UUID>'})
    for entry in endpoints:
        if entry['id'] == 'fields.deletePlayer':
            entry.update(bodyType='PlayerEraseInput', bodyRequired=True, queryParams=[], responseJava='PlayerEraseResult', cacheable=False, retryable=False, idempotent=False)
    for name, method, suffix, body, result, query, level in [
        ('playerOverview', 'GET', '/players/{userId}/overview', None, 'JsonNode', {}, 'READ'),
        ('searchPlayers', 'GET', '/players/search', None, 'PlayerSearchPage', {'q': ('string', True), 'cursor': ('string', False), 'limit': ('number', False)}, 'READ'),
        ('revertPlayer', 'POST', '/players/{userId}/revert', 'PlayerRevertInput', 'JsonNode', {}, 'ADMIN'),
        ('exportPlayer', 'GET', '/players/{userId}/export', None, 'JsonNode', {}, 'READ'),
    ]:
        add(name, method, '/api/fields/universes/{universeId}'+suffix, body, result, level, query)
        endpoints[-1].update(id=f'fields.{name}', service='fields', serviceName='FieldsService')
    # Environment resources stay with their owning services; the platform only orchestrates promotion.
    for service, catalog, prefix in [('fields', 'FieldsService', '/api/fields'), ('config', 'ConfigService', '/api/config'), ('matchmaking', 'MatchmakingService', '/api/gamemodes')]:
        doc['types'][service]['EnvironmentReplaceInput'] = record({'resources': 'List<JsonNode>', 'reason': 'String', 'operationId': 'String'})
        for name, method, body, level in [('environmentResources', 'GET', None, 'READ'), ('replaceEnvironmentResources', 'PUT', 'EnvironmentReplaceInput', 'ADMIN')]:
            add(name, method, prefix+'/universes/{universeId}/environments/{env}/resources', body, level=level)
            endpoints[-1].update(id=f'{service}.{name}', service=service, serviceName=catalog)
    add('dailyAnalytics', 'GET', '/api/fields/universes/{universeId}/analytics/daily', query={'day': ('string', True)})
    endpoints[-1].update(id='fields.dailyAnalytics', service='fields', serviceName='FieldsService')
    contract = ROOT.parent/'rbac/f/CONTRACT2.md'
    if contract.is_file():
        doc.setdefault('sourceHashes', {})['rbac/f/CONTRACT2.md'] = hashlib.sha256(contract.read_bytes()).hexdigest()
    doc['endpoints'] = sorted(endpoints, key=lambda entry: (entry['service'], entry['path'], entry['method']))
    return doc


def main() -> None:
    """Write curated source metadata; tools/gen.py creates all derived Luau and docs."""
    path = ROOT/'spec/endpoints.json'
    doc = apply(json.loads(path.read_text()))
    path.write_text(json.dumps(doc, indent=2, sort_keys=True)+'\n')
    routes = json.loads((ROOT/'routes.json').read_text())
    routes = [r for r in routes if r['svc'] != 'platform' and not (r['svc'] in ('fields','config','matchmaking') and any(e['service'] == r['svc'] and e['path'] == r['path'] and e['name'] in ('playerOverview','searchPlayers','revertPlayer','exportPlayer','environmentResources','replaceEnvironmentResources','dailyAnalytics') for e in doc['endpoints']))]
    routes.extend({'svc': e['service'], 'method': e['method'], 'path': e['path']} for e in doc['endpoints'] if e['service'] == 'platform' or e['name'] in ('playerOverview','searchPlayers','revertPlayer','exportPlayer','environmentResources','replaceEnvironmentResources','dailyAnalytics'))
    (ROOT/'routes.json').write_text(json.dumps(routes, indent=2)+'\n')


if __name__ == '__main__':
    main()
