# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Distributed Graph Projection - Advanced

  Scenario: Load nodes and edges from different data sources
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_type_mixed AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow {score INT,MULTIEDGE KEY()}]->(player)
      }
      """
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_mixed_s3_gcs TYPED dist_graph_type_mixed
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_mixed_s3_gcs TYPED dist_graph_type_mixed PARTITION BY DEFAULT
      """
    Then the execution should be successful
    # Load from s3 and gcs
    When executing graph analytic query:
      """
      USE #dist_graph_csv_mixed_s3_gcs IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_DATASET_DIR_PATH}minigraph.v?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}"
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
    When executing analytic query:
      """
      USE #dist_graph_csv_mixed_s3_gcs SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    When executing query:
      """
      USE #dist_graph_csv_mixed_s3_gcs SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
      | "player"     | "Node"       | 5         |
      | "follow"     | "Edge"       | 6         |
    And drop the graph "#dist_graph_csv_mixed_s3_gcs"
    # Load from s3 and local file
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_mixed_s3_local TYPED dist_graph_type_mixed
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_mixed_s3_local TYPED dist_graph_type_mixed PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_mixed_s3_local IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"s3://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_TEST_DATASET_DIR_PATH}minigraph.v?endpoint_override=${MINIO_ENDPOINT}&scheme=${MINIO_SCHEME}"
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e",
          delimiter: ",",
          include_columns: ["src_id","dst_id","score"]
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_graph_csv_mixed_s3_local SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    When executing query:
      """
      USE #dist_graph_csv_mixed_s3_local SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
      | "player"     | "Node"       | 5         |
      | "follow"     | "Edge"       | 6         |
    And drop the graph "#dist_graph_csv_mixed_s3_local"
    And drop the graph type "dist_graph_type_mixed"

  @non_tls
  # Reading nodes and edges from nebula and non-nebula would cause dangling edges,
  # because the node ids from file sources are re-encoded. We disable this feature for now.
  Scenario: Load data from multiple data sources
    # load 1 node from nebula and 1 node from local file
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS multiple_ldbc_type_gt AS {
        NODE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING}),
        NODE Person (LABEL Person {id INT PRIMARY KEY, firstName STRING, lastName STRING, gender STRING, birthday DATE, creationDate LOCAL DATETIME, locationIP STRING, browserUsed STRING, vec VECTOR<3,float>}),
        EDGE IS_PART_OF (Place)-[:IS_PART_OF {MULTIEDGE KEY()}]->(Place)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_multi_data_sources TYPED multiple_ldbc_type_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_multi_data_sources IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id, firstName:firstName}) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        NODE (v@Place{id:id, name:name, url:url, kind:kind}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_ldbc_graph/mini_ldbc_graph.v"
        }
      }
      """
    Then an Error should be raised: "Mixed nebula and file(non-nebula file system) source is not allowed"
    # load 1 node from nebula and 1 edge from local file
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_multi_data_sources TYPED multiple_ldbc_type_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_multi_data_sources IMPORT INTO GRAPH
      {
        NODE (v@Place{id:id, name:name, url:url, kind:kind}) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Place"
        },
        EDGE (id:src)-[e@IS_PART_OF{}]->(id:dst) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_ldbc_graph/mini_ldbc_graph.e"
        }
      }
      """
    Then an Error should be raised: "Mixed nebula and file(non-nebula file system) source is not allowed"
    # hdfs
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #hdfs_not_configured TYPED multiple_ldbc_type_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #hdfs_not_configured IMPORT INTO GRAPH
      {
        NODE (v@Place{id:id, name:name, url:url, kind:kind}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"hdfs://mini_ldbc_graph.e"
        },
        EDGE (id:src)-[e@IS_PART_OF{}]->(id:dst) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"hdfs://mini_ldbc_graph.e"
        }
      }
      """
    Then an Error should be raised: "[NP004]: Plugin `hdfs`, parse configuration error: `JAVA_HOME is not set`"
    And drop the graph "#dist_cross_group_graph_multi_data_sources"
    And drop the graph "#hdfs_not_configured"

  Scenario: Load distributed temporary graph with undirected edge
    # issue https://github.com/vesoft-inc/nebula-ng/issues/8001
    # graph type contains undirected edge
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_type_undirected AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow_undirected (player)~[LABEL follow_undirected {score INT,MULTIEDGE KEY()}]~(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_undirected TYPED dist_graph_type_undirected
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_undirected TYPED dist_graph_type_undirected PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_undirected IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.v",
          delimiter: " "
        },
        EDGE (id:src_id)~[e@follow_undirected{score: score}]~(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_space/mini_graph_csv_space.e",
          delimiter: " "
        }
      }
      """
    Then the execution should be successful
    And drop the graph "#dist_graph_csv_undirected"
    And drop the graph type "dist_graph_type_undirected"
