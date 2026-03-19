# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: privilege on temporary graph

  Scenario: vesoft-inc/nebula-ng#8958
    When executing query:
      """
      GRANT MATCH ON GRAPH /default_schema/#analytic_ldbc TO USER root
      """
    Then an Error should be raised: "[42001]: syntax error near `#analytic_ldbc`"
    When executing query:
      """
      GRANT MATCH ON GRAPH `/default_schema/#analytic_ldbc` TO USER root
      """
    Then an Error should be raised: "[01G03]: Graph `#analytic_ldbc` not found in schema `/default_schema`"
    When executing query:
      """
      GRANT MATCH ON GRAPH `/tmp_schema/#analytic_ldbc` TO USER root
      """
    Then an Error should be raised: "[NS000]: Semantic error: The schema `/tmp_schema` is reserved and cannot be used"
    When executing query:
      """
      GRANT MATCH ON GRAPH `#analytic_ldbc` TO USER root
      """
    Then an Error should be raised: "[NB000]: Authorization error: Cannot grant/revoke privilege on temporary schema"
    When executing query:
      """
      REVOKE MATCH ON GRAPH /default_schema/#analytic_ldbc FROM USER root
      """
    Then an Error should be raised: "[42001]: syntax error near `#analytic_ldbc`"
    When executing query:
      """
      REVOKE MATCH ON GRAPH `/default_schema/#analytic_ldbc` FROM USER root
      """
    Then an Error should be raised: "[01G03]: Graph `#analytic_ldbc` not found in schema `/default_schema`"
    When executing query:
      """
      REVOKE MATCH ON GRAPH `/tmp_schema/#analytic_ldbc` FROM USER root
      """
    Then an Error should be raised: "[NS000]: Semantic error: The schema `/tmp_schema` is reserved and cannot be used"
    When executing query:
      """
      REVOKE MATCH ON GRAPH `#analytic_ldbc` FROM USER root
      """
    Then an Error should be raised: "[NB000]: Authorization error: Cannot grant/revoke privilege on temporary schema"
