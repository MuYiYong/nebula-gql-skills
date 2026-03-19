# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Session

  Scenario: session close
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_current_session() RETURN id NEXT call kill_session(id) FINISH
      """
    Then an Error should be raised: "[NR402]: Kill session failed: Can not kill self"
    When executing query:
      """
      CALL show_current_session() RETURN id NEXT call kill_session(id, false) FINISH
      """
    Then the execution should be successful
    And close the current session

  Scenario: session set timezone
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET TIME ZONE "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET timezone = "America/New_York"
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_current_session() YIELD timezone RETURN timezone
      """
    Then the result should be, in any order:
      | timezone           |
      | "America/New_York" |
    When executing query:
      """
      SESSION RESET timezone
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET timezone = "invalid timezone"
      """
    Then an Error should be raised: "[NV003]: Config data error: invalid timezone not found in timezone database"
    And close the current session

  Scenario: session set schema
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /home/session_test_user1
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /home/session_test_user1
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA IF EXISTS /home/session_test_user1
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_SCHEMA
      """
    Then the result should be, in any order:
      | path | owner |
    # NOTE: Using backticks (``) or double quotes ("") to represent a schema path will be deprecated in the future.
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS `/home/session_test_user1`
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA "/home/session_test_user1"
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_SCHEMA
      """
    Then the result should be, in any order:
      | path                       | owner  |
      | "/home/session_test_user1" | "root" |
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should not contain:
      | name                      | graph_type                     | schema                     | owner  | extra |
      | "session_test_user1_ldbc" | "session_test_user1_ldbc_type" | "/home/session_test_user1" | "root" | ""    |
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS session_test_user1_ldbc_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow {day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS session_test_user1_ldbc TYPED session_test_user1_ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                      | graph_type                     | schema                     | owner  | extra |
      | "session_test_user1_ldbc" | "session_test_user1_ldbc_type" | "/home/session_test_user1" | "root" | ""    |
    When executing query:
      """
      USE session_test_user1_ldbc INSERT
      (:player{id:1, name:"Tim"}),
      (:player{id:2, name:"Jerry"}),
      (:player{id:3, name:"Kyle"}),
      (:player{id:4, name:"Yao"})
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE session_test_user1_ldbc
      MATCH (a:player{id:1}), (b:player{id:2}), (c:player{id:3})
      INSERT
      (a)-[:follow{day:10}]->(b),
      (b)-[:follow{day:20}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE session_test_user1_ldbc MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE ldbc MATCH (v) LIMIT 10 RETURN v
      """
    Then an Error should be raised: "[01G03]: Graph `ldbc` not found in schema `/home/session_test_user1`"
    When executing query:
      """
      SESSION SET GRAPH session_test_user1_ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_current_session() YIELD `schema` AS schema_path, `graph` AS graph_name
      RETURN schema_path, graph_name
      """
    Then the result should be, in any order:
      | schema_path                | graph_name                                         |
      | "/home/session_test_user1" | "/home/session_test_user1/session_test_user1_ldbc" |
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH session_test_user1_ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_current_session() YIELD `schema` AS schema_path, `graph` AS graph_name
      RETURN schema_path, graph_name
      """
    Then the result should be, in any order:
      | schema_path                | graph_name |
      | "/home/session_test_user1" | ""         |
    When executing query:
      """
      DROP GRAPH TYPE session_test_user1_ldbc_type
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA /home/session_test_user1
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_current_session() YIELD `schema` AS schema_path, `graph` AS graph_name
      RETURN schema_path, graph_name
      """
    Then the result should be, in any order:
      | schema_path | graph_name |
      | ""          | ""         |
    When executing query:
      """
      SESSION RESET SCHEMA
      """
    Then the execution should be successful
    And close the current session

  Scenario: session set graph
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET GRAPH ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then the result should be, in any order:
      | src | dst |
      | 2   | 2   |
      | 2   | 2   |
      | 4   | 4   |
      | 3   | 3   |
      | 3   | 3   |
    When executing query:
      """
      SESSION RESET GRAPH
      """
    Then the execution should be successful
    When executing query:
      """
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing query:
      """
      SESSION SET GRAPH "invalidGraph"
      """
    Then an Error should be raised: "[01G03]: Graph `invalidGraph` not found in schema `/default_schema`"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS to_be_delete_type AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS to_be_delete_graph TYPED to_be_delete_type
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET GRAPH "to_be_delete_graph"
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH to_be_delete_graph
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS to_be_delete_type_1 AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then the execution should be successful
    And drop the graph type "to_be_delete_type"
    And drop the graph type "to_be_delete_type_1"
    And close the current session

  Scenario: session set and show datetime formats
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET local_datetime_format = "%H:%M:%S"
      """
    Then an Error should be raised: "[NV003]: Config data error: local_datetime_format missing the required: %Y or %y for years."
    When executing query:
      """
      SESSION SET local_datetime_format = "%H:%M:%S %Y"
      """
    Then an Error should be raised: "[NV003]: Config data error: local_datetime_format missing the required: %m for months."
    When executing query:
      """
      SESSION SET local_datetime_format = "%H:%M:%S %Y-%m"
      """
    Then an Error should be raised: "[NV003]: Config data error: local_datetime_format missing the required: %d for days."
    When executing query:
      """
      SESSION SET local_datetime_format = "%Y%m%dT%H:%M:%S"
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION RESET local_datetime_format
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN DATETIME "2024-05-14 11:47:30"
      """
    Then an Error should be raised: "[22009]: Parse DATETIME (either local or zoned): `2024-05-14 11:47:30` fail"
    When executing query:
      """
      RETURN DATETIME "2024-05-14T11:47:30"
      """
    Then the result should be, in any order:
      | DATETIME "2024-05-14T11:47:30"        |
      | DATETIME "2024-05-14T11:47:30.000000" |
    When executing query:
      """
      RETURN TIME "11:47:30"
      """
    Then the result should be, in any order:
      | TIME "11:47:30"        |
      | TIME "11:47:30.000000" |
    When executing query:
      """
      RETURN TIME "11:47:30Z"
      """
    Then the result should be, in any order:
      | TIME "11:47:30Z"             |
      | ZONED TIME "19:47:30.000000" |
    When executing query:
      """
      RETURN DATE "2024-05-14"
      """
    Then the result should be, in any order:
      | DATE "2024-05-14" |
      | DATE "2024-05-14" |
    When executing query:
      """
      RETURN DATE "2024-05-14Z"
      """
    Then an Error should be raised: "[22009]: Parse Date: `2024-05-14Z` fail"
    When executing query:
      """
      RETURN DATE "05-14-2014"
      """
    Then an Error should be raised: "[22009]: Parse Date: `05-14-2014` fail"
    When executing query:
      """
      SHOW CURRENT_SESSION TIME FORMATS
      """
    Then the result should be, in any order:
      | date_format | local_time_format | zoned_time_format | local_datetime_format | zoned_datetime_format  |
      | "%Y-%m-%d"  | "%H:%M:%S"        | "%H:%M:%S %z"     | "%Y-%m-%dT%H:%M:%S"   | "%Y-%m-%dT%H:%M:%S %z" |
    And close the current session

  Scenario: session set list
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET timezone = "America/New_York"
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_current_session()  RETURN timezone
      """
    Then the result should be, in any order:
      | timezone           |
      | "America/New_York" |
    And close the current session

  Scenario: invalid session set
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET GRAPH "ldbc" MATCH (v) RETURN v
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
    When executing query:
      """
      SESSION SET SCHEMA /default_schema MATCH (v) RETURN v
      """
    Then an Error should be raised: "[42N57]: Commands can only appear as top-level command statements without mixing"
    And close the current session

  Scenario: session set temporary schema and graph
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SESSION SET SCHEMA /tmp_schema
      """
    Then an Error should be raised: "[NS000]: Semantic error: The schema `/tmp_schema` is reserved and cannot be used"
    When executing query:
      """
      SESSION SET GRAPH #analytic_ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_GRAPH
      """
    Then the result should be, in any order:
      | name             | graph_type  | schema        | owner  | extra               |
      | "#analytic_ldbc" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      USE /tmp_schema/#analytic_ldbc MATCH (v) return count(v)
      """
    Then an Error should be raised: "[42001]: syntax error near `#analytic_ldbc`"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /test_session_set_schema
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /test_session_set_schema
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_SCHEMA
      """
    Then the result should be, in any order:
      | path                       | owner  |
      | "/test_session_set_schema" | "root" |
    When executing query:
      """
      SHOW CURRENT_GRAPH
      """
    Then the result should be, in any order:
      | name             | graph_type  | schema        | owner  | extra               |
      | "#analytic_ldbc" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      SESSION RESET SCHEMA
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA IF EXISTS /test_session_set_schema
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_SCHEMA
      """
    Then the result should be, in any order:
      | path              | owner  |
      | "/default_schema" | "root" |
    And close the current session

  Scenario: show current user
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_current_user() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should be, in any order:
      | name   | home_schema       | home_graph |
      | "root" | "/default_schema" | ""         |
    When executing query:
      """
      CALL show_current_session() RETURN username, `schema`, `graph`
      """
    Then the result should be, in any order:
      | username | schema            | graph |
      | "root"   | "/default_schema" | ""    |
    When executing query:
      """
      SESSION SET GRAPH ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_GRAPH
      """
    Then the result should be, in any order:
      | name   | graph_type  | schema            | owner  | extra |
      | "ldbc" | "ldbc_type" | "/default_schema" | "root" | ""    |
    When executing query:
      """
      CALL show_current_session() RETURN username, `schema`, `graph`
      """
    Then the result should be, in any order:
      | username | schema            | graph                  |
      | "root"   | "/default_schema" | "/default_schema/ldbc" |
    When executing query:
      """
      SESSION SET GRAPH #analytic_ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_GRAPH
      """
    Then the result should be, in any order:
      | name             | graph_type  | schema        | owner  | extra               |
      | "#analytic_ldbc" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      CALL show_current_session() RETURN username, `schema`, `graph`
      """
    Then the result should be, in any order:
      | username | schema            | graph                        |
      | "root"   | "/default_schema" | "/tmp_schema/#analytic_ldbc" |
    When executing query:
      """
      CALL show_current_user() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should be, in any order:
      | name   | home_schema       | home_graph |
      | "root" | "/default_schema" | ""         |
    When executing query:
      """
      SESSION RESET GRAPH
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_current_session() RETURN username, `schema`, `graph`
      """
    Then the result should be, in any order:
      | username | schema            | graph |
      | "root"   | "/default_schema" | ""    |
    And close the current session

  Scenario: vesoft-inc/nebula-ng#8960
    And create a new user session with username "user_8960" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /test_schema_8960
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /test_schema_8960
      """
    Then the execution should be successful
    When executing query:
      """
      MATCH (v) RETURN count(v)
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing query:
      """
      SESSION SET GRAPH /default_schema/ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      MATCH (v) RETURN count(v) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 34  |
    When executing query:
      """
      MATCH (v) RETURN v LIMIT 1
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION RESET GRAPH
      """
    Then the execution should be successful
    When executing query:
      """
      MATCH (v) RETURN count(v)
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing query:
      """
      ALTER USER user_8960 SET HOME_GRAPH /default_schema/ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_GRAPH
      """
    Then the result should be, in any order:
      | name   | graph_type  | schema            | owner  | extra |
      | "ldbc" | "ldbc_type" | "/default_schema" | "root" | ""    |
    When executing query:
      """
      MATCH (v) RETURN count(v) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 34  |
    When executing query:
      """
      SESSION RESET GRAPH
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CURRENT_GRAPH
      """
    Then the result should be, in any order:
      | name   | graph_type  | schema            | owner  | extra |
      | "ldbc" | "ldbc_type" | "/default_schema" | "root" | ""    |
    When executing query:
      """
      MATCH (v) RETURN count(v) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 34  |
    When executing query:
      """
      MATCH (v) RETURN v LIMIT 1
      """
    Then the execution should be successful
    When executing query:
      """
      DROP SCHEMA IF EXISTS /test_schema_8960
      """
    Then the execution should be successful
    And close current session and drop the user "user_8960"

  Scenario: vesoft-inc/nebula-ng#9012
    And create a new user session with username "user_9012" and password "NebulaGraph01"
    When executing query:
      """
      CALL dbms.show_queries() RETURN username
      """
    Then the result should be, in order:
      | username    |
      | "user_9012" |
    When executing query:
      """
      CALL dbms.show_sessions() RETURN username
      """
    Then the result should be, in order:
      | username    |
      | "user_9012" |
    And close current session and drop the user "user_9012"
