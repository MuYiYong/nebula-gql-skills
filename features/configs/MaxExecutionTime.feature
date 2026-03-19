# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: max execution time

  Scenario: query deadline exceeded
    When executing query with timeout "2000" us:
      """
      USE ldbc
      MATCH TRAIL (n)-[]->{0,100}(m)
      RETURN n
      """
    Then an Error should be raised: "[TN001]: RPC failed, Deadline Exceeded"

  @pretest
  Scenario: insert failed caused by timeout
    Given a ldbc graph copy named "ldbc_dml_timeout_test"
    When executing query with timeout "1" us:
      """
      USE ldbc_dml_timeout_test
      INSERT (:Tag{id:5, name:"tag5", url:"https://tag5.com"})
      """
    Then an Error should be raised: "[TN001]: RPC failed, Deadline Exceeded"
    And wait "3" seconds
    # Cancel the DML before it started
    # When executing query:
    # """
    # USE ldbc_dml_timeout_test
    # MATCH (v:Tag WHERE v.id=5) RETURN v.name AS name
    # """
    # Then the result should be, in any order:
    # | name |
    And drop the graph "ldbc_dml_timeout_test"

  @skip @pretest
  Scenario: kill failed since DML started
    Given a ldbc graph copy named "ldbc_kill_failed_test"
    When executing query with timeout "2000" us:
      """
      USE ldbc_kill_failed_test
      INSERT (:Tag{id:5, name:"tag5", url:"https://tag5.com"})
      """
    Then an Error should be raised: "[TN001]: RPC failed, Deadline Exceeded"
    And wait "3" seconds
    # Cancel the DML after it started
    When executing query:
      """
      USE ldbc_kill_failed_test
      MATCH (v:Tag WHERE v.id=5) RETURN v.name AS name
      """
    Then the result should be, in any order:
      | name   |
      | "tag5" |
    And drop the graph "ldbc_kill_failed_test"
