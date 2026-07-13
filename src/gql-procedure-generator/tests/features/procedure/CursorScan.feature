# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: cursor scan

  Scenario: cursor node scan
    When executing query:
      """
      CALL cursor_node_scan("ldbc", "Person", list["firstName", "lastName"], 1, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_node_scan("ldbc", "Person", list["firstName", "lastName"], 2, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_node_scan("ldbc", "Person", list[], 2, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_node_scan("ldbc", "Person", list["firstName", "lastName"], 3, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_node_scan("ldbc", "Person", list["firstName", "lastName", null], 3, "", 10) RETURN *
      """
    Then an Error should be raised: "[ND004]: Property `null` of type `Person` not found"
    When executing query:
      """
      CALL cursor_node_scan("ldbc", "Person", list[1, 2], 3, "", 10) RETURN *
      """
    Then an Error should be raised: "[NP102]: Invalid argument for procedure `cursor_node_scan`: argument `LIST[1, 2]` is of type `LIST<INT32>` instead of the expected `LIST<STRING>`"

  Scenario: cursor edge scan
    When executing query:
      """
      CALL cursor_edge_scan("ldbc", "KNOWS", list["creationDate"], 1, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_scan("ldbc", "KNOWS", list["creationDate"], 2, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_scan("ldbc", "KNOWS", list["creationDate"], 3, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_scan("ldbc", "KNOWS", list[], 3, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_scan("ldbc", "KNOWS", list["id", null], 3, "", 10) RETURN *
      """
    Then an Error should be raised: "[ND004]: Property `id` of type `KNOWS` not found"

  Scenario: cursor edge scan
    When executing query:
      """
      CALL cursor_edge_only_scan("ldbc", "KNOWS", list["creationDate"], 1, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_only_scan("ldbc", "KNOWS", list["creationDate"], 2, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_only_scan("ldbc", "KNOWS", list["creationDate"], 3, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_only_scan("ldbc", "KNOWS", list[], 3, "", 10) RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      CALL cursor_edge_only_scan("ldbc", "KNOWS", list["id", null], 3, "", 10) RETURN *
      """
    Then an Error should be raised: "[ND004]: Property `id` of type `KNOWS` not found"
