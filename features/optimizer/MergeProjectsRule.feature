# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: MergeProjectsRule

  Scenario: basic
    When executing query:
      """
      LET a = 1
      LET b = 2
      RETURN a + b AS c
      """
    Then the result should be, in any order:
      | c |
      | 3 |

  Scenario: merge with complex expressions
    When executing query:
      """
      LET x = 10
      LET y = 5
      LET z = x * y + 2
      RETURN z * 2 AS result
      """
    Then the result should be, in any order:
      | result |
      | 104    |

  Scenario: merge with multiple references
    When executing query:
      """
      LET a = 5
      LET b = a * 2
      RETURN b + b AS sum, b * b AS square
      """
    Then the result should be, in any order:
      | sum | square |
      | 20  | 100    |

  Scenario: merge deterministic complex expressions with single reference
    When executing query:
      """
      LET complex_expr = (3 * 4 + 2) / 2 - 1
      RETURN complex_expr * 3 AS result
      """
    Then the result should be, in any order:
      | result |
      | 18     |

  Scenario: do not merge deterministic complex expressions with multiple references
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      LET complex_expr = 3 * v.id
      RETURN complex_expr * 3 AS result, complex_expr * 4 AS result2
      """
    Then the result should be, in any order:
      | result | result2 |
      | 18     | 24      |
      | 36     | 48      |
      | 27     | 36      |
      | 9      | 12      |
