# Copyright (c) 2023 vesoft inc. All rights reserved.
@pretest
Feature: ttl

  Scenario: basic ttl
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ttl_test_type AS {
        NODE player (LABEL player {id INT PRIMARY KEY}),
        EDGE follow (player)-[LABEL follow {t1 ZONED DATETIME, t2 ZONED DATETIME, s1 STRING, vec VECTOR<3,float> NOT NULL}]->(player)
      }
      """
    Then the execution should be successful
    And graph type "ttl_test_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ttl_test TYPED ttl_test_type
      """
    Then the execution should be successful
    And graph "ttl_test" should be ready to use
    When executing query:
      """
      USE ttl_test CREATE TTL ON NODE player(t1) DURATION({"days":1})
      """
    Then an Error should be raised: "[42001]: syntax error near `NODE`"
    When executing query:
      """
      USE ttl_test CREATE TTL ON EDGE follow(s1) DURATION({"days":1})
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: Only zoned datetime property support ttl"
    When executing query:
      """
      USE ttl_test CREATE TTL ON EDGE follow(t1) DURATION({"years":1})
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: ttl duration only support day/hour/min/sec/ms/us"
    When executing query:
      """
      USE ttl_test CREATE TTL ON EDGE follow(t1) DURATION({"months":1})
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: ttl duration only support day/hour/min/sec/ms/us"
    When executing query:
      """
      USE ttl_test CREATE TTL ON EDGE follow(t1) DURATION({"hours":-1})
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: ttl duration must be positive"
    When executing query:
      """
      USE ttl_test CREATE TTL ON EDGE follow(t1) DURATION({"seconds":2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_test SHOW TTLS
      """
    Then the result should be, in any order:
      | type   | name     | ttl_property | ttl_duration                 |
      | "Edge" | "follow" | "t1"         | DURATION "P0DT0H0M2.000000S" |
    When executing query:
      """
      USE ttl_test ALTER TTL ON EDGE follow(t2) DURATION({"seconds":2, "milliseconds":500})
      """
    Then an Error should be raised: "[NC013]: `follow` already has a ttl property `t1`"
    When executing query:
      """
      USE ttl_test ALTER TTL ON EDGE follow(t1) DURATION({"seconds":5, "milliseconds":500})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx1 ON EDGE follow::vec OPTIONS {dim:3, type:HNSW, metric:IP, capacity:333}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_test CREATE VECTOR INDEX IF NOT EXISTS ann_edge_idx2 ON EDGE follow::vec OPTIONS {dim:3, type:IVF, metric:L2, nlist:8}
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_test SHOW TTLS
      """
    Then the result should be, in any order:
      | type   | name     | ttl_property | ttl_duration                 |
      | "Edge" | "follow" | "t1"         | DURATION "P0DT0H0M5.500000S" |
    When executing query:
      """
      USE ttl_test INSERT (:player{id:1}), (:player{id:2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_test
      MATCH (a:player{id:1}), (b:player{id:2})
      INSERT (a)-[:follow{t1:current_time, t2:local_time("11:22:33"), s1:"abc", vec:vector(1,2,3)}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_test
      MATCH (a:player)-[e:follow]->(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1    |
      | "abc" |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ttl_test
      MATCH (a:player)-[e:follow]->(b:player)
      ORDER BY inner_product(vector(1,2,3), e.vec) desc APPROX LIMIT 333 OPTIONS {type:HNSW, metric:IP}
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1    |
      | "abc" |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ttl_test
      MATCH (a:player)-[e:follow]->(b:player)
      ORDER BY euclidean(vector(1,2,3), e.vec) APPROX LIMIT 333 OPTIONS {type:IVF, metric:L2, nprobe:8}
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1    |
      | "abc" |
    And wait "6" seconds
    When executing query:
      """
      USE ttl_test
      MATCH (a:player)-[e:follow]->(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ttl_test
      MATCH (a:player)-[e:follow]->(b:player)
      ORDER BY inner_product(vector(1,2,3), e.vec) desc APPROX LIMIT 333 OPTIONS {type:HNSW, metric:IP}
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ttl_test
      MATCH (a:player)-[e:follow]->(b:player)
      ORDER BY euclidean(vector(1,2,3), e.vec) APPROX LIMIT 333 OPTIONS {type:IVF, metric:L2, nprobe:8}
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1 |
    When executing query:
      """
      USE ttl_test
      MATCH (a:player)<-[e:follow]-(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1 |
    When executing query:
      """
      USE ttl_test
      MATCH (a:player)-[e:follow]-(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1 |
    When executing query:
      """
      USE ttl_test DROP TTL ON EDGE follow
      """
    Then the execution should be successful
    And drop the graph "ttl_test"
    And drop the graph type "ttl_test_type"
    When executing query:
      """
      CALL show_ttls() RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `show_ttls`: at least 1 argument(s) required"

  Scenario: ttl ddl fail
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ttl_test_fail_type AS {
        NODE player (LABEL player {id INT PRIMARY KEY}),
        EDGE follow (player)-[LABEL follow {t1 ZONED DATETIME, t2 ZONED DATETIME, s1 STRING}]->(player)
      }
      """
    Then the execution should be successful
    And graph type "ttl_test_fail_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ttl_fail_test TYPED ttl_test_fail_type
      """
    Then the execution should be successful
    And graph "ttl_fail_test" should be ready to use
    When executing query:
      """
      USE ttl_fail_test CREATE TTL ON EDGE follow(t1) DURATION({"hours":2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_fail_test CREATE TTL ON EDGE follow(t1) DURATION({"minutes":2})
      """
    Then an Error should be raised: "[NC013]: `follow` already has a ttl property `t1`"
    When executing query:
      """
      USE ttl_fail_test ALTER TTL ON EDGE follow(t1) DURATION({"seconds":2, "milliseconds":500})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_fail_test DROP TTL ON EDGE follow
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_fail_test ALTER TTL ON EDGE follow(t1) DURATION({"seconds":2, "milliseconds":500})
      """
    Then an Error should be raised: "[NC304]: Illegal DDL: No ttl property existed"
    And drop the graph "ttl_fail_test"
    And drop the graph type "ttl_test_fail_type"

  Scenario: ttl expired and insert
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ttl_expired_test_type AS {
        NODE player (LABEL player {id INT PRIMARY KEY}),
        EDGE follow (player)-[LABEL follow {t1 ZONED DATETIME, t2 ZONED DATETIME, s1 STRING}]->(player)
      }
      """
    Then the execution should be successful
    And graph type "ttl_expired_test_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ttl_expired_test TYPED ttl_expired_test_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_expired_test CREATE TTL ON EDGE follow(t1) DURATION({"seconds":5})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_expired_test INSERT (:player{id:1}), (:player{id:2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_expired_test
      MATCH (a:player{id:1}), (b:player{id:2})
      INSERT (a)-[:follow{t1:current_time, t2:local_time("11:22:33"), s1:"abc"}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_expired_test
      MATCH (a:player)-[e:follow]->(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1    |
      | "abc" |
    And wait "6" seconds
    When executing query:
      """
      USE ttl_expired_test
      MATCH (a:player)-[e:follow]->(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1 |
    When executing query:
      """
      USE ttl_expired_test
      MATCH (a:player{id:1}), (b:player{id:2})
      INSERT (a)-[:follow{t1:current_time, t2:local_time("11:22:33"), s1:"def"}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_expired_test
      MATCH (a:player)-[e:follow]->(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1    |
      | "def" |
    And drop the graph "ttl_expired_test"
    And drop the graph type "ttl_expired_test_type"

  Scenario: ttl stats
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ttl_stats_test_type AS {
        NODE player (LABEL player {id INT PRIMARY KEY}),
        EDGE follow (player)-[LABEL follow {t1 ZONED DATETIME, t2 ZONED DATETIME, s1 STRING, vec VECTOR<3,float>}]->(player)
      }
      """
    Then the execution should be successful
    And graph type "ttl_stats_test_type" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ttl_stats_test TYPED ttl_stats_test_type
      """
    When executing query:
      """
      USE ttl_stats_test CREATE TTL ON EDGE follow(t1) DURATION({"seconds":2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_stats_test INSERT (:player{id:1}), (:player{id:2})
      """
    Then the execution should be successful
    When executing query:
      """
      USE ttl_stats_test
      MATCH (a:player{id:1}), (b:player{id:2})
      INSERT (a)-[:follow{t1:current_time, t2:local_time("11:22:33"), s1:"abc", vec:vector(1,2,3)}]->(b)
      """
    Then the execution should be successful
    And wait "3" seconds
    When executing query:
      """
      USE ttl_stats_test
      MATCH (a:player)-[e:follow]->(b:player)
      RETURN e.s1 as s1
      """
    Then the result should be, in any order:
      | s1 |
    When executing query:
      """
      SUBMIT JOB STATS ttl_stats_test
      """
    Then the execution should be successful
    And stats of graph "ttl_stats_test" should be ready
    When executing raw query:
      """
      SHOW STATS ttl_stats_test
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Edge Total" | "Edge"       | 0         |
      | "Node Total" | "Node"       | 2         |
      | "follow"     | "Edge"       | 0         |
      | "player"     | "Node"       | 2         |
    And drop the graph "ttl_stats_test"
    And drop the graph type "ttl_stats_test_type"
