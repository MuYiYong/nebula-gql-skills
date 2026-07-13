# Copyright (c) 2025 vesoft inc. All rights reserved.
@aggregator
Feature: GlobalAgg Chunking RPC pipeline tests

  Scenario: session params accept valid values
    And create a new session with username "root" and password "NebulaGraph01"
    When executing graph query:
      """
      SESSION SET global_agg_chunk_size = 1048576
      """
    Then the execution should be successful
    When executing graph query:
      """
      SESSION SET global_agg_chunk_size = 536870912
      """
    Then the execution should be successful
    And close the current session

  Scenario: SumAgg round-trip via GlobalAgg pipeline
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT> = 0
        MATCH (a@Person)
        PER NODE (a) {
          SET @sum_agg += a.id
        }
        RETURN @sum_agg
      }
      """
    Then the result should be, in any order:
      | @sum_agg |
      | 10       |

  Scenario: SumAgg two-phase read write with global agg dependency
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE read_agg SumAgg<INT> = 0
        VALUE sum_agg  SumAgg<INT> = 0
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

  Scenario: ListAgg round-trip via GlobalAgg pipeline
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE id_list ListAgg<INT>
        MATCH (a@Person)
        PER NODE (a) {
          SET @id_list += a.id
        }
        RETURN length(@id_list) AS list_len
      }
      """
    Then the result should be, in any order:
      | list_len |
      | 4        |

  Scenario: multiple aggregator types via GlobalAgg pipeline
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE cnt   SumAgg<INT> = 0
        VALUE maxid MaxAgg<INT> = 0
        VALUE minid MinAgg<INT> = 0
        MATCH (a@Person)
        PER NODE (a) {
          SET @cnt   += 1
          IF a.id > @maxid THEN { SET @maxid += a.id }
          IF a.id < @minid THEN { SET @minid += a.id }
        }
        RETURN @cnt AS cnt, @maxid AS maxid, @minid AS minid
      }
      """
    Then the result should be, in any order:
      | cnt | maxid | minid |
      | 4   | 4     | 0     |

  Scenario: node-level agg via PullGlobalAgg path
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_sum SumAgg<INT> = 0
        VALUE global_sum  SumAgg<INT> = 0
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

  Scenario: large ListAgg over 1MB triggers chunking at 1MB threshold
    And create a new session with username "root" and password "NebulaGraph01"
    When executing graph query:
      """
      SESSION SET global_agg_chunk_size = 1048576
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE big_list ListAgg<STRING>
        MATCH (a@Person)
        PER NODE (a) {
          VALUE s = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
          VALUE count INT64 = 0
          WHILE count < 550 THEN {
            SET @big_list += s
            SET count = count + 1
          }
        }
        RETURN length(@big_list) AS list_len
      }
      """
    Then the result should be, in any order:
      | list_len |
      | 2200     |
    And close the current session

  Scenario: chunking is transparent and results match non-chunked execution
    And create a new session with username "root" and password "NebulaGraph01"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE big_list ListAgg<STRING>
        MATCH (a@Person)
        PER NODE (a) {
          VALUE s = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
          VALUE count INT64 = 0
          WHILE count < 550 THEN {
            SET @big_list += s
            SET count = count + 1
          }
        }
        RETURN length(@big_list) AS list_len
      }
      """
    Then the result should be, in any order:
      | list_len |
      | 2200     |
    When executing graph query:
      """
      SESSION SET global_agg_chunk_size = 1048576
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE big_list ListAgg<STRING>
        MATCH (a@Person)
        PER NODE (a) {
          VALUE s = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
          VALUE count INT64 = 0
          WHILE count < 550 THEN {
            SET @big_list += s
            SET count = count + 1
          }
        }
        RETURN length(@big_list) AS list_len
      }
      """
    Then the result should be, in any order:
      | list_len |
      | 2200     |
    And close the current session

  @skip
  Scenario: large global agg trigger chunking
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE big_list ListAgg<STRING>
        VALUE dummy    SumAgg<INT> = 0
        MATCH (a@Person)
        PER NODE (a) {
          VALUE s = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
          VALUE count INT64 = 0
          WHILE count < 1100000 THEN {
            SET @big_list += s
            SET count = count + 1
          }
        }
        PER NODE (a) {
          SET @dummy += length(@big_list)
        }
        RETURN @dummy
      }
      """
    Then the result should be, in any order:
      | @dummy   |
      | 17600000 |
