# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: PushTopNDownEdgeJoinRule

  Scenario: Basic
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_edge_join=on") */
      use ldbc match (v@Person)-[e:LIKES]-(v2) order by e.creationDate limit 10 return v2.id as c
      """
    Then the result should be, in any order:
      | c |
      | 1 |
      | 2 |
      | 3 |
      | 1 |
      | 2 |
      | 3 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_edge_join=on") */
      use ldbc match (v@Person)-[e:LIKES]-(v2) order by e.creationDate limit 10 offset 2 return v2.id as c
      """
    Then the result should be, in any order:
      | c |
      | 3 |
      | 1 |
      | 2 |
      | 3 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_edge_join=on") */
      use ldbc match (v@Person)-[e:LIKES]-(v2) order by v2.id offset 1 limit 10  return v2.id
      """
    Then the result should be, in any order:
      | v2.id |
      | 1     |
      | 2     |
      | 2     |
      | 3     |
      | 3     |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_edge_join=on") */
      use ldbc match (v@Person)-[e:LIKES]-(v2) return v2.id as c order by e.creationDate  offset 2  limit 10
      """
    Then the result should be, in any order:
      | c |
      | 3 |
      | 1 |
      | 2 |
      | 3 |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_edge_join=on") */
      use ldbc match (v@Person)-[e:LIKES]-(v2) return v2.id,  e.creationDate  as c order by e.creationDate  offset 2  limit 2
      """
    Then the result should be, in any order:
      | v2.id | c                                      |
      | 3     | DATETIME  '2021-04-01T10:00:40.213000' |
      | 1     | DATETIME  '2121-01-01T10:00:40.213000' |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "push_top_n_down_edge_join=on") */
      use ldbc match (v@Person)-[e:LIKES]-(v2) return v2.id,  e.creationDate  as c order by e.creationDate  offset 1  limit 4
      """
    Then the result should be, in any order:
      | v2.id | c                                     |
      | 2     | DATETIME '2021-03-01T10:00:40.213000' |
      | 3     | DATETIME '2021-04-01T10:00:40.213000' |
      | 1     | DATETIME '2121-01-01T10:00:40.213000' |
      | 2     | DATETIME '2221-01-01T10:00:40.213000' |
