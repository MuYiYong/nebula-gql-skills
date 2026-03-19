# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: RandomWalk

  Scenario: RandomWalk procedure
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE random_walk(max_iter INT) RETURNS id_path LIST<INT> AS {
        VALUE      step         = 1
        NODE VALUE recv_paths   ListAgg<List<INT>>
        NODE VALUE send_paths   ListAgg<List<INT>>
        TABLE      result_table TYPED TABLE {id INT, paths LIST<LIST<INT>>}

        MATCH (s:Person)
        PER NODE (s) {
          SET s.@send_paths += LIST[s.id]
        }

        WHILE step <= max_iter THEN {
          LOG_INFO("Step: ", step)
          MATCH (s:Person)-[e:FOLLOWS SAMPLE RIGHT 10]->(t:Person)
          PER PATH {
            SET t.@recv_paths += s.@send_paths
          }

          MATCH (s:Person)
          PER NODE (s) {
            VALUE p = s.@recv_paths
            VALUE i = 0
            VALUE len = Length(p)
            SET s.@send_paths.clear()
            WHILE i < len THEN {
              SET s.@send_paths += p[i] || LIST[s.id]
              SET i = i + 1
            }
            SET s.@recv_paths.clear()
          }
          SET step = step + 1
        }

        MATCH (s:Person)
        PER NODE (s) {
          EXPORT s.id, s.@send_paths INTO result_table
        }

        FOR r IN result_table
        FOR p IN r.paths
        RETURN p
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #analytic_ldbc
      CALL random_walk(3)
      RETURN *
      """
    Then the result should be, in any order:
      | id_path        |
      | LIST [3,1,2,4] |
      | LIST [2,3,2,4] |
      | LIST [2,3,1,2] |
      | LIST [1,2,3,2] |
      | LIST [3,2,3,2] |
      | LIST [1,2,3,1] |
      | LIST [3,2,3,1] |
      | LIST [3,1,2,3] |
      | LIST [2,3,2,3] |
    And drop the procedure "random_walk"
