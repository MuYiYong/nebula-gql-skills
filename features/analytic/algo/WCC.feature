# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: WCC

  Scenario: WCC procedure
    When executing graph query:
      """
      CREATE GRAPH wcc_test_graph ldbc_type
      """
    Then the execution should be successful
    And graph "wcc_test_graph" should be ready to use
    When executing graph query:
      """
      USE wcc_test_graph
      FOR i IN range(1,30)
      INSERT (a@Person{id:i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src, dst} =
      (1,2),(2,3),(2,4),(4,5),(5,1),
      (6,7),(6,8),(8,9),(9,10),(10,7),
      (11,12),(13,15),(15,11),(12,11),(14,11),
      (17,16),(16,18),(18,19),(20,19),(20,1),
      (20,21),(21,22),(22,23),(23,24),(24,25),
      (27,26),(26,27),(27,28),(28,29)
      USE wcc_test_graph
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[:KNOWS]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #wcc_test_dist_graph AS COPY OF wcc_test_graph
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #wcc_test_dist_graph TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #wcc_test_dist_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=wcc_test_graph&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #wcc_test_dist_graph {
        NODE VALUE component_id  MinAgg<INT> = 0
        VALUE      new_active    OrAgg  = true
        TABLE      result_table  TYPED TABLE {id INT, component_id INT}
        VALUE      v_set         ACTIVE_SET

        MATCH (a@Person)
        PER NODE (a) {
          SET a.@component_id = a.id
        }
        FINALLY {
          SET v_set = a
        }

        WHILE @new_active = true THEN {
          SET @new_active = false
          LOG_INFO("-----next stage----")
          MATCH (a@Person)-[e@KNOWS]-(b)
          WHERE a.@component_id < b.@component_id
                AND a IN v_set
          PER PATH {
            SET b.@component_id += a.@component_id
            SET @new_active += true
          }
          FINALLY {
            SET v_set = b
          }
        }

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.@component_id INTO result_table
        }
        FOR r IN result_table
        RETURN r.component_id as component_id, count(*) group by (component_id)
      }
      """
    Then the result should be, in any order:
      | component_id | count(*) |
      | 1            | 15       |
      | 6            | 5        |
      | 26           | 4        |
      | 30           | 1        |
      | 11           | 5        |
    # WCC without active_set
    # If some nodes have a very large number of incoming edges (super nodes),
    # in order to prevent these super nodes from reducing computation parallelism,
    # we abandon the use of ACTIVE_SET and always traverse using only outgoing edges.
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS wcc_no_active_set() RETURNS (component_id int, cnt int) AS {
        NODE VALUE component_id  MinAgg<INT> = 0
        VALUE      new_active    OrAgg  = true
        TABLE      result_table  TYPED TABLE {id INT, component_id INT}

        MATCH (a@Person)
        PER NODE (a) {
          SET a.@component_id = a.id
        }

        WHILE @new_active = true THEN {
          SET @new_active = false
          LOG_INFO("-----next stage----")
          MATCH (a@Person)-[e@KNOWS]->(b)
          WHERE a.@component_id <> b.@component_id
          PER PATH {
            IF a.@component_id < b.@component_id THEN {
              SET b.@component_id += a.@component_id
            } ELSE {
              SET a.@component_id += b.@component_id
            }
            SET @new_active += true
          }
        }

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.@component_id INTO result_table
        }
        FOR r IN result_table
        RETURN r.component_id as component_id, count(*) AS cnt group by (component_id)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #wcc_test_dist_graph CALL wcc_no_active_set() RETURN component_id, cnt
      """
    Then the result should be, in any order:
      | component_id | cnt |
      | 1            | 15  |
      | 6            | 5   |
      | 26           | 4   |
      | 30           | 1   |
      | 11           | 5   |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #wcc_test_mut_graph AS COPY OF wcc_test_graph
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #wcc_test_mut_graph CALL wcc_no_active_set() RETURN component_id, cnt
      """
    Then the result should be, in any order:
      | component_id | cnt |
      | 1            | 15  |
      | 6            | 5   |
      | 26           | 4   |
      | 30           | 1   |
      | 11           | 5   |
    And drop the graph "#wcc_test_mut_graph"
    And drop the graph "#wcc_test_dist_graph"
    And drop the graph "wcc_test_graph"
    And drop the procedure "wcc_no_active_set"
