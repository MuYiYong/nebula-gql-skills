# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: SrcPushedDownByHashJoinRule

  Scenario: vesoft-inc/nebula-ng#5019
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:FOLLOWS]-(v2:Person)
      WHERE element_id(v)=289166301065117700 AND element_id(v2)=289293960378056708
      RETURN v.id AS v1id, v2.id AS v2id, element_id(v) AS v1, element_id(v2) AS v2
      """
    Then the result should be, in any order:
      | v1id | v2id | v1                 | v2                 |
      | 3    | 2    | 289166301065117700 | 289293960378056708 |
      | 3    | 2    | 289166301065117700 | 289293960378056708 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:FOLLOWS]-(v2:Person)
      WHERE element_id(v2)=289293960378056708
      RETURN v2.id AS id, element_id(v2) AS v2
      """
    Then the result should be, in any order:
      | id | v2                 |
      | 2  | 289293960378056708 |
      | 2  | 289293960378056708 |
      | 2  | 289293960378056708 |
      | 2  | 289293960378056708 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:FOLLOWS]-(v2:Person{id: 2})
      RETURN v2.id AS v2
      """
    Then the result should be, in any order:
      | v2 |
      | 2  |
      | 2  |
      | 2  |
      | 2  |

  Scenario: DF precedence over indexes
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS df_vs_index_type AS {
        NODE Person (LABELS Person {id INT PRIMARY KEY, name STRING}),
        EDGE FOLLOWS (Person)-[LABEL FOLLOWS {score INT}]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS df_vs_index df_vs_index_type
      """
    Then the execution should be successful
    And graph "df_vs_index" should be ready to use
    # Create secondary indexes on node and edge
    When executing query:
      """
      USE df_vs_index CREATE INDEX IF NOT EXISTS idx_person_name ON NODE Person(name)
      """
    Then the execution should be successful
    And index "idx_person_name" of "df_vs_index" should be ready to use
    When executing query:
      """
      USE df_vs_index CREATE INDEX IF NOT EXISTS idx_follows_score ON EDGE FOLLOWS(score)
      """
    Then the execution should be successful
    When executing query:
      """
      USE df_vs_index
      INSERT (p1@Person{id:1,name:"u1"}),(p2@Person{id:2,name:"u2"}),(p3@Person{id:3,name:"u3"}),(p4@Person{id:4,name:"u4"}),
      (p1)-[:FOLLOWS{score:5}]->(p2),
      (p3)-[:FOLLOWS{score:5}]->(p2),
      (p4)-[:FOLLOWS{score:7}]->(p3)
      """
    Then the execution should be successful
    # 1) DF vs PK index on node
    When executing query:
      """
      USE df_vs_index
      MATCH (s:Person)-[:FOLLOWS]->(t:Person{id:2})
      RETURN s.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 1  |
      | 3  |
    # 2) DF vs node secondary index
    When executing query:
      """
      USE df_vs_index
      MATCH (s:Person)-[:FOLLOWS]->(t:Person{name:"u2"})
      RETURN t.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
      | 2  |
    # Prefer node index via hint: skip DF rewrite preference
    When executing query:
      """
      USE df_vs_index
      MATCH (s:Person)-[:FOLLOWS]->(t:Person{name:"u2"} /*+ INDEX(idx_person_name) */)
      RETURN t.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
      | 2  |
    # Ignore node index via hint: DF should still be applicable
    When executing query:
      """
      USE df_vs_index
      MATCH (s:Person)-[:FOLLOWS]->(t:Person{name:"u2"} /*+ IGNORE_INDEX(idx_person_name) */)
      RETURN t.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
      | 2  |
    # 3) DF vs edge secondary index
    When executing query:
      """
      USE df_vs_index
      MATCH (s:Person WHERE s.id IN [1,3])-[e:FOLLOWS{score:5}]->(t:Person)
      RETURN t.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
      | 2  |
    # Prefer edge index via hint: skip DF rewrite on edge
    When executing query:
      """
      USE df_vs_index
      MATCH (s:Person WHERE s.id IN [1,3])-[e:FOLLOWS{score:5} /*+ INDEX(idx_follows_score) */]->(t:Person)
      RETURN t.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
      | 2  |
    # Ignore edge index via hint: DF should still be applicable
    When executing query:
      """
      USE df_vs_index
      MATCH (s:Person WHERE s.id IN [1,3])-[e:FOLLOWS{score:5} /*+ IGNORE_INDEX(idx_follows_score) */]->(t:Person)
      RETURN t.id AS id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
      | 2  |
    And drop the index "idx_person_name" of "df_vs_index"
    And drop the index "idx_follows_score" of "df_vs_index"
    And drop the graph "df_vs_index"
    And drop the graph type "df_vs_index_type"
