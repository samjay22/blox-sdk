"""Extract GAS tenant controllers and DTOs with reviewed API_CONTRACT wire semantics."""
from __future__ import annotations
import re
from pathlib import Path
import import_contract as java


def curate_service_keys(endpoints: list[dict], definitions: dict) -> None:
    """Apply shared F6 wire semantics while backend source worktrees converge."""
    source = 'CONTRACT.md#f6-service-key-expiry--rotation'
    definitions['ServiceAccountRotateRequest'] = {
        'source': source,
        'fields': {'gracePeriodSeconds': {'java': 'Integer', 'required': False, 'notBlank': False}},
    }
    definitions['ServiceAccountStatus'] = {
        'source': source, 'enum': ['ACTIVE', 'EXPIRING_SOON', 'EXPIRED', 'REVOKED'],
    }
    fields = definitions['ServiceAccountResponse']['fields']
    for name in ('rotatedAt', 'previousKeyExpiresAt'):
        fields.setdefault(name, {}).update(java='Instant', required=False, notBlank=False)
    fields.setdefault('status', {}).update(java='ServiceAccountStatus', required=True, notBlank=False)
    for endpoint in endpoints:
        if endpoint['id'] == 'auth.rotateServiceAccount':
            endpoint.update(path='/api/auth/orgs/{org}/service-accounts/{id}/rotate',
                            pathParams=[{'java': 'UUID', 'name': name, 'required': True, 'type': 'string'}
                                        for name in ('org', 'id')],
                            bodyType='ServiceAccountRotateRequest', bodyRequired=True)


