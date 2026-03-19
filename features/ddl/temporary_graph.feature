# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: temporary graph

  Scenario: temporary graph of the anonGraphType
    When executing query:
      """
      create  temporary graph IF NOT EXISTS #test1 typed {NODE TYPE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING, vec1 VECTOR<3, float>, vec2
               VECTOR<128, float>}),EDGE TYPE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT, vec VECTOR<128, float>}]->(node_type_player)}
      """
    Then the execution should be successful

  Scenario: create drop show temporary graph
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS projection_test_type AS {
        NODE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS projection_base_graph TYPED projection_test_type
      """
    Then the execution should be successful
    And graph "projection_base_graph" should be ready to use
    When executing query:
      """
      DROP GRAPH non_exist_projection
      """
    Then an Error should be raised: "[01G03]: Graph `non_exist_projection` not found in schema `/default_schema`"
    When executing query:
      """
      TABLE t {id, name} = (1, "name")
      USE projection_base_graph
      FOR r IN t
      INSERT (@node_type_player {id: r.id, name: r.name})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection AS COPY OF projection_base_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #test_graph_projection AS COPY OF projection_base_graph
      """
    Then an Error should be raised: "[NR122]: Temporary graph already existed: `#test_graph_projection`"
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                     | graph_type             | schema        | owner  | extra               |
      | "#test_graph_projection" | "projection_test_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection AS COPY OF projection_base_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS show_projection_base TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "show_projection_base" should be ready to use
    When executing query:
      """
      TABLE t {id, name, url, kind} =
      {id:1, name:"Beijing", url:"https://beijing.com", kind:"city"}
      USE show_projection_base
      FOR r IN t
      INSERT (@Place{id:r.id,name:r.name,url:r.url,kind:r.kind})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #show_projection_projection AS COPY OF show_projection_base
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                          | graph_type             | schema        | owner  | extra               |
      | "#show_projection_projection" | "ldbc_type"            | "/tmp_schema" | "root" | "distributed:false" |
      | "#test_graph_projection"      | "projection_test_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #not_exist_projection AS COPY OF not_exist_graph
      """
    Then an Error should be raised: "[01G03]: Graph `not_exist_graph` not found in schema `/default_schema`"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #not_exist_projection AS COPY OF ""
      """
    Then an Error should be raised: "[42001]: empty identifier"
    When executing query:
      """
      DROP GRAPH #test_graph_projection
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                          | graph_type  | schema        | owner  | extra               |
      | "#show_projection_projection" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      DROP GRAPH #test_graph_projection
      """
    Then an Error should be raised: "[NR123]: Temporary graph not found: `#test_graph_projection`"
    When executing query:
      """
      DROP GRAPH IF EXISTS #test_graph_projection
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #test_graph_projection AS COPY OF projection_base_graph
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                          | graph_type             | schema        | owner  | extra               |
      | "#show_projection_projection" | "ldbc_type"            | "/tmp_schema" | "root" | "distributed:false" |
      | "#test_graph_projection"      | "projection_test_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      DROP GRAPH `projection_base_graph`
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_proj_test_ldbc_projection AS COPY OF ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                               | graph_type  | schema        | owner  | extra               |
      | "#show_projection_projection"      | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
      | "#graph_proj_test_ldbc_projection" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      DROP GRAPH #show_projection_projection
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                               | graph_type  | schema        | owner  | extra               |
      | "#graph_proj_test_ldbc_projection" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      DROP GRAPH #graph_proj_test_ldbc_projection
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH #test_graph_projection
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH #test_graph_projection
      """
    Then an Error should be raised: "[NR123]: Temporary graph not found: `#test_graph_projection`"
    When executing query:
      """
      DROP GRAPH TYPE projection_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS proj_test_ldbc_dml TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "proj_test_ldbc_dml" should be ready to use
    When executing query:
      """
      USE proj_test_ldbc_dml
      FOR i in range(1,10000)
      INSERT (a@Person{id:i})-[@KNOWS{}]->(b@Person{id:i+10000})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #projection_dml AS COPY OF proj_test_ldbc_dml
      """
    Then the execution should be successful
    When executing query:
      """
      USE #projection_dml SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 20000     |
      | "Edge Total" | "Edge"       | 10000     |
    When executing query:
      """
      USE proj_test_ldbc_dml
      FOR i in range(1,10000)
      MATCH (a@Person{id:i})
      MATCH (b@Person{id:i+1})
      INSERT (a)-[@KNOWS{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE #projection_dml SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 20000     |
      | "Edge Total" | "Edge"       | 10000     |
    When executing query:
      """
      USE proj_test_ldbc_dml
      MATCH (a)-[e]->(b)
      DELETE e
      """
    Then the execution should be successful
    # The projection stays the same
    When executing query:
      """
      USE #projection_dml SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 20000     |
      | "Edge Total" | "Edge"       | 10000     |
    When executing query:
      """
      DROP GRAPH #projection_dml
      """
    Then the execution should be successful
    And drop the graph "proj_test_ldbc_dml"
    And drop the graph "show_projection_base"
    # Graph reference as graph source
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_copy_of_ldbc AS COPY OF ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                      | graph_type  | schema        | owner  | extra               |
      | "#proj_from_copy_of_ldbc" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      USE #proj_from_copy_of_ldbc SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 34        |
      | "Edge Total" | "Edge"       | 74        |
    And drop the graph "proj_from_copy_of_ldbc"

  Scenario: create drop show temporary graph errors
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS projection_test_empty_type AS {}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS projection_empty_base_graph TYPED projection_test_empty_type
      """
    Then the execution should be successful
    And graph "projection_empty_base_graph" should be ready to use
    # projection on empty base graph
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_empty_graph_projection AS COPY OF projection_empty_base_graph
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: At least one node type is required to build a temporary graph"
    # projection on non-exist base graph
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #projection_dml AS COPY OF non_exist_base_graph
      """
    Then an Error should be raised: "[01G03]: Graph `non_exist_base_graph` not found in schema `/default_schema`"
    And drop the graph "projection_empty_base_graph"
    And drop the graph type "projection_test_empty_type"

  Scenario: multiple temporary graphs of the same base graph
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_multi_graph_projection1 AS COPY OF ldbc OPTIONS {without_properties: true}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_multi_graph_projection2 AS COPY OF ldbc OPTIONS {without_properties: true}
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH #test_multi_graph_projection1
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH #test_multi_graph_projection2
      """
    Then the execution should be successful

  Scenario: create temporary graph without properties
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection_no_prop AS COPY OF ldbc OPTIONS {without_properties: true}
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH #test_graph_projection_no_prop
      """
    Then the execution should be successful

  Scenario: create temporary graph concurrently
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */ CREATE TEMPORARY GRAPH IF NOT EXISTS #test_con_graph_projection AS COPY OF ldbc OPTIONS {without_properties: true}
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH #test_con_graph_projection
      """
    Then the execution should be successful

  @sf01
  # Fix https://github.com/vesoft-inc/nebula-ng/issues/5448
  Scenario: create drop temporary graph contains variable length patter
    # get total nodes
    When executing query:
      """
      USE sf01 MATCH TRAIL (v1{id:318})-[e]->{1,2}(v2) return v1 as e_node
      UNION
      USE sf01 MATCH TRAIL (v1{id:318})-[e]->{1,2}(v2) return v2 as e_node
      NEXT
      USE sf01 RETURN COUNT(DISTINCT e_node) AS sum_node GROUP BY ()
      """
    Then the result should be, in any order:
      | sum_node |
      | 4978     |
    When executing query:
      """
      USE sf01 MATCH TRAIL (v1{id:318})-[e]->{1,2}(v2)
      FOR _e IN e RETURN COUNT(DISTINCT _e) AS sum_edges GROUP BY ()
      """
    Then the result should be, in any order:
      | sum_edges |
      | 9715      |
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH {USE sf01 MATCH TRAIL (v1{id:318})-[e]->{1,2}(v2) RETURN v1,e,v2} RETURN g AS gx
      NEXT
      CALL algo.graph_stats(gx)
      RETURN total_edge_number, total_node_number
      """
    Then the result should be, in any order:
      | total_edge_number | total_node_number |
      | 9715              | 4978              |

  Scenario: create temporary graph with undirected undirected edges
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS projection_test_undirected_type AS {
      NODE node_type_person ( LABEL person {id INT PRIMARY KEY}),
      EDGE undirected_follow (node_type_person)~[ LABEL follow {id int multiedge key } ]~(node_type_person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS projection_base_undirected_graph TYPED projection_test_undirected_type
      """
    Then the execution should be successful
    And graph "projection_base_undirected_graph" should be ready to use
    When executing query:
      """
      USE projection_base_undirected_graph
      INSERT (:person{id:1})~[:follow{id:1}]~(:person{id:2})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE projection_base_undirected_graph
      MATCH (x:person{id:1})~[e]~(y)
      RETURN count(e) as count GROUP BY ()
      """
    Then the result should be, in any order:
      | count |
      | 1     |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_undirected_projection AS COPY OF projection_base_undirected_graph OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing query:
      """
      CALL algo.degree("#test_graph_undirected_projection")
      RETURN in_degree, out_degree
      """
    Then the result should be, in any order:
      | in_degree | out_degree |
      | 0         | 1          |
      | 1         | 0          |
    When executing query:
      """
      USE #test_graph_undirected_projection SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 2         |
      | "Edge Total" | "Edge"       | 1         |
    When executing query:
      """
      DROP GRAPH #test_graph_undirected_projection
      """
    Then the execution should be successful
    And drop the graph "projection_base_undirected_graph"
    And drop the graph type "projection_test_undirected_type"

  Scenario: create temporary graph from match result
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match AS COPY OF
      GRAPH{ USE ldbc MATCH(v) RETURN v }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #proj_from_match SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 34        |
      | "Edge Total" | "Edge"       | 0         |
    When executing query:
      """
      CREATE TEMPORARY GRAPH #proj_from_match AS COPY OF
      GRAPH{ USE ldbc MATCH(v) RETURN v }
      """
    Then an Error should be raised: "[NR122]: Temporary graph already existed: `#proj_from_match`"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match AS COPY OF
      GRAPH{ USE ldbc MATCH(v) RETURN v }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match2 AS COPY OF
      GRAPH{ USE ldbc MATCH(v)-[e]-(v2) RETURN v,e}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #proj_from_match2 SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 28        |
      | "Edge Total" | "Edge"       | 74        |
    # var-length pattern
    # issue https://github.com/vesoft-inc/nebula-ng/issues/7207
    When executing query:
      """
      /*+SET_VAR(query_concurrency=1)*/CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match_var AS COPY OF
      GRAPH { USE ldbc MATCH TRAIL (v1@Person)-[e]->{1,3}(v2) return v1,e,v2}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #proj_from_match_var SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 25        |
      | "Edge Total" | "Edge"       | 62        |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match4 AS COPY OF
      GRAPH { USE ldbc MATCH p=TRAIL (v1@Person)-[e]->{1,3}(v2) return nodes(p), relationships(p) }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match3 AS COPY OF
      GRAPH { USE ldbc MATCH (v1:Message{id:1}) OPTIONAL MATCH (v2:Message{id:10000}) RETURN v1, v2 }
      """
    Then the execution should be successful
    # no actual node data after filter
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_filtered_match AS COPY OF
      GRAPH{ USE ldbc MATCH (v:Forum where v.id =0) RETURN v }
      """
    Then the execution should be successful
    And drop the graph "#proj_from_match"
    And drop the graph "#proj_from_match2"
    And drop the graph "#proj_from_match3"
    And drop the graph "#proj_from_match4"
    And drop the graph "#proj_from_match_var"
    And drop the graph "#proj_from_filtered_match"

  Scenario: create temporary graph from match result errors
    # error: node type not found
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match_error AS COPY OF
      GRAPH{ USE ldbc MATCH(v:Person&City)-[e]-(v2) RETURN v,e,v2}
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(v:(Person) & (City))` was found"
    # error: dangling edges
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #proj_from_match_error AS COPY OF
      GRAPH { USE ldbc MATCH (v:Forum where v.id = 1)-[e]->(v2) RETURN v, e }
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"
