# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Constant folding requires casting

  # https://github.com/vesoft-inc/nebula-ng/issues/2337
  Scenario: Constant folding requires casting
    When executing query:
      """
      RETURN  20 > (22 / 27) AS a
      """
    Then the result should be, in order:
      | a    |
      | true |
    When executing query:
      """
      RETURN  40 / 43 AS a
      """
    Then the result should be, in order:
      | a |
      | 0 |
    # Divide by 0
    When executing query:
      """
      RETURN  27 / 0 as a
      """
    Then an Error should be raised: "[22012]: Division by zero: `27 / 0`, type: `INT32`, in expression: 27 / 0"
    When executing query:
      """
      RETURN +(22 - 89) / ((27 - 11) / (40 / 43)) AS a
      """
    Then an Error should be raised: "[22012]: Division by zero: `16 / 0`, type: `INT32`, in expression: -67 / 16 / 0"
    When executing query:
      """
      RETURN ((+(+20)) > ((+(22 - 89)) / ((27 - 11) / (40 / 43)))) AS a
      """
    Then an Error should be raised: "[22012]: Division by zero: `16 / 0`, type: `INT32`, in expression: 20 > -67 / 16 / 0"
