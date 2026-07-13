# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Log Test

  Scenario: Log level test
    When executing graph query:
      """
      USE ldbc {
        LOG_DEBUG("This is a debug log")
        LOG_INFO("This is a info log")
        LOG_WARN("This is a warn log")
        LOG_ERROR("This is a error log")
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      SUBMIT USE #analytic_ldbc {
        LOG_DEBUG("This is a debug log")
        LOG_INFO("This is a info log")
        LOG_WARN("This is a warn log")
        LOG_ERROR("This is a error log")
      }
      """
    Then the result should be, in any order:
      | procedure_id | status      |
      | /.+/         | "SUBMITTED" |
    When executing query:
      """
      SUBMIT USE #analytic_ldbc {
        LOG_DEBUG("This is a debug log")
        LOG_INFO("This is a info log")
        LOG_WARN("This is a warn log")
        LOG_ERROR("This is a error log")
      }
      """
    Then an Error should be raised: "[NT601]: Environment GraphD does not support SUBMIT (async execution)"
    When executing analytic query:
      """
      /*+ SET_VAR(procedure_minloglevel = "DEBUG") */
      USE #analytic_ldbc {
        LOG_DEBUG("This is a debug log")
        LOG_INFO("This is a info log")
        LOG_WARN("This is a warn log")
        LOG_ERROR("This is a error log")
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc {
        LOG_FATAL("This is a fatal log")
      }
      """
    Then an Error should be raised: "[NP101]"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {vid INT64, current_score DOUBLE}
        LOG_INFO("TEST")
      }
      """
    Then the execution should be successful

  Scenario: type test
    When executing graph analytic query:
      """
      LOG_INFO(zoned_time("05:06:07.089 +08:00", "%H:%M:%S %Ez"))
      """
    Then the log should contains: "INFO  - 21:06:07.089000 +0000"
    When executing graph analytic query:
      """
      LOG_INFO(VECTOR<3,FLOAT>([0,1,0]))
      """
    Then the log should contains: "INFO  - [0.000000, 1.000000, 0.000000]"
    When executing graph analytic query:
      """
      LOG_ERROR(ST_GeogFromText("POLYGON((0 1, 1 2, 2 3, 0 1))"))
      """
    Then the log should contains: "ERROR - POLYGON((0 1, 1 2, 2 3, 0 1))"
    When executing graph analytic query:
      """
      LOG_WARN(ST_GeogFromWkt("LINESTRING(3 8, 4.7 73.23)"))
      """
    Then the log should contains: "WARN  - LINESTRING(3 8, 4.7 73.23)"
    When executing graph analytic query:
      """
      VALUE flag BOOL = true
      LOG_INFO(flag)
      """
    Then the log should contains: "INFO  - true"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s:Person)-[e:FOLLOWS]->(t)
          PER PATH {
            LOG_INFO(t)
          }
      }
      """
    Then the log should contains: "@Person:Person"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s:Person)-[e:FOLLOWS]->(t)
          PER PATH {
            LOG_INFO(e)
          }
      }
      """
    Then the log should contains: "@FOLLOWS:FOLLOWS"
    When executing query:
      """
      VALUE a = VALUE {USE ldbc MATCH (v:Person) ORDER BY v.id RETURN v LIMIT 1 } LOG_INFO(a)
      """
    Then the log should contains: "@Person:Person"
    When executing query:
      """
      VALUE a = VALUE {USE ldbc MATCH (v:Person)-[e:KNOWS]->() ORDER BY v.id RETURN e LIMIT 1 } LOG_INFO(a)
      """
    Then the log should contains: "@KNOWS:KNOWS"

  Scenario: Detailed path info
    When executing query:
      """
      VALUE a = VALUE { USE #analytic_ldbc MATCH p = (v:Person{id:1})-[e1@KNOWS]-() RETURN p LIMIT 1 } LOG_INFO(a)
      """
    Then the log should contains: "@Person:Person{vec: [1.000000, 2.000000, 3.000000], locationIP: \"192.168.1\", lastName: \"cao\", firstName: \"Kyle\", id: 1, creationDate: DATETIME \"2021-01-01T10:00:40.213000\", gender: \"male\", browserUsed: \"Chrome\", birthday: DATE \"1990-01-01\"})-[0@KNOWS:KNOWS{vec: [1.000000, 2.000000, 3.000000], creationDate: DATETIME \"2021-01-01T10:00:40.213000\"}]->"

  Scenario: Logging in call procedure
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE log_in_procedure_test() RETURNS ret BOOL AS {
        LOG_INFO("This is a info log in a procedure call")
        RETURN true
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #analytic_ldbc
      CALL log_in_procedure_test()
      FINISH
      """
    Then the log should contains: "This is a info log in a procedure call"
