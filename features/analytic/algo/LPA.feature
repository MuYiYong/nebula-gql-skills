# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: LPA

  # karate_club_graph from python networkx
  Scenario: LPA procedure
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS lpa_test_graph ldbc_type
      """
    Then the execution should be successful
    And graph "lpa_test_graph" should be ready to use
    When executing graph query:
      """
      USE lpa_test_graph
      FOR i IN range(0, 33)
      INSERT (a@Person{id:i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src,dst} =
      (0, 1),(0, 2),(0, 3),(0, 4),(0, 5),
      (0, 6),(0, 7),(0, 8),(0, 10),(0, 11),
      (0, 12),(0, 13),(0, 17),(0, 19),(0, 21),
      (0, 31),(1, 2),(1, 3),(1, 7),(1, 13),
      (1, 17),(1, 19),(1, 21),(1, 30),(2, 3),
      (2, 7),(2, 8),(2, 9),(2, 13),(2, 27),
      (2, 28),(2, 32),(3, 7),(3, 12),(3, 13),
      (4, 6),(4, 10),(5, 6),(5, 10),(5, 16),
      (6, 16),(8, 30),(8, 32),(8, 33),(9, 33),
      (13, 33),(14, 32),(14, 33),(15, 32),(15, 33),
      (18, 32),(18, 33),(19, 33),(20, 32),(20, 33),
      (22, 32),(22, 33),(23, 25),(23, 27),(23, 29),
      (23, 32),(23, 33),(24, 25),(24, 27),(24, 31),
      (25, 31),(26, 29),(26, 33),(27, 33),(28, 31),
      (28, 33),(29, 32),(29, 33),(30, 32),(30, 33),
      (31, 32),(31, 33),(32, 33)
      USE lpa_test_graph
      FOR r IN t
      MATCH (a@Person{id:r.src}),(b@Person{id:r.dst})
      INSERT (a)-[@KNOWS{}]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_lpa_test_graph AS COPY OF lpa_test_graph
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_lpa_test_graph TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_lpa_test_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=lpa_test_graph&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_lpa_test_graph {
        NODE VALUE node_label      SumAgg<INT> = 0
        NODE VALUE node_count      SumAgg<INT> = 0
        NODE VALUE label_count_map MapAgg<INT, SumAgg<INT>>
        TABLE      result          TYPED TABLE {id INT, label_id INT}
        VALUE      new_active      OrAgg = true
        VALUE      iter = 0

        MATCH (a@Person)
        PER NODE (a) {
          SET a.@node_label = a.id
        }

        WHILE @new_active AND iter < 10 THEN {
          // LOG_INFO("------------------ iter == ", iter, " ------------------")
          SET @new_active = false
          SET iter = iter + 1
          MATCH (s@Person)-[@KNOWS]-(t@Person)
          PER PATH {
            SET t.@label_count_map += TUPLE(s.@node_label, 1)
          }
          PER NODE (t) {
            VALUE max_count INT = 0
            VALUE max_label INT = -1
            VALUE cur_iter = 0
            VALUE label_count_list = t.@label_count_map
            WHILE cur_iter < length(label_count_list) THEN {
              VALUE val = label_count_list[cur_iter]
              IF val._1 > max_count OR val._1 = max_count AND val._0 > max_label THEN {
                SET max_count = val._1
                SET max_label = val._0
              }
              SET cur_iter = cur_iter + 1
            }
            IF max_label <> -1 AND (max_count > t.@node_count AND max_label <> t.@node_label
             OR max_count = t.@node_count AND max_label > t.@node_label
            ) THEN {
              SET @new_active += true
              SET t.@node_count = max_count
              SET t.@node_label = max_label
            }
            SET t.@label_count_map.clear()
          }
        }

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.@node_label INTO result
        }

        FOR r IN result
        RETURN r.id, r.label_id
      }
      """
    Then the result should be, in any order:
      | r.id | r.label_id |
      | 4    | 31         |
      | 10   | 31         |
      | 7    | 33         |
      | 28   | 33         |
      | 5    | 31         |
      | 0    | 33         |
      | 25   | 33         |
      | 16   | 31         |
      | 9    | 33         |
      | 24   | 33         |
      | 2    | 33         |
      | 18   | 33         |
      | 19   | 33         |
      | 12   | 33         |
      | 23   | 33         |
      | 20   | 33         |
      | 21   | 33         |
      | 30   | 33         |
      | 27   | 33         |
      | 31   | 33         |
      | 32   | 33         |
      | 26   | 33         |
      | 33   | 33         |
      | 6    | 31         |
      | 3    | 33         |
      | 8    | 33         |
      | 15   | 33         |
      | 17   | 33         |
      | 14   | 33         |
      | 22   | 33         |
      | 1    | 33         |
      | 29   | 33         |
      | 13   | 33         |
      | 11   | 33         |
    And drop the graph "#dist_lpa_test_graph"
    And drop the graph "lpa_test_graph"
