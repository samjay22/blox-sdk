"""Binding scale-contract session DTOs and routes, independent of parallel service changes."""
from __future__ import annotations


def curate(doc: dict) -> None:
    """Install exact v1 wire shapes without inheriting backend internal DTO records."""
    definitions = doc['types']['fields']

    def dto(name: str, **fields: str) -> None:
        """Declare exact required/optional fields; v1 never emits null for absent properties."""
        definitions[name] = {
            'source': 'API_CONTRACT.md',
            'fields': {key: {'java': value.rstrip('?'), 'required': not value.endswith('?'),
                             'responseNullable': False} for key, value in fields.items()},
        }

    dto('SessionPlayer', userId='long', steal='boolean')
    dto('SessionLease', userId='long', epoch='long')
    dto('SessionSnapshot', seq='long', fields='JsonNode', versions='Map<String,Long>')
    dto('AcquireInput', serverId='String', ttlMs='long', players='List<SessionPlayer>')
    dto('RenewInput', serverId='String', ttlMs='long', leases='List<SessionLease>')
    dto('ReleaseInput', serverId='String', leases='List<SessionLease>')
    dto('SessionItem', userId='long', status='String', epoch='long?', expiresAt='String?',
        snapshot='SessionSnapshot?', owner='String?', retryAfterMs='long?')
    dto('SessionResponse', items='List<SessionItem>')
    dto('CommitPlayer', userId='long', epoch='long', ops='List<Fields.PlayerOperation>')
    dto('CommitInput', serverId='String', commitId='String', players='List<CommitPlayer>')
    dto('CommitError', code='String', field='String?')
    dto('CommitItem', userId='long', status='String', seq='long?', versions='Map<String,Long>?',
        expiresAt='String?', error='CommitError?')
    dto('CommitResponse', commitId='String', items='List<CommitItem>')
    dto('PollInput', serverId='String', cursor='long')
    dto('PollResponse', cursor='long', reset='boolean', more='boolean', players='List<Long>')
    base = next(endpoint for endpoint in doc['endpoints'] if endpoint['id'] == 'fields.changesBatch')
    for name, route, body, response in (
        ('acquireSessions', 'sessions/acquire', 'AcquireInput', 'SessionResponse'),
        ('renewSessions', 'sessions/renew', 'RenewInput', 'SessionResponse'),
        ('releaseSessions', 'sessions/release', 'ReleaseInput', 'SessionResponse'),
        ('commitSession', 'commits', 'CommitInput', 'CommitResponse'),
        ('pollSessions', 'sessions/poll', 'PollInput', 'PollResponse'),
    ):
        endpoint = dict(base, id='fields.' + name, name=name,
                        path='/api/fields/universes/{universeId}/' + route, bodyType=body,
                        responseJava=response, responseType=name[0].upper() + name[1:] + 'ResultValue',
                        minimumLevel='READ_WRITE', source='API_CONTRACT.md', retryable=False,
                        idempotent=True)
        # Match by wire identity, not Java method names that may change in parallel repositories.
        doc['endpoints'] = [existing for existing in doc['endpoints']
                            if (existing['service'], existing['method'], existing['path']) !=
                            (endpoint['service'], endpoint['method'], endpoint['path'])]
        doc['endpoints'].append(endpoint)
