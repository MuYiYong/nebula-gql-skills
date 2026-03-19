# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: ShowPrivilege

  Scenario: show roles
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_show_roles", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    When create a new user:
      """
      {"username":"user_show_roles_test", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_show_roles" should be ready to use
    And user "user_show_roles_test" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_show_roles
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER user_show_roles_test
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_only_read COMMENT "only read for test comment"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_only_write COMMENT "only write for test comment"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_read_write COMMENT "read and write for test"
      """
    Then the execution should be successful
    And role "role_read_write" should be ready to use
    When executing query:
      """
      GRANT ROLE role_only_read, role_only_write, role_read_write TO USER user_show_roles
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ROLE role_only_read TO USER user_show_roles_test
      """
    Then the execution should be successful
    And role "role_only_read" for user "user_show_roles_test" should be granted
    When executing query:
      """
      SHOW ROLES
      """
    Then the result should be, in any order:
      | name    | owner  | comment        |
      | "ADMIN" | "root" | "Builtin role" |
    When executing query:
      """
      SHOW ROLES FOR USER user_show_roles
      """
    Then the result should be, in any order:
      | name              | owner  | comment                       |
      | "role_only_read"  | "root" | "only read for test comment"  |
      | "role_only_write" | "root" | "only write for test comment" |
      | "role_read_write" | "root" | "read and write for test"     |
    When executing query:
      """
      SHOW ROLES FOR USER user_show_roles_test
      """
    Then the result should be, in any order:
      | name             | owner  | comment                      |
      | "role_only_read" | "root" | "only read for test comment" |
    When executing query:
      """
      ALTER ROLE role_read_write SET COMMENT = "read and write for test comment"
      """
    Then the execution should be successful
    And switch to a new session with username "user_show_roles" and password "NebulaGraph01"
    When executing query:
      """
      SHOW ROLES
      """
    Then the result should be, in any order:
      | name              | owner  | comment                           |
      | "role_only_read"  | "root" | "only read for test comment"      |
      | "role_only_write" | "root" | "only write for test comment"     |
      | "role_read_write" | "root" | "read and write for test comment" |
    When executing query:
      """
      SHOW ROLES FOR USER user_show_roles_test
      """
    Then an Error should be raised: "[NB105]: Only ADMIN or User user_show_roles_test can execute SHOW ROLES FOR USER user_show_roles_test"
    # revoke role
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE ROLE role_read_write FROM USER user_show_roles
      """
    Then the execution should be successful
    And role "role_read_write" for user "user_show_roles" should be revoked
    And switch to a new session with username "user_show_roles" and password "NebulaGraph01"
    When executing query:
      """
      SHOW ROLES
      """
    Then the result should be, in any order:
      | name              | owner  | comment                       |
      | "role_only_read"  | "root" | "only read for test comment"  |
      | "role_only_write" | "root" | "only write for test comment" |
    # drop roles
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      DROP ROLE IF EXISTS role_only_read
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW ROLES FOR USER user_show_roles
      """
    Then the result should be, in any order:
      | name              | owner  | comment                       |
      | "role_only_write" | "root" | "only write for test comment" |
    When executing query:
      """
      DROP ROLE IF EXISTS role_only_write
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW ROLES FOR USER user_show_roles
      """
    Then the result should be, in any order:
      | name | owner | comment |
    And drop the role "role_read_write"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_show_roles"
    And logout from the meta

  Scenario: show all roles
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_test_a COMMENT "rolea"
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_test_b COMMENT "roleb"
      """
    Then the execution should be successful
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_test_c COMMENT "rolec"
      """
    Then the execution should be successful
    And close the current session
    And role "role_test_c" should be ready to use
    When executing query:
      """
      SHOW ALL ROLES
      """
    Then the result should contain:
      | name          | owner  | comment        |
      | "ADMIN"       | "root" | "Builtin role" |
      | "role_test_c" | "root" | "rolec"        |
      | "role_test_a" | "root" | "rolea"        |
      | "role_test_b" | "root" | "roleb"        |
    When executing query:
      """
      DROP ROLE IF EXISTS role_test_a, role_test_b, role_test_c
      """
    Then the execution should be successful

  Scenario: show users
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_test_a", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    When create a new user:
      """
      {"username":"user_test_b", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_test_a" should be ready to use
    And user "user_test_b" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_test_a
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER user_test_b
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_test_b" should be granted
    When executing query:
      """
      CALL show_users() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name          | home_schema       | home_graph |
      | "root"        | "/default_schema" | ""         |
      | "user_test_a" | "/default_schema" | ""         |
      | "user_test_b" | "/default_schema" | ""         |
    When executing query:
      """
      REVOKE CONNECT FROM USER user_test_b
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_test_b" should be revoked
    When executing query:
      """
      SHOW PRIVILEGES FOR USER user_test_b
      """
    Then the result should be, in any order:
      | role | type | object | actions |
    When executing query:
      """
      CALL show_users() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name          | home_schema       | home_graph |
      | "root"        | "/default_schema" | ""         |
      | "user_test_a" | "/default_schema" | ""         |
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_test_a"
    And logout from the meta

  Scenario: show privileges for role
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_show_privileges COMMENT "test show privileges"
      """
    Then the execution should be successful
    And role "role_show_privileges" should be ready to use
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH, MATCH ANY GRAPH ON SCHEMA /default_schema TO ROLE role_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ALTER, DROP ON GRAPH TYPE ldbc_type TO ROLE role_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INSERT, UPDATE, DELETE ON GRAPH ldbc TO ROLE role_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INSERT, UPDATE, DELETE ON NODE TYPE ldbc.Person TO ROLE role_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, UPDATE ON NODE PROPERTY ldbc.Person.firstName, ldbc.Person.lastName TO ROLE role_show_privileges
      """
    Then the execution should be successful
    And action "MATCH" on "NODE_PROPERTY" for role "role_show_privileges" should be granted
    When executing query:
      """
      SHOW PRIVILEGES FOR ROLE role_show_privileges
      """
    Then the result should be, in any order:
      | role                   | type            | object                                  | actions                                                       |
      | "role_show_privileges" | "SCHEMA"        | "/default_schema"                       | LIST ["CREATE_GRAPH_TYPE", "CREATE_GRAPH", "MATCH_ANY_GRAPH"] |
      | "role_show_privileges" | "GRAPH_TYPE"    | "/default_schema/ldbc_type"             | LIST ["DROP", "ALTER"]                                        |
      | "role_show_privileges" | "GRAPH"         | "/default_schema/ldbc"                  | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | "role_show_privileges" | "NODE_TYPE"     | "/default_schema/ldbc.Person"           | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | "role_show_privileges" | "NODE_PROPERTY" | "/default_schema/ldbc.Person.firstName" | LIST ["MATCH", "UPDATE"]                                      |
      | "role_show_privileges" | "NODE_PROPERTY" | "/default_schema/ldbc.Person.lastName"  | LIST ["MATCH", "UPDATE"]                                      |
    # revoke privilege
    When executing query:
      """
      REVOKE CREATE GRAPH, MATCH ANY GRAPH ON SCHEMA /default_schema FROM ROLE role_show_privileges
      """
    Then the execution should be successful
    And action "CREATE_GRAPH" on "SCHEMA" for role "role_show_privileges" should be revoked
    When executing query:
      """
      SHOW PRIVILEGES FOR ROLE role_show_privileges
      """
    Then the result should be, in any order:
      | role                   | type            | object                                  | actions                                      |
      | "role_show_privileges" | "SCHEMA"        | "/default_schema"                       | LIST ["CREATE_GRAPH_TYPE"]                   |
      | "role_show_privileges" | "GRAPH_TYPE"    | "/default_schema/ldbc_type"             | LIST ["DROP", "ALTER"]                       |
      | "role_show_privileges" | "GRAPH"         | "/default_schema/ldbc"                  | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
      | "role_show_privileges" | "NODE_TYPE"     | "/default_schema/ldbc.Person"           | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
      | "role_show_privileges" | "NODE_PROPERTY" | "/default_schema/ldbc.Person.firstName" | LIST ["MATCH", "UPDATE"]                     |
      | "role_show_privileges" | "NODE_PROPERTY" | "/default_schema/ldbc.Person.lastName"  | LIST ["MATCH", "UPDATE"]                     |
    When executing query:
      """
      REVOKE CREATE GRAPH TYPE ON SCHEMA /default_schema FROM ROLE role_show_privileges
      """
    Then the execution should be successful
    And action "CREATE_GRAPH_TYPE" on "SCHEMA" for role "role_show_privileges" should be revoked
    When executing query:
      """
      SHOW PRIVILEGES FOR ROLE role_show_privileges
      """
    Then the result should be, in any order:
      | role                   | type            | object                                  | actions                                      |
      | "role_show_privileges" | "GRAPH_TYPE"    | "/default_schema/ldbc_type"             | LIST ["DROP", "ALTER"]                       |
      | "role_show_privileges" | "GRAPH"         | "/default_schema/ldbc"                  | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
      | "role_show_privileges" | "NODE_TYPE"     | "/default_schema/ldbc.Person"           | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
      | "role_show_privileges" | "NODE_PROPERTY" | "/default_schema/ldbc.Person.firstName" | LIST ["MATCH", "UPDATE"]                     |
      | "role_show_privileges" | "NODE_PROPERTY" | "/default_schema/ldbc.Person.lastName"  | LIST ["MATCH", "UPDATE"]                     |
    And drop the role "role_show_privileges"
    And close the current session

  Scenario: show privileges for user
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_show_privileges", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    When create a new user:
      """
      {"username":"user_show_privileges_test", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_show_privileges" should be ready to use
    And user "user_show_privileges_test" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER user_show_privileges_test
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_show_privileges_1 COMMENT "test show privileges"
      """
    Then the execution should be successful
    And role "role_show_privileges_1" should be ready to use
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH, MATCH ANY GRAPH ON SCHEMA /default_schema TO ROLE role_show_privileges_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ALTER, DROP ON GRAPH TYPE ldbc_type TO ROLE role_show_privileges_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INSERT, UPDATE, DELETE ON GRAPH ldbc TO ROLE role_show_privileges_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INSERT, UPDATE, DELETE ON NODE TYPE ldbc.Person TO ROLE role_show_privileges_1
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE GRAPH TYPE, CREATE GRAPH, MATCH ANY GRAPH ON SCHEMA /default_schema TO USER user_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ALTER, DROP ON GRAPH TYPE ldbc_type TO USER user_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INSERT, UPDATE, DELETE ON GRAPH ldbc TO USER user_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INSERT, UPDATE, DELETE ON NODE TYPE ldbc.Person TO USER user_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ROLE role_show_privileges_1 TO USER user_show_privileges
      """
    Then the execution should be successful
    And action "MATCH" on "NODE_TYPE" for user "user_show_privileges" should be granted
    And role "role_show_privileges_1" for user "user_show_privileges" should be granted
    When executing query:
      """
      SHOW PRIVILEGES FOR USER user_show_privileges
      """
    Then the result should be, in any order:
      | role                     | type         | object                        | actions                                                       |
      | "role_show_privileges_1" | "SCHEMA"     | "/default_schema"             | LIST ["CREATE_GRAPH_TYPE", "CREATE_GRAPH", "MATCH_ANY_GRAPH"] |
      | "role_show_privileges_1" | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | "role_show_privileges_1" | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | "role_show_privileges_1" | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "SVCGRP"     | "CURRENT_SVCGRP"              | LIST ["CONNECT"]                                              |
      | ""                       | "SCHEMA"     | "/default_schema"             | LIST ["CREATE_GRAPH_TYPE", "CREATE_GRAPH", "MATCH_ANY_GRAPH"] |
      | ""                       | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | ""                       | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
    And switch to a new session with username "user_show_privileges" and password "NebulaGraph01"
    When executing query:
      """
      SHOW PRIVILEGES FOR USER user_show_privileges_test
      """
    Then an Error should be raised: "[NB106]: Only ADMIN or User user_show_privileges_test can execute SHOW PRIVILEGES FOR USER user_show_privileges_test"
    When executing query:
      """
      SHOW PRIVILEGES
      """
    Then the result should be, in any order:
      | role                     | type         | object                        | actions                                                       |
      | "role_show_privileges_1" | "SCHEMA"     | "/default_schema"             | LIST ["CREATE_GRAPH_TYPE", "CREATE_GRAPH", "MATCH_ANY_GRAPH"] |
      | "role_show_privileges_1" | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | "role_show_privileges_1" | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | "role_show_privileges_1" | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "SVCGRP"     | "CURRENT_SVCGRP"              | LIST ["CONNECT"]                                              |
      | ""                       | "SCHEMA"     | "/default_schema"             | LIST ["CREATE_GRAPH_TYPE", "CREATE_GRAPH", "MATCH_ANY_GRAPH"] |
      | ""                       | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | ""                       | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
    # revoke privilege from user
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      REVOKE CREATE GRAPH, MATCH ANY GRAPH ON SCHEMA /default_schema FROM USER user_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PRIVILEGES FOR USER user_show_privileges
      """
    Then the result should be, in any order:
      | role                     | type         | object                        | actions                                                       |
      | "role_show_privileges_1" | "SCHEMA"     | "/default_schema"             | LIST ["CREATE_GRAPH_TYPE", "CREATE_GRAPH", "MATCH_ANY_GRAPH"] |
      | "role_show_privileges_1" | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | "role_show_privileges_1" | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | "role_show_privileges_1" | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "SVCGRP"     | "CURRENT_SVCGRP"              | LIST ["CONNECT"]                                              |
      | ""                       | "SCHEMA"     | "/default_schema"             | LIST ["CREATE_GRAPH_TYPE"]                                    |
      | ""                       | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | ""                       | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
    When executing query:
      """
      REVOKE CREATE GRAPH TYPE ON SCHEMA /default_schema FROM USER user_show_privileges
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PRIVILEGES FOR USER user_show_privileges
      """
    Then the result should be, in any order:
      | role                     | type         | object                        | actions                                                       |
      | "role_show_privileges_1" | "SCHEMA"     | "/default_schema"             | LIST ["CREATE_GRAPH_TYPE", "CREATE_GRAPH", "MATCH_ANY_GRAPH"] |
      | "role_show_privileges_1" | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | "role_show_privileges_1" | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | "role_show_privileges_1" | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "SVCGRP"     | "CURRENT_SVCGRP"              | LIST ["CONNECT"]                                              |
      | ""                       | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                                        |
      | ""                       | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
      | ""                       | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"]                  |
    When executing query:
      """
      REVOKE ROLE role_show_privileges_1 FROM USER user_show_privileges
      """
    Then the execution should be successful
    And role "role_show_privileges_1" for user "user_show_privileges" should be revoked
    When executing query:
      """
      SHOW PRIVILEGES FOR USER user_show_privileges
      """
    Then the result should be, in any order:
      | role | type         | object                        | actions                                      |
      | ""   | "SVCGRP"     | "CURRENT_SVCGRP"              | LIST ["CONNECT"]                             |
      | ""   | "GRAPH_TYPE" | "/default_schema/ldbc_type"   | LIST ["DROP", "ALTER"]                       |
      | ""   | "GRAPH"      | "/default_schema/ldbc"        | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
      | ""   | "NODE_TYPE"  | "/default_schema/ldbc.Person" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
    And drop the role "role_show_privileges_1"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_show_privileges"
    And logout from the meta

  Scenario: show privileges for role after delete object
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE ROLE IF NOT EXISTS role_delete_object COMMENT "test delete object"
      """
    Then the execution should be successful
    And role "role_delete_object" should be ready to use
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS delete_object_type AS {
        NODE TYPE node_type ( LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE edge_type  (node_type)-[LABEL follow {day INT}]->(node_type)
       }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS delete_object TYPED delete_object_type
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INDEX ON GRAPH /default_schema/delete_object TO ROLE role_delete_object
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT MATCH, INSERT, UPDATE, DELETE ON GRAPH ldbc TO ROLE role_delete_object
      """
    Then the execution should be successful
    And action "DELETE" on "GRAPH" for role "role_delete_object" should be granted
    When executing query:
      """
      SHOW PRIVILEGES FOR ROLE role_delete_object
      """
    Then the result should be, in any order:
      | role                 | type    | object                          | actions                                      |
      | "role_delete_object" | "GRAPH" | "/default_schema/ldbc"          | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
      | "role_delete_object" | "GRAPH" | "/default_schema/delete_object" | LIST ["MATCH", "INDEX"]                      |
    # delete graph
    When executing query:
      """
      DROP GRAPH IF EXISTS delete_object
      """
    Then the execution should be successful
    And action "INDEX" on "GRAPH" for role "role_delete_object" should be revoked
    When executing query:
      """
      SHOW PRIVILEGES FOR ROLE role_delete_object
      """
    Then the result should be, in any order:
      | role                 | type    | object                 | actions                                      |
      | "role_delete_object" | "GRAPH" | "/default_schema/ldbc" | LIST ["MATCH", "INSERT", "DELETE", "UPDATE"] |
    And drop the graph type "delete_object_type"
    And drop the role "role_delete_object"
    And close the current session
