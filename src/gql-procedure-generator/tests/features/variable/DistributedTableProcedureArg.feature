# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Distributed Table Procedure Arg

  Scenario: Distributed table procedure args are passed by reference
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_fill_person(t TABLE) AS {
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.firstName INTO t
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_keep_even_person(t TABLE) AS {
        PER PARTITION (part) OF t {
          SET part.clear()
        }

        MATCH (a@Person)
        WHERE a.id % 2 = 0
        PER NODE (a) {
          EXPORT a.id, a.firstName INTO t
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT, name STRING} PARTITION BY DEFAULT

        CALL dt_proc_arg_fill_person(t) FINISH
        CALL dt_proc_arg_keep_even_person(t) FINISH

        PER PARTITION (part) OF t {
          FOR r IN part
          RETURN r.id AS id, r.name AS name
        }
      }
      """
    Then the result should be, in any order:
      | id | name     |
      | 2  | "Tim"    |
      | 4  | "Sophie" |
    And drop the procedure "dt_proc_arg_fill_person"
    And drop the procedure "dt_proc_arg_keep_even_person"

  Scenario: Distributed table procedure args work across multiple child procedures
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_stage_one(t TABLE) AS {
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, "s1" INTO t
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_stage_two(t TABLE) AS {
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id + 10, "s2" INTO t
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT, stage STRING} PARTITION BY DEFAULT

        CALL dt_proc_arg_stage_one(t) FINISH
        CALL dt_proc_arg_stage_two(t) FINISH

        PER PARTITION (part) OF t {
          FOR r IN part
          RETURN r.id AS id, r.stage AS stage
        }
      }
      """
    Then the result should be, in any order:
      | id | stage |
      | 1  | "s1"  |
      | 2  | "s1"  |
      | 3  | "s1"  |
      | 4  | "s1"  |
      | 11 | "s2"  |
      | 12 | "s2"  |
      | 13 | "s2"  |
      | 14 | "s2"  |
    And drop the procedure "dt_proc_arg_stage_one"
    And drop the procedure "dt_proc_arg_stage_two"

  Scenario: Distributed table procedure arg works across nested child procedures
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_nested_leaf(t TABLE) AS {
        MATCH (a@Person)
        WHERE a.id = 1
        PER NODE (a) {
          EXPORT a.id, "leaf" INTO t
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_nested_mid(t TABLE) AS {
        CALL dt_proc_arg_nested_leaf(t) FINISH

        MATCH (a@Person)
        WHERE a.id = 2
        PER NODE (a) {
          EXPORT a.id, "mid" INTO t
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_nested_top(t TABLE) AS {
        CALL dt_proc_arg_nested_mid(t) FINISH

        MATCH (a@Person)
        WHERE a.id = 3
        PER NODE (a) {
          EXPORT a.id, "top" INTO t
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT, stage STRING} PARTITION BY DEFAULT

        CALL dt_proc_arg_nested_top(t) FINISH

        PER PARTITION (part) OF t {
          FOR r IN part
          RETURN r.id AS id, r.stage AS stage
        }
      }
      """
    Then the result should be, in any order:
      | id | stage  |
      | 1  | "leaf" |
      | 2  | "mid"  |
      | 3  | "top"  |
    And drop the procedure "dt_proc_arg_nested_leaf"
    And drop the procedure "dt_proc_arg_nested_mid"
    And drop the procedure "dt_proc_arg_nested_top"

  Scenario: PER PARTITION in child procedure requires distributed table argument
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_need_dist(t TABLE) AS {
        PER PARTITION (x) OF t {
          SET x.clear()
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT}
        CALL dt_proc_arg_need_dist(t) FINISH
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: PER PARTITION OF `t` requires a distributed binding table"
    And drop the procedure "dt_proc_arg_need_dist"

  Scenario: size is not supported for distributed table procedure argument
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE dt_proc_arg_size(t TABLE) RETURNS (sz INT64) AS {
        RETURN size(t) AS sz
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT
        CALL dt_proc_arg_size(t) RETURN sz
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: size function is not supported for distributed table"
    And drop the procedure "dt_proc_arg_size"
