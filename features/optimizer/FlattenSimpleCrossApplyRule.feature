# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: FlattenSimpleCrossApplyRule

  Scenario: basic
    When executing query:
      """
      USE ldbc
      LET a = 1
      CALL { RETURN a + 1 AS b LIMIT 1 }
      RETURN *
      """
    Then the result should be, in order:
      | a | b |
      | 1 | 2 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN a, VALUE { RETURN a + 1 AS b LIMIT 1 } AS c
      """
    Then the result should be, in order:
      | a | c |
      | 1 | 2 |
