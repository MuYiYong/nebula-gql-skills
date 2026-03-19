# Copyright (c) 2023 vesoft inc. All rights reserved.
@pretest @skip
Feature: show and kill query

  Scenario: longtime query1
    When executing raw query:
      """
      USE ldbc MATCH test_kill_query_path=TRAIL (a)-[]-{20}() RETURN a AS t
      """
    Then an Error should be raised: "[NR302]: Query is canceled by user"

  Scenario: longtime query2
    When executing raw query:
      """
      USE ldbc MATCH test_kill_query_path=ANY SHORTEST (v1)-[e1]->{1,10}(v2) RETURN v1 LIMIT 10
      """
    Then an Error should be raised: "[NR302]: Query is canceled by user"

  Scenario: kill longtime queries
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"kill_query_user", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    # the "longtime query2" takes ~1.7 seconds to execute, so we wait for 1 second
    And wait "1" seconds
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      GRANT CONNECT TO USER kill_query_user
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "kill_query_user" should be granted
    And switch to a new session with username "kill_query_user" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_queries() YIELD query_id AS qid, `query` AS qstr, username
      FILTER qstr LIKE "%test_kill_query_path%"
      CALL kill_query(qid) YIELD query_id AS id
      RETURN username, qstr
      """
    Then an Error should be raised: "[NR401]: Kill query failed: only ADMIN or query's owner can kill query"
    # TODO should verify if the type of session_start is zoned datetime.
    # maybe we could use <value type predicate>, but not implemented yet.
    # and then verify if current_time - session_start < 1min for example.
    When executing query:
      """
      CALL show_sessions() YIELD active_query AS qstr, username
      FILTER qstr LIKE "%test_kill_query_path%"
      RETURN username, qstr
      """
    Then the result should be, in any order:
      | username | qstr                                                                                        |
      | "root"   | "USE ldbc MATCH test_kill_query_path=TRAIL (a)-[]-{20}() RETURN a AS t"                     |
      | "root"   | "USE ldbc MATCH test_kill_query_path=ANY SHORTEST (v1)-[e1]->{1,10}(v2) RETURN v1 LIMIT 10" |
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_queries() YIELD query_id AS qid, `query` AS qstr, username
      FILTER qstr LIKE "%test_kill_query_path%"
      CALL kill_query(qid) YIELD query_id AS id
      RETURN username, qstr
      """
    Then the result should be, in any order:
      | username | qstr                                                                                        |
      | "root"   | "USE ldbc MATCH test_kill_query_path=TRAIL (a)-[]-{20}() RETURN a AS t"                     |
      | "root"   | "USE ldbc MATCH test_kill_query_path=ANY SHORTEST (v1)-[e1]->{1,10}(v2) RETURN v1 LIMIT 10" |
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "kill_query_user"
    And logout from the meta

  Scenario: show session
    When executing raw query:
      """
      CALL show_current_session() RETURN username, active_query
      """
    Then the result should be, in any order:
      | username | active_query                                                |
      | "root"   | "CALL show_current_session() RETURN username, active_query" |

  Scenario: kill session
    And login meta with username "root" and password "NebulaGraph01"
    When create a new user:
      """
      {"username":"kill_session_user", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    When create a new user:
      """
      {"username":"killed_session_user", "password":"NebulaGraph01", "ifNotExists":true}
      """
    Then the execution should be successful
    And logout from the meta
    And create a new session with username "root" and password "NebulaGraph01"
    And wait "5" seconds
    When executing query:
      """
      GRANT CONNECT TO USER kill_session_user
      """
    Then the execution should be successful
    When executing query:
      """
      GRANT CONNECT TO USER killed_session_user
      """
    Then the execution should be successful
    And action "CONNECT" on "SVCGRP" for user "killed_session_user" should be granted
    And switch to a new session with username "killed_session_user" and password "NebulaGraph01"
    And create a new session with username "kill_session_user" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_sessions() YIELD username AS name, id AS sid
      FILTER name = "killed_session_user"
      CALL kill_session(sid) RETURN *
      """
    Then an Error should be raised: "[NR402]: Kill session failed: only ADMIN or session's owner can kill session"
    # close killed_session_user 's session
    And close the current session
    And switch to a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CALL show_sessions() YIELD username AS name, id AS sid
      FILTER name = "killed_session_user"
      CALL kill_session(sid) RETURN *
      """
    Then the execution should be successful
    And close the current session
    And login meta with username "root" and password "NebulaGraph01"
    And drop the user "kill_session_user"
    And drop the user "killed_session_user"
    And logout from the meta
