# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Mathematical1

  Scenario: plus
    When executing query:
      """
      RETURN 10 + 25 as a
      """
    Then the result should be, in any order:
      | a  |
      | 35 |

  Scenario: minus
    When executing query:
      """
      RETURN 10 - 25 as a
      """
    Then the result should be, in any order:
      | a   |
      | -15 |

  Scenario: multiplication
    When executing query:
      """
      RETURN 25 * 25 as a
      """
    Then the result should be, in any order:
      | a   |
      | 625 |

  Scenario: division
    When executing query:
      """
      RETURN 25 / 10 as a
      """
    Then the result should be, in any order:
      | a |
      | 2 |

  Scenario: mod
    When executing query:
      """
      RETURN 25 % 10 as a
      """
    Then the result should be, in any order:
      | a |
      | 5 |
