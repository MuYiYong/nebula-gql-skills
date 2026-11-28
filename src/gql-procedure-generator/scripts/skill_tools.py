#!/usr/bin/env python3
"""Standalone bounded reference lookup and conservative GQL lint (stdlib only).

Lint is not a GQL parser/type checker. Findings are violations of documented
contracts; an empty finding list means only that these checks found no issue.
"""
from __future__ import annotations

import argparse
from bisect import bisect_right
from collections import ChainMap
import json
import re
from pathlib import Path
from typing import NamedTuple


def sections(path):
    lines = path.read_text(encoding='utf-8').splitlines()
    starts = [i for i, line in enumerate(lines) if re.match(r'^#{1,6} ', line)]
    for n, start in enumerate(starts):
        end = starts[n + 1] if n + 1 < len(starts) else len(lines)
        yield lines[start], start + 1, '\n'.join(lines[start:end])


def lookup(root, term, kind='function', offset=0, limit=6000, all_matches=False):
    files = ([root / 'references/documented-functions.md'] if kind == 'function'
             else sorted((root / 'references').glob('*.md')))
    found = []
    needle = re.compile(r'(?<!\w)' + re.escape(term) + r'(?!\w)', re.I)
    for path in files:
        for title, line, body in sections(path):
            key = title.lstrip('# ').strip('`').removesuffix('()')
            if (kind == 'function' and key.casefold() == term.casefold().removesuffix('()')) or (
                kind == 'topic' and needle.search(body)
            ):
                normalized = re.sub(r'^\d+[.)]\s*', '', key).replace('`','').strip()
                rank = 0 if normalized.casefold()==term.casefold() else 1 if needle.search(normalized) else 2
                catalog_rank = 0 if path.name.startswith('documented-') else 1
                found.append(((rank,catalog_rank,path.name,line),f'{path.relative_to(root)}:{line}\n{body}'))
    found.sort(key=lambda item:item[0])
    other_matches=0
    if kind=='topic' and found and not all_matches and found[0][0][0]<2:
        best_rank=found[0][0][0]
        selected=[item for item in found if item[0][0]==best_rank]
        other_matches=len(found)-len(selected);found=selected
    content = '\n\n'.join(body for _,body in found)
    return {'matches': len(found), 'other_matches':other_matches,
            'hint':'Use --all-matches for cross-topic body mentions' if other_matches else None, 'offset': offset, 'total_chars': len(content),
            'next_offset': offset + limit if offset + limit < len(content) else None,
            'text': content[offset:offset + limit]}


TOKEN = re.compile(r'''(?P<space>\s+)|(?P<comment>--[^\n]*|//[^\n]*|/\*[\s\S]*?\*/)|(?P<string>'(?:''|\\.|[^'\\])*'|"(?:""|\\.|[^"\\])*")|(?P<quoted>`(?:``|[^`])*`)|(?P<param>\$(?:`(?:``|[^`])*`|[\w$]+))|(?P<temp>\#[^\W\d][\w$]*)|(?P<word>[^\W\d]\w*)|(?P<number>\d+(?:\.\d+)?)|(?P<symbol>.)''', re.UNICODE)


def token_matches(code):
    return (m for m in TOKEN.finditer(code) if m.lastgroup not in {'space', 'comment'})


def tokens(code):
    return [(m.lastgroup, m.group()) for m in token_matches(code)]


def split_args(ts):
    result, current, stack = [], [], []
    for token in ts:
        value = token[1]
        if value in ('(', '[', '{'): stack.append(value)
        elif value in (')', ']', '}') and stack: stack.pop()
        if value == ',' and not stack:
            result.append(current); current = []
        else: current.append(token)
    if current: result.append(current)
    return result


def catalog(root):
    result = {}
    for title, _, body in sections(root / 'references/documented-functions.md'):
        name = title.lstrip('# ').strip('`')
        if name.endswith('()'):
            name = name[:-2].lower()
            entry = result.setdefault(name, {'bodies': [], 'signatures': [], 'scope': set()})
            entry['bodies'].append(body)
            entry['signatures'] += re.findall(r'```text\n([\s\S]*?)\n```', body)
            scope = re.search(r'- Scope: (.*)', body)
            if scope: entry['scope'].update(scope.group(1).lower().split())
    return result


def arities(signatures, name):
    """Parse comma-style signatures only; special grammar stays explicitly unknown."""
    choices = set()
    for sig in signatures:
        pattern = r'(?im)^\s*' + re.escape(name.split('.')[-1]) + r'\s*\((.*?)\)\s*(?:->|$)'
        for m in re.finditer(pattern, sig):
            args = m.group(1).strip()
            if any(s in args for s in ('...', '|', ' FROM ', ' AS ', '->')):
                continue
            if not args: choices.add((0, 0)); continue
            # Type parameters can contain commas; strip their interiors first.
            simple = re.sub(r'<[^<>]*>', 'TYPE', args)
            first_optional = simple.find('[')
            required = simple if first_optional < 0 else simple[:first_optional]
            minimum = len(re.findall(r'\b\w+\s*:', required))
            maximum = len(re.findall(r'\b\w+\s*:', simple))
            if maximum: choices.add((minimum, maximum))
    return choices


STRUCTURAL = {'MATCH', 'OPTIONAL', 'IF', 'WHILE', 'FOR', 'IN', 'EXISTS', 'NOT',
              'NODE', 'EDGE', 'PATH', 'RECORD', 'TABLE', 'LIST', 'SET', 'MAP',
              'VECTOR', 'GRAPH', 'ACYCLIC', 'TRAIL', 'WALK', 'SIMPLE', 'CALL',
              'YIELD', 'RETURN', 'DISTINCT', 'WHERE', 'FILTER', 'AND', 'OR',
              'THEN', 'ELSE', 'NEXT', 'UNION', 'INSERT', 'UPDATE', 'CAST', 'RETURNS', 'PARTITION'}


