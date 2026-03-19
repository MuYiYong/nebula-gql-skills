# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: EliminateCrossJoinRuleWithUnitValuesRule

  Scenario: EliminateCrossJoinRuleWithUnitValuesRule
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN a + 1 AS b LIMIT 1 } AS c
      """
    Then the result should be, in order:
      | c |
      | 2 |
