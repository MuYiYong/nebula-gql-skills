# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: EliminateUselessNodeEdgeJoinRule

  Scenario: Remove useless node-edge join
    # Both p1 and p2 are eliminated
    When executing query:
      """
      USE ldbc
      MATCH (p1:Person)-[e:KNOWS]->(p2:Person)
      RETURN e.creationDate
      """
    Then the result should be, in order:
      | e.creationDate                        |
      | DATETIME '2021-01-01T10:00:40.213000' |
      | DATETIME '2021-01-01T10:00:40.213000' |
      | DATETIME '2021-01-01T10:00:40.213000' |
    # p2 is eliminated, p1 kept due to pk scan
    When executing query:
      """
      USE ldbc
      MATCH (p1:Person{id:1})-[e:KNOWS]->(p2:Person)
      RETURN e.creationDate
      """
    Then the result should be, in order:
      | e.creationDate                        |
      | DATETIME '2021-01-01T10:00:40.213000' |
    # Both v and v2 are eliminated
    # v2 is eliminated because only its _id is used in return
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[:KNOWS]->(v2:Person)
      RETURN element_id(v2) AS vid
      """
    Then the result should be, in any order:
      | vid                |
      | 289293960378056708 |
      | 289166301065117700 |
      | 289107795020611588 |
    # friend, post and tag are eliminated (tag only needs _id for DISTINCT)
    # person remains due to pk scan
    When executing query:
      """
      USE ldbc
      MATCH (person:Person{id: 2})<-[:KNOWS]->(friend:Person)<-[:HAS_CREATOR]-(post:Post)-[:HAS_TAG]->(tag:Tag)
      RETURN DISTINCT tag
      NEXT USE ldbc RETURN COUNT(*) AS total GROUP BY ()
      """
    Then the result should be, in order:
      | total |
      | 1     |
    # friend is eliminated (unused in COUNT(*)), person kept for pk scan
    When executing query:
      """
      USE ldbc MATCH (person:Person{id: 1})-[:KNOWS]->(friend:Person) RETURN friend
      NEXT
      USE ldbc RETURN COUNT(*) AS total
      """
    Then the result should be, in any order:
      | total |
      | 1     |
    # friend is eliminated (only _id is used in DISTINCT), person kept for pk scan
    When executing query:
      """
      USE ldbc MATCH (person:Person{id: 1})-[:KNOWS]->(friend:Person) RETURN DISTINCT friend
      NEXT
      USE ldbc RETURN COUNT(*) AS total
      """
    Then the result should be, in any order:
      | total |
      | 1     |
    # Both v and v2 are eliminated
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)-[e:KNOWS]->(v2:Person)
      ORDER BY e.creationDate LIMIT 3
      RETURN element_id(v2) AS vid
      """
    Then the result should be, in any order:
      | vid                |
      | 289107795020611588 |
      | 289166301065117700 |
      | 289293960378056708 |
    # Both m and p are eliminated because only _id is used.
    # n is kept for pk scan
    When executing query:
      """
      use ldbc match (n:Person)-[:KNOWS]->(m) where n.id in [1,3] return distinct(m) as t
      next use ldbc match(t)-[:KNOWS]->(p) return count(p)
      """
    Then the result should be, in any order:
      | count(p) |
      | 2        |

  # FIX https://github.com/vesoft-inc/nebula-ng/issues/7994
  Scenario: Remove useless node-edge join
    When executing query:
      """
      USE ldbc
      OPTIONAL MATCH (v1:Person)<-[e1:KNOWS]-(v2:Person)
      MATCH (v2)
      RETURN v2
      """
    Then the execution should be successful

  # FIX https://github.com/vesoft-inc/nebula-ng/issues/8971
  Scenario: disable rewrite if edge not exist
    # Fix if no edge `e` existed, `element_id(v)` could be incorrectly optimized away.
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS eunj_test_type as {
        NODE Node01 (LABEL Node01 {id INT64 PRIMARY KEY, name STRING}),
        NODE Node02 (LABEL Node02 {id INT64 PRIMARY KEY, nums LIST<INT64> DEFAULT [0, 1]}),
        Edge Edge0101 (Node01)-[:Edge0101{nums LIST<INT64>}]->(Node01),
        Edge Edge0102 (Node01)-[:Edge0102{nums LIST<INT64>}]->(Node02)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS eunj_test TYPED eunj_test_type
      """
    Then the execution should be successful
    And graph "eunj_test" should be ready to use
    When executing query:
      """
      USE eunj_test
      INSERT
          (@Node01{id: 11, name: "114"}),
          (@Node01{id: 12, name: "job"}),
          (@Node01{id: 13, name: "zhansan"})
      """
    When executing query:
      """
      TABLE t {src_id, dst_id, edge_nums, dst_nums} =
          (11, 11, [1, 2, 3, 4], [1]),
          (12, 23, [4, 3, 2, 1], [2]),
          (13, 14, [5, 6, 4, 7], [3])

      USE eunj_test
      FOR re in t
      MATCH (n@Node01) where n.id = re.src_id
      INSERT (n)-[@Edge0102{nums:re.edge_nums}]->(@Node02{id:re.dst_id, nums:re.dst_nums})
      """
    # For statment aftet match, and return a element_id
    When executing query:
      """
      USE eunj_test {
      MATCH ()-[e:Edge0102]->(v:Node02)
        FOR u0 IN e.nums
          RETURN element_id(v) as vid
      }
      """
    Then the result should be, in any order:
      | vid                |
      | 288744204564168705 |
      | 288744204564168705 |
      | 288744204564168705 |
      | 288744204564168705 |
      | 288582035189006337 |
      | 288582035189006337 |
      | 288582035189006337 |
      | 288582035189006337 |
      | 288606709776121858 |
      | 288606709776121858 |
      | 288606709776121858 |
      | 288606709776121858 |
    When executing query:
      """
      USE eunj_test {
      MATCH ()-[e:Edge0102]->(v:Node02)
        FOR u0 IN e.nums
          RETURN element_id(v), e
      }
      """
    Then the result should be, in any order:
      | element_id(v)      | e                      |
      | 288744204564168705 | [{nums:List[4,3,2,1]}] |
      | 288744204564168705 | [{nums:List[4,3,2,1]}] |
      | 288744204564168705 | [{nums:List[4,3,2,1]}] |
      | 288744204564168705 | [{nums:List[4,3,2,1]}] |
      | 288606709776121858 | [{nums:List[1,2,3,4]}] |
      | 288606709776121858 | [{nums:List[1,2,3,4]}] |
      | 288606709776121858 | [{nums:List[1,2,3,4]}] |
      | 288606709776121858 | [{nums:List[1,2,3,4]}] |
      | 288582035189006337 | [{nums:List[5,6,4,7]}] |
      | 288582035189006337 | [{nums:List[5,6,4,7]}] |
      | 288582035189006337 | [{nums:List[5,6,4,7]}] |
      | 288582035189006337 | [{nums:List[5,6,4,7]}] |
    # Destroy graph
    And drop the graph "eunj_test"
    And drop the graph type "eunj_test_type"

  # fix https://github.com/vesoft-inc/nebula-ng/issues/9133
  Scenario: fix eliminate useless node-edge join which forgets the filter in GetNodes
    When executing query:
      """
      use ldbc match (v:Person where element_id(v) = 777)-[e:KNOWS]->(v2:Person where element_id(v2) = 999) return count(e) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    When executing query:
      """
      USE ldbc match (v where false)-[e:KNOWS]->(v2) return count(e) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |

  Scenario: use set to check existence for large amount of types
    When executing query:
      """
      use ldbc match (a)-[e]->(b) return count(*) as cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 74  |
