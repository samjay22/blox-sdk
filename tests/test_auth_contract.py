"""Independent tenant route, DTO, safety and static-typing regression checks."""
from __future__ import annotations
import json
import copy
from pathlib import Path
import subprocess
import tempfile
import unittest
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
from auth_contract import curate_service_keys


class AuthContractTests(unittest.TestCase):
    """Assert the GAS tenant contract without deriving expectations from generator output."""

    def test_rotation_refresh_curation(self) -> None:
        """Replay the shared F6 overlay idempotently without changing unrelated endpoints."""
        doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        expected = copy.deepcopy(doc)
        rotate = next(e for e in doc['endpoints'] if e['id']=='auth.rotateServiceAccount')
        rotate.update(path='/api/auth/service-accounts/{id}/rotate',
                      pathParams=[rotate['pathParams'][1]], bodyType=None, bodyRequired=False)
        definitions = doc['types']['auth']
        for name in ('ServiceAccountStatus', 'ServiceAccountRotateRequest'):
            del definitions[name]
        for name in ('status', 'rotatedAt', 'previousKeyExpiresAt'):
            del definitions['ServiceAccountResponse']['fields'][name]
        curate_service_keys(doc['endpoints'], definitions)
        self.assertEqual(doc, expected)
        curate_service_keys(doc['endpoints'], definitions)
        self.assertEqual(doc, expected)

    def test_tenant_surface(self) -> None:
        """Require every tenant capability and prohibit retired account/unowned universe routes."""
        doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        routes = {e['id']:e for e in doc['endpoints'] if e['service']=='auth'}
        expected = {
            'listOrgs': ('GET','/orgs'), 'createOrg': ('POST','/orgs'),
            'getOrg': ('GET','/orgs/{org}'), 'patchOrg': ('PATCH','/orgs/{org}'),
            'deleteOrg': ('DELETE','/orgs/{org}'), 'setOrgPlan': ('PUT','/orgs/{org}/plan'),
            'transferOwnership': ('POST','/orgs/{org}/transfer-ownership'),
            'listMembers': ('GET','/orgs/{org}/members'), 'addMember': ('POST','/orgs/{org}/members'),
            'patchMember': ('PATCH','/orgs/{org}/members/{user}'),
            'removeMember': ('DELETE','/orgs/{org}/members/{user}'), 'leaveOrg': ('POST','/orgs/{org}/leave'),
            'getMyAccess': ('GET','/me/access'), 'listOrgUniverses': ('GET','/orgs/{org}/universes'),
            'createOrgUniverse': ('POST','/orgs/{org}/universes'),
            'getOrgUniverse': ('GET','/orgs/{org}/universes/{universe}'),
            'patchOrgUniverse': ('PATCH','/orgs/{org}/universes/{universe}'),
            'moveUniverse': ('POST','/orgs/{org}/universes/{universe}/move'),
            'exchangeScopedToken': ('POST','/universes/{universe}/token'),
            'createInvitation': ('POST','/orgs/{org}/invitations'),
            'listInvitations': ('GET','/orgs/{org}/invitations'),
            'revokeInvitation': ('DELETE','/orgs/{org}/invitations/{id}'),
            'acceptInvitation': ('POST','/invitations/accept'),
            'listRoleTemplates': ('GET','/role-templates'), 'setRoleTemplate': ('PUT','/role-templates/{role}'),
            'getAccessLog': ('GET','/orgs/{org}/access-log'),
            'rotateServiceAccount': ('POST','/orgs/{org}/service-accounts/{id}/rotate'),
        }
        for name, (method, path) in expected.items():
            route = routes['auth.'+name]
            self.assertEqual((route['method'],route['path']), (method,'/api/auth'+path))
            self.assertEqual(route['authKinds'], ['user','custom'])
            self.assertFalse(route['cacheable'])
            self.assertEqual(route['retryable'], method=='GET')
        for route in routes.values():
            self.assertNotRegex(route['path'], r'/accounts/(?:admin|universe-account|\{accountId\}|username)')
            self.assertNotIn('/promote', route['path'])
            if route['path'].startswith('/api/auth/universes'):
                self.assertTrue('/places' in route['path'] or route['path'].endswith('/token'))
        self.assertEqual(routes['auth.getAccessLog']['responseJava'], 'CursorPage<AccessEvent>')
        self.assertTrue(next(p for p in routes['auth.listServiceAccounts']['queryParams'] if p['name']=='orgId')['required'])
        for name in ('patchMember','removeMember','leaveOrg'):
            self.assertFalse(routes['auth.'+name]['queryParams'][0]['scopeDefault'])

    def test_dto_boundaries(self) -> None:
        """Keep identity roles separate from validation account types and preserve explicit null semantics."""
        doc = json.loads((ROOT/'spec/endpoints.json').read_text())
        types = doc['types']['auth']
        self.assertEqual(types['AccountType']['enum'], ['SUPER_ADMIN','USER'])
        self.assertEqual(types['ValidationAccountType']['enum'], ['SUPER_ADMIN','USER','UNIVERSE_ACCOUNT'])
        self.assertEqual(set(types['TenantRole']['enum']), {'OWNER','ADMIN','DEVELOPER','VIEWER'})
        self.assertEqual(set(types['AccountCreateRequest']['fields']), {'username','password','email','metadata'})
        self.assertEqual(set(types['AccountUpdateRequest']['fields']), {'email','metadata'})
        self.assertEqual(set(types['Token']['fields']), {'accessToken','tokenType','expiresIn'})
        self.assertNotIn('universeId', types['LoginResponse']['fields'])
        self.assertNotIn('servicePermissions', types['LoginResponse']['fields'])
        self.assertTrue(types['ServiceAccountResponse']['fields']['orgId']['required'])
        self.assertFalse(types['ServiceAccountCreateRequest']['fields']['expiresAt']['required'])
        self.assertEqual(types['ServiceAccountCreateRequest']['fields']['expiresAt']['java'], 'Instant')
        self.assertEqual(types['ServiceAccountStatus']['enum'], ['ACTIVE','EXPIRING_SOON','EXPIRED','REVOKED'])
        fields = types['ServiceAccountResponse']['fields']
        self.assertEqual(fields['status']['java'], 'ServiceAccountStatus')
        self.assertTrue(fields['status']['required'])
        for name in ('expiresAt', 'rotatedAt', 'previousKeyExpiresAt'):
            self.assertEqual(fields[name]['java'], 'Instant')
            self.assertFalse(fields[name]['required'])
        rotation = next(e for e in doc['endpoints'] if e['id']=='auth.rotateServiceAccount')
        self.assertEqual(rotation['bodyType'], 'ServiceAccountRotateRequest')
        self.assertFalse(rotation['bodyRequired'])
        self.assertFalse(rotation['cacheable'])
        self.assertFalse(rotation['retryable'])
        self.assertFalse(rotation['idempotent'])
        self.assertEqual(types['ServiceAccountRotateRequest']['fields'], {
            'gracePeriodSeconds': {'java': 'Integer', 'required': False, 'notBlank': False},
        })
        self.assertTrue(types['Member']['fields']['universeId']['nullable'])
        self.assertTrue(all(f['nullable'] for f in types['Plan']['fields'].values()))
        for definitions in doc['types'].values():
            self.assertNotIn('AccountPromoteRequest', definitions)
            self.assertNotIn('PENDING', json.dumps(definitions))

    def test_static_types(self) -> None:
        """Compile supported calls and reject removed methods, identity roles and malformed tenant DTOs."""
        prefix = '''--!strict
local SDK = require("./src/BloxSDK")
local Auth = require("./src/Types/Auth")
--- Compile-only tenant API fixture; never execute credentials or requests.
return function(client: SDK.Client)
 local _scope: SDK.Client = client:scoped(42)
 local _role: Auth.TenantRole = "DEVELOPER"
 client.auth:addMember({path={org="org"},body={username="user",role="VIEWER",universeId=42,overrides={}}})
 client.auth:setOrgPlan({path={org="org"},body={maxUniverses=SDK.null,maxMembers=10,maxServiceAccounts=20}})
 client.auth:listServiceAccounts({query={orgId="org"}})
 client.auth:createServiceAccount({name="key",universeId=42,permissions={},expiresAt="2030-01-01T00:00:00Z"})
 client.auth:rotateServiceAccount({path={org="org",id="key"},body={gracePeriodSeconds=0}})
 client.auth:rotateServiceAccount({path={org="org",id="key"}})
 local _status: Auth.ServiceAccountStatus = "EXPIRING_SOON"
'''
        with tempfile.NamedTemporaryFile(prefix='auth-types-', suffix='.luau', dir=ROOT, mode='w') as file:
            path = Path(file.name)
            for statement, valid in (
                ('', True),
                ('client.auth:createAdminAccount({username="u",password="p"})', False),
                ('client.auth:promoteAccount({})', False),
                ('client.auth:listServiceAccounts()', False),
                ('client.auth:rotateServiceAccount({path={id="key"}})', False),
                ('client.auth:rotateServiceAccount({path={org="org",id="key"},body={gracePeriodSeconds="0"}})', False),
                ('local bad: Auth.ServiceAccountStatus = "DISABLED"', False),
                ('SDK.new({userSession={role="ADMIN"}})', False),
                ('local bad: Auth.AccountType = "UNIVERSE_ACCOUNT"', False),
                ('local bad: Auth.TenantRole = "SUPER_ADMIN"', False),
                ('client.auth:setRoleTemplate({path={role="USER"},body={}})', False),
                ('client.auth:patchMember({path={org="o",user="u"},body={role="PENDING"}})', False),
            ):
                path.write_text(prefix+statement+'\nend\n')
                result = subprocess.run(['luau-analyze','-j1',str(path)], capture_output=True, text=True)
                if valid: self.assertEqual(result.returncode,0,result.stdout+result.stderr)
                else:
                    self.assertNotEqual(result.returncode,0,statement)
                    self.assertIn('TypeError',result.stdout+result.stderr)


if __name__ == '__main__':
    unittest.main()
