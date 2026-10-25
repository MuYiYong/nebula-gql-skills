#!/usr/bin/env python3
"""Standalone bounded reference lookup and conservative GQL lint (stdlib only).

Lint is not a GQL parser/type checker. Findings are violations of documented
contracts; an empty finding list means only that these checks found no issue.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


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


TOKEN = re.compile(r'''(?P<space>\s+)|(?P<comment>--[^\n]*|//[^\n]*|/\*[\s\S]*?\*/)|(?P<string>'(?:''|\\.|[^'\\])*'|"(?:""|\\.|[^"\\])*")|(?P<quoted>`(?:``|[^`])*`)|(?P<param>\$(?:`(?:``|[^`])*`|[\w]+))|(?P<word>[^\W\d]\w*)|(?P<number>\d+(?:\.\d+)?)|(?P<symbol>.)''', re.UNICODE)


def tokens(code):
    return [(m.lastgroup, m.group()) for m in TOKEN.finditer(code)
            if m.lastgroup not in {'space', 'comment'}]


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


def quote_identifier(name, root):
    """Format one raw identifier, not an expression or an already quoted name."""
    if not name or len(name) > 127 or '`' in name or any(ord(c) < 32 for c in name):
        raise ValueError('Expected one raw identifier of 1..127 characters without backticks/control characters')
    data = json.loads((root / 'references/documented-keywords.json').read_text())
    keywords = set(data['reserved']) | set(data['non_reserved'])
    if name.upper() in keywords or not re.fullmatch(r'[^\W\d]\w*', name, re.UNICODE):
        return '`' + name + '`'
    return name


def identifier_positions(ts):
    """Recognize clear identifier positions; this is not a complete GQL parser."""
    values = [v.upper() if k == 'word' else v for k, v in ts]
    found, stack = {}, []
    pattern = False
    expression_forms = {'ALL', 'DISTINCT', 'CASE', 'NOT', 'EXISTS', 'TRUE', 'FALSE', 'NULL',
                        'UNKNOWN', 'CURRENT_DATE', 'CURRENT_TIME', 'CURRENT_TIMESTAMP',
                        'CURRENT_GRAPH', 'CURRENT_PROPERTY_GRAPH', 'CURRENT_SCHEMA',
                        'CURRENT_USER', 'CURRENT_ROLE', 'CURRENT_SESSION', 'SESSION_USER',
                        'SYSTEM_USER', 'LOCAL_TIME', 'LOCAL_TIMESTAMP', 'LOCAL_DATETIME'}
    constructors = {'LIST': '[', 'RECORD': '{', 'TABLE': '{', 'MAP': '{', 'VECTOR': '<',
                    'VALUE': '{', 'GRAPH': '{'}
    def mark(index, role):
        if 0 <= index < len(ts) and ts[index][0] in {'word', 'quoted', 'string'}:
            found[index] = role
    for i, (kind, value) in enumerate(ts):
        word = values[i]
        prev = values[i-1] if i else ''
        after = values[i+1] if i+1 < len(ts) else ''
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
            if value == '{' and prev in {'OPTIONS', 'DATAFILE'}:
                context = 'options'
            if value == '(':
                if i >= 2 and values[i-2] == 'PROCEDURE':
                    context = 'parameters'
                elif pattern and (prev in {'MATCH', '=', ',', '>', '-', '~', 'OPTIONAL'}
                                  or (stack and stack[-1][1] == 'pattern' and prev == '(')):
                    context = 'pattern'
                elif (i+2 < len(ts) and values[i+2] in {':', '@', 'IS', '{', 'WHERE'}
                      and (i == 0 or ts[i-1][0] != 'word' or prev in STRUCTURAL)):
                    context = 'pattern'
            elif value == '[' and prev in {'-', '~', '<'}:
                context = 'pattern'
            elif value == '[' and prev == '@':
                context = 'types'
            stack.append((value, context, prev))
            if context == 'pattern' and after not in {'WHERE', 'IS'}:
                mark(i+1, 'pattern binding')
        elif kind == 'symbol' and value in {')', ']', '}'}:
            if stack:
                stack.pop()
        if kind not in {'word', 'quoted', 'string'}:
            continue
        if prev == 'AS' and not any(s[2] == 'CAST' for s in stack):
            mark(i, 'alias')
        if prev == '.' and (i < 2 or values[i-2] != '.') and after != '(':
            mark(i, 'qualified name or property')
        if after == ':' and not any(s[1] == 'options' for s in stack):
            mark(i, 'field or pattern binding')
        if prev in {':', '|', '&'} and stack and stack[-1][1] == 'pattern':
            mark(i, 'label or type')
        if (prev == 'IS' and stack and stack[-1][1] == 'pattern'
                and word not in {'NOT', 'TYPED', 'DIRECTED', 'SOURCE', 'DESTINATION', 'NULL'}):
            mark(i, 'label')
        if stack and stack[-1][1] == 'types' and prev in {'[', ','}:
            mark(i, 'type')
        if prev == '@':
            mark(i, 'type or aggregator name')
        if values[i+1:i+3] == ['-', '>']:
            mark(i, 'lambda binding')
        if (prev in {'LET', 'VALUE', 'FOR', 'YIELD', 'PROCEDURE', 'CALL', 'USE'} and i-1 not in found
                and not (prev == 'PROCEDURE' and word == 'IF')):
            mark(i, 'name or binding')
        if (prev in {'GRAPH', 'SCHEMA', 'INDEX'} and i-1 not in found
                and word not in {'TYPE', 'IF', 'ON'}):
            mark(i, 'catalog object')
        if prev == 'TYPE' and i >= 2 and values[i-2] == 'GRAPH':
            mark(i, 'graph type')
        # Parameter/column declarations and multi-variable LET declarations.
        scalar = r'(?:U?INT\d*|INTEGER\d*|STRING|BOOLEAN|DOUBLE|FLOAT\d*|DECIMAL|NODE|EDGE|PATH|TABLE)'
        if re.fullmatch(scalar, after) or (after.endswith('AGG') and i+2 < len(ts) and values[i+2] == '<'):
            if prev in {'(', ',', 'VALUE', 'PARAMETER'}:
                mark(i, 'declaration')
        if prev == ',' and after == '=':
            mark(i, 'binding')
        # A bare projection/predicate name need not have a declaration in this snippet.
        if (kind in {'word', 'quoted'} and prev in {'RETURN', 'DISTINCT', 'BY', 'WHERE', 'FILTER'} and after != '('
                and word not in expression_forms and constructors.get(word) != after
                and not (prev == 'FILTER' and word == 'WHERE')
                and not (prev == 'BY' and i >= 2 and values[i-2] == 'PARTITION' and word == 'DEFAULT')
                and not (i+1 < len(ts) and ts[i+1][0] == 'string')):
            mark(i, 'expression name')
    # Follow bound names in expression positions, retaining keyword clauses.
    names = {ts[i][1].strip('`"').upper() for i in found}
    expression_prefixes = {'RETURN', 'BY', 'WHERE', 'FILTER', 'WHEN', 'IN', 'AND', 'OR',
                           '(', ',', '=', '+', '-', '*', '/', '%', '<', '>'}
    for i, (kind, value) in enumerate(ts):
        if (kind == 'word' and value.upper() in names and i and values[i-1] in expression_prefixes
                and value.upper() not in expression_forms
                and not (values[i-1] == 'FILTER' and value.upper() == 'WHERE')
                and not (values[i-1] == 'BY' and i >= 2 and values[i-2] == 'PARTITION' and value.upper() == 'DEFAULT')
                and not (i+1 < len(ts) and (values[i+1] == '(' or constructors.get(value.upper()) == values[i+1]))):
            mark(i, 'bound reference')
    return found


def lint(code, root, scope='database'):
    issues, unknown = [], []
    ts = tokens(code)
    values = [v.upper() if k == 'word' else v for k, v in ts]
    clean = ' '.join(v if k not in {'string', 'quoted', 'param'} else '?' for k, v in ts)
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
    if re.search(r"['\"]", ''.join(v for k,v in ts if k == 'symbol')):
        add('literal', 'Unterminated string literal')
    if re.search(r'\b(?:UNWIND|MERGE|GO)\b|==|\[\s*[^\]]*\*\s*\d', clean, re.I):
        add('dialect', 'Source dialect syntax requires a documented GQL mapping')
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
    if re.search(r'\bNODE\s+VALUE\s+@?\w+\s+(?:INT\d*|STRING|DOUBLE|BOOLEAN)\b', clean, re.I):
        add('node-value-type', 'NODE VALUE requires a documented aggregator type')
    keyword_data = json.loads((root / 'references/documented-keywords.json').read_text())
    reserved = set(keyword_data['reserved'])
    keywords = reserved | set(keyword_data['non_reserved'])
    for i, role in identifier_positions(ts).items():
        kind, value = ts[i]
        if kind == 'quoted' or (kind == 'string' and not value.startswith('"')):
            continue
        name = value.strip('"') if kind == 'string' else value
        if name.upper() in keywords:
            category = 'reserved' if name.upper() in reserved else 'non-reserved'
            rule = 'reserved-alias' if role == 'alias' and category == 'reserved' else 'keyword-identifier'
            add(rule, f'Quote {category} identifier {name} as `{name}` ({role})')
    for kind, value in ts:
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
    for i, (kind, name) in enumerate(ts[:-1]):
        if kind not in {'word', 'quoted'} or ts[i+1][1] != '(': continue
        prev = values[i-1] if i else ''
        if name.upper() in STRUCTURAL or prev in {'CALL', 'PROCEDURE'}: continue
        if prev in {':', '@'}: continue  # a label/type before a node's parentheses
        # Find balanced call body.
        depth, end = 1, i + 2
        while end < len(ts) and depth:
            depth += (ts[end][1] == '(') - (ts[end][1] == ')'); end += 1
        if depth: continue
        key = name.strip('`').lower()
        if prev == '.':
            receiver = ts[i-2][1] if i >= 2 else ''
            declared = re.search(r'\b' + re.escape(receiver) + r'\s+([A-Za-z]+Agg)\b', clean, re.I)
            if declared: key = declared.group(1).lower() + '.' + key
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
            if re.search(r'\[\s*' + re.escape(variable) + r'\s*[:@\]]', clean):
                add('function-type', 'element_id accepts NODE, not EDGE')
        if key == 'all_different' and count == 1 and args[0] and args[0][0][1].upper() == 'LIST':
            add('function-type', 'all_different is not a list-deduplication function')
    return {'issues': issues, 'needs_review': sorted(set(unknown)),
            'syntax': 'unverified: lint is not a server parser',
            'semantics': 'unverified: requires case contracts and result comparison'}


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
    else: result = lint(a.file.read_text(encoding='utf-8'), a.root, a.scope)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if a.command == 'lint' and result['issues']: raise SystemExit(1)


if __name__ == '__main__': main()
