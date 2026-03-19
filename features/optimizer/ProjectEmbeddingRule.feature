# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: ProjectEmbeddingRule

  Scenario: basic
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e:KNOWS]->(b) WHERE a.id <> 1
      RETURN a.id, b.id
      """
    Then the result should be, in any order:
      | a.id | b.id |
      | 3    | 3    |
      | 2    | 2    |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)-[e:KNOWS]->(b)
      RETURN a.id
      """
    Then the result should be, in any order:
      | a.id |
      | 2    |
      | 3    |
      | 1    |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person{id:1})-[e:FOLLOWS]->(b)
      RETURN e
      """
    Then the result should be, in any order:
      | e               |
      | [{dst:2,src:1}] |
    When executing query:
      """
      USE ldbc
      MATCH (a{id:1})-[e:KNOWS|FOLLOWS]->(b{id:2})
      RETURN e
      """
    Then the result should be, in any order:
      | e               |
      | [{dst:2,src:1}] |
    When executing query:
      """
      USE ldbc
      MATCH (a{id:1})-[e:KNOWS]->{1,3}(b)
      RETURN count(b)
      """
    Then the result should be, in any order:
      | count(b) |
      | 3        |
    When executing query:
      """
      USE ldbc
      MATCH (a)-[:IS_SUBCLASS_OF]->(b)
      RETURN b
      """
    Then the result should be, in any order:
      | b                                                     |
      | ({id:1,name:"tagClass1",url:"https://tagClass1.com"}) |
      | ({id:3,name:"tagClass3",url:"https://tagClass3.com"}) |
      | ({id:2,name:"tagClass2",url:"https://tagClass2.com"}) |
    When executing query:
      """
      USE ldbc
      MATCH (a:Person)
      OPTIONAL MATCH (a)-[e:FOLLOWS]->(b)
      RETURN a.id, b.id
      """
    Then the result should be, in any order:
      | a.id | b.id |
      | 4    | null |
      | 2    | 4    |
      | 2    | 3    |
      | 1    | 2    |
      | 3    | 2    |
      | 3    | 1    |

  Scenario: shuffle order
    When executing query:
      """
      USE ldbc
      MATCH (a)-[:HAS_TYPE]->(b)
      RETURN a, b
      """
    Then the result should be, in any order:
      | a                                           | b                                                     |
      | ({id:1,name:"tag1",url:"https://tag1.com"}) | ({id:1,name:"tagClass1",url:"https://tagClass1.com"}) |
      | ({id:2,name:"tag2",url:"https://tag2.com"}) | ({id:2,name:"tagClass2",url:"https://tagClass2.com"}) |
      | ({id:3,name:"tag3",url:"https://tag3.com"}) | ({id:3,name:"tagClass3",url:"https://tagClass3.com"}) |
    When executing query:
      """
      USE ldbc
      MATCH (a)-[:HAS_TYPE]->(b)
      RETURN a as b, b as a
      """
    Then the result should be, in any order:
      | b                                           | a                                                     |
      | ({id:1,name:"tag1",url:"https://tag1.com"}) | ({id:1,name:"tagClass1",url:"https://tagClass1.com"}) |
      | ({id:2,name:"tag2",url:"https://tag2.com"}) | ({id:2,name:"tagClass2",url:"https://tagClass2.com"}) |
      | ({id:3,name:"tag3",url:"https://tag3.com"}) | ({id:3,name:"tagClass3",url:"https://tagClass3.com"}) |

  Scenario: MarkJoin project
    When executing raw query:
      """
      USE ldbc {
      LET ua0 = 1
      LET ar4 = EXISTS {
      RETURN ua0 AS ri3
      }
      RETURN 1 AS c
      }
      """
    Then the result should be, in any order:
      | c |
      | 1 |
