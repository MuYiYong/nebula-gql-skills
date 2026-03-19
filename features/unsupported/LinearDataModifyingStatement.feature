# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Unsupported linear data modifying statement

  Scenario: Multiple modifying statements
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS multiple_ddl_test_graph_type AS {
        NODE node_type_player (LABEL player {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS multiple_ddl_test_graph TYPED multiple_ddl_test_graph_type
      """
    Then the execution should be successful
    And graph "multiple_ddl_test_graph" should be ready to use
    When executing query:
      """
      SESSION SET GRAPH multiple_ddl_test_graph
      """
    Then the execution should be successful
    When executing query:
      """
      INSERT (:player{id:1,name:"jack"})
      INSERT (:player{id:2,name:"rose"})
      """
    Then an Error should be raised: "[NT103]: Only one DML allowed, must be last, optionally followed by FINISH"
    When executing query:
      """
      INSERT (:player{id:1,name:"jack"})
      """
    Then the execution should be successful
    When executing query:
      """
      INSERT (:player{id:2,name:"rose"})
      RETURN v
      """
    Then an Error should be raised: "[NT103]: Only one DML allowed, must be last, optionally followed by FINISH"
    When executing query:
      """
      MATCH (v)
      SET v.name = "lee"
      RETURN count(v) GROUP BY ()
      """
    Then an Error should be raised: "[NT103]: Only one DML allowed, must be last, optionally followed by FINISH"
    When executing query:
      """
      VALUE a = 1
      SET a = a + 2
      RETURN a
      """
    Then the execution should be successful
    And drop the graph "multiple_ddl_test_graph"
    And drop the graph type "multiple_ddl_test_graph_type"
    And reset graph
