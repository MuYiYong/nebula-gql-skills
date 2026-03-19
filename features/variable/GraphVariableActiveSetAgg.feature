# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Graph Variable ActiveSet and Aggregation on graphd

  Scenario: Active set and aggregation on graph variable
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_graph_active_set_agg() RETURNS (cnt INT) AS {
        VALUE active_set ACTIVE_SET
        VALUE cnt SumAgg<INT> = 0

        MATCH (s@Person) WHERE s.id < 3
        FINALLY {
          SET active_set = s
        }

        MATCH (v@Person)
        WHERE v IN active_set
        PER NODE (v) {
          SET @cnt += 1
        }
        RETURN @cnt
      }
      """
    Then the execution should be successful
    When executing query:
      """
      GRAPH g = GRAPH{ USE ldbc MATCH (a@Person) RETURN a }
      USE g
      CALL proc_graph_active_set_agg() RETURN cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    And drop the procedure "proc_graph_active_set_agg"
