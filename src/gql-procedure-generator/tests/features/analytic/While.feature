# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: While test

  Scenario: While
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT64, score INT64}
        NODE VALUE score SumAgg<INT> = 0
        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = a.id
          VALUE fac INT64 = 1
          WHILE local_v > 0 THEN {
            SET fac = fac * local_v
            SET local_v = local_v - 1
          }
          SET a.@score += fac
        }
        PER NODE (a) {
          EXPORT a.id, a.@score INTO t
        }
        FOR r IN t
        RETURN r.id, r.score
      }
      """
    Then the result should be, in any order:
      | r.id | r.score |
      | 3    | 6       |
      | 2    | 2       |
      | 4    | 24      |
      | 1    | 1       |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT64, gender STRING, score INT64}
        NODE VALUE score SumAgg<INT> = 0
        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = 0
          WHILE local_v < 5 THEN {
            SET local_v = local_v + 1
            IF a.gender = "female" THEN {
              BREAK
            }
            ELSEIF local_v = a.id THEN {
              CONTINUE
            }
            SET a.@score += local_v
          }
        }
        PER NODE (a) {
          EXPORT a.id, a.gender, a.@score INTO t
        }
        FOR r IN t
        RETURN r.id,r.gender,r.score
      }
      """
    Then the result should be, in any order:
      | r.id | r.gender | r.score |
      | 3    | "male"   | 12      |
      | 2    | "male"   | 13      |
      | 4    | "female" | 0       |
      | 1    | "male"   | 14      |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT64, gender STRING, score INT64}
        NODE VALUE score SumAgg<INT64> = 0

        MATCH (a@Person{id:1})
        PER NODE (a) {
          VALUE iter = 0
          WHILE iter < 5 THEN {
            VALUE local_v = iter
            LOG_INFO("begin a.id: ",a.id, " iter: ",iter, " local_v:", local_v)
            SET iter = iter + 1
            LOG_INFO("end a.id: ",a.id, " iter: ",iter, " local_v:", local_v)
            WHILE local_v < 5 THEN {
              SET local_v = local_v + 1
              LOG_INFO("end a.id: ",a.id, " iter: ",iter, " local_v:", local_v)
              SET a.@score += local_v
            }
          }
        }
        PER NODE (a) {
          EXPORT a.id, a.gender, a.@score INTO t
        }
        FOR r IN t
        RETURN r.id,r.gender,r.score
      }
      """
    Then the result should be, in any order:
      | r.id | r.gender | r.score |
      | 1    | "male"   | 55      |
