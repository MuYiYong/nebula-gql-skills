"""Independent finite-data oracles; no SQL/GQL string matching or reference queries."""
from collections import Counter


def expected(case, fixture, params):
    nodes = {node['id']: node for node in fixture['nodes']}
    edges = fixture['edges']
    name = case['oracle']
    if name == 'optional':
        rows = []
        for key in nodes:
            matches = [e['dst'] for e in edges if e['src'] == key
                       and nodes[e['dst']]['age'] is not None
                       and nodes[e['dst']]['age'] > params['min_age']]
            rows.extend([[key, target] for target in matches] or [[key, None]])
    elif name == 'group':
        rows = [[age, count] for age, count in Counter(n['age'] for n in nodes.values()).items()]
    elif name in ('paths_trail', 'paths_acyclic'):
        rows = []
        def visit(path, used):
            if len(path) > 1:
                rows.append([path.copy()])
            if len(used) == 3:
                return
            for index, edge in enumerate(edges):
                if edge['src'] != path[-1] or index in used:
                    continue
                if name == 'paths_acyclic' and edge['dst'] in path:
                    continue
                visit(path + [edge['dst']], used | {index})
        if params['seed'] in nodes:
            visit([params['seed']], set())
    elif name == 'anti':
        rows = [[key] for key in nodes if not any(e['src'] == key for e in edges)]
    elif name == 'page':
        ordered = sorted(nodes.values(), key=lambda n: (n['age'] is None, -(n['age'] or 0), n['id']))
        rows = [[n['id'], n['age']] for n in ordered[1:3]]
    elif name == 'sum':
        rows = [[sum(range(1, params['n'] + 1))]]
    elif name == 'contributions':
        rows = [[params['left'] + params['right']]]
    elif name == 'branch':
        x = params['x']
        rows = [['missing' if x is None else 'negative' if x < 0 else 'zero' if x == 0 else 'positive']]
    elif name == 'degrees':
        counts = Counter(e['src'] for e in edges)
        rows = [[key, counts[key]] for key in nodes]
    elif name == 'targets':
        rows = [[len({e['dst'] for e in edges})]]
    elif name == 'destination_chars':
        rows = [[sum(len(e['dst']) for e in edges)]]
    elif name == 'incoming':
        rows = [[key, sum(e['degree'] or 0 for e in edges if e['dst'] == key)] for key in nodes]
    else:
        raise ValueError(f'Unknown oracle: {name}')
    return {'columns': case['columns'], 'rows': rows}
