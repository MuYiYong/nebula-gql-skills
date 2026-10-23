"""Narrow disposable-fixture executor. No model-provided persistent operations."""
from __future__ import annotations

import hashlib
import json
import re
import uuid
from pathlib import Path

from skill_tools import lint, tokens
from validate_database import materialize

ROOT = Path(__file__).resolve().parents[2]


def literal(value):
    if value is None:
        return 'NULL'
    if type(value) is bool:
        return 'TRUE' if value else 'FALSE'
    if type(value) is int:
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    raise ValueError('Fixture parameters allow only NULL, bool, int and string')


def guard(query, case):
    """An execution subset, not a claim about all legal GQL.

    Generated WHILE is allowed only for the suite's explicitly bounded counting
    contract. There is no trusted server cancellation for arbitrary loops.
    """
    query = query.strip().removesuffix(';')
    if len(query) > 20000:
        raise ValueError('Generated body exceeds fixture budget')
    ts = tokens(query)
    words = [value.upper() for kind, value in ts if kind == 'word']
    if set(case.get('required_constructs', [])) - set(words):
        raise ValueError('Missing explicitly requested construct')
    banned = {
        'USE', 'CREATE', 'ALTER', 'DROP', 'INSERT', 'DELETE', 'DETACH', 'REMOVE',
        'IMPORT', 'FILE', 'DATAFILE', 'LOAD', 'COPY', 'SUBMIT', 'KILL', 'SESSION',
        'GRANT', 'REVOKE', 'GRAPH', 'PARAMETERS', 'LOG', 'LOG_INFO', 'PARTITION',
    }
    if not ts or banned.intersection(words) or any(value == ';' for _, value in ts):
        raise ValueError('Outside disposable execution subset')
    if '/*+' in query:
        raise ValueError('Model-provided execution hints are not allowed')
    for index, (kind, value) in enumerate(ts):
        if kind == 'word' and value.upper() == 'CALL':
            if index + 1 >= len(ts) or ts[index + 1][1] != '{':
                raise ValueError('Only inline CALL is allowed')
        if kind == 'param' and value[1:] not in case['parameter_sets'][0]:
            raise ValueError('Unexpected parameter')
    clean = ' '.join(value if kind not in {'string', 'quoted'} else '?' for kind, value in ts)
    if re.search(r'\]\s*(?:-\s*>|-|~)\s*[+*]', clean):
        raise ValueError('Unbounded path outside fixture budget')
    if re.search(r'\{\s*\d*\s*,\s*\}', clean):
        raise ValueError('Open-ended quantified path')
    if any(int(upper) > 3 for upper in re.findall(r'\{\s*\d+\s*,\s*(\d+)\s*\}', clean)):
        raise ValueError('Path exceeds requested three-hop bound')
    # SET can update declared scalar/aggregate state, never graph properties.
    declared = set(re.findall(r'\bVALUE\s+(\w+)\b', clean, re.I))
    for match in re.finditer(r'\bSET\s+([^=+]+)(?:\+=|=)', clean, re.I):
        target = match.group(1).replace(' ', '')
        local = re.fullmatch(r'@?(\w+)', target)
        node_agg = re.fullmatch(r'\w+\.@(\w+)', target)
        name = local.group(1) if local else node_agg.group(1) if node_agg else None
        if name not in declared:
            raise ValueError('SET target is not declared local state')
    tables = set(re.findall(r'\bTABLE\s+(\w+)\s+(?:TYPED|::|\{)', clean, re.I))
    for target in re.findall(r'\bEXPORT\b.*?\bINTO\s+(\w+)', clean, re.I | re.S):
        if target not in tables:
            raise ValueError('EXPORT target must be a declared local table')
    if 'EXPORT' in words and not re.search(r'\bEXPORT\b.*?\bINTO\s+\w+', clean, re.I | re.S):
        raise ValueError('Unknown EXPORT form')
    for iterable in re.findall(r'\bFOR\s+\w+\s+IN\s+(\w+)', clean, re.I):
        if iterable not in tables:
            raise ValueError('FOR source must be the bounded local result table')
    if 'WHILE' in words:
        if case['oracle'] != 'sum' or words.count('WHILE') != 1:
            raise ValueError('Unproven loop termination')
        # Only the explicitly requested increment loop: i=1; i<=n; tail i=i+1.
        if not re.search(r'\bVALUE\s+i(?:\s+(?:INT64|INT))?\s*=\s*1\b', clean, re.I):
            raise ValueError('Unknown loop initialization')
        if not re.search(r'\bWHILE\s+i\s*<\s*=\s*\$n\s+THEN\s*\{', clean, re.I):
            raise ValueError('Unknown loop condition')
        assignments = re.findall(r'\bSET\s+i\s*=\s*([^}]+)', clean, re.I)
        if len(assignments) != 1 or not re.fullmatch(r'\s*i\s*\+\s*1\s*', assignments[0]):
            raise ValueError('Loop counter must advance once at the tail')
        if any(word in words for word in ['CONTINUE', 'BREAK', 'IF', 'FOR']):
            raise ValueError('Loop progress could be bypassed')
        if any(not isinstance(p['n'], int) or not -2 <= p['n'] <= 6 for p in case['parameter_sets']):
            raise ValueError('Loop parameter outside proven bound')
    if case['stratum'] == 'query' and any(word in words for word in ['SET', 'EXPORT', 'WHILE']):
        raise ValueError('Query contains procedure effects')
    if case['stratum'] == 'database_procedure' and 'MATCH' in words:
        raise ValueError('Scalar procedure fixture cannot access a graph')
    skill = 'gql-query-generator' if case['stratum'] == 'query' else 'gql-procedure-generator'
    static = lint(query, ROOT / 'src' / skill, 'database')
    # Documented special signatures need review but are not automatically invalid.
    if static['issues']:
        raise ValueError('Static capability/structure findings need resolution')
    reviewed_special = {'Special signature requires checking: size', 'Special signature requires checking: coalesce'}
    if set(static['needs_review']) - reviewed_special:
        raise ValueError('Unreviewed signature or receiver')
    return query, static['needs_review']


