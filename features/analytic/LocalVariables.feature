# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Local Variables test

  Scenario: Local Variables
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_value SumAgg<INT> = 0
        TABLE t TYPED TABLE {id INT64, score INT64}
        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = 4
          VALUE local_v_1 = 5
          SET local_v = local_v + local_v_1
          SET a.@sum_value += (local_v + a.id)
        }
        PER NODE (a) {
            EXPORT a.id, a.@sum_value INTO t
        }
        FOR r IN t
        RETURN r.id, r.score
      }
      """
    Then the result should be, in any order:
      | r.id | r.score |
      | 3    | 12      |
      | 2    | 11      |
      | 4    | 13      |
      | 1    | 10      |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT64, score INT64}
        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v INT64 = 4
          IF a.id > 1 THEN {
            SET local_v = local_v + a.id
          }
          ELSE {
            SET local_v = local_v - a.id
            LOG_INFO("local_v == ",local_v)
          }
          EXPORT a.id, local_v INTO t
        }
        FOR r IN t
        RETURN r.id, r.score
      }
      """
    Then the result should be, in any order:
      | r.id | r.score |
      | 3    | 7       |
      | 2    | 6       |
      | 4    | 8       |
      | 1    | 3       |
