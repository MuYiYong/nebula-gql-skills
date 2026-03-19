# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: User

  Scenario: authenticate
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_auth_test_user10",
        "password": "a123456789",
        "ifNotExists": true
      }
      """
    Then an Error should be raised: "[NH001]: The password must be at least 8 characters long and should include at least one digit, one lowercase letter, and one uppercase letter"
    When create a new user:
      """
      {
        "username": "user_auth_test_user0",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_auth_test_user0" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_auth_test_user0
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "user_auth_test_user0" and password "NebulaGraph01"
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_auth_test_user0"
    And logout from the meta

  Scenario: create user
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_create_test_user1",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    When create a new user:
      """
      {
        "username": "user_create_test_user2",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    When list user:
      """
      {
        "usernames": [
          "user_create_test_user1",
          "user_create_test_user2"
        ]
      }
      """
    Then the result should be, in any order:
      | username                 | active | auth_type  |
      | "user_create_test_user1" | true   | "password" |
      | "user_create_test_user2" | true   | "password" |
    When create a new user:
      """
      {
        "username": "user_create_test_user1",
        "password": "NebulaGraph02",
        "ifNotExists": false
      }
      """
    Then an Error should be raised: "[NH002]: User `user_create_test_user1` exist"
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_create_test_user1" should be ready to use
    And user "user_create_test_user2" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_create_test_user1
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_users() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name                     | home_schema       | home_graph |
      | "user_create_test_user1" | "/default_schema" | ""         |
      | "user_create_test_user2" | "/default_schema" | ""         |
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /home/user_create_test_user11
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_create_test_user1" should be granted
    And switch to a new session with username "user_create_test_user1" and password "NebulaGraph01"
    When executing query:
      """
      SET USER GRAPH ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_users() RETURN  name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name                     | home_schema       | home_graph             |
      | "user_create_test_user1" | "/default_schema" | "/default_schema/ldbc" |
      | "user_create_test_user2" | "/default_schema" | ""                     |
    When executing query:
      """
      SET USER SCHEMA /home/user_create_test_user11
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_users() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name                     | home_schema                     | home_graph             |
      | "user_create_test_user1" | "/home/user_create_test_user11" | "/default_schema/ldbc" |
      | "user_create_test_user2" | "/default_schema"               | ""                     |
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      DROP SCHEMA IF EXISTS /home/user_create_test_user11
      """
    Then the execution should be successful
    And switch to a new session with username "user_create_test_user1" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_users() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name                     | home_schema       | home_graph             |
      | "user_create_test_user1" | ""                | "/default_schema/ldbc" |
      | "user_create_test_user2" | "/default_schema" | ""                     |
    When executing query:
      """
      RETURN 1
      """
    Then the result should be, in any order:
      | 1 |
      | 1 |
    When executing query:
      """
      USE ldbc MATCH (v) RETURN v
      """
    Then an Error should be raised: "[NC002]: Catalog schema not found:"
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_create_test_user1"
    And drop the user "user_create_test_user2"
    And logout from the meta

  Scenario: change password
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_alter_test_password",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_alter_test_password" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_alter_test_password
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER USER user_alter_test_password WITH PASSWORD "NebulaGraph02"
      """
    Then an Error should be raised: "[NR407]: Alter password failed: only allowed alter own password"
    And action "CONNECT" on "SVCGRP" for user "user_alter_test_password" should be granted
    And switch to a new session with username "user_alter_test_password" and password "NebulaGraph01"
    When executing query:
      """
      ALTER USER root WITH PASSWORD "NebulaGraph02"
      """
    Then an Error should be raised: "[NR407]: Alter password failed: only allowed alter own password"
    When executing query:
      """
      ALTER USER user_alter_test_password WITH PASSWORD "NebulaGraph01"
      """
    Then an Error should be raised: "[NR407]: Alter password failed: new password cannot be the same as the old password"
    When executing query:
      """
      ALTER USER user_alter_test_password WITH PASSWORD "NebulaGraph02"
      """
    Then the execution should be successful
    And switch to a new session with username "user_alter_test_password" and password "NebulaGraph02"
    When executing query:
      """
      CALL show_users() RETURN  name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name                       | home_schema       | home_graph |
      | "user_alter_test_password" | "/default_schema" | ""         |
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_alter_test_password"
    And logout from the meta

  Scenario: alter user
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_alter_test_user3",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    When alter user:
      """
      {
        "active": false,
        "username": "user_alter_test_user3",
        "password": "NebulaGraph03"
      }
      """
    Then the execution should be successful
    When list user:
      """
      {
        "usernames": [
          "user_alter_test_user3"
        ]
      }
      """
    Then the result should be, in any order:
      | username                | active | auth_type  |
      | "user_alter_test_user3" | false  | "password" |
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_alter_test_user3" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_alter_test_user3
      """
    Then the execution should be successful
    And close the current session
    # cannot alter disabled user
    And login meta with username "root" and password "NebulaGraph01"
    When alter user:
      """
      {
        "active": true,
        "username": "user_alter_test_user3",
        "password": "NebulaGraph03"
      }
      """
    Then an Error should be raised: "[NH004]: User `user_alter_test_user3` disabled"
    When alter user:
      """
      {
        "active": true,
        "username": "user_alter_test_user3"
      }
      """
    Then the execution should be successful
    When alter user:
      """
      {
        "active": true,
        "username": "user_alter_test_user3",
        "password": "NebulaGraph04"
      }
      """
    Then the execution should be successful
    And drop the user "user_alter_test_user3"
    And logout from the meta

  Scenario: remove user
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {
        "username": "user_remove_test_user4",
        "password": "NebulaGraph01",
        "ifNotExists": true
      }
      """
    Then the execution should be successful
    When list user:
      """
      {
        "usernames": [
          "user_remove_test_user4"
        ]
      }
      """
    Then the result should be, in any order:
      | username                 | active | auth_type  |
      | "user_remove_test_user4" | true   | "password" |
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_remove_test_user4" should be ready to use
    When executing query:
      """
      REMOVE USER user_remove_test_user4
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_remove_test_user4"
    When list user:
      """
      {
        "usernames": [
          "user_remove_test_user4"
        ]
      }
      """
    Then the result should be, in any order:
      | username | active | auth_type |
    And logout from the meta

  Scenario: set temp schema as home schema
    When executing query:
      """
      ALTER USER root SET HOME_SCHEMA /tmp_schema
      """
    Then an Error should be raised: "[NS000]: Semantic error: The schema `/tmp_schema` is reserved and cannot be used"
    When executing query:
      """
      ALTER USER root SET HOME_GRAPH #analytic_ldbc
      """
    Then an Error should be raised: "[42001]: syntax error near `#analytic_ldbc`"

  Scenario: vesoft-inc/nebula-ng#8956
    And create a new user session with username "user_test_user_8956" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /test_schema_8956
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER USER user_test_user_8956 SET HOME_SCHEMA /test_schema_8956
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER USER user_test_user_8956 SET HOME_SCHEMA ../test_schema_8956
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER USER user_test_user_8956 SET HOME_GRAPH /default_schema/ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER USER user_test_user_8956 SET HOME_GRAPH ../default_schema/ldbc
      """
    Then the execution should be successful
    When executing query:
      """
      CALL dbms.show_current_user() RETURN name, `home_schema`, `home_graph`
      """
    Then the result should contain:
      | name                  | home_schema         | home_graph             |
      | "user_test_user_8956" | "/test_schema_8956" | "/default_schema/ldbc" |
    When executing query:
      """
      DROP SCHEMA IF EXISTS /test_schema_8956
      """
    Then the execution should be successful
    And close current session and drop the user "user_test_user_8956"
