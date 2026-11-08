"""Reviewed durable Fields control-plane contracts; no backend execution or network."""
from __future__ import annotations
from copy import deepcopy
from fields_contract import record


def definitions_into(definitions: dict) -> None:
    """Replace ambiguous Java names and map-built envelopes with explicit public DTOs."""
    definitions.update({
        # JobModels.Item shadows the earlier outbox record in simple-name discovery.
        'Item': record(id='UUID', universeId='long', kind='String', payload='JsonNode', status='String',
                       attempts='int', nextAttemptAt='Instant', lastError='String?', createdAt='Instant',
                       doneAt='Instant?', queueOrder='long'),
        'JobKind': {'enum': ['BULK','REVERSE','EXPORT','IMPORT','MIGRATION','ROLLBACK','SCHEDULE','ALERT_SCAN','NOTIFY']},
        'JobState': {'enum': ['QUEUED','RUNNING','SUCCEEDED','CANCELLED','FAILED']},
        'JobReceipt': record(id='UUID', kind='JobKind', state='JobState', total='long', succeeded='long',
                             failed='long', prepared='boolean', cancelRequested='boolean', attempts='int',
                             updatedAt='Instant', error='String?', phase='String?', snapshotId='UUID?', recurrence='ScheduleRecurrence?'),
        'JobSummary': record(id='UUID', kind='JobKind', state='JobState', total='long', succeeded='long',
                             failed='long', updatedAt='Instant', error='String?'),
        'JobEvent': record(id='long', event='String', actor='String', metadata='Map<String, JsonNode>', createdAt='Instant'),
        'JobFailure': record(ordinal='long', subject='long', error='String'),
        'JobActionInput': record(universeId='Long?', reason='String'),
        'KeyedJobActionInput': record(universeId='Long?', reason='String', idempotencyKey='String?'),
        'BulkInput': record(universeId='Long?', target='Fields.BulkTarget', ops='List<Fields.PlayerOperation>', reason='String', idempotencyKey='String?'),
        'BulkPreviewInput': record(universeId='Long?', target='Fields.BulkTarget', ops='List<Fields.PlayerOperation>', reason='String?', idempotencyKey='String?'),
        'BulkPreviewSample': record(subject='long', before='Map<String, JsonNode>', after='Map<String, JsonNode>', error='String?'),
        'BulkPreview': record(matchedCount='long', validation='OpsValidationResult', samples='List<BulkPreviewSample>'),
        'BulkDefinitionCreated': record(id='UUID'),
        'ExportInput': record(universeId='Long?', target='Fields.BulkTarget?', fields='List<String>?', reason='String', idempotencyKey='String?'),
        'MigrationInput': record(universeId='Long?', type='Fields.TypeExpr', default='JsonNode?', converter='Fields.Converter?',
                                 onFailure='FailurePolicy?', expectedDefinitionVersion='Long', reason='String', idempotencyKey='String?'),
        'MigrationPreviewInput': record(universeId='Long?', type='Fields.TypeExpr', default='JsonNode?', converter='Fields.Converter?',
                                        onFailure='FailurePolicy?', expectedDefinitionVersion='Long', reason='String?', idempotencyKey='String?'),
        'MigrationSample': record(subject='long', before='JsonNode', after='JsonNode'),
        'MigrationFailureSample': record(subject='long', code='String'),
        'MigrationPreview': record(affectedSubjects='long', samples='List<MigrationSample>', failureCounts='Map<String, Long>',
                                  failureSamples='List<MigrationFailureSample>', unconverted='long', canApplyDirectly='boolean'),
        'ScheduleInput': record(universeId='Long?', name='String', start='Instant', end='Instant?',
                                startActions='List<Fields.ScheduleAction>', endActions='List<Fields.ScheduleAction>?',
                                restorePrevious='boolean?', reason='String', idempotencyKey='String?', recurrence='ScheduleRecurrence?'),
        'SchedulePreview': record(start='Instant', startActions='List<Fields.ScheduleAction>', endActions='List<Fields.ScheduleAction>',
                                  restorePrevious='boolean', requiresExistingConfigResources='boolean'),
        'ScheduleSummary': record(id='UUID', state='JobState', phase='String', name='String', start='Instant', end='Instant?', recurrence='ScheduleRecurrence?'),
        'ScheduleActionResult': record(ordinal='long', done='boolean', kind='String', key='String?', version='Long?', jobId='UUID?', error='String?'),
        'ImportError': record(line='long', code='String'),
        'ImportValidation': record(dryRun='boolean', valid='boolean', records='long', errors='List<ImportError>'),
        'AlertConfigInput': record(universeId='Long?', enabled='boolean?', pendingAgeSeconds='Long?', pendingSize='Long?',
                                   stalledSeconds='Long?', configFailOpenRate='Double?', transaction5xxRate='Double?', webhook='String?'),
        'AlertConfigResponse': record(enabled='boolean', pendingAgeSeconds='long', pendingSize='long', stalledSeconds='long',
                                      configFailOpenRate='double', transaction5xxRate='double', webhookConfigured='boolean'),
        'AlertState': {'enum': ['OPEN','ACKED','RESOLVED']},
        'AlertSeverity': {'enum': ['WARNING','CRITICAL']},
        'AlertRule': {'enum': ['OUTBOX_BACKLOG','OUTBOX_FAILED','RECONCILE_MISMATCH','CONFIG_FAIL_OPEN','JOB_FAILED','JOB_STALLED','SCHEDULE_ACTION_FAILED','TRANSACTION_5XX']},
        'Alert': record(id='UUID', rule='AlertRule', severity='AlertSeverity', state='AlertState', firstSeen='Instant', lastSeen='Instant', count='long'),
        'AlertAcknowledgement': record(id='UUID', state='AlertState'),
        'OpenAlertCounts': record(WARNING='long', CRITICAL='long'),
        'HealthSummary': record(openAlerts='OpenAlertCounts', runningJobs='long', upcomingSchedules='long'),
    })
    definitions['ScheduleRecurrence'] = record(type='RecurrenceType', daysOfWeek='List<DayOfWeek>', timezone='String')
    # Definition reads may include null record components; NON_NULL may omit them.
    # Keep this distinct from ScheduleInput so requests do not accept meaningless nulls.
    import copy
    definitions['ScheduleDefinition'] = copy.deepcopy(definitions['ScheduleInput'])
    for field in definitions['ScheduleDefinition']['fields'].values(): field['required'] = True
    for name in ('universeId','end','endActions','idempotencyKey','recurrence'):
        definitions['ScheduleDefinition']['fields'][name].update(nullable=True, required=False)
    definitions['RecurrenceType'] = {'enum':['NONE','DAILY','WEEKLY']}
    definitions['DayOfWeek'] = {'enum':['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY']}
    definitions['ScheduleActionResult']['fields'].update(skipped={'java':'boolean','required':False,'nullable':True}, skipReason={'java':'String','required':False,'nullable':True})
    definitions['ScheduleRun'] = record(id='long', occurrence='long', edge='ScheduleEdge', startedAt='Instant', finishedAt='Instant?', status='ScheduleRunStatus', error='String?', actions='List<ScheduleActionResult>')
    for name in ('finishedAt','error'): definitions['ScheduleRun']['fields'][name]['nullable'] = True
    definitions['ScheduleEdge'] = {'enum':['START','END']}
    definitions['ScheduleRunStatus'] = {'enum':['RUNNING','SUCCEEDED','FAILED','CANCELLED']}
    # SQL jsonb_build_object emits explicit nulls for absent optional properties.
    for name, fields in {'JobSummary':['error'], 'ScheduleSummary':['end','recurrence'],
                         'JobReceipt':['recurrence'],
                         'ScheduleActionResult':['key','version','jobId','error'],
                         'AlertConfigInput':['webhook']}.items():
        for field in fields:
            definitions[name]['fields'][field]['nullable'] = True


