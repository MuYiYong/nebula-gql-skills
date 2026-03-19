# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Unsupported expression

  Scenario: Predicate
    When executing query:
      """
      RETURN "sss" IS NORMALIZED
      """
    Then an Error should be raised: "[NT000]: normalized predicate is not supported yet"
    When executing query:
      """
      USE ldbc
      MATCH (n:Person WHERE n.id = 35184372090183)-[e:IS_LOCATED_IN]->(p:City)
      RETURN
        e IS DIRECTED
      """
    Then an Error should be raised: "[NT000]: directed predicate is not supported yet"
    When executing query:
      """
      USE ldbc
      MATCH (n:Person WHERE n.id = 35184372090183)-[e:IS_LOCATED_IN]->(p:City)
      RETURN
        n IS SOURCE e ,
        p is DESTINATION e
      """
    Then an Error should be raised: "[NT000]: source destination predicate is not supported yet"
