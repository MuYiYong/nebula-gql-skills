# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: DelimScan prune bug

  # https://github.com/vesoft-inc/nebula-ng/issues/5351
  Scenario: use previous variable in the where clause of next optional match
    When executing query:
      """
      USE ldbc
      MATCH (m:Person)
      LET seed = 2
      OPTIONAL MATCH (m)-[:KNOWS]->(n)
      WHERE n.id <> seed
      RETURN n.id AS nid
      """
    Then the result should be, in any order:
      | nid  |
      | NULL |
      | NULL |
      | 3    |
      | 1    |
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "enhanced_column_pruner=on") */
      USE ldbc
      MATCH (m:Person)
      LET seed = 2
      OPTIONAL MATCH (m)-[:KNOWS]->(n)
      WHERE n.id <> seed
      RETURN n.id AS nid
      """
    Then the execution should be successful
