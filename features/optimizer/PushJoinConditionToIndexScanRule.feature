# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: PushJoinConditionToIndexScanRule

  Scenario: basic
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS primary_key_push_down_type AS {
        NODE node_type_1 (LABEL label_1 {pk_id INT, name STRING, PRIMARY KEY (pk_id)}),
        NODE node_type_2 (LABEL label_2 {id INT, pk_name STRING, PRIMARY KEY (pk_name)}),
        NODE node_type_3 (LABEL label_3 {pk_id INT, pk_name STRING, PRIMARY KEY (pk_id,pk_name)}),
        NODE node_type_4 (LABEL label_4 {pk_id_1 INT, pk_id_2 INT, PRIMARY KEY (pk_id_1,pk_id_2)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS primary_key_push_down primary_key_push_down_type
      """
    Then the execution should be successful
    And graph "primary_key_push_down" should be ready to use
    When executing query:
      """
      USE primary_key_push_down
      INSERT
      (@node_type_1{pk_id:1,name: "name_1"}),
      (@node_type_1{pk_id:2,name: "name_2"}),
      (@node_type_2{id:3,pk_name: "name_3"}),
      (@node_type_2{id:4,pk_name: "name_4"}),
      (@node_type_3{pk_id:5,pk_name: "name_5"}),
      (@node_type_3{pk_id:6,pk_name: "name_6"}),
      (@node_type_4{pk_id_1:7,pk_id_2: 70}),
      (@node_type_4{pk_id_1:8,pk_id_2: 80})
      """
    Then the execution should be successful
    # Expected index range: [/pk_id]: [/"1"/], [/"2"/], tight=true
    When executing query:
      """
      TABLE t {id} =
      (1),(2)
      USE primary_key_push_down
      FOR r IN t
      MATCH (a@node_type_1) WHERE a.pk_id = r.id
      RETURN a.pk_id
      """
    Then the result should be, in any order:
      | a.pk_id |
      | 1       |
      | 2       |
    # Expected index range: [/pk_name]: [/"name_3" - /"name_3"], [/"name_4" - /"name_4"], tight=true
    When executing query:
      """
      TABLE t {name} =
      ("name_3"),("name_4")
      USE primary_key_push_down
      FOR r IN t
      MATCH (a@node_type_2) WHERE a.pk_name = r.name
      RETURN a.pk_name
      """
    Then the result should be, in any order:
      | a.pk_name |
      | "name_4"  |
      | "name_3"  |
    # Expected index range: [/pk_id/pk_name]: [/"5"/"name_5" - /"5"/"name_5"], [/"6"/"name_6" - /"6"/"name_6"], tight=true
    When executing query:
      """
      TABLE t {id, name} =
      (5,"name_5"),
      (6,"name_6")
      USE primary_key_push_down
      FOR r IN t
      MATCH (a@node_type_3) WHERE a.pk_id = r.id and a.pk_name = r.name
      RETURN a.pk_id,a.pk_name
      """
    Then the result should be, in any order:
      | a.pk_id | a.pk_name |
      | 6       | "name_6"  |
      | 5       | "name_5"  |
    # Expected index range: [/pk_id/pk_name]: [/5/"name_5" - /5/"name_5"], [/6/"name_6" - /6/"name_6"], tight=true
    When executing query:
      """
      TABLE t {id, name} =
      (5,"name_5"),
      (6,"name_6")
      USE primary_key_push_down
      FOR r IN t
      MATCH (a@node_type_3) WHERE a.pk_name = r.name and a.pk_id = r.id
      RETURN a.pk_id,a.pk_name
      """
    Then the result should be, in any order:
      | a.pk_id | a.pk_name |
      | 6       | "name_6"  |
      | 5       | "name_5"  |
    # Expected index range: [/pk_id_1/pk_id_2]: [/7/70 - /7/70], [/8/80 - /8/80], tight=true
    When executing query:
      """
      TABLE t {id_1, id_2} =
      (7,70),
      (8,80)
      USE primary_key_push_down
      FOR r IN t
      MATCH (a@node_type_4) WHERE a.pk_id_1 = r.id_1 and a.pk_id_2 = r.id_2
      RETURN a.pk_id_1,a.pk_id_2
      """
    Then the result should be, in any order:
      | a.pk_id_1 | a.pk_id_2 |
      | 7         | 70        |
      | 8         | 80        |
    # Expected index range: [/pk_id_1/pk_id_2]: [/7 - /7], [/8 - /8], tight=true
    When executing query:
      """
      TABLE t {id_1, id_2} =
      (7,70),
      (8,80)
      USE primary_key_push_down
      FOR r IN t
      MATCH (a@node_type_4) WHERE a.pk_id_1 = r.id_1
      RETURN a.pk_id_1,a.pk_id_2
      """
    Then the result should be, in any order:
      | a.pk_id_1 | a.pk_id_2 |
      | 7         | 70        |
      | 8         | 80        |
    And drop the graph "primary_key_push_down"
    And drop the graph type "primary_key_push_down_type"

  Scenario: complex path pattern
    # Complex path pattern, not a single node pattern
    When executing query:
      """
      USE ldbc
      LET a = 3
      MATCH (v1:Person)-[:KNOWS]->(v2:Person)
      WHERE v1.id = a
      RETURN v1.id, v2.id LIMIT 10
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      LET ids = LIST[3,4,5,6]
      MATCH (v1:Person)-[:KNOWS]->(v2:Person)
      WHERE v1.id IN ids
      RETURN v1.id, v2.id LIMIT 10
      """
    Then the execution should be successful
    # long path with multiple let vars
    When executing query:
      """
      USE ldbc
      LET a = 3
      LET ids = LIST[4,5]
      LET lo = 2, hi = 20
      MATCH (p1:Person)-[:KNOWS]->(p2:Person)-[:KNOWS]->(p3:Person)
      WHERE p1.id = a AND p2.id IN ids AND p3.id >= lo AND p3.id <= hi
      RETURN p1.id, p2.id, p3.id LIMIT 10
      """
    Then the execution should be successful
    # two-sided equality on long path
    When executing query:
      """
      USE ldbc
      LET a = 3, b = 4
      MATCH (p1:Person)-[:KNOWS]->(p2:Person)<-[:KNOWS]-(p3:Person)
      WHERE p1.id = a AND p3.id = b
      RETURN p1.id, p2.id, p3.id LIMIT 10
      """
    Then the execution should be successful
    # OR equality on start node
    When executing query:
      """
      USE ldbc
      LET a = 3, a2 = 4
      MATCH (p1:Person)-[:KNOWS]->(p2:Person)
      WHERE p1.id = a OR p1.id = a2
      RETURN p1.id, p2.id LIMIT 10
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      LET a = 2, b = [3,4,5], c = 1, d = 5
      MATCH (v1:Person)-[:FOLLOWS]->{1,2}(v2:Person)-[:FOLLOWS]->(v3:Person)
      WHERE v1.id = a and v2.id in b and v3.id >= c and v3.id <= d
      RETURN v1.id, v2.id, v3.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id | v3.id |
      | 2     | 3     | 1     |
      | 2     | 3     | 2     |

  # Composite PK + normal index, complex path with multiple external variables
  Scenario: Composite PK And Normal Index On Long Path
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS opt_idx_join_type AS {
        NODE Person (LABEL Person {id1 INT, id2 INT, name STRING, PRIMARY KEY (id1,id2)}),
        NODE Movie (LABEL Movie {id INT, title STRING, rating INT, PRIMARY KEY (id)}),
        EDGE KNOWS (Person)-[ LABEL KNOWS {since INT}]->(Person),
        EDGE LIKES (Person)-[ LABEL LIKES {}]->(Movie)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS opt_idx_join_graph TYPED opt_idx_join_type
      """
    Then the execution should be successful
    And use graph "opt_idx_join_graph"
    When executing query:
      """
      TABLE persons {id1, id2, name} =
        {id1:1, id2:10, name: "A"},
        {id1:2, id2:20, name: "B"},
        {id1:3, id2:30, name: "C"},
        {id1:4, id2:40, name: "D"},
        {id1:5, id2:50, name: "E"}
      FOR r IN persons INSERT (@Person{id1:r.id1, id2:r.id2, name:r.name})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE knows {s1,s2,d1,d2,since} =
        (1,10,2,20,2010),
        (2,20,3,30,2011),
        (3,30,4,40,2012),
        (4,40,5,50,2013)
      FOR r IN knows
      MATCH (a@Person{id1:r.s1, id2:r.s2}), (b@Person{id1:r.d1, id2:r.d2})
      INSERT (a)-[@KNOWS{since:r.since}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE movies {id, title, rating} = (101,"M1",90),(102,"M2",80)
      FOR r IN movies INSERT (@Movie{id:r.id, title:r.title, rating:r.rating})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE likes {p_id1, p_id2, m} =
        (3,30,101),
        (4,40,102)
      FOR r IN likes
      MATCH (a@Person{id1:r.p_id1, id2:r.p_id2}), (b@Movie{id:r.m})
      INSERT (a)-[@LIKES{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS movie_title_idx ON NODE Movie(title)
      """
    Then the execution should be successful
    And index "movie_title_idx" of "opt_idx_join_graph" should be ready to use
    # Equality on composite PK (p1), IN on p2 composite id via OR, normal index on Movie title
    When executing query:
      """
      LET a1 = 1, a2 = 10
      LET b1 = 2, b2 = 20
      LET t1 = "M1", t2 = "M2"
      // p1, p2, and m should be index scans
      MATCH (p1:Person)-[:KNOWS]->{1,2}(p2:Person)-[:LIKES]->(m:Movie)
      WHERE p1.id1 = a1 AND p1.id2 = a2
        AND ((p2.id1 = b1 AND p2.id2 = b2) OR (p2.id1 = 3 AND p2.id2 = 30))
        AND (m.title = t1 OR m.title = t2)
      RETURN p1.id1, p1.id2, p2.id1, p2.id2, m.title LIMIT 10
      """
    Then the result should be, in any order:
      | p1.id1 | p1.id2 | p2.id1 | p2.id2 | m.title |
      | 1      | 10     | 3      | 30     | "M1"    |
    And drop the index "movie_title_idx" of "opt_idx_join_graph"
    And drop the graph "opt_idx_join_graph"
    And drop the graph type "opt_idx_join_type"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9688
  Scenario: Property Filters Preserved With Index Scan
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS filter_preserve_type AS {
        NODE node_02 (LABELS node_02_label_00&node_02_label_01 {
          id INT,
          node_02_01_STRING STRING,
          node_02_03_STRING STRING,
          node_02_06_STRING STRING,
          node_02_09_BOOL BOOL,
          PRIMARY KEY (id)
        }),
        NODE node_03 (LABELS node_03_label_00&node_03_label_01 {
          id INT,
          node_03_11_STRING STRING,
          PRIMARY KEY (id)
        })
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS filter_preserve_graph TYPED filter_preserve_type
      """
    Then the execution should be successful
    And use graph "filter_preserve_graph"
    # Create composite index on node_02 (similar to ni_node_02_4 in original bug)
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS idx_node_02_composite ON NODE node_02(node_02_01_STRING, node_02_06_STRING, node_02_09_BOOL)
      """
    Then the execution should be successful
    And index "idx_node_02_composite" of "filter_preserve_graph" should be ready to use
    # Create index on node_03_11_STRING
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS idx_node_03_str ON NODE node_03(node_03_11_STRING)
      """
    Then the execution should be successful
    And index "idx_node_03_str" of "filter_preserve_graph" should be ready to use
    # Insert test data for node_02
    When executing query:
      """
      TABLE dt {id, s01, s03, s06, b09} =
        (1, "str1", "Luka Doncic", "Chris Paul", false),
        (2, "str2", "Luka Doncic", "Chris Paul", false),
        (3, "str3", "Other", "Chris Paul", false),
        (4, "str4", "Luka Doncic", "Other", false),
        (5, "str5", "Luka Doncic", "Chris Paul", true)
      FOR r IN dt
      INSERT (@node_02{
        id: r.id,
        node_02_01_STRING: r.s01,
        node_02_03_STRING: r.s03,
        node_02_06_STRING: r.s06,
        node_02_09_BOOL: r.b09
      })
      """
    Then the execution should be successful
    # Insert test data for node_03
    When executing query:
      """
      TABLE dt {id, s11} =
        (1, "str1"), (2, "str2"), (3, "str6")
      FOR r IN dt
      INSERT (@node_03{
        id: r.id,
        node_03_11_STRING: r.s11
      })
      """
    Then the execution should be successful
    When executing query:
      """
      MATCH
        (v0:node_02_label_01&node_02_label_00{
          node_02_09_BOOL: true
        }),
        (v1:node_03_label_00&node_03_label_01)
      WHERE v0.node_02_01_STRING = v1.node_03_11_STRING
      RETURN v0.node_02_03_STRING AS vstr, v0.node_02_09_BOOL AS vbool
      """
    Then the result should be, in any order:
      | vstr | vbool |
    And drop the graph "filter_preserve_graph"
    And drop the graph type "filter_preserve_type"
