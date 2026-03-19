# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: procedure acl

  Scenario: procedure acl
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"uproc", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "uproc" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER uproc
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "uproc" should be granted
    When executing query:
      """
      create or replace procedure ufoo() RETURNS ret int AS {
        return 1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      create or replace procedure ufoo(a int) RETURNS ret int AS {
        return a + 1
      }
      """
    Then the execution should be successful
    And switch to a new session with username "uproc" and password "NebulaGraph01"
    When executing query:
      """
      call ufoo() return *
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [EXECUTE] on PROCEDURE ufoo()"
    When executing query:
      """
      call ufoo(1) return *
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [EXECUTE] on PROCEDURE ufoo(INT64)"
    When executing query:
      """
      DROP PROCEDURE ufoo(int)
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [DROP] on PROCEDURE ufoo(INT64)"
    When executing query:
      """
      ALTER PROCEDURE ufoo() RENAME to ufoo2
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [ALTER] on PROCEDURE ufoo()"
    When executing query:
      """
      CREATE PROCEDURE ubar() RETURNS (ret int) { return 1 }
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [CREATE_PROCEDURE] on SCHEMA /default_schema"
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      GRANT EXECUTE ON PROCEDURE `/default_schema/ufoo`() TO USER uproc
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ALTER ON PROCEDURE `/default_schema/ufoo`() TO USER uproc
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT DROP ON PROCEDURE `/default_schema/ufoo`(int) TO USER uproc
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CREATE PROCEDURE ON SCHEMA /default_schema TO USER uproc
      """
    Then the execution should be successful
    And switch to a new session with username "uproc" and password "NebulaGraph01"
    And action "EXECUTE" on "PROCEDURE" for user "uproc" should be granted
    And action "ALTER" on "PROCEDURE" for user "uproc" should be granted
    And action "DROP" on "PROCEDURE" for user "uproc" should be granted
    And action "CREATE_PROCEDURE" on "SCHEMA" for user "uproc" should be granted
    When executing query:
      """
      call ufoo() return *
      """
    Then the result should be, in any order:
      | ret |
      | 1   |
    When executing query:
      """
      call ufoo(1) return *
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [EXECUTE] on PROCEDURE ufoo(INT64)"
    When executing query:
      """
      ALTER PROCEDURE ufoo() RENAME to ufoo2
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER PROCEDURE ufoo(int) RENAME to ufoo3
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [ALTER] on PROCEDURE ufoo(INT64)"
    When executing query:
      """
      call ufoo2() return *
      """
    Then the result should be, in any order:
      | ret |
      | 1   |
    When executing query:
      """
      CREATE PROCEDURE ubar() RETURNS (ret int) { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      call ubar() return *
      """
    Then the result should be, in any order:
      | ret |
      | 1   |
    When executing query:
      """
      DROP PROCEDURE ufoo(int)
      """
    Then the execution should be successful
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE PROCEDURE ga1() RETURNS (ret int) { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT ALTER ANY PROCEDURE ON SCHEMA /default_schema TO USER uproc
      """
    Then the execution should be successful
    And switch to a new session with username "root" and password "NebulaGraph01"
    And action "ALTER_ANY_PROCEDURE" on "SCHEMA" for user "uproc" should be granted
    When executing query:
      """
      ALTER PROCEDURE ga1() RENAME to ga2
      """
    Then the execution should be successful
    And drop the procedure "ufoo2"
    And drop the procedure "ubar"
    And drop the procedure "ga2"
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE insert_proc(a int, b string) {use ldbc insert (v:Person{id:a, firstName:b})}
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT EXECUTE ANY PROCEDURE ON SCHEMA /default_schema TO USER uproc
      """
    Then the execution should be successful
    And action "EXECUTE_ANY_PROCEDURE" on "SCHEMA" for user "uproc" should be granted
    And switch to a new session with username "uproc" and password "NebulaGraph01"
    When executing query:
      """
      CALL insert_proc(1,"tom") FINISH
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Action [INSERT] on NODE_PROPERTY /default_schema/ldbc.Person.id"
    And switch to a new session with username "root" and password "NebulaGraph01"
    And drop the procedure "insert_proc"
    And drop the user "uproc"