def quote_identifier(name, root=None):
    """Format one raw identifier, not an expression or an already quoted name."""
    if not name or len(name) > 127 or '`' in name or any(ord(c) < 32 for c in name):
        raise ValueError('Expected one raw identifier of 1..127 characters without backticks/control characters')
    if name.startswith('@'):
        raise ValueError('Identifier cannot start with @; format the name separately from its prefix')
    return '`' + name.replace('\\', '\\\\') + '`'


def catalog_path_positions(ts, values):
    """Collect only name segments, leaving IF clauses and path separators intact."""
    found = {}
    for i, word in enumerate(values):
        if ts[i][0] != 'word' or word not in {'USE', 'CALL', 'PROCEDURE', 'GRAPH', 'SCHEMA', 'INDEX', 'TYPE'}:
            continue
        prev = values[i-1] if i else ''
        if word == 'TYPE' and prev not in {'GRAPH', 'NODE', 'EDGE'}:
            continue
        j = i+1
        if values[j:j+3] == ['IF', 'NOT', 'EXISTS']:
            j += 3
        elif values[j:j+2] == ['IF', 'EXISTS']:
            j += 2
        while j < len(ts) and values[j] in {'/', '.'}:
            j += 1
        while j < len(ts) and ts[j][0] in {'word', 'quoted', 'string'}:
            has_next = j+2 < len(ts) and values[j+1] in {'/', '.'} and ts[j+2][0] in {'word', 'quoted', 'string'}
            if has_next or j > i+1:
                found[j] = 'catalog path'
            if not has_next:
                break
            j += 2
    return found


DDL_KEYS = {'PRIMARY KEY', 'MULTIEDGE KEY'}


def ddl_key_clause(ts, values, i):
    """Return the keyword phrase and its last token in a DDL constraint slot."""
    head = ' '.join(values[i].removeprefix('`').removesuffix('`').upper().split())
    end = i
    if head in {'PRIMARY', 'MULTIEDGE'} and i + 1 < len(ts) and values[i+1].upper() in {'KEY', '`KEY`'}:
        head += ' KEY'
        end += 1
    if head not in DDL_KEYS or end + 1 >= len(ts):
        return None
    prev, following = values[i-1], values[end+1]
    if prev in {'{', ','}:
        # A name such as `PRIMARY KEY` followed by a type declares a property.
        if following == '(':
            return head, end
    elif following in {',', '}', 'NOT', 'NULL', 'DEFAULT'} and prev != 'DEFAULT':
        # Inline constraints can follow a type, a nullability constraint or a default.
        if ts[i-1][0] != 'symbol' or prev in {')', ']', '}', '>'}:
            return head, end
    return None


