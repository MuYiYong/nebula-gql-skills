# Copyright (c) 2022 vesoft inc. All rights reserved.
Feature: identifier

  Scenario: common regular identifier
    When executing query:
      """
      RETURN 1 AS _a
      """
    Then the result should be, in any order:
      | _a |
      | 1  |

  Scenario: non-reserved keyword as regular identifier
    When executing query:
      """
      LET SHORTEST = 1, shortest = 2, shORtest = 3
      RETURN SHORTEST, shortest, shORtest
      """
    Then the result should be, in any order:
      | SHORTEST | shortest | shORtest |
      | 1        | 2        | 3        |
    When executing query:
      """
      LET DIRECTED = 1, directed = 2, DIRECTeD = 3
      RETURN DIRECTED, directed, DIRECTeD
      """
    Then the result should be, in any order:
      | DIRECTED | directed | DIRECTeD |
      | 1        | 2        | 3        |
    When executing query:
      """
      LET BINDINGS = 1, bindings = 2, BIndINgs = 3
      RETURN BINDINGS, bindings, BIndINgs
      """
    Then the result should be, in any order:
      | BINDINGS | bindings | BIndINgs |
      | 1        | 2        | 3        |
    When executing query:
      """
      LET VERSION = 1, version = 2, VerSion = 3
      RETURN VERSION, version, VerSion
      """
    Then the result should be, in any order:
      | VERSION | version | VerSion |
      | 1       | 2       | 3       |
    When executing query:
      """
      LET PROPERTY = 1, property = 2, ProPerty = 3
      RETURN PROPERTY, property, ProPerty
      """
    Then the result should be, in any order:
      | PROPERTY | property | ProPerty |
      | 1        | 2        | 3        |
    When executing query:
      """
      LET BINDING = 1, binding = 2, BiNDing = 3
      RETURN BINDING, binding, BiNDing
      """
    Then the result should be, in any order:
      | BINDING | binding | BiNDing |
      | 1       | 2       | 3       |

  Scenario: reserved keyword cannot be directly used as identifier
    When executing query:
      """
      LET DROP = 1, like = 2, FaLse = 3
      RETURN DROP, like, FaLse
      """
    Then an Error should be raised: "[42001]: syntax error near `DROP`"
    When executing query:
      """
      LET list = 1, path = 2, RECORD = 3
      RETURN list, path, RECORD
      """
    Then an Error should be raised: "[42001]: syntax error near `list`"
    When executing query:
      """
      LET GRAPH = 1, graph = 2, GraPH = 3
      RETURN GRAPH, graph, GraPH
      """
    Then an Error should be raised: "[42001]: syntax error near `GRAPH`"
    When executing query:
      """
      LET TABLE = 1, table = 2, TABle = 3
      RETURN TABLE, table, TABle
      """
    Then an Error should be raised: "[42001]: syntax error near `TABLE`"

  Scenario: delimited identifier
    When executing query:
      """
      RETURN 1 AS "abc def"
      """
    Then the result should be, in any order:
      | abc def |
      | 1       |
    When executing query:
      """
      RETURN 123
      """
    Then the result should be, in any order:
      | 123 |
      | 123 |
    When executing query:
      """
      RETURN "123"
      """
    Then the result should be, in any order:
      | "123" |
      | "123" |
    When executing query:
      """
      LET `list` = 1 RETURN 3 AS a
      """
    Then the execution should be successful
    When executing query:
      """
      RETURN 1 AS `list`
      """
    Then the result should be, in any order:
      | list |
      | 1    |
    When executing query:
      """
      RETURN 1 AS "list"
      """
    Then the result should be, in any order:
      | list |
      | 1    |
    When executing query:
      """
      RETURN 1 AS 'list'
      """
    Then an Error should be raised: "[42001]: syntax error near `'list'`"
    When executing query:
      """
      DESCRIBE GRAPH `ldbc`
      """
    Then the result should be, in any order:
      | graph_name | graph_type_name |
      | "ldbc"     | "ldbc_type"     |
    When executing query:
      """
      USE `ldbc` MATCH (n:Person WHERE n.id = 1) RETURN n.firstName
      """
    Then the result should be, in any order:
      | n.firstName |
      | "Kyle"      |
    When executing query:
      """
      RETURN 3 as a，bc
      """
    Then an Error should be raised: "[42001]: illegal (continue) character: `，`"
    When executing query:
      """
      RETURN 3 as "a，bc"
      """
    Then the result should be, in any order:
      | a，bc |
      | 3     |
    When executing query:
      """
      LET `GRAPH` = 1, `table` = 2, `DROP` = 3
      RETURN `GRAPH`, `table`, `DROP`
      """
    Then the result should be, in any order:
      | GRAPH | table | DROP |
      | 1     | 2     | 3    |
    When executing query:
      """
      FOR `match` in [1,2,3] RETURN `match` + 1 as `match`
      """
    Then the result should be, in any order:
      | match |
      | 2     |
      | 3     |
      | 4     |
    When executing query:
      """
      CALL version() YIELD version AS `let` RETURN `let`
      """
    Then the execution should be successful

  Scenario: Max length of identifer shall not exceed 127
    When executing query:
      """
      RETURN 1 AS aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      """
    Then an Error should be raised: "[42001]: identifier exceeds max length 127"
