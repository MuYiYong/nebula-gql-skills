# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: show

  Scenario: show function
    When executing query:
      """
      SHOW FUNCTION `MAX`
      """
    Then the result should be, in any order:
      | name  | signature                             | function_type |
      | "max" | "max(ZONEDTIME) -> ZONEDTIME"         | "[aggregate]" |
      | "max" | "max(ZONEDDATETIME) -> ZONEDDATETIME" | "[aggregate]" |
      | "max" | "max(LOCALTIME) -> LOCALTIME"         | "[aggregate]" |
      | "max" | "max(LOCALDATETIME) -> LOCALDATETIME" | "[aggregate]" |
      | "max" | "max(DATE) -> DATE"                   | "[aggregate]" |
      | "max" | "max(INT16) -> INT16"                 | "[aggregate]" |
      | "max" | "max(INT32) -> INT32"                 | "[aggregate]" |
      | "max" | "max(DURATION) -> DURATION"           | "[aggregate]" |
      | "max" | "max(INT64) -> INT64"                 | "[aggregate]" |
      | "max" | "max(UINT8) -> UINT8"                 | "[aggregate]" |
      | "max" | "max(UINT16) -> UINT16"               | "[aggregate]" |
      | "max" | "max(INT8) -> INT8"                   | "[aggregate]" |
      | "max" | "max(DECIMAL) -> DECIMAL"             | "[aggregate]" |
      | "max" | "max(UINT32) -> UINT32"               | "[aggregate]" |
      | "max" | "max(UINT64) -> UINT64"               | "[aggregate]" |
      | "max" | "max(FLOAT) -> FLOAT"                 | "[aggregate]" |
      | "max" | "max(DOUBLE) -> DOUBLE"               | "[aggregate]" |
      | "max" | "max(STRING) -> STRING"               | "[aggregate]" |
    When executing query:
      """
      SHOW FUNCTION `fmt`
      """
    Then the result should be, in any order:
      | name  | signature                          | function_type |
      | "fmt" | "fmt(STRING, DOUBLE...) -> STRING" | "[scalar]"    |
      | "fmt" | "fmt(STRING, FLOAT...) -> STRING"  | "[scalar]"    |
      | "fmt" | "fmt(STRING, BOOL...) -> STRING"   | "[scalar]"    |
      | "fmt" | "fmt(STRING, STRING...) -> STRING" | "[scalar]"    |
      | "fmt" | "fmt(STRING, UINT64...) -> STRING" | "[scalar]"    |
      | "fmt" | "fmt(STRING, UINT32...) -> STRING" | "[scalar]"    |
      | "fmt" | "fmt(STRING, UINT16...) -> STRING" | "[scalar]"    |
      | "fmt" | "fmt(STRING, UINT8...) -> STRING"  | "[scalar]"    |
      | "fmt" | "fmt(STRING, INT64...) -> STRING"  | "[scalar]"    |
      | "fmt" | "fmt(STRING, INT32...) -> STRING"  | "[scalar]"    |
      | "fmt" | "fmt(STRING, INT16...) -> STRING"  | "[scalar]"    |
      | "fmt" | "fmt(STRING, INT8...) -> STRING"   | "[scalar]"    |

  Scenario: show procedure
    When executing query:
      """
      SHOW PROCEDURE `KILL\\w*`
      """
    Then the result should be, in any order:
      | proc_type | module    | schema | owner | name           | parameters                                       | return_fields      | null_case | comment                                  |
      | "CPP"     | "dbms.so" | ""     | ""    | "kill_query"   | "query_id:STRING"                                | "query_id:STRING"  | ""        | "kill the query with specified query Id" |
      | "CPP"     | "dbms.so" | ""     | ""    | "kill_session" | "session_id:INT64, reportErrorWhenKillSelf:BOOL" | "session_id:INT64" | ""        | "kill session"                           |

  Scenario: show graphs
    When executing query:
      """
      SHOW GRAPHS of ldbc_type
      """
    Then the execution should be successful
