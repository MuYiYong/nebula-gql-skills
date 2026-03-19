# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: KHop

  Scenario: KHop basic
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.khop(g, element_id(src), 'bidirect', 10) YIELD neighbor AS _dst
      MATCH (v WHERE element_id(v)=_dst)
      WHERE v.id <> 1
      RETURN DISTINCT v.id AS dst
      ORDER BY dst DESC
      LIMIT 10
      """
    Then the result should be, in order:
      | dst |
      | 6   |
      | 5   |
      | 4   |
      | 3   |
      | 2   |
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.khop(g, element_id(src), 'incoming', 10) YIELD neighbor AS _dst
      MATCH (v WHERE element_id(v)=_dst)
      WHERE v.id <> 1
      RETURN DISTINCT v.id AS dst
      ORDER BY dst DESC
      LIMIT 10
      """
    Then the result should be, in order:
      | dst |
      | 3   |
      | 2   |
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.khop(g, element_id(src), 'outgoing', 10) YIELD neighbor AS _dst
      MATCH (v WHERE element_id(v)=_dst)
      WHERE v.id <> 1
      RETURN DISTINCT v.id AS dst
      ORDER BY dst DESC
      LIMIT 10
      """
    Then the result should be, in order:
      | dst |
      | 6   |
      | 5   |
      | 4   |
      | 3   |
      | 2   |
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v1)-[e]->(v2) RETURN v1,e,v2 }
      USE ldbc MATCH (src:Person{id:1})
      CALL algo.khop(g, element_id(src), 'unknown', 1) RETURN *
      """
    Then an Error should be raised:
      """
      [NP102]: Invalid argument for procedure `khop`: invalid direction `unknown`, only allowed: incoming, bidirect or outgoing
      """
    When executing query:
      """
      USE ldbc match (v:Person{id:1}) return v NEXT USE ldbc CALL algo.khop(v,1) RETURN *
      """
    Then an Error should be raised:
      """
      [NP102]: Invalid argument for procedure `khop`: invalid graph input type, must be either a graph name or a graph reference, but got `NODE`
      """

  Scenario: KHop with filters
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS khop_test_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE KNOWS (Person)-[:KNOWS{weight INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS khop_test TYPED khop_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET graph khop_test
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
    # Test KHop with edge property filter (weight >= 2)
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person) WHERE e.weight >= 2 RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.khop(g, element_id(src), 'outgoing', 10, 'weight >= 2') YIELD neighbor AS _dst
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst
      """
    Then the result should be, in any order:
      | dst |
      | 0   |
      | 1   |
      | 2   |
      | 4   |
      | 5   |
    # Test KHop with edge property filter (weight >= 2), bidirect
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person) WHERE e.weight >= 2 RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.khop(g, element_id(src), 'bidirect', 10, 'weight >= 2') YIELD neighbor AS _dst
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst
      """
    Then the result should be, in any order:
      | dst |
      | 0   |
      | 1   |
      | 2   |
      | 3   |
      | 4   |
      | 5   |
    # Test KHop with node property filter (age <= 30)
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person) WHERE v2.age <= 30 RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.khop(g, element_id(src), 'outgoing', 10, '', 'age <= 30') YIELD neighbor AS _dst
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst
      """
    Then the result should be, in any order:
      | dst |
      | 3   |
      | 1   |
      | 0   |
    # Test KHop with both edge and node filters (weight <= 2 AND age <= 30)
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:KNOWS]->(v2:Person)
                       WHERE e.weight <= 2 AND v2.age <= 30
                       RETURN v1,e,v2 }
      MATCH (src:Person{id:0})
      CALL algo.khop(g, element_id(src), 'outgoing', 10, 'weight <= 2', 'age <= 30') YIELD neighbor AS _dst
      MATCH (v WHERE element_id(v)=_dst)
      RETURN v.id AS dst
      """
    Then the result should be, in any order:
      | dst |
      | 3   |
      | 1   |
      | 0   |
    When executing query:
      """
      DROP GRAPH khop_test
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE khop_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION RESET graph
      """
    Then the execution should be successful
