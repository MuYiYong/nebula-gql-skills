# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Per Partition

  Scenario: Basic per partition usage
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {id INT, name STRING} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.firstName INTO result_table
        }

        PER PARTITION (part) OF result_table {
          FOR r IN part
          RETURN r.id AS id, r.name AS name
        }
      }
      """
    Then the result should be, in any order:
      | id | name     |
      | 1  | "Kyle"   |
      | 2  | "Tim"    |
      | 3  | "Ming"   |
      | 4  | "Sophie" |

  Scenario: Forbidden operations in PER PARTITION body
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT, name STRING} PARTITION BY DEFAULT
        TABLE t1 {id, name} = (11, "new3"), (21, "new4")
        PER PARTITION (x) OF t {
          FOR r IN x
          CALL show_functions("ALL") RETURN name
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: Procedure `dbms.show_functions` is not allowed in PER PARTITION body"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        PER PARTITION (x) OF t {
          FOR r IN t
          RETURN r.id AS id
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: Invalid expression: outer table variable `t` is not allowed. expr=`t`, type=`TABLE {id INT64} PARTITION BY DEFAULT"

  Scenario: More forbidden PER PARTITION cases
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT}
        PER PARTITION (x) OF t {
          RETURN 1
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: PER PARTITION OF `t` requires a distributed binding table"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE v = 1
        PER PARTITION (x) OF v {
          RETURN 1
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: PER PARTITION OF `v` requires a distributed binding table"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT
        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }
        PER PARTITION (x) OF t {
          MATCH (p@Person)
          RETURN p.id
        }
      }
      """
    Then an Error should be raised: "[NS251]: Unsupported statement in subquery: `Match` is Unsupported statement in PER PARTITION"

  Scenario: Access outer literal variable in PER PARTITION body
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE delta = 10
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        PER PARTITION (x) OF t {
          FOR r IN x
          RETURN r.id + delta AS id
        }
      }
      """
    Then the result should be, in any order:
      | id |
      | 11 |
      | 12 |
      | 13 |
      | 14 |

  Scenario: log in PER PARTITION body
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE delta = 10
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        PER PARTITION (x) OF t {
          LOG_INFO("This is a log")
        }
      }
      """
    Then the log should contains: "This is a log"

  Scenario: Forbidden outer NodeAgg and ActiveSet in PER PARTITION body
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE score SumAgg<INT> = 0
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (s@Person)
        PER NODE (s) {
          SET @score += 1
          EXPORT s.id INTO t
        }

        PER PARTITION (x) OF t {
          RETURN @score AS score
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: Invalid expression: GlobalAgg expression is not allowed. expr=`@score`, type=`INT64`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set ACTIVE_SET
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person) WHERE a.id = 1
        FINALLY {
          SET active_set = a
        }

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        PER PARTITION (x) OF t {
          RETURN active_set AS active_set
        }
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `active_set:ActiveSet` cannot be referenced by binding variable expressions"

  Scenario: Distributed table is forbidden outside PER PARTITION functions and FOR
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        RETURN size(t) AS s
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: size function is not supported for distributed table `t`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        FOR p IN table_split(t)
        RETURN 1
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: table_split function is not supported for distributed table `t`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        SET t.clear()
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: clear function is not supported for distributed table `t`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        FOR r IN t
        RETURN r.id AS id
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: unwind function is not supported for distributed table `t`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT
        PER PARTITION (x) OF t {
          SET t.clear()
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: Invalid expression: outer table variable `t` is not allowed. expr=`t`, type=`TABLE {id INT64} PARTITION BY DEFAULT`"

  Scenario: Export to FILE in PER PARTITION body
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/per_partition"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT
        FILE f {id INT64} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/per_partition", FORMAT:"CSV"}

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        PER PARTITION (x) OF t {
          FOR r IN x
          EXPORT r.id AS id INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/per_partition" should match:
      | id |
      | 1  |
      | 2  |
      | 3  |
      | 4  |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/per_partition"

  Scenario: Export to binding table in PER PARTITION body is forbidden
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT} PARTITION BY DEFAULT
        TABLE t2 TYPED TABLE {id INT}

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id INTO t
        }

        PER PARTITION (x) OF t {
          FOR r IN x
          EXPORT r.id INTO t2
        }
      }
      """
    Then an Error should be raised: "[NS253]: Invalid PER PARTITION statement: EXPORT to variable `t2` is not allowed in PER PARTITION body: only FILE targets are supported"
