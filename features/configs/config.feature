# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: configs

  Scenario: session set configs
    When executing query:
      """
      CALL show_session_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should be, in any order:
      | name | v |
    When executing query:
      """
      SESSION SET query_concurrency = 4
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_session_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should be, in any order:
      | name                | v   |
      | "query_concurrency" | "4" |
    When executing query:
      """
      SESSION RESET query_concurrency
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_session_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should be, in any order:
      | name                | v   |
      | "query_concurrency" | "1" |
    When executing query:
      """
      SESSION UNSET query_concurrency
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_session_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should be, in any order:
      | name | v |
    When executing query:
      """
      SESSION SET no_exist_config = 123
      """
    Then an Error should be raised: "[NV001]: Unknown config found: `no_exist_config`"
    When executing query:
      """
      SESSION SET sessionless_user = "root"
      """
    Then an Error should be raised: "[NV006]: Config `sessionless_user` is immutable"

  Scenario: service set configs
    When executing query:
      """
      CALL show_service_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should contain:
      | name       | v                        |
      | "pid_file" | "pids/nebula-graphd.pid" |
    When executing query:
      """
      SERVICE SET GRAPH query_concurrency = 3
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_session_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should be, in any order:
      | name | v |
    When executing query:
      """
      CALL show_service_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should contain:
      | name                | v   |
      | "query_concurrency" | "3" |
    When executing query:
      """
      SERVICE RESET GRAPH query_concurrency
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_service_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should contain:
      | name                | v   |
      | "query_concurrency" | "1" |
    When executing query:
      """
      SERVICE UNSET GRAPH query_concurrency
      """
    Then the execution should be successful
    When executing query:
      """
      SERVICE SET GRAPH no_exist_config = 123
      """
    Then an Error should be raised: "[NV001]: Unknown config found: `no_exist_config`"
    When executing query:
      """
      SERVICE SET GRAPH num_storage_query_threads = 100
      """
    Then an Error should be raised: "[NV001]: Unknown config found: `num_storage_query_threads`"
    When executing query:
      """
      SERVICE SET STORAGE "192.168.8.3:80" num_storage_query_threads = 100
      """
    Then an Error should be raised: "[NV007]: Config error: invalid storage address 192.168.8.3:80"

  Scenario: show storage global configs
    When executing query:
      """
      SHOW GLOBAL CONFIGS STORAGE
      """
    Then the execution should be successful

  Scenario: global set configs
    When executing query:
      """
      GLOBAL SET GRAPH query_concurrency = 3
      """
    Then the execution should be successful
    When executing query:
      """
      GLOBAL SET GRAPH timezone = "UTC"
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_global_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should contain:
      | name                | v     |
      | "query_concurrency" | "3"   |
      | "timezone"          | "UTC" |
    When executing query:
      """
      GLOBAL RESET GRAPH query_concurrency
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_global_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should contain:
      | name                | v     |
      | "query_concurrency" | "1"   |
      | "timezone"          | "UTC" |
    When executing query:
      """
      GLOBAL UNSET GRAPH query_concurrency
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_global_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should contain:
      | name       | v     |
      | "timezone" | "UTC" |
    # Multiple commands are not supported in a request
    When executing query:
      """
      GLOBAL SET GRAPH query_concurrency = 18
      """
    Then the execution should be successful
    When executing query:
      """
      GLOBAL SET GRAPH timezone = "Asia/Tokyo"
      """
    Then the execution should be successful
    When executing query:
      """
      CALL show_global_configs() YIELD name, `value` AS v RETURN name, v
      """
    Then the result should contain:
      | name                | v            |
      | "query_concurrency" | "18"         |
      | "timezone"          | "Asia/Tokyo" |
    When executing query:
      """
      GLOBAL RESET GRAPH query_concurrency
      """
    Then the execution should be successful
    When executing query:
      """
      GLOBAL RESET GRAPH timezone
      """
    Then the execution should be successful
    When executing query:
      """
      GLOBAL SET GRAPH num_storage_query_threads = 100
      """
    Then an Error should be raised: "[NV001]: Unknown config found: `num_storage_query_threads`"
    When executing query:
      """
      GLOBAL SET GRAPH query_concurrency = "100"
      """
    Then an Error should be raised: "[NV002]: Config `query_concurrency` required type INT64, but got STRING"
    When executing query:
      """
      GLOBAL SET STORAGE "192.168.8.3:80" num_storage_query_threads = 100
      """
    Then an Error should be raised: ""

  Scenario: show configs
    When executing query:
      """
      CALL show_configs() YIELD name, `value` AS v
      FILTER name = "max_sessions_per_service" RETURN name, v
      """
    Then the result should be, in any order:
      | name                       | v       |
      | "max_sessions_per_service" | "60000" |

  Scenario: show config
    When executing query:
      """
      CALL show_config("max_sessions_per_service") YIELD name, `value` AS v RETURN name, v
      """
    Then the result should be, in any order:
      | name                       | v       |
      | "max_sessions_per_service" | "60000" |
    When executing query:
      """
      SHOW CONFIG no_exist
      """
    Then an Error should be raised: "[NV001]: Unknown config found: `no_exist`"
    When executing query:
      """
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW CONFIG timezone
      """
    Then the result should be, in any order:
      | name       | type     | value           | default_value | scope     | deprecated | mutable | since   | description                   |
      | "timezone" | "STRING" | "Asia/Shanghai" | "UTC"         | "SESSION" | false      | true    | "5.0.0" | "timezone of current session" |

  Scenario: no privilege
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"user_global_set", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And user "user_global_set" should be ready to use
    When executing query:
      """
      GRANT CONNECT TO USER  user_global_set
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "user_global_set" should be granted
    And switch to a new session with username "user_global_set" and password "NebulaGraph01"
    When executing query:
      """
      SERVICE SET GRAPH max_sessions_per_service = 100
      """
    Then an Error should be raised: "[NV006]: Config `max_sessions_per_service` is immutable"
    And close the current session
    And drop the user "user_global_set"

  Scenario: config hint
    When executing query:
      """
      /*+ hahha */ return 1
      """
    Then an Error should be raised: "[NV000]: Config error: syntax error"
    When executing query:
      """
      /*+ SET_VAR(query_concurrency=20,local_time_format="%H-%M-%S") */ return 1
      """
    Then an Error should be raised: "[NV000]: Config error: syntax error"
    When executing query:
      """
      /*+ set_var(query_concurrency=0) */ return 1
      """
    Then an Error should be raised: "[NV003]: Config data error: Out of range"
    When executing query:
      """
      /*+ set_var(query_concurrency=-1.1D) */ return 1
      """
    Then an Error should be raised: "[NV002]: Config `query_concurrency` required type INT64, but got DOUBLE"
    When executing query:
      """
      /*+ set_var(not_exist_config=1) */ return 1
      """
    Then an Error should be raised: "[NV001]: Unknown config found: `not_exist_config`"
    When executing query:
      """
      /*+ set_var(optimizer_rules="get_node_to_node_index_scan:on") */ return 1
      """
    Then an Error should be raised: "[NV003]: Config data error: Invalid rule format: expect 'rule=state'"
    When executing query:
      """
      /*+ set_var(optimizer_rules="non_exist_rule=off") */ return 1
      """
    Then an Error should be raised: "[NV003]: Config data error: Invalid rule name: rule not found"
    When executing query:
      """
      /*+ set_var(optimizer_rules="get_node_to_node_index_scan=true") */ return 1
      """
    Then an Error should be raised: "[NV003]: Config data error: Invalid rule state: expect 'on' or 'off'"

  Scenario: show internal configs
    When executing query:
      """
      CALL show_configs() YIELD name
      FILTER name IN ['insert_return_id_mapping', 'skip_conflict_check'] RETURN name
      """
    Then the result should be, in any order:
      | name |
    When executing query:
      """
      CALL show_config('insert_return_id_mapping') RETURN name
      """
    Then the result should be, in any order:
      | name                       |
      | "insert_return_id_mapping" |

  Scenario: vesoft-inc/nebula-ng#8858
    When executing query:
      """
      SERVICE SET GRAPH optimizer_rules="push_down_appl=false"
      """
    Then an Error should be raised: "[NV003]: Config data error: Invalid rule state: expect 'on' or 'off'"
    When executing query:
      """
      SERVICE UNSET GRAPH optimizer_rules
      """
    Then the execution should be successful
