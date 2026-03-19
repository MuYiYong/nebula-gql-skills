# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Job

  Scenario: Flush and compact
    When executing raw query:
      """
      SUBMIT JOB FLUSH
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing raw query:
      """
      /*+ SET_VAR(task_concurrency = 1) */
      SUBMIT JOB FLUSH
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing raw query:
      """
      CALL flush() RETURN *
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing raw query:
      """
      SUBMIT JOB COMPACT
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing raw query:
      """
      CALL compact() RETURN *
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    And wait "1" seconds
    When executing raw query:
      """
      SHOW JOB 1
      """
    Then the result should contain:
      | task_id | state | service_id | dispatch_time | end_time |
    When executing query:
      """
      SHOW JOB 34567
      """
    Then an Error should be raised: "[NJ010]: There are no tasks in job 34567"
    When executing raw query:
      """
      CALL show_job(1) RETURN *
      """
    Then the result should contain:
      | task_id | state | service_id | dispatch_time | end_time |
    When executing raw query:
      """
      SHOW JOBS
      """
    Then the result should contain:
      | job_id | type | state | submit_time | start_time | end_time |
    When executing raw query:
      """
      CALL show_all_job() RETURN *
      """
    Then the result should contain:
      | job_id | type | state | submit_time | start_time | end_time |
    When executing raw query:
      """
      SHOW JOBS VERBOSE
      """
    Then the result should contain:
      | job_id | type | state | submit_time | start_time | end_time | schema_path | graph_name | index_name |
    When executing raw query:
      """
      CALL show_all_job_verbose() RETURN *
      """
    Then the result should contain:
      | job_id | type | state | submit_time | start_time | end_time | schema_path | graph_name | index_name |
    When executing query:
      """
      CALL show_job() RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `show_job`: at least 1 argument(s) required"
    When executing query:
      """
      CALL show_job('1') RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `show_job`: argument `\"1\"` is of type `STRING` instead of the expected `INT64`"
    When executing query:
      """
      CALL show_job(CAST(1 AS UINT8)) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_job(CAST(1 AS INT64)) RETURN *
      """
    Then the execution should be successful

  Scenario: Repair index
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS repair_graph_type AS {
        NODE person ( LABEL person {id INT PRIMARY KEY, name STRING, age INT32, gender bool, money DOUBLE, score INT, luckyTime LOCAL DATETIME}),
        NODE city ( LABEL city {id INT PRIMARY KEY, name STRING}),
        EDGE follow (person)-[ LABEL follow {followness INT}]->(person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS repair_index_graph TYPED repair_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE repair_index_graph INSERT
      (@person{id: 1, name: "Lee",   age: 16,   gender: true,  money: -123.45, score: 78,   luckyTime: local_datetime('2012-04-03T00:00:00.000', "%Y-%m-%dT%H:%M:%S")}),
      (@person{id: 2, name: "Tom",   age: 25,   gender: true,  money: 88888.0, score: 100,  luckyTime: local_datetime('2008-11-14T12:56:59.123', "%Y-%m-%dT%H:%M:%S")}),
      (@person{id: 3, name: "Jerry", age: 22,   gender: false, money: 666.6,   score: 99,   luckyTime: local_datetime('2023-01-11T08:08:08.008', "%Y-%m-%dT%H:%M:%S")}),
      (@person{id: 4, name: "Biden", age: 90,   gender: true,  money: 10000,   score: 14,   luckyTime: local_datetime('1992-04-13T12:12:12.012', "%Y-%m-%dT%H:%M:%S")}),
      (@person{id: 5, name:  NULL,   age: NULL, gender: NULL,  money: 123.45,  score: NULL, luckyTime: NULL})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst,followness} =
      (1,2,77),
      (4,3,100)
      USE repair_index_graph
      FOR r IN t
      MATCH (a@person) WHERE a.id = r.src
      MATCH (b@person) WHERE b.id = r.dst
      INSERT (a)-[@follow{followness:r.followness}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      USE repair_index_graph CREATE INDEX IF NOT EXISTS person_name_idx ON NODE person(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE repair_index_graph CREATE INDEX IF NOT EXISTS person_age_idx ON NODE person(age)
      """
    Then the execution should be successful
    When executing query:
      """
      USE repair_index_graph CREATE INDEX IF NOT EXISTS follow_followness ON EDGE follow(followness)
      """
    Then the execution should be successful
    When executing query:
      """
      USE repair_index_graph REPAIR INDEX person_name_idx
      """
    Then the execution should be successful
    When executing query:
      """
      USE repair_index_graph REPAIR INDEX follow_followness
      """
    Then the execution should be successful
    And index "person_name_idx" of "repair_index_graph" should be ready to use
    And index "person_age_idx" of "repair_index_graph" should be ready to use
    And index "follow_followness" of "repair_index_graph" should be ready to use
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE repair_index_graph
      MATCH (v:person {id:3})
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 3  | "Jerry" |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE repair_index_graph
      MATCH (v:person) WHERE v.name IS NULL
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name |
      | 5  | NULL |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE repair_index_graph
      MATCH (v:person) WHERE v.name > "ABC"
      RETURN v.id AS id, v.name AS name
      """
    Then the result should be, in any order:
      | id | name    |
      | 1  | "Lee"   |
      | 2  | "Tom"   |
      | 3  | "Jerry" |
      | 4  | "Biden" |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE repair_index_graph
      MATCH (v:person) WHERE v.age >= 18 AND v.age < 25
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 3  | "Jerry" | 22  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE repair_index_graph
      MATCH (v:person) WHERE v.age < 18 OR v.age >= 22 AND v.age < 35
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name    | age |
      | 1  | "Lee"   | 16  |
      | 2  | "Tom"   | 25  |
      | 3  | "Jerry" | 22  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE repair_index_graph
      MATCH (v:person) WHERE v.age IS NULL
      RETURN v.id AS id, v.name AS name, v.age AS age
      """
    Then the result should be, in any order:
      | id | name | age  |
      | 5  | NULL | NULL |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE repair_index_graph
      MATCH (v:person)-[e:follow{followness:77}]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness
      """
    Then the result should be, in any order:
      | src | dst | followness |
      | 1   | 2   | 77         |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_edge_to_edge_scan=off") */
      USE repair_index_graph
      MATCH (v:person)-[e:follow WHERE e.followness > 20 AND e.followness <= 100]->(v2:person)
      RETURN v.id as src, v2.id as dst, e.followness as followness
      """
    Then the result should be, in any order:
      | src | dst | followness |
      | 1   | 2   | 77         |
      | 4   | 3   | 100        |
    And drop the index "person_name_idx" of "repair_index_graph"
    And drop the index "follow_followness" of "repair_index_graph"
    And drop the graph "repair_index_graph"
    And drop the graph type "repair_graph_type"

  Scenario: Stats task
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS stats_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS stats_index_graph TYPED stats_graph_type
      """
    Then the execution should be successful
    And graph "stats_index_graph" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS stats_index_graph_bk TYPED stats_graph_type
      """
    Then the execution should be successful
    And graph "stats_index_graph_bk" should be ready to use
    When executing raw query:
      """
      SUBMIT JOB STATS not_exist_graph
      """
    Then an Error should be raised: "[01G03]: Graph `not_exist_graph` not found in schema `/default_schema`"
    When executing query:
      """
      USE stats_index_graph INSERT (@node_type_player{id:1, name: "Goku"}), (@node_type_player{id:2, name: "Vegeta"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE stats_index_graph
      MATCH (a@node_type_player{id: 1}),(b@node_type_player{id: 2})
      INSERT (a)-[@edge_type_follow{followness: 10, age: 1}]->(b)
      """
    Then the execution should be successful
    And wait "1" seconds
    When executing raw query:
      """
      SUBMIT JOB STATS stats_index_graph
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing raw query:
      """
      CALL stats('stats_index_graph_bk') RETURN *
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing raw query:
      """
      CALL stats() RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `stats`: at least 1 argument(s) required"
    When executing raw query:
      """
      CALL stats(1) RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `stats`: argument `1` is of type `INT32` instead of the expected `STRING`"
    And stats of graph "stats_index_graph" should be ready
    And stats of graph "stats_index_graph_bk" should be ready
    When executing raw query:
      """
      USE stats_index_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name         | element_type | total_num |
      | "Edge Total"       | "Edge"       | 1         |
      | "Node Total"       | "Node"       | 2         |
      | "edge_type_follow" | "Edge"       | 1         |
      | "node_type_player" | "Node"       | 2         |
    When executing raw query:
      """
      USE stats_index_graph SHOW VERBOSE STATS
      """
    Then the execution should be successful
    When executing raw query:
      """
      CALL show_verbose_stats("stats_index_graph")
      RETURN entry_name, element_type, total_num
      """
    Then the result should be, in any order:
      | entry_name         | element_type | total_num |
      | "Edge Total"       | "Edge"       | 1         |
      | "Node Total"       | "Node"       | 2         |
      | "edge_type_follow" | "Edge"       | 1         |
      | "node_type_player" | "Node"       | 2         |
    When executing query:
      """
      CALL show_stats("stats_index_graph_bk")
      RETURN entry_name, element_type, total_num
      """
    Then the result should be, in any order:
      | entry_name         | element_type | total_num |
      | "Edge Total"       | "Edge"       | 0         |
      | "Node Total"       | "Node"       | 0         |
      | "edge_type_follow" | "Edge"       | 0         |
      | "node_type_player" | "Node"       | 0         |
    When executing query:
      """
      CALL show_stats() RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `show_stats`: at least 1 argument(s) required"
    When executing query:
      """
      CALL show_stats(1) RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `show_stats`: argument `1` is of type `INT32` instead of the expected `STRING`"
    When executing raw query:
      """
      /*+ SET_VAR(task_concurrency = 1) */
      SUBMIT JOB STATS stats_index_graph
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    And drop the graph "stats_index_graph_bk"
    And drop the graph "stats_index_graph"
    And drop the graph type "stats_graph_type"

  Scenario: Stop job
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS stop_job_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE edge_type_follow (node_type_player)-[LABEL follow {followness INT, age INT}]->(node_type_player)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS stop_job_graph TYPED stop_job_type
      """
    Then the execution should be successful
    And graph "stop_job_graph" should be ready to use
    When executing raw query:
      """
      SUBMIT JOB STATS stop_job_graph
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    And stats of graph "stop_job_graph" should be ready
    # When executing raw query:
    # """
    # STOP JOB 1
    # """
    # Then an Error should be raised: "[NJ006]: Job has already stopped: `1`"
    When executing query:
      """
      STOP JOB 34567
      """
    Then an Error should be raised: "[NJ002]: Can't find Job 34567"
    And drop the graph "stop_job_graph"
    And drop the graph type "stop_job_type"

  @sf01
  Scenario: export job
    # ldbc graph has a vector property
    When executing raw query:
      """
      SUBMIT JOB EXPORT TO CSV ldbc
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing raw query:
      """
      SUBMIT JOB EXPORT TO CSV sf01
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    And wait "10" seconds
    When executing raw query:
      """
      CALL show_all_job() FILTER state = "FAILED" RETURN job_id
      """
    Then the result should be, in any order:
      | job_id |
