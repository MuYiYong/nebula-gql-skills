# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: call named GQL procedure

  Scenario: basic
    When executing query:
      """
      create procedure foo() RETURNS ret int AS {
        return 1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      create procedure cp1() RETURNS ret int AS { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      create procedure cp2() RETURNS ret int AS { return 2 }
      """
    Then the execution should be successful
    When executing query:
      """
      create procedure foo() RETURNS ret int AS {
        return 1
      }
      """
    Then an Error should be raised: "[NC113]: Procedure already exist: conflict with existing procedure: foo()"
    When executing query:
      """
      LET arry = LIST[1, 2, 3]
      FOR val IN arry
      CALL foo()
      RETURN val, ret
      """
    Then the result should be, in any order:
      | val | ret |
      | 1   | 1   |
      | 2   | 1   |
      | 3   | 1   |
    When executing query:
      """
      LET s = SET{1, 2, 3}
      FOR val IN s
      CALL foo()
      RETURN val, ret
      """
    Then the result should be, in any order:
      | val | ret |
      | 1   | 1   |
      | 2   | 1   |
      | 3   | 1   |
    When executing query:
      """
      create procedure bar() RETURNS ret int AS { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      create procedure bar() RETURNS ret int AS { return 1 }
      """
    Then an Error should be raised: "[NC113]: Procedure already exist: conflict with existing procedure: bar()"
    When executing query:
      """
      create procedure baz(a int) RETURNS ret int AS { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      create procedure qux(a int, b string) RETURNS (ret int, name string) AS { return 1, "hello" }
      """
    Then the execution should be successful
    # create a procedure with void result
    When executing query:
      """
      create procedure boo(a int, b string) RETURNS () AS {
        LET y = 2 FINISH
      }
      """
    Then the execution should be successful
    When executing query:
      """
      create or replace procedure proc_return() returns (){return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_return() FINISH
      """
    Then an Error should be raised: "[NP107]: Procedure return type mismatch expect return 0 column(s) but got 1 column(s)"
    And drop the procedure "foo"
    And drop the procedure "bar"
    And drop the procedure "baz"
    And drop the procedure "qux"
    And drop the procedure "boo"
    And drop the procedure "proc_return"
    # test void gql proc
    When executing query:
      """
      CREATE PROCEDURE proc_void() RETURNS () { FINISH }
      """
    Then the execution should be successful
    When executing query:
      """
      LET arry = LIST[1, 2, 3]
      FOR val IN arry
      CALL proc_void()
      RETURN arry, val
      """
    Then the result should be, in any order:
      | arry | val |
    When executing query:
      """
      LET arry = LIST[1, 2, 3]
      FOR val IN arry
      OPTIONAL CALL proc_void()
      RETURN arry, val
      """
    Then the result should be, in any order:
      | arry          | val |
      | LIST[1, 2, 3] | 1   |
      | LIST[1, 2, 3] | 2   |
      | LIST[1, 2, 3] | 3   |
    When executing query:
      """
      LET s = SET{1, 2, 3}
      FOR val IN s
      CALL proc_void()
      RETURN s, val
      """
    Then the result should be, in any order:
      | s | val |
    When executing query:
      """
      LET s = SET{1, 2, 3}
      FOR val IN s
      OPTIONAL CALL proc_void()
      RETURN s, val
      """
    Then the result should be, in any order:
      | s            | val |
      | SET{1, 2, 3} | 1   |
      | SET{1, 2, 3} | 2   |
      | SET{1, 2, 3} | 3   |
    And drop the procedure "proc_void"
    # test nested proc call
    When executing query:
      """
      CREATE PROCEDURE proc_callee() RETURNS ret INT AS {
        RETURN 1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE proc_caller() RETURNS ret INT AS {
        CALL proc_callee() RETURN ret
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_caller() RETURN *
      """
    Then the result should be, in any order:
      | ret |
      | 1   |
    And drop the procedure "proc_callee"
    When executing query:
      """
      CALL proc_caller() RETURN *
      """
    Then an Error should be raised: "[01G12]: Procedure not found: `proc_callee`"
    And drop the procedure "proc_caller"
    # test proc with branching statement
    When executing query:
      """
      CREATE PROCEDURE proc_branching(a int) RETURNS ret INT AS {
        IF a > 0 THEN {
            RETURN 0 as x
        } ELSE {
            RETURN 1 as x
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_branching(0) RETURN *
      """
    Then the result should be, in any order:
      | ret |
      | 1   |
    When executing query:
      """
      CALL proc_branching(1) RETURN *
      """
    Then the result should be, in any order:
      | ret |
      | 0   |
    And drop the procedure "proc_branching"
    When executing query:
      """
      CREATE PROCEDURE ret_error(a int, b string) RETURNS (ret int, name string) AS { return a }
      """
    Then the execution should be successful
    When executing query:
      """
      call ret_error(1, "a") return *
      """
    Then an Error should be raised: "[NP107]: Procedure return type mismatch expect return 2 column(s) but got 1 column(s)"
    And drop the procedure "ret_error"

  Scenario: default proc arg
    When executing query:
      """
      create or replace procedure foo_default_arg(a int DEFAULT 123) RETURNS ret int AS {
        return 1 + a
      }
      """
    Then the execution should be successful
    When executing query:
      """
      call show_procedures()
      filter where proc_type = "GQL" and name = "foo_default_arg"
      return proc_type, module,  name, parameters, return_fields, comment
      """
    Then the result should be, in any order:
      | proc_type | module | name              | parameters            | return_fields | comment |
      | "GQL"     | ""     | "foo_default_arg" | "a:INT64 DEFAULT 123" | "ret:INT64"   | ""      |
    When executing query:
      """
      call foo_default_arg(2) return *
      """
    Then the result should be, in any order:
      | ret |
      | 3   |
    When executing query:
      """
      call foo_default_arg() return *
      """
    Then the result should be, in any order:
      | ret |
      | 124 |
    And drop the procedure "foo_default_arg"
    When executing query:
      """
      create procedure foo_default_arg1(a int DEFAULT 123, b int) RETURNS ret int AS {
        return 1 + a
      }
      """
    Then an Error should be raised: "[NP108]: Invalid procedure definition argument `b` should have default value"
    When executing query:
      """
      create procedure foo_default_arg1(a int DEFAULT 1, b int DEFAULT 2) RETURNS ret int AS {
        return a + b
      }
      """
    Then the execution should be successful
    When executing query:
      """
      call foo_default_arg1() return *
      """
    Then the result should be, in any order:
      | ret |
      | 3   |
    When executing query:
      """
      call foo_default_arg1(2) return *
      """
    Then the result should be, in any order:
      | ret |
      | 4   |
    When executing query:
      """
      call foo_default_arg1(3) return *
      """
    Then the result should be, in any order:
      | ret |
      | 5   |
    And drop the procedure "foo_default_arg1"
    When executing query:
      """
      create procedure foo_default_arg2(a int DEFAULT 8 + 9, b int DEFAULT 10 * 3) RETURNS ret int AS {
        return a + b
      }
      """
    Then the execution should be successful
    When executing query:
      """
      call foo_default_arg2() return *
      """
    Then the result should be, in any order:
      | ret |
      | 47  |
    And drop the procedure "foo_default_arg2"
    # FIX https://github.com/vesoft-inc/nebula-ng/issues/6683
    When executing query:
      """
      create procedure foo_default_arg3(a int DEFAULT "hello") RETURNS ret int AS {
        return a
      }
      """
    Then an Error should be raised: "[NR008]: Invalid cast expression: `CAST(\"hello\" AS INT64)`, can not cast from `STRING` to `INT64`"
    When executing query:
      """
      create procedure foo_one_arg (a int )returns ret int {return a}
      """
    Then the execution should be successful
    When executing query:
      """
      call foo_one_arg() return *
      """
    Then an Error should be raised: "[01G12]: Procedure not found: `foo_one_arg()`"
    And drop the procedure "foo_one_arg"

  Scenario: graph type created in the same query is invisible to named gql procedure
    When executing query:
      """
      create or replace procedure proc_create_gt(){
          create graph type if not exists g_ddl as {node Person (label Person {id int primary key, name string})}
      }
      """
    Then the execution should be successful
    When executing query:
      """
      create or replace procedure proc_alter_gt(){
          alter graph type g_ddl {add node type City (label City {id int primary key, name string})}
      }
      """
    When executing query:
      """
      create or replace procedure proc_test(){
          call proc_create_gt() finish
          call proc_alter_gt() finish
      }
      """
    When executing query:
      """
      call proc_test() finish
      """
    Then an Error should be raised: "[01G04]: Graph type not found: `g_ddl`"
    And drop the procedure "proc_create_gt"
    And drop the procedure "proc_alter_gt"
    And drop the procedure "proc_test"

  Scenario: duplicate proc arg
    When executing query:
      """
      create procedure dup_arg_proc(a int, a int) RETURNS ret int AS {
        return 1 + a
      }
      """
    Then an Error should be raised: "[NP108]: Invalid procedure definition duplicate procedure argument `a`"

  # FIX https://github.com/vesoft-inc/nebula-ng/issues/6666
  Scenario: gql proc symbol
    When executing query:
      """
      create procedure run_gql_proc(vid int DEFAULT 3) RETURNS ret int AS {         match (v{id: vid}) limit 1 return v.id       }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc CALL run_gql_proc() return *
      """
    Then the result should be, in any order:
      | ret |
      | 3   |
    When executing query:
      """
      USE ldbc CALL run_gql_proc(4) return *
      """
    Then the result should be, in any order:
      | ret |
      | 4   |
    And drop the procedure "run_gql_proc"

  Scenario: replace procedure
    When executing query:
      """
      create procedure proc_replace() RETURNS ret int AS { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      call proc_replace() return *
      """
    Then the result should be, in any order:
      | ret |
      | 1   |
    When executing query:
      """
      create or replace procedure proc_replace() RETURNS ret int AS { return 8848 }
      """
    Then the execution should be successful
    When executing query:
      """
      USE ldbc CALL proc_replace() return *
      """
    Then the result should be, in any order:
      | ret  |
      | 8848 |
    And drop the procedure "proc_replace"
    When executing query:
      """
      create procedure proc_replace2(a int) RETURNS ret int AS { return a }
      """
    Then the execution should be successful
    When executing query:
      """
      create or replace procedure proc_replace2(b int) RETURNS ret int AS { return b }
      """
    Then the execution should be successful
    When executing query:
      """
      show create procedure proc_replace2
      """
    Then the result should be, in any order:
      | proc_type | create_statement                                                                         |
      | "GQL"     | "CREATE PROCEDURE proc_replace2(b INT64) RETURNS (ret INT64) LANGUAGE GQL{\nreturn b\n}" |
    When executing query:
      """
      drop procedure proc_replace2
      """
    Then the execution should be successful

  Scenario: proc characteristic
    # comment
    When executing query:
      """
      create or replace procedure proc_comment() RETURNS (ret int) COMMENT "this is a comment" AS { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      show procedure proc_comment
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name           | parameters | return_fields | null_case                   | comment             |
      | "GQL"     | ""     | "/default_schema" | "root" | "proc_comment" | ""         | "ret:INT64"   | "raise error on null input" | "this is a comment" |
    When executing query:
      """
      desc procedure proc_comment
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name           | parameters | return_fields | null_case                   | comment             |
      | "GQL"     | ""     | "/default_schema" | "root" | "proc_comment" | ""         | "ret:INT64"   | "raise error on null input" | "this is a comment" |
    # TODO: we don't support null-case for now
    When executing query:
      """
      create procedure proc_ret() RETURNS (ret int) RETURNS NULL ON NULL INPUT COMMENT "this is a comment" AS { return 1 }
      """
    Then an Error should be raised: "[NP101]: Procedure error: Illegal create procedure statement, unsupported null call behavior returns null on null input"
    When executing query:
      """
      create procedure proc_ret() RETURNS (ret int) CALLED ON NULL INPUT COMMENT "this is a comment" AS { return 1 }
      """
    Then an Error should be raised: "[NP101]: Procedure error: Illegal create procedure statement, unsupported null call behavior called on null input"
    When executing query:
      """
      create procedure proc_gql_lang() RETURNS (ret int) LANGUAGE GQL COMMENT "gql proc" AS { return 1 }
      """
    Then the execution should be successful
    When executing query:
      """
      create procedure proc_cpp_lang() RETURNS (ret int) LANGUAGE CPP COMMENT "cpp proc" AS { return 1 }
      """
    Then an Error should be raised: "[NP101]: Procedure error: Illegal create procedure statement, unsupported procedure type CPP"

  Scenario: recursive proc
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE fibonacci(a int) RETURNS ret INT AS {
        IF a > 0 THEN {
          call fibonacci(a - 1) return ret + a AS x
        } ELSE {
          RETURN 0 as x
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      call fibonacci(0) return *
      """
    Then the result should be, in any order:
      | ret |
      | 0   |
    When executing query:
      """
      call fibonacci(1) return *
      """
    Then the result should be, in any order:
      | ret |
      | 1   |
    When executing query:
      """
      call fibonacci(2) return *
      """
    Then the result should be, in any order:
      | ret |
      | 3   |
    # TODO tck added PROFILE to every call stmt, with this deep recursion query,
    # the plan info profile will cause grpc cpp into a deserialization problem.
    # see: https://github.com/grpc/grpc/blob/master/include/grpcpp/impl/client_unary_call.h#L89-L91
    # ngql(grpc go client) works fine
    # When executing query:
    # """
    # call fibonacci(100) return *
    # """
    # Then the result should be, in any order:
    # | ret  |
    # | 5050 |
    When executing query:
      """
      drop procedure fibonacci
      """
    Then the execution should be successful

  Scenario: drop proc
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE dp1(a int) RETURNS ret INT AS {
        return 1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE dp1(STRING)
      """
    Then an Error should be raised: "[01G12]: Procedure not found: `dp1(STRING)`"
    When executing query:
      """
      DROP PROCEDURE dp1(int)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE dp2(a int) RETURNS ret INT AS {
        return 1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE dp2(hahaha int)
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE IF EXISTS dp2(hahaha int)
      """
    Then the execution should be successful

  Scenario: show create proc
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE sp1(a int) RETURNS ret INT AS {return 1}
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CREATE PROCEDURE sp1
      """
    Then the result should be, in any order:
      | proc_type | create_statement                                                               |
      | "GQL"     | "CREATE PROCEDURE sp1(a INT64) RETURNS (ret INT64) LANGUAGE GQL{\nreturn 1\n}" |
    When executing query:
      """
      SHOW CREATE PROCEDURE sp2
      """
    Then an Error should be raised: "[01G12]: Procedure not found: `sp2`"

  Scenario: alter procedure
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE ap1(a int) RETURNS ret INT AS { return 1 }
      """
    Then the execution should be successful
    # alter name
    When executing query:
      """
      ALTER PROCEDURE ap1(int) RENAME to ap2
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PROCEDURE `ap.`
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name  | parameters | return_fields | null_case                   | comment |
      | "GQL"     | ""     | "/default_schema" | "root" | "ap2" | "a:INT64"  | "ret:INT64"   | "raise error on null input" | ""      |
    # alter comment
    When executing query:
      """
      ALTER PROCEDURE ap2(int) COMMENT "hello world"
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PROCEDURE `ap.`
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name  | parameters | return_fields | null_case                   | comment       |
      | "GQL"     | ""     | "/default_schema" | "root" | "ap2" | "a:INT64"  | "ret:INT64"   | "raise error on null input" | "hello world" |
    # alter null case
    When executing query:
      """
      ALTER PROCEDURE ap2(int) CALLED ON NULL INPUT
      """
    Then an Error should be raised: "[NP101]: Procedure error: Illegal alter procedure statement, unsupported null call behavior called on null input"
    # alter language
    When executing query:
      """
      ALTER PROCEDURE ap2(int) LANGUAGE CPP
      """
    Then an Error should be raised: "[NP101]: Procedure error: Illegal alter procedure statement, unable to change procedure language type."
    When executing query:
      """
      DROP PROCEDURE ap2
      """
    Then the execution should be successful

  Scenario: set val and delete in procedure
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_proc AS {
        NODE TYPE N1 (LABEL N1 {id INT PRIMARY KEY, val int})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_proc TYPED gt_proc
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_proc INSERT (@N1{id: 1, val: 1024})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_set(nv int) RETURNS () { USE g_proc match (v{id: 1}) set v.val = nv }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_set(8848) FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_proc MATCH (v{id: 1}) RETURN v.val AS val
      """
    Then the result should be, in any order:
      | val  |
      | 8848 |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_del() RETURNS () { USE g_proc match (v{id: 1}) delete v }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_del() FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_proc MATCH (v{id: 1}) RETURN v.val AS val
      """
    Then the result should be, in any order:
      | val |
    And drop the procedure "proc_set"
    And drop the procedure "proc_del"
    And drop the graph "g_proc"
    And drop the graph type "gt_proc"

  Scenario: proc override
    When executing query:
      """
      CREATE PROCEDURE o1(a int) {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE o1(b int) {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE IF NOT EXISTS o1(c int) {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE o1(a int, b int) {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE o1(a int, b int, c int DEFAULT 2) {FINISH}
      """
    Then an Error should be raised: "[NC113]: Procedure already exist: conflict with existing procedure: o1(INT64, INT64)"
    When executing query:
      """
      CREATE PROCEDURE o1(a int, b int DEFAULT 2) {FINISH}
      """
    Then an Error should be raised: "[NC113]: Procedure already exist: conflict with existing procedure: o1(INT64)"
    When executing query:
      """
      show procedure o1
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name | parameters         | return_fields | null_case                   | comment |
      | "GQL"     | ""     | "/default_schema" | "root" | "o1" | "b:INT64"          | ""            | "raise error on null input" | ""      |
      | "GQL"     | ""     | "/default_schema" | "root" | "o1" | "a:INT64, b:INT64" | ""            | "raise error on null input" | ""      |
    When executing query:
      """
      DROP PROCEDURE o1(int)
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE o1(int, int)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE o2(a int32) RETURNS (ret int) { return 32 }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE o2(a int64) RETURNS (ret int) { return 64 }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL o2(CAST(1 as int32)) RETURN *
      """
    Then the result should be, in any order:
      | ret |
      | 32  |
    When executing query:
      """
      CALL o2(CAST(1 as int64)) RETURN *
      """
    Then the result should be, in any order:
      | ret |
      | 64  |
    When executing query:
      """
      CALL o2("hello") RETURN *
      """
    Then an Error should be raised: "[01G12]: Procedure not found: `o2(STRING)`"
    When executing query:
      """
      DROP PROCEDURE o2(int64)
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE o2(int32)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE test01() {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER PROCEDURE test01() RENAME TO test01
      """
    Then an Error should be raised: "[NC113]: Procedure already exist: request to change procedure name to its original name"
    When executing query:
      """
      CREATE PROCEDURE test02() {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER PROCEDURE test01() RENAME TO test02
      """
    Then an Error should be raised: "[NC113]: Procedure already exist: conflict with existing procedure: test02()"
    When executing query:
      """
      ALTER PROCEDURE test01() CALLED ON NULL INPUT
      """
    Then an Error should be raised: "[NP101]: Procedure error: Illegal alter procedure statement, unsupported null call behavior called on null input"
    When executing query:
      """
      ALTER PROCEDURE test01() RETURNS NULL ON NULL INPUT
      """
    Then an Error should be raised: "[NP101]: Procedure error: Illegal alter procedure statement, unsupported null call behavior returns null on null input"
    And drop the procedure "test01"
    And drop the procedure "test02"
    # alter override
    When executing query:
      """
      CREATE PROCEDURE drop1(a int) {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE drop1() {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE drop1
      """
    Then an Error should be raised: "[NP109]: Unable to drop multiple procedure: drop1(), drop1(INT64)"
    When executing query:
      """
      DROP PROCEDURE drop1(int)
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE drop1
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE alter1(a int DEFAULT 1) {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE alter1(a int, b int) {FINISH}
      """
    Then the execution should be successful
    When executing query:
      """
      ALTER PROCEDURE alter1(int) RENAME TO alter2
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE alter1
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE alter2
      """
    Then the execution should be successful

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/7301
  Scenario: proc create schema
    When executing query:
      """
      create or replace procedure proc_create_schema01() { create schema /test_udp_08 }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_create_schema01() FINISH
      """
    Then the execution should be successful

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/7590
  Scenario: init analytic ctx
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE log_test() AS {
        LOG_INFO("x == ",1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      call log_test() finish
      """
    Then the execution should be successful
    And drop the procedure "log_test"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/7670
  Scenario: init analytic ctx
    When executing query:
      """
      CREATE OR replace PROCEDURE proc_const_fold() RETURNS (ret INT64) LANGUAGE GQL {
        return 1 + 1 + 1 +  1 + 1 + 1 +  1 + 1 + 1 +  1 + 1 + 1 + 1 + 1 + 1 +  1 + 1 + 1 +  1 + 1 + 1 +  1 + 1 + 1 + 1 + 1 + 1 +  1 + 1 + 1 +  1 + 1 + 1 +  1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      FOR i IN RANGE(1, 256) CALL proc_const_fold() FINISH
      """
    Then the execution should be successful
    And drop the procedure "proc_const_fold"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8098
  Scenario: result cast
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_a (n int ) RETURNS ret INT {
                value a int = 0
                while a < 10 then {set a = a+1 }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_a(10) RETURN *
      """
    Then an Error should be raised: "[NP107]: Procedure return type mismatch expect return 1 column(s) but got 0 column(s)"
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_b (n int ) RETURNS () {
                value a int = 0
                while a < 10 then {set a = a+1 }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_b(10) FINISH
      """
    Then the execution should be successful
    And drop the procedure "proc_a"
    And drop the procedure "proc_b"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8129
  Scenario: result cast
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE tt() RETURNS (a INT64) {
        finish
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL tt() RETURN *
      """
    Then an Error should be raised: " [NP107]: Procedure return type mismatch expect return 1 column(s) but got 0 column(s)"
    And drop the procedure "tt"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/8331
  Scenario: result cast
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE r_proc_sub_a(a INT, b INT) RETURNS c INT{RETURN a-b}
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE r_proc_sub_a(a FLOAT, b FLOAT) RETURNS c FLOAT{RETURN a-b}
      """
    Then the execution should be successful
    When executing query:
      """
      CALL r_proc_sub_a(11,1) RETURN *
      """
    Then the result should be, in any order:
      | c  |
      | 10 |
    When executing query:
      """
      CALL r_proc_sub_a(11,1.0) RETURN *
      """
    Then the result should be, in any order:
      | c    |
      | 10.0 |
    And drop the procedure "tt"
    When executing query:
      """
      DROP PROCEDURE r_proc_sub_a(INT, INT)
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE r_proc_sub_a(FLOAT, FLOAT)
      """
    Then the execution should be successful

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9099
  Scenario: proc rctx copy
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS geo_dql_gt AS {
          NODE TYPE Geog(labels Geog {id string PRIMARY KEY, name string, g Geography}),
          NODE TYPE GPoint(labels roads {id string PRIMARY KEY, name string, g Geography(point)}),
          NODE TYPE GLine(labels roads {id string PRIMARY KEY, name string, g Geography(linestring)}),
          NODE TYPE GPolygon(labels roads {id string PRIMARY KEY, name string, g Geography(polygon)}),
          EDGE TYPE point_in_linestring (GPoint)-[labels spatial_relationship {relation_type string, distance double}]->(GLine),
          EDGE TYPE geog_contain_point (Geog)-[labels spatial_relationship {relation_type string, distance double}]->(GPoint)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH geo_dql_g geo_dql_gt
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo_dql_g INSERT (p_beijing@GPoint{id: "p_beijing", name: "北京天安门", g: ST_Point(116.3975, 39.9087)})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE PROCEDURE IF NOT EXISTS geo_test (t_point GEOGRAPHY(POINT)) RETURNS (type_name STRING, node_name STRING, geog GEOGRAPHY) AS {
        MATCH (v)
        WHERE ST_Intersects(v.g, t_point)
        RETURN type(v) as type_name, v.name as node_name, v.g as geog
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE geo_dql_g CALL geo_test(ST_Point(116.3975, 39.9087)) RETURN type_name, node_name, geog
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE geo_test
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH geo_dql_g
      """
    Then the execution should be successful
    When executing query:
      """
      DROP GRAPH TYPE geo_dql_gt
      """
    Then the execution should be successful

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/9126
  Scenario: set proc param
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE set_proc_param_test1 (a INT) RETURNS r INT  {
        SET a = a + 1
        RETURN a
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL set_proc_param_test1(3) RETURN r
      """
    Then the result should be, in any order:
      | r |
      | 4 |
    And drop the procedure "set_proc_param_test1"

  @sf01
  Scenario: Node Edge proc param
    # Test EDGE parameter with show/show create
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE set_proc_param_test (a EDGE) RETURNS r INT  {
        RETURN 1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PROCEDURE set_proc_param_test
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name                  | parameters | return_fields | null_case                   | comment |
      | "GQL"     | ""     | "/default_schema" | "root" | "set_proc_param_test" | "a:EDGE"   | "r:INT64"     | "raise error on null input" | ""      |
    When executing query:
      """
      SHOW CREATE PROCEDURE set_proc_param_test
      """
    Then the result should be, in any order:
      | proc_type | create_statement                                                                            |
      | "GQL"     | "CREATE PROCEDURE set_proc_param_test(a EDGE) RETURNS (r INT64) LANGUAGE GQL{\nRETURN 1\n}" |
    # Test NODE parameter with show/show create
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE set_proc_param_test (a NODE) RETURNS r INT  {
        RETURN 1
      }
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PROCEDURE set_proc_param_test
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name                  | parameters | return_fields | null_case                   | comment |
      | "GQL"     | ""     | "/default_schema" | "root" | "set_proc_param_test" | "a:NODE"   | "r:INT64"     | "raise error on null input" | ""      |
      | "GQL"     | ""     | "/default_schema" | "root" | "set_proc_param_test" | "a:EDGE"   | "r:INT64"     | "raise error on null input" | ""      |
    When executing query:
      """
      SHOW CREATE PROCEDURE set_proc_param_test
      """
    Then the result should be, in any order:
      | proc_type | create_statement                                                                            |
      | "GQL"     | "CREATE PROCEDURE set_proc_param_test(a NODE) RETURNS (r INT64) LANGUAGE GQL{\nRETURN 1\n}" |
      | "GQL"     | "CREATE PROCEDURE set_proc_param_test(a EDGE) RETURNS (r INT64) LANGUAGE GQL{\nRETURN 1\n}" |
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person) LIMIT 1
        RETURN v
        NEXT
        CALL set_proc_param_test(v)
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 1 |
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person)-[e]->(f:Person) LIMIT 1
        RETURN e
        NEXT
        CALL set_proc_param_test(e)
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 1 |
    When executing query:
      """
      CALL set_proc_param_test(1) RETURN r
      """
    Then an Error should be raised: "[01G12]: Procedure not found: `set_proc_param_test(INT32)`"
    When executing query:
      """
      DROP PROCEDURE set_proc_param_test(NODE)
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE set_proc_param_test(EDGE)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE set_proc_param_node(a NODE) RETURNS r INT  {
        MATCH (a)-[:KNOWS]->(f:Person) RETURN COUNT(f) AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 13194139534420})
      CALL set_proc_param_node(v)
      RETURN r
      """
    Then the result should be, in any order:
      | r |
      | 4 |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE set_proc_param_edge(e EDGE) RETURNS r INT  {
        MATCH ()-[e]->(f:Person) RETURN COUNT(f) AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 13194139534420})-[e:KNOWS]->()
      CALL set_proc_param_edge(e)
      RETURN r
      """
    Then the result should be, in any order:
      | r |
      | 1 |
      | 1 |
      | 1 |
      | 1 |
    When executing query:
      """
      USE sf01
      MATCH (v:Message)
      LIMIT 1
      CALL set_proc_param_node(v)
      RETURN r
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a)-[:KNOWS]->(f:Person)` was found"
    When executing query:
      """
      USE sf01
      MATCH ()-[e@FORUM_CONTAINER_OF_POST]->()
      LIMIT 1
      CALL set_proc_param_edge(e)
      RETURN r
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `()-[e]->(f:Person)` was found"
    And drop the procedure "set_proc_param_node"
    And drop the procedure "set_proc_param_edge"
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE corr_proc(a NODE) RETURNS r INT  {
        LET b = 1
        MATCH (a)-[:KNOWS]->(f:Person)
        WHERE f.id > b
        RETURN COUNT(f) + a.id AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 13194139534420})
      CALL corr_proc(v)
      RETURN r
      """
    Then the result should be, in any order:
      | r              |
      | 13194139534424 |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE dup_param1(a NODE) RETURNS r INT  {
        LET a = 1
        RETURN a AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 13194139534420})
      CALL dup_param1(v)
      RETURN r
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `a`"
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE dup_param2(a INT) RETURNS r INT  {
        MATCH (a:Person) RETURN COUNT(a) AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        LET v = 1
        CALL dup_param2(v)
        RETURN r
      }
      """
    Then an Error should be raised: "[42N23]: Invalid syntax, redefined variable: `a`"
    # node filter
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE node_filter(a NODE) RETURNS r INT  {
        MATCH (a:Person WHERE a.email <> 'Aleksandr13194139534420@gmail.com') RETURN COUNT(a) AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person{id: 13194139534420})
        CALL node_filter(v)
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 0 |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE node_filter(a NODE) RETURNS r INT  {
        MATCH (a:Person WHERE a.email = 'Aleksandr13194139534420@gmail.com') RETURN COUNT(a) AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person{id: 13194139534420})
        CALL node_filter(v)
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 1 |
    # edge filter
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE edge_filter(e EDGE) RETURNS r INT  {
        MATCH (a:Person)-[e WHERE e.creationDate = local_datetime('2012-05-13T01:11:10.759000', "%Y-%m-%dT%H:%M:%S")]->(f)
        RETURN f.id AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person{id: 13194139534420})-[e:KNOWS]->()
        CALL edge_filter(e)
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r              |
      | 28587302322548 |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE edge_filter(e EDGE) RETURNS r INT  {
        MATCH (a:Person)-[e WHERE e.creationDate <> local_datetime('2012-05-13T01:11:10.759000', "%Y-%m-%dT%H:%M:%S")]->(f)
        RETURN f.id AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person{id: 13194139534420})-[e:KNOWS]->()
        CALL edge_filter(e)
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r              |
      | 26388279068150 |
      | 24189255811254 |
      | 26388279067534 |
    # optional match
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE optional_match(a NODE) RETURNS r INT  {
        OPTIONAL MATCH (a:Person WHERE a.email <> 'Aleksandr13194139534420@gmail.com')-[]->(f) RETURN f.id AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        MATCH (v:Person{id: 13194139534420})
        CALL optional_match(v)
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r    |
      | null |
    And drop the procedure "corr_proc"
    And drop the procedure "dup_param1"
    And drop the procedure "dup_param2"
    And drop the procedure "node_filter"
    And drop the procedure "edge_filter"
    And drop the procedure "optional_match"

  @sf01
  Scenario: Binding table proc param
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE binding_table_proc (t TABLE) RETURNS r INT  {
        RETURN size(t) AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW PROCEDURE binding_table_proc
      """
    Then the result should be, in any order:
      | proc_type | module | schema            | owner  | name                 | parameters | return_fields | null_case                   | comment |
      | "GQL"     | ""     | "/default_schema" | "root" | "binding_table_proc" | "t:TABLE"  | "r:INT64"     | "raise error on null input" | ""      |
    When executing query:
      """
      SHOW CREATE PROCEDURE binding_table_proc
      """
    Then the result should be, in any order:
      | proc_type | create_statement                                                                                       |
      | "GQL"     | "CREATE PROCEDURE binding_table_proc(t TABLE) RETURNS (r INT64) LANGUAGE GQL{\nRETURN size(t) AS r\n}" |
    When executing query:
      """
      TABLE binding_values {id, name} = (1, "a"), (2, "b"), (3, "c")
      CALL binding_table_proc(binding_values)
      RETURN r
      """
    Then the result should be, in any order:
      | r |
      | 3 |
    When executing query:
      """
      CALL binding_table_proc(1) RETURN r
      """
    Then an Error should be raised: "[01G12]: Procedure not found: `binding_table_proc(INT32)`"
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE binding_table_export (t TABLE) RETURNS r INT  {
        EXPORT 100, "proc" INTO t
        RETURN size(t) AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE export_values {id, name} = (1, "seed")
      CALL binding_table_export(export_values)
      RETURN r
      """
    Then the result should be, in any order:
      | r |
      | 2 |
    When executing query:
      """
      TABLE export_values {id, name} = (1, "seed")
      CALL binding_table_export(export_values)
      FOR rec in export_values RETURN rec.id AS rid, rec.name AS rname
      """
    Then the result should be, in any order:
      | rid | rname  |
      | 1   | "seed" |
      | 100 | "proc" |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE append_table(t TABLE, idx INT32, name STRING) RETURNS r INT  {
        EXPORT idx, name INTO t
        RETURN size(t) AS r
      }
      """
    Then the execution should be successful
    # TODO: enable this test after fixing the concurrent proc execution problem
    # When executing query:
    # """
    # TABLE export_values {id, name} = (0, "seed")
    # LET indices = [1, 2]
    # LET names = ["proc_a"]
    # FOR idx IN indices
    # FOR name IN names
    # CALL append_table(export_values, idx, name)
    # FOR rec IN export_values RETURN rec.id AS rid, rec.name AS rname, r
    # """
    # Then the result should be, in any order:
    # | rid | rname    | r |
    # | 0   | "seed"   | 2 |
    # | 1   | "proc_a" | 2 |
    # | 2   | "proc_a" | 2 |
    # | 0   | "seed"   | 3 |
    # | 1   | "proc_a" | 3 |
    # | 2   | "proc_a" | 3 |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE nested_append_table(t TABLE) RETURNS r INT {
        LET indices = [1, 2, 3]
        LET names = ["proc_b", "proc_c"]
        FOR idx IN indices
        FOR name IN names
        CALL append_table(t, idx, name)
        RETURN 0 AS r
      }
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE export_values {id, name} = (0, "seed")
      CALL nested_append_table(export_values)
      RETURN count(r) AS total
      NEXT
      FOR rec in export_values RETURN rec.id AS rid, rec.name AS rname, total
      """
    Then the result should be, in any order:
      | rid | rname    | total |
      | 0   | "seed"   | 6     |
      | 1   | "proc_b" | 6     |
      | 1   | "proc_c" | 6     |
      | 2   | "proc_b" | 6     |
      | 2   | "proc_c" | 6     |
      | 3   | "proc_b" | 6     |
      | 3   | "proc_c" | 6     |
    And drop the procedure "binding_table_proc"
    And drop the procedure "binding_table_export"
    And drop the procedure "append_table"
    And drop the procedure "nested_append_table"

  @sf01
  Scenario: VarLenExpand with procedure parameter in node filter
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE var_len_expand_pk_scan(src INT64) RETURNS (cnt INT64) AS {
        MATCH ANY SHORTEST (v{id:src})->+(v)
        RETURN count(v) AS cnt GROUP BY ()
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        MATCH ANY SHORTEST (v{id:15393162789604})->+(v)
        RETURN count(v) AS expected_cnt GROUP BY ()
        NEXT
        CALL var_len_expand_pk_scan(15393162789604)
        RETURN expected_cnt, cnt
      }
      """
    Then the result should be, in any order:
      | expected_cnt | cnt |
      | 1            | 1   |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE var_len_expand_edge_filter(src INT64, minDate STRING) RETURNS (cnt INT64) AS {
        MATCH ANY SHORTEST (v{id:src})-[e WHERE e.creationDate > local_datetime(minDate, "%Y-%m-%dT%H:%M:%S")]->+(v)
        RETURN count(v) AS cnt GROUP BY ()
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE sf01 {
        MATCH ANY SHORTEST (v{id:15393162789604})-[e WHERE e.creationDate > local_datetime('2010-01-01T00:00:00', "%Y-%m-%dT%H:%M:%S")]->+(v)
        RETURN count(v) AS expected_cnt GROUP BY ()
        NEXT
        CALL var_len_expand_edge_filter(15393162789604, '2010-01-01T00:00:00')
        RETURN expected_cnt, cnt
      }
      """
    Then the result should be, in any order:
      | expected_cnt | cnt |
      | 0            | 0   |
    And drop the procedure "var_len_expand_pk_scan"
    And drop the procedure "var_len_expand_edge_filter"

  # FIX: procedure call with full graph path from different schema
  Scenario: procedure call with full graph path from different schema
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_proc_graph_type AS {
        NODE TYPE City (LABEL City {id INT PRIMARY KEY, name STRING, url STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS full_schema_graph_test TYPED test_proc_graph_type
      """
    Then the execution should be successful
    And graph "full_schema_graph_test" should be ready to use
    When executing query:
      """
      USE full_schema_graph_test INSERT (@City{id: 1368, name: "Jönköping", url: "http://dbpedia.org/resource/Jönköping"})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /test_schema
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /test_schema
      """
    Then the execution should be successful
    When executing query:
      """
      USE /default_schema/full_schema_graph_test MATCH (v) RETURN v LIMIT 1
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE circles_detection(src INT64) RETURNS (result INT64) AS {
        MATCH p = ANY SHORTEST (v{id:src}) RETURN count(p) AS result
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE /default_schema/full_schema_graph_test CALL circles_detection(1368) RETURN result
      """
    Then the result should be, in any order:
      | result |
      | 1      |
    And drop the procedure "circles_detection"
    And drop the graph "full_schema_graph_test"
    And drop the graph type "test_proc_graph_type"

  Scenario: Test multi batches
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE test_multi_batch(x INT, y INT) RETURNS (x INT, y INT) {
        RETURN x, y
      }
      """
    Then the execution should be successful
    When executing query:
      """
      /*+SET_VAR(call_procedure_concurrency=2)*/
      FOR i IN range(1,5)
      FOR j IN range(1,3)
      CALL test_multi_batch(i, j) RETURN *
      """
    Then the result should be, in any order:
      | i | j | x | y |
      | 1 | 1 | 1 | 1 |
      | 1 | 2 | 1 | 2 |
      | 1 | 3 | 1 | 3 |
      | 2 | 1 | 2 | 1 |
      | 2 | 2 | 2 | 2 |
      | 2 | 3 | 2 | 3 |
      | 3 | 1 | 3 | 1 |
      | 3 | 2 | 3 | 2 |
      | 3 | 3 | 3 | 3 |
      | 4 | 1 | 4 | 1 |
      | 4 | 2 | 4 | 2 |
      | 4 | 3 | 4 | 3 |
      | 5 | 1 | 5 | 1 |
      | 5 | 2 | 5 | 2 |
      | 5 | 3 | 5 | 3 |
    When executing query:
      """
      /*+SET_VAR(call_procedure_concurrency=4)*/
      FOR i IN range(1,10)
      FOR j IN range(1,10)
      CALL test_multi_batch(i, j) RETURN count(*)
      """
    Then the result should be, in any order:
      | count(*) |
      | 100      |
    And drop the procedure "test_multi_batch"

  # We skip the tests below because tck does not guarantee scenario order
  # so the result might not be expected. Toggle these tests when tck
  # scenario order is supported
  @sf01 @skip
  Scenario: start long time procedure call query
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE long_running_proc(id INT) RETURNS ret INT AS {
        MATCH test_kill_query_gql_proc_path=TRAIL (a)-[]-{20}()
        RETURN a.id AS ret
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE nested_long_proc() RETURNS ret INT AS {
        VALUE i = 0
        WHILE i < 10 THEN {
          SET i = i + 1
          MATCH (v:Person) LIMIT 10 CALL long_running_proc(v.id) FINISH
        }
        RETURN 0
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE nested_nested_long_proc() RETURNS ret INT AS {
        VALUE i = 0
        WHILE i < 10 THEN {
          SET i = i + 1
          CALL nested_long_proc() FINISH
        }
        RETURN 0
      }
      """
    Then the execution should be successful

  @sf01 @skip
  Scenario: long time gql procedure query1
    When executing raw query:
      """
      USE sf01 CALL nested_long_proc() RETURN ret
      """
    Then an Error should be raised: "[NR302]: Query is canceled by user"

  @sf01 @skip
  Scenario: long time gql procedure query2
    When executing raw query:
      """
      USE sf01 CALL nested_nested_long_proc() RETURN ret
      """
    Then an Error should be raised: "[NR302]: Query is canceled by user"

  @sf01 @skip
  Scenario: kill long time gql procedure queries
    And wait "1" seconds
    When executing query:
      """
      CALL show_sessions() YIELD active_query AS qstr, username
      FILTER qstr LIKE "%CALL nested_long_proc%" OR qstr LIKE "%CALL nested_nested_long_proc%"
      RETURN username, qstr
      """
    Then the result should be, in any order:
      | username | qstr                                                 |
      | "root"   | "USE sf01 CALL nested_long_proc() RETURN ret"        |
      | "root"   | "USE sf01 CALL nested_nested_long_proc() RETURN ret" |
    When executing query:
      """
      CALL show_queries() YIELD query_id AS qid, `query` AS qstr, username
      FILTER qstr LIKE "%CALL nested_long_proc%" OR qstr LIKE "%CALL nested_nested_long_proc%"
      CALL kill_query(qid) YIELD query_id AS id
      RETURN username, qstr
      """
    Then the result should be, in any order:
      | username | qstr                                                 |
      | "root"   | "USE sf01 CALL nested_long_proc() RETURN ret"        |
      | "root"   | "USE sf01 CALL nested_nested_long_proc() RETURN ret" |
    When executing query:
      """
      DROP PROCEDURE long_running_proc
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE nested_long_proc
      """
    Then the execution should be successful
    When executing query:
      """
      DROP PROCEDURE nested_nested_long_proc
      """
    Then the execution should be successful
    And close the current session

  Scenario: table arg output in analytic procedure
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_export_person(result_table TABLE)
      RETURNS () AS {
        MATCH (p@Person)
        PER NODE (p) {
          LOG_INFO("p.id: ", p.id)
          EXPORT p.id INTO result_table
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE result_table TYPED TABLE {id INT64}
      USE #analytic_ldbc CALL proc_export_person(result_table) FINISH
      FOR r IN result_table
      RETURN r.id
      ORDER BY r.id
      """
    Then the execution should be successful
    And drop the procedure "proc_export_person"
