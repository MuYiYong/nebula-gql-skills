# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Dijkstra

  Scenario: int dijkstra
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /dijkstra/`int`
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /dijkstra/`int`
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS int_dijkstra_gt AS {
        NODE TYPE nod (LABEL nod {id INT PRIMARY KEY}),
        EDGE TYPE edg (nod)-[LABEL edg {distance INT NOT NULL}]->(nod)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS int_dijkstra_graph TYPED int_dijkstra_gt
      """
    Then the execution should be successful
    And graph "int_dijkstra_graph" should be ready to use
    When executing query:
      """
      USE int_dijkstra_graph INSERT
      (a@nod{id: 1}),
      (b@nod{id: 2}),
      (c@nod{id: 3}),
      (d@nod{id: 4}),
      (e@nod{id: 5}),
      (f@nod{id: 6}),
      (g@nod{id: 7}),
      (a)-[:edg{distance: 1}]->(b),
      (a)-[:edg{distance: 2}]->(c),
      (a)-[:edg{distance: 10}]->(f),
      (b)-[:edg{distance: 3}]->(d),
      (b)-[:edg{distance: 1}]->(e),
      (c)-[:edg{distance: 3}]->(d),
      (d)-[:edg{distance: 4}]->(f),
      (e)-[:edg{distance: 8}]->(f),
      (g)-[:edg{distance: 0}]->(a)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #int_dijkstra_graph_p1 AS COPY OF int_dijkstra_graph OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE int_dijkstra_graph
      MATCH (v:nod{id: 1})
      RETURN element_id(v) AS src
      NEXT
      USE int_dijkstra_graph
      CALL algo.dijkstra("#int_dijkstra_graph_p1", src, "distance")
      RETURN distance
      ORDER BY distance DESC
      LIMIT 10
      """
    Then the result should be, in any order:
      | distance |
      | 8        |
      | 4        |
      | 2        |
      | 2        |
      | 1        |
      | 0        |
      | -1       |
    When executing query:
      """
      CALL algo.dijkstra("#int_dijkstra_graph_p1", 4294967296, "distance")
      RETURN distance
      ORDER BY distance DESC
      LIMIT 10
      """
    Then an Error should be raised:
      """
      [NP102]: Invalid argument for procedure `dijkstra`: src node `4294967296` not found in graph `#int_dijkstra_graph_p1`
      """
    And drop the graph "#int_dijkstra_graph_p1"
    And drop the graph "int_dijkstra_graph"
    And drop the graph type "int_dijkstra_gt"
    When executing query:
      """
      DROP SCHEMA /dijkstra/"int"
      """
    Then the execution should be successful
    And close the current session

  # 0.3 + 0.6 = 0.89999999999999991 < 0.9
  # if eps is normal or use relative eps,
  # dis(node4) = dis(node5) = dis(node6) = 0.9
  # 1 -0.9> 4
  # 1 -0.9> 5
  # 1 -0.9> 4 -0> 6
  # but if eps is very small, eps will be ineffective,
  # dis(node4) = dis(node5) = dis(node6) = 0.89999999999999991
  # node4 and node5 will be updated by another path
  # 1 -0.3> 2 -0.6> 4
  # 1 -0.3> 3 -0.6> 5
  # 1 -0.3> 2 -0.6> 4 -0> 6
  Scenario: double dijkstra with relative eps
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /dijkstra/double1
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /dijkstra/double1
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS double_dijkstra_gt AS {
        NODE TYPE nod (LABEL nod {id INT PRIMARY KEY}),
        EDGE TYPE edg (nod)-[LABEL edg {distance FLOAT64 NOT NULL}]->(nod)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS double_dijkstra_graph TYPED double_dijkstra_gt
      """
    Then the execution should be successful
    And graph "double_dijkstra_graph" should be ready to use
    When executing query:
      """
      USE double_dijkstra_graph INSERT
      (a@nod{id: 1}),
      (b@nod{id: 2}),
      (c@nod{id: 3}),
      (d@nod{id: 4}),
      (e@nod{id: 5}),
      (f@nod{id: 6}),
      (g@nod{id: 7}),
      (a)-[:edg{distance: 0.3}]->(b),
      (a)-[:edg{distance: 0.6}]->(c),
      (a)-[:edg{distance: 0.9}]->(d),
      (a)-[:edg{distance: 0.9}]->(e),
      (a)-[:edg{distance: 0.9}]->(f),
      (b)-[:edg{distance: 0.6}]->(d),
      (c)-[:edg{distance: 0.3}]->(e),
      (d)-[:edg{distance: 0.0}]->(f),
      (e)-[:edg{distance: 0.0}]->(f),
      (g)-[:edg{distance: 0}]->(a)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #double_dijkstra_graph_p2 AS COPY OF double_dijkstra_graph OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE double_dijkstra_graph
      MATCH (v:nod{id: 1})
      RETURN element_id(v) AS src
      NEXT
      USE double_dijkstra_graph
      CALL algo.dijkstra('#double_dijkstra_graph_p2', src, 'distance')
      RETURN distance
      ORDER BY distance DESC
      LIMIT 10
      """
    Then the result should be, in any order:
      | distance |
      | 0.9      |
      | 0.9      |
      | 0.9      |
      | 0.6      |
      | 0.3      |
      | 0        |
      | -1       |
    And drop the graph "#double_dijkstra_graph_p2"
    And drop the graph "double_dijkstra_graph"
    And drop the graph type "double_dijkstra_gt"
    When executing query:
      """
      DROP SCHEMA /dijkstra/double1
      """
    Then the execution should be successful
    And close the current session

  Scenario: double dijkstra with const eps
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /dijkstra/double2
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /dijkstra/double2
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS double2_dijkstra_gt AS {
        NODE TYPE nod (LABEL nod {id INT PRIMARY KEY}),
        EDGE TYPE edg (nod)-[LABEL edg {distance FLOAT64 NOT NULL}]->(nod)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS double2_dijkstra_graph TYPED double2_dijkstra_gt
      """
    Then the execution should be successful
    And graph "double2_dijkstra_graph" should be ready to use
    When executing query:
      """
      USE double2_dijkstra_graph INSERT
      (a@nod{id: 1}),
      (b@nod{id: 2}),
      (c@nod{id: 3}),
      (d@nod{id: 4}),
      (e@nod{id: 5}),
      (f@nod{id: 6}),
      (g@nod{id: 7}),
      (a)-[:edg{distance: 0.3}]->(b),
      (a)-[:edg{distance: 0.6}]->(c),
      (a)-[:edg{distance: 0.9}]->(d),
      (a)-[:edg{distance: 0.9}]->(e),
      (a)-[:edg{distance: 0.9}]->(f),
      (b)-[:edg{distance: 0.6}]->(d),
      (c)-[:edg{distance: 0.3}]->(e),
      (d)-[:edg{distance: 0.0}]->(f),
      (e)-[:edg{distance: 0.0}]->(f),
      (g)-[:edg{distance: 0}]->(a)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #double2_dijkstra_graph_p3 AS COPY OF double2_dijkstra_graph OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE double2_dijkstra_graph
      MATCH (v:nod{id: 1})
      RETURN element_id(v) AS src
      NEXT
      USE double2_dijkstra_graph
      CALL algo.dijkstra('#double2_dijkstra_graph_p3', src, 'distance', 1e-8)
      RETURN distance
      ORDER BY distance DESC
      LIMIT 10
      """
    Then the result should be, in any order:
      | distance |
      | 0.9      |
      | 0.9      |
      | 0.9      |
      | 0.6      |
      | 0.3      |
      | 0        |
      | -1       |
    And drop the graph "#double2_dijkstra_graph_p3"
    And drop the graph "double2_dijkstra_graph"
    And drop the graph type "double2_dijkstra_gt"
    When executing query:
      """
      DROP SCHEMA /dijkstra/double2
      """
    Then the execution should be successful
    And close the current session

  Scenario: double dijkstra with tiny eps
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /dijkstra/double3
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /dijkstra/double3
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS double3_dijkstra_gt AS {
        NODE TYPE nod (LABEL nod {id INT PRIMARY KEY}),
        EDGE TYPE edg (nod)-[LABEL edg {distance FLOAT64 NOT NULL}]->(nod)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS double3_dijkstra_graph TYPED double3_dijkstra_gt
      """
    Then the execution should be successful
    And graph "double3_dijkstra_graph" should be ready to use
    When executing query:
      """
      USE double3_dijkstra_graph INSERT
      (a@nod{id: 1}),
      (b@nod{id: 2}),
      (c@nod{id: 3}),
      (d@nod{id: 4}),
      (e@nod{id: 5}),
      (f@nod{id: 6}),
      (g@nod{id: 7}),
      (a)-[:edg{distance: 0.3}]->(b),
      (a)-[:edg{distance: 0.6}]->(c),
      (a)-[:edg{distance: 0.9}]->(d),
      (a)-[:edg{distance: 0.9}]->(e),
      (a)-[:edg{distance: 0.9}]->(f),
      (b)-[:edg{distance: 0.6}]->(d),
      (c)-[:edg{distance: 0.3}]->(e),
      (d)-[:edg{distance: 0.0}]->(f),
      (e)-[:edg{distance: 0.0}]->(f),
      (g)-[:edg{distance: 0}]->(a)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #double3_dijkstra_graph_p4 AS COPY OF double3_dijkstra_graph OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE double3_dijkstra_graph
      MATCH (v:nod{id: 1})
      RETURN element_id(v) AS src
      NEXT
      USE double3_dijkstra_graph
      CALL algo.dijkstra("#double3_dijkstra_graph_p4", src, "distance", 1e-30)
      RETURN distance
      ORDER BY distance DESC
      LIMIT 10
      """
    Then the result should be, in any order:
      | distance            |
      | 0.89999999999999991 |
      | 0.89999999999999991 |
      | 0.89999999999999991 |
      | 0.6                 |
      | 0.3                 |
      | 0                   |
      | -1                  |
    And drop the graph "#double3_dijkstra_graph_p4"
    And drop the graph "double3_dijkstra_graph"
    And drop the graph type "double3_dijkstra_gt"
    When executing query:
      """
      DROP SCHEMA /dijkstra/double3
      """
    Then the execution should be successful
    And close the current session

  Scenario: invalid dijkstra negative edge value
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /dijkstra/invalid
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /dijkstra/invalid
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_dijkstra_gt AS {
        NODE TYPE nod (LABEL nod {id INT PRIMARY KEY}),
        EDGE TYPE edg (nod)-[LABEL edg {distance INT NOT NULL}]->(nod)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS invalid_dijkstra_graph TYPED invalid_dijkstra_gt
      """
    Then the execution should be successful
    And graph "invalid_dijkstra_graph" should be ready to use
    When executing query:
      """
      USE invalid_dijkstra_graph INSERT
      (a@nod{id: 1}),
      (b@nod{id: 2}),
      (a)-[:edg{distance: -1}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #invalid_dijkstra_graph_p5 AS COPY OF invalid_dijkstra_graph OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE invalid_dijkstra_graph
      MATCH (v:nod{id: 1})
      RETURN element_id(v) AS src
      NEXT
      USE invalid_dijkstra_graph
      CALL algo.dijkstra("#invalid_dijkstra_graph_p5", src, "distance")
      RETURN distance
      """
    Then an Error should be raised:
      """
      [NG002]: Algorithm `Dijkstra`, invalid edge distance: Edge `[:(288263370090479617->288449535447924737 0@1024) distance:-1]` property `distance` should be non-negative number, but got `-1`
      """
    And drop the graph "#invalid_dijkstra_graph_p5"
    And drop the graph "invalid_dijkstra_graph"
    And drop the graph type "invalid_dijkstra_gt"
    When executing query:
      """
      DROP SCHEMA /dijkstra/invalid
      """
    Then the execution should be successful
    And close the current session
