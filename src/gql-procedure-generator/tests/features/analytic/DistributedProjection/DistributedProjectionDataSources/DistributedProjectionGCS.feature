# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Distributed Graph Projection - GCS Storage

  Scenario: Load graph from gcs
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_type_gcs AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow {score INT,MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_gcs TYPED dist_graph_type_gcs
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_gcs TYPED dist_graph_type_gcs PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_gcs IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"gs://anonymous@${GCS_BUCKET_NAME}/dataset/minigraph.v?endpoint_override=${GCS_ENDPOINT}&scheme=http&retry_limit_seconds=20",
          delimiter: ",",
          include_columns: ["id","name"]
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"gs://anonymous@${GCS_BUCKET_NAME}/dataset/minigraph.e?endpoint_override=${GCS_ENDPOINT}&scheme=http&retry_limit_seconds=20",
          delimiter: ",",
          include_columns: ["src_id","dst_id","score"]
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_gcs SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    # invalid uri
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_gcs_invalid_uri TYPED dist_graph_type_gcs
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_gcs_invalid_uri TYPED dist_graph_type_gcs PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_gcs_invalid_uri IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"gs://anonymous@${GCS_BUCKET_NAME}/invalid/minigraph.v?endpoint_override=${GCS_ENDPOINT}&scheme=http&retry_limit_seconds=5"
        }
      }
      """
    Then an Error should be raised: "[AN000]: Analytic error: File not found for path:/invalid/minigraph.v"
    And drop the graph "#dist_graph_csv_gcs_invalid_uri"
    And drop the graph "#dist_graph_csv_gcs"
    And drop the graph type "dist_graph_type_gcs"
