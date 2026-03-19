# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Node2IdRule

  Scenario: basic
    When executing query:
      """
      EXPLAIN
      use ldbc
      match (v:Person{id:1})-[r:KNOWS]->(w:Person) return v.id, count(w) as cnt
      """
    Then the execution should be successful
    When executing query:
      """
      EXPLAIN
      use ldbc
      match (v:Person{id:1})-[r:KNOWS]->(w:Person) return v.id, count(distinct w) as cnt
      """
    Then the execution should be successful
