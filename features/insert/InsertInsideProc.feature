# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Insert inside proc

  Scenario: Inser inside proc
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_proc_insert AS {
        NODE N1 (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE E1 (N1)-[LABEL E1 {ep1 INT, ep2 STRING}]->(N1)
      }
      """
    Then the execution should be successful
    And graph type "gt_proc_insert" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_proc_insert TYPED gt_proc_insert
      """
    Then the execution should be successful
    And graph "g_proc_insert" should be ready to use
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE proc_insert_node(id int) RETURNS () { USE g_proc_insert INSERT (n@N1{id: id, name: "gogogo"}) }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_insert_node(8848) FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_proc_insert MATCH (v{id: 8848}) RETURN v.id AS vid, v.name AS vname
      """
    Then the result should be, in any order:
      | vid  | vname    |
      | 8848 | "gogogo" |
    When executing query:
      """
      CREATE PROCEDURE proc_insert_edge(id int, ep1 int, ep2 STRING) RETURNS () { USE g_proc_insert MATCH (v{id: id}) INSERT (v)-[@E1{ep1: ep1, ep2: ep2}]->(v) }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL proc_insert_edge(8848, 5566, "okk") FINISH
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_proc_insert MATCH (v{id: 8848})-[e]->() RETURN e.ep1 AS ep1, e.ep2 AS ep2
      """
    Then the result should be, in any order:
      | ep1  | ep2   |
      | 5566 | "okk" |
    And drop the procedure "proc_insert_edge"
    And drop the graph "g_proc_insert"
    And drop the graph type "gt_proc_insert"