def token_roles(ts, keywords=(), non_reserved=()):
    """Recognize clear identifier and DDL constraint positions for lint."""
    values = [v.upper() if k == 'word' else v for k, v in ts]
    found = catalog_path_positions(ts, values)
    stack = []
    pattern = False
    expression_forms = {'ALL', 'DISTINCT', 'CASE', 'NOT', 'EXISTS', 'TRUE', 'FALSE', 'NULL',
                        'UNKNOWN', 'NAN', 'INFINITY', 'CURRENT_DATE', 'CURRENT_TIME', 'CURRENT_TIMESTAMP',
                        'CURRENT_GRAPH', 'CURRENT_PROPERTY_GRAPH', 'CURRENT_SCHEMA',
                        'CURRENT_USER', 'CURRENT_ROLE', 'CURRENT_SESSION', 'SESSION_USER',
                        'SYSTEM_USER', 'LOCAL_TIME', 'LOCAL_TIMESTAMP', 'LOCAL_DATETIME'}
    constructors = {'LIST': '[', 'RECORD': '{', 'TABLE': '{', 'MAP': '{', 'VECTOR': '<',
                    'VALUE': '{', 'GRAPH': '{', 'SET': '{', 'PATH': '['}
    ann_keys = {'TYPE', 'DIM', 'METRIC', 'NLIST', 'TRAINSIZE', 'MAXDEGREE',
                'EFCONSTRUCTION', 'CAPACITY', 'NPROBE', 'EFSEARCH'}
    pattern_prefixes = {'MATCH', '=', ',', '>', '-', '~', 'OPTIONAL', 'ACYCLIC',
                        'TRAIL', 'WALK', 'SIMPLE', 'SHORTEST', 'INSERT', 'UPDATE', 'REPLACE', 'IGNORE', '}', '+', '*'}
    operand_prefixes = {'(', '[', ',', ':', '=', '+', '-', '/', '*', '%', '|',
                        'THEN', 'ELSE', 'WHEN', 'EXPORT', 'IN', 'FROM', 'WHILE',
                        'IF', 'AND', 'OR', 'NOT', 'DELETE', 'YIELD'}
    # Track comma-separated expressions at the depth of their clause. Nested
    # calls and type specifications have their own argument grammar.
    list_depth = None
    graph_type_header = False

    def mark(index, role):
        if 0 <= index < len(ts) and ts[index][0] in {'word', 'quoted', 'string'}:
            found.setdefault(index, role)

    for i, (kind, value) in enumerate(ts):
        word = values[i]
        prev = values[i-1] if i else ''
        after = values[i+1] if i+1 < len(ts) else ''
        if prev == 'GRAPH' and word == 'TYPE':
            before_graph = i-3 if i >= 3 and values[i-2] == 'PROPERTY' else i-2
            graph_type_header = before_graph >= 0 and values[before_graph] in {'CREATE', 'REPLACE', 'ALTER'}
        elif word == ';':
            graph_type_header = False
        parent = stack[-1][1] if stack else None
        if word == 'DATE' or (word == 'LOCAL' and after == 'DATE'):
            end = i + 1 if word == 'LOCAL' else i
            declaration = (i > 0 and ts[i-1][0] == 'quoted') or found.get(i-1) in {
                'DDL property', 'field', 'declaration', 'name or binding',
                'declaration or target', 'parameter or return column',
            }
            type_argument = (prev == '<' and values[i-2] in {'LIST', 'SET', 'MAP', 'VECTOR'}
                             or prev == ',' and values[end+1:end+2] == ['>'])
            cast_type = prev == 'AS' and stack and stack[-1][2] == 'CAST'
            date_literal = end+1 < len(ts) and ts[end+1][0] == 'string'
            if ((i == 0 and word == 'LOCAL') or declaration or type_argument or cast_type or date_literal
                    or prev == 'TYPED' or values[max(0, i-2):i] == [':', ':']):
                if word == 'LOCAL':
                    found[i] = 'calendar date qualifier'
                continue
        if parent == 'property definitions' and kind in {'word', 'quoted'}:
            if found.get(i) in DDL_KEYS:
                continue
            clause = ddl_key_clause(ts, values, i)
            if clause:
                phrase, end = clause
                for j in range(i, end + 1):
                    found[j] = phrase
                continue
        # Generic type arguments may contain commas, which do not start a new property.
        if parent in {'property definitions', 'type arguments'}:
            if word == '<' and prev in {'LIST', 'SET', 'MAP', 'VECTOR', 'RECORD'}:
                stack.append(('<', 'type arguments', prev))
                continue
            if parent == 'type arguments':
                if word == '>':
                    stack.pop()
                if word not in {'(', '[', '{'}:
                    continue
        if kind == 'word' and word in {'RETURN', 'YIELD', 'BY', 'EXPORT'}:
            list_depth = len(stack)
        elif word in {'NEXT', 'MATCH', 'CALL', 'LIMIT', 'OFFSET', 'UNION', ';'}:
            list_depth = None
        if kind == 'word' and word in {'MATCH', 'INSERT'}:
            pattern = True
            if i+2 < len(ts) and values[i+2] == '=':
                mark(i+1, 'path binding')
        if kind == 'word' and word in {'RETURN', 'PER', 'SET', 'NEXT'}:
            pattern = False
        if kind == 'word' and word == 'WHERE' and not any(s[1] == 'pattern' for s in stack):
            pattern = False
        if kind == 'symbol' and value in {'(', '[', '{'}:
            context = 'expression'
            if value == '{' and i >= 2 and (prev == 'TABLE' or values[i-2] in {'FILE', 'TABLE'}):
                context = 'fields'
            if value == '{' and prev == 'OPTIONS':
                context = 'options'
            if value in {'(', '['} and (prev in {'LABELED', '!', '&', '|'}
                    or stack and (stack[-1][1] == 'labels' or
                                  stack[-1][1] == 'pattern' and prev in {':', 'IS'})):
                context = 'labels'
            if value == '(':
                if prev in {'NODE', 'PARTITION'} and i >= 2 and values[i-2] == 'PER':
                    mark(i+1, 'compute binding')
                if i >= 2 and (values[i-2] == 'PROCEDURE' or prev == 'RETURNS'):
                    context = 'parameters'
                elif context != 'labels' and pattern and (prev in pattern_prefixes
                                  or (stack and stack[-1][1] == 'pattern' and prev == '(')):
                    context = 'pattern'
                elif (i+2 < len(ts) and values[i+2] in {':', '@', 'IS', '{', 'WHERE'}
                      and (i == 0 or ts[i-1][0] != 'word' or prev in STRUCTURAL)):
                    context = 'pattern'
            elif value == '[' and prev in {'-', '~', '<'}:
                context = 'pattern'
            elif value == '[' and (prev in {'@', 'LABELED'} or values[max(0, i-2):i] in (['@', '!'], ['ELEMENT', 'TYPED'], ['TYPED', '!'])):
                context = 'types'
            if value == '{' and graph_type_header:
                context = 'graph type body'
                graph_type_header = False
            elif parent == 'graph type body' and value in {'(', '['}:
                context = 'element type filler'
                if value == '(' and values[i+2:i+3] == [')']:
                    mark(i+1, 'endpoint type')
            elif parent == 'element type filler' and value == '{':
                context = 'property definitions'
            elif parent == 'property definitions' and value == '(' and found.get(i-1) in DDL_KEYS:
                context = 'key members'
            stack.append((value, context, prev))
            if context == 'pattern' and after not in {'WHERE', 'IS', 'SAMPLE'}:
                mark(i+1, 'pattern binding')
        elif kind == 'symbol' and value in {')', ']', '}'}:
            if stack:
                stack.pop()
        if kind not in {'word', 'quoted', 'string'}:
            continue
        if parent == 'element type filler' and prev in {':', 'IS', 'LABEL', 'LABELS', '&'}:
            mark(i, 'label')
        if parent == 'property definitions' and prev in {'{', ','}:
            mark(i, 'DDL property')
            continue
        if parent == 'key members' and prev in {'(', ','}:
            mark(i, 'key member')
            continue
        if prev == 'AS' and not (stack and stack[-1][2] == 'CAST'):
            found[i] = 'alias'
        if prev == '.' and (i < 2 or values[i-2] != '.') and after != '(':
            mark(i, 'qualified name or property')
        if (after == ':' and values[i+1:i+3] != [':', ':']
                and not (stack and (stack[-1][1] == 'options' and word in ann_keys
                                    or stack[-1][2] == 'MAP' and kind == 'string'))):
            mark(i, 'field or pattern binding')
        if stack and (stack[-1][1] == 'labels' or stack[-1][1] == 'pattern' and prev in {':', '|', '&'}):
            mark(i, 'label or type')
        if (prev == 'IS' and stack and stack[-1][1] == 'pattern'
                and word not in {'NOT', 'TYPED', 'DIRECTED', 'SOURCE', 'DESTINATION', 'NULL'}):
            mark(i, 'label')
        if stack and stack[-1][1] == 'fields' and prev in {'{', ','}:
            mark(i, 'field')
        if stack and stack[-1][1] == 'types' and prev in {'[', ','}:
            mark(i, 'type')
        if ((prev in {'@', 'LABELED', '!', 'LABEL', 'LABELS'} and i-1 not in found)
                or (prev == 'TYPED' and i >= 2 and values[i-2] == 'ELEMENT')):
            mark(i, 'type or aggregator name')
        if values[i+1:i+3] == ['-', '>']:
            mark(i, 'lambda binding')
        if (prev in {'LET', 'VALUE', 'FOR', 'YIELD', 'PROCEDURE', 'CALL', 'USE'} and i-1 not in found
                and not (prev == 'PROCEDURE' and (word == 'IF' or kind == 'string' and values[i-2:i] == ['SHOW', 'PROCEDURE']))
                and not (prev == 'USE' and word in {'GRAPH', 'HOME_GRAPH', 'CURRENT_GRAPH'})):
            mark(i, 'name or binding')
        if (prev in {'GRAPH', 'SCHEMA', 'INDEX'} and i-1 not in found
                and word not in {'TYPE', 'IF', 'ON'}):
            mark(i, 'catalog object')
        if prev in {'RETURNS', 'FILE', 'TABLE', 'INTO', 'OF'} and i-1 not in found and word not in {'GRAPH', 'TABLE', 'IF', 'NULL'}:
            mark(i, 'declaration or target')
        if prev == 'TO' and i >= 2 and values[i-2] == 'RENAME':
            mark(i, 'catalog object')
        if prev == 'TYPE' and i >= 2 and values[i-2] in {'GRAPH', 'NODE', 'EDGE'} and word != 'IF':
            mark(i, 'element or graph type')
        if prev in {'NODE', 'EDGE', 'VERTEX', 'RELATIONSHIP'} and after == '(' and word != 'TYPE':
            mark(i, 'element type')
        if (prev == 'TYPED' and word not in {'GRAPH', 'TABLE'} and
                ('GRAPH' in values[max(0, i-3):i-1] or found.get(i-2) == 'catalog path')):
            mark(i, 'graph type')
        if (values[i+1:i+3] == [':', ':'] or after == 'TYPED') and word not in {'ELEMENT', 'NOT', 'IS'}:
            mark(i, 'typed declaration')
        if stack and stack[-1][1] == 'parameters' and prev in {'(', ','} and after not in {',', ')', '<'}:
            mark(i, 'parameter or return column')
        # Parameter/column declarations and multi-variable LET declarations.
        scalar = r'(?:U?INT(?:EGER)?\d*|STRING|BOOL(?:EAN)?|DOUBLE|FLOAT\d*|DECIMAL|DATE|TIME|TIMESTAMP|DURATION|LIST|SET|MAP|RECORD|VECTOR|NODE|EDGE|PATH|TABLE)'
        if (re.fullmatch(scalar, after) or values[i+1:i+3] == ['LOCAL', 'DATE']
                or after.endswith('AGG') and values[i+2:i+3] == ['<']):
            if prev in {'(', '{', ',', 'VALUE', 'PARAMETER', 'RETURNS'}:
                mark(i, 'declaration')
        if (i == 0 and after == '=') or (prev == ',' and after in {'=', 'IN'}):
            mark(i, 'binding')
        if prev == 'SET' and after in {'.', ':', '=', '+', '-'}:
            mark(i, 'assignment target')
        if after == '.' and i+2 < len(ts) and (ts[i+2][0] in {'word', 'quoted'} or values[i+2] == '@'):
            mark(i, 'qualified name')
        if prev in {'|', '&'} and (i < 2 or values[i-2] != '|') and after != '|':
            mark(i, 'label expression')
        # Exclude calls, typed literals and constructors before looking at
        # expression slots. The same spelling can be a label, function or type.
        if prev == ',' and after == '<' and values[max(0, i-4):i-2] == ['MAPAGG', '<']:
            continue  # MapAgg<key_type, nested_aggregator<...>>
        if (kind != 'word' or after == '(' or word in expression_forms
                or constructors.get(word) == after or word in constructors and after == '<'
                or i+1 < len(ts) and ts[i+1][0] == 'string'):
            continue
        if (prev in {'RETURN', 'DISTINCT', 'BY', 'WHERE', 'FILTER'}
                and values[max(0, i-1):i+1] != ['FILTER', 'WHERE']
                and values[max(0, i-2):i+1] != ['PARTITION', 'BY', 'DEFAULT']):
            mark(i, 'expression name')
        if prev == ',' and len(stack) == list_depth and after != '>':
            mark(i, 'list item')
        if stack and stack[-1][1] in {'options', 'parameters'}:
            continue
        plain_operand = word not in keywords
        keyword_operand = (word in non_reserved
                           and after in {'', ',', ')', ']', '}', ';', 'AS', '.', '=', '+', '-', '*', '/', '<', '>'}
                           and not (stack and stack[-1][2] in {'NORMALIZE', 'TRIM', 'CAST', 'EXTRACT'}))
        if ((plain_operand or keyword_operand)
                and (prev in operand_prefixes or prev in {'<', '>'} and plain_operand
                     or values[max(0, i-2):i] == ['-', '>'])):
            mark(i, 'expression name')
    return found


