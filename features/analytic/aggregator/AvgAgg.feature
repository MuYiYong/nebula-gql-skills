# Copyright (c) 2024 vesoft inc. All rights reserved.
@aggregator
Feature: AvgAgg

  Scenario: global AvgAgg
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test_avg AvgAgg<INT>
        VALUE test_avg_0 AvgAgg<INT>
        VALUE test_avg_d AvgAgg<DOUBLE>
        VALUE test_avg_d_0 AvgAgg<DOUBLE>
        SET @test_avg += 1
        SET @test_avg += 2
        SET @test_avg += 3
        SET @test_avg += 9
        SET @test_avg_0 = 1
        SET @test_avg_d = 40.0
        SET @test_avg_d_0 += 20.0
        SET @test_avg_d_0 += 10.0
        RETURN @test_avg, @test_avg_0, @test_avg_d, @test_avg_d_0
      }
      """
    Then the result should be, in any order:
      | @test_avg | @test_avg_0 | @test_avg_d | @test_avg_d_0 |
      | 3.75      | 1.0         | 40.0        | 15.0          |

  Scenario: AvgAgg on node properties
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE avg_id AvgAgg<INT>
        MATCH (a@Person)
        PER NODE (a) {
          SET @avg_id += a.id
        }
        RETURN @avg_id
      }
      """
    Then the result should be, in any order:
      | @avg_id |
      | 2.5     |

  Scenario: NODE VALUE AvgAgg
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_avg AvgAgg<DOUBLE>
        VALUE global_avg AvgAgg<DOUBLE>
        MATCH (a@Person)
        PER NODE (a) {
          SET a.@node_avg += a.id
        }
        PER NODE (a) {
          SET @global_avg += a.@node_avg
        }
        RETURN @global_avg
      }
      """
    Then the result should be, in any order:
      | @global_avg |
      | 2.5         |
