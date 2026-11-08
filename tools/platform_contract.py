"""Current Platform controller contracts, not planned or compiled-only feature routes."""
from __future__ import annotations
from pathlib import Path
import copy
import re


def extract(root: Path) -> tuple[list[dict], dict]:
    """Read every controller and resolve map-built wire bodies, permissions and response types."""
    import import_contract as java
    from service_contracts import records
    java.CATALOG['platform'] = 'PlatformService'
    definitions = records(root)
    # Public SDK DTO names are descriptive rather than nested implementation names.
    aliases = {'Rate':'RateLimit','Plan':'PlanInput','Batch':'UsageBatch','Put':'WebhookInput', 'Event':'PlatformEvent', 'Backfill':'DateRange','Incident':'IncidentInput'}
    types = {}
    for name, definition in definitions.items():
        target = aliases.get(name,name)
        types[target] = copy.deepcopy(definition)
        for field in types[target].get('fields',{}).values():
            typ = field['java'].split('.')[-1] if '<' not in field['java'] else field['java']
            for original, alias in aliases.items(): typ = re.sub(r'\b'+original+r'\b', alias, typ)
            typ = typ.replace('Set<','List<')
            field['java'] = typ
    from fields_contract import record
    types['HealthResponse'] = record(status='String',service='String',timestamp='String')
    types['HealthComponent'] = record(status='String')
    types['MetricsResponse'] = record(names='List<String>')
    names = {
        'MeteringController': {'ingest':'ingestUsage','plans':'plans','define':'putPlan','create':'createPlan','update':'updatePlan','delete':'deletePlan','assign':'setOrgPlan','plan':'orgPlan','usage':'usage','limits':'limits','invoices':'invoices'},
        'RateLimitController': {'org':'setRateLimits','key':'setKeyRateLimit','resetOrg':'resetRateLimits','resetKey':'resetKeyRateLimit','get':'rateLimits','internal':'gatewayRateLimits'},
        'WebhookController': {'list':'webhooks','create':'createWebhook','get':'webhook','put':'updateWebhook','delete':'deleteWebhook','deliveries':'webhookDeliveries','ping':'testWebhook','redeliver':'redeliverWebhook','publish':'publishEvent'},
        'AnalyticsController': {'summary':'analyticsSummary','series':'analyticsTimeseries','economy':'analyticsEconomy','backfill':'backfillAnalytics'},
        'DevxController': {'status':'status','openapi':'openapi','create':'createIncident','incidents':'incidents','put':'updateIncident','delete':'deleteIncident'},
        'SandboxController': {'create':'sandbox'},
    }
    endpoints = java.endpoints_for('platform',root)
    for e in endpoints:
        owner = Path(e['source']).stem
        name = names.get(owner,{}).get(e['name'], e['name'])
        # Route metadata is backend-relative for a single gateway prefix. Platform
        # preserves its prefix on direct hosts too; Pipeline handles that separately.
        e['path'] = e['path'].removeprefix('/platform-service').replace('{u}','{universeId}')
        for p in e['pathParams']:
            if p['name']=='u': p.update(name='universeId',type='id')
        response = e['javaResponse']
        while response.startswith(('Mono<','ResponseEntity<')): response = response[response.index('<')+1:-1]
        if response.startswith('Flux<'): response = 'List<'+response[5:]
        body = e['bodyType']
        if body: body = aliases.get(body.split('.')[-1], body)
        if e['path']=='/health': response = 'HealthResponse'
        if '/actuator/health/' in e['path']: response = 'HealthComponent'
        if name in ('createPlan','updatePlan','putPlan'): body = 'PlanInput'
        e.update(id='platform.'+name, name=name, bodyType=body, responseJava=response,
                 responseType=name[0].upper()+name[1:]+'ResultValue', responseFormat='json',
                 cacheable=False, retryable=e['method']=='GET', idempotent=e['method']=='GET',
                 minimumLevel='READ' if e['method']=='GET' else 'READ_WRITE', requiredRole=None,
                 authKinds=['serviceAccount','user','custom','scoped'],
                 errorStatuses=[400,401,403,404,409,422,429,500,503],
                 errorStatusNote='Current Platform controllers and scope checks; server validation remains authoritative.')
        if name in ('createPlan','updatePlan','putPlan','deletePlan','createIncident','updateIncident','deleteIncident','incidents','setRateLimits','setKeyRateLimit','resetRateLimits','resetKeyRateLimit'):
            e.update(requiredRole='SUPER_ADMIN', minimumLevel=None, authKinds=['user','custom'])
        elif name in ('orgPlan','setOrgPlan','usage','limits','invoices','rateLimits','sandbox'):
            e.update(requiredRole='IDENTITY', minimumLevel=None, authKinds=['user','custom'])
        elif name=='plans': e.update(minimumLevel=None,authKinds=['serviceAccount','user','custom','scoped'])
        elif name in ('publishEvent','ingestUsage','gatewayRateLimits'): e['authKinds']=['serviceAccount']
        elif name=='backfillAnalytics': e['minimumLevel']='ADMIN'
        if name=='status' or e['path'] in ('/health','/actuator/health/liveness','/actuator/health/readiness'):
            e.update(minimumLevel=None,authKinds=['none','serviceAccount','user','custom','scoped'])
        if name=='sandbox':
            e['queryParams'].append({'name':'universeId','type':'id','required':True}) # selected-universe filter uses exchange params
    health = next(e for e in endpoints if e['path']=='/health')
    for name in ('metrics','info'):
        endpoints.append(dict(health,id='platform.'+name,name=name,path='/'+name,
                              responseJava='MetricsResponse' if name=='metrics' else 'Map<String,Object>',responseType=name.capitalize()+'ResultValue'))
    # Keep only the public DTO graph; stale internal auth enums are not SDK APIs.
    from gen import schema
    needed: set[str] = set()
    def visit(value: dict) -> None:
        """Retain transitive DTOs while rejecting unresolved source types."""
        if value['kind']=='ref':
            name=value['name']
            if name in needed: return
            needed.add(name)
            for field in types[name].get('fields',{}).values(): visit(schema(field['java']))
        if 'item' in value: visit(value['item'])
        for item in value.get('items',[]): visit(item)
    for e in endpoints:
        visit(schema(e['responseJava']))
        if e['bodyType']: visit(schema(e['bodyType']))
    return endpoints, {name:types[name] for name in sorted(needed)}


def apply(doc: dict) -> dict:
    """Refresh only Platform from its current sources, leaving owning-service contracts untouched."""
    from service_contracts import SOURCES
    endpoints, types = extract(SOURCES['platform'])
    doc['endpoints'] = sorted([e for e in doc['endpoints'] if e['service']!='platform']+endpoints,key=lambda e:(e['service'],e['path'],e['method']))
    doc['types']['platform'] = types
    return doc
