# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: PushTopNDownProject

  Scenario: basic test
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_project=on") */
      use ldbc
      match (v)-[e:LIKES]->(v1)
      return e.creationDate order by e.creationDate limit 10
      """
    Then the result should be, in any order:
      | e.creationDate                        |
      | DATETIME "2021-01-01T10:00:40.213000" |
      | DATETIME "2021-03-01T10:00:40.213000" |
      | DATETIME "2021-04-01T10:00:40.213000" |
      | DATETIME "2121-01-01T10:00:40.213000" |
      | DATETIME "2221-01-01T10:00:40.213000" |
      | DATETIME "2321-01-01T10:00:40.213000" |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_project=on") */
      use ldbc
      match (v)
      return v.id order by v.id offset 2 limit 10
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
      | 1    |
      | 1    |
      | 1    |
      | 1    |
      | 1    |
      | 2    |
      | 2    |
      | 2    |
      | 2    |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_project=on") */
      use ldbc
      match (v1:Person)-[e]->(v2)
      return v1 as v2, v2 as v1
      next use ldbc
      order by abs(v1.id)-v2.id desc
      return v1.id as vid, v2.id as v1 limit 3
      """
    Then the result should be, in any order:
      | vid | v1 |
      | 4   | 2  |
      | 2   | 1  |
      | 3   | 2  |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_project=on") */
      use ldbc {
          match (v)
          return v as c
          next
          return c as d
          next
          return d as c order by c.id limit 10
          next
          return c.id as g
      }
      """
    Then the result should be, in any order:
      | g |
      | 1 |
      | 1 |
      | 1 |
      | 1 |
      | 1 |
      | 1 |
      | 1 |
      | 1 |
      | 2 |
      | 2 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_project=on") */
      use ldbc {
          match (v)
          return v.id as c
          next
          return c + 1 as d
          next
          return d + 2 as c
          next
          return c + 1 as d
          next
          return d + 2 as c order by c limit 10
      }
      """
    Then the result should be, in any order:
      | c |
      | 7 |
      | 7 |
      | 7 |
      | 7 |
      | 7 |
      | 7 |
      | 7 |
      | 7 |
      | 8 |
      | 8 |
