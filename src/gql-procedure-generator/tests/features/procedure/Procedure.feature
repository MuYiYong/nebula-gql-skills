# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: procedure

  Scenario: define value variables
    When executing query:
      """
      VALUE a = 1
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      VALUE a int = 1
      VALUE b::int = 2
      VALUE c TYPED int = 3
      RETURN a, b, c
      """
    Then the result should be, in any order:
      | a | b | c |
      | 1 | 2 | 3 |
    When executing query:
      """
      VALUE a::double = 123
      RETURN a
      """
    Then the result should be, in any order:
      | a     |
      | 123.0 |
    When executing query:
      """
      VALUE a int = true
      RETURN a
      """
    Then an Error should be raised: "[NS208]: The type of `true(BOOL)` cannot be assigned to `a(INT64)`"
    When executing query:
      """
      VALUE a = 1
      VALUE b = 2
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |
    When executing query:
      """
      VALUE a = 1
      VALUE b = a + 1
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |
    # The following case is actually a valid case
    # TODO(jie): support the following case
    # When executing query:
    # """
    # VALUE a = 1
    # RETURN 2 AS b
    # NEXT
    # RETURN a
    # """
    # Then an Error should be raised: "Syntax Error"
    When executing query:
      """
      VALUE a = 1
      VALUE b = VALUE { RETURN a + 1 LIMIT 1 }
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 2 |
    When executing query:
      """
      VALUE a = 1
      VALUE b = VALUE { USE ldbc MATCH (v:Person{id:a}) RETURN v.id AS vid LIMIT 1 }
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 1 |
    When executing query:
      """
      VALUE a = 1
      VALUE b = VALUE { USE ldbc MATCH (v:Person)-[e:KNOWS]->(v2:Person WHERE v2.id = a + 2) RETURN v.id AS vid LIMIT 1 }
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 3 |
    When executing query:
      """
      VALUE a = 1
      VALUE b = 2
      VALUE c = a + b
      RETURN c
      """
    Then the result should be, in any order:
      | c |
      | 3 |
    When executing query:
      """
      VALUE a = 1
      VALUE b = 2
      VALUE c = a + b
      LET d = c + 100, e = a + 100, f = b + 100
      RETURN d, e, f
      """
    Then the result should be, in any order:
      | d   | e   | f   |
      | 103 | 101 | 102 |
    When executing query:
      """
      VALUE numPerson = VALUE { USE ldbc MATCH (v:Person) return count(v) AS cnt GROUP BY() }
      VALUE numPlaces = VALUE { USE ldbc MATCH (v:City|Country|Continent) return count(v) AS cnt GROUP BY() }
      RETURN numPerson, numPlaces
      """
    Then the result should be, in any order:
      | numPerson | numPlaces |
      | 4         | 6         |
    When executing query:
      """
      VALUE cnt = VALUE { USE ldbc MATCH (v:Person) return count(v) AS cnt GROUP BY() }
      VALUE cnt2 = VALUE { USE ldbc MATCH (v:City|Country|Continent) return count(v) AS cnt GROUP BY() }
      RETURN cnt, cnt2
      """
    Then the result should be, in any order:
      | cnt | cnt2 |
      | 4   | 6    |
    When executing query:
      """
      VALUE cnt1 = VALUE { USE ldbc MATCH (v:Person) return count(v) AS cnt GROUP BY() }
      VALUE cnt = VALUE { USE ldbc MATCH (v:City|Country|Continent) return count(v) AS cnt GROUP BY() }
      RETURN cnt1, cnt
      """
    Then the result should be, in any order:
      | cnt1 | cnt |
      | 4    | 6   |
    When executing query:
      """
      VALUE a = 1
      VALUE b = 2
      LET c = 3
      RETURN *
      """
    Then the result should be, in any order:
      | c |
      | 3 |
    When executing query:
      """
      VALUE a = 1
      VALUE b = 2
      RETURN *
      """
    Then an Error should be raised: "[NS107]: RETURN * is not allowed when there are no iterated variables in scope"

  Scenario: complex
    When executing query:
      """
      RETURN 1 AS v
      NEXT
      RETURN v UNION ALL RETURN v
      NEXT
      RETURN v
      """
    Then the result should be, in any order:
      | v |
      | 1 |
      | 1 |
    When executing query:
      """
      RETURN 1 AS v
      NEXT
      RETURN v UNION RETURN 2 AS v
      NEXT
      RETURN v
      NEXT
      RETURN v INTERSECT RETURN 2 AS v
      NEXT
      RETURN v
      """
    Then the result should be, in any order:
      | v |
      | 2 |
    When executing query:
      """
      VALUE numPerson = VALUE { USE ldbc MATCH (v:Person) return count(v) GROUP BY() }
      VALUE dateList = VALUE { USE ldbc MATCH (v:Forum) return collect(DISTINCT v.creationDate) GROUP BY() }
      VALUE numTags = VALUE { USE ldbc MATCH (t:Tag) return count(t) GROUP BY() }
      USE ldbc
      LET numObjs = numPerson + numTags
      MATCH (v:Person)-[e:KNOWS]->(v2:Person) WHERE e.creationDate IN dateList
      RETURN numPerson, numObjs, v2.id AS vid
      """
    Then the result should be, in any order:
      | numPerson | numObjs | vid |
      | 4         | 8       | 1   |
      | 4         | 8       | 2   |
      | 4         | 8       | 3   |

  Scenario: nested procedure
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person)
        RETURN v
        NEXT
        MATCH (v)
        FILTER exists { (v)-[:KNOWS]->() }
        RETURN count(*) AS numPersonHasFriends GROUP BY()
      }
      """
    Then the result should be, in any order:
      | numPersonHasFriends |
      | 3                   |
    When executing query:
      """
      USE ldbc {
        VALUE numPersonHasFriends = VALUE {
          MATCH (v:Person)
          FILTER exists { (v)-[:KNOWS]->() }
          RETURN count(*) AS cnt GROUP BY()
        }
        RETURN numPersonHasFriends
      }
      """
    Then the result should be, in any order:
      | numPersonHasFriends |
      | 3                   |
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person)
        RETURN v.id AS vid
      }
      """
    Then the result should be, in any order:
      | vid |
      | 1   |
      | 2   |
      | 3   |
      | 4   |
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person)
        RETURN v.firstName AS name
        UNION
        MATCH (t:City)
        RETURN t.name AS name
      }
      """
    Then the result should be, in any order:
      | name        |
      | "Kyle"      |
      | "Tim"       |
      | "Ming"      |
      | "Sophie"    |
      | "Beijing"   |
      | "Shanghai"  |
      | "Hangzhou"  |
      | "Chongqing" |
      | "Chengdu"   |
      | "Shenzhen"  |
    When executing query:
      """
      {
        RETURN 1 AS a
        UNION
        RETURN 2 AS a
      }
      NEXT
      LET b = a + 10
      RETURN b
      """
    Then the result should be, in any order:
      | b  |
      | 11 |
      | 12 |
    When executing query:
      """
      {
        RETURN 1 AS a
      }
      UNION
      {
        RETURN 2 AS a
      }
      NEXT
      LET b = a + 10
      RETURN b
      """
    Then the result should be, in any order:
      | b  |
      | 11 |
      | 12 |
    When executing query:
      """
      {
        {
            RETURN 1 AS a
        }
        UNION
        {
            RETURN 2 AS a
        }
      }
      INTERSECT
      RETURN 2 AS a
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      USE ldbc {
        {
          MATCH (v:Person)
          RETURN v.firstName AS name
          UNION
          MATCH (t:City)
          RETURN t.name AS name
        }
        NEXT
        FILTER length(name) > 5
        RETURN name
      }
      """
    Then the result should be, in any order:
      | name        |
      | "Sophie"    |
      | "Beijing"   |
      | "Shanghai"  |
      | "Hangzhou"  |
      | "Chongqing" |
      | "Chengdu"   |
      | "Shenzhen"  |
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person)
        RETURN v.firstName AS name
        UNION
        MATCH (t:City)
        RETURN t.name AS name
      }
      FILTER length(name) > 5
      RETURN name
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `name` not defined"
    When executing query:
      """
      {
        FILTER true
      }
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement"

  Scenario: Procedure syntax error
    # Illegal use of NEXT connector
    When executing query:
      """
      NEXT
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `NEXT`"
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      """
    Then an Error should be raised: "[42001]: syntax error near `NEXT`"
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      NEXT
      RETURN 2 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `NEXT`"
    # NEXT connector with invalid operands
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      UNION ALL
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `UNION`"
    # Only DQL is allowed inside planned nested queries
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      { CREATE GRAPH nested_next_ddl TYPED ldbc_type }
      """
    Then an Error should be raised: "[42N48]: Invalid syntax, cannot mix DDL statements with non-DDL statements"
    When executing query:
      """
      { CREATE GRAPH nested_next_ddl TYPED ldbc_type }
      NEXT
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42N48]: Invalid syntax, cannot mix DDL statements with non-DDL statements"
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      IF true THEN { RETURN 2 AS a }
      """
    Then an Error should be raised: "[42001]: syntax error near `IF`"
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      CREATE ROLE genius
      """
    Then an Error should be raised: "[42001]: syntax error near `CREATE`"
    When executing query:
      """
      RETURN 1 AS a
      NEXT
      BALANCE LEADER
      """
    Then an Error should be raised: "[42001]: syntax error near `CALL`"
    # Illegal use of query conjunctions
    When executing query:
      """
      UNION ALL
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `UNION`"
    When executing query:
      """
      RETURN 1 AS a
      UNION ALL
      """
    Then an Error should be raised: "[42001]: syntax error near `UNION`"
    When executing query:
      """
      RETURN 1 AS a
      UNION ALL
      UNION ALL
      RETURN 2 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `UNION`"
    When executing query:
      """
      RETURN 1 AS a
      UNION ALL
      IF true THEN { RETURN 2 AS a }
      """
    Then an Error should be raised: "[42001]: syntax error near `IF`"
    When executing query:
      """
      RETURN 1 AS a
      UNION ALL
      CREATE ROLE genius
      """
    Then an Error should be raised: "[42001]: syntax error near `CREATE`"
    # Illegal use of USE GRAPH clause
    When executing query:
      """
      USE ldbc
      """
    Then an Error should be raised: "[42001]: syntax error near `USE`"
    When executing query:
      """
      USE ldbc
      USE ldbc
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `USE`"
    When executing query:
      """
      USE ldbc
      USE ldbc
      """
    Then an Error should be raised: "[42001]: syntax error near `USE`"
    # USE GRAPH clause cannot bind to control flow statements
    When executing query:
      """
      USE ldbc
      IF true THEN { RETURN 1 AS a }
      """
    Then an Error should be raised: "[42001]: syntax error near `IF`"
    When executing query:
      """
      USE ldbc
      WHILE true THEN { RETURN 1 AS a }
      """
    Then an Error should be raised: "[42001]: syntax error near `WHILE`"
    # Control flow statements can only be used as standalone procedure statements
    When executing query:
      """
      IF true THEN { RETURN 1 AS a }
      NEXT
      RETURN 2 AS a
      """
    Then an Error should be raised: "[42001]: syntax error near `NEXT`"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN 1 AS a
      NEXT
      IF true THEN { RETURN 2 AS a }
      """
    Then an Error should be raised: "[42001]: syntax error near `IF`"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      RETURN 1 AS a
      UNION ALL
      IF true THEN { RETURN 2 AS a }
      """
    Then an Error should be raised: "[42001]: syntax error near `IF`"
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      IF true THEN { RETURN 1 AS a }
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement"
    When executing query:
      """
      USE ldbc MATCH (v:Person) RETURN v
      NEXT
      { IF true THEN { RETURN 1 AS a } }
      """
    Then an Error should be raised: "[NS241]: Only DQL is allowed in subquery"
    When executing query:
      """
      USE ldbc MATCH (v:Person) RETURN v.id AS a
      UNION ALL
      { IF true THEN { RETURN 1 AS a } }
      """
    Then an Error should be raised: "[NS241]: Only DQL is allowed in subquery"
    When executing query:
      """
      { IF true THEN { RETURN 1 AS a } }
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    # Nested queries cannot be directly chained with other statements, but can be chained with NEXT
    When executing query:
      """
      LET a = 1
      {
        RETURN a
      }
      """
    Then an Error should be raised: "[42001]: syntax error near `{`"
    When executing query:
      """
      {
        RETURN 1 AS a
      }
      NEXT
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      WHILE true THEN {
        CREATE GRAPH ddl_in_while::ldbc_type
      }
      """
    Then an Error should be raised: "[42N48]: Invalid syntax, cannot mix DDL statements with non-DDL statements"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /builtin_mix_schema
      RETURN 1 AS a
      """
    Then an Error should be raised: "[42N48]: Invalid syntax, cannot mix DDL statements with non-DDL statements"

  Scenario: Procedure and Statement Execution Rules
    # Rule 1: Non-final statements must not end with RETURN (avoid orphan results)
    When executing query:
      """
      RETURN 1 AS a
      RETURN 2 AS b
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    # Two independent blocks: the first one ends with RETURN and is not final
    When executing query:
      """
      { RETURN 1 AS a }
      { RETURN 2 AS b }
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    # Composite (UNION) followed by another statement: the composite ends with RETURN and is not final
    When executing query:
      """
      RETURN 1 AS a
      UNION ALL
      RETURN 2 AS a
      RETURN 3 AS b
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    # Rule 2: IF may RETURN only when IF is the final statement
    When executing query:
      """
      VALUE i = 0
      IF true THEN {
        RETURN 42 AS x
      }
      WHILE i < 2 THEN {
        SET i = i + 1
      }
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    When executing query:
      """
      IF true THEN { RETURN 1 AS a }
      RETURN 2 AS b
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    When executing query:
      """
      { IF true THEN { RETURN 1 AS a } }
      { IF true THEN { RETURN 2 AS b, 3 AS c } }
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    When executing query:
      """
      { IF true THEN { RETURN 1 AS a } }
      { IF true THEN { FINISH } }
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    When executing query:
      """
      { IF true THEN { FINISH } }
      { IF true THEN { RETURN 2 AS b, 3 AS c } }
      """
    Then the result should be, in any order:
      | b | c |
      | 2 | 3 |
    # Non-final IF without RETURN (state update only); the next statement produces the result
    When executing query:
      """
      VALUE i = 1
      IF true THEN { SET i = i + 10 }
      RETURN i
      """
    Then the result should be, in any order:
      | i  |
      | 11 |
    # IF as the final statement may produce the result
    When executing query:
      """
      VALUE a = 1
      IF a > 0 THEN { RETURN 1 AS x }
      ELSE { RETURN 2 AS x }
      """
    Then the result should be, in any order:
      | x |
      | 1 |
    # IF statement is not the final, but it's branch ends with FINISH instead of RETURN, which is allowed
    When executing query:
      """
      IF true THEN { CALL { RETURN 1 AS a } FINISH }
      RETURN 2 AS b
      """
    Then the result should be, in any order:
      | b |
      | 2 |
    # Rule 3: WHILE does not produce results; update variables in the loop and RETURN after the loop
    When executing query:
      """
      VALUE i = 0
      WHILE i < 3 THEN {
        SET i = i + 1
      }
      RETURN i
      """
    Then the result should be, in any order:
      | i |
      | 3 |
    # RETURN inside a WHILE body is not allowed
    When executing query:
      """
      VALUE i = 0
      WHILE i < 2 THEN {
        RETURN 1
      }
      RETURN i
      """
    Then an Error should be raised: "[NS247]: Procedure statements in the while body must not end with RETURN"
    # Rule 4: Inline CALL may be non-final; the last statement decides the result
    When executing query:
      """
      CALL { RETURN 1 AS a }
      RETURN 2 AS b
      """
    Then the result should be, in any order:
      | b |
      | 2 |
    # Inline CALL result may be explicitly discarded via FINISH; the last RETURN still decides the result
    When executing query:
      """
      CALL { RETURN 1 AS a } FINISH
      RETURN 2 AS b
      """
    Then the result should be, in any order:
      | b |
      | 2 |
    # NEXT: segments connected by NEXT form one statement; only the last segment determines the result
    When executing query:
      """
      RETURN 2 AS a
      NEXT
      RETURN a + 1 As b
      """
    Then the result should be, in any order:
      | b |
      | 3 |
    # Cross-statement check: a procedure statement ending with RETURN followed by more procedure statements is invalid
    When executing query:
      """
      VALUE i = 0
      RETURN 1 AS a
      WHILE i < 2 THEN {
        SET i = i + 1
      }
      RETURN 2 AS a
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    When executing query:
      """
      { RETURN 1 AS a } NEXT { RETURN 2 AS b }
      RETURN 3 AS c
      """
    Then an Error should be raised: "[NS246]: Non-final procedure statement must not end with RETURN; use FINISH instead"
    # FINISH: explicitly discard a non-final output; the last statement determines the procedure result
    When executing query:
      """
      CALL dbms.version() FINISH
      RETURN 1 AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    # Control statements produce side effects only; the final result is produced by RETURN
    When executing query:
      """
      VALUE x = 1
      SET x = x + 2
      RETURN x
      """
    Then the result should be, in any order:
      | x |
      | 3 |

  Scenario: Ensure ast context is not mutated during planning of mutiple iterations of while loop
    When executing query:
      """
      VALUE i = 0
      WHILE i < 3 THEN {
        -- LET with value-subquery referencing outer variable `i`
        LET a = VALUE { RETURN i + 1 LIMIT 1 }
        CALL version(VALUE { RETURN true LIMIT 1 }) FINISH
        SET i = i + VALUE { RETURN 1 LIMIT 1 }
      }
      RETURN i
      """
    Then the result should be, in any order:
      | i |
      | 3 |
    # UNWIND source contains a value-subquery
    And use graph "ldbc"
    When executing query:
      """
      value i = 0
      value srcv = value { match (v@Person{id:3}) return collect(v) }
      while i < 3 then {
        set srcv = value {
          for temp in srcv
          return value {
            match (v1@Person where v1=temp)-[e@FOLLOWS]->(v2@Person) limit 100
            return collect (v2)
          } as templ
          next
          for item in templ
          return collect(item)
        }
        set i = i + 1
      }
      for x in srcv
      return x.id as result order by result
      """
    Then the result should be, in any order:
      | result |
      | 1      |
      | 2      |
      | 3      |
      | 4      |
    When executing query:
      """
      value i = 0
      while i < 4 then {
        value j = value { return i * 2 as b limit 1 }
        set i = j + 1
      }
      return i
      """
    Then the result should be, in any order:
      | i |
      | 7 |

  Scenario: symbol scope
    When executing query:
      """
      VALUE bvd1 LIST<INT> = LIST[68, 43]
      VALUE bvd2 INT = 93
      VALUE bvd3 LIST<BOOL> = LIST[true, false, false]
      VALUE bvd4 LIST<INT> = LIST[35, 57]
      VALUE bvd5 LIST<BOOL> = LIST[false]
      VALUE bvd6 BOOL = (19 < 28)
      RETURN
          collect('LeBron James') AS ri0
      NEXT     RETURN
          ALL bvd2 AS ri1
      OFFSET 0
      LIMIT 1
      """
    Then the result should be, in any order:
      | ri1 |
      | 93  |
    When executing query:
      """
      VALUE x INT = 0
      IF true THEN {
        VALUE a int = 0
        SET x = 1
      } ELSE {
        VALUE b int = 10
        SET x = 2
      }
      """
    Then the execution should be successful