def extract(root: Path) -> tuple[list[dict], dict]:
    """Replace the entire Auth surface; never merge retired account-management contracts."""
    from service_contracts import records
    definitions = java.types_for('auth', root)
    definitions.update(records(root))
    client = root.parent / 'global-auth-client'
    definitions.update(records(client))
    definitions['TenantRole']['enum'] = [re.match(r'\w+', item)[0] for item in definitions['TenantRole']['enum']]
    # Records serialize null; NON_NULL DTOs omit optional fields. Requests only expose
    # explicit null where the contract assigns it meaning (unlimited plans / key patch).
    nullable = {
        'Organization': {'maxUniverses','maxMembers','maxServiceAccounts'},
        'Member': {'universeId'},
        'MemberDetail': {'universeId','displayName'},
        'Invitation': {'universeId','targetUserId','acceptedAt','revokedAt'},
        'AccessEvent': {'actor','target','before','after','requestId'},
    }
    optional = {
        'AccountResponse': {'email'}, 'LoginResponse': {'email'},
        'ServiceAccountResponse': {'description','lastUsedAt','expiresAt','revokedAt','key','rotatedAt','previousKeyExpiresAt'},
    }
    responses = ('Organization Member MemberDetail CreatedMember Scope Universe Access Token Invitation Issued Template AccessEvent '
                 'AccountResponse LoginResponse RefreshResponse PlaceResponse ServiceAccountResponse '
                 'ServiceDefinitionResponse ServicePermissionResponse').split()
    for name in responses:
        for field, info in definitions[name]['fields'].items():
            info['required'] = field not in optional.get(name, set())
            if field in nullable.get(name, set()): info['nullable'] = True
    for info in definitions['Plan']['fields'].values():
        info.update(required=True, nullable=True)
    definitions['TokenValidateResponse']['fields']['valid']['required'] = True
    definitions['TokenValidateResponse']['fields']['accountType']['java'] = 'ValidationAccountType'
    definitions['ValidationAccountType'] = {'enum': ['SUPER_ADMIN','USER','UNIVERSE_ACCOUNT']}
    definitions['TokenValidateResponse']['fields']['role']['java'] = 'TenantRole'
    # Stable descriptive names avoid duplicate create/get/patch methods across controllers.
    names = {
        'OpenApiController': {'spec':'openApiSpec'},
        'AccountController': {'create':'createAccount','me':'getCurrentAccount','update':'updateCurrentAccount'},
        'ServiceAccountController': {'create':'createServiceAccount','list':'listServiceAccounts','get':'getServiceAccount',
            'permissions':'setServiceAccountPermissions','rotate':'rotateServiceAccount','patch':'patchServiceAccount','revoke':'revokeServiceAccount'},
        'OrganizationController': {'mine':'listOrgs','create':'createOrg','get':'getOrg','patch':'patchOrg','plan':'setOrgPlan',
            'delete':'deleteOrg','transfer':'transferOwnership','members':'listMembers','add':'addMember','owner':'assignOwner','newMember':'createMember',
            'remove':'removeMember','leave':'leaveOrg','universes':'listOrgUniverses','createUniverse':'createOrgUniverse',
            'universe':'getOrgUniverse','patchUniverse':'patchOrgUniverse','move':'moveUniverse','token':'exchangeScopedToken',
            'access':'getMyAccess','invite':'createInvitation','invitations':'listInvitations','accept':'acceptInvitation',
            'templates':'listRoleTemplates','template':'setRoleTemplate','log':'getAccessLog'},
    }
    endpoints = java.endpoints_for('auth', root)
    for e in endpoints:
        controller = Path(e['source']).stem
        name = names.get(controller, {}).get(e['name'], e['name'])
        response = e['javaResponse']
        while re.match(r'^(Mono|ResponseEntity)<.*>$', response):
            response = response[response.index('<')+1:-1]
        if response.startswith('Flux<'): response = 'List<' + response[5:]
        from runtime_contract import wire_type
        response = wire_type(response.replace('Page<', 'CursorPage<'))
        e.update(name=name, id='auth.'+name, responseJava=response,
                 responseType=name[0].upper()+name[1:]+'ResultValue', responseFormat='json',
                 cacheable=False, retryable=e['method']=='GET', idempotent=e['method']=='GET',
                 errorStatuses=[400,401,403,404,409,429,500,503],
                 errorStatusNote='GAS API_CONTRACT.md; identity and live tenant capability checks are authoritative.')
        public = 'none' in e['authKinds']
        places = controller == 'UniverseController'
        catalog_read = controller == 'ServiceCatalogController' and e['method']=='GET'
        if not public and not places:
            e.update(minimumLevel=None, requiredRole='IDENTITY', authKinds=['user','custom'])
            if catalog_read:
                e.update(requiredRole=None, authKinds=['user','scoped','custom'])
            if name in ('setOrgPlan','moveUniverse','setRoleTemplate','createService','updateService','deleteService'):
                e['requiredRole'] = 'SUPER_ADMIN'
        else:
            e['authKinds'].append('scoped')
        if controller == 'PlatformKeyLookupController':
            e.update(name='lookupServiceAccount', id='auth.lookupServiceAccount', responseType='LookupServiceAccountResultValue', requiredRole=None, authKinds=['serviceAccount'], minimumLevel='READ')
        elif controller == 'OpenApiController':
            e.update(requiredRole=None, authKinds=['serviceAccount','user','custom','scoped'], minimumLevel='READ')
        if e['method']=='POST' and name in ('createAccount','createOrg','createInvitation','createServiceAccount'):
            e['statuses'] = [201]
        if e['method']=='DELETE' or name in ('leaveOrg','deletePlace'):
            e['statuses'] = [204]
        if name == 'validateToken': e['statuses'] = [200,401]
        for param in e['queryParams']:
            # Omitting a membership selector means org-wide, never the facade's universe.
            if param['name'] == 'universeId': param['scopeDefault'] = False
        if name == 'setRoleTemplate': e['pathParams'][0]['luauType'] = 'TenantRole'
    curate_service_keys(endpoints, definitions)
    # Keep only reachable DTOs so unused legacy Java artifacts cannot leak into the SDK.
    from gen import schema
    needed: set[str] = set()
    def visit(value: dict) -> None:
        """Collect the closed public DTO graph, rejecting unresolved references."""
        if value['kind']=='ref':
            name = value['name']
            if name in needed: return
            needed.add(name)
            definition = definitions[name]
            if definition.get('parent'): visit(schema(definition['parent']))
            for field in definition.get('fields', {}).values(): visit(schema(field['java']))
        if 'item' in value: visit(value['item'])
        for item in value.get('items', []): visit(item)
    for e in endpoints:
        visit(schema(e['responseJava']))
        if e['bodyType']: visit(schema(e['bodyType']))
    return endpoints, {name:definitions[name] for name in sorted(needed)}
