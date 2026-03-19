# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: BFS

  Scenario: BFS procedure
    When executing graph analytic query:
      """
      /*+ SET_VAR(optimizer_rules = "push_filter_down_join=off") */
      USE #analytic_ldbc {
        TABLE      result       TYPED TABLE {id INT64, distance INT64, visited BOOL}
        VALUE      v_set        ACTIVE_SET
        VALUE      new_active   OrAgg  = true
        NODE VALUE min_distance MinAgg<INT> = 999
        NODE VALUE visited      OrAgg = false

        MATCH (s@Place) WHERE s.id = 1
        FINALLY {
            SET v_set = s
        }

        MATCH (s)
        WHERE s IN v_set
        PER NODE (s) {
          SET s.@visited = true
          SET s.@min_distance = 0
        }

        WHILE @new_active = true THEN {
          SET @new_active = false

          MATCH (v)-[e]-(d)
          WHERE d.@visited = false AND v IN v_set
          PER PATH {
            SET d.@visited += true
            SET d.@min_distance += v.@min_distance + 1
            SET @new_active += true
          }
          FINALLY {
            SET v_set = d
          }
        }

        MATCH (s)
        PER NODE(s) {
          EXPORT s.id, s.@min_distance, s.@visited INTO result
        }

        FOR i IN result
        RETURN i.id AS vid, i.distance AS dist, i.visited AS visited
        ORDER BY dist DESC, vid DESC
      }
      """
    Then the result should be, in order:
      | vid | dist | visited |
      | 4   | 999  | false   |
      | 4   | 999  | false   |
      | 4   | 999  | false   |
      | 4   | 999  | false   |
      | 4   | 999  | false   |
      | 4   | 999  | false   |
      | 6   | 4    | true    |
      | 5   | 4    | true    |
      | 3   | 4    | true    |
      | 2   | 4    | true    |
      | 4   | 3    | true    |
      | 3   | 3    | true    |
      | 3   | 3    | true    |
      | 3   | 3    | true    |
      | 3   | 3    | true    |
      | 3   | 3    | true    |
      | 3   | 3    | true    |
      | 2   | 3    | true    |
      | 2   | 3    | true    |
      | 2   | 3    | true    |
      | 2   | 3    | true    |
      | 2   | 3    | true    |
      | 2   | 3    | true    |
      | 1   | 3    | true    |
      | 3   | 2    | true    |
      | 2   | 2    | true    |
      | 1   | 2    | true    |
      | 1   | 2    | true    |
      | 4   | 1    | true    |
      | 1   | 1    | true    |
      | 1   | 1    | true    |
      | 1   | 1    | true    |
      | 1   | 1    | true    |
      | 1   | 0    | true    |