# Only infer cardinalities and assignments with a known overload and a complete RHS.
SIZE_TYPES = {'LIST': 'INT32', 'SET': 'INT32', 'MAP': 'INT32', 'TABLE': 'INT64'}
SIZED_AGGS = {'LISTAGG', 'SETAGG', 'MAPAGG', 'TOPKAGG'}
AGG_TYPES = SIZED_AGGS | {'SUMAGG', 'AVGAGG', 'MINAGG', 'MAXAGG', 'ANDAGG', 'ORAGG'}
INTEGER_TYPES = {'INT8', 'INT16', 'INT32', 'INT64', 'UINT8', 'UINT16', 'UINT32', 'UINT64'}
PROCEDURE_STATEMENTS = {'VALUE', 'NODE', 'TABLE', 'MATCH', 'OPTIONAL', 'SET', 'RETURN',
                        'FINISH', 'IF', 'FOR', 'WHILE', 'CALL', 'NEXT', 'EXPORT', 'USE',
                        'LET', 'FILTER', 'LOG_INFO', 'PER', 'FINALLY', '}', ';'}


class Declaration(NamedTuple):
    kind: str
    type: str
    index: int


def symbol_name(ts, i):
    if 0 <= i < len(ts):
        kind, value = ts[i]
        if kind == 'quoted':
            return value[1:-1]
        if kind == 'word':
            return value
    return None