def statement(query, case, params, graph=None):
    prefix = ''
    if params:
        prefix = 'PARAMETERS ' + ', '.join(f'${k} = {literal(v)}' for k, v in params.items()) + ' '
    if case['stratum'] == 'database_procedure':
        return prefix + 'CALL { ' + query + ' } RETURN *'
    if graph is None or not re.fullmatch(r'gql_quality_[0-9a-f]{32}', graph):
        raise ValueError('Missing owned fixture graph')
    return prefix + f'USE #{graph} {{ {query} }}'


def seed_statement(fixture):
    if not fixture['nodes']:
        return None
    aliases = {node['id']: f'n{i}' for i, node in enumerate(fixture['nodes'])}
    parts = []
    for node in fixture['nodes']:
        properties = ','.join(key + ':' + literal(node[key]) for key in ('id', 'name', 'age'))
        parts.append('(' + aliases[node['id']] + '@player {' + properties + '})')
    for edge in fixture['edges']:
        parts.append('(' + aliases[edge['src']] + ')-[@follow {degree:' + literal(edge['degree']) + '}]->(' + aliases[edge['dst']] + ')')
    return 'INSERT ' + ', '.join(parts)


class CleanupFailure(RuntimeError):
    pass


class OwnedGraph:
    def __init__(self, client, graph_type):
        if not graph_type.isidentifier():
            raise ValueError('Fixture graph type must be a simple identifier')
        self.client = client
        self.graph_type = graph_type
        self.name = 'gql_quality_' + uuid.uuid4().hex
        self.created = False
        self.cleaned = False

    def __enter__(self):
        result = self.client.execute(f'CREATE TEMPORARY GRAPH #{self.name} TYPED `{self.graph_type}`')
        if not result.is_succeeded:
            raise RuntimeError('Temporary graph creation failed: ' + result.status_code)
        self.created = True
        return self

    def seed(self, fixture):
        query = seed_statement(fixture)
        if query:
            result = self.client.execute(f'USE #{self.name} ' + query)
            if not result.is_succeeded:
                raise RuntimeError('Synthetic seed failed: ' + result.status_code)
        # Verify all rows/properties and parallel edges before trusting any oracle.
        from evaluate import compare_results
        nodes = materialize(self.client.execute(f'USE #{self.name} MATCH (p@player) RETURN p.id AS id, p.name AS name, p.age AS age'))
        edges = materialize(self.client.execute(f'USE #{self.name} MATCH (s@player)-[e@follow]->(t@player) RETURN s.id AS src, t.id AS dst, e.degree AS degree'))
        expected_nodes = {'columns': ['id', 'name', 'age'], 'rows': [[n['id'], n['name'], n['age']] for n in fixture['nodes']]}
        expected_edges = {'columns': ['src', 'dst', 'degree'], 'rows': [[e['src'], e['dst'], e['degree']] for e in fixture['edges']]}
        if nodes['status'] != '00000' or edges['status'] != '00000' or not compare_results(expected_nodes, nodes) or not compare_results(expected_edges, edges):
            raise RuntimeError('Synthetic fixture identity mismatch')

    def __exit__(self, exc_type, exc, traceback):
        if self.created:
            result = self.client.execute(f'DROP GRAPH #{self.name}')
            self.cleaned = result.is_succeeded
            if not self.cleaned:
                # Exact owned name permits recovery; never issue wildcard cleanup.
                raise CleanupFailure(f'Cleanup failed for owned #{self.name}: {result.status_code}')
        return False
