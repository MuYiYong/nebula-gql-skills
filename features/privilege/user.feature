# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: PrivilegeToUser

  Scenario: privilege constraint
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_constraint",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_constraint" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER  user_constraint
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON SCHEMA /default_schema TO USER user_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `MATCH` on `SCHEMA`"
    When executing query:
      """
      GRANT INSERT ANY GRAPH, MATCH ANY GRAPH, EXECUTE ON SCHEMA /default_schema TO USER user_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `EXECUTE` on `SCHEMA`"
    When executing query:
      """
      GRANT MATCH, ALTER ON GRAPH TYPE /default_schema/ldbc_type TO USER user_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `MATCH` on `GRAPH_TYPE`"
    When executing query:
      """
      GRANT MATCH, EXECUTE ON GRAPH /default_schema/ldbc TO USER user_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `EXECUTE` on `GRAPH`"
    When executing query:
      """
      GRANT INSERT, MATCH ANY GRAPH, UPDATE ON NODE TYPE /default_schema/ldbc.Person TO USER user_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `MATCH_ANY_GRAPH` on `NODE_TYPE`"
    When executing query:
      """
      GRANT DELETE, EXECUTE ANY PROCEDURE, MATCH ON EDGE TYPE /default_schema/ldbc.KNOWS TO USER user_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `EXECUTE_ANY_PROCEDURE` on `EDGE_TYPE`"
    When executing query:
      """
      GRANT MATCH, EXECUTE ON NODE PROPERTY /default_schema/ldbc.Person.firstName TO USER user_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `EXECUTE` on `NODE_PROPERTY`"
    When executing query:
      """
      GRANT MATCH ANY GRAPH, INSERT ANY GRAPH, DELETE ANY GRAPH ON SCHEMA /default_schema TO USER user_constraint
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT DELETE, MATCH, UPDATE, INSERT ON EDGE TYPE /default_schema/ldbc.KNOWS TO USER user_constraint
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_constraint"
    And logout from the meta

  Scenario: user only has connect
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_only_connect",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_only_connect" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER  user_only_connect
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ROLE ADMIN TO USER  user_only_connect
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Can not grant/revoke ADMIN to/from user"
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_test
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_only_connect" should be granted
    And switch to a new session with username "user_only_connect" and password "NebulaGraph01"
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_only_read_1
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can create role"
    And role "role_test" should be ready to use
    When executing query:
      """
      DROP ROLE role_test
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can drop role `role_test`"
    When executing query:
      """
      CREATE SCHEMA /home/schema1
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_SCHEMA] on CATALOG "
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_privilege_type AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH_TYPE] on SCHEMA /default_schema"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    When executing query:
      """
      USE ldbc MATCH (v:Person) LIMIT 10 RETURN v.locationIP
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.locationIP"
    When executing query:
      """
      USE ldbc MATCH ()-[e:KNOWS]->() LIMIT 10 RETURN e.creationDate
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/ldbc.KNOWS.creationDate"
    When executing query:
      """
      USE ldbc INSERT (:Tag{id:1, name:"tag", url:"www.vesoft.com"})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/ldbc.Tag.id"
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS  test_create_plugin_1
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute create_plugin"
    When executing query:
      """
      DROP PLUGIN IF EXISTS  dbms
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute drop_plugin"
    When executing query:
      """
      SUBMIT job EXPORT TO CSV
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute export_csv"
    When executing query:
      """
      EXPORT SCHEMA
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute export_schema"
    When executing query:
      """
      GRANT CONNECT TO USER "root"
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_only_connect"
    And logout from the meta

  Scenario: create schema
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_create_schema",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_schema" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_create_schema
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE SCHEMA TO USER user_create_schema
      """
    Then the execution should be successful
    And action "CREATE_SCHEMA" on "CATALOG" for user "user_create_schema" should be granted
    And switch to a new session with username "user_create_schema" and password "NebulaGraph01"
    When executing raw query:
      """
      SHOW CURRENT_SCHEMA
      """
    Then the result should contain:
      | path              | owner  |
      | "/default_schema" | "root" |
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /home/user_create_schema
      """
    Then the execution should be successful
    When executing raw query:
      """
      SHOW SCHEMAS
      """
    Then the result should contain:
      | path                       | owner                |
      | "/home/user_create_schema" | "user_create_schema" |
    When executing query:
      """
      SESSION SET SCHEMA /home/user_create_schema
      """
    Then the execution should be successful
    When executing raw query:
      """
      SHOW CURRENT_SCHEMA
      """
    Then the result should contain:
      | path                       | owner                |
      | "/home/user_create_schema" | "user_create_schema" |
    When executing raw query:
      """
      SHOW OBJECTS
      """
    Then the result should contain:
      | type     | name                       |
      | "SCHEMA" | "/home/user_create_schema" |
    When executing query:
      """
      ALTER OWNER SCHEMA /home/user_create_schema TO USER user_create_schema
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER OWNER SCHEMA ../../home/user_create_schema TO USER root
      """
    Then the execution should be successful
    And wait "2" seconds
    When executing raw query:
      """
      SHOW CURRENT_SCHEMA
      """
    Then the result should contain:
      | path                       | owner  |
      | "/home/user_create_schema" | "root" |
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE CREATE SCHEMA FROM USER user_create_schema
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER OWNER SCHEMA "/home/user_create_schema" TO USER user_create_schema
      """
    Then the execution should be successful
    And wait "2" seconds
    And action "CREATE_SCHEMA" on "CATALOG" for user "user_create_schema" should be revoked
    And switch to a new session with username "user_create_schema" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /home/user_create_schema
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_SCHEMA] on CATALOG "
    When executing query:
      """
      DROP SCHEMA /home/user_create_schema
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_create_schema"
    And logout from the meta

  Scenario: drop schema
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_drop_schema",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_drop_schema" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_drop_schema
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /home/user_drop_schema
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT DROP ON SCHEMA /home/user_drop_schema TO USER user_drop_schema
      """
    Then the execution should be successful
    And action "DROP" on "SCHEMA" for user "user_drop_schema" should be granted
    And switch to a new session with username "user_drop_schema" and password "NebulaGraph01"
    When executing raw query:
      """
      SHOW SCHEMAS
      """
    Then the result should contain:
      | path                     | owner  |
      | "/home/user_drop_schema" | "root" |
    When executing query:
      """
      DROP SCHEMA /home/user_drop_schema
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_drop_schema"
    And logout from the meta

  Scenario: create graph type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_create_graph_type",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_graph_type" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_create_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE ON SCHEMA /default_schema TO USER user_create_graph_type
      """
    Then the execution should be successful
    And action "CREATE_GRAPH_TYPE" on "SCHEMA" for user "user_create_graph_type" should be granted
    And switch to a new session with username "user_create_graph_type" and password "NebulaGraph01"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_privilege_type AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER GRAPH TYPE test_privilege_type {
        RENAME NODE TYPE node_type TO person,
        RENAME EDGE TYPE edge_type TO follow
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED test_privilege_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    When executing query:
      """
      USE ldbc
      MATCH ()-[e:KNOWS]->()
      RETURN count(e) AS num GROUP BY ()
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/ldbc.KNOWS.vec"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE CREATE GRAPH TYPE ON SCHEMA /default_schema FROM USER user_create_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE ON SCHEMA ../default_schema TO USER user_create_graph_type
      """
    Then the execution should be successful
    When executing query:
      """
      REVOKE CREATE GRAPH TYPE ON SCHEMA ../default_schema FROM USER user_create_graph_type
      """
    Then the execution should be successful
    And action "CREATE_GRAPH_TYPE" on "SCHEMA" for user "user_create_graph_type" should be revoked
    And switch to a new session with username "user_create_graph_type" and password "NebulaGraph01"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_privilege_type AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH_TYPE] on SCHEMA /default_schema"
    And drop the graph type "test_privilege_type"
    And close the current session

  Scenario: create graph
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_create_graph",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_graph" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_create_graph
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH ON SCHEMA /default_schema TO USER user_create_graph
      """
    Then the execution should be successful
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_create_graph" should be granted
    And switch to a new session with username "user_create_graph" and password "NebulaGraph01"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS privilege_nba_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS privilege_nba TYPED privilege_nba_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE privilege_nba INSERT
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
      USE privilege_nba
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
    When executing raw query:
      """
      SUBMIT JOB STATS privilege_nba
      """
    Then the result should be, in any order:
      | job_id |
      | /.*/   |
    When executing query:
      """
      USE privilege_nba MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE privilege_nba MATCH (v)-[e:follow]->(b)
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    And stats of graph "privilege_nba" should be ready
    When executing raw query:
      """
      SHOW STATS privilege_nba
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Edge Total" | "Edge"       | 2         |
      | "Node Total" | "Node"       | 4         |
      | "edge_type"  | "Edge"       | 2         |
      | "node_type"  | "Node"       | 4         |
    When executing query:
      """
      USE privilege_nba CREATE INDEX IF NOT EXISTS privilege_nba_index ON NODE node_type(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE privilege_nba REPAIR INDEX privilege_nba_index
      """
    Then the execution should be successful
    When executing query:
      """
      USE privilege_nba DROP INDEX IF EXISTS privilege_nba_index
      """
    Then the execution should be successful
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE CREATE GRAPH ON SCHEMA /default_schema FROM USER user_create_graph
      """
    Then the execution should be successful
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_create_graph" should be revoked
    And switch to a new session with username "user_create_graph" and password "NebulaGraph01"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS privilege_nba TYPED privilege_nba_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    When executing query:
      """
      USE privilege_nba MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE privilege_nba
      MATCH (v:player{id:1})
      SET v.name = "new name Tim"
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE privilege_nba
      MATCH (v:player{id:1})-[e:follow]->(b)
      SET e.day = 15
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE privilege_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE a,r
      """
    Then the execution should be successful
    When executing query:
      """
      RENAME GRAPH privilege_nba TO rename_privilege_nba
      """
    Then the execution should be successful
    And drop the graph "rename_privilege_nba"
    And drop the graph type "privilege_nba_type"
    And close the current session

  Scenario: grant graph privilege to other user
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_graph_owner",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    When create a new user:
      """
      {
        "username": "user_graph_usage",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_graph_owner" should be ready to use
    And user "user_graph_usage" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_graph_usage
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH ON SCHEMA /default_schema TO USER user_graph_owner
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER user_graph_owner
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_graph_owner" should be granted
    And switch to a new session with username "user_graph_owner" and password "NebulaGraph01"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS graph_owner_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS owner_nba TYPED graph_owner_type
      """
    Then the execution should be successful
    # grant match to user
    When executing query:
      """
      GRANT INDEX, MATCH, INSERT, UPDATE, DELETE, ALTER ON GRAPH /default_schema/owner_nba TO USER user_graph_usage
      """
    Then the execution should be successful
    And switch to a new session with username "user_graph_usage" and password "NebulaGraph01"
    And action "MATCH" on "GRAPH" for user "user_graph_usage" should be granted
    When executing query:
      """
      USE owner_nba INSERT
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
      USE owner_nba
      MATCH  (a:player{id:1}), (b:player{id:2}), (c:player{id:3})
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
      USE owner_nba MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE owner_nba MATCH (v)-[e:follow]->(b)
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    When executing query:
      """
      USE owner_nba
      MATCH (v:player{id:1})
      SET v.name = "new name Tim"
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE owner_nba
      MATCH (v:player{id:1})-[e:follow]->(b)
      SET e.day = 15
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE owner_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE a,r
      """
    Then the execution should be successful
    When executing query:
      """
      USE owner_nba CREATE INDEX IF NOT EXISTS owner_nba_index ON NODE node_type(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE owner_nba REPAIR INDEX owner_nba_index
      """
    Then the execution should be successful
    When executing query:
      """
      RENAME GRAPH owner_nba TO rename_owner_nba
      """
    Then the execution should be successful
    # revoke privilege
    And switch to a new session with username "user_graph_owner" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE INDEX, INSERT, UPDATE, DELETE, ALTER ON GRAPH /default_schema/rename_owner_nba FROM USER user_graph_usage
      """
    Then the execution should be successful
    And switch to a new session with username "user_graph_usage" and password "NebulaGraph01"
    And action "INSERT" on "GRAPH" for user "user_graph_usage" should be revoked
    When executing query:
      """
      USE rename_owner_nba INSERT (@node_type{id:1, name:"Tim"})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/rename_owner_nba.node_type.id"
    When executing query:
      """
      USE rename_owner_nba
      MATCH (a:player{id:2}), (b:player{id:3})
      INSERT (a)-[:follow{day:23}]->(b)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on EDGE_PROPERTY /default_schema/rename_owner_nba.edge_type.day"
    When executing query:
      """
      USE rename_owner_nba
      MATCH (v:player{id:1})
      SET v.name = "new name Tim"
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [UPDATE] on NODE_PROPERTY /default_schema/rename_owner_nba.node_type.name"
    When executing query:
      """
      USE rename_owner_nba
      MATCH (v:player{id:1})-[e:follow]->(b)
      SET e.day = 15
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [UPDATE] on EDGE_PROPERTY /default_schema/rename_owner_nba.edge_type.day"
    When executing query:
      """
      USE rename_owner_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE a
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DELETE] on NODE_TYPE /default_schema/rename_owner_nba.node_type"
    When executing query:
      """
      USE rename_owner_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE r
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DELETE] on EDGE_TYPE /default_schema/rename_owner_nba.edge_type"
    When executing query:
      """
      USE rename_owner_nba CREATE INDEX IF NOT EXISTS owner_nba_index ON NODE node_type(name)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/rename_owner_nba"
    When executing query:
      """
      USE rename_owner_nba REPAIR INDEX owner_nba_index
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/rename_owner_nba"
    When executing query:
      """
      USE rename_owner_nba DROP INDEX IF EXISTS owner_nba_index
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/rename_owner_nba"
    When executing query:
      """
      RENAME GRAPH rename_owner_nba TO owner_nba
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [ALTER] on GRAPH /default_schema/rename_owner_nba"
    And switch to a new session with username "user_graph_owner" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ON GRAPH /default_schema/rename_owner_nba FROM USER user_graph_usage
      """
    Then the execution should be successful
    And switch to a new session with username "user_graph_usage" and password "NebulaGraph01"
    And action "MATCH" on "GRAPH" for user "user_graph_usage" should be revoked
    When executing query:
      """
      USE rename_owner_nba MATCH (v:player) RETURN v.name
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/rename_owner_nba.node_type.name"
    When executing query:
      """
      USE rename_owner_nba MATCH (v)-[e:follow]->(b)
      RETURN count(e) AS num GROUP BY ()
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/rename_owner_nba.edge_type.day"
    And switch to a new session with username "user_graph_owner" and password "NebulaGraph01"
    And drop the index "owner_nba_index" of "rename_owner_nba"
    And drop the graph "rename_owner_nba"
    And drop the graph type "graph_owner_type"
    And drop the graph type "owner_nba_type"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_graph_owner"
    And drop the user "user_graph_usage"
    And logout from the meta

  Scenario: match any graph on schema
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_match_any_graph",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_any_graph" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_any_graph
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ANY GRAPH ON SCHEMA /default_schema TO USER user_match_any_graph
      """
    Then the execution should be successful
    And action "MATCH_ANY_GRAPH" on "SCHEMA" for user "user_match_any_graph" should be granted
    And switch to a new session with username "user_match_any_graph" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then the result should be, in any order:
      | src | dst |
      | 2   | 2   |
      | 3   | 3   |
      | 4   | 4   |
      | 2   | 2   |
      | 3   | 3   |
    When executing query:
      """
      USE ldbc
      FOR i IN LIST[abs(1), abs(2), abs(3)]
      OPTIONAL MATCH (v:Person{firstName:"not exist"})
      RETURN i, v.id AS b
      """
    Then the result should be, in any order:
      | i | b    |
      | 1 | NULL |
      | 2 | NULL |
      | 3 | NULL |
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_privilege_type AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH_TYPE] on SCHEMA /default_schema"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    When executing query:
      """
      USE ldbc INSERT (:Tag{id:1, name:"tag", url:"www.vesoft.com"})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/ldbc.Tag.id"
    When executing query:
      """
      USE ldbc MATCH (v IS Person WHERE v.id IN LIST[2, 3 , 4, 888]) DELETE v
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DELETE] on NODE_TYPE /default_schema/ldbc.Person"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ANY GRAPH ON SCHEMA /default_schema FROM USER user_match_any_graph
      """
    Then the execution should be successful
    And action "MATCH_ANY_GRAPH" on "SCHEMA" for user "user_match_any_graph" should be revoked
    And switch to a new session with username "user_match_any_graph" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_match_any_graph"
    And logout from the meta

  Scenario: match on graph
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_match",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON GRAPH /default_schema/ldbc TO USER user_match
      """
    Then the execution should be successful
    And action "MATCH" on "GRAPH" for user "user_match" should be granted
    And switch to a new session with username "user_match" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then the result should be, in any order:
      | src | dst |
      | 2   | 2   |
      | 3   | 3   |
      | 4   | 4   |
      | 2   | 2   |
      | 3   | 3   |
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    When executing query:
      """
      USE ldbc INSERT (:Tag{id:1, name:"tag", url:"www.vesoft.com"})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/ldbc.Tag.id"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ON GRAPH /default_schema/ldbc FROM USER user_match
      """
    Then the execution should be successful
    And action "MATCH" on "GRAPH" for user "user_match" should be revoked
    And switch to a new session with username "user_match" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_match"
    And logout from the meta

  Scenario: match on node type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_match_node_type",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_node_type" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_node_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON NODE TYPE /default_schema/ldbc.Person TO USER user_match_node_type
      """
    Then the execution should be successful
    And action "MATCH" on "NODE_TYPE" for user "user_match_node_type" should be granted
    And switch to a new session with username "user_match_node_type" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])
      RETURN v.id as id
      """
    Then the result should be, in any order:
      | id |
      | 2  |
      | 3  |
      | 4  |
    When executing query:
      """
      USE ldbc
      MATCH TRAIL (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Cannot find privilege for Action [MATCH] on any EDGE_PROPERTY of EDGE_TYPE /default_schema/ldbc.KNOWS"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Cannot find privilege for Action [MATCH] on any EDGE_PROPERTY of EDGE_TYPE /default_schema/ldbc.KNOWS"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ON NODE TYPE /default_schema/ldbc.Person FROM USER user_match_node_type
      """
    Then the execution should be successful
    And action "MATCH" on "NODE_TYPE" for user "user_match_node_type" should be revoked
    And switch to a new session with username "user_match_node_type" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])
      RETURN v.id as id
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    When executing query:
      """
      USE ldbc
      MATCH (v@Place) RETURN count(v) GROUP BY ()
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Cannot find privilege for Action [MATCH] on any NODE_PROPERTY of NODE_TYPE /default_schema/ldbc.Place"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_match_node_type"
    And logout from the meta

  Scenario: match on edge type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_match_edge_type",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_edge_type" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON EDGE TYPE /default_schema/ldbc.KNOWS TO USER user_match_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON EDGE TYPE /default_schema/ldbc.HAS_INTEREST TO USER user_match_edge_type
      """
    Then the execution should be successful
    And action "MATCH" on "EDGE_TYPE" for user "user_match_edge_type" should be granted
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->(b)
      RETURN v.id as src, b.id as dst
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_edge_type" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH ()-[e:KNOWS]->()
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 3   |
    When executing query:
      """
      USE ldbc
      MATCH ()-[e:HAS_INTEREST]->()
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 3   |
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    When executing query:
      """
      USE ldbc
      MATCH ()-[e:HAS_TYPE]->()
      RETURN e
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_TYPE /default_schema/ldbc.HAS_TYPE"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    Then the execution should be successful
    When executing query:
      """
      REVOKE MATCH ON EDGE TYPE /default_schema/ldbc.KNOWS FROM USER user_match_edge_type
      """
    Then the execution should be successful
    And action "MATCH" on "EDGE_TYPE" for user "user_match_edge_type" should be revoked
    And switch to a new session with username "user_match_edge_type" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH ()-[e:KNOWS]->()
      RETURN COUNT(e) AS num GROUP BY ()
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/ldbc.KNOWS.vec"
    And close the current session

  Scenario: match on edge type and node type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_match_node_edge_type",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_node_edge_type" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_node_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON NODE TYPE /default_schema/ldbc.Person TO USER user_match_node_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON EDGE TYPE /default_schema/ldbc.KNOWS TO USER user_match_node_edge_type
      """
    Then the execution should be successful
    And action "MATCH" on "EDGE_TYPE" for user "user_match_node_edge_type" should be granted
    And switch to a new session with username "user_match_node_edge_type" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH ()-[e:KNOWS]->()
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 3   |
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then the result should be, in any order:
      | src | dst |
      | 2   | 2   |
      | 3   | 3   |
      | 4   | 4   |
      | 2   | 2   |
      | 3   | 3   |
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ON EDGE TYPE /default_schema/ldbc.KNOWS FROM USER user_match_node_edge_type
      """
    Then the execution should be successful
    And action "MATCH" on "EDGE_TYPE" for user "user_match_node_edge_type" should be revoked
    And switch to a new session with username "user_match_node_edge_type" and password "NebulaGraph01"
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->(b)
      RETURN v.id as src, b.id as dst, e.creationDate as dt
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/ldbc.KNOWS.creationDate"
    And close the current session

  Scenario: match on node property
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_match_node_property",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_node_property" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_node_property
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS node_property_type AS {
        NODE TYPE node_type (LABEL player {id INT PRIMARY KEY, name STRING, default_prop INT DEFAULT 10}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{day INT}]->(node_type)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS graph_node_property TYPED node_property_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT INSERT, MATCH, UPDATE ON NODE PROPERTY `graph_node_property`.node_type.id, graph_node_property.node_type.name TO USER user_match_node_property
      """
    Then the execution should be successful
    And action "MATCH" on "NODE_PROPERTY" for user "user_match_node_property" should be granted
    And switch to a new session with username "user_match_node_property" and password "NebulaGraph01"
    When executing query:
      """
      USE graph_node_property INSERT
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
      USE graph_node_property INSERT
      (:player{id:5, name:"Putin", default_prop:1}),
      (:player{id:6, name:"Biden", default_prop:2})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/graph_node_property.node_type.default_prop"
    When executing query:
      """
      USE graph_node_property
      MATCH (v WHERE v.id IN LIST[2, 3, 4, 888])
      RETURN v.id as id, v.name as name
      """
    Then the result should be, in any order:
      | id | name    |
      | 2  | "Jerry" |
      | 3  | "Kyle"  |
      | 4  | "Yao"   |
    When executing query:
      """
      USE graph_node_property
      MATCH (v WHERE v.id IN LIST[2, 3, 4, 888])
      RETURN v.default_prop
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/graph_node_property.node_type.default_prop"
    When executing query:
      """
      USE graph_node_property
      MATCH (v:player{id:1})
      SET v.name = "new name Tim"
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 1     |
      | "num_affected_edges" | 0     |
    When executing query:
      """
      USE graph_node_property
      MATCH (v:player{id:1})
      DELETE v
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DELETE] on NODE_TYPE /default_schema/graph_node_property.node_type"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH,INSERT ON NODE PROPERTY `graph_node_property`.node_type.id, graph_node_property.node_type.name FROM USER user_match_node_property
      """
    Then the execution should be successful
    And action "MATCH" on "NODE_PROPERTY" for user "user_match_node_property" should be revoked
    And switch to a new session with username "user_match_node_property" and password "NebulaGraph01"
    When executing query:
      """
      USE graph_node_property
      MATCH (v WHERE v.id IN LIST[2, 3, 4, 888])
      RETURN v.id as id
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/graph_node_property.node_type.id"
    When executing query:
      """
      USE graph_node_property INSERT (:player{id:5, name:"Trump"})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/graph_node_property.node_type.id"
    And switch to a new session with username "root" and password "NebulaGraph01"
    And drop the graph "graph_node_property"
    And drop the graph type "node_property_type"
    And close the current session

  Scenario: match on edge property
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_match_edge_property",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_edge_property" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_edge_property
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS edge_property_type AS {
        NODE TYPE node_type (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{plike INT, default_prop INT DEFAULT 10}]->(node_type)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS graph_edge_property TYPED edge_property_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT INSERT, MATCH ON NODE PROPERTY `graph_edge_property`.node_type.id, graph_edge_property.node_type.name TO USER user_match_edge_property
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT INSERT, MATCH, UPDATE ON EDGE PROPERTY `graph_edge_property`.edge_type.plike TO USER user_match_edge_property
      """
    Then the execution should be successful
    And action "MATCH" on "EDGE_PROPERTY" for user "user_match_edge_property" should be granted
    And switch to a new session with username "user_match_edge_property" and password "NebulaGraph01"
    When executing query:
      """
      USE graph_edge_property INSERT
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
      USE graph_edge_property
      MATCH  (a:player{id:1}), (b:player{id:2}), (c:player{id:3})
      INSERT
      (a)-[:follow{plike:10}]->(b),
      (b)-[:follow{plike:20}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE graph_edge_property
      MATCH  (a:player{id:2}), (b:player{id:4})
      INSERT
      (a)-[:follow{plike:10, default_prop:15}]->(b)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on EDGE_PROPERTY /default_schema/graph_edge_property.edge_type.default_prop"
    When executing query:
      """
      USE graph_edge_property
      MATCH (v)-[e:follow]->(b)
      RETURN e.plike as plike
      """
    Then the result should be, in any order:
      | plike |
      | 10    |
      | 20    |
    When executing query:
      """
      USE graph_edge_property
      MATCH (v)-[e:follow]->(b)
      RETURN e.plike as plike, e.default_prop
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/graph_edge_property.edge_type.default_prop"
    When executing query:
      """
      USE graph_edge_property
      MATCH (v:player{id:1})-[e:follow {plike:10}]->(b)
      SET e.plike = 15
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 0     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE graph_edge_property
      MATCH (a:player{id:1})-[r]-(b)
      DELETE r
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DELETE] on EDGE_TYPE /default_schema/graph_edge_property.edge_type"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH,INSERT ON EDGE PROPERTY "graph_edge_property".edge_type.plike FROM USER user_match_edge_property
      """
    Then the execution should be successful
    And action "MATCH" on "EDGE_PROPERTY" for user "user_match_edge_property" should be revoked
    And switch to a new session with username "user_match_edge_property" and password "NebulaGraph01"
    When executing query:
      """
      USE graph_edge_property
      MATCH (v)-[e:follow]->(b)
      RETURN e.plike as plike
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/graph_edge_property.edge_type.plike"
    When executing query:
      """
      USE graph_edge_property
      MATCH  (a:player{id:2}), (b:player{id:4})
      INSERT
      (a)-[:follow{plike:10}]->(b)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on EDGE_PROPERTY /default_schema/graph_edge_property.edge_type.plike"
    And switch to a new session with username "root" and password "NebulaGraph01"
    And drop the graph "graph_edge_property"
    And drop the graph type "edge_property_type"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_match_edge_property"
    And logout from the meta

  Scenario: alter owner
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_alter_owner",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_alter_owner" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_alter_owner
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS alter_owner_nba_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS alter_owner_nba TYPED alter_owner_nba_type
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER OWNER GRAPH alter_owner_nba TO USER user_alter_owner
      """
    Then the execution should be successful
    And switch to a new session with username "user_alter_owner" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_graphs() FILTER name = 'alter_owner_nba' RETURN graph_type, name, owner, `schema`, extra
      """
    Then the result should be, in any order:
      | graph_type             | name              | owner              | schema            | extra |
      | "alter_owner_nba_type" | "alter_owner_nba" | "user_alter_owner" | "/default_schema" | ""    |
    When executing query:
      """
      USE alter_owner_nba INSERT
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
      USE alter_owner_nba MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      ALTER OWNER GRAPH alter_owner_nba TO USER root
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_graphs() FILTER name = 'alter_owner_nba' RETURN graph_type, name, owner, `schema`, extra
      """
    Then the result should be, in any order:
      | graph_type             | name              | owner  | schema            | extra |
      | "alter_owner_nba_type" | "alter_owner_nba" | "root" | "/default_schema" | ""    |
    When executing query:
      """
      ALTER OWNER GRAPH alter_owner_nba TO USER root
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can alter owner"
    When executing query:
      """
      USE alter_owner_nba
      MATCH (v WHERE v.id IN LIST[2, 3, 4, 888])
      RETURN v.id as id
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/alter_owner_nba.node_type.id"
    And switch to a new session with username "root" and password "NebulaGraph01"
    And drop the graph "alter_owner_nba"
    And drop the graph type "alter_owner_nba_type"
    And close the current session

  Scenario: create index on schema
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_create_index",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_index" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_create_index
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ANY GRAPH, CREATE INDEX ON SCHEMA /default_schema TO USER user_create_index
      """
    Then the execution should be successful
    And action "CREATE_INDEX" on "SCHEMA" for user "user_create_index" should be granted
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_create_index_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_create_index TYPED test_create_index_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_create_index INSERT
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
      USE test_create_index
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
    And switch to a new session with username "user_create_index" and password "NebulaGraph01"
    When executing query:
      """
      USE test_create_index MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE test_create_index MATCH (v)-[e:follow]->(b)
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    When executing query:
      """
      USE test_create_index CREATE INDEX IF NOT EXISTS node_type_index ON NODE node_type(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE test_create_index REPAIR INDEX node_type_index
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/test_create_index"
    When executing query:
      """
      USE test_create_index DROP INDEX IF EXISTS node_type_index
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/test_create_index"
    And switch to a new session with username "root" and password "NebulaGraph01"
    And drop the graph "test_create_index"
    And drop the graph type "test_create_index_type"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_create_index"
    And logout from the meta

  Scenario: group user
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_invite",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_invite" should be ready to use
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_invite_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    And graph type "test_invite_type" should be ready to use
    When executing query:
      """
      ALTER OWNER GRAPH TYPE test_invite_type TO USER user_invite
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER user_invite
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_invite" should be granted
    And switch to a new session with username "user_invite" and password "NebulaGraph01"
    When executing query:
      """
      REMOVE USER root
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Can not remove service group's owner"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_users() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name          | home_schema       | home_graph |
      | "root"        | "/default_schema" | ""         |
      | "user_invite" | "/default_schema" | ""         |
    When executing query:
      """
      CALL show_graph_types() FILTER graph_type = "test_invite_type" RETURN graph_type, owner
      """
    Then the result should be, in any order:
      | graph_type         | owner         |
      | "test_invite_type" | "user_invite" |
    When executing query:
      """
      REMOVE USER root
      """
    Then an Error should be raised: "[NB000]: Authorization error: Can not remove self"
    When executing query:
      """
      REMOVE USER user_invite
      """
    Then the execution should be successful
    And drop the graph type "test_invite_type"
    And close the current session

  Scenario: operation
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_operation",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_operation" should be ready to use
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ttl_test_type_1 AS {
        NODE player (LABEL player {id INT PRIMARY KEY}),
        EDGE follow (player)-[LABEL follow {t1 ZONED DATETIME, t2 ZONED DATETIME, s1 STRING}]->(player)
      }
      """
    Then the execution should be successful
    And graph type "ttl_test_type_1" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS ttl_test_1 TYPED ttl_test_type_1
      """
    Then the execution should be successful
    And graph "ttl_test_1" should be ready to use
    When executing query:
      """
      GRANT ALTER ON GRAPH ttl_test_1 TO USER user_operation
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER user_operation
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_operation" should be granted
    And switch to a new session with username "user_operation" and password "NebulaGraph01"
    When executing query:
      """
      USE ttl_test_1 CREATE TTL ON EDGE follow(t1) DURATION({"seconds":20})
      """
    Then the execution should be successful
    When executing query:
      """
      BALANCE DATA
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute balance_data"
    When executing query:
      """
      BALANCE LEADER
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute balance_leader"
    When executing query:
      """
      CANCEL BALANCE DATA
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute cancel_balance_data"
    When executing query:
      """
      SUBMIT JOB COMPACT
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute compact"
    When executing query:
      """
      SUBMIT JOB FLUSH
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute flush"
    When executing query:
      """
      SUBMIT JOB STATS ttl_test_1
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute stats"
    When executing query:
      """
      CREATE PLUGIN algo
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute create_plugin"
    When executing query:
      """
      DROP PLUGIN algo
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute drop_plugin"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE ALTER ON GRAPH ttl_test_1 FROM USER user_operation
      """
    Then the execution should be successful
    And action "ALTER" on "GRAPH" for user "user_operation" should be revoked
    And switch to a new session with username "user_operation" and password "NebulaGraph01"
    When executing query:
      """
      USE ttl_test_1 CREATE TTL ON EDGE follow(t1) DURATION({"seconds":20})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [ALTER] on GRAPH /default_schema/ttl_test_1"
    And switch to a new session with username "root" and password "NebulaGraph01"
    And drop the graph "ttl_test_1"
    And drop the graph type "ttl_test_type_1"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_operation"
    And logout from the meta

  Scenario: create drop temporary graph
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_graph_projection",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_graph_projection" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_graph_projection
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS projection_test_type_1 AS {
        NODE node_type_player ( LABEL player {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS projection_test_graph_1 TYPED projection_test_type_1
      """
    Then the execution should be successful
    And graph "projection_test_graph_1" should be ready to use
    When executing query:
      """
      TABLE t {id, name} = (1, "name")
      USE projection_test_graph_1
      FOR r IN t
      INSERT (@node_type_player {id: r.id, name: r.name})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection_1 AS COPY OF projection_test_graph_1 OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                       | graph_type               | schema        | owner  | extra               |
      | "#test_graph_projection_1" | "projection_test_type_1" | "/tmp_schema" | "root" | "distributed:false" |
    When executing query:
      """
      DROP GRAPH #test_graph_projection_1
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_graph_projection" should be granted
    And switch to a new session with username "user_graph_projection" and password "NebulaGraph01"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection_2 AS COPY OF projection_test_graph_1 OPTIONS {immutable: true}
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/projection_test_graph_1.node_type_player.name"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection_2 AS COPY OF
      GRAPH{ USE projection_test_graph_1 MATCH(v) RETURN v } OPTIONS {immutable: true}
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/projection_test_graph_1.node_type_player.name"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      GRANT MATCH ON GRAPH /default_schema/projection_test_graph_1 TO USER user_graph_projection
      """
    Then the execution should be successful
    And action "MATCH" on "GRAPH" for user "user_graph_projection" should be granted
    And switch to a new session with username "user_graph_projection" and password "NebulaGraph01"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection_2 AS COPY OF projection_test_graph_1 OPTIONS {immutable: true}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_graph_projection_3 AS COPY OF
      GRAPH{ USE projection_test_graph_1 MATCH(v) RETURN v } OPTIONS {immutable: true}
      """
    Then the execution should be successful
    And wait "1" seconds
    # FIXME(wuu): add graph_name back
    # When executing query:
    # """
    # SHOW GRAPHS
    # """
    # Then the result should contain:
    # | projection_name           | graph_name                                                           |
    # | "#test_graph_projection_2" | "projection_test_graph_1"                                            |
    # | "#test_graph_projection_3" | "#anon0{ GRAPH { USE projection_test_graph_1 MATCH (v) RETURN v } }" |
    When executing query:
      """
      DROP GRAPH #test_graph_projection_2
      """
    Then the execution should be successful
    And switch to a new session with username "root" and password "NebulaGraph01"
    And drop the graph "projection_test_graph_1"
    And drop the graph type "projection_test_type_1"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_graph_projection"
    And logout from the meta

  @pretest
  Scenario: create function
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_create_function",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_function" should be ready to use
    When executing query:
      """
      CREATE PLUGIN IF NOT EXISTS mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER user_create_function
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE FUNCTION ON SCHEMA /default_schema TO USER user_create_function
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE FUNCTION IF NOT EXISTS _add(int32, int32) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    And action "CREATE_FUNCTION" on "SCHEMA" for user "user_create_function" should be granted
    And switch to a new session with username "user_create_function" and password "NebulaGraph01"
    When executing query:
      """
      CREATE FUNCTION IF NOT EXISTS _add(int64, int64) RETURNS int64 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _add(1, 3)
      """
    Then the result should be, in any order:
      | _add(1, 3) |
      | 4          |
    When executing query:
      """
      DROP FUNCTION IF EXISTS _add(int64, int64) RETURNS int64 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN _add(1, 3)
      """
    Then the result should be, in any order:
      | _add(1, 3) |
      | 4          |
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE CREATE FUNCTION ON SCHEMA /default_schema FROM USER user_create_function
      """
    Then the execution should be successful
    When executing query:
      """
      DROP FUNCTION _add
      """
    Then the execution should be successful
    And action "CREATE_FUNCTION" on "SCHEMA" for user "user_create_function" should be revoked
    And switch to a new session with username "user_create_function" and password "NebulaGraph01"
    When executing query:
      """
      CREATE FUNCTION IF NOT EXISTS _add(int64, int64) RETURNS int64 EXTERNAL PLUGIN mathUdf
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_FUNCTION] on SCHEMA /default_schema"
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      GRANT DROP ANY FUNCTION ON SCHEMA /default_schema TO USER user_create_function
      """
    Then the execution should be successful
    And action "DROP_ANY_FUNCTION" on "SCHEMA" for user "user_create_function" should be granted
    And switch to a new session with username "user_create_function" and password "NebulaGraph01"
    When executing query:
      """
      DROP FUNCTION IF EXISTS _add(int32, int32) RETURNS int32 EXTERNAL PLUGIN mathUdf
      """
    Then the execution should be successful
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      DROP PLUGIN IF EXISTS mathUdf
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_create_function"
    And logout from the meta

  Scenario: mutate memory graph
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_mutate_mem_graph_owner",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    When create a new user:
      """
      {
        "username": "user_mutate_mem_graph",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_mutate_mem_graph_owner" should be ready to use
    And user "user_mutate_mem_graph" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER  user_mutate_mem_graph_owner
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER  user_mutate_mem_graph
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH ON SCHEMA /default_schema TO USER  user_mutate_mem_graph_owner
      """
    Then the execution should be successful
    And switch to a new session with username "user_mutate_mem_graph_owner" and password "NebulaGraph01"
    And action "CREATE_GRAPH_TYPE" on "SCHEMA" for user "user_mutate_mem_graph_owner" should be granted
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_mutate_mem_graph_owner" should be granted
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_mutable_temp_graph_1 AS {
        NODE person (LABEL person {id INT PRIMARY KEY, name string, age int}),
        NODE dog (LABEL dog {id INT PRIMARY KEY, name string}),
        EDGE bought (person)-[LABEL bought {year:: int}]->(dog)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS mutable_temp_graph_1 TYPED gt_mutable_temp_graph_1
      """
    Then the execution should be successful
    When executing query:
      """
      USE mutable_temp_graph_1
      INSERT (@person {id:1, name: "alice", age: 20}), (@person {id: 2, name: "bob", age: 21}), (@dog {id: 3, name: "dog1"}), (@dog {id: 4, name: "dog2"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE mutable_temp_graph_1
      MATCH (p:person {id:1}), (d3:dog {id:3}), (d4:dog {id:4})
      INSERT (p)-[@bought {year: 2023}]->(d3), (p)-[@bought {year: 2024}]->(d4)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #mutable_temp_graph_1 AS COPY OF mutable_temp_graph_1
      """
    Then the execution should be successful
    When executing query:
      """
      USE #mutable_temp_graph_1 SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 2         |
      | "person"     | "Node"       | 2         |
      | "dog"        | "Node"       | 2         |
      | "bought"     | "Edge"       | 2         |
    When executing query:
      """
      USE #mutable_temp_graph_1
      INSERT (a@person {id:5, name: "charlie", age: 22}), (b@dog {id:5, name: "dog3"}), (a)-[@bought {year: 2025}]->(b)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 1     |
    When executing query:
      """
      USE #mutable_temp_graph_1 SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 6         |
      | "Edge Total" | "Edge"       | 3         |
      | "person"     | "Node"       | 3         |
      | "dog"        | "Node"       | 3         |
      | "bought"     | "Edge"       | 3         |
    When executing query:
      """
      USE #mutable_temp_graph_1
      MATCH (v)-[e]->(v2) return v.id, v.name, v.age, e.year, v2.id, v2.name
      """
    Then the result should be, in any order:
      | v.id | v.name    | v.age | e.year | v2.id | v2.name |
      | 1    | "alice"   | 20    | 2023   | 3     | "dog1"  |
      | 1    | "alice"   | 20    | 2024   | 4     | "dog2"  |
      | 5    | "charlie" | 22    | 2025   | 5     | "dog3"  |
    When executing query:
      """
      USE #mutable_temp_graph_1
      MATCH (v)-[e]->(v2)
      SET v.age = v.age + 10, e.year = e.year + 20
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 2     |
      | "num_affected_edges" | 3     |
    When executing query:
      """
      USE #mutable_temp_graph_1
      MATCH (v)-[e]->(v2)
      RETURN v.id, v.name, v.age, e.year, v2.id, v2.name
      """
    Then the result should be, in any order:
      | v.id | v.name    | v.age | e.year | v2.id | v2.name |
      | 1    | "alice"   | 30    | 2043   | 3     | "dog1"  |
      | 1    | "alice"   | 30    | 2044   | 4     | "dog2"  |
      | 5    | "charlie" | 32    | 2045   | 5     | "dog3"  |
    When executing query:
      """
      USE #mutable_temp_graph_1
      MATCH (a)-[e]->(b)
      DELETE a, e, b
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 5     |
      | "num_affected_edges" | 3     |
    And switch to a new session with username "user_mutate_mem_graph" and password "NebulaGraph01"
    When executing query:
      """
      USE #mutable_temp_graph_1
      INSERT (a@person {id:5, name: "charlie", age: 22}), (b@dog {id:5, name: "dog3"}), (a)-[@bought {year: 2025}]->(b)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can execute DML statement of temporary graph"
    When executing query:
      """
      USE #mutable_temp_graph_1
      MATCH (v)-[e]->(v2) return v.id, v.name, v.age, e.year, v2.id, v2.name
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can execute DQL statement of temporary graph"
    When executing query:
      """
      USE #mutable_temp_graph_1
      MATCH (v)-[e]->(v2)
      SET v.age = v.age + 10, e.year = e.year + 20
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can execute DML statement of temporary graph"
    When executing query:
      """
      USE #mutable_temp_graph_1
      MATCH (a)-[e]->(b)
      DELETE a, e, b
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can execute DML statement of temporary graph"
    When executing query:
      """
      DROP GRAPH #mutable_temp_graph_1
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can execute DDL statement of temporary graph"
    And switch to a new session with username "user_mutate_mem_graph_owner" and password "NebulaGraph01"
    And drop the graph "#mutable_temp_graph_1"
    And drop the graph "mutable_temp_graph_1"
    And drop the graph type "gt_mutable_temp_graph_1"
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_mutate_mem_graph_owner"
    And drop the user "user_mutate_mem_graph"
    And logout from the meta

  Scenario: const temp memory graph
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_const_mem_graph_owner",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    When create a new user:
      """
      {
        "username": "user_const_mem_graph",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_const_mem_graph_owner" should be ready to use
    And user "user_const_mem_graph" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER  user_const_mem_graph_owner
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER  user_const_mem_graph
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH ON SCHEMA /default_schema TO USER  user_const_mem_graph_owner
      """
    Then the execution should be successful
    And switch to a new session with username "user_const_mem_graph_owner" and password "NebulaGraph01"
    And action "CREATE_GRAPH_TYPE" on "SCHEMA" for user "user_const_mem_graph_owner" should be granted
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_const_mem_graph_owner" should be granted
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_const_temp_graph_1 AS {
        NODE person (LABEL person {id INT PRIMARY KEY, name string, age int}),
        NODE dog (LABEL dog {id INT PRIMARY KEY, name string}),
        EDGE bought (person)-[LABEL bought {year:: int}]->(dog)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS const_temp_graph_1 TYPED gt_const_temp_graph_1
      """
    Then the execution should be successful
    When executing query:
      """
      USE const_temp_graph_1
      INSERT (@person {id:1, name: "alice", age: 20}), (@person {id: 2, name: "bob", age: 21}), (@dog {id: 3, name: "dog1"}), (@dog {id: 4, name: "dog2"})
      """
    Then the execution should be successful
    When executing query:
      """
      USE const_temp_graph_1
      MATCH (p:person {id:1}), (d3:dog {id:3}), (d4:dog {id:4})
      INSERT (p)-[@bought {year: 2023}]->(d3), (p)-[@bought {year: 2024}]->(d4)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH #const_temp_graph_1 AS COPY OF const_temp_graph_1 OPTIONS {IMMUTABLE: true, WITHOUT_PROPERTIES: true}
      """
    Then the execution should be successful
    When executing query:
      """
      USE #const_temp_graph_1 SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 4         |
      | "Edge Total" | "Edge"       | 2         |
    When executing query:
      """
      USE #const_temp_graph_1
      MATCH ()-[]->()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    And switch to a new session with username "user_const_mem_graph" and password "NebulaGraph01"
    When executing query:
      """
      USE #const_temp_graph_1
      MATCH ()-[]->()
      RETURN count(*) AS num GROUP BY ()
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can execute DQL statement of temporary graph"
    When executing query:
      """
      DROP GRAPH #const_temp_graph_1
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN or owner can execute DDL statement of temporary graph"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      USE #const_temp_graph_1
      MATCH ()-[]->()
      RETURN count(*) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    And drop the graph "#const_temp_graph_1"
    And drop the graph "const_temp_graph_1"
    And drop the graph type "gt_const_temp_graph_1"
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_const_mem_graph_owner"
    And drop the user "user_const_mem_graph"
    And logout from the meta