def delimiter_ends(values):
    stack, closing = [], {}
    for i, token in enumerate(values):
        if token in ('(', '[', '{'):
            stack.append(i)
        elif token in (')', ']', '}') and stack:
            start = stack.pop()
            if (values[start], token) in (('(', ')'), ('[', ']'), ('{', '}')):
                closing[start] = i
    return closing


def declaration_type(values, i):
    if values[i:i+2] == [':', ':']:
        i += 2
    elif values[i:i+1] in (['TYPED'], ['TYPE']):
        i += 1
    value = values[i] if i < len(values) else ''
    return {'INT': 'INT64', 'INTEGER': 'INT64'}.get(value, value), i


def procedure_parameters(ts, values, closing, name_index):
    """Bind typed inputs only inside this named procedure's body."""
    if values[name_index:name_index+3] == ['IF', 'NOT', 'EXISTS']:
        name_index += 3
    opening = name_index + 1
    if values[opening:opening+1] != ['('] or opening not in closing:
        return None, {}
    end = closing[opening]
    params = {}
    i = opening + 1
    while i < end:
        name = symbol_name(ts, i)
        typ, _ = declaration_type(values, i+1)
        if name is not None and ts[i+1][0] == 'word':
            params[name] = Declaration('value', typ, i)
        # Skip a whole parameter, including nested types and default expressions.
        angles = 0
        while i < end and (angles or values[i] != ','):
            if values[i] in {'(', '{', '['} and i in closing:
                i = closing[i]
            elif values[i] == '<' and values[i-1] in {'LIST', 'SET', 'MAP', 'VECTOR'}:
                angles += 1
            elif values[i] == '>' and angles:
                angles -= 1
            i += 1
        i += 1
    i = end + 1
    while i < len(ts) and values[i] not in {';', 'CREATE'}:
        if values[i] == '{' and values[i-1] not in {'RECORD', 'TABLE'}:
            return i, params
        i = closing.get(i, i) + 1
    return None, {}


def global_agg_operand(values, i, functions):
    """Only treat @ as a global reference at an expression operand."""
    prev = values[i-1] if i else ''
    if prev in {'(', '['}:
        # (@Type), [@Edge] and n@Type are pattern/type tests. Parenthesized
        # operands are unambiguous after RETURN/WHERE or a known scalar call.
        j = i-1
        while j > 0 and values[j] in {'(', '['}:
            j -= 1
        head = values[j]
        if head == '=' and values[max(0, j-2):j-1] == ['SET']:
            return True
        return (head in {'CAST', 'RETURN', 'DISTINCT', 'WHERE', 'IF', 'WHEN', 'NOT', 'AND', 'OR', 'LIST'}
                or head.lower() in functions)
    return prev in {'', 'RETURN', 'SET', 'WHERE', 'FILTER', 'DISTINCT', 'EXPORT', 'BY', 'IN',
                    'THEN', 'ELSE', 'WHEN', 'CASE', 'IF', 'WHILE', 'AND', 'OR', 'NOT', '=', '+', '-',
                    '*', '/', '%', ',', ':', '<', '>'}


def single_node_per_path(values, closing, start):
    """Recognize one flat node factor and an optional, balanced graph WHERE."""
    i = start
    if values[i+1:i+2] == ['=']:
        i += 2
    while i < len(values) and values[i] in {'ALL', 'WALK', 'PATH', 'PATHS'}:
        i += 1
    if values[i:i+1] != ['('] or i not in closing or values[i+1:i+2] == ['(']:
        return None
    i = closing[i]+1
    if values[i:i+1] == ['WHERE']:
        i += 1
        boundaries = {'PER', 'MATCH', 'RETURN', 'NEXT', 'FINALLY', 'CALL', 'FINISH', ';', ')', ']', '}'}
        while i < len(values) and values[i] not in boundaries:
            i = closing.get(i, i)+1
    return i if values[i:i+3] == ['PER', 'PATH', '{'] else None


