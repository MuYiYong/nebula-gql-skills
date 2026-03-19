# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: PrivilegeToRole

  Scenario: privilege constraint
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_constraint
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_constraint
      """
    Then the execution should be successful
    And role "role_constraint" should be ready to use
    When executing query:
      """
      GRANT MATCH ON SCHEMA /default_schema TO ROLE role_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `MATCH` on `SCHEMA`"
    When executing query:
      """
      GRANT INSERT ANY GRAPH, MATCH ANY GRAPH, EXECUTE ON SCHEMA /default_schema TO ROLE role_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `EXECUTE` on `SCHEMA`"
    When executing query:
      """
      GRANT MATCH, ALTER ON GRAPH TYPE /default_schema/ldbc_type TO ROLE role_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `MATCH` on `GRAPH_TYPE`"
    When executing query:
      """
      GRANT MATCH, EXECUTE ON GRAPH /default_schema/ldbc TO ROLE role_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `EXECUTE` on `GRAPH`"
    When executing query:
      """
      GRANT INSERT, MATCH ANY GRAPH, UPDATE ON NODE TYPE /default_schema/ldbc.Person TO ROLE role_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `MATCH_ANY_GRAPH` on `NODE_TYPE`"
    When executing query:
      """
      GRANT DELETE, EXECUTE ANY PROCEDURE, MATCH ON EDGE TYPE /default_schema/ldbc.KNOWS TO ROLE role_constraint
      """
    Then an Error should be raised: "[NB102]: Invalid action `EXECUTE_ANY_PROCEDURE` on `EDGE_TYPE`"
    When executing query:
      """
      GRANT MATCH ANY GRAPH, INSERT ANY GRAPH, DELETE ANY GRAPH ON SCHEMA /default_schema TO ROLE role_constraint
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT DELETE, MATCH, UPDATE, INSERT ON EDGE TYPE /default_schema/ldbc.KNOWS TO ROLE role_constraint
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT DELETE, MATCH, UPDATE, INSERT ON EDGE TYPE /default_schema/ldbc.KNOWS TO ROLE role_constraint
      """
    Then the execution should be successful

  Scenario: create graph type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_create_graph_type_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_graph_type_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_create_graph_type_1
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_create_graph_type
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_create_graph_type_1" should be granted
    And role "role_create_graph_type" should be ready to use
    When executing query:
      """
      GRANT ROLE role_create_graph_type TO USER user_create_graph_type_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE ON SCHEMA /default_schema TO ROLE role_create_graph_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_create_graph_type_1" and password "NebulaGraph01"
    And action "CREATE_GRAPH_TYPE" on "SCHEMA" for user "user_create_graph_type_1" should be granted
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS role_test_privilege_type AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED role_test_privilege_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    When executing query:
      """
      ALTER GRAPH TYPE role_test_privilege_type {
        RENAME NODE TYPE node_type TO person,
        RENAME EDGE TYPE edge_type TO follow
      }
      """
    Then the execution should be successful
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
      REVOKE CREATE GRAPH TYPE ON SCHEMA /default_schema FROM ROLE role_create_graph_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_create_graph_type_1" and password "NebulaGraph01"
    And action "CREATE_GRAPH_TYPE" on "SCHEMA" for user "user_create_graph_type_1" should be revoked
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS role_test_privilege_type AS {
        NODE TYPE node_type ( LABEL label {id INT PRIMARY KEY}),
        EDGE TYPE edge_type  (node_type)-[LABEL elabel]->(node_type)
       }
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH_TYPE] on SCHEMA /default_schema"
    And drop the graph type "role_test_privilege_type"
    And close the current session
    And drop the user "user_create_graph_type_1"

  Scenario: create graph
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_create_graph_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_graph_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_create_graph_1
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_create_graph
      """
    Then the execution should be successful
    And role "role_create_graph" should be ready to use
    When executing query:
      """
      GRANT ROLE role_create_graph TO USER user_create_graph_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH ON SCHEMA /default_schema TO ROLE role_create_graph
      """
    Then the execution should be successful
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_create_graph_1" should be granted
    And switch to a new session with username "user_create_graph_1" and password "NebulaGraph01"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS role_nba_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow {day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS role_nba TYPED role_nba_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE role_nba INSERT
        (a@node_type{id:1, name:"Tim"}),
        (b@node_type{id:2, name:"Jerry"}),
        (c@node_type{id:3, name:"Kyle"}),
        (d@node_type{id:4, name:"Yao"}),
        (a)-[@edge_type{day:10}]->(b),
        (b)-[@edge_type{day:20}]->(c)
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                 | value |
      | "num_affected_nodes" | 4     |
      | "num_affected_edges" | 2     |
    When executing query:
      """
      USE role_nba MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE role_nba MATCH (v)-[e:follow]->(b)
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE CREATE GRAPH ON SCHEMA /default_schema FROM ROLE role_create_graph
      """
    Then the execution should be successful
    And switch to a new session with username "user_create_graph_1" and password "NebulaGraph01"
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_create_graph_1" should be revoked
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege_1 TYPED role_nba_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    When executing query:
      """
      USE role_nba MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE role_nba
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
      USE role_nba
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
      USE role_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE a,r
      """
    Then the execution should be successful
    When executing query:
      """
      RENAME GRAPH role_nba TO rename_role_nba
      """
    Then the execution should be successful
    And drop the graph "rename_role_nba"
    And drop the graph type "role_nba_type"
    And close the current session

  Scenario: match any graph on schema
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_match_any_graph_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_any_graph_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_any_graph_1
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_match_any_graph_1" should be granted
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_match_any_graph
      """
    Then the execution should be successful
    And role "role_match_any_graph" should be ready to use
    When executing query:
      """
      GRANT ROLE role_match_any_graph TO USER user_match_any_graph_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ANY GRAPH ON SCHEMA /default_schema TO ROLE role_match_any_graph
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_any_graph_1" and password "NebulaGraph01"
    And action "MATCH_ANY_GRAPH" on "SCHEMA" for user "user_match_any_graph_1" should be granted
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
      REVOKE MATCH ANY GRAPH ON SCHEMA /default_schema FROM ROLE role_match_any_graph
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_any_graph_1" and password "NebulaGraph01"
    And action "MATCH_ANY_GRAPH" on "SCHEMA" for user "user_match_any_graph_1" should be revoked
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    And close the current session
    And drop the user "user_match_any_graph_1"

  Scenario: grant graph privilege to other user
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_graph_owner_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    When create a new user:
      """
      {"username":"user_graph_usage_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_graph_usage
      """
    Then the execution should be successful
    And user "user_graph_owner_1" should be ready to use
    And role "role_graph_usage" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_graph_owner_1
      """
    Then the execution should be successful
    And user "user_graph_usage_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_graph_usage_1
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_graph_usage_1" should be granted
    When executing query:
      """
      GRANT ROLE role_graph_usage TO USER user_graph_usage_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH ON SCHEMA /default_schema TO USER user_graph_owner_1
      """
    Then the execution should be successful
    And switch to a new session with username "user_graph_owner_1" and password "NebulaGraph01"
    And action "CREATE_GRAPH" on "SCHEMA" for user "user_graph_owner_1" should be granted
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS role_owner_nba_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow{day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS role_owner_nba TYPED role_owner_nba_type
      """
    Then the execution should be successful
    # grant match to user
    When executing query:
      """
      GRANT INDEX, MATCH, INSERT, UPDATE, DELETE, ALTER ON GRAPH /default_schema/role_owner_nba TO ROLE role_graph_usage
      """
    Then the execution should be successful
    And switch to a new session with username "user_graph_usage_1" and password "NebulaGraph01"
    And action "MATCH" on "GRAPH" for user "user_graph_usage_1" should be granted
    When executing query:
      """
      USE role_owner_nba INSERT
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
      USE role_owner_nba
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
      USE role_owner_nba MATCH (v:player) RETURN v.id, v.name
      """
    Then the result should be, in any order:
      | v.id | v.name  |
      | 1    | "Tim"   |
      | 2    | "Jerry" |
      | 3    | "Kyle"  |
      | 4    | "Yao"   |
    When executing query:
      """
      USE role_owner_nba MATCH (v)-[e:follow]->(b)
      RETURN count(e) AS num GROUP BY ()
      """
    Then the result should be, in any order:
      | num |
      | 2   |
    When executing query:
      """
      USE role_owner_nba
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
      USE role_owner_nba
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
      USE role_owner_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE a,r
      """
    Then the execution should be successful
    When executing query:
      """
      USE role_owner_nba CREATE INDEX IF NOT EXISTS role_owner_nba_index ON NODE node_type(name)
      """
    Then the execution should be successful
    When executing query:
      """
      USE role_owner_nba REPAIR INDEX role_owner_nba_index
      """
    Then the execution should be successful
    When executing query:
      """
      RENAME GRAPH role_owner_nba TO rename_role_owner_nba
      """
    Then the execution should be successful
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE INDEX, INSERT, UPDATE, DELETE, ALTER ON GRAPH /default_schema/rename_role_owner_nba FROM ROLE role_graph_usage
      """
    Then the execution should be successful
    And switch to a new session with username "user_graph_usage_1" and password "NebulaGraph01"
    And action "INDEX" on "GRAPH" for user "user_graph_usage_1" should be revoked
    When executing query:
      """
      USE rename_role_owner_nba INSERT (@node_type{id:1, name:"Tim"})
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/rename_role_owner_nba.node_type.id"
    When executing query:
      """
      USE rename_role_owner_nba
      MATCH (a:player{id:2}), (b:player{id:3})
      INSERT (a)-[:follow{day:23}]->(b)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on EDGE_PROPERTY /default_schema/rename_role_owner_nba.edge_type.day"
    When executing query:
      """
      USE rename_role_owner_nba
      MATCH (v:player{id:1})
      SET v.name = "new name Tim"
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [UPDATE] on NODE_PROPERTY /default_schema/rename_role_owner_nba.node_type.name"
    When executing query:
      """
      USE rename_role_owner_nba
      MATCH (v:player{id:1})-[e:follow]->(b)
      SET e.day = 15
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [UPDATE] on EDGE_PROPERTY /default_schema/rename_role_owner_nba.edge_type.day"
    When executing query:
      """
      USE rename_role_owner_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE a
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DELETE] on NODE_TYPE /default_schema/rename_role_owner_nba.node_type"
    When executing query:
      """
      USE rename_role_owner_nba
      MATCH (a:player{id:1})-[r]-(b)
      DELETE r
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DELETE] on EDGE_TYPE /default_schema/rename_role_owner_nba.edge_type"
    When executing query:
      """
      USE rename_role_owner_nba CREATE INDEX IF NOT EXISTS role_owner_nba_index ON NODE node_type(name)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/rename_role_owner_nba"
    When executing query:
      """
      USE rename_role_owner_nba REPAIR INDEX role_owner_nba_index
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/rename_role_owner_nba"
    When executing query:
      """
      USE rename_role_owner_nba DROP INDEX IF EXISTS role_owner_nba_index
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INDEX] on GRAPH /default_schema/rename_role_owner_nba"
    When executing query:
      """
      RENAME GRAPH rename_role_owner_nba TO role_owner_nba
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [ALTER] on GRAPH /default_schema/rename_role_owner_nba"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ON GRAPH /default_schema/rename_role_owner_nba FROM ROLE role_graph_usage
      """
    Then the execution should be successful
    And switch to a new session with username "user_graph_usage_1" and password "NebulaGraph01"
    And action "MATCH" on "GRAPH" for user "user_graph_usage_1" should be revoked
    When executing query:
      """
      USE rename_role_owner_nba MATCH (v:player) RETURN v.name
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/rename_role_owner_nba.node_type.name"
    When executing query:
      """
      USE rename_role_owner_nba MATCH (v)-[e:follow]->(b)
      RETURN count(e) AS num GROUP BY ()
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/rename_role_owner_nba.edge_type.day"
    And switch to a new session with username "user_graph_owner_1" and password "NebulaGraph01"
    And drop the index "role_owner_nba_index" of "rename_role_owner_nba"
    And drop the graph "rename_role_owner_nba"
    And drop the graph type "role_owner_nba_type"
    And close the current session
    And drop the user "user_graph_owner_1"

  Scenario: match on graph
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_match_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_1
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_match_1" should be granted
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_match
      """
    Then the execution should be successful
    And role "role_match" should be ready to use
    When executing query:
      """
      GRANT ROLE role_match TO USER user_match_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON GRAPH /default_schema/ldbc TO ROLE role_match
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_1" and password "NebulaGraph01"
    And action "MATCH" on "GRAPH" for user "user_match_1" should be granted
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
      REVOKE MATCH ON GRAPH /default_schema/ldbc FROM ROLE role_match
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_1" and password "NebulaGraph01"
    And action "MATCH" on "GRAPH" for user "user_match_1" should be revoked
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->{0,1}(b)
      RETURN v.id as src, b.id as dst
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    And close the current session
    And drop the user "user_match_1"

  Scenario: match on node type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_match_node_type_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_node_type_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_node_type_1
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_match_node_type_1" should be granted
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_match_node_type
      """
    Then the execution should be successful
    And role "role_match_node_type" should be ready to use
    When executing query:
      """
      GRANT ROLE role_match_node_type TO USER user_match_node_type_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON NODE TYPE /default_schema/ldbc.Person TO ROLE role_match_node_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_node_type_1" and password "NebulaGraph01"
    And action "MATCH" on "NODE_TYPE" for user "user_match_node_type_1" should be granted
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
    Then an Error should be raised: "[NB101]: Insufficient privilege: Cannot find privilege for Action [MATCH] on any EDGE_PROPERTY of EDGE_TYPE"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ON NODE TYPE /default_schema/ldbc.Person FROM ROLE role_match_node_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_node_type_1" and password "NebulaGraph01"
    And action "MATCH" on "NODE_TYPE" for user "user_match_node_type_1" should be revoked
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])
      RETURN v.id as id
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    And close the current session

  Scenario: match on edge type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_match_edge_type_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_edge_type_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_edge_type_1
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_match_edge_type_1" should be granted
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_match_edge_type
      """
    Then the execution should be successful
    And role "role_match_edge_type" should be ready to use
    When executing query:
      """
      GRANT ROLE role_match_edge_type TO USER user_match_edge_type_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON EDGE TYPE `/default_schema/ldbc.KNOWS` TO ROLE role_match_edge_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_edge_type_1" and password "NebulaGraph01"
    And action "MATCH" on "EDGE_TYPE" for user "user_match_edge_type_1" should be granted
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
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS test_privilege TYPED ldbc_type
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_GRAPH] on SCHEMA /default_schema"
    # revoke privilege
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE MATCH ON EDGE TYPE `/default_schema/ldbc.KNOWS` FROM ROLE role_match_edge_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_edge_type_1" and password "NebulaGraph01"
    And action "MATCH" on "EDGE_TYPE" for user "user_match_edge_type_1" should be revoked
    When executing query:
      """
      USE ldbc
      MATCH ()-[e:KNOWS]->()
      RETURN COUNT(e.creationDate) AS num GROUP BY ()
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/ldbc.KNOWS.creationDate"
    And close the current session
    And drop the user "user_match_edge_type_1"

  Scenario: match on edge type and node type
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_match_node_edge_type_1", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_match_node_edge_type_1" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_match_node_edge_type_1
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_match_node_edge_type_1" should be granted
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_match_node_edge_type
      """
    Then the execution should be successful
    And role "role_match_node_edge_type" should be ready to use
    When executing query:
      """
      GRANT ROLE role_match_node_edge_type TO USER user_match_node_edge_type_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON NODE TYPE `/default_schema/ldbc.Person` TO ROLE role_match_node_edge_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH ON EDGE TYPE `/default_schema/ldbc.KNOWS` TO ROLE role_match_node_edge_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_node_edge_type_1" and password "NebulaGraph01"
    And action "MATCH" on "EDGE_TYPE" for user "user_match_node_edge_type_1" should be granted
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
      REVOKE MATCH ON EDGE TYPE `/default_schema/ldbc.KNOWS` FROM ROLE role_match_node_edge_type
      """
    Then the execution should be successful
    And switch to a new session with username "user_match_node_edge_type_1" and password "NebulaGraph01"
    And action "MATCH" on "EDGE_TYPE" for user "user_match_node_edge_type_1" should be revoked
    When executing query:
      """
      USE ldbc
      MATCH (v IS Person WHERE v.id IN LIST[2, 3, 4, 888])-[e:KNOWS]->(b)
      RETURN v.id as src, b.id as dst, e.creationDate as dt
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [MATCH] on EDGE_PROPERTY /default_schema/ldbc.KNOWS.creationDate"
    And close the current session
    And drop the user "user_match_node_edge_type_1"
