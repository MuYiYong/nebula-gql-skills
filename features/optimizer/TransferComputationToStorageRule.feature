# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: TransferComputationToStorageRule

  Scenario: basic
    When executing query:
      """
      USE ldbc
      MATCH (v:Person) WHERE v.gender = "male"
      RETURN count(*) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