def procedure_diagnostics(code, matches, ts, values, scope, functions):
    """Track explicit lexical declarations, not general query result schemas."""
    closing = delimiter_ends(values)
    symbols = ChainMap({})
    parents = []
    named_bodies = {}
    initializers = {}
    receivers = {}
    diagnostics = []
    starts = [0] + [m.end() for m in re.finditer('\n', code)]

    def location(index):
        offset = matches[index].start()
        line = bisect_right(starts, offset)
        return line, offset - starts[line-1] + 1

    def report(index, rule, error, message):
        line, column = location(index)
        diagnostics.append(dict(rule=rule, code=error, line=line, column=column, message=message))

    def lookup(index):
        return symbols.get(symbol_name(ts, index))

    def rhs_ends(end):
        return end == len(ts) or (end < len(ts) and values[end] in PROCEDURE_STATEMENTS)

    def literal_collection(start):
        if values[start:start+1] == ['['] and start in closing:
            return 'LIST', closing[start]+1
        if values[start:start+2] in (['LIST', '['], ['SET', '{'], ['MAP', '{']) and start+1 in closing:
            return values[start], closing[start+1]+1
        return '', start

    def size_result(start):
        # Consume exactly one call, optionally parenthesized. A larger
        # expression (e.g. size(x) > 0) can have a different result type.
        outer_ends = []
        while values[start:start+1] == ['('] and start in closing:
            outer_ends.append(closing[start])
            start += 1
        source = None
        if values[start:start+2] == ['SIZE', '(']:
            end = closing.get(start+1)
            if end is None:
                return None
            arg = start+2
            if arg+1 == end:
                decl = lookup(arg)
                if decl and decl.kind == 'value':
                    source = SIZE_TYPES.get(decl.type)
            else:
                typ, stop = literal_collection(arg)
                if stop == end:
                    source = SIZE_TYPES.get(typ)
            stop = end+1
        else:
            node_member = symbol_name(ts, start) is not None and values[start+1:start+3] == ['.', '@']
            at = start+2 if node_member else start
            if values[at:at+1] != ['@'] or values[at+2:at+6] != ['.', 'SIZE', '(', ')']:
                return None
            decl = lookup(at+1)
            if decl and decl.kind == ('node' if node_member else 'global') and decl.type in SIZED_AGGS:
                source = 'UINT64'
            stop = at+6
        for end in reversed(outer_ends):
            if stop != end:
                return None
            stop += 1
        if source and rhs_ends(stop):
            return source, stop
        return None

    for i, token in enumerate(values):
        prev = values[i-1] if i else ''
        if token == 'MATCH':
            per = single_node_per_path(values, closing, i+1)
            if per is not None:
                report(per, 'single-node-per-path', 'NS238',
                       'PER PATH cannot consume a single-node MATCH. Keep the WHERE filters; '
                       'use PER NODE on the matched binding for per-node work, or match the actual '
                       'relationship for per-edge work.')
        if token == 'PROCEDURE' and prev in {'CREATE', 'REPLACE'}:
            body, params = procedure_parameters(ts, values, closing, i+1)
            if body is not None:
                named_bodies[body] = params
        if token == '{':
            parents.append(symbols)
            symbols = ChainMap(named_bodies[i]) if i in named_bodies else symbols.new_child()
        elif token == '}' and parents:
            symbols = parents.pop()
        elif token == ';' and not parents:
            symbols = ChainMap({})

        if token in {'VALUE', 'TABLE'} and prev not in {'.', '@', 'AS'}:
            name = symbol_name(ts, i+1)
            if name is None:
                continue
            typ, t = declaration_type(values, i+2)
            if token == 'TABLE':
                typ = 'TABLE'
            elif typ == '=':
                # Untyped declarations still take part in duplicate-name checks.
                typ, stop = literal_collection(t+1)
                if not rhs_ends(stop):
                    typ = ''
                if values[t+1:t+3] == ['CAST', '('] and t+2 in closing:
                    end = closing[t+2]
                    if values[end-2:end-1] == ['AS'] and rhs_ends(end+1):
                        typ, _ = declaration_type(values, end-1)
            elif t >= len(ts) or ts[t][0] != 'word':
                continue
            kind = 'value'
            if typ in AGG_TYPES:
                kind = 'node' if prev == 'NODE' else 'global'
            decl = Declaration(kind, typ, i+1)
            original = symbols.get(name)
            if original:
                line, col = location(original.index)
                report(i+1, 'duplicate-declaration', 'NS002',
                       f'{name} was already declared at {line}:{col} in a visible scope. Reuse or rename the declaration.')
            else:
                symbols[name] = decl
            if values[t+1:t+2] == ['=']:
                initializers[t+1] = decl

        if token == '@':
            name = symbol_name(ts, i+1)
            decl = lookup(i+1)
            if name is not None and prev == '.' and (not decl or decl.kind != 'node'):
                report(i+1, 'undeclared-node-aggregator', '42N56',
                       f'No visible NODE VALUE declaration for {name}. Use the exact declared name or '
                       'declare a distinct node aggregator before use.')
            elif name is not None and global_agg_operand(values, i, functions) and (not decl or decl.kind != 'global'):
                report(i+1, 'undeclared-global-aggregator', '42N56',
                       f'No visible global aggregator named {name}. Reference a scalar VALUE or procedure '
                       f'parameter directly as `{name}`; use @ only for a VALUE declared with an aggregator type.')

        if token == '(' and i >= 3 and values[i-2] == '.':
            decl = lookup(i-3)
            node = i >= 5 and values[i-5] == '.'
            explicit_agg = i >= 4 and values[i-4] == '@'
            if decl and decl.kind in {'node', 'global'} and (
                    not explicit_agg or decl.kind == ('node' if node else 'global')):
                receivers[i-1] = decl.type.lower()

        if token == 'NODE' and values[i+1:i+2] == ['('] and prev in {
                'RETURN', 'DISTINCT', 'WHERE', 'WHEN', 'THEN', 'ELSE', '=', '(', '[', ',',
                '+', '-', '*', '/', '%', '<', '>', 'AND', 'OR', 'NOT', 'IN', 'FILTER', 'BY', 'YIELD', 'EXPORT'}:
            end = closing.get(i+1)
            if end is not None and values[end+1:end+2] != ['FROM']:  # NODE(...) FROM is an import specification
                report(i, 'scalar-node-lookup', 'NR002',
                       f'{scope.title()} has no documented node(id) scalar lookup. Bind the node with MATCH on its business primary key.')

        if token == '=':
            target = initializers.get(i)
            if i >= 2 and values[i-2] == 'SET':
                target = lookup(i-1)
            if not target or target.kind != 'value' or target.type not in INTEGER_TYPES | {'BOOL', 'BOOLEAN', 'STRING', 'DATE'}:
                continue
            result = size_result(i+1)
            if result:
                source, stop = result
                if target.type == source or (source, target.type) == ('INT32', 'INT64'):
                    continue
                name = symbol_name(ts, target.index)
                fix = f'Use {source} for the count.'
                if target.type in INTEGER_TYPES:
                    expr = code[matches[i+1].start():matches[stop-1].end()]
                    fix += f' For an intentional conversion, range-check and use CAST({expr} AS {target.type}).'
                report(i+1, 'size-assignment-type', 'NS208',
                       f'This size result is {source} and cannot be implicitly assigned to {name} ({target.type}). {fix}')
    return diagnostics, receivers