def curate(endpoints: list[dict]) -> list[dict]:
    """Resolve overloaded controller methods, aliases, safe retries and NDJSON contracts."""
    jobs = [e for e in endpoints if e['source'].endswith('/JobsController.java')]
    for endpoint in jobs:
        if endpoint['name'] == 'cancel':
            for family in ('migrations','schedules'):
                alias = deepcopy(endpoint)
                alias['path'] = alias['path'].replace('/jobs/', '/'+family+'/')
                endpoints.append(alias)
        if endpoint['name'] == 'get':
            alias = deepcopy(endpoint)
            alias['path'] = alias['path'].replace('/jobs/', '/schedules/')
            endpoints.append(alias)
    for e in endpoints:
        if not e['source'].endswith('/JobsController.java'): continue
        suffix = e['path'].split('/{universeId}', 1)[1]
        routes = {
            ('POST','/definitions/{id}/migrations/preview'): ('migrationPreview','MigrationPreview','MigrationPreviewInput'),
            ('POST','/definitions/{id}/migrations'): ('migrate','JobReceipt','MigrationInput'),
            ('POST','/jobs/{id}/cancel'): ('cancelJob','JobReceipt','JobActionInput'),
            ('POST','/migrations/{id}/cancel'): ('cancelMigration','JobReceipt','JobActionInput'),
            ('POST','/schedules/{id}/cancel'): ('cancelSchedule','JobReceipt','JobActionInput'),
            ('POST','/migrations/{id}/rollback'): ('rollbackMigration','JobReceipt','KeyedJobActionInput'),
            ('POST','/bulk/preview'): ('bulkPreview','BulkPreview','BulkPreviewInput'),
            ('POST','/bulk'): ('bulk','JobReceipt','BulkInput'),
            ('POST','/bulk/definitions'): ('createBulkDefinition','BulkDefinitionCreated','BulkInput'),
            ('GET','/bulk/definitions/{id}'): ('bulkDefinition','BulkInput',None),
            ('POST','/bulk/{id}/reverse'): ('reverseBulk','JobReceipt','KeyedJobActionInput'),
            ('POST','/export'): ('export','JobReceipt','ExportInput'),
            ('POST','/import'): ('import','ImportValidation|JobReceipt','String'),
            ('GET','/jobs'): ('jobs','List<JobSummary>',None),
            ('GET','/jobs/{id}'): ('job','JobReceipt',None),
            ('POST','/jobs/{id}/retry'): ('retryJob','JobReceipt','JobActionInput'),
            ('GET','/schedules'): ('schedules','List<ScheduleSummary>',None),
            ('GET','/schedules/{id}'): ('schedule','JobReceipt',None),
            ('GET','/schedules/{id}/definition'): ('scheduleDefinition','ScheduleDefinition',None),
            ('GET','/schedules/{id}/runs'): ('scheduleRuns','List<ScheduleRun>',None),
            ('GET','/schedules/{id}/actions'): ('scheduleActions','List<ScheduleActionResult>',None),
            ('GET','/jobs/{id}/failures'): ('jobFailures','List<JobFailure>',None),
            ('GET','/jobs/{id}/failures/download'): ('jobFailuresDownload','String',None),
            ('GET','/jobs/{id}/download'): ('jobDownload','String',None),
            ('GET','/jobs/{id}/events'): ('jobEvents','List<JobEvent>',None),
            ('POST','/schedules/preview'): ('schedulePreview','SchedulePreview','ScheduleInput'),
            ('POST','/schedules'): ('createSchedule','JobReceipt','ScheduleInput'),
            ('PUT','/schedules/{id}'): ('editSchedule','JobReceipt','ScheduleInput'),
            ('POST','/schedules/{id}/end-now'): ('endSchedule','JobReceipt','JobActionInput'),
            ('GET','/alerts/config'): ('alertConfig','AlertConfigResponse',None),
            ('PUT','/alerts/config'): ('putAlertConfig','AlertConfigResponse','AlertConfigInput'),
            ('GET','/alerts'): ('alerts','List<Alert>',None),
            ('POST','/alerts/{id}/ack'): ('ackAlert','AlertAcknowledgement',None),
            ('POST','/alerts/webhook/test'): ('testWebhook','JobReceipt',None),
            ('GET','/health/summary'): ('healthSummary','HealthSummary',None),
        }
        name, response, body = routes[e['method'], suffix]
        e.update(name=name, id='fields.'+name, responseJava=response, bodyType=body,
                 responseType=name[0].upper()+name[1:]+'ResultValue', minimumLevel='READ' if name in ('healthSummary','scheduleRuns') else 'ADMIN',
                 cacheable=False, responseFormat='text' if name in ('jobDownload','jobFailuresDownload') else 'json')
        if name in ('bulk','export','migrate','rollbackMigration','reverseBulk','createSchedule'):
            e.update(idempotencyField='idempotencyKey', idempotent=True, retryable=True)
        if name == 'import':
            e.update(requestFormat='ndjson', idempotencyHeader=True, optionalKey=True, idempotent=True, retryable=True)
        if name in ('jobDownload','jobFailuresDownload'):
            e['responseContentType'] = 'application/x-ndjson'
        if name == 'jobDownload': e['errorStatuses'].append(410)
    return endpoints
