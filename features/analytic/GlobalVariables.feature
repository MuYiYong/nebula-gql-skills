# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Global Variables test

  Scenario: Global Variables
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_v     = 1
        VALUE sum_value    SumAgg<INT> = 0
        TABLE result_table TYPED TABLE {score INT}

        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = global_v
          SET @sum_value += global_v
          EXPORT global_v INTO result_table
          LOG_INFO("global_v == ", global_v, " local_v == ",local_v)
        }

        FOR r IN result_table
        RETURN r.score, @sum_value
      }
      """
    Then the result should be, in any order:
      | r.score | @sum_value |
      | 1       | 4          |
      | 1       | 4          |
      | 1       | 4          |
      | 1       | 4          |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_v = 1
        VALUE sum_value SumAgg<INT> = 0

        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = global_v - 1
          IF local_v < global_v THEN  {
            SET @sum_value += global_v
          }
        }
        RETURN @sum_value
      }
      """
    Then the result should be, in any order:
      | @sum_value |
      | 4          |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_v = 1
        VALUE sum_value SumAgg<INT> = 0

        MATCH (a@Person)
        PER NODE (a) {
          VALUE local_v = global_v - 10
          WHILE local_v < global_v THEN  {
            SET @sum_value += global_v
            SET local_v = local_v + 1
          }
        }
        RETURN @sum_value
      }
      """
    Then the result should be, in any order:
      | @sum_value |
      | 40         |
