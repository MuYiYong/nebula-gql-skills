# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Dry Run PageRank

  Scenario: Dry Run PageRank on a small graph
    And create a new session with username "root" and password "NebulaGraph01"
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      SESSION SET enable_tracing=true
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH TYPE IF NOT EXISTS dry_run_page_rank_simple_graph_type AS {
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
      /*+ SET_VAR(dry_run=true) */
      CREATE GRAPH IF NOT EXISTS dry_run_simple_graph_for_page_rank TYPED dry_run_page_rank_simple_graph_type
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      TABLE persons {id, name} =
      {id:1, name:"Alice"},
      {id:2, name:"Bob"},
      {id:3, name:"Charlie"},
      {id:4, name:"David"}
      USE dry_run_simple_graph_for_page_rank
      FOR r IN persons
      INSERT (@Person{id:r.id, name:r.name})
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      TABLE edges {src, dst} =
      (1,2),
      (2,3),
      (1,4),
      (3,4),
      (4,2)
      USE dry_run_simple_graph_for_page_rank
      FOR r IN edges
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[@KNOWS{}]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_simple_graph_for_page_rank_projection AS COPY OF dry_run_simple_graph_for_page_rank  OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_simple_graph_for_page_rank_projection TYPED dry_run_page_rank_simple_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_simple_graph_for_page_rank_projection IMPORT INTO GRAPH
      {
      GRAPH FROM NEBULA{
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dry_run_simple_graph_for_page_rank&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
      }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE PLUGIN IF NOT EXISTS algo
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CALL algo.pagerank("#dry_run_simple_graph_for_page_rank_projection", 30, 0.85, 0.01)
      YIELD node_id, ranking
      RETURN node_id, round(ranking, 5) AS rank
      ORDER BY rank DESC
      """
    Then the result should be, in order:
      | node_id | rank |
    When executing graph query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_simple_graph_for_page_rank_dist_projection AS COPY OF dry_run_simple_graph_for_page_rank
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_simple_graph_for_page_rank_dist_projection TYPED dry_run_page_rank_simple_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_simple_graph_for_page_rank_dist_projection IMPORT INTO GRAPH
      {
      GRAPH FROM NEBULA{
      PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dry_run_simple_graph_for_page_rank&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
      }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      CREATE OR REPLACE PROCEDURE dry_run_pagerank(damping DOUBLE, max_iter INT) RETURNS (final_delta DOUBLE, id INT64, rank DOUBLE) AS {
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
      /*+ SET_VAR(dry_run=true) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dry_run_mutgraph_for_pagerank AS COPY OF dry_run_simple_graph_for_page_rank
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) SET_VAR(query_concurrency = 4) */
      USE #dry_run_mutgraph_for_pagerank CALL dry_run_pagerank(0.85, 30) RETURN  id, rank
      """
    Then the result should be, in any order:
      | id | rank |
    When executing analytic query:
      """
      SUBMIT
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_simple_graph_for_page_rank_dist_projection CALL dry_run_pagerank(0.85, 30) RETURN  id, rank
      """
    Then the result should be, in any order:
      | procedure_id | status      |
      | /.+/         | "SUBMITTED" |
    When executing graph analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_simple_graph_for_page_rank_dist_projection CALL dry_run_pagerank(0.85, 30) RETURN id, rank
      """
    Then the result should be, in any order:
      | id | rank |
    When executing graph analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_simple_graph_for_page_rank_dist_projection
      FOR i IN LIST[0.85D, 0.9D]
      CALL dry_run_pagerank(i, 30)
      RETURN rank, id, i
      """
    Then the result should be, in any order:
      | rank | id | i |
    When executing graph analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      USE #dry_run_simple_graph_for_page_rank_dist_projection
      FOR i IN LIST[0.85D]
      CALL dry_run_pagerank(i, 30)
      YIELD rank as rk1, rank as rk2
      RETURN i, rk1, rk2
      """
    Then the result should be, in any order:
      | i | rk1 | rk2 |
    When executing graph analytic query:
      """
      /*+ SET_VAR(dry_run=true) */
      CALL dry_run_pagerank(0.85, 1) RETURN *
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing query:
      """
      /*+ SET_VAR(dry_run=true) */
      DROP PROCEDURE dry_run_pagerank
      """
    Then the execution should be successful
    And drop the graph "#dry_run_mutgraph_for_pagerank"
    And drop the graph "#dry_run_simple_graph_for_page_rank_projection"
    And drop the graph "#dry_run_simple_graph_for_page_rank_dist_projection"
    And drop the graph "dry_run_simple_graph_for_page_rank"
    And drop the graph type "dry_run_page_rank_simple_graph_type"
    And drop the procedure "dry_run_pagerank"
    And close the current session
