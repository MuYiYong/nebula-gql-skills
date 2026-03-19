# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Error messages carry source location

  Scenario: Diagnostics show source locations
    When executing query:
      """
      IF true THEN {
        RETURN 1 AS a
      } ELSE {
        RETURN 2 AS b
      }
      """
    Then an Error should be raised: "[NS217]: All branches of the if statement must have the same column names and compatible types, at ["
    When executing query:
      """
      WHILE true THEN {
        RETURN 1 AS a
      }
      """
    Then an Error should be raised: "[NS247]: Procedure statements in the while body must not end with RETURN, at ["
    When executing query:
      """
      RETURN x
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `x` not defined, at ["
    When executing query:
      """
      SET x = 1
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `x` not defined, at ["
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s)
        FINALLY {
          SET not_defined_active_set = s
        }
        RETURN 1
      }
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `not_defined_active_set` not defined, at ["
    When executing query:
      """
      USE ldbc MATCH (v:City)-[e:IS_PART_OF]-() RETURN v,e
      UNION
      USE ldbc MATCH (v:Comment) RETURN v
      """
    Then an Error should be raised: "[NS004]: Semantic error, column size `1` vs. `2` mismatched for the linear query of composite query statement: `USE ldbc MATCH (v:Comment) RETURN v`, at ["
    When executing query:
      """
      USE ldbc MATCH (v:City)-[e:IS_PART_OF]-() RETURN e
      UNION
      USE ldbc MATCH (v:Comment) RETURN v
      """
    Then an Error should be raised: "[NS007]: Semantic error, column name `e` vs. `v` mismatched for the linear query of composite query statement: `USE ldbc MATCH (v:Comment) RETURN v`, at ["
    When executing query:
      """
      USE ldbc RETURN 1 AS a, 2 AS b
      UNION
      USE ldbc FINISH
      """
    Then an Error should be raised: "[NS004]: Semantic error, column size `0` vs. `2` mismatched for the linear query of composite query statement: `USE ldbc FINISH`, at ["
    When executing query:
      """
      RETURN 1 AS a UNION  RETURN "1" AS a
      """
    Then an Error should be raised: "[NS010]: Semantic error, column `a` has incompatible types: INT32, STRING, at ["
    When executing query:
      """
      USE ldbc
      LET a = 1
      RETURN VALUE { RETURN 3 AS a NEXT RETURN a LIMIT 1 } AS b
      """
    Then an Error should be raised: "[NS216]: The returned column `a` conflicts with parent scope variables. Please use a unique alias to distinguish them, at ["
    When executing query:
      """
      RETURN 1 AS a
      RETURN 2 AS b
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead, at ["
    When executing query:
      """
      CALL version()
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement, at ["
    When executing query:
      """
      RETURN 2<>1ascompare1
      """
    Then an Error should be raised: "[42001]: syntax error near `ascompare1`, at ["
    When executing query:
      """
      NEXT
      RETURN 1
      """
    Then an Error should be raised: "[42001]: syntax error near `NEXT`, at ["
    When executing query:
      """
      UNION
      RETURN 1
      """
    Then an Error should be raised: "[42001]: syntax error near `UNION`, at ["
    When executing query:
      """
      USE ldbc
      USE ldbc
      RETURN 1
      """
    Then an Error should be raised: "[42001]: syntax error near `USE`, at ["
