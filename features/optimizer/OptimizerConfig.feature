# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: OptimizerConfig

  Scenario: disable rules
    When executing query:
      """
      /*+ SET_VAR(optimizer_rules = "get_node_to_node_scan=off") */
      USE ldbc MATCH (v:Person) RETURN v
      """
    Then an Error should be raised: "[NZ001]: Optimizer internal error: no execution plan generated, optimizer rules may be disabled or misconfigured"
