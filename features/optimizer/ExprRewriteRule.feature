# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: ExprRewriteRule

  Scenario: ConstantFoldRule
    When executing query:
      """
      RETURN 1+1*3
      """
    Then the result should be, in any order:
      | 1+1*3 |
      | 4     |

  Scenario: CaseSimplifyRule
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.id,
      CASE WHEN FALSE THEN -1
      WHEN v.id = 1 THEN 0
      ELSE 1 END AS a
      """
    Then the result should be, in any order:
      | v.id | a |
      | 3    | 1 |
      | 2    | 1 |
      | 1    | 0 |
      | 4    | 1 |

  Scenario: DistributiveRule
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN v.id , ((v.id=1) AND (v.gender="male")) OR ((v.id=1) AND (v.gender="male")) AS a
      """
    Then the result should be, in any order:
      | v.id | a     |
      | 3    | false |
      | 4    | false |
      | 2    | false |
      | 1    | true  |

  Scenario: DistributiveRule
    When executing query:
      """
      USE ldbc match (v:Person)
      RETURN v.id,
      (v.id=1 and v.firstName="Ming") or(v.id=1 and v.gender="male") AS a
      """
    Then the result should be, in any order:
      | v.id | a     |
      | 3    | false |
      | 4    | false |
      | 2    | false |
      | 1    | true  |
