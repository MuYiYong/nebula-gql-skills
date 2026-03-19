# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: SimplifyComparisonRule

  Scenario: cast expression with index scan
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS cast_index_type AS {
        NODE player (LABEL player {id INT PRIMARY KEY, score INT16})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS cast_index_graph TYPED cast_index_type
      """
    Then the execution should be successful
    When executing query:
      """
      USE cast_index_graph CREATE INDEX IF NOT EXISTS player_score_idx ON NODE player(score)
      """
    Then the execution should be successful
    And index "player_score_idx" of "cast_index_graph" should be ready to use
    When executing query:
      """
      USE cast_index_graph INSERT
      (@player{id: 1, score: 100}),
      (@player{id: 2, score: 200}),
      (@player{id: 3, score: 300}),
      (@player{id: 4, score: 400})
      """
    Then the execution should be successful
    # Test without explicit cast - type system will add implicit cast to v.score.
    # CAST(score AS INT32) > 250 should be rewritten as score > 250, where 250 is INT16
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE cast_index_graph
      MATCH (v:player) WHERE v.score > 250
      RETURN v.id AS id, v.score AS score
      """
    Then the result should be, in any order:
      | id | score |
      | 3  | 300   |
      | 4  | 400   |
    # Test with explicit cast - should be optimized to use index scan
    # CAST(score AS INT32) > 250 should be rewritten as score > 250, where 250 is INT16
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE cast_index_graph
      MATCH (v:player) WHERE CAST(v.score AS INT32) > 250
      RETURN v.id AS id, v.score AS score
      """
    Then the result should be, in any order:
      | id | score |
      | 3  | 300   |
      | 4  | 400   |
    # Test with range adjustment
    # CAST(score AS DECIMAL) > 310.2, where 310.2 is decimal, should be rewritten as score > 310, where 310 is INT16
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE cast_index_graph
      MATCH (v:player) WHERE CAST(v.score AS INT32) > 310.2
      RETURN v.id AS id, v.score AS score
      """
    Then the result should be, in any order:
      | id | score |
      | 4  | 400   |
    # Test with constant out of range of column type
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE cast_index_graph
      MATCH (v:player) WHERE CAST(v.score AS INT32) > 123456789
      RETURN v.id AS id, v.score AS score
      """
    Then an Error should be raised: "[NZ001]: Optimizer internal error: no execution plan generated, optimizer rules may be disabled or misconfigured"
    And drop the index "player_score_idx" of "cast_index_graph"
    And drop the graph "cast_index_graph"
    And drop the graph type "cast_index_type"
