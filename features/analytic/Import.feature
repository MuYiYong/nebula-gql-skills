# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Analytic import Test

  Scenario: Import temporal values from csv file
    And drop the graph type "temporal_graph_type"
    And drop the graph "#temporal_graph"
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS temporal_graph_type AS {
        NODE temporal_node (
          LABEL temporal_node {
            id INT PRIMARY KEY,
            date_col DATE,
            local_time_col LOCAL TIME,
            zoned_time_col ZONED TIME,
            local_datetime_col LOCAL DATETIME,
            zoned_datetime_col ZONED DATETIME
          }
        ),
        EDGE temporal_edge (temporal_node)-[:temporal_edge
        {
          date_col DATE,
          local_time_col LOCAL TIME,
          zoned_time_col ZONED TIME,
          local_datetime_col LOCAL DATETIME,
          zoned_datetime_col ZONED DATETIME,
          MULTIEDGE KEY()
        }]->(temporal_node)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #temporal_graph TYPED temporal_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #temporal_graph IMPORT INTO GRAPH
      {
        NODE (v@temporal_node{
              id:id,
              date_col:date_col,
              local_time_col:local_time_col,
              zoned_time_col:zoned_time_col,
              local_datetime_col:local_datetime_col,
              zoned_datetime_col:zoned_datetime_col
            }) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_temporal_csv/mini_temporal_csv.v"
        },
        EDGE (id:src_id)-[e@temporal_edge{
              date_col:date_col,
              local_time_col:local_time_col,
              zoned_time_col:zoned_time_col,
              local_datetime_col:local_datetime_col,
              zoned_datetime_col:zoned_datetime_col
            }]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_temporal_csv/mini_temporal_csv.e"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #temporal_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 2         |
    # check the data
    When executing analytic query:
      """
      USE #temporal_graph {
        TABLE t {id INT, date_col DATE, local_time_col LOCAL TIME, zoned_time_col ZONED TIME, local_datetime_col LOCAL DATETIME, zoned_datetime_col ZONED DATETIME}
        MATCH (v@temporal_node) PER NODE (v){  export v.id, v.date_col, v.local_time_col, v.zoned_time_col, v.local_datetime_col, v.zoned_datetime_col into t }
        FOR r in t RETURN r.id, r.date_col, r.local_time_col, r.zoned_time_col, r.local_datetime_col, r.zoned_datetime_col
      }
      """
    Then the result should be, in any order:
      | r.id | r.date_col        | r.local_time_col       | r.zoned_time_col             | r.local_datetime_col                  | r.zoned_datetime_col                        |
      | 0    | DATE "1990-01-01" | TIME "01:02:03.000000" | ZONED TIME "01:02:03.000000" | DATETIME "1990-01-01T01:02:03.000000" | ZONED DATETIME "1990-01-01T01:02:03.000000" |
      | 4    | DATE "2010-01-10" | TIME "04:05:06.000000" | ZONED TIME "07:35:06.000000" | DATETIME "2010-01-10T04:05:06.000000" | ZONED DATETIME "2010-01-10T07:35:06.000000" |
      | 1    | DATE "2020-02-29" | TIME "23:59:59.000000" | ZONED TIME "07:59:59.000000" | DATETIME "2020-02-29T23:59:59.000000" | ZONED DATETIME "2020-03-01T07:59:59.000000" |
      | 2    | DATE "1970-01-01" | TIME "00:00:00.000000" | ZONED TIME "18:30:00.000000" | DATETIME "1970-01-01T00:00:00.000000" | ZONED DATETIME "1969-12-31T18:30:00.000000" |
      | 3    | DATE "2024-12-31" | TIME "12:34:56.000000" | ZONED TIME "00:34:56.000000" | DATETIME "2024-12-31T12:34:56.000000" | ZONED DATETIME "2024-12-31T00:34:56.000000" |
    When executing analytic query:
      """
      USE #temporal_graph {
        TABLE t {date_col DATE, local_time_col LOCAL TIME, zoned_time_col ZONED TIME, local_datetime_col LOCAL DATETIME, zoned_datetime_col ZONED DATETIME}
        MATCH (v1)-[e:temporal_edge]->(v2)
        PER PATH {
          EXPORT e.date_col,e.local_time_col,e.zoned_time_col,e.local_datetime_col,e.zoned_datetime_col into t
        }
        FOR r in t RETURN r.date_col, r.local_time_col, r.zoned_time_col, r.local_datetime_col, r.zoned_datetime_col
      }
      """
    Then the result should be, in any order:
      | r.date_col        | r.local_time_col       | r.zoned_time_col             | r.local_datetime_col                  | r.zoned_datetime_col                        |
      | DATE "1990-01-01" | TIME "01:02:03.000000" | ZONED TIME "01:02:03.000000" | DATETIME "1990-01-01T01:02:03.000000" | ZONED DATETIME "1990-01-01T01:02:03.000000" |
      | DATE "2020-02-29" | TIME "23:59:59.000000" | ZONED TIME "07:59:59.000000" | DATETIME "2020-02-29T23:59:59.000000" | ZONED DATETIME "2020-03-01T07:59:59.000000" |
    And drop the graph "#temporal_graph"
    And drop the graph type "temporal_graph_type"

  # Fix https://github.com/vesoft-inc/nebula-ng/issues/9302
  # Fix https://github.com/vesoft-inc/nebula-ng/issues/9303
  Scenario: Mixed string, int, zoned time types and null values in analytic import
    And drop the graph "#a_test_import_string_int_mixed_dist_g"
    And drop the graph type "a_test_import_string_int_mixed_dist_gt"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes_dist.csv"
    When executing analytic query:
      """
      FILE f1 {id INT64, _string STRING, _zoned_time STRING} = DATAFILE {
        FORMAT: "csv",
        PATH: "file://${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes_dist.csv"
      }
      BINDING TABLE table_v TYPED TABLE {id INT64, _string STRING, _zoned_time STRING} =
        {id: 1, _string: null, _zoned_time: null},
        {id: 2, _string: "10", _zoned_time: "11:11:11Z"},
        {id: 3, _string: "10.0", _zoned_time: "12:12:12Z"}
      FOR t IN table_v
      EXPORT t.id AS id, t._string AS _string, t._zoned_time AS _zoned_time INTO f1
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS a_test_import_string_int_mixed_dist_gt AS {
        NODE TYPE Person (LABEL Person {
              id INT64 PRIMARY KEY,
              _string STRING,
              _zoned_time ZONED TIME
            }
          )
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #a_test_import_string_int_mixed_dist_g TYPED a_test_import_string_int_mixed_dist_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #a_test_import_string_int_mixed_dist_g IMPORT INTO GRAPH {
        NODE (v@Person{id: id, _string: _string, _zoned_time: _zoned_time}) FROM DATAFILE {
          PATH: "file://${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes_dist.csv",
          FORMAT: "CSV"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #a_test_import_string_int_mixed_dist_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 3         |
      | "Edge Total" | "Edge"       | 0         |
    And drop the graph "#a_test_import_string_int_mixed_dist_g"
    And drop the graph type "a_test_import_string_int_mixed_dist_gt"
    Then remove the temporary directory "${TEST_DIR}/dataset/temp_test_files/temp_string_int_mixed_nodes_dist.csv"
