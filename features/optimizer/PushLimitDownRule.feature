# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: PushLimitDownRule

  Scenario: PushLimitDownProjectRule
    When executing query:
      """
      USE ldbc MATCH (v)
      WHERE v.id=1
      LET vid=v.id
      LIMIT 1
      RETURN vid
      """
    Then the result should be, in any order:
      | vid |
      | 1   |

  Scenario: PushLimitDownUnionAllRule
    When executing query:
      """
      USE ldbc MATCH (v) RETURN v limit 1
      NEXT
      USE ldbc RETURN count(v) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    When executing query:
      """
      USE ldbc
      CALL {
        MATCH (v:City) RETURN v
        UNION ALL
        MATCH (v:Comment) RETURN v
      }
      RETURN v LIMIT 1
      NEXT
      USE ldbc RETURN count(v) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: PushLimitDownJoinRule
    When executing query:
      """
      USE ldbc MATCH (a:Person)
      OPTIONAL
      MATCH (a)-[]->(b) RETURN a, b LIMIT 1
      NEXT
      USE ldbc RETURN COUNT(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
