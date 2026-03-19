# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: MergeLimitsRule

  Scenario: mergeLimits
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "merge_limits=on") */
      for x in LIST[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
      return x as c
      next
      return c offset 3 limit 10
      next
      return c offset 2 limit 10
      next let y = c + 1
      return c offset 1 limit 20
      """
    Then the result should be, in any order:
      | c  |
      | 7  |
      | 8  |
      | 9  |
      | 10 |
      | 11 |
      | 12 |
      | 13 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "merge_limits=on") */
      for x in LIST[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
      return x as c
      next
      return c limit 4
      next
      return c offset 5
      """
    Then the result should be, in any order:
      | c |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "merge_limits=on") */
      use ldbc match (v@Person{id:1})-[e]->(w)
      return v.id as id limit 1
      """
    Then the result should be, in any order:
      | id |
      | 1  |
