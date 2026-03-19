# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: PrefixScan

  Scenario: Node prefix scan by element_id
    When executing query:
      """
      USE ldbc
      MATCH (v:Person) WHERE element_id(v) = 289316916978253828
      RETURN element_id(v)
      """
    Then the result should be, in any order:
      | element_id(v)      |
      | 289316916978253828 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person WHERE 289316916978253828 = element_id(v))
      RETURN element_id(v)
      """
    Then the result should be, in any order:
      | element_id(v)      |
      | 289316916978253828 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person) WHERE element_id(v) IN [289316916978253828,289166301065117700]
      RETURN element_id(v)
      """
    Then the result should be, in any order:
      | element_id(v)      |
      | 289316916978253828 |
      | 289166301065117700 |
    # Scan by the prefix /_id with consecutive list
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE element_id(v) IN [289316916978253828,289316916978253829]
      RETURN element_id(v)
      """
    Then the result should be, in any order:
      | element_id(v)      |
      | 289316916978253828 |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person) WHERE element_id(v) NOT IN []
      RETURN element_id(v)
      """
    Then the result should be, in any order:
      | element_id(v)      |
      | 289293960378056708 |
      | 289316916978253828 |
      | 289166301065117700 |
      | 289107795020611588 |
    When executing query:
      """
      USE ldbc
      MATCH TRAIL (v:Person where element_id(v) in [289107795020611588])-[e:FOLLOWS]->{1,3}(t:Person where element_id(t) = 289293960378056708)
      RETURN element_id(v), element_id(t)
      """
    Then the result should be, in any order:
      | element_id(v)      | element_id(t)      |
      | 289107795020611588 | 289293960378056708 |
      | 289107795020611588 | 289293960378056708 |
    When executing query:
      """
      use #analytic_ldbc
      match (v) where element_id(v)=123
      return count(v)
      """
    Then the result should be, in order:
      | count(v) |
      | 0        |
    When executing query:
      """
      use #analytic_ldbc
      match (v) where element_id(v)>=0
      return count(v)
      """
    Then the result should be, in order:
      | count(v) |
      | 34       |

  @sf01
  Scenario: Match node with element_id
    # Since the element_id could be diffrent, we use pk to get the element_id, and match node with element_id
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id:318})
      RETURN element_id(v) as node_id
      NEXT
      USE sf01
      MATCH (v1:Person) FILTER WHERE element_id(v1) = node_id
      RETURN v1.id as id
      """
    Then the result should be, in order:
      | id  |
      | 318 |

  Scenario: Edge prefix scan by prefix
    # Scan by the prefix /_src
    When executing query:
      """
      USE ldbc
      MATCH (src:Person WHERE element_id(src)=289293960378056708)-[e]->(dst:Person)
      RETURN count(*) AS c
      """
    Then the result should be, in order:
      | c |
      | 3 |
    # Scan by the prefix /_src/_dst
    When executing query:
      """
      USE ldbc
      MATCH (src:Person)-[e]->(dst:Person)
      WHERE element_id(src)=289293960378056708 AND
            element_id(dst) IN [289316916978253828,289166301065117700]
      RETURN count(*) AS c
      """
    Then the result should be, in order:
      | c |
      | 2 |
    # Scan by the prefix /_src/_dst/_rank
    When executing query:
      """
      USE ldbc
      MATCH (src:Person WHERE element_id(src)=289293960378056708)-[e]->(dst:Person WHERE element_id(dst)=289316916978253828)
      WHERE multiedge_id(e) = 0
      RETURN count(*) AS c
      """
    Then the result should be, in order:
      | c |
      | 1 |
