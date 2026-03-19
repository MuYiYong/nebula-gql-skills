# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: crash cases

  # https://github.com/vesoft-inc/nebula-ng-tools/pull/976
  Scenario: empty query string
    When executing raw query:
      """
      """
    Then an Error should be raised: "[42001]: syntax error near ``, at N/A"
