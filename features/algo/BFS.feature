# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: BFS

  Scenario: BFS basic
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.bfs(g, element_id(src)) YIELD node_id AS _dst, distance
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst, distance
      ORDER BY distance DESC, dst DESC
      LIMIT 10
      """
    Then the result should be, in order:
      | dst | distance |
      | 6   | 4        |
      | 3   | 4        |
      | 5   | 3        |
      | 3   | 3        |
      | 3   | 3        |
      | 3   | 3        |
      | 3   | 3        |
      | 3   | 3        |
      | 2   | 3        |
      | 4   | 2        |
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.bfs(g, element_id(src), 'incoming', 2)
      RETURN node_id AS _dst, distance
      ORDER BY distance DESC, _dst
      """
    Then the result should be, in order:
      | _dst               | distance |
      | 288603351111696386 | 2        |
      | 288884826088407043 | 2        |
      | 289293960378056708 | 2        |
      | 289729251018539014 | 2        |
      | 288544845067190274 | 1        |
      | 288826320043900931 | 1        |
      | 289166301065117700 | 1        |
      | 289670744974032902 | 1        |
      | 289107795020611588 | 0        |
      | 288232351836667905 | -1       |
      | 288263370090479617 | -1       |
      | 288321876134985729 | -1       |
      | 288415253018968065 | -1       |
      | 288449535447924737 | -1       |
      | 288472492048121857 | -1       |
      | 288731010424635394 | -1       |
      | 289012485401346051 | -1       |
      | 289316916978253828 | -1       |
      | 289389269997322245 | -1       |
      | 289447776041828357 | -1       |
      | 289575435354767365 | -1       |
      | 289856910331478022 | -1       |
      | 289952219950743559 | -1       |
      | 290010725995249671 | -1       |
      | 290138385308188679 | -1       |
      | 290233694927454216 | -1       |
      | 290292200971960328 | -1       |
      | 290419860284899336 | -1       |
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.bfs(g, element_id(src), 'bidirect', 2)
      RETURN node_id AS _dst, distance
      ORDER BY distance DESC, _dst
      """
    Then the result should be, in order:
      | _dst               | distance |
      | 288321876134985729 | 2        |
      | 288449535447924737 | 2        |
      | 288472492048121857 | 2        |
      | 288603351111696386 | 2        |
      | 288731010424635394 | 2        |
      | 288884826088407043 | 2        |
      | 289012485401346051 | 2        |
      | 289316916978253828 | 2        |
      | 289447776041828357 | 2        |
      | 289575435354767365 | 2        |
      | 289729251018539014 | 2        |
      | 289856910331478022 | 2        |
      | 289952219950743559 | 2        |
      | 290292200971960328 | 2        |
      | 290419860284899336 | 2        |
      | 288263370090479617 | 1        |
      | 288544845067190274 | 1        |
      | 288826320043900931 | 1        |
      | 289166301065117700 | 1        |
      | 289293960378056708 | 1        |
      | 289389269997322245 | 1        |
      | 289670744974032902 | 1        |
      | 290233694927454216 | 1        |
      | 289107795020611588 | 0        |
      | 288232351836667905 | -1       |
      | 288415253018968065 | -1       |
      | 290010725995249671 | -1       |
      | 290138385308188679 | -1       |
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.bfs(g, element_id(src), 'unknown') RETURN node_id AS _dst, distance
      """
    Then an Error should be raised:
      """
      [NP102]: Invalid argument for procedure `bfs`: invalid direction `unknown`, only allowed: incoming, bidirect or outgoing
      """
    When executing query:
      """
      USE ldbc match (v:Person{id:1}) return v NEXT USE ldbc CALL algo.bfs(v,1) RETURN *
      """
    Then an Error should be raised:
      """
      [NP102]: Invalid argument for procedure `bfs`: invalid graph input type, must be either a graph name or a graph reference, but got `NODE`
      """

  Scenario: BFS with filters
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS bfs_test_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE KNOWS (Person)-[:KNOWS{weight INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS bfs_test TYPED bfs_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET graph bfs_test
      """
    Then the execution should be successful
    # Insert nodes with properties
    When executing query:
      """
      TABLE t {id, name, age} =
      {id:0, name:"Alice", age:25},
      {id:1, name:"Bob", age:30},
      {id:2, name:"Charlie", age:35},
      {id:3, name:"David", age:28},
      {id:4, name:"Eve", age:32},
      {id:5, name:"Frank", age:27}
      FOR r IN t
      INSERT (@Person{id:r.id, name:r.name, age:r.age})
      """
    Then the execution should be successful
    # Insert edges with weight property
    When executing query:
      """
      TABLE t {src,dst,weight} =
      (0,1,2),
      (1,2,3),
      (0,3,1),
      (1,4,2),
      (2,5,1),
      (3,4,3),
      (4,5,2)
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[@KNOWS{weight: r.weight}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    # Test BFS with edge property filter (weight >= 2)
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person) WHERE e.weight >= 2 RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.bfs(g, element_id(src), 'outgoing', 10, 'weight >= 2') YIELD node_id AS _dst, distance
      FILTER distance > 0
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst, distance
      """
    Then the result should be, in any order:
      | dst | distance |
      | 1   | 1        |
      | 2   | 2        |
      | 4   | 2        |
      | 5   | 3        |
    # Test BFS with edge property filter (weight >= 2), bidirect
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person) WHERE e.weight >= 2 RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.bfs(g, element_id(src), 'bidirect', 10, 'weight >= 2') YIELD node_id AS _dst, distance
      FILTER distance > 0
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst, distance
      """
    Then the result should be, in any order:
      | dst | distance |
      | 1   | 1        |
      | 2   | 2        |
      | 3   | 3        |
      | 4   | 2        |
      | 5   | 3        |
    # Test BFS with node property filter (age <= 30)
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person) WHERE v2.age <= 30 RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.bfs(g, element_id(src), 'outgoing', 10, '', 'age <= 30') YIELD node_id AS _dst, distance
      FILTER distance > 0
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst, distance
      """
    Then the result should be, in any order:
      | dst | distance |
      | 3   | 1        |
      | 1   | 1        |
    # Test BFS with both edge and node filters (weight <= 2 AND age <= 30)
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person)
                       WHERE e.weight <= 2 AND v2.age <= 30
                       RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.bfs(g, element_id(src), "outgoing", 10, "weight <= 2", "age <= 30") YIELD node_id AS _dst, distance
      FILTER distance > 0
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst, distance
      """
    Then the result should be, in any order:
      | dst | distance |
      | 3   | 1        |
      | 1   | 1        |
    When executing query:
      """
      DROP GRAPH bfs_test
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE bfs_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION RESET graph
      """
    Then the execution should be successful
