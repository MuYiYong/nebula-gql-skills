# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: If Statement

  Scenario: basic
    When executing query:
      """
      IF true THEN {
        RETURN 1 AS a
      } ELSE {
        RETURN 2 AS a
      }
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      VALUE a = 1
      IF a = 2 THEN { RETURN 1 AS x }
      ELSEIF a = 1 THEN { RETURN 2 AS x, 3 AS y }
      ELSE { RETURN 4 AS x }
      """
    Then an Error should be raised: "[NS217]: All branches of the if statement must have the same column names and compatible types"
    When executing query:
      """
      IF true THEN {
        RETURN 1 AS a
      }
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      IF false THEN {
        RETURN 1 AS a
      } ELSE {
        RETURN 2 AS a
      }
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      SESSION SET VALUE $temp_param = 100
      """
    Then the execution should be successful
    When executing query:
      """
      IF $temp_param = 100 THEN {
        RETURN "Equal" AS result
      } ELSE {
        RETURN "Not Equal" AS result
      }
      """
    Then the result should be, in any order:
      | result  |
      | "Equal" |
    When executing query:
      """
      SESSION RESET $temp_param
      """
    Then the execution should be successful
    When executing query:
      """
      VALUE a = 1
      IF a = 1 THEN {
        RETURN a AS b
      } ELSE {
        RETURN 2 AS b
      }
      """
    Then the result should be, in any order:
      | b |
      | 1 |
    When executing query:
      """
      IF true THEN {
        RETURN 1 AS a
      } ELSE {
        RETURN 2 AS b
      }
      """
    Then an Error should be raised: "[NS217]: All branches of the if statement must have the same column names and compatible types"
    When executing query:
      """
      IF true THEN {
        RETURN 1 AS a
      } ELSE {
        RETURN 2 AS a, 3 AS b
      }
      """
    Then an Error should be raised: "[NS217]: All branches of the if statement must have the same column names and compatible types"
    When executing query:
      """
      IF true THEN {
        RETURN 1 AS a
      } ELSE {
        RETURN false AS a
      }
      """
    Then an Error should be raised: "[NS217]: All branches of the if statement must have the same column names and compatible types"
    When executing query:
      """
      VALUE a = 1
      IF a = 1 THEN { RETURN a }
      ELSE { RETURN 2 AS a }
      """
    Then the result should be, in any order:
      | a |
      | 1 |
    When executing query:
      """
      value i int = -10
      if i < 0 then {
        call {let c = 10 return c+i as d } return d
      }
      """
    Then the result should be, in any order:
      | d |
      | 0 |
