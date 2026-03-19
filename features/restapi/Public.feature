# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: restapi - public

  Scenario: Metrics
    When request the rest api "GET /metrics" with: ""
    Then the http response should be ok
    When request the rest api "GET /metrics?format=prometheus" with: ""
    Then the http response should be ok
    When request the rest api "GET /metrics?format=prometheus&filter=graphd_query_latency_summary_5s" with: ""
    Then the http response should be ok

  Scenario: Info
    When request the rest api "GET /info" with: ""
    Then the http response should contain:
      """
      {
        "vendor": "VEsoft Inc.",
        "version": "5.0",
        "supportedProtocolVersions": [
          "5.0.0"
        ]
      }
      """

  Scenario: HealthCheck
    When request the rest api "GET /health" with: ""
    Then the http response should contain:
      """
      {
        "status": "UP"
      }
      """
