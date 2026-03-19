# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: DummyJoinEliminationRule

  Scenario: DummyJoinEliminationRule
    # project
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id:10}) let t = 1 return v, t
      """
    Then the result should be, in order:
      | v | t |
    # join - conflicting types resolved at runtime (returns empty since no vertex is both City and Person)
    When executing query:
      """
      USE ldbc
      MATCH (v:City) MATCH (v:Person) return v
      """
    Then the result should be, in order:
      | v |
    # cross product
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id:10}) MATCH (t:City) return v, t
      """
    Then the result should be, in order:
      | v | t |
    # aggregate
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id:10}) RETURN COUNT(v) as cnt GROUP BY ()
      """
    Then the result should be, in order:
      | cnt |
      | 0   |
    # recursive
    When executing query:
      """
      USE ldbc
      MATCH p = TRAIL (v1)-[e:STUDY_AT]->*(v2:City)
      RETURN COUNT(p) AS total GROUP by()
      """
    Then the result should be, in order:
      | total |
      | 6     |
    # anti join
    When executing query:
      """
      USE ldbc
      MATCH p = (v:Person)-[e:KNOWS]->(t:Person)
      WHERE NOT EXISTS (MATCH (v:Person{id:5}))
      RETURN COUNT(p) as total GROUP BY ()
      """
    Then the result should be, in order:
      | total |
      | 3     |
    When executing query:
      """
      USE ldbc
      MATCH p = (v:Person{id:5}) WHERE NOT EXISTS (match (t))
      RETURN COUNT(p) as total GROUP BY ()
      """
    Then the result should be, in order:
      | total |
      | 0     |
    # optimize mark join
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id:5}) WHERE EXISTS ((v))
      RETURN v
      """
    Then the result should be, in order:
      | v |
