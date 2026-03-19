# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: ColumnPrunerRule

  Scenario: All columns are pruned
    When executing query:
      """
      LET a = 1, b = 2
      RETURN COUNT(*) AS c GROUP BY ()
      """
    Then the result should be, in any order:
      | c |
      | 1 |
    When executing query:
      """
      USE ldbc MATCH p = (v:Person) return 1 AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
      | 1 |
      | 1 |
      | 1 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      MATCH (v2:Person)
      RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 16  |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person) RETURN COUNT(*) AS cnt GROUP BY ()
      UNION ALL
      USE ldbc
      MATCH (v:Person) RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 4   |
      | 4   |
    When executing query:
      """
      USE ldbc MATCH (v:Person{id:5}) RETURN COUNT(*) AS total GROUP BY()
      NEXT
      USE ldbc
      RETURN 123 AS a
      """
    Then the result should be, in any order:
      | a   |
      | 123 |
    When executing query:
      """
      USE ldbc MATCH (v:Person{id:10}) RETURN COUNT(*) AS total GROUP BY()
      NEXT
      USE ldbc
      RETURN COUNT(*) AS cnt group by()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      FOR i IN LIST[1,2,2,3] RETURN i
      NEXT
      RETURN COUNT(i) AS cnt group by()
      """
    Then the result should be, in any order:
      | cnt |
      | 4   |
    When executing query:
      """
      FOR i IN LIST[1,2,2,3] RETURN DISTINCT i
      NEXT
      RETURN COUNT(i) AS cnt group by()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query:
      """
      FOR i IN LIST[1,2,2,3] RETURN i
      NEXT
      RETURN COUNT(*) AS cnt group by()
      """
    Then the result should be, in any order:
      | cnt |
      | 4   |
    When executing query:
      """
      FOR i IN LIST[1,2,2,3] RETURN DISTINCT i
      NEXT
      RETURN COUNT(*) AS cnt group by()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
