# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: restapi - Management

  Scenario: kill query
    And create a http client with username "root" and password "NebulaGraph01"
    When request the rest api "DELETE /sessions/current/query" with: ""
    Then the http response should contain:
      """
      {
        "code": "00000"
      }
      """
    And close the http client
