# Copyright (c) 2024 vesoft inc. All rights reserved.
@aggregator
Feature: BoolAgg

  Scenario: global AndAgg
    When executing graph analytic query:
      """
      VALUE test_and AndAgg = true
      VALUE test_and_1 AndAgg = true
      VALUE test_and_2 AndAgg = true
      SET @test_and += true
      SET @test_and_1 = false
      SET @test_and_2 += false
      RETURN @test_and, @test_and_1, @test_and_2
      """
    Then the result should be, in any order:
      | @test_and | @test_and_1 | @test_and_2 |
      | true      | false       | false       |

  Scenario: global OrAgg
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test_or OrAgg = false
        VALUE test_or_1 OrAgg = false
        VALUE test_or_2 OrAgg = false
        SET @test_or += false
        SET @test_or_1 = true
        SET @test_or_2 += true
        RETURN @test_or, @test_or_1, @test_or_2
      }
      """
    Then the result should be, in any order:
      | @test_or | @test_or_1 | @test_or_2 |
      | false    | true       | true       |

  Scenario: BoolAgg on node properties
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_and AndAgg = true
        VALUE global_or OrAgg = false
        MATCH (a@Person)
        PER NODE (a) {
          SET @global_and += (a.gender = "male")
          SET @global_or += (a.gender = "male")
        }
        RETURN @global_and, @global_or
      }
      """
    Then the result should be, in any order:
      | @global_and | @global_or |
      | false       | true       |

  Scenario: NODE VALUE BoolAgg
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_and AndAgg = true
        NODE VALUE node_or OrAgg = false
        VALUE agg_or OrAgg = false
        VALUE agg_and AndAgg = true
        MATCH (a@Person)
        PER NODE (a) {
          SET a.@node_and += (a.id > 1)
          SET a.@node_or += (a.id <= 2)
        }
        PER NODE (a) {
          SET @agg_or += a.@node_and
          SET @agg_and += a.@node_or
        }
        RETURN @agg_or, @agg_and
      }
      """
    Then the result should be, in any order:
      | @agg_or | @agg_and |
      | true    | false    |
