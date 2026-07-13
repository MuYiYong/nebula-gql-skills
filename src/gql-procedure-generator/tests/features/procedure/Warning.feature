# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: warning

  Scenario: show warnings
    When executing query:
      """
      SESSION SET SCHEMA "/default_schema"
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_warnings() RETURN code
      """
    Then the result should be, in any order:
      | code    |
      | "01005" |
    When executing query:
      """
      SHOW WARNINGS
      """
    Then the result should be, in any order:
      | code | message |
    When executing query:
      """
      SESSION SET SCHEMA /default_schema
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW WARNINGS
      """
    Then the result should be, in any order:
      | code | message |

  Scenario: show all warnings
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_show_warnings", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_show_warnings" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER user_show_warnings
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_show_warnings" should be granted
    And switch to a new session with username "user_show_warnings" and password "NebulaGraph01"
    When executing query:
      """
      SHOW ALL WARNINGS
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute show_all_warnings"
    When executing query:
      """
      CLEAR WARNINGS "01005"
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute clear_warnings"
    When executing query:
      """
      CLEAR ALL WARNINGS
      """
    Then an Error should be raised: "[NB101]: Insufficient privilege: Only ADMIN can execute clear_all_warnings"
    When executing query:
      """
      SESSION SET SCHEMA "/default_schema"
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA "/default_schema"
      """
    Then the execution should be successful
    And close the current session
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      SHOW ALL WARNINGS
      """
    Then the result should contain:
      | code    | username             | nums |
      | "01005" | "user_show_warnings" | 2    |
    When executing query:
      """
      CLEAR WARNINGS "01005,01006"
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW ALL WARNINGS
      """
    Then the result should be, in any order:
      | code | username | nums |
    When executing query:
      """
      GLOBAL SET GRAPH suppressed_warning_codes =  "01005"
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA "/default_schema"
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW WARNINGS
      """
    Then the result should be, in any order:
      | code | message |
    # runtime label type filter warning
    When executing query:
      """
      USE ldbc {
        MATCH (v:Person {id:2}) RETURN type(v) AS t
        NEXT
        MATCH (v:t {id:1}) RETURN v.id
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_warnings() RETURN code
      """
    Then the result should contain:
      | code    |
      | "01006" |
    # Pay attention to clear warnings, Scenarios may runs concurrently, this will clear other scenario's warnings
    When executing query:
      """
      CLEAR ALL WARNINGS
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "user_show_warnings"
    And logout from the meta