def lint(code, root, scope='database'):
    issues, unknown = [], []
    matches = list(token_matches(code))
    ts = [(m.lastgroup, m.group()) for m in matches]
    values = [v.upper() if k == 'word' else v for k, v in ts]
    clean = ' '.join(v if k not in {'string', 'quoted', 'param', 'temp'} else '?' for k, v in ts)
    def add(rule, message):
        item = {'rule': rule, 'message': message}
        if item not in issues: issues.append(item)
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for kind, value in ts:
        if kind != 'symbol': continue
        if value in '([{': stack.append(value)
        elif value in ')]}':
            if not stack or stack.pop() != pairs[value]: add('delimiters', 'Unbalanced delimiters')
    if stack: add('delimiters', 'Unbalanced delimiters')
    if re.search(r"['\"`]", ''.join(v for k,v in ts if k == 'symbol')):
        add('literal', 'Unterminated string or identifier')
    if re.search(r'\b(?:UNWIND|MERGE|GO)\b|==|\[\s*[^\]]*\*\s*\d', clean, re.I):
        add('dialect', 'Source dialect syntax requires a documented GQL mapping')
    if re.search(r'=\s*~', clean):
        add('regex-operator', 'GQL 5.3 uses regexp_like(value, pattern[, options]), not =~; preserve full-string matching and pattern escaping')
    if re.search(r'\bWITH\b', clean, re.I):
        add('dialect', 'Check WITH against GQL statement context; Cypher WITH requires NEXT')
    if re.search(r'\bLIMIT\s+[^;{}]+\bORDER\s+BY\b', clean, re.I):
        add('pagination-order', 'ORDER BY precedes OFFSET and LIMIT within a paging fragment')
    if re.search(r'\b(?:LIMIT|OFFSET|SKIP)\s*-', clean, re.I):
        add('pagination-value', 'Negative pagination is invalid')
    if re.search(r'\bCREATE\s+(?:OR\s+REPLACE\s+)?PROCEDURE\b', clean, re.I):
        if re.search(r'\bRETURNS\b[^{}]*\bLIST\s*<\s*RECORD', clean, re.I):
            add('procedure-return', 'LIST<RECORD> is not a documented procedure return type')
    for m in re.finditer(r'\bMATCH\b(.*?)(?=\bPER\s+(?:NODE|PATH)\b|\bFINALLY\b)', clean, re.I|re.S):
        if re.search(r'\b(?:RETURN|NEXT|MATCH)\b', m.group(1), re.I): continue
        if len(re.findall(r'\]\s*(?:-\s*>|-)', m.group(1))) > 1 or re.search(r'\}\s*\(', m.group(1)):
            add('compute-hop', 'Match-compute accepts only zero or one hop')
    if re.search(r'\bNODE\s+VALUE\s+@?\s*(?:\w+|\?)\s+(?:INT\d*|STRING|DOUBLE|BOOLEAN)\b', clean, re.I):
        add('node-value-type', 'NODE VALUE requires a documented aggregator type')
    keyword_data = json.loads((root / 'references/documented-keywords.json').read_text())
    reserved = set(keyword_data['reserved'])
    non_reserved = set(keyword_data['non_reserved'])
    positions = token_roles(ts, reserved | non_reserved, non_reserved)
    # Apply edits to the original spans so comments, literals, line endings and
    # the case of DATE survive. A field named `LOCAL` has an identifier role.
    parts = []
    cursor = 0
    line = 1
    for i, match in enumerate(matches):
        if positions.get(i) != 'calendar date qualifier':
            continue
        start = match.start()
        line += code.count('\n', cursor, start)
        column = start - code.rfind('\n', 0, start)
        add('local-date-type', f'Use DATE for a calendar date at line {line}, column {column}')
        parts.append(code[cursor:start])
        cursor = match.end()
        while cursor < len(code) and code[cursor] in ' \t':
            cursor += 1
    for i in range(1, len(ts) - 1):
        if values[i].upper() not in {'IS', '`IS`'}:
            continue
        has_not = values[i+1].upper() in {'NOT', '`NOT`'}
        end = i + 2 if has_not else i + 1
        if end >= len(ts) or values[end].upper() not in {'NULL', '`NULL`'}:
            continue
        # In a pattern filler, IS can introduce a label named `NULL`.
        if not has_not and values[i] == 'IS' and positions.get(end) == 'label':
            opening = i - 2 if positions.get(i-1) == 'pattern binding' else i - 1
            if values[opening] in {'(', '['}:
                while opening > 0 and values[opening-1] == '(':
                    opening -= 1
                # The identifier heuristic can also see a label in a grouped expression.
                if opening == 0 or values[opening-1] not in {
                    'WHERE', 'FILTER', 'RETURN', 'AND', 'OR', 'XOR', 'NOT',
                    'WHEN', 'THEN', 'ELSE', 'IF', 'WHILE',
                }:
                    continue
        if any(kind == 'quoted' for kind, _ in ts[i:end+1]):
            add('null-predicate-quoting', 'Write IS NULL or IS NOT NULL with no backticks on predicate keywords')
    for i, role in positions.items():
        kind, value = ts[i]
        if role == 'calendar date qualifier':
            continue
        if role in DDL_KEYS:
            if kind == 'quoted':
                add('ddl-key-quoting', f'Write {role} without backticks and quote each key property name')
            continue
        if kind == 'quoted' or (kind == 'string' and not value.startswith('"')):
            continue
        name = value.strip('"') if kind == 'string' else value
        if name.upper() in reserved or name.upper() in non_reserved:
            category = 'reserved' if name.upper() in reserved else 'non-reserved'
            rule = 'reserved-alias' if role == 'alias' and category == 'reserved' else 'keyword-identifier'
            add(rule, f'Quote {category} identifier {name} as `{name}` ({role})')
        else:
            add('unquoted-identifier', f'Use backticks for {name} ({role})')
    for kind, value in ts:
        if kind == 'symbol' and value == '#':
            add('temporary-graph-token', 'Use #name for a temporary graph; the scanner requires one token')
        if kind == 'param' and value.startswith('$`'):
            add('parameter-quoting', 'External $name parameters are lexical tokens; backticks after $ are unsupported')
    for i in range(len(values)-1):
        if values[i:i+2] not in (['PER','NODE'], ['PER','PATH']): continue
        start = next((j for j in range(i+2,len(values)) if values[j]=='{'),None)
        if start is None: continue
        depth = 1
        for j in range(start+1,len(values)):
            depth += (values[j]=='{') - (values[j]=='}')
            if not depth: break
            if values[j]=='RETURN': add('compute-return', 'RETURN is forbidden inside PER NODE/PER PATH')
    for segment in re.split(r'\bNEXT\b', clean, flags=re.I)[:-1]:
        last_compute = re.search(r'\b(?:PER\s+(?:NODE|PATH)|FINALLY)\b(.*)$', segment, re.I | re.S)
        if last_compute and not re.search(r'\bRETURN\b', last_compute.group(1), re.I):
            add('compute-next', 'NEXT cannot separate match-compute procedure stages')
    if scope == 'analytics':
        for segment in re.split(r'\bMATCH\b',clean,flags=re.I)[1:]:
            before_return = re.split(r'\bRETURN\b',segment,maxsplit=1,flags=re.I)
            if len(before_return)>1 and not re.search(r'\bPER\s+(?:NODE|PATH)\b|\bFINALLY\b',before_return[0],re.I):
                add('analytics-match', 'Analytics uses match-compute, not ordinary MATCH RETURN')
    records = catalog(root)
    semantic_issues, receivers = procedure_diagnostics(code, matches, ts, values, scope, records)
    issues.extend(semantic_issues)
    for i, (kind, name) in enumerate(ts[:-1]):
        if kind not in {'word', 'quoted'} or ts[i+1][1] != '(': continue
        prev = values[i-1] if i else ''
        if name.upper() in STRUCTURAL or prev in {'CALL', 'PROCEDURE'}: continue
        if values[i] in {'DEC', 'DECIMAL'}:
            # property_name [TYPED | ::] DECIMAL(precision[, scale])
            prop = i-1
            if prev == 'TYPED':
                prop -= 1
            elif values[max(0, i-2):i] == [':', ':']:
                prop -= 2
            if positions.get(prop) == 'DDL property':
                continue
        if (values[i] == 'LABELED' and prev in {'IS', 'NOT'}
                or values[i] == 'IS' and prev != 'RETURN'
                or values[i] == 'KEY' and prev in {'PRIMARY', 'MULTIEDGE'}):
            continue
        if positions.get(i) in DDL_KEYS:
            continue
        if prev in {':', '@'} or positions.get(i) in {'catalog path', 'element type', 'element or graph type'}:
            continue
        # Find balanced call body.
        depth, end = 1, i + 2
        while end < len(ts) and depth:
            depth += (ts[end][1] == '(') - (ts[end][1] == ')'); end += 1
        if depth: continue
        key = name.strip('`').lower()
        if prev == '.':
            receiver = ts[i-2][1] if i >= 2 else ''
            declared = receivers.get(i)
            if declared: key = declared + '.' + key
            else:
                unknown.append(f'Receiver type needed for {receiver}.{name}'); continue
        entry = records.get(key)
        if entry is None:
            add('undocumented-function', f'No documented function or receiver signature: {key}')
            continue
        if scope not in entry['scope']: add('function-scope', f'{key} is unavailable in {scope}')
        ranges = arities(entry['signatures'], key)
        args = split_args(ts[i+2:end-1]); count = len(args)
        if ranges and not any(lo <= count <= hi for lo,hi in ranges):
            add('function-arity', f'{key}: {count} arguments do not match documented arity')
        if not ranges: unknown.append(f'Special signature requires checking: {key}')
        if key == 'list_distinct' and args and args[0][0][0] in {'string','number'}:
            add('function-type', 'list_distinct requires a LIST argument')
        if key == 'element_id' and args:
            variable = ''.join(v for _,v in args[0])
            if any(values[j] == '[' and ts[j+1][1] == variable and values[j+2] in {':', '@', ']'}
                   for j in range(len(ts)-2)):
                add('function-type', 'element_id accepts NODE, not EDGE')
        if key == 'all_different' and count == 1 and args[0] and args[0][0][1].upper() == 'LIST':
            add('function-type', 'all_different is not a list-deduplication function')
    report = {'issues': issues, 'needs_review': sorted(set(unknown)),
              'syntax': 'unverified: lint is not a server parser',
              'semantics': 'unverified: requires case contracts and result comparison'}
    if parts:
        report['corrected_gql'] = ''.join(parts) + code[cursor:]
    return report


