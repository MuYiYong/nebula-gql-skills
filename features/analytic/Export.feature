# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Analytic Export Test

  Scenario: Export to csv file in procedure
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE output_test(file_name STRING) RETURNS ret BOOL AS {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {PATH:file_name, FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
        RETURN true
      }
      """
    Then the execution should be successful
    # basic test
    When executing analytic query:
      """
      /*+SET_VAR(query_concurrency = 2) */
      USE #analytic_ldbc
      LET file_name = "file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/basic"
      CALL output_test(file_name)
      FINISH
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 8     |
      | "exported_paths"       | 6     |
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/basic" should match:
      | id                 | score |
      | 289166301065117700 | 1.0   |
      | 289293960378056708 | 1.0   |
      | 289316916978253828 | 1.0   |
      | 289107795020611588 | 1.0   |
      | 289166301065117700 | 1.0   |
      | 289293960378056708 | 1.0   |
      | 289316916978253828 | 1.0   |
      | 289107795020611588 | 1.0   |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/basic"
    When executing analytic query:
      """
      /*+ SET_VAR(exec_batch_size = 1) */ USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/normal", FORMAT:"CSV", MAX_ROWS_PER_FILE: 1}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 3.1415926
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 4     |
      | "exported_paths"       | 3     |
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/normal" should match:
      | id                 | score     |
      | 289166301065117700 | 3.1415926 |
      | 289293960378056708 | 3.1415926 |
      | 289316916978253828 | 3.1415926 |
      | 289107795020611588 | 3.1415926 |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/normal"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score INT64} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/cast", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 3.1415926
        }
        PER NODE (s1) {
            EXPORT element_id(s1), CAST(s1.@current_score AS INT64) INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/cast" should match:
      | id                 | score |
      | 289166301065117700 | 3     |
      | 289293960378056708 | 3     |
      | 289316916978253828 | 3     |
      | 289107795020611588 | 3     |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/cast"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score INT64} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/autocast", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 3.1415926
        }
        PER NODE (s1) {
            EXPORT element_id(s1), CAST(s1.@current_score AS INT32) INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/autocast" should match:
      | id                 | score |
      | 289166301065117700 | 3     |
      | 289293960378056708 | 3     |
      | 289316916978253828 | 3     |
      | 289107795020611588 | 3     |
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 4     |
      | "exported_paths"       | 3     |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/autocast"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/csv_no_score", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 3.1415926
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "[NS249]: Invalid export statement: Export file column size mismatch, definition size: 1, export size: 2"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score INT64} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/csv_type_mismatch", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 3.1415926
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "[NS208]: The type of `s1.@current_score(DOUBLE)` cannot be assigned to `File column(score:INT64)`"
    # invalid parameter
    When executing analytic query:
      """
      USE #analytic_ldbc {
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/invalid_option",
          FORMAT:"CSV",
          INVALID_OPTION:"INVALID_OPTION"
        }
        FINISH
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: Invalid option for CSV: invalid_option"
    # use quoted identifiers as file ref name
    # https://github.com/vesoft-inc/nebula-ng/issues/8224
    When executing analytic query:
      """
      USE #analytic_ldbc {
        FILE "file" {id INT64, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/invalid_option", FORMAT:"CSV"}
        FINISH
      }
      """
    Then an Error should be raised: "[42001]: syntax error near `\"file\"`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        FILE f {id INT64, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/include_header", FORMAT:"CSV", INCLUDE_HEADER:123}
        FINISH
      }
      """
    Then an Error should be raised: "[NS208]: The type of `123(INT32)` cannot be assigned to `include_header(BOOL)`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        FILE f {id INT64, score DOUBLE} = DATAFILE {FORMAT:"CSV", INCLUDE_HEADER:true}
        FINISH
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: `PATH` option is required for file definition"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        FILE f FORMAT CSV OPTIONS {INCLUDE_HEADER:true}
        FINISH
      }
      """
    Then an Error should be raised: "[42001]: syntax error near `FORMAT`"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        FILE f1 {id INT64, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/include_header", FORMAT:"CSV"}
        FILE f2 {id INT64, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/include_header", FORMAT:"CSV"}
        FINISH
      }
      """
    Then an Error should be raised: "[NS242]: Invalid variable definition: file `f2` defines duplicate path with `f1`: file:///"
    # more options
    # TODO(Aiee): Add more read options in TCK to check the result
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/csv_more_options",
          FORMAT:"CSV",
          INCLUDE_HEADER:false,
          DELIMITER:"|",
          NULL_STRING:"NULL",
          BATCH_SIZE:512,
          EOL:"\n"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/csv_more_options"
    # Without control flow
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/8250
    When executing analytic query:
      """
      FILE f  {id int, age int } = DATAFILE {path:"file:///${TCK_SERVER_DIR}/output/output_csv_file_tck/csv_without_control_flow", FORMAT:"CSV"}
      EXPORT 1 as id, 23 as age INTO f
      """
    Then the execution should be successful
    Then the "csv" output under "${TCK_SERVER_DIR}/output/output_csv_file_tck/csv_without_control_flow" should match:
      | id | age |
      | 1  | 23  |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_csv_file_tck/csv_without_control_flow"
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/8223
    # Path contains non-ASCII characters
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score INT64} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/测试中文目录/العربية/русский/日本語/한국어/français/output_csv/", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
          SET s1.@current_score += 3.1415926
        }
        PER NODE (s1) {
          EXPORT element_id(s1), CAST(s1.@current_score AS INT32) INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "csv" output under "${TCK_SERVER_DIR}/测试中文目录/العربية/русский/日本語/한국어/français/output_csv/" should match:
      | id                 | score |
      | 289166301065117700 | 3     |
      | 289293960378056708 | 3     |
      | 289316916978253828 | 3     |
      | 289107795020611588 | 3     |
    Then remove the temporary directory "${TCK_SERVER_DIR}/测试中文目录/العربية/русский/日本語/한국어/français/output_csv/"

  Scenario: Export to parquet file
    # basic test
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {PATH:"file:///${TCK_SERVER_DIR}/output/output_parquet_file_tck/case1", FORMAT:"PARQUET"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "parquet" output under "${TCK_SERVER_DIR}/output/output_parquet_file_tck/case1" should match:
      | id                 | score |
      | 289166301065117700 | 1.0   |
      | 289293960378056708 | 1.0   |
      | 289316916978253828 | 1.0   |
      | 289107795020611588 | 1.0   |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_parquet_file_tck"
    # with compression
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id2 INT64, score2 DOUBLE} = DATAFILE {
          PATH:"file:///${TCK_SERVER_DIR}/output/output_parquet_file_tck/case2",
          FORMAT:"PARQUET",
          column_properties_compression:"SNAPPY"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "parquet" output under "${TCK_SERVER_DIR}/output/output_parquet_file_tck/case2" should match:
      | id2                | score2 |
      | 289166301065117700 | 1.0    |
      | 289293960378056708 | 1.0    |
      | 289316916978253828 | 1.0    |
      | 289107795020611588 | 1.0    |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_parquet_file_tck"
    # with all available options
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id2 INT64, score2 DOUBLE} = DATAFILE {
          PATH:"file:///${TCK_SERVER_DIR}/output/output_parquet_file_tck/all_options",
          FORMAT:"PARQUET",
          max_rows_per_file: 1000000,
          dictionary_pagesize_limit: 4096,
          write_batch_size: 1024,
          max_row_group_length: 10000,
          pagesize: 8192,
          version: "PARQUET_2_6",
          data_page_version: 2,
          created_by: "nebula-test",
          store_decimal_as_integer: true,
          page_checksum_enabled: false,
          column_properties_encoding: "PLAIN",
          column_properties_compression: "GZIP",
          column_properties_dictionary_enabled: true,
          column_properties_statistics_enabled: true,
          column_properties_max_statistics_size: 2048,
          column_properties_page_index_enabled: true,
          store_schema: true,
          use_threads: false
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "parquet" output under "${TCK_SERVER_DIR}/output/output_parquet_file_tck/all_options" should match:
      | id2                | score2 |
      | 289166301065117700 | 1.0    |
      | 289293960378056708 | 1.0    |
      | 289316916978253828 | 1.0    |
      | 289107795020611588 | 1.0    |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_parquet_file_tck"

  Scenario: Export to ORC file
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id2 INT64, score2 DOUBLE} = DATAFILE {
          FORMAT:"ORC",
          PATH:"file:///${TCK_SERVER_DIR}/output/output_orc_file_tck/case1",
          COMPRESSION:"SNAPPY"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    Then the "orc" output under "${TCK_SERVER_DIR}/output/output_orc_file_tck/case1" should match:
      | id2                | score2 |
      | 289166301065117700 | 1.0    |
      | 289293960378056708 | 1.0    |
      | 289316916978253828 | 1.0    |
      | 289107795020611588 | 1.0    |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/output_orc_file_tck"

  Scenario: Export to csv file s3
    # basic test
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}&allow_bucket_creation=true",
          FORMAT:"CSV"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    # error cases
    # invalid endpoint
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH: "s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=127.0.0.1:1000&scheme=${MINIO_SCHEME}&allow_bucket_creation=true",
          FORMAT: "parquet"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "AWS Error NETWORK_CONNECTION"
    # invalid secret key
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH: "s3://${MINIO_ACCESS_KEY}:INVALID_SECRET_KEY@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}&allow_bucket_creation=true",
          FORMAT: "csv"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "AWS Error SIGNATURE_DOES_NOT_MATCH"
    # invalid https scheme
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH: "s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=https&allow_bucket_creation=true",
          FORMAT: "csv"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "SSL connect error"

  Scenario: Export to parquet file s3
    # basic test
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          FORMAT:"PARQUET",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}&allow_bucket_creation=true"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    # with compression
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          FORMAT:"PARQUET",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}&allow_bucket_creation=true",
          column_properties_compression:"SNAPPY"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 4     |
      | "exported_paths"       | 3     |
    # error cases
    # invalid endpoint
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          FORMAT:"PARQUET",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=127.0.0.1:1000&scheme=${MINIO_SCHEME}&allow_bucket_creation=true"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "AWS Error NETWORK_CONNECTION"
    # invalid secret key
    When executing analytic query:
      """
        USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH:"s3://${MINIO_ACCESS_KEY}:INVALID_SECRET_KEY@${MINIO_TEST_OUTPUT_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}&allow_bucket_creation=true",
          FORMAT:"PARQUET"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "AWS Error SIGNATURE_DOES_NOT_MATCH"

  # TODO(Aiee): Now we use anonymous as the user to skip the authentication
  Scenario: Export to csv file gcs
    # basic test
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          FORMAT:"CSV",
          PATH:"gs://anonymous@${GCS_BUCKET_NAME}/test_output?endpoint_override=${GCS_ENDPOINT}&scheme=http&retry_limit_seconds=20"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    # error cases
    # invalid endpoint
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          FORMAT:"CSV",
          PATH:"gs://anonymous@${GCS_BUCKET_NAME}/test_output?endpoint_override=127.0.0.1:1000&scheme=http&retry_limit_seconds=5"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "CURL error [7]=Couldn't connect to server"
    # invalid bucket
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          FORMAT:"CSV",
          PATH:"gs://anonymous@invalid-bucket/test_output?endpoint_override=${GCS_ENDPOINT}&scheme=http&retry_limit_seconds=5"

        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "No such file or directory"

  Scenario: Export to parquet file gcs
    # basic test
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH:"gs://anonymous@${GCS_BUCKET_NAME}/test_output?endpoint_override=${GCS_ENDPOINT}&scheme=${GCS_SCHEME}&retry_limit_seconds=30",
          FORMAT:"PARQUET"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 4     |
      | "exported_paths"       | 3     |
    # # error cases
    # # invalid endpoint
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH:"gs://anonymous@${GCS_BUCKET_NAME}/test_output?endpoint_override=127.0.0.1:1000&scheme=${GCS_SCHEME}&retry_limit_seconds=5",
          FORMAT:"PARQUET"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "CURL error [7]=Couldn't connect to server"
    # invalid bucket
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {
          PATH:"gs://anonymous@invalid-bucket/test_output?endpoint_override=${GCS_ENDPOINT}&scheme=${GCS_SCHEME}&retry_limit_seconds=5",
          FORMAT:"PARQUET"
        }
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        PER NODE (s1) {
            EXPORT element_id(s1), s1.@current_score INTO f
        }
      }
      """
    Then an Error should be raised: "No such file or directory"

  Scenario: Export to table variable
    # duplicate export items
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE result_table TYPED TABLE {person_id INT, a INT, b INT, c INT}
        MATCH (v:Person)
           PER NODE (v) {
            EXPORT v.id, v.id, 1, 1 INTO result_table
        }
        FOR r IN result_table
        RETURN r.person_id, r.a, r.b, r.c
      }
      """
    Then the result should be, in any order:
      | r.person_id | r.a | r.b | r.c |
      | 2           | 2   | 1   | 1   |
      | 3           | 3   | 1   | 1   |
      | 4           | 4   | 1   | 1   |
      | 1           | 1   | 1   | 1   |

  Scenario: Conditional output
    When executing analytic query:
      """
      USE #analytic_ldbc {
        TABLE t {id INT64}
        MATCH (s:Person)
        PER NODE (s) {
          IF s.birthday > date("2000-01-01") THEN {
            EXPORT s.id INTO t
          }
        }

        FOR r IN t
        RETURN r.id
      }
      """
    Then the result should be, in any order:
      | r.id |
      | 2    |
    When executing analytic query:
      """
      USE #analytic_ldbc {
        FILE f {id INT64} = DATAFILE {
          FORMAT:"CSV",
          PATH:"file:///${TCK_SERVER_DIR}/output/conditional_output/case1"
        }
        MATCH (s:Person)
        PER NODE (s) {
          IF s.birthday > date("2000-01-01") THEN {
            EXPORT s.id INTO f
          }
        }
      }
      """
    Then the execution should be successful
    And the query stats should be, in any order:
      | name                   | value |
      | "num_affected_nodes"   | 0     |
      | "num_affected_edges"   | 0     |
      | "num_exported_records" | 1     |
      | "exported_paths"       | 3     |
    Then the "csv" output under "${TCK_SERVER_DIR}/output/conditional_output/case1" should match:
      | id |
      | 2  |
    Then remove the temporary directory "${TCK_SERVER_DIR}/output/conditional_output/case1"

  Scenario: Export return nothing
    When executing query:
      """
      USE ldbc {
      TABLE t TYPED TABLE { id INT, random_rate DOUBLE }
      MATCH (v)
      EXPORT v.id, rand() INTO t
      NEXT
      LET c = 1
      RETURN *
      }
      """
    Then the result should be, in any order:
      | c |
      | 1 |

  Scenario: All supported data types export analytic
    And drop the graph "#all_supported_data_types_dist_g"
    And drop the graph "all_supported_data_types_dist_g"
    And drop the graph type "all_supported_data_types_dist_gt"
    And create a new session with username "root" and password "NebulaGraph01"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/all_supported_data_types_dist"
    # The temporal data types uses current session timezone to export
    When executing analytic query:
      """
      /*+ set_var(enable_analyticd_service_mode=true) */
      SESSION SET timezone = "Asia/Shanghai"
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS all_supported_data_types_dist_gt AS {
        NODE person (LABEL person {
          id INT PRIMARY KEY,
          _string STRING,
          _uint8 UINT8,
          _float FLOAT,
          _decimal DECIMAL(10,2),
          _boolean BOOLEAN,
          _date DATE,
          _time LOCAL TIME,
          _zoned_time ZONED TIME,
          _local_datetime LOCAL DATETIME,
          _zoned_datetime ZONED DATETIME,
          _vector VECTOR<3,FLOAT>,
          _geo GEOGRAPHY,
          _list LIST<STRING>,
          _set SET<STRING>,
          _map MAP<INT, INT>
        })
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ set_var(enable_analyticd_service_mode=true) */
      CREATE GRAPH IF NOT EXISTS all_supported_data_types_dist_g all_supported_data_types_dist_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE all_supported_data_types_dist_g
      INSERT (p1@person{id:3,_string:"string",_uint8:18, _float: 3.4f, _decimal:1088.88m, _boolean:true,
               _date:date("2021-01-01"),
               _time:local_time("10:00:40.213"),
               _zoned_time:zoned_time("10:00:40.213 +0800"),
               _local_datetime:LOCAL_DATETIME("2021-01-01T10:00:40.213"),
               _zoned_datetime:zoned_datetime("2021-01-01T10:00:40.213 +0800"),
               _vector:vector<3,float>([1,2,3]),
               _geo:ST_GeogFromText('POINT(1 1)'),
               _list:["1","2"],
               _set:SET{"string"},
               _map:MAP{1:1}})
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ set_var(enable_analyticd_service_mode=true) */
      FILE f1  {id int,
        _string string,
        _uint8 uint8,
        _float float,
        _decimal decimal(10,2),
        _boolean boolean,
        _date date,
        _time local time,
        _zoned_time zoned time,
        _local_datetime local datetime,
        _zoned_datetime zoned datetime,
        _vector vector<3,float>,
        _geo geography,
        _list list<string>,
        _set set<string>,
        _map map<int, int>}
      = DATAFILE {PATH:'file://${TEST_DIR}/dataset/temp_test_files/all_supported_data_types_dist/',  FORMAT:'CSV'}
      USE all_supported_data_types_dist_g MATCH (v@person) EXPORT
        v.id,
        v._string,
        v._uint8,
        v._float,
        v._decimal,
        v._boolean,
        v._date,
        v._time,
        v._zoned_time,
        v._local_datetime,
        v._zoned_datetime,
        v._vector,
        v._geo,
        v._list,
        v._set,
        v._map
      INTO f1
      """
    Then the execution should be successful
    Then the "csv" output under "${TEST_DIR}/dataset/temp_test_files/all_supported_data_types_dist" should match:
      | v.id | v._string | v._uint8 | v._float | v._decimal | v._boolean | v._date      | v._time           | v._zoned_time           | v._local_datetime            | v._zoned_datetime                  | v._vector                        | v._geo       | v._list         | v._set         | v._map  |
      | 3    | "string"  | 18       | 3.4      | 1088.88    | true       | "2021-01-01" | "10:00:40.213000" | "10:00:40.213000 +0800" | "2021-01-01T10:00:40.213000" | "2021-01-01T10:00:40.213000 +0800" | "[1.000000, 2.000000, 3.000000]" | "POINT(1 1)" | "[\"1\",\"2\"]" | "{\"string\"}" | "{1:1}" |
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/all_supported_data_types_dist"
    And drop the graph "#all_supported_data_types_dist_g"
    And drop the graph "all_supported_data_types_dist_g"
    And drop the graph type "all_supported_data_types_dist_gt"
    And close the current session

  # https://github.com/vesoft-inc/nebula-ng/issues/9481
  Scenario: Variable scope
    When executing analytic query:
      """
      use #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_test_files/variable_scope_test", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        MATCH (s1:Person)
        PER NODE (s1) {
          IF s1.id > 0 THEN {
            EXPORT s1.id, s1.@current_score INTO f
          }
          ELSE {
            SET s1.@current_score += 1
          }
        }
      }
      """
    Then the execution should be successful
    Then the "csv" output under "${TEST_DIR}/dataset/temp_test_files/variable_scope_test" should match:
      | id | score |
      | 1  | 1     |
      | 2  | 1     |
      | 3  | 1     |
      | 4  | 1     |
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/variable_scope_test"
    When executing analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE current_score SumAgg<DOUBLE> = 0.0
        FILE f {id INT64, score DOUBLE} = DATAFILE {PATH:"file://${TEST_DIR}/dataset/temp_test_files/variable_scope_test_1", FORMAT:"CSV"}
        MATCH (s1:Person)
        PER NODE (s1) {
            SET s1.@current_score += 1.0
        }
        MATCH (s1:Person)
        PER NODE (s1) {
          IF s1.id > 2 THEN {
            EXPORT s1.id, s1.@current_score INTO f
          }
          ELSE {
            EXPORT s1.id, s1.@current_score + 1 INTO f
          }
        }
      }
      """
    Then the execution should be successful
    Then the "csv" output under "${TEST_DIR}/dataset/temp_test_files/variable_scope_test_1" should match:
      | id | score |
      | 1  | 2     |
      | 2  | 2     |
      | 3  | 1     |
      | 4  | 1     |
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/variable_scope_test_1"
