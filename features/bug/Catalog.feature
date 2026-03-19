# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: catalog

  # https://github.com/vesoft-inc/nebula-ng/issues/8273
  Scenario: alter hangs
    When executing query:
      """
      create graph type if not exists test_edge_only_8273 as {
        node Person( LABELS Person_Label {id INT PRIMARY KEY,  age INT64}),
        edge Enjoy_SD(Person)~[ LABELS LIKES&Enjoy_SD {name string}]~(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      alter graph type test_edge_only_8273 {
        add edge type WorkAt(Person)-[:WorkAt]->(Company)
      }
      """
    Then an Error should be raised: "[NC003]: Node type not found: `Company`"
    And drop the graph type "test_edge_only_8273"