def read_only(code, root):
    """Fail closed execution subset. No named/inline procedures, hints, DDL or DML.

    Conservatively blocks ambiguous identifiers too. This runner is intentionally
    narrower than generation capabilities; rejection never means GQL unsupported.
    """
    ts = tokens(code)
    words = {v.upper() for k,v in ts if k in {'word','quoted'}}
    banned = {'CREATE','ALTER','DROP','INSERT','DELETE','DETACH','SET','UPDATE','REMOVE',
              'CALL','IMPORT','EXPORT','LOAD','COPY','SUBMIT','KILL','CANCEL','GRANT',
              'REVOKE','USE','SESSION','CLEAR','REPLACE','PROCEDURE','LOG','FINISH'}
    if not ts or ts[0][1].upper() not in {'RETURN','FOR','LET','MATCH','OPTIONAL','FILTER'}:
        raise ValueError('Outside read-only execution subset')
    if banned & words or any(v == ';' for k,v in ts) or '/*+' in code:
        raise ValueError('Potential side effect or multiple statements blocked')
    report = lint(code, root)
    if report['issues'] or report['needs_review']:
        raise ValueError('Execution requires resolved lint and signature checks')
    return code


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    sub = p.add_subparsers(dest='command', required=True)
    q = sub.add_parser('lookup'); q.add_argument('term')
    q.add_argument('--kind', choices=['function','topic'], default='function')
    q.add_argument('--all-matches', action='store_true')
    q.add_argument('--offset', type=int, default=0); q.add_argument('--limit', type=int, default=6000)
    l = sub.add_parser('lint'); l.add_argument('file', type=Path)
    l.add_argument('--scope', choices=['database','analytics'], default='database')
    qn = sub.add_parser('quote-identifiers', help='Format raw schema/binding names, not whole GQL')
    qn.add_argument('names', nargs='+')
    a = p.parse_args()
    if a.command == 'lookup':
        if a.offset < 0 or not 200 <= a.limit <= 12000: p.error('offset >= 0; limit 200..12000')
        result = lookup(a.root, a.term, a.kind, a.offset, a.limit, a.all_matches)
    elif a.command == 'quote-identifiers':
        try:
            result = {name: quote_identifier(name, a.root) for name in a.names}
        except ValueError as exc:
            p.error(str(exc))
    else:
        with a.file.open(encoding='utf-8', newline='') as candidate:
            result = lint(candidate.read(), a.root, a.scope)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if a.command == 'lint' and result['issues']: raise SystemExit(1)


if __name__ == '__main__': main()
