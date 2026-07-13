# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Personalized PageRank

  Scenario: Personalized PageRank
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE pers_pagerank(source_pks LIST<INT>, damping DOUBLE, max_iter INT, eps DOUBLE) RETURNS (node_id INT, score DOUBLE) AS {
        VALUE      start_set     ACTIVE_SET
        VALUE      total_set     ACTIVE_SET
        VALUE      cur_iter      = 0
        VALUE      delta         SumAgg<DOUBLE> = 1.0
        VALUE      topk_score    TopKAgg<20, score DOUBLE DESC, node_id INT DESC>
        VALUE      pk_set        SetAgg<INT>
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        NODE VALUE next_score    SumAgg<DOUBLE> = 0.0
        NODE VALUE out_edge      SumAgg<INT64> = 0
        NODE VALUE is_source     OrAgg = false

        MATCH (s)-[e]->(t)
        PER PATH {
          SET s.@out_edge += 1
        }

        SET @pk_set = source_pks

        MATCH (s@Person)
        WHERE @pk_set.contains_key(s.id)
        FINALLY {
          SET start_set = s
        }

        MATCH (s)
        WHERE s IN start_set
        PER NODE (s) {
          SET s.@current_score = 1.0
          SET s.@is_source = true
        }
        FINALLY {
          SET total_set = s
        }

        WHILE cur_iter < max_iter AND @delta > eps THEN {
          SET @delta = 0
          MATCH (s)-[e]->(t)
          WHERE s IN start_set
          PER PATH {
            SET t.@next_score += s.@current_score / s.@out_edge
          }
          FINALLY {
            SET start_set |= t
          }

          MATCH (s)
          WHERE s IN start_set
          PER NODE (s) {
            IF s.@is_source = true THEN {
              SET s.@next_score = 1.0 - damping + damping * s.@next_score
            } ELSE {
              SET s.@next_score = damping * s.@next_score
            }
            SET @delta += abs(s.@next_score - s.@current_score)
            SET s.@current_score = s.@next_score
            SET s.@next_score = 0
          }
          FINALLY {
            SET total_set |= s
          }
          SET cur_iter = cur_iter + 1
          LOG_INFO("delta == ", @delta)
        }

        MATCH (a)
        WHERE a IN total_set
        PER NODE (a) {
          SET @topk_score += RECORD{score:a.@current_score, node_id:a.id}
        }

        FOR r IN @topk_score
        RETURN r.node_id, round(r.score, 5)
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc
      CALL pers_pagerank([1,2,3,4],0.85, 10, 0.001)
      RETURN *
      """
    Then the result should be, in any order:
      | node_id | score   |
      | 2       | 0.22302 |
      | 1       | 0.20217 |
      | 3       | 0.20036 |
      | 1       | 0.18809 |
      | 2       | 0.1844  |
      | 4       | 0.17107 |
      | 3       | 0.16569 |
      | 1       | 0.0698  |
      | 2       | 0.06847 |
      | 3       | 0.06149 |
      | 4       | 0.05944 |
      | 5       | 0.05834 |
      | 6       | 0.05237 |
      | 1       | 0.04298 |
      | 2       | 0.04215 |
      | 3       | 0.03786 |
      | 1       | 0.03324 |
      | 2       | 0.0326  |
      | 3       | 0.02928 |
      | 1       | 0.0259  |
    And drop the procedure "pers_pagerank"
