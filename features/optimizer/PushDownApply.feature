# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: PushDownApply

  Scenario: CrossJoin
    When executing query:
      """
      USE ldbc
      MATCH (v1:Person where v1.id < 128), (v2:Person where v2.id < 128)
      LIMIT 1
      MATCH (v2 where v2.id < 128), (v1 where v1.id < 128)
      LIMIT 1
      RETURN 1
      """
    Then the result should be, in any order:
      | 1 |
      | 1 |
    When executing query:
      """
      EXPLAIN
      USE ldbc
      OPTIONAL MATCH (v1)-[e1]->(v2)-[e2]->(v3)
      MATCH (v4), (v4)-[e1]->(v5), (v6)-[e2]->(v7)
      RETURN v7
      """
    Then the execution should be successful

  Scenario: DeCorrelatValuesNode
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id:5})-[:KNOWS]->(t:Person)
      OPTIONAL MATCH (t)
      RETURN 0
      """
    Then the result should be, in any order:
      | 0 |

  Scenario: FlatternNestedApplyInTheRightChild
    When executing query:
      """
      USE ldbc
      MATCH (p:Person{id: 1})
      OPTIONAL MATCH (p:Person)
      WHERE EXISTS ((p:Person))
      RETURN p.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |

  Scenario: HandleDedup
    When executing query:
      """
      USE ldbc
      MATCH (v:Person{id: 3}) WHERE VALUE{
        MATCH (v:Person) RETURN DISTINCT v AS v2 NEXT RETURN COUNT(v2) GROUP BY ()
      } = 1
      RETURN v.id AS vid
      """
    Then the result should be, in any order:
      | vid |
      | 3   |

  Scenario: push apply down left join
    When executing query:
      """
      USE ldbc {
        MATCH (p:Person)
        RETURN p
        NEXT
        LET r = VALUE { OPTIONAL MATCH (p)-[:KNOWS]->(t) RETURN count(t) GROUP BY() }
        RETURN p.id AS id, r
      }
      """
    Then the result should be, in any order:
      | id | r |
      | 1  | 1 |
      | 2  | 1 |
      | 3  | 1 |
      | 4  | 0 |

  @sf01
  Scenario: Recursive
    When executing query:
      """
      USE sf01
      MATCH
          (v3:Person{id: 32985348834036})-[e3:KNOWS]->()
      OPTIONAL MATCH
          (v9:Person)-[e7:KNOWS]->{1, 2}(v10:Person)-[e3:KNOWS]->(v11:Person)-[e8:KNOWS]->{1, 1}(v12:Person)
      RETURN
          true AS ret
      LIMIT 1
      """
    Then the result should be, in any order:
      | ret  |
      | true |

  Scenario: Join expr
    When executing query:
      """
      USE ldbc {
          RETURN 1 AS r
          NEXT MATCH (v:Person)-[e]-({id: (r + e.src - 1 )})
          RETURN r, v.id, r + e.src - 1 as c
      }
      """
    Then the result should be, in any order:
      | r | v.id | c |
      | 1 | 4    | 2 |
      | 1 | 3    | 2 |
      | 1 | 2    | 3 |
      | 1 | 1    | 3 |
      | 1 | 2    | 1 |
    When executing query:
      """
      USE ldbc {
      MATCH (v1) return v1
      NEXT MATCH (v:Person)-[e]-({id: (v1.id + e.src - 1 )})
      RETURN DISTINCT v1.id, v.id
      }
      """
    Then the result should be, in any order:
      | v1.id | v.id |
      | 1     | 4    |
      | 2     | 1    |
      | 1     | 3    |
      | 3     | 2    |
      | 2     | 2    |
      | 1     | 2    |
      | 1     | 1    |

  Scenario: Path Edge must be sortable in window function
    When executing query:
      """
      USE ldbc {
      MATCH ()-[e:FOLLOWS]->()
      LET var = VALUE {
          MATCH p2 = ()
          ORDER BY e.src
          RETURN e.dst
          LIMIT 1
      }
      RETURN var
      }
      """
    Then the result should be, in any order:
      | var |
      | 3   |
      | 4   |
      | 1   |
      | 2   |
      | 2   |
    When executing query:
      """
      explain
      USE ldbc {
          MATCH p = ()-[]->()
          LET var = VALUE {
              let r  = 1
              ORDER BY r
              RETURN p
              LIMIT 1
          }
          FINISH
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc {
        LET r = RECORD{id:1}
        LET var = VALUE {
            let a = 1
            ORDER BY r.id
            RETURN a
            LIMIT 1
        }
        FINISH
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc {
        MATCH (v)
        LET var = VALUE {
        MATCH p2 = ()
        ORDER BY v.id
        RETURN v.id
        LIMIT 1
      }
      FINISH
      }
      """
    Then the execution should be successful
