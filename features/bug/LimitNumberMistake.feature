# Copyright (c) 2023 vesoft inc. All rights reserved.
Feature: Mismached result number of limit

  # #1723
  @sf01
  Scenario: Mismatched result number of limit
    When executing query:
      """
      USE sf01
      MATCH (person:Person {id: 15393162790207})<-[:KNOWS]->(friend:Person)<-[:HAS_CREATOR]-(message:Message)
      LIMIT 20
      RETURN COUNT(*) AS c GROUP BY ()
      """
    Then the result should be, in order:
      | c  |
      | 20 |
