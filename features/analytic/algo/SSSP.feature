# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: SSSP

  Scenario: positive weight SSSP procedure
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS positive_sssp_test_gt {
        NODE TYPE Place (LABEL Place {id INT PRIMARY KEY}),
        EDGE TYPE Connect (Place)-[LABEL Connect {distance INT}]->(Place)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS positive_sssp_test_g positive_sssp_test_gt
      """
    Then the execution should be successful
    And graph "positive_sssp_test_g" should be ready to use
    When executing graph query:
      """
      USE positive_sssp_test_g
      FOR i IN range(1,12)
      INSERT (a@Place{id:i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src, dst, dist} =
      (1,2,3),(1,3,4),(2,3,2),(1,9,9),(1,7,9),
      (7,9,2),(3,7,1),(2,6,999),(3,5,1),(3,8,1),
      (5,6,2),(5,11,5),(6,10,1),(10,11,1)
      USE positive_sssp_test_g
      FOR r IN t
      MATCH (a@Place) WHERE a.id = r.src
      MATCH (b@Place) WHERE b.id = r.dst
      INSERT OR REPLACE (a)-[:Connect{distance:r.dist}]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #positive_sssp_test_dist_graph AS COPY OF positive_sssp_test_g
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #positive_sssp_test_dist_graph TYPED positive_sssp_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #positive_sssp_test_dist_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=positive_sssp_test_g&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS sssp() RETURNS (vid int, min_dst int) AS {
        NODE VALUE min_dist      MinAgg<INT> = 10000000000 + 7
        VALUE      new_active    OrAgg = true
        TABLE      result_table  TYPED TABLE {id INT, min_dist INT}
        VALUE      v_set         ACTIVE_SET

        MATCH (a) WHERE a.id = 1
        PER NODE (a) {
          SET a.@min_dist = 0
        }
        FINALLY {
          SET v_set = a
        }

        WHILE @new_active = true THEN {
          SET @new_active = false
          LOG_INFO("-----next stage----")
          MATCH (a)-[e]-(b)
          WHERE a.@min_dist + e.distance < b.@min_dist
                AND a IN v_set
          PER PATH {
              LOG_INFO("min_dist[",b.id,"] = " ,  a.@min_dist + e.distance)
              SET b.@min_dist += a.@min_dist + e.distance
              SET @new_active += true
          }
          FINALLY {
            SET v_set = b
          }
        }

        MATCH (a)
        PER NODE (a) {
          EXPORT a.id, a.@min_dist INTO result_table
        }
        FOR r IN result_table
        ORDER BY r.id
        RETURN r.id AS vid, r.min_dist AS min_dst
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #positive_sssp_test_dist_graph CALL sssp() RETURN vid, min_dst
      """
    Then the result should be, in order:
      | vid | min_dist    |
      | 1   | 0           |
      | 2   | 3           |
      | 3   | 4           |
      | 4   | 10000000007 |
      | 5   | 5           |
      | 6   | 7           |
      | 7   | 5           |
      | 8   | 5           |
      | 9   | 7           |
      | 10  | 8           |
      | 11  | 9           |
      | 12  | 10000000007 |
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #positive_sssp_test_mut_graph AS COPY OF positive_sssp_test_g
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #positive_sssp_test_mut_graph CALL sssp() RETURN vid, min_dst
      """
    Then the result should be, in order:
      | vid | min_dist    |
      | 1   | 0           |
      | 2   | 3           |
      | 3   | 4           |
      | 4   | 10000000007 |
      | 5   | 5           |
      | 6   | 7           |
      | 7   | 5           |
      | 8   | 5           |
      | 9   | 7           |
      | 10  | 8           |
      | 11  | 9           |
      | 12  | 10000000007 |
    And drop the graph "#positive_sssp_test_mut_graph"
    And drop the graph "#positive_sssp_test_dist_graph"
    And drop the graph "positive_sssp_test_g"
    And drop the graph type "positive_sssp_test_gt"
    And drop the procedure "sssp"
