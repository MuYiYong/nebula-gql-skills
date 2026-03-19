# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Memory

  Scenario: InvalidParameter
    When executing query:
      """
      /*+ SET_VAR(memory = 16368) */ RETURN [10 - 25] as a
      """
    Then an Error should be raised: "[NV001]: Unknown config found: `memory`"
    When executing query:
      """
      /*+ SET_VAR(memory_limit_bytes = 512) */ RETURN [10] as a
      """
    Then an Error should be raised: "Memory usage for Query exceeded hard limit 512"
    When executing query:
      """
      /*+ SET_VAR(memory_limit_bytes = "102400") */ RETURN [10 - 25] as a
      """
    Then an Error should be raised: "[NV002]: Config `memory_limit_bytes` required type INT64, but got STRING"

  Scenario: MemoryExceeded
    When executing query:
      """
      /*+ SET_VAR(graph_memory_limit_bytes = 1024) */ USE ldbc MATCH (person:Person) RETURN count(person) AS c GROUP BY ()
      """
    Then an Error should be raised: "Memory usage for Query exceeded hard limit 1024"
    When executing query:
      """
      /*+ SET_VAR(storage_memory_limit_bytes = 1024) */ USE ldbc MATCH (person:Person) RETURN count(person) AS c GROUP BY ()
      """
    Then an Error should be raised: "Memory usage for Query exceeded hard limit 1024"

  Scenario: MemoryNotExceeded
    When executing query:
      """
      /*+ SET_VAR(memory_limit_bytes = 32768000) */ USE ldbc MATCH (person:Person) RETURN count(person) AS c GROUP BY ()
      """
    Then the result should be, in any order:
      | c |
      | 4 |
    When executing query:
      """
      /*+ SET_VAR(graph_memory_limit_bytes = 32768000) */ USE ldbc MATCH (person:Person) RETURN count(person) AS c GROUP BY ()
      """
    Then the result should be, in any order:
      | c |
      | 4 |
    When executing query:
      """
      /*+ SET_VAR(storage_memory_limit_bytes = 32768000) */ USE ldbc MATCH (person:Person) RETURN count(person) AS c GROUP BY ()
      """
    Then the result should be, in any order:
      | c |
      | 4 |
