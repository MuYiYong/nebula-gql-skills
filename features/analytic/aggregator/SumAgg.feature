# Copyright (c) 2024 vesoft inc. All rights reserved.
@aggregator
Feature: SumAgg

  Scenario: global SumAgg
    When executing graph analytic query:
      """
      VALUE test_sum SumAgg<INT> = 2
      SET @test_sum = 2
      SET @test_sum += 1
      SET @test_sum += 4
      RETURN @test_sum
      """
    Then the result should be, in any order:
      | @test_sum |
      | 7         |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE read_agg SumAgg<INT> = 0
        VALUE sum_agg SumAgg<INT> = 0
        MATCH (a@Person)
        PER NODE (a) {
          SET @read_agg += a.id
        }
        PER NODE (a) {
          SET @sum_agg += @read_agg
        }
        PER NODE (a) {
          SET @sum_agg += @sum_agg
        }
        RETURN @read_agg, @sum_agg
      }
      """
    Then the result should be, in any order:
      | @read_agg | @sum_agg |
      | 10        | 200      |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_sum SumAgg<INT> = 0
        VALUE global_sum SumAgg<INT> = 0
        MATCH (a@Person)
        PER NODE (a) {
          SET a.@node_sum += a.id
          SET a.@node_sum += a.id
        }
        PER NODE (a) {
          SET @global_sum += a.@node_sum
        }
        RETURN @global_sum
      }
      """
    Then the result should be, in any order:
      | @global_sum |
      | 20          |

  Scenario: SumAgg<STRING>
    When executing graph analytic query:
      """
      VALUE test_str SumAgg<STRING> = ""
      SET @test_str = "hello"
      SET @test_str += " "
      SET @test_str += "world"
      RETURN @test_str
      """
    Then the result should be, in any order:
      | @test_str     |
      | "hello world" |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE str_concat SumAgg<STRING> = ""
        MATCH (a@Person)
        PER NODE (a) {
          SET @str_concat += "x"
        }
        RETURN @str_concat
      }
      """
    Then the result should be, in any order:
      | @str_concat |
      | "xxxx"      |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_str SumAgg<STRING> = ""
        VALUE global_str SumAgg<STRING> = ""
        MATCH (a@Person)
        PER NODE (a) {
          SET a.@node_str += "x"
          SET a.@node_str += "x"
        }
        PER NODE (a) {
          SET @global_str += a.@node_str
        }
        RETURN @global_str
      }
      """
    Then the result should be, in any order:
      | @global_str |
      | "xxxxxxxx"  |
