# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: call named procedure

  Scenario: call procedure version
    When executing query:
      """
      CALL version() RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL version(true) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL version(false) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL version() YIELD version RETURN substring(version, 1, 10) AS version
      """
    Then the result should be, in any order:
      | version      |
      | "5.0, Build" |
    When executing query:
      """
      CALL version(false) YIELD version RETURN substring(version, 1, 10) AS version
      """
    Then the result should be, in any order:
      | version      |
      | "5.0, Build" |
    When executing query:
      """
      CALL version(true) YIELD version RETURN substring(version, 1, 3) AS version
      """
    Then the result should be, in any order:
      | version |
      | "5.0"   |
    When executing query:
      """
      CALL version() YIELD version AS v RETURN substring(v, 1, 10) AS v
      """
    Then the result should be, in any order:
      | v            |
      | "5.0, Build" |
    When executing query:
      """
      CALL version(false) YIELD version AS v RETURN substring(v, 1, 10) AS v
      """
    Then the result should be, in any order:
      | v            |
      | "5.0, Build" |
    When executing query:
      """
      CALL version(true) YIELD version AS v RETURN substring(v, 1, 3) AS v
      """
    Then the result should be, in any order:
      | v     |
      | "5.0" |
    When executing query:
      """
      CALL version() YIELD version AS a, version AS b
      RETURN substring(a, 1, 3) AS a, substring(b, 1, 3) AS b
      """
    Then the result should be, in any order:
      | a     | b     |
      | "5.0" | "5.0" |
    When executing query:
      """
      LET version = "dummy_version"
      CALL version() YIELD version
      RETURN version
      """
    Then an Error should be raised: "[NP105]: The yield column `version` of procedure `dbms.version` conflicts with previous variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      LET version = "dummy_version"
      CALL version() YIELD version AS ver
      RETURN version, substring(ver, 1, 3) AS ver
      """
    Then the result should be, in any order:
      | version         | ver   |
      | "dummy_version" | "5.0" |
    When executing query:
      """
      CALL version() YIELD * RETURN *
      """
    Then an Error should be raised: "[42001]: syntax error near `*`"
    When executing query:
      """
      CALL version() YIELD version RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL version('true') RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `version`: argument `\"true\"` is of type `STRING` instead of the expected `BOOL`"
    When executing query:
      """
      CALL version(false, true) RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `version`: no more than 1 argument(s)"
    When executing query:
      """
      CALL version() YIELD version, v2 RETURN *
      """
    Then an Error should be raised: "[NP106]: Unknown yield column `v2` for procedure `dbms.version`"
    When executing query:
      """
      CALL version() YIELD version AS v, v2 RETURN *
      """
    Then an Error should be raised: "[NP106]: Unknown yield column `v2` for procedure `dbms.version`"
    When executing query:
      """
      CALL version() YIELD v RETURN *
      """
    Then an Error should be raised: "[NP106]: Unknown yield column `v` for procedure `dbms.version`"
    When executing query:
      """
      CALL dbms.version() RETURN substring(version,6,5) AS v
      """
    Then the result should be, in any order:
      | v       |
      | "Build" |
    When executing query:
      """
      CALL version() YIELD count(version) RETURN *
      """
    Then an Error should be raised: "[42001]: syntax error near `(`"
    When executing query:
      """
      RETURN true AS v
      NEXT
      CALL version(v) RETURN substring(version, 1, 3) AS v
      """
    Then the result should be, in any order:
      | v     |
      | "5.0" |
    When executing query:
      """
      RETURN true AS v
      NEXT
      CALL version(v) YIELD * RETURN *
      """
    Then an Error should be raised: "[42001]: syntax error near `*`"
    When executing query:
      """
      CALL version() RETURN version
      NEXT
      RETURN substring(version, 1, 10) AS v
      """
    Then the result should be, in any order:
      | v            |
      | "5.0, Build" |
    When executing query:
      """
      FOR i IN [TRUE, FALSE, TRUE]
      LET a = CASE WHEN i = TRUE THEN VALUE { CALL version(i) RETURN version LIMIT 1 } ELSE VALUE { CALL version(i) RETURN version LIMIT 1 } END
      RETURN substring(a, 1, 8) AS v
      """
    Then the result should be, in any order:
      | v          |
      | "5.0, Git" |
      | "5.0, Bui" |
      | "5.0, Git" |
    When executing query:
      """
      FOR i IN [TRUE, FALSE, TRUE]
      LET a = substring(VALUE { CALL version( EXISTS { LET a = i RETURN a} ) RETURN version LIMIT 1 }, 1, 8)
      RETURN substring(a, 1, 8) AS v
      """
    Then the result should be, in any order:
      | v          |
      | "5.0, Git" |
      | "5.0, Git" |
      | "5.0, Git" |
    When executing query:
      """
      CALL version() YIELD version AS `v`
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement"

  Scenario: multiple query statements
    When executing query:
      """
      USE ldbc
      MATCH (p:Person{firstName: 'Tim'})
      CALL version(p.gender='male')
      RETURN p.lastName AS n, substring(version, 1, 10) AS v
      """
    Then the result should be, in any order:
      | n        | v            |
      | "Duncan" | "5.0, Git: " |
    When executing query:
      """
      USE ldbc
      MATCH (p:Person{firstName: 'Tim2'})
      CALL version(p.gender='male')
      RETURN p.lastName AS n, substring(version, 1, 10) AS v
      """
    Then the result should be, in any order:
      | n | v |
    When executing query:
      """
      USE ldbc
      MATCH (p:Person{firstName: 'Tim'})
      WHERE VALUE {
        CALL version(false) RETURN substring(version, 1, 3)='5.0'
        LIMIT 1
      }
      RETURN p.lastName AS n
      """
    Then the result should be, in any order:
      | n        |
      | "Duncan" |
    When executing query:
      """
      USE ldbc
      MATCH (p:Person{firstName: 'Tim'})
      WHERE VALUE {
        CALL version(true) RETURN substring(version, 1, 10)='Build Time'
        LIMIT 1
      }
      RETURN p.lastName AS n
      """
    Then the result should be, in any order:
      | n |
    When executing query:
      """
      USE ldbc
      MATCH (p:Person{firstName: 'Tim'})
      WHERE VALUE {
        CALL version(p.gender='male') RETURN substring(version, 6, 10)='Build Time'
        LIMIT 1
      }
      RETURN p.lastName AS n
      """
    Then the result should be, in any order:
      | n |
    When executing query:
      """
      USE ldbc
      MATCH (version:Person{firstName: 'Tim'})
      WHERE VALUE {
        CALL version(version.gender='male') YIELD version AS v
        RETURN substring(v, 1, 9)='5.0, Git:' LIMIT 1
      }
      RETURN version.lastName AS n
      """
    Then the result should be, in any order:
      | n        |
      | "Duncan" |
    When executing query:
      """
      FOR i IN LIST[1, 2]
      CALL version() YIELD version AS v
      RETURN i, substring(v,1,10) AS s
      """
    Then the result should be, in any order:
      | i | s            |
      | 1 | "5.0, Build" |
      | 2 | "5.0, Build" |
    When executing query:
      """
      FOR i IN LIST[1, 2]
      CALL version() YIELD version AS v
      RETURN i
      """
    Then the result should be, in any order:
      | i |
      | 1 |
      | 2 |
    When executing query:
      """
      FOR i IN LIST[1, 2]
      CALL version(i>1) YIELD version AS v
      RETURN i, substring(v,6,3) AS v
      """
    Then the result should be, in any order:
      | i | v     |
      | 1 | "Bui" |
      | 2 | "Git" |
    When executing query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE ldbc
      MATCH (p:Person)
      CALL version(p.id>1) YIELD version AS v
      RETURN p.id AS i, substring(v,6,5) AS v
      ORDER BY i
      """
    Then the result should be, in any order:
      | i | v       |
      | 1 | "Build" |
      | 2 | "Git: " |
      | 3 | "Git: " |
      | 4 | "Git: " |
    When executing query:
      """
      CALL version()
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement"

  # TODO(yee): reference the issue vesoft-inc/nebula-ng#2087
  # TODO(Aiee): Rethink how to handle non-exist graph name
  # Issue: https://github.com/vesoft-inc/nebula-ng/issues/2568
  # When executing query:
  # """
  # FOR g IN LIST['ldbc','_not_exist_graph_name_']
  # FILTER VALUE {
  # CALL describe_graph(g) YIELD `graph_type_name` AS t
  # RETURN t IS NOT NULL AS has_type
  # }
  # RETURN *
  # """
  # Then the result should be, in any order:
  # | g      | has_type |
  # | "ldbc" | true     |
  # When executing query:
  # """
  # FOR g IN LIST['ldbc','_not_exist_graph_name_']
  # FILTER VALUE {
  # OPTIONAL CALL describe_graph(g) YIELD `graph_type_name` AS t
  # RETURN t IS NOT NULL AS has_type
  # }
  # RETURN *
  # """
  # Then the result should be, in any order:
  # | g      | has_type |
  # | "ldbc" | true     |
  Scenario: optional procedure
    # TODO(Aiee): Rethink how to handle non-exist graph name
    # https://github.com/vesoft-inc/nebula-ng/issues/2568
    # When executing query:
    # """
    # FOR g IN LIST['ldbc', '_not_exist_graph_name_']
    # CALL describe_graph(g) YIELD `graph_type_name` AS t
    # RETURN g, t
    # """
    # Then the result should be, in any order:
    # | g      | t           |
    # | "ldbc" | "ldbc_type" |
    # When executing query:
    # """
    # FOR g IN LIST['ldbc', '_not_exist_graph_name_']
    # OPTIONAL CALL describe_graph(g) YIELD `graph_type_name` AS t
    # RETURN g, t
    # """
    # Then the result should be, in any order:
    # | g                        | t           |
    # | "ldbc"                   | "ldbc_type" |
    # | "_not_exist_graph_name_" | NULL        |
    # When executing query:
    # """
    # OPTIONAL CALL describe_graph('_not_exist_graph_name_') RETURN *
    # """
    # Then the result should be, in any order:
    # | graph_name | graph_type_name |
    # | NULL       | NULL            |
    When executing query:
      """
      OPTIONAL CALL version() RETURN substring(version, 1, 10) AS v
      """
    Then the result should be, in any order:
      | v            |
      | "5.0, Build" |
    When executing query:
      """
      RETURN true AS t, false AS f
      NEXT
      OPTIONAL CALL version(f) RETURN substring(version, 1, 10) AS v, t
      """
    Then the result should be, in any order:
      | v            | t    |
      | "5.0, Build" | true |

  Scenario: column pruning
    When executing query:
      """
      RETURN true AS t, false AS f
      NEXT
      CALL version(t) RETURN substring(version, 6, 3) AS v
      """
    Then the result should be, in any order:
      | v     |
      | "Git" |
    When executing query:
      """
      RETURN true AS t, false AS f
      NEXT
      CALL version(t) RETURN substring(version, 6, 3) AS v, f
      """
    Then the result should be, in any order:
      | v     | f     |
      | "Git" | false |
    When executing query:
      """
      RETURN true AS t, false AS f
      NEXT
      CALL version(t) YIELD version, f RETURN substring(version, 1, 3) AS v
      """
    Then an Error should be raised: "[NP106]: Unknown yield column `f` for procedure `dbms.version`"
    When executing query:
      """
      RETURN true AS t, false AS f
      NEXT
      CALL version(t) YIELD version RETURN substring(version, 6, 3) AS v, f
      """
    Then the result should be, in any order:
      | v     | f     |
      | "Git" | false |
    When executing query:
      """
      RETURN true AS t, false AS version
      NEXT
      CALL version(t) YIELD version RETURN *
      """
    Then an Error should be raised: "[NP105]: The yield column `version` of procedure `dbms.version` conflicts with previous variables. Please use a unique alias to distinguish them"
    When executing query:
      """
      RETURN true AS t, false AS version
      NEXT
      CALL version(t) YIELD version AS v RETURN substring(v, 1, 3) AS v, version
      """
    Then the result should be, in any order:
      | v     | version |
      | "5.0" | false   |
    When executing query:
      """
      FOR i IN LIST[1, 2]
      LET t=true, f=false
      OPTIONAL CALL version(t) YIELD version
      RETURN substring(version, 6, 3) AS v, f, i
      """
    Then the result should be, in any order:
      | v     | f     | i |
      | "Git" | false | 1 |
      | "Git" | false | 2 |
    When executing query:
      """
      FOR i IN LIST[1, 2]
      LET t=true, f=false
      OPTIONAL CALL version(t) YIELD version AS f
      RETURN substring(f, 1, 3) AS v, f, i
      """
    Then an Error should be raised: "[NP105]: The yield column `f` of procedure `dbms.version` conflicts with previous variables. Please use a unique alias to distinguish them"

  Scenario: nullable argument in call procedure
    When executing query:
      """
      FOR i in LIST[true, false, NULL]
      CALL version(i) RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `version`: null value is not allowed in procedure call"

  @skip
  Scenario: call named external procedure
    When executing query:
      """
      CALL bfs(g, 1234) YIELD vid, distance
      RETURN vid, distance
      """
    Then the result should be, in any order:
      | vid | distance |
    When executing query:
      """
      CALL bfs(g, 1234) YIELD *
      RETURN *
      """
    Then the result should be, in any order:
      | vid | distance |
    When executing query:
      """
      CALL bfs(g, 1234) YIELD *
      RETURN vid
      """
    Then the result should be, in any order:
      | vid |
    When executing query:
      """
      CALL bfs(g, 1234)
      RETURN vid, distance
      """
    Then the result should be, in any order:
      | vid | distance |
    When executing query:
      """
      CALL abc()
      RETURN vid, distance
      """
    Then the result should be, in any order:
      | vid | distance |
    When executing query:
      """
      CALL {
        USE ldbc MATCH (v) RETURN v
      }
      RETURN v
      """
    Then the result should be, in any order:
      | v |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      OPTIONAL CALL {
        USE ldbc MATCH (v) RETURN v
      }
      RETURN v
      """
    Then the result should be, in any order:
      | v |

  Scenario: vesoft-inc/nebula-ng#4553
    When executing query:
      """
      USE ldbc MATCH (v:Person{firstName: 'Tim'})
      CALL dbms.version(v.id=2)
      RETURN v.id AS id, substring(version, 1, 10) AS v
      """
    Then the result should be, in order:
      | id | v            |
      | 2  | "5.0, Git: " |
    When executing query:
      """
      USE ldbc MATCH (v:Person{firstName: 'Tim'})
      CALL dbms.version(v.id=3)
      RETURN v.id AS id, substring(version, 1, 10) AS v
      """
    Then the result should be, in order:
      | id | v            |
      | 2  | "5.0, Build" |
