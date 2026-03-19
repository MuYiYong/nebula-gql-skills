# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Submit

  Scenario: negative
    # issue https://github.com/vesoft-inc/nebula-ng/issues/9363
    When executing analytic query:
      """
      CREATE TEMP GRAPH IF NOT EXISTS #sf01_from_error TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      SUBMIT USE #sf01_from_error IMPORT INTO GRAPH
      {
      NODE(v@Person{id:id}) from nebula{
      FORMAT:"nebula",
      PATH:"s3://aaa:bbb@test-qa/test_data/csv/data_node.csv?endpoint_override=minio.vesoft-inc.com"
      }
      }
      """
    Then the execution should get submitted
    And wait "1" seconds
    And the procedure status should be:
      | procedure_id | status   | error                                     |
      | /.+/         | "FAILED" | /\[08N01\]: Failed to parse Nebula URI.+/ |
