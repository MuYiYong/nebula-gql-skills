# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: NoReorder

  Background:
    And executes "SESSION SET enable_reorder = false"

  Scenario: No-reorder keeps automatic bi-varlen selection
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS bivarlen_no_reorder_auto_type AS {
        NODE Person (LABEL Person {id INT PRIMARY KEY}),
        EDGE KNOWS (Person)-[:KNOWS]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS bivarlen_no_reorder_auto TYPED bivarlen_no_reorder_auto_type
      """
    Then the execution should be successful
    And use graph "bivarlen_no_reorder_auto"
    # Both endpoint GetNodes are index-constrained and cheap. Disabling general query
    # reorder should not make this classic two-endpoint bounded var-length query fall
    # back to one-sided Expand(All).
    When executing query:
      """
      EXPLAIN
      MATCH path = walk (src:Person{id: 1})-[e:KNOWS]->{1,3}(dst:Person{id: 2})
      RETURN count(*)
      """
    Then the execution should be successful
    And the plan should contain "BiVarLenExpand"
    And the plan should not contain "VarLenExpand(All"
    And drop the graph "bivarlen_no_reorder_auto"
    And drop the graph type "bivarlen_no_reorder_auto_type"
