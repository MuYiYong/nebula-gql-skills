# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: BiBFS

  @sf01
  Scenario: BiBFS
    When executing query:
      """
      USE sf01
      MATCH ANY SHORTEST (person1:Person{id:2199023256586})<-[e:KNOWS]->*(person2:Person{id:32985348833679})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE sf01
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 3                  |
    When executing query:
      """
      USE sf01
      OPTIONAL MATCH ANY SHORTEST (person1:Person{id:2199023256586})<-[e:KNOWS]->*(person2:Person{id:32985348833679})
      RETURN CASE WHEN e IS NULL THEN -1 ELSE length(e) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 3                  |
    When executing query:
      """
      USE sf01
      MATCH ANY SHORTEST (person1:Person{id:2199023256586})-[e]-*(person2:Person{id:32985348833679})
      RETURN collect(e) AS l GROUP BY ()
      NEXT
      USE sf01
      RETURN CASE WHEN size(l) = 0 THEN -1 ELSE size(l[0]) END AS shortestPathLength
      """
    Then the result should be, in any order:
      | shortestPathLength |
      | 2                  |

  Scenario: run bibfs procedure on memory or temporary graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS simple_ldbc_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING}),
        EDGE FOLLOWS (Person)-[:FOLLOWS{follow_year INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS simple_ldbc TYPED simple_ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET GRAPH "simple_ldbc"
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, name} =
      {id:1, name:"Kyle"},
      {id:2, name:"Tim"},
      {id:3, name:"Ming"},
      {id:4, name:"Sophie"}
      FOR r IN t
      INSERT (@Person{id:r.id,name:r.name})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst,follow_year} =
      (1,2,2021),
      (2,3,2022),
      (3,4,2023),
      (3,1,2024)
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[@FOLLOWS{follow_year: r.follow_year}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #simple_ldbc_mirror AS COPY OF simple_ldbc OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    # run procedure on memory graph
    When executing query:
      """
      GRAPH g = GRAPH { MATCH (v1:Person)-[e:FOLLOWS]-(v2:Person) RETURN v1, e, v2 }
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs(g, src_id, dst_id, 10, true, "outgoing") YIELD paths AS ougoing_paths
      OPTIONAL CALL algo.bibfs(g, src_id, dst_id, 10, true, "incoming") YIELD paths AS incoming_paths
      OPTIONAL CALL algo.bibfs(g, src_id, dst_id, 10, true, "bidirect") YIELD paths AS bidirect_paths
      RETURN count(ougoing_paths) AS cnt0, count(incoming_paths) AS cnt1, count(bidirect_paths) AS cnt2 GROUP BY()
      """
    Then the result should be, in any order:
      | cnt0 | cnt1 | cnt2 |
      | 1    | 0    | 1    |
    # run procedure on mem graph "#simple_ldbc_mirror".
    # NOTE: Currently, when used as a procedure parameter, the mem graph name must be quoted.
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#simple_ldbc_mirror", src_id, dst_id, 10, true, "outgoing") YIELD paths AS outgoing_paths
      RETURN CASE WHEN outgoing_paths IS NULL THEN 0 ELSE length(outgoing_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 4   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#simple_ldbc_mirror", src_id, dst_id, 10, true, "incoming") YIELD paths AS incoming_paths
      RETURN CASE WHEN incoming_paths IS NULL THEN 0 ELSE length(incoming_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 0   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#simple_ldbc_mirror", src_id, dst_id, 10, true, "bidirect") YIELD paths AS bidirect_paths
      RETURN CASE WHEN bidirect_paths IS NULL THEN 0 ELSE length(bidirect_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 3   |
    # When executing query:
    # """
    # GRAPH g = { MATCH (v1:Person)-[e:FOLLOWS]-(v2:Person) RETURN v1, e, v2 }
    # CALL algo.pagerank(g, 10, 0.85) YIELD ranking
    # RETURN ranking ORDER BY ranking DESC
    # """
    # Then the result should be, in any order:
    # | ranking            |
    # | 4.2656279782963855 |
    # | 0.7875             |
    # | 0.7875             |
    # | 0.7875             |
    And drop the graph "#simple_ldbc_mirror"
    And drop the graph "simple_ldbc"
    And drop the graph type "simple_ldbc_type"
    When executing query:
      """
      SESSION RESET GRAPH
      """
    Then the execution should be successful

  Scenario: run bibfs procedure on temporary graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_graph_proj_bibfs_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING}),
        EDGE FOLLOWS (Person)-[:FOLLOWS{follow_year INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_graph_proj_bibfs_source TYPED test_graph_proj_bibfs_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET GRAPH "test_graph_proj_bibfs_source"
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, name} =
      {id:1, name:"Kyle"},
      {id:2, name:"Tim"},
      {id:3, name:"Ming"},
      {id:4, name:"Sophie"}
      FOR r IN t
      INSERT (@Person{id:r.id,name:r.name})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst,follow_year} =
      (1,2,2021),
      (2,3,2022),
      (3,4,2023),
      (3,1,2024)
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[@FOLLOWS{follow_year: r.follow_year}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_proj_bibfs_projection AS COPY OF test_graph_proj_bibfs_source OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #test_graph_proj_bibfs_projection SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 4         |
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    # run procedure on temporary graph "#test_graph_proj_bibfs_projection".
    # NOTE: Currently, when used as a procedure parameter, the mirror graph name must be quoted.
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#test_graph_proj_bibfs_projection", src_id, dst_id, 10, true, "outgoing") YIELD paths AS outgoing_paths
      RETURN CASE WHEN outgoing_paths IS NULL THEN 0 ELSE length(outgoing_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 4   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#test_graph_proj_bibfs_projection", src_id, dst_id, 10, true, "outgoing", true) YIELD paths AS outgoing_paths
      RETURN CASE WHEN outgoing_paths IS NULL THEN 0 ELSE length(outgoing_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 4   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#test_graph_proj_bibfs_projection", src_id, dst_id, 10, true, "outgoing") YIELD paths AS outgoing_paths
      RETURN CASE WHEN outgoing_paths IS NULL THEN 0 ELSE length(outgoing_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 4   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#test_graph_proj_bibfs_projection", src_id, dst_id, 10, true, "incoming", true) YIELD paths AS incoming_paths
      RETURN CASE WHEN incoming_paths IS NULL THEN 0 ELSE length(incoming_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 0   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#test_graph_proj_bibfs_projection", src_id, dst_id, 10, true, "incoming") YIELD paths AS incoming_paths
      RETURN CASE WHEN incoming_paths IS NULL THEN 0 ELSE length(incoming_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 0   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#test_graph_proj_bibfs_projection", src_id, dst_id, 10, true, "bidirect", true) YIELD paths AS bidirect_paths
      RETURN CASE WHEN bidirect_paths IS NULL THEN 0 ELSE length(bidirect_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 3   |
    When executing query:
      """
      VALUE src_id = VALUE { MATCH (src:Person{id: 1}) RETURN element_id(src) LIMIT 1 }
      VALUE dst_id = VALUE { MATCH (dst:Person{id: 4}) RETURN element_id(dst) LIMIT 1 }
      OPTIONAL CALL algo.bibfs("#test_graph_proj_bibfs_projection", src_id, dst_id, 10, true, "bidirect") YIELD paths AS bidirect_paths
      RETURN CASE WHEN bidirect_paths IS NULL THEN 0 ELSE length(bidirect_paths) END AS len
      """
    Then the result should be, in any order:
      | len |
      | 3   |
    When executing query:
      """
      CALL algo.pagerank('#test_graph_proj_bibfs_projection', 10, 0.85) YIELD ranking
      RETURN ranking ORDER BY ranking DESC
      """
    Then the result should be, in order:
      | ranking            |
      | 0.5696980028083496 |
      | 0.4937623562451172 |
      | 0.3921216511935486 |
      | 0.3921216511935486 |
    When executing query:
      """
      CALL algo.wcc("#test_graph_proj_bibfs_projection") YIELD component_id
      RETURN component_id ORDER BY component_id DESC
      """
    Then the execution should be successful
    # Then the result should be, in order:
    # | component_id |
    # | 1            |
    # | 1            |
    # | 1            |
    # | 0            |
    When executing query:
      """
      CALL algo.degree("#test_graph_proj_bibfs_projection") YIELD in_degree, out_degree
      RETURN in_degree, out_degree ORDER BY in_degree DESC, out_degree DESC
      """
    Then the result should be, in order:
      | in_degree | out_degree |
      | 1         | 2          |
      | 1         | 1          |
      | 1         | 1          |
      | 1         | 0          |
    When executing query:
      """
      CALL algo.louvain("#test_graph_proj_bibfs_projection", 10) YIELD community, node_id
      RETURN count(node_id) AS c GROUP BY community ORDER BY c DESC
      """
    Then the result should be, in any order:
      | c |
      | 2 |
      | 1 |
      | 1 |
    And drop the graph "#test_graph_proj_bibfs_projection"
    And drop the graph "test_graph_proj_bibfs_source"
    And drop the graph type "test_graph_proj_bibfs_type"
    When executing query:
      """
      SESSION RESET GRAPH
      """
    Then the execution should be successful

  Scenario: Test graph stats algorithm procedure
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CALL algo.graph_stats('ldbc') RETURN *
      """
    Then an Error should be raised:
      """
      [NP102]: Invalid argument for procedure `graph_stats`: argument `"ldbc"` is of type `STRING` instead of the expected `GRAPH<NODES[],EDGES[]>`
      """
    When executing query:
      """
      GRAPH g = GRAPH { USE ldbc MATCH (v)-[e]-(v2) RETURN v, e, v2 }
      CALL algo.graph_stats(g) RETURN total_edge_number, total_node_number
      """
    Then the result should be, in any order:
      | total_edge_number | total_node_number |
      | 74                | 28                |

  Scenario: Test SHORTEST PATH with NULL input from preceding OPTIONAL MATCH
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS simple_ldbc_type1 AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING}),
        EDGE FOLLOWS (Person)-[:FOLLOWS{follow_year INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS simple_ldbc1 TYPED simple_ldbc_type1
      """
    Then the execution should be successful
    When executing query:
      """
      USE simple_ldbc1 {
        TABLE t {id, name} =
        {id:1, name:"Kyle"},
        {id:2, name:"Tim"},
        {id:3, name:"Ming"},
        {id:4, name:"Sophie"}
        FOR r IN t
        INSERT (@Person{id:r.id,name:r.name})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE simple_ldbc1 {
        TABLE t {src,dst,follow_year} =
        (1,2,2021),
        (2,3,2022),
        (3,4,2023),
        (3,1,2024)
        FOR r IN t
        MATCH (a@Person) WHERE a.id = r.src
        MATCH (b@Person) WHERE b.id = r.dst
        INSERT (a)-[@FOLLOWS{follow_year: r.follow_year}]->(b)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE simple_ldbc1
      OPTIONAL MATCH ()-[:FOLLOWS]->(), (v3:Person{name:"DoesNotExist"})

      OPTIONAL MATCH ALL SHORTEST PATH (v3)-{1}({id: 4})

      RETURN 1
      """
    Then the result should be, in any order:
      | 1 |
      | 1 |
    And drop the graph "simple_ldbc1"
    And drop the graph type "simple_ldbc_type1"
