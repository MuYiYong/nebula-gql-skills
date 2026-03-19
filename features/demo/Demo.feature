# Copyright (c) 2020 vesoft inc. All rights reserved.
Feature: Demo

  Scenario Outline: AdditionExamples
    Then Sum of "<a>" and "<b>" should be "<c>"

    Examples:
      | a | b | c |
      | 1 | 2 | 3 |
      | 4 | 5 | 9 |

  Scenario Outline: AdditionExamples1
    Then Sum of "<e>" and "<f>" should be "<g>"

    Examples:
      | e | f | g |
      | 4 | 2 | 6 |
      | 3 | 1 | 4 |

  Scenario: Addition
    Then Sum of "1" and "2" should be "3"

  Scenario: Query
    When executing query:
      """
      malformed query
      """

  @skip
  Scenario: Skiped
    Then Sum of "1" and "2" should be "3"
