"""Hand-authored calibration queries and known-wrong semantic mutants.

Generators must never read this module. These outputs test the judge, not skills.
"""
CASES = {
    'q_optional': (
        'MATCH (p:player) OPTIONAL MATCH (p)-[:follow]->(f:player WHERE f.age > $min_age) RETURN p.id AS src, f.id AS dst',
        'MATCH (p:player) OPTIONAL MATCH (p)-[:follow]->(f:player WHERE f.age > $min_age) RETURN DISTINCT p.id AS src, f.id AS dst'),
    'q_group': (
        'MATCH (p:player) RETURN p.age AS age, count(*) AS total GROUP BY age',
        'MATCH (p:player) RETURN p.age AS age, count(DISTINCT p.name) AS total GROUP BY age'),
    'q_trail': (
        'MATCH p = TRAIL (s:player {id:$seed})-[:follow]->{1,3}(t:player) RETURN transform(nodes(p), n -> n.id) AS node_ids',
        'MATCH p = ACYCLIC (s:player {id:$seed})-[:follow]->{1,3}(t:player) RETURN transform(nodes(p), n -> n.id) AS node_ids'),
    'q_anti': (
        'MATCH (p:player) WHERE NOT EXISTS { MATCH (p)-[:follow]->(f) } RETURN p.id AS id',
        'MATCH (p:player) WHERE EXISTS { MATCH (p)-[:follow]->(f) } RETURN p.id AS id'),
    'q_page': (
        'MATCH (p:player) RETURN p.id AS id, p.age AS age ORDER BY age DESC NULLS LAST, id ASC OFFSET 1 LIMIT 2',
        'MATCH (p:player) RETURN p.id AS id, p.age AS age ORDER BY age ASC NULLS LAST, id ASC OFFSET 1 LIMIT 2'),
    'q_acyclic': (
        'MATCH p = ACYCLIC (s:player {id:$seed})-[:follow]->{1,3}(t:player) RETURN transform(nodes(p), n -> n.id) AS node_ids',
        'MATCH p = TRAIL (s:player {id:$seed})-[:follow]->{1,3}(t:player) RETURN transform(nodes(p), n -> n.id) AS node_ids'),
    'p_sum': (
        'VALUE i INT64 = 1 VALUE total INT64 = 0 WHILE i <= $n THEN { SET total = total + i SET i = i + 1 } RETURN total',
        'VALUE i INT64 = 1 VALUE total INT64 = 0 WHILE i <= $n THEN { SET total = total + i + 1 SET i = i + 1 } RETURN total'),
    'p_contributions': (
        'CALL { RETURN $left AS score UNION ALL RETURN $right AS score } RETURN sum(score) AS total',
        'CALL { RETURN $left AS score UNION RETURN $right AS score } RETURN sum(score) AS total'),
    'p_branch': (
        'IF $x IS NULL THEN { RETURN "missing" AS `label` } ELSEIF $x < 0 THEN { RETURN "negative" AS `label` } ELSEIF $x = 0 THEN { RETURN "zero" AS `label` } ELSE { RETURN "positive" AS `label` }',
        'IF $x IS NULL THEN { RETURN "missing" AS `label` } ELSEIF $x <= 0 THEN { RETURN "negative" AS `label` } ELSE { RETURN "positive" AS `label` }'),
    'c_degrees': (
        'NODE VALUE degree SumAgg<INT64> = 0 TABLE results TYPED TABLE {id STRING, degree INT64} MATCH (s:player)-[:follow]->(t:player) PER PATH { SET s.@degree += 1 } MATCH (n:player) PER NODE (n) { EXPORT n.id, n.@degree INTO results } FOR row IN results RETURN row.id AS id, row.degree AS degree',
        'NODE VALUE degree SumAgg<INT64> = 0 TABLE results TYPED TABLE {id STRING, degree INT64} MATCH (s:player)-[:follow]->(t:player) PER PATH { SET t.@degree += 1 } MATCH (n:player) PER NODE (n) { EXPORT n.id, n.@degree INTO results } FOR row IN results RETURN row.id AS id, row.degree AS degree'),
    'c_long_set': (
        'VALUE collected_destination_ids SetAgg<STRING> MATCH (s:player)-[:follow]->(t:player) PER PATH { SET @collected_destination_ids += t.id } RETURN size(@collected_destination_ids) AS distinct_targets',
        'VALUE collected_destination_ids SetAgg<STRING> MATCH (s:player)-[:follow]->(t:player) PER PATH { SET @collected_destination_ids += s.id } RETURN size(@collected_destination_ids) AS distinct_targets'),
    'c_incoming': (
        'NODE VALUE total SumAgg<INT64> = 0 TABLE results TYPED TABLE {id STRING, total INT64} MATCH (s:player)-[e:follow]->(t:player) PER PATH { SET t.@total += coalesce(e.degree, 0) } MATCH (n:player) PER NODE (n) { EXPORT n.id, n.@total INTO results } FOR row IN results RETURN row.id AS id, row.total AS total',
        'NODE VALUE total SumAgg<INT64> = 0 TABLE results TYPED TABLE {id STRING, total INT64} MATCH (s:player)-[e:follow]->(t:player) PER PATH { SET s.@total += coalesce(e.degree, 0) } MATCH (n:player) PER NODE (n) { EXPORT n.id, n.@total INTO results } FOR row IN results RETURN row.id AS id, row.total AS total'),
    'c_string_concat': (
        'VALUE joined_ids SumAgg<STRING> = "" MATCH (s:player)-[:follow]->(t:player) PER PATH { SET @joined_ids += t.id } RETURN length(CAST(@joined_ids AS STRING)) AS total_chars',
        'VALUE joined_ids SumAgg<STRING> = "" MATCH (s:player)-[:follow]->(t:player) PER PATH { SET @joined_ids += "x" } RETURN length(CAST(@joined_ids AS STRING)) AS total_chars'),
}
