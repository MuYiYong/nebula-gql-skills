# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: RemoveNoopProjectRule

  Scenario: Variable with the same name
    When executing query:
      """
      USE ldbc {
          VALUE v1 INT = 1
      LET v2 = VALUE {
          LET v3 = v1
          MATCH ()-[e]->()
          RETURN DISTINCT e AS r
          NEXT RETURN v1 AS r
          ORDER BY r
          LIMIT 1
          }
          RETURN v2 as r
      }
      """
    Then the result should be, in any order:
      | r |
      | 1 |
