# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: restapi - assets

  Scenario: success
    When request the rest api "GET /" with: ""
    Then the http response should be ok
    When request the rest api "GET /" with:
      """
      {
        "headers": [
          "Accept-Encoding: gzip"
        ]
      }
      """
    Then the http response should be ok
    When request the rest api "GET /" with:
      """
      {
        "headers": [
          "Accept-Encoding: zstd"
        ]
      }
      """
    Then the http response should be ok
    When request the rest api "GET /index.html" with: ""
    Then the http response should be ok
    When request the rest api "GET /index.html" with:
      """
      {
        "headers": [
          "Accept-Encoding: gzip"
        ]
      }
      """
    Then the http response should be ok
    When request the rest api "GET /assets/index.css" with: ""
    Then the http response should be ok
    When request the rest api "GET /assets/index.css" with:
      """
      {
        "headers": [
          "Accept-Encoding: gzip"
        ]
      }
      """
    Then the http response should be ok
    When request the rest api "GET /assets/index.css" with: ""
    Then the http response should be ok
    When request the rest api "GET /assets/index.css" with:
      """
      {
        "headers": [
          "Accept-Encoding: gzip"
        ]
      }
      """
    Then the http response should be ok
    When request the rest api "GET /assets/../assets/index.css" with: ""
    Then the http response should be ok
    When request the rest api "GET /xxxx/../assets/index.css" with: ""
    Then the http response should be ok
    When request the rest api "GET /assets/xxxx/../index.css" with: ""
    Then the http response should be ok
    When request the rest api "GET /./assets/index.css" with: ""
    Then the http response should be ok
    # proxygen has handled the path to avoid the traversal attack
    When request the rest api "GET /./../assets/index.css" with: ""
    Then the http response should be ok
    When request the rest api "GET /../index.html" with: ""
    Then the http response should be ok

  Scenario: fail
    When request the rest api "GET /index.htm" with: ""
    Then an http error should be raised: "Not Found"
    When request the rest api "GET /xxx/" with: ""
    Then an http error should be raised: "Not Found"
    When request the rest api "GET /assets/xx/../assets/index.css" with: ""
    Then an http error should be raised: "Not Found"
    When request the rest api "GET /assets/" with: ""
    Then an http error should be raised: "Not Found"
