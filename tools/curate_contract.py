#!/usr/bin/env python3
"""Apply explicit, reviewed controller/DTO corrections to the one-time Java import."""
from __future__ import annotations
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def field(java: str, required: bool = False) -> dict:
    """Describe a hand-reviewed DTO field."""
    return {'java':java,'required':required,'notBlank':False}

def main() -> None:
    """Produce the authoritative declarative contract from reviewed local evidence."""
    doc=json.loads((ROOT/'.test-build/imported.json').read_text())
    doc['version']=1
    types=doc['types']
    for ts in types.values():
        ts['AccountType']={'enum':['SUPER_ADMIN','ADMIN','UNIVERSE_ACCOUNT','PENDING']}
        ts['ServiceAccessLevel']={'enum':['READ','READ_WRITE','ADMIN']}
    types['auth']['UniverseEnabledRequest']={'fields':{'enabled':field('Boolean',True)}}
    for name in ('QueueRequest','MultiQueueRequest'):
        fs=types['matchmaking'][name]['fields']
        fs.update(robloxUserId=field('String'),metadata=field('Map<String, Object>'))
        fs['robloxUniverseId']['required']=True
    types['matchmaking']['QueueRequest']['fields']['gameModeName']['required']=True
    types['matchmaking']['MultiQueueRequest']['fields']['gameModeNames']['java']='List<String>|String'
    types['matchmaking']['MultiQueueRequest']['fields']['gameModeNames']['required']=True
    types['matchmaking']['BaseQueueRequest']['fields']['robloxUserIds']['java']='List<String>|String'
    types['matchmaking']['CriteriaType']={'enum':['RANGE','GROUP_BY','TEAM_TOTAL','THRESHOLD','WEIGHTED','CROSS_GROUP','TEAM_SIZE','LATENCY','REGION','SKILL_BASED','PARTY','BALANCE','LEVEL_RANGE','EXCLUDE','PRIORITY','FILL']}
    for svc, ts in types.items():
        ts['HealthResponse']={'fields':{'status':field('String',True),'timestamp':field('String'),'database':field('String')}}
        for name in ('LoginResponse','RefreshResponse'):
            for f in ('accessToken','refreshToken','expiresIn'): ts[name]['fields'][f]['required']=True
    types['matchmaking']['QueueResponse']={'fields':{'success':field('boolean',True),'message':field('String',True),'userIds':field('List<String>',True),'resolvedGameMode':field('String',True),'bannedUserIds':field('List<String>',True)}}
    types['matchmaking']['MultiQueueResponse']={'fields':{'success':field('boolean',True),'message':field('String',True),'userIds':field('List<String>',True),'resolvedGameModes':field('List<String>',True),'bannedUserIds':field('List<String>',True)}}
    # Map-built responses have real named fields, not fabricated queue DTOs.
    mm=types['matchmaking']
    envelopes={
      'BanListResponse':{'success':'boolean','count':'int','bans':'List<BannedPlayerResponse>'},
      'UniverseBanListResponse':{'success':'boolean','universeId':'String','count':'int','bans':'List<BannedPlayerResponse>'},
      'BanResponse':{'success':'boolean','ban':'BannedPlayerResponse','message':'String'},
      'BanCheckResponse':{'success':'boolean','userId':'String','universeId':'String','isBanned':'boolean'},
      'BulkBanResponse':{'success':'boolean','message':'String','bannedCount':'int','totalRequests':'int','bans':'List<BannedPlayerResponse>'},
      'BulkUnbanResponse':{'success':'boolean','message':'String','unbannedCount':'int','totalRequests':'int'},
      'UnbanResponse':{'success':'boolean','message':'String','userId':'String','universeId':'String'},
      'CleanupResponse':{'success':'boolean','message':'String','removedCount':'int'},
      'ApiKeysResponse':{'success':'boolean','count':'int','apiKeys':'List<RobloxApiKeyResponse>'},
      'ApiKeyResponse':{'success':'boolean','apiKey':'RobloxApiKeyResponse','message':'String'},
      'DeleteApiKeyResponse':{'success':'boolean','message':'String','universeId':'String'},
      'UniverseInfoEnvelope':{'success':'boolean','universe':'UniverseInfoResponse'},
      'UniversesEnvelope':{'success':'boolean','universe':'List<UniverseResponse>'},
      'SuccessMessage':{'success':'boolean','message':'String'},
    }
    for name,fields in envelopes.items(): mm[name]={'fields':{k:field(v,k!='message') for k,v in fields.items()}}
    map_responses={
      'getAllBannedPlayers':'BanListResponse','getBannedPlayersByUniverse':'UniverseBanListResponse','getPermanentBans':'UniverseBanListResponse','getTemporaryBans':'UniverseBanListResponse',
      'getBannedPlayer':'BanResponse','banPlayer':'BanResponse','updateBan':'BanResponse','checkBanStatus':'BanCheckResponse',
      'bulkBanPlayers':'BulkBanResponse','bulkUnbanPlayers':'BulkUnbanResponse','unbanPlayer':'UnbanResponse','removeExpiredBans':'CleanupResponse',
      'getAllApiKeys':'ApiKeysResponse','getApiKeyForCurrentUniverse':'ApiKeyResponse','getApiKeyByUniverseId':'ApiKeyResponse','createApiKey':'ApiKeyResponse','updateApiKey':'ApiKeyResponse','updateApiKeyForCurrentUniverse':'ApiKeyResponse','createOrUpdateApiKey':'ApiKeyResponse',
      'deleteApiKey':'DeleteApiKeyResponse','deleteApiKeyForCurrentUniverse':'DeleteApiKeyResponse','getUniverseInfo':'UniverseInfoEnvelope','getUniverseInfoForCurrentUniverse':'UniverseInfoEnvelope','getAllUniverses':'UniversesEnvelope',
      'queuePlayer':'QueueResponse','queuePlayerMulti':'MultiQueueResponse','removePlayer':'SuccessMessage','removePlayerPost':'SuccessMessage','processMatchmaking':'SuccessMessage',
    }
    names={'create':'createServiceAccount','list':'listServiceAccounts','get':'getServiceAccount','permissions':'setServiceAccountPermissions','rotate':'rotateServiceAccount','patch':'patchServiceAccount','revoke':'revokeServiceAccount'}
    keep=[]
    for e in doc['endpoints']:
        if e['path'].startswith('/actuator/'): continue  # deployment probes are outside the SDK route inventory
        svc=e['service']; old=e['name']
        response=e['javaResponse']
        while re.match(r'^(Mono|ResponseEntity)<.*>$',response): response=response[response.index('<')+1:-1]
        if old in ('login','refreshToken'): response='LoginResponse' if old=='login' else 'RefreshResponse'
        if e['path']=='/health' or e['path']=='/api/auth/health': response='HealthResponse'
        if svc=='matchmaking': response=map_responses.get(old,response)
        if svc=='matchmaking' and old=='createGameMode': e['minimumLevel']='ADMIN'
        if svc=='data' and old=='getUserData': response='UserDataDto|List<UserDataDto>'
        if svc=='party' and old=='leaveParty': response='PartyResponse|Void'
        if svc=='auth' and old.endswith('Rest'): e['statuses']=[204]
        if svc=='auth' and old=='validateToken': e['statuses']=[200,401]
        if svc=='party' and e['path'].startswith('/api/poll/'):
            e['minimumLevel']=None; e['authKinds']=['none','serviceAccount','user','custom']
        if svc=='auth' and old=='listServices': e['minimumLevel']=None
        if svc=='auth' and '/service-accounts' in e['path']: e['name']=names[old]
        if svc=='matchmaking' and old=='queuePlayer': e['name']='joinQueue'
        if svc=='matchmaking' and old=='queuePlayerMulti': e['name']='joinQueues'
        if e['path'] in ('/api/matchmaking/queue/status/bulk','/api/matchmaking/validate'): e.update(idempotent=True,retryable=True)
        # Destructive read/snapshot and sensitive credential responses cannot be coalesced or cached.
        if '/roblox/keys' in e['path']: e['cacheable']=False
        e['id']=svc+'.'+e['name']
        e['responseJava']=response
        e['responseType']=e['name'][0].upper()+e['name'][1:]+'ResultValue'
        e['errorStatuses']=[400,401,403,404,409,429,500,503]
        e['errorStatusNote']='Common framework/service errors; not an exhaustive set of domain exceptions.'
        keep.append(e)
    doc['endpoints']=sorted(keep,key=lambda e:(e['service'],e['path'],e['method']))
    (ROOT/'spec/endpoints.json').write_text(json.dumps(doc,indent=2,sort_keys=True)+'\n')
if __name__=='__main__':main()
