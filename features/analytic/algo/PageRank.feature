# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: PageRank

  Scenario: PageRank on a small graph
    And create a new session with username "root" and password "NebulaGraph01"
    When executing graph query:
      """
      SESSION SET enable_tracing=true
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS page_rank_simple_graph_type AS {
          NODE Person (LABEL Person {
              id INT PRIMARY KEY,
              name STRING
          }),
          EDGE KNOWS (Person)-[:KNOWS]->(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS simple_graph_for_page_rank TYPED page_rank_simple_graph_type
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE persons {id, name} =
      {id:1, name:"Alice"},
      {id:2, name:"Bob"},
      {id:3, name:"Charlie"},
      {id:4, name:"David"}
      USE simple_graph_for_page_rank
      FOR r IN persons
      INSERT (@Person{id:r.id, name:r.name})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edges {src, dst} =
      (1,2),
      (2,3),
      (1,4),
      (3,4),
      (4,2)
      USE simple_graph_for_page_rank
      FOR r IN edges
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[@KNOWS{}]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #simple_graph_for_page_rank_projection AS COPY OF simple_graph_for_page_rank  OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #simple_graph_for_page_rank_projection TYPED page_rank_simple_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #simple_graph_for_page_rank_projection IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=simple_graph_for_page_rank&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing graph query:
      """
      CALL algo.pagerank("#simple_graph_for_page_rank_projection", 30, 0.85, 0.01)
      YIELD node_id, ranking
      RETURN node_id, round(ranking, 5) AS rank
      ORDER BY rank DESC
      """
    Then the result should be, in order:
      | node_id            | rank    |
      | 288449535447924737 | 1.3033  |
      | 288472492048121857 | 1.28564 |
      | 288321876134985729 | 1.26105 |
      | 288263370090479617 | 0.15    |
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #simple_graph_for_page_rank_dist_projection AS COPY OF simple_graph_for_page_rank
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #simple_graph_for_page_rank_dist_projection TYPED page_rank_simple_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #simple_graph_for_page_rank_dist_projection IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=simple_graph_for_page_rank&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE pagerank(damping DOUBLE, max_iter INT) RETURNS (final_delta DOUBLE, id INT64, rank DOUBLE) AS {
        VALUE      cur_iter      INT64  = 1
        VALUE      add_constant  DOUBLE = 1.0 - 0.85
        VALUE      delta         SumAgg<DOUBLE> = 1.0
        VALUE      total_nodes   SumAgg<INT>    = 0
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        NODE VALUE next_score    SumAgg<DOUBLE> = 0.0
        NODE VALUE out_edge      SumAgg<INT64>  = 0

        TABLE result_table {id INT64, current_score DOUBLE}

        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER PATH {
          SET s.@out_edge += 1
        }

        MATCH (s:Person)
        PER NODE (s) {
          SET @total_nodes += 1
        }

        SET add_constant = add_constant / @total_nodes

        MATCH (s:Person)
        PER NODE (s) {
          SET s.@current_score = 1.0 / @total_nodes
        }

        LOG_INFO("Start Iteration")
        WHILE cur_iter <= max_iter AND @delta > 0.01 THEN {
          SET @delta = 0.0

          MATCH (s:Person)-[e:KNOWS]->(t:Person)
          PER PATH {
            SET t.@next_score += damping * s.@current_score / s.@out_edge
          }

          LOG_INFO("current iter: ", cur_iter)

          MATCH (s:Person)
          PER NODE (s) {
            SET s.@next_score += add_constant
          }

          MATCH (s:Person)
          PER NODE (s) {
            SET @delta += abs(s.@next_score - s.@current_score)
          }

          MATCH (s:Person)
          PER NODE (s) {
            SET s.@current_score = s.@next_score
            SET s.@next_score = 0
          }

          SET cur_iter = cur_iter + 1
        }

        LOG_INFO("Finish Iteration")
        LOG_INFO("Final @delta: " , @delta)

        MATCH (s:Person)
        PER NODE (s) {
          EXPORT s.id, s.@current_score INTO result_table
        }

        FOR i IN result_table
        RETURN @delta AS final_delta, i.id AS id, round(i.current_score, 5) AS rank
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #mutgraph_for_pagerank AS COPY OF simple_graph_for_page_rank
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #mutgraph_for_pagerank CALL pagerank(0.85, 30) RETURN  id, rank
      """
    Then the result should be, in any order:
      | id | rank    |
      | 4  | 0.31818 |
      | 2  | 0.32801 |
      | 3  | 0.31631 |
      | 1  | 0.0375  |
    When executing analytic query:
      """
      SUBMIT USE #simple_graph_for_page_rank_dist_projection CALL pagerank(0.85, 30) RETURN  id, rank
      """
    Then the result should be, in any order:
      | procedure_id | status      |
      | /.+/         | "SUBMITTED" |
    When executing graph analytic query:
      """
      USE #simple_graph_for_page_rank_dist_projection CALL pagerank(0.85, 30) RETURN id, rank
      """
    Then the result should be, in any order:
      | id | rank    |
      | 4  | 0.31818 |
      | 2  | 0.32801 |
      | 3  | 0.31631 |
      | 1  | 0.0375  |
    When executing graph analytic query:
      """
      USE #simple_graph_for_page_rank_dist_projection
      FOR i IN LIST[0.85D, 0.9D]
      CALL pagerank(i, 30)
      RETURN rank, id, i
      """
    Then the result should be, in any order:
      | rank    | id | i    |
      | 0.32801 | 2  | 0.85 |
      | 0.31631 | 3  | 0.85 |
      | 0.31818 | 4  | 0.85 |
      | 0.0375  | 1  | 0.85 |
      | 0.483   | 2  | 0.9  |
      | 0.47617 | 3  | 0.9  |
      | 0.48213 | 4  | 0.9  |
      | 0.0375  | 1  | 0.9  |
    When executing graph analytic query:
      """
      USE #simple_graph_for_page_rank_dist_projection
      FOR i IN LIST[0.85D]
      CALL pagerank(i, 30)
      YIELD rank as rk1, rank as rk2
      RETURN i, rk1, rk2
      """
    Then the result should be, in any order:
      | i    | rk1     | rk2     |
      | 0.85 | 0.32801 | 0.32801 |
      | 0.85 | 0.31631 | 0.31631 |
      | 0.85 | 0.31818 | 0.31818 |
      | 0.85 | 0.0375  | 0.0375  |
    When executing graph analytic query:
      """
      CALL pagerank(0.85, 1) RETURN *
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing query:
      """
      DROP PROCEDURE pagerank
      """
    Then the execution should be successful
    And drop the graph "#mutgraph_for_pagerank"
    And drop the graph "#simple_graph_for_page_rank_projection"
    And drop the graph "#simple_graph_for_page_rank_dist_projection"
    And drop the graph "simple_graph_for_page_rank"
    And drop the graph type "page_rank_simple_graph_type"
    And drop the procedure "pagerank"
    And close the current session

  Scenario: PageRank
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE      max_iter      INT64  = 30
        VALUE      damping       DOUBLE = 0.85
        VALUE      add_constant  DOUBLE = 1.0 - 0.85
        VALUE      total_nodes   SumAgg<INT>    = 0
        VALUE      delta         SumAgg<DOUBLE> = 1.0
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        NODE VALUE next_score    SumAgg<DOUBLE> = 0.0
        NODE VALUE out_edge      SumAgg<INT64>  = 0
        TABLE      result_table  TYPED TABLE {vid INT64, current_score DOUBLE}

        MATCH (s)-[e]->(t)
        PER PATH {
          SET s.@out_edge += 1
        }

        MATCH (s)
        PER NODE (s) {
          SET @total_nodes += 1
        }
        SET add_constant = add_constant / @total_nodes

        MATCH (s)
        PER NODE (s) {
          SET s.@current_score = 1.0 / @total_nodes
        }

        WHILE max_iter > 0 AND @delta > 0.01 THEN {
          SET @delta = 0.0
          MATCH (s)-[e]->(t)
          PER PATH {
            SET t.@next_score += damping * s.@current_score / s.@out_edge
          }

          MATCH (s)
          PER NODE (s) {
            SET s.@next_score += add_constant
          }

          MATCH (s)
          PER NODE (s) {
            SET @delta += abs(s.@next_score - s.@current_score)
          }

          MATCH (s)
          PER NODE (s) {
            SET s.@current_score = s.@next_score
            SET s.@next_score = 0
          }
          SET max_iter = max_iter - 1
        }

        LOG_INFO("Final @delta: " , @delta)

        MATCH (s)
        PER NODE (s) {
          EXPORT s.id, s.@current_score INTO result_table
        }

        FOR i IN result_table
        RETURN i.vid as node_id, round(i.current_score,5) as ranking
        ORDER BY ranking DESC, node_id DESC LIMIT 20
      }
      """
    Then the result should be, in order:
      | node_id | ranking |
      | 1       | 0.08599 |
      | 2       | 0.08574 |
      | 3       | 0.08467 |
      | 4       | 0.01752 |
      | 5       | 0.01751 |
      | 6       | 0.01705 |
      | 1       | 0.01517 |
      | 2       | 0.01513 |
      | 3       | 0.01465 |
      | 2       | 0.01345 |
      | 1       | 0.01217 |
      | 3       | 0.01206 |
      | 1       | 0.01008 |
      | 2       | 0.01005 |
      | 3       | 0.00983 |
      | 1       | 0.00784 |
      | 2       | 0.00782 |
      | 3       | 0.00765 |
      | 1       | 0.00703 |
      | 2       | 0.00699 |

  Scenario: PageRank Plato
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE pagerank_plato(damping DOUBLE, max_iter INT64) RETURNS (id INT64, rank DOUBLE) AS {
          VALUE cur_iter INT64 = 0
          VALUE eps = 0.0001
          VALUE delta SumAgg<DOUBLE> = 1.0
          NODE VALUE current_score SumAgg<DOUBLE> = 0.0
          NODE VALUE next_score SumAgg<DOUBLE> = 0.0
          NODE VALUE out_edge SumAgg<INT64> = 0
          TABLE result_table TYPED TABLE {vid INT64, current_score DOUBLE}

          MATCH (s)-[e]->(t)
          PER PATH {
            SET s.@out_edge += 1
          }

          MATCH (s)
          PER NODE (s) {
            IF s.@out_edge > 0 THEN {
              SET s.@current_score = 1.0 / s.@out_edge
            } ELSE {
              SET s.@current_score = 1.0
            }
          }
          WHILE cur_iter < max_iter THEN {
            SET @delta = 0.0
            MATCH (t)<-[e]-(s)
            PER PATH {
              SET t.@next_score += s.@current_score
            }
            IF cur_iter + 1 = max_iter THEN {
              MATCH (s)
              PER NODE (s) {
                SET s.@next_score = 1.0 - damping + damping * s.@next_score
              }
            } ELSE {
              MATCH (s)
              PER NODE (s) {
                SET s.@next_score = 1.0 - damping + damping * s.@next_score
                IF s.@out_edge > 0 THEN {
                  SET s.@next_score = s.@next_score / s.@out_edge
                  SET @delta += abs(s.@next_score - s.@current_score) * s.@out_edge
                } ELSE {
                  SET @delta += abs(s.@next_score - s.@current_score)
                }
              }
              IF @delta < eps THEN {
                SET cur_iter = max_iter - 2
              }
            }
            MATCH (s)
            PER NODE (s) {
              SET s.@current_score = s.@next_score
              SET s.@next_score = 0
            }
            LOG_INFO("cur_iter: ",cur_iter ," @delta: " , @delta)
            SET cur_iter = cur_iter + 1
          }
          MATCH (s)
          PER NODE (s) {
            EXPORT s.id, s.@current_score INTO result_table
          }

          LOG_INFO("Final @delta: " , @delta)

          FOR r IN result_table
          RETURN r.vid, r.current_score
        }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc
      CALL pagerank_plato(0.85, 30)
      RETURN id, round(rank, 5) as rank ORDER BY rank DESC LIMIT 10
      """
    Then the result should be, in order:
      | id | rank    |
      | 1  | 2.92829 |
      | 2  | 2.92083 |
      | 3  | 2.88277 |
      | 4  | 0.58357 |
      | 5  | 0.58122 |
      | 6  | 0.56923 |
      | 1  | 0.51008 |
      | 2  | 0.50731 |
      | 3  | 0.49321 |
      | 2  | 0.4529  |
    When executing graph analytic query:
      """
      /*+ SET_VAR(memory_limit_bytes = 1048576) */
      USE #analytic_ldbc
      CALL pagerank_plato(0.85, 30)
      RETURN id, round(rank, 5) as rank ORDER BY rank DESC LIMIT 10
      """
    Then an Error should be raised: "Memory usage for Query exceeded hard limit 1048576"
    And drop the procedure "pagerank_plato"
