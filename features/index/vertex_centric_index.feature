# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Vertex-Centric Index

  @testmark
  Scenario: Vertex-centric index test
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS vc_index_graph_type AS {
        NODE user (LABEL user {id INT64 PRIMARY KEY, name STRING, age INT64}),
        NODE movie (LABEL movie {id INT64 PRIMARY KEY, title STRING, year INT64}),
        EDGE watch (user)-[LABEL watch {rate INT64, ts INT64}]->(movie),
        EDGE friend (user)-[LABEL friend {since INT64, weight INT64}]->(user),
        EDGE knows (user)~[LABEL knows {strength INT64}]~(user)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_index_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH vc_index_graph TYPED vc_index_graph_type
      """
    Then the execution should be successful
    # ============================================
    # Part 1: Create vertex-centric index with correct syntax
    # ============================================
    # Create _src index (single property)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    # Create _dst index (single property)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # Create _src index (composite properties)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_time_idx ON EDGE watch(_src, rate, ts)
      """
    Then the execution should be successful
    # Create _dst index (composite properties)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_time_idx ON EDGE watch(_dst, rate DESC, ts ASC)
      """
    Then the execution should be successful
    # Create _src index (another edge type)
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    # Verify indexes are created
    When executing query:
      """
      USE vc_index_graph SHOW INDEXES
      """
    Then the result should be, in any order:
      | name                      | state   | index_type | schema            | graph_name       | entity_type | element_type | properties                             |
      | "watch_src_rate_idx"      | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_src ASC","rate ASC"]           |
      | "watch_dst_rate_idx"      | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_dst ASC","rate ASC"]           |
      | "watch_src_rate_time_idx" | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_src ASC","rate ASC","ts ASC"]  |
      | "watch_dst_rate_time_idx" | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "watch"      | LIST ["_dst ASC","rate DESC","ts ASC"] |
      | "friend_src_since_idx"    | "Valid" | "Normal"   | "/default_schema" | "vc_index_graph" | "Edge"      | "friend"     | LIST ["_src ASC","since ASC"]          |
    # Cleanup indexes for next part
    And drop the index "friend_src_since_idx" of "vc_index_graph"
    And drop the index "watch_dst_rate_time_idx" of "vc_index_graph"
    And drop the index "watch_src_rate_time_idx" of "vc_index_graph"
    And drop the index "watch_dst_rate_idx" of "vc_index_graph"
    And drop the index "watch_src_rate_idx" of "vc_index_graph"
    # ============================================
    # Part 2: Create vertex-centric index with invalid syntax
    # ============================================
    # Invalid: _src not at the first position
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx1 ON EDGE watch(rate, _src)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: System fields (_src, _dst) can only appear as the first indexed property"
    # Invalid: _dst not at the first position
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx2 ON EDGE watch(rate, _dst)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: System fields (_src, _dst) can only appear as the first indexed property"
    # Invalid: both _src and _dst are used
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx3 ON EDGE watch(_src, _dst, rate)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: System fields (_src, _dst) can only appear as the first indexed property"
    # Invalid: VC index cannot be created on undirected edge
    When executing query:
      """
      USE vc_index_graph CREATE INDEX invalid_idx4 ON EDGE knows(_src, strength)
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Vertex-Centric Index (with _src/_dst) is not supported for undirected edge type"
    # ============================================
    # Part 3: Query data using vertex-centric index with _src
    # ============================================
    # Create _src index
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    # Insert test data
    When executing query:
      """
      USE vc_index_graph INSERT (@user{id:1, name:"Alice", age:25}), (@user{id:2, name:"Bob", age:30}), (@user{id:3, name:"Carol", age:28})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph INSERT (@movie{id:101, title:"Movie A", year:2020}), (@movie{id:102, title:"Movie B", year:2021}), (@movie{id:103, title:"Movie C", year:2022})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (m1:movie WHERE m1.id = 101), (m2:movie WHERE m2.id = 102), (m3:movie WHERE m3.id = 103) INSERT (u1)-[@watch{rate:85, ts:1000}]->(m1), (u1)-[@watch{rate:90, ts:2000}]->(m2), (u2)-[@watch{rate:75, ts:3000}]->(m1), (u2)-[@watch{rate:95, ts:4000}]->(m3), (u3)-[@watch{rate:88, ts:5000}]->(m2)
      """
    Then the execution should be successful
    # Use hint to force _src vc-index using outgoing edge pattern
    # _src index is outgoing edge index, use edge pattern: (u:user)-[e:watch]->(m:movie) or (u:user)-[e:watch]-(m:movie)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_idx) */]->(v2:movie) WHERE e.rate > 0 ORDER BY e.rate DESC RETURN u.id AS user_id, v2.id AS movie_id, e.rate AS rate
      """
    Then the execution plan should use index "watch_src_rate_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_idx) */]-(m:movie) WHERE e.rate > 0 ORDER BY e.rate ASC RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate
      """
    Then the execution plan should use index "watch_src_rate_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 101      | 85   |
      | 1       | 102      | 90   |
    When executing query:
      """
      USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_idx) */]->(m:movie) WHERE u.id = 2 AND e.rate > 70 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 2       | 101      | 75   |
    # Cleanup
    And drop the index "watch_src_rate_idx" of "vc_index_graph"
    # Create _src index again to verify RepairIndex
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_idx ON EDGE watch(_src, rate)
      """
    Then the execution should be successful
    # Use hint to force _src index
    When executing query:
      """
      USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_idx) */]->(m:movie) WHERE u.id = 1 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 1       | 101      | 85   |
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:2})-[e:watch /*+ INDEX(watch_src_rate_idx) */]-(m:movie) WHERE e.rate > 70 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the execution plan should use index "watch_src_rate_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 2       | 101      | 75   |
    # Cleanup
    And drop the index "watch_src_rate_idx" of "vc_index_graph"
    # ============================================
    # Part 4: Query data using vertex-centric index with _dst
    # ============================================
    # Create _dst index
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # Insert more data
    When executing query:
      """
      USE vc_index_graph INSERT (@user{id:4, name:"David", age:35}), (@user{id:5, name:"Eve", age:27}), (@user{id:6, name:"Frank", age:32})
      """
    Then the execution should be successful
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4), (u5:user WHERE u5.id = 5), (u6:user WHERE u6.id = 6), (m1:movie WHERE m1.id = 101), (m2:movie WHERE m2.id = 102), (m3:movie WHERE m3.id = 103) INSERT (u3)-[@watch{rate:92, ts:6000}]->(m1), (u4)-[@watch{rate:78, ts:7000}]->(m1), (u5)-[@watch{rate:88, ts:8000}]->(m1), (u2)-[@watch{rate:82, ts:9000}]->(m2), (u4)-[@watch{rate:85, ts:10000}]->(m2), (u6)-[@watch{rate:91, ts:11000}]->(m2), (u1)-[@watch{rate:88, ts:12000}]->(m3), (u3)-[@watch{rate:92, ts:13000}]->(m3), (u5)-[@watch{rate:87, ts:14000}]->(m3)
      """
    Then the execution should be successful
    # Use hint to force _dst index using incoming edge pattern
    # _dst index is incoming edge index, use pattern: (m:movie)-[e:watch]-(u:user) or (m:movie)<-[e:watch]-(u:user)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})<-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the execution plan should use index "watch_dst_rate_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 3       | 101      | 92   |
      | 5       | 101      | 88   |
      | 1       | 101      | 85   |
      | 4       | 101      | 78   |
      | 2       | 101      | 75   |
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:102})-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE e.rate >= 80 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY u.id ASC
      """
    Then the execution plan should use index "watch_dst_rate_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 1       | 102      | 90   |
      | 2       | 102      | 82   |
      | 3       | 102      | 88   |
      | 4       | 102      | 85   |
      | 6       | 102      | 91   |
    When executing query:
      """
      USE vc_index_graph MATCH (m:movie)<-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE m.id = 103 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 3       | 103      | 92   |
      | 1       | 103      | 88   |
      | 5       | 103      | 87   |
    # Cleanup
    And drop the index "watch_dst_rate_idx" of "vc_index_graph"
    # Create _dst index again to verify RepairIndex
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_idx ON EDGE watch(_dst, rate)
      """
    Then the execution should be successful
    # Use hint to force _dst index
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie)-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE m.id = 101 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the execution plan should use index "watch_dst_rate_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 3       | 101      | 92   |
      | 5       | 101      | 88   |
      | 1       | 101      | 85   |
      | 4       | 101      | 78   |
      | 2       | 101      | 75   |
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie)<-[e:watch /*+ INDEX(watch_dst_rate_idx) */]-(u:user) WHERE m.id = 103 AND e.rate > 0 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate ORDER BY e.rate DESC
      """
    Then the execution plan should use index "watch_dst_rate_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate |
      | 2       | 103      | 95   |
      | 3       | 103      | 92   |
      | 1       | 103      | 88   |
      | 5       | 103      | 87   |
    # Cleanup
    And drop the index "watch_dst_rate_idx" of "vc_index_graph"
    # ============================================
    # Part 5: Query data using composite vertex-centric index
    # ============================================
    # Create composite _src index
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_time_idx ON EDGE watch(_src, rate, ts)
      """
    Then the execution should be successful
    # Clean up existing watch edges before inserting new ones
    When executing query:
      """
      USE vc_index_graph MATCH (u:user)-[e:watch]->(m:movie) WHERE u.id IN [1, 2, 3] OR m.id IN [101, 102, 103] DELETE e
      """
    Then the execution should be successful
    # Insert edge data for composite index testing
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (m1:movie WHERE m1.id = 101), (m2:movie WHERE m2.id = 102), (m3:movie WHERE m3.id = 103) INSERT (u1)-[@watch{rate:85, ts:1000}]->(m1), (u1)-[@watch{rate:85, ts:2000}]->(m2), (u1)-[@watch{rate:90, ts:3000}]->(m3), (u2)-[@watch{rate:75, ts:4000}]->(m1)
      """
    Then the execution should be successful
    # Query with composite index (prefix match: _src + rate)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_time_idx) */]->(m:movie) WHERE u.id = 1 AND e.rate = 85 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the execution plan should use index "watch_src_rate_time_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
      | 1       | 102      | 85   | 2000 |
    # Query with composite index (full match: _src + rate + ts)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user)-[e:watch /*+ INDEX(watch_src_rate_time_idx) */]-(m:movie) WHERE u.id = 1 AND e.rate >= 85 AND e.ts > 1500 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the execution plan should use index "watch_src_rate_time_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 102      | 85   | 2000 |
      | 1       | 103      | 90   | 3000 |
    # Cleanup
    And drop the index "watch_src_rate_time_idx" of "vc_index_graph"
    # Create composite index again to verify RepairIndex
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_src_rate_time_idx ON EDGE watch(_src, rate, ts)
      """
    Then the execution should be successful
    # Create composite incoming edge index to verify RepairIndex
    # Verify non-reserve and reserve index both exist
    When executing query:
      """
      USE vc_index_graph CREATE INDEX watch_dst_rate_time_idx ON EDGE watch(_dst, rate, ts)
      """
    Then the execution should be successful
    # Query with composite index (prefix match: _src + rate)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u:user{id:1})-[e:watch /*+ INDEX(watch_src_rate_time_idx) */]-(m:movie) WHERE e.rate = 85 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the execution plan should use index "watch_src_rate_time_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
      | 1       | 102      | 85   | 2000 |
    # Query with composite index (prefix match: _dst + rate)
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (m:movie{id:101})-[e:watch /*+ INDEX(watch_dst_rate_time_idx) */]-(u:user) WHERE e.rate = 85 RETURN u.id AS user_id, m.id AS movie_id, e.rate AS rate, e.ts AS ts ORDER BY e.ts ASC
      """
    Then the execution plan should use index "watch_dst_rate_time_idx" for EdgesScan
    Then the result should be, in order:
      | user_id | movie_id | rate | ts   |
      | 1       | 101      | 85   | 1000 |
    # Cleanup
    And drop the index "watch_src_rate_time_idx" of "vc_index_graph"
    # ============================================
    # Part 6: Query data using vertex-centric index on self-loop edge (_src)
    # ============================================
    # Clean up existing data before inserting
    When executing query:
      """
      USE vc_index_graph MATCH (u:user) WHERE u.id IN [1, 2, 3, 4] DETACH DELETE u
      """
    Then the execution should be successful
    # Create _src index on self-loop edge
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_src_since_idx ON EDGE friend(_src, since)
      """
    Then the execution should be successful
    # Insert data
    When executing query:
      """
      USE vc_index_graph INSERT (@user{id:1, name:"Alice", age:25}), (@user{id:2, name:"Bob", age:30}), (@user{id:3, name:"Carol", age:28}), (@user{id:4, name:"David", age:35})
      """
    Then the execution should be successful
    # Insert friend edge data (user -> user self-loop)
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4) INSERT (u1)-[@friend{since:2020, weight:10}]->(u2), (u1)-[@friend{since:2021, weight:8}]->(u3), (u1)-[@friend{since:2019, weight:9}]->(u4), (u2)-[@friend{since:2022, weight:7}]->(u1), (u2)-[@friend{since:2023, weight:6}]->(u3), (u3)-[@friend{since:2024, weight:5}]->(u1)
      """
    Then the execution should be successful
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user)-[e:friend /*+ INDEX(friend_src_since_idx) */]-(u2:user) WHERE u1.id = 1 AND e.since > 2018 RETURN u1.id AS from_user, u2.id AS to_user, e.since AS since ORDER BY e.since ASC
      """
    Then the execution plan should use index "friend_src_since_idx" for EdgesScan
    Then the result should be, in order:
      | from_user | to_user | since |
      | 1         | 4       | 2019  |
      | 1         | 2       | 2020  |
      | 1         | 3       | 2021  |
    # outgoing edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u1:user)-[e:friend /*+ INDEX(friend_src_since_idx) */]->(u2:user) WHERE u1.id = 2 AND e.since >= 2022 RETURN u1.id AS from_user, u2.id AS to_user, e.since AS since ORDER BY e.since DESC
      """
    Then the execution plan should use index "friend_src_since_idx" for EdgesScan
    Then the result should be, in order:
      | from_user | to_user | since |
      | 2         | 3       | 2023  |
      | 2         | 1       | 2022  |
    # Cleanup
    And drop the index "friend_src_since_idx" of "vc_index_graph"
    # ============================================
    # Part 7: Query data using vertex-centric index on self-loop edge (_dst)
    # ============================================
    # Create _dst index on self-loop edge
    When executing query:
      """
      USE vc_index_graph CREATE INDEX friend_dst_weight_idx ON EDGE friend(_dst, weight)
      """
    Then the execution should be successful
    # Insert data
    When executing query:
      """
      USE vc_index_graph MATCH (u1:user WHERE u1.id = 1), (u2:user WHERE u2.id = 2), (u3:user WHERE u3.id = 3), (u4:user WHERE u4.id = 4) INSERT (u4)-[@friend{since:2021, weight:9}]->(u1), (u4)-[@friend{since:2022, weight:8}]->(u2), (u3)-[@friend{since:2023, weight:6}]->(u2)
      """
    Then the execution should be successful
    # bidirectional edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u2:user)-[e:friend /*+ INDEX(friend_dst_weight_idx) */]-(u1:user) WHERE u2.id = 1 AND e.weight > 0 RETURN u1.id AS from_user, u2.id AS to_user, e.weight AS weight ORDER BY e.weight DESC
      """
    Then the execution plan should use index "friend_dst_weight_idx" for EdgesScan
    Then the result should be, in order:
      | from_user | to_user | weight |
      | 4         | 1       | 9      |
      | 2         | 1       | 7      |
      | 3         | 1       | 5      |
    # incoming edge pattern
    When executing query:
      """
      PROFILE USE vc_index_graph MATCH (u2:user)<-[e:friend /*+ INDEX(friend_dst_weight_idx) */]-(u1:user) WHERE u2.id = 3 AND e.weight >= 6 RETURN u1.id AS from_user, u2.id AS to_user, e.weight AS weight ORDER BY e.weight ASC
      """
    Then the execution plan should use index "friend_dst_weight_idx" for EdgesScan
    Then the result should be, in order:
      | from_user | to_user | weight |
      | 2         | 3       | 6      |
      | 1         | 3       | 8      |
    # Cleanup
    And drop the index "friend_dst_weight_idx" of "vc_index_graph"
    # ============================================
    # Part 8: Drop inexistent vertex-centric index
    # ============================================
    # Dropping again should raise error
    When executing query:
      """
      USE vc_index_graph DROP INDEX friend_dst_weight_idx
      """
    Then an Error should be raised: "[NC007]: Catalog index not found: `friend_dst_weight_idx`"
    # ============================================
    # Cleanup
    # ============================================
    When executing query:
      """
      DROP GRAPH IF EXISTS vc_index_graph
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE IF EXISTS vc_index_graph_type
      """
    Then the execution should be successful
