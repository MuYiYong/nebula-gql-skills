# Copyright (c) 2024 vesoft inc. All rights reserved.
@aggregator
Feature: MinMaxAgg

  Scenario: global MinMaxAgg
    When executing graph analytic query:
      """
      VALUE test_max MaxAgg<INT> = 0
      VALUE test_max_1 MaxAgg<INT> = 0
      VALUE test_min MinAgg<INT> = 99999
      VALUE test_min_1 MinAgg<INT> = 99999
      SET @test_max = 1
      SET @test_max_1 = 1
      SET @test_max_1 += 2
      SET @test_min = 1
      SET @test_min_1 = 1
      SET @test_min_1 += -99999
      RETURN @test_max,@test_max_1,@test_min,@test_min_1
      """
    Then the result should be, in any order:
      | @test_max | @test_max_1 | @test_min | @test_min_1 |
      | 1         | 2           | 1         | -99999      |

  Scenario: Uninitialized Global Agg
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE max_agg MaxAgg<INT> = 3
        TABLE t {id int}
        MATCH (v@Person{id:1})
        PER NODE(v) {
          EXPORT @max_agg INTO t
        }
        FOR r IN t
        RETURN r.id
      }
      """
    Then the result should be, in any order:
      | r.id |
      | 3    |

  Scenario: NULL input
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE max_agg MaxAgg<INT> = 3
        VALUE min_agg MaxAgg<INT> = 3
        SET @max_agg += NULL
        SET @max_agg += NULL
        SET @max_agg = NULL
        SET @max_agg = NULL
        RETURN @max_agg, @min_agg
      }
      """
    Then the result should be, in any order:
      | @max_agg | @min_agg |
      | 3        | 3        |

  Scenario: MinAgg and MaxAgg on STRING
    When executing graph analytic query:
      """
      VALUE test_max_str MaxAgg<STRING> = ""
      VALUE test_min_str MinAgg<STRING> = "zzz"
      SET @test_max_str = "banana"
      SET @test_max_str += "apple"
      SET @test_max_str += "cherry"
      SET @test_min_str = "banana"
      SET @test_min_str += "apple"
      SET @test_min_str += "cherry"
      RETURN @test_max_str, @test_min_str
      """
    Then the result should be, in any order:
      | @test_max_str | @test_min_str |
      | "cherry"      | "apple"       |

  Scenario: MinAgg<STRING> and MaxAgg<STRING> on node properties
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE max_first MaxAgg<STRING> = ""
        VALUE min_first MinAgg<STRING> = "~~~~"
        MATCH (a@Person)
        PER NODE (a) {
          SET @max_first += a.firstName
          SET @min_first += a.firstName
        }
        RETURN @max_first, @min_first
      }
      """
    Then the result should be, in any order:
      | @max_first | @min_first |
      | "Tim"      | "Kyle"     |

  Scenario: MinAgg<STRING> and MaxAgg<STRING> aggregating per-node results
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_max MaxAgg<STRING> = ""
        NODE VALUE node_min MinAgg<STRING> = "~~~~"
        VALUE global_max MaxAgg<STRING> = ""
        VALUE global_min MinAgg<STRING> = "~~~~"
        MATCH (a@Person)
        PER NODE (a) {
          SET a.@node_max += a.firstName
          SET a.@node_max += a.lastName
          SET a.@node_min += a.firstName
          SET a.@node_min += a.lastName
        }
        PER NODE (a) {
          SET @global_max += a.@node_max
          SET @global_min += a.@node_min
        }
        RETURN @global_max, @global_min
      }
      """
    Then the result should be, in any order:
      | @global_max | @global_min |
      | "cao"       | "Duncan"    |
