"""Audit Java read nullability separately from the curated write contract, offline."""
from __future__ import annotations

import re
from pathlib import Path

import import_contract as java
from runtime_contract import RECORD_NAMES

PRIMITIVES = {'boolean', 'byte', 'short', 'int', 'long', 'float', 'double', 'char'}
TYPE_DECLARATION = r'\b(class|record)\s+(\w+)(?:\s*<[^>]+>)?'


def inclusion(declaration: str) -> str | None:
    """Read a direct Jackson inclusion annotation without inspecting nested declarations."""
    match = re.search(r'@(?:[\w.]*\.)?JsonInclude\([^)]*\b(ALWAYS|NON_NULL|NON_EMPTY|NON_ABSENT|NON_DEFAULT)\b[^)]*\)', declaration)
    return match[1] if match else None


def type_inclusions(path: Path) -> dict[str, str | None]:
    """Find per-type inclusion; one nested member must not affect unrelated DTOs."""
    text = java.clean(path.read_text())
    result = {}
    for match in re.finditer(TYPE_DECLARATION, text):
        name = RECORD_NAMES.get(path.stem, {}).get(match[2], match[2])
        start = max(text.rfind(c, 0, match.start()) for c in (';', '{', '}')) + 1
        result[name] = inclusion(text[start:match.start()])
    return result


def members(path: Path) -> dict[str, dict[str, tuple[str, str]]]:
    """Read record components and direct class fields, preserving null annotations."""
    from service_contracts import strip_annotations
    text = java.clean(path.read_text())
    result = {}
    for match in re.finditer(TYPE_DECLARATION, text):
        kind, name = match.groups()
        name = RECORD_NAMES.get(path.stem, {}).get(name, name)
        start = text.index('(' if kind == 'record' else '{', match.end())
        body, _ = java.balanced(text, start, '(' if kind == 'record' else '{', ')' if kind == 'record' else '}')
        if kind == 'record':
            items = java.split(body)
        else:
            # Only direct declarations: methods and nested classes are audited separately.
            top, depth, quoted = [], 0, False
            for c in body:
                if c == '"': quoted = not quoted
                if not quoted and c == '{': depth += 1
                if depth == 0: top.append(c)
                if not quoted and c == '}':
                    depth -= 1
                    if depth == 0: top.append('\n')
            items = re.findall(r'((?:@[\w.]+(?:\([^\n]*?\))?\s*)*private\s+(?!static)(?:final\s+)?[\w<>?, .@]+\s+\w+\s*(?:=[^;]+)?);', ''.join(top))
        fields = {}
        for item in items:
            declaration = strip_annotations(item).removeprefix('private ').removeprefix('final ').split('=')[0].strip()
            parsed = re.fullmatch(r'(.+?)\s+(\w+)', declaration)
            if not parsed or '@JsonIgnore' in item: continue
            typ, field = parsed.groups()
            wire = re.search(r'@(?:[\w.]*\.)?JsonProperty\("([^"]+)"\)', item)
            if wire: field = wire[1]
            fields[field] = (typ, item)
        result[name] = fields
    return result


def response_names(doc: dict, service: str) -> set[str]:
    """Collect the transitive response DTO graph, including inherited members."""
    from gen import schema
    needed: set[str] = set()
    def visit(node: dict) -> None:
        """Walk recursive schema nodes once per named definition."""
        if node['kind'] == 'ref':
            name = node['name']
            if name in needed: return
            needed.add(name)
            definition = doc['types'][service][name]
            if definition.get('parent'): visit(schema(definition['parent']))
            for field in definition.get('fields', {}).values(): visit(schema(field['java']))
        if 'item' in node: visit(node['item'])
        for child in node.get('items', []): visit(child)
    for endpoint in doc['endpoints']:
        if endpoint['service'] == service: visit(schema(endpoint['responseJava']))
    return needed


def curate_reads(doc: dict) -> None:
    """Persist conservative read semantics; generator never needs sibling source trees."""
    from service_contracts import SOURCE_ROOT, SOURCES
    cache: dict[Path, dict[str, dict[str, tuple[str, str]]]] = {}
    includes: dict[Path, dict[str, str | None]] = {}
    for service, definitions in doc['types'].items():
        # Health is one shared SDK contract, never a model of actuator internals.
        definitions['HealthResponse'] = {'fields': {'status': {'java': 'String', 'required': True}}}
        for endpoint in doc['endpoints']:
            if endpoint['service'] == service and endpoint['name'] == 'healthProxy':
                endpoint['responseJava'] = 'HealthResponse'
        root = SOURCES.get(service)
        properties = root / 'src/main/resources/application.properties' if root else None
        omit_nulls = bool(properties and properties.is_file() and re.search(
            r'spring\.jackson\.default-property-inclusion\s*=\s*non_null', properties.read_text(), re.I))
        for name in sorted(response_names(doc, service)):
            definition = definitions[name]
            source = SOURCE_ROOT / definition.get('source', '')
            source_fields = {}
            class_inclusion = 'NON_NULL' if omit_nulls else 'ALWAYS'
            if source.is_file() and source.suffix == '.java':
                if source not in cache:
                    cache[source] = members(source)
                    includes[source] = type_inclusions(source)
                source_fields = cache[source].get(name, {})
                class_inclusion = includes[source].get(name) or class_inclusion
            for field, info in definition.get('fields', {}).items():
                info.pop('responseNullable', None)
                info.pop('responseRequired', None)
                if field not in source_fields:
                    # Curated map-built responses have explicit required guarantees. Optional
                    # reference fields remain tolerant of both omitted and explicit JSON null.
                    if not info['required'] and info['java'] not in PRIMITIVES:
                        info['responseNullable'] = True
                    continue
                typ, declaration = source_fields[field]
                prefix = declaration.split('<')[0]
                field_inclusion = inclusion(prefix) or class_inclusion
                nonnull = typ in PRIMITIVES or bool(re.search(r'@(\w+\.)*(NonNull|Nonnull|NotNull|NotBlank|NotEmpty)\b', prefix))
                if field_inclusion in ('NON_EMPTY', 'NON_ABSENT', 'NON_DEFAULT'):
                    info['responseRequired'] = False
                if nonnull: continue
                info['responseNullable'] = True
                if field_inclusion == 'NON_NULL':
                    info['responseRequired'] = False
    # These queue identities/containers are always populated in MatchmakingService.
    # Keep ids strings, primitive booleans/counts required, and only actual nullable
    # branches nullable (no queue, solo/party metrics, unfiltered flush, empty estimate).
    guaranteed = {
        'PlayerQueueStatusResponse': {'userId', 'universeId', 'inQueue'},
        'BulkQueueStatusResponse': {'results'},
        'QueueCountResponse': {'universeId', 'gameModeName', 'queuedPlayerCount', 'timestamp'},
        'QueueFlushResponse': {'success', 'removedCount', 'universeId'},
        'QueueMetricsResponse': {'totalPlayersInQueue', 'universeBreakdown', 'timestamp'},
        'UniverseQueueInfo': {'universeId', 'totalPlayers', 'gameModes'},
        'GameModeQueueInfo': {'gameModeName', 'playerCount', 'players'},
        'WaitEstimateResponse': {'universeId', 'gameModeName', 'queuedPlayerCount', 'maxMatchSize', 'playersNeeded'},
        'ValidateQueueResponse': {'valid', 'errors'},
    }
    for name, fields in guaranteed.items():
        definition = doc['types'].get('matchmaking', {}).get(name)
        if not definition: continue
        for field, info in definition['fields'].items():
            info['responseRequired'] = True
            info['responseNullable'] = field not in fields
