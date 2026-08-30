# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: PushFilterDownRule

  Scenario: PushFilterDownProjectRule
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      LET id=v.id+1, name=v.firstName
      FILTER id>2 AND name<>"Ming"
      RETURN
      name,id
      """
    Then the result should be, in any order:
      | name     | id |
      | "Sophie" | 5  |
      | "Tim"    | 3  |

  Scenario: PushFilterDownProjectRuleWhenNext
    When executing query:
      """
      LET a=4
      RETURN a+1 AS b
      NEXT
      FILTER b > 4
      RETURN b
      """
    Then the result should be, in any order:
      | b |
      | 5 |

  Scenario: PushFilterDownCrossJoinRule
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      LET id=v.id+1, person=v
      FILTER id>2 AND person.firstName<>"Tim"
      RETURN
      person.firstName, id
      """
    Then the result should be, in any order:
      | person.firstName | id |
      | "Ming"           | 4  |
      | "Sophie"         | 5  |

  Scenario: PushFilterDownInnerJoinRule
    When executing query:
      """
      USE ldbc
      MATCH (forum:Forum)-[membership:HAS_MEMBER]->(person:Person)
      FILTER forum.id <> 1 AND forum.id = person.id
      RETURN forum.title , person.firstName
      """
    Then the result should be, in any order:
      | forum.title | person.firstName |
      | "forum3"    | "Ming"           |
      | "forum2"    | "Tim"            |

  Scenario: PushFilterDownLeftOuterJoinRule
    When executing query:
      """
      USE ldbc
      MATCH (c:Comment)-[:REPLY_OF]->(m:Message), (c)-[:HAS_CREATOR]->(p:Person)
      OPTIONAL MATCH (m)-[:HAS_CREATOR]->(a:Person)-[r:KNOWS]-(p)
      LET replyFirstName = p.firstName,messageFirstName=a.firstName
      FILTER true and replyFirstName<> "Tim"
      RETURN replyFirstName,messageFirstName
      """
    Then the result should be, in any order:
      | replyFirstName | messageFirstName |
      | "Kyle"         | "Kyle"           |
      | "Kyle"         | "Kyle"           |
      | "Kyle"         | "Kyle"           |
      | "Kyle"         | "Kyle"           |
      | "Ming"         | "Ming"           |
      | "Ming"         | "Ming"           |
      | "Ming"         | "Ming"           |
      | "Ming"         | "Ming"           |

  Scenario: PushFilterDownAggregateRule
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[e]->(b)
      RETURN v.firstName AS firstName, count(e) AS cnt GROUP BY v
      NEXT
      USE ldbc
      FILTER firstName > "M" AND cnt > 5
      RETURN firstName, cnt
      """
    Then the result should be, in any order:
      | firstName | cnt |
      | "Ming"    | 9   |
      | "Tim"     | 9   |
    # Only expressions that depend on group-by columns can be pushed down.
    When executing query:
      """
      RETURN count(1) AS ri9
      NEXT FILTER false
      RETURN count(*) as c
      """
    Then the result should be, in any order:
      | c |
      | 0 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_filter_down_aggregate=on") */
      use ldbc {
          match (v)
          let id = v.id
          let id1 = v.id * 2
          return count(*) as c, id, id1 group by id, id1
          next
          filter id + id1 + 1 > 0
          return *
      }
      """
    Then the result should be, in any order:
      | c | id | id1 |
      | 1 | 5  | 10  |
      | 1 | 6  | 12  |
      | 8 | 4  | 8   |
      | 8 | 2  | 4   |
      | 8 | 3  | 6   |
      | 8 | 1  | 2   |

  Scenario: PushFilterDownSortRule
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e]->(b)
      RETURN a, e ORDER BY a.id
      NEXT
      USE ldbc
      FILTER a.firstName > "T"
      RETURN count(a) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 9   |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e]->(b)
      RETURN a, e ORDER BY a.id
      NEXT
      USE ldbc
      FILTER a.firstName > "T"
      RETURN count(a) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 9   |

  Scenario: PushFilterDownRecursiveRule
    When executing query:
      """
      USE ldbc
      MATCH (v1)-[e:KNOWS]->{1,2}(v2) WHERE v1.id=1
      RETURN size(e) AS sz
      """
    Then the result should be, in any order:
      | sz |
      | 1  |
      | 2  |

  Scenario: Do not push group variable predicate into var-length edge scan
    When executing query:
      """
      USE ldbc
      MATCH p=(v:Person)-[e:KNOWS]-{0,3}(w)
      WHERE length(e) > 1 and v.id <> 1 and w.id <> 2
      RETURN length(e) AS len, count(*) AS cnt GROUP BY len
      """
    Then the result should be, in any order:
      | len | cnt |
      | 2   | 4   |
      | 3   | 8   |
