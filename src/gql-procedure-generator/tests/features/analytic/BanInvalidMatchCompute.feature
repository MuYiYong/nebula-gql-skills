# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Ban Invalid Match Compute After Import

  Scenario: Match compute is forbidden in same procedure and ancestors after import
    And drop the graph type "ban_invalid_match_compute_gt"
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS ban_invalid_match_compute_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY
          }
        ),
        EDGE Knows (Person)-[:Knows{
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE ban_invalid_mc_child_import() AS {
        TABLE persons TYPED TABLE {id INT} =
          {id: 1},
          {id: 2}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 10}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE ban_invalid_mc_child_match() AS {
        NODE VALUE cnt SumAgg<INT> = 0

        MATCH (p@Person)
        PER NODE (p) {
          SET p.@cnt += 1
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE ban_invalid_mc_child_import_then_match() AS {
        NODE VALUE cnt SumAgg<INT> = 0
        TABLE persons TYPED TABLE {id INT} =
          {id: 1},
          {id: 2}

        TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
          {src_id: 1, dst_id: 2, id: 10}

        IMPORT INTO GRAPH {
          NODE (p@Person{ id: id }) FROM persons,
          EDGE (id:src_id)-[e@Knows{ id: id }]->(id:dst_id) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }

        MATCH (p@Person)
        PER NODE (p) {
          SET p.@cnt += 1
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE ban_invalid_mc_parent_call_child_import_then_match() AS {
        GRAPH g TYPED ban_invalid_match_compute_gt
        USE g
        CALL ban_invalid_mc_child_import_then_match() FINISH
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE ban_invalid_mc_parent_after_import_match() AS {
        GRAPH g TYPED ban_invalid_match_compute_gt
          USE g {
          NODE VALUE cnt SumAgg<INT> = 0

          USE g
          CALL ban_invalid_mc_child_import() FINISH

          USE g {
            MATCH (p@Person)
            PER NODE (p) {
              SET p.@cnt += 1
            }
          }
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE ban_invalid_mc_parent_call_sibling() AS {
        GRAPH g TYPED ban_invalid_match_compute_gt
        USE g
        CALL ban_invalid_mc_child_import() FINISH
        USE g
        CALL ban_invalid_mc_child_match() FINISH
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CALL ban_invalid_mc_parent_call_child_import_then_match() FINISH
      """
    Then an Error should be raised: "[NR153]: Temporary graph failed to execute match-compute: Graph version mismatch: expected 2, got 3"
    When executing graph query:
      """
      CALL ban_invalid_mc_parent_after_import_match() FINISH
      """
    Then an Error should be raised: "[NR153]: Temporary graph failed to execute match-compute: Graph version mismatch: expected 2, got 3"
    When executing graph query:
      """
      CALL ban_invalid_mc_parent_call_sibling() FINISH
      """
    Then the execution should be successful
    And drop the procedure "ban_invalid_mc_parent_call_sibling"
    And drop the procedure "ban_invalid_mc_parent_after_import_match"
    And drop the procedure "ban_invalid_mc_parent_call_child_import_then_match"
    And drop the procedure "ban_invalid_mc_child_import_then_match"
    And drop the procedure "ban_invalid_mc_child_match"
    And drop the procedure "ban_invalid_mc_child_import"
    And drop the graph type "ban_invalid_match_compute_gt"
