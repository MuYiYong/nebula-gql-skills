# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Distributed Graph Projection - S3 Storage

  Scenario: Load graph from s3
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_type_s3 AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_s3 TYPED dist_graph_type_s3
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_s3 TYPED dist_graph_type_s3 PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_s3 IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_DATASET_DIR_PATH}minigraph.v?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}",
          delimiter: ",",
          include_columns: ["id","name"],
          block_size: 16777216
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_DATASET_DIR_PATH}minigraph.e?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_s3 SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    # Invalid uri
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_s3_invalid_uri TYPED dist_graph_type_s3
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_s3_invalid_uri TYPED dist_graph_type_s3 PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_s3_invalid_uri IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_OUTPUT_DIR_PATH}invalid/minigraph.v?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}"
        }
      }
      """
    Then an Error should be raised: "[AN000]: Analytic error: File not found for path:/ci_test/dir1/dir2/invalid/minigraph.v"
    And drop the graph "#dist_graph_csv_s3_invalid_uri"
    And drop the graph "#dist_graph_csv_s3"
    And drop the graph type "dist_graph_type_s3"

  Scenario: Load csv from s3 directory
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_csv_s3_dir_gt {
        NODE TYPE node_type ({id INT PRIMARY KEY, score DOUBLE}),
        EDGE TYPE edge_type (node_type)-[{MULTIEDGE KEY()}]->(node_type)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_s3_dir TYPED dist_graph_csv_s3_dir_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_s3_dir TYPED dist_graph_csv_s3_dir_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_s3_dir IMPORT INTO GRAPH
      {
        NODE (v@node_type{id:f0, score:f1}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_NODE_DATA_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}",
          autogenerate_column_names: true,
          delimiter: " "
        },
          EDGE (id:f0)-[e@edge_type{}]->(id:f1) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_EDGE_DATA_DIR_PATH}?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}",
          autogenerate_column_names: true,
          delimiter: " "
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_graph_csv_s3_dir SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 12        |
      | "Edge Total" | "Edge"       | 14        |
    When executing query:
      """
      USE #dist_graph_csv_s3_dir SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 12        |
      | "Edge Total" | "Edge"       | 14        |
      | "node_type"  | "Node"       | 12        |
      | "edge_type"  | "Edge"       | 14        |
    And drop the graph "#dist_graph_csv_s3_dir"
    And drop the graph type "dist_graph_csv_s3_dir_gt"
