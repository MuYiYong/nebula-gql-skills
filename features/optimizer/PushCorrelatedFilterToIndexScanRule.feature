# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: PushCorrelatedFilterToIndexScanRule

  Scenario: basic
    When executing query:
      """
      USE ldbc
      LET a = LIST[1, 2, 100, 3, 0]
      MATCH (x:Person) WHERE x.id in a
      RETURN x.id
      """
    Then the result should be, in any order:
      | x.id |
      | 1    |
      | 2    |
      | 3    |
    When executing query:
      """
      USE ldbc
      LET a = 2, b = 5
      MATCH (x:Person) WHERE x.id >= a AND x.id <= b
      RETURN x.id
      """
    Then the result should be, in any order:
      | x.id |
      | 2    |
      | 3    |
      | 4    |
    When executing query:
      """
      USE ldbc
      FOR i IN [[3,8],[4,12],[2,6]]
      MATCH (x:Person) WHERE x.id >= i[0] AND x.id <= i[1]
      RETURN DISTINCT x.id
      """
    Then the result should be, in any order:
      | x.id |
      | 2    |
      | 3    |
      | 4    |

  Scenario: complex
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS idx_push_down_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT, city STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS idx_push_down_graph TYPED idx_push_down_type
      """
    Then the execution should be successful
    And use graph "idx_push_down_graph"
    When executing query:
      """
      TABLE persons {id, name, age, city} =
      {id:1, name:"Alice", age:30, city:"City1"},
      {id:2, name:"Bob", age:25, city:"City2"},
      {id:3, name:"Charlie", age:35, city:"City1"},
      {id:4, name:"Dave", age:30, city:"City3"},
      {id:5, name:"Eve", age:25, city:"City2"}
      FOR r IN persons
      INSERT (@Person{id:r.id, name:r.name, age:r.age, city:r.city})
      """
    Then the execution should be successful
    When executing query:
      """
      USE idx_push_down_graph CREATE INDEX IF NOT EXISTS person_name_age_index ON NODE Person(name, age)
      """
    Then the execution should be successful
    And index "person_name_age_index" of "idx_push_down_graph" should be ready to use
    # Expected index range: [/name/age]: [/"Alice"/30], tight=true
    When executing query:
      """
      LET name = "Alice"
      LET age = 30
      MATCH (v:Person) WHERE v.name = name AND v.age = age
      RETURN v.name, v.age
      """
    Then the result should be, in any order:
      | v.name  | v.age |
      | "Alice" | 30    |
    # # Expected index range: [/name/age]: [/"Bob"/25], tight=true
    When executing query:
      """
      LET age = 25
      MATCH (v:Person) WHERE v.name = "Bob" AND v.age = age
      RETURN v.name, v.age
      """
    Then the result should be, in any order:
      | v.name | v.age |
      | "Bob"  | 25    |
    # # Expected index range: [/name/age]: [/"Charlie"/35], tight=true
    When executing query:
      """
      LET name = "Charlie"
      MATCH (v:Person) WHERE v.name = name AND v.age = 35
      RETURN v.name, v.age
      """
    Then the result should be, in any order:
      | v.name    | v.age |
      | "Charlie" | 35    |
    # # Expected index range: [/name/age]: [/"Alice"/30], tight=false
    When executing query:
      """
      LET name = "Alice"
      LET age = 30
      MATCH (v:Person) WHERE v.name = name AND v.age = age AND v.city = "City1"
      RETURN v.name, v.age, v.city
      """
    Then the result should be, in any order:
      | v.name  | v.age | v.city  |
      | "Alice" | 30    | "City1" |
    # # Expected index range: [/name/age]: [/"Eve"/20 - /"Eve"/], tight=true
    When executing query:
      """
      LET name = "Eve"
      LET minAge = 20
      MATCH (v:Person) WHERE v.name = name AND v.age > minAge
      RETURN v.name, v.age
      """
    Then the result should be, in any order:
      | v.name | v.age |
      | "Eve"  | 25    |
    # # Expected index range: [/name/age]: [/"Bob"/ - /"Bob"/], tight=false
    When executing query:
      """
      LET name = "Bob"
      LET cityVar = "City2"
      MATCH (v:Person) WHERE v.name = name AND v.city = cityVar
      RETURN v.name, v.city
      """
    Then the result should be, in any order:
      | v.name | v.city  |
      | "Bob"  | "City2" |
    # Expected index range: [/name/age]: [/"Alice"/ - /"Alice"/], [/"Bob"/ - /"Bob"/], tight=true
    When executing query:
      """
      LET name1 = "Alice"
      LET name2 = "Bob"
      MATCH (v:Person) WHERE v.name = name1 OR v.name = name2
      RETURN v.name
      """
    Then the result should be, in any order:
      | v.name  |
      | "Alice" |
      | "Bob"   |
    When executing query:
      """
      LET r = [ ["Alice", "Alicd"], ["Bob", "Cob"]]
      FOR i in r
      MATCH (v:Person) WHERE v.name = i[0] OR v.name = i[1]
      RETURN v.name
      """
    Then the result should be, in any order:
      | v.name  |
      | "Alice" |
      | "Bob"   |
    # # Expected index range: [/name/age]: [/"Alice"/25], [/"Alice"/30], tight=true
    When executing query:
      """
      LET name = "Alice"
      LET age1 = 25
      LET age2 = 30
      MATCH (v:Person) WHERE v.name = name AND (v.age = age1 OR v.age = age2)
      RETURN v.name, v.age
      """
    Then the result should be, in any order:
      | v.name  | v.age |
      | "Alice" | 30    |
    # Expected: cannot generate index scan plan
    When executing query:
      """
      LET name = "Bob"
      LET city = "City2"
      MATCH (v:Person) WHERE v.name = name OR v.city = city
      RETURN v.name, v.city
      """
    Then the result should be, in any order:
      | v.name | v.city  |
      | "Bob"  | "City2" |
      | "Eve"  | "City2" |
    # Expected index range: [/name/age]: [/"Alice"/30], [/"Bob"/25], tight=true
    When executing query:
      """
      LET age1 = 25
      LET age2 = 30
      MATCH (v:Person) WHERE (v.name = "Alice" AND v.age = age2) OR (v.name = "Bob" AND v.age = age1)
      RETURN v.name, v.age
      """
    Then the result should be, in any order:
      | v.name  | v.age |
      | "Alice" | 30    |
      | "Bob"   | 25    |
    And drop the index "person_name_age_index" of "idx_push_down_graph"
    And drop the graph "idx_push_down_graph"
    And drop the graph type "idx_push_down_type"

  Scenario: Predicate with the same node on both sides
    # FIX https://github.com/vesoft-inc/nebula-ng/issues/8909
    When executing query:
      """
      USE ldbc {
        LET x = 1
        MATCH
            (v)
        WHERE
            (v.id > 1 + x + v.id)
        FINISH
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc {
        LET x = 1
        MATCH
            (v)
        WHERE
            (v.id > 1 + x + v.id) AND v.id > 1 - x + element_id(v) OR v.id > v.id - x
        FINISH
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc {
        VALUE bvd0 INT = 1
        VALUE bvd3 INT = 1
        OPTIONAL MATCH
            (v0)
        WHERE
            ((v0.id + (bvd0 - bvd3)) > v0.id)
        FINISH
      }
      """
    Then the execution should be successful

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8909
  Scenario: Wrong use index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS idx_push_down_type1 AS {
      NODE Person1 (LABEL Person1 {id INT PRIMARY KEY, age INT}),
      NODE Person2 (LABEL Person2 {id INT PRIMARY KEY, age INT})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS idx_push_down_graph1 TYPED idx_push_down_type1
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE persons {id, age} =
          {id:1,  age:30 },
          {id:2,  age:25 },
          {id:3,  age:35 },
          {id:4,  age:30 },
          {id:5,  age:25 }
      USE idx_push_down_graph1
      FOR r IN persons
      INSERT (@Person1{id:r.id, age:r.age})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE persons {id, age} =
          {id:1,  age:30 },
          {id:2,  age:25 },
          {id:3,  age:35 },
          {id:4,  age:30 },
          {id:5,  age:25 }
      USE idx_push_down_graph1
      FOR r IN persons
      INSERT (@Person2{id:r.id, age:r.age})
      """
    Then the execution should be successful
    When executing query:
      """
      USE idx_push_down_graph1
      MATCH (v1:Person1)
      MATCH (v2:Person2)
      WHERE v1.id < v2.age
      RETURN v1.id LIMIT 5
      """
    Then the result should be, in any order:
      | v1.id |
      | 5     |
      | 4     |
      | 2     |
      | 3     |
      | 1     |
    When executing query:
      """
      USE idx_push_down_graph1
      LET x = RECORD{id:CAST(1 AS INT64)}
      MATCH (v1:Person1)
      WHERE v1.age > x.id
      RETURN v1.age
      """
    Then the result should be, in any order:
      | v1.age |
      | 25     |
      | 25     |
      | 30     |
      | 35     |
      | 30     |
    And drop the graph "idx_push_down_graph1"
    And drop the graph type "idx_push_down_type1"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9197
  Scenario: Assure correct bridge filter input
    When executing query:
      """
      USE ldbc
      MATCH (v{id: 5})
      LET vid = v.id
      MATCH (t)
      WHERE t.id > vid
      RETURN vid, t.id AS tid
      """
    Then the result should be, in any order:
      | vid | tid |
      | 5   | 6   |

  Scenario: Long path with multiple variables
    When executing query:
      """
      USE ldbc
      LET ids = LIST[3,4,5]
      LET lo = 2, hi = 20
      MATCH (p1:Person)-[:KNOWS]->(p2:Person)-[:KNOWS]->(p3:Person)
      WHERE p1.id IN ids AND p3.id >= lo AND p3.id <= hi
      RETURN p1.id, p2.id, p3.id LIMIT 10
      """
    Then the execution should be successful
    # FOR-driven correlated long path
    When executing query:
      """
      USE ldbc
      LET ranges = LIST[[3,8],[4,12],[2,6]]
      FOR r IN ranges
      MATCH (x:Person)-[:KNOWS]->(y:Person)-[:KNOWS]->(z:Person)
      WHERE x.id >= r[0] AND z.id <= r[1]
      RETURN DISTINCT x.id LIMIT 10
      """
    Then the execution should be successful

  Scenario: Equality Join With Let Variable
    When executing query:
      """
      USE ldbc
      LET x = 3
      MATCH (p1:Person)-[:KNOWS]->(p2:Person) WHERE p1.id = x
      RETURN p1.id, p2.id LIMIT 10
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      LET a = LIST[1, 2, 100, 3, 0]
      MATCH (x:Person)-[:KNOWS]->(y:Person) WHERE x.id in a
      RETURN x.id, y.id LIMIT 10
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      LET a = 2, b = 5
      MATCH (x:Person)-[:KNOWS]->(y:Person) WHERE x.id >= a AND x.id <= b
      RETURN x.id, y.id LIMIT 10
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc
      FOR i IN [[3,8],[4,12],[2,6]]
      MATCH (x:Person)-[:KNOWS]->(y:Person) WHERE x.id >= i[0] AND x.id <= i[1]
      RETURN DISTINCT x.id LIMIT 10
      """
    Then the execution should be successful

  # Composite PK + normal index on separate graph, correlated filter on path
  Scenario: Composite PK And Normal Index With Correlated Filters
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS opt_idx_corr_type AS {
        NODE Person (LABEL Person {id1 INT, id2 INT, name STRING, PRIMARY KEY (id1,id2)}),
        NODE Movie (LABEL Movie {id INT, title STRING, rating INT, PRIMARY KEY (id)}),
        EDGE KNOWS (Person)-[ LABEL KNOWS {since INT}]->(Person),
        EDGE LIKES (Person)-[ LABEL LIKES {}]->(Movie)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS opt_idx_corr_graph TYPED opt_idx_corr_type
      """
    Then the execution should be successful
    And use graph "opt_idx_corr_graph"
    When executing query:
      """
      TABLE persons {id1, id2, name} =
        (1,10,"A"), (2,20,"B"), (3,30,"C"), (4,40,"D"), (5,50,"E")
      FOR r IN persons INSERT (@Person{id1:r.id1, id2:r.id2, name:r.name})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE knows {s1,s2,d1,d2,since} =
        (1,10,2,20,2010), (2,20,3,30,2011), (3,30,4,40,2012)
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
      TABLE likes {p_id1, p_id2, m} = (2,20,101)
      FOR r IN likes
      MATCH (a@Person{id1:r.p_id1, id2:r.p_id2}), (b@Movie{id:r.m})
      INSERT (a)-[@LIKES{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE INDEX IF NOT EXISTS movie_title_idx2 ON NODE Movie(title)
      """
    Then the execution should be successful
    And index "movie_title_idx2" of "opt_idx_corr_graph" should be ready to use
    # Correlated filters on both ends of a two-hop path
    When executing query:
      """
      LET r = RECORD{id1:1, id2:10}
      LET titles = LIST["M1","M2"]
      -- Both p1 and m should be index scans
      MATCH (p1:Person)-[:KNOWS]->(p2:Person)-[:LIKES]->(m:Movie)
      WHERE (p1.id1 = r.id1 AND p1.id2 = r.id2)
        AND m.title IN titles
      RETURN p1.id1, p1.id2, p2.id1, p2.id2, m.title LIMIT 10
      """
    Then the result should be, in any order:
      | p1.id1 | p1.id2 | p2.id1 | p2.id2 | m.title |
      | 1      | 10     | 2      | 20     | "M1"    |
    And drop the index "movie_title_idx2" of "opt_idx_corr_graph"
    And drop the graph "opt_idx_corr_graph"
    And drop the graph type "opt_idx_corr_type"

  Scenario: Dynamic index scan shall not scan redundant data
    And use graph "ldbc"
    When executing query:
      """
      for i in range(1,2)
      match (v:Person{id:i}),(t:Person where t.id > i)
      return v.id as vid , t.id as tid order by vid, tid
      """
    Then the result should be, in any order:
      | vid | tid |
      | 1   | 2   |
      | 1   | 3   |
      | 1   | 4   |
      | 2   | 3   |
      | 2   | 4   |
    When executing query:
      """
      /*+ set_var(optimizer_rules="push_correlated_filter_to_index_scan=off") */
      for i in range(1,2)
      match (v:Person{id:i}),(t:Person where t.id > i)
      return v.id as vid , t.id as tid order by vid, tid
      """
    Then the result should be, in any order:
      | vid | tid |
      | 1   | 2   |
      | 1   | 3   |
      | 1   | 4   |
      | 2   | 3   |
      | 2   | 4   |
    # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9671
    When executing query:
      """
      USE ldbc
      LET vid = 4
      MATCH (v:Person{lastName: "Marceau"})
      WHERE v.id <= vid
      RETURN v.id AS vid, v.lastName as lastName
      """
    Then the result should be, in any order:
      | vid | lastName  |
      | 4   | "Marceau" |
