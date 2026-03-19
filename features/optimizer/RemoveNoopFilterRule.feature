# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: RemoveNoopFilterRule

  Scenario: RemoveNoopFilterRule
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      LET id=v.id+1, name=v.firstName
      FILTER 1 = 1 AND 2 = 2
      RETURN name,id
      """
    Then the result should be, in any order:
      | name     | id |
      | "Kyle"   | 2  |
      | "Ming"   | 4  |
      | "Tim"    | 3  |
      | "Sophie" | 5  |
    # Since the filter condition equals to FALSE,
    # the filter subplan should be replaced with a empty values plan.
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE v.id = 1 AND FALSE
      RETURN v.id AS id, v.firstName AS name
      """
    Then the result should be, in any order:
      | id | name |
    When executing query:
      """
      USE ldbc
      MATCH (v:Person)
      WHERE v.id = 1 AND NULL
      RETURN v.id AS id, v.firstName AS name
      """
    Then the result should be, in any order:
      | id | name |
