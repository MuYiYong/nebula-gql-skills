# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: transaction

  Scenario: basic
    When executing query:
      """
      START TRANSACTION
      """
    Then the execution should be successful
    When executing query:
      """
      START TRANSACTION READ ONLY
      """
    Then the execution should be successful
    When executing query:
      """
      START TRANSACTION READ WRITE
      """
    Then the execution should be successful
    When executing query:
      """
      COMMIT
      """
    Then the execution should be successful
    When executing query:
      """
      ROLLBACK
      """
    Then the execution should be successful
    When executing query:
      """
      START TRANSACTION
      RETURN 1 AS a
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      RETURN 2 AS b
      COMMIT
      """
    Then the result should be, in any order:
      | b |
      | 2 |
    When executing query:
      """
      START TRANSACTION
      RETURN 1 AS a
      COMMIT
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      START TRANSACTION
      VALUE a = 1
      IF true THEN {
        SET a = a + 1
      } ELSE {
        SET a = a - 1
      }
      RETURN a
      COMMIT
      """
    Then the result should be, in any order:
      | a |
      | 2 |
