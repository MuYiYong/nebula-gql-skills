# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Distributed Graph Projection - Data Types

  Scenario: Auto Cast
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_graph_type_autocast AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE follow (player)-[LABEL follow{score DOUBLE,score2 DOUBLE DEFAULT 1.11,creationDate ZONED DATETIME DEFAULT CURRENT_TIMESTAMP,MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_autocast TYPED dist_graph_type_autocast
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_csv_autocast TYPED dist_graph_type_autocast PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_autocast IMPORT INTO GRAPH
      {
        NODE (v@player{id:id, name:name}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.v"
        },
        EDGE (id:src_id)-[e@follow{score: score}]->(id:dst_id) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/mini_graph_csv_comma/mini_graph_csv_comma.e"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_graph_csv_autocast {
        TABLE result_table TYPED TABLE {sid INT64, score DOUBLE, score2 DOUBLE, creationDate STRING, tid INT64}
        MATCH (s)-[e]->(t)
        PER PATH  {
          EXPORT s.id, e.score, e.score2, CAST(e.creationDate AS STRING), t.id INTO result_table
        }

        FOR i IN result_table
        RETURN i.sid, i.score, i.score2, i.creationDate, i.tid
      }
      """
    Then the result should be, in any order:
      | i.sid | i.score | i.score2 | i.creationDate | i.tid |
      | 0     | 1.0     | 1.11     | /.+/           | 1     |
      | 4     | 6.0     | 1.11     | /.+/           | 2     |
      | 1     | 2.0     | 1.11     | /.+/           | 3     |
      | 1     | 3.0     | 1.11     | /.+/           | 2     |
      | 2     | 4.0     | 1.11     | /.+/           | 4     |
      | 3     | 5.0     | 1.11     | /.+/           | 4     |
    And drop the graph "#dist_graph_csv_autocast"
    And drop the graph type "dist_graph_type_autocast"

  Scenario: Invalid data type
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS invalid_data_type AS {
        NODE TYPE user (LABEL user {id STRING PRIMARY KEY})
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #invalid_data TYPED invalid_data_type
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #invalid_data TYPED invalid_data_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #invalid_data IMPORT INTO GRAPH
      {
        NODE (v@user{id:id}) FROM DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/invalid_node_csv/invalid_node_csv.v"
        }
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      """
    Then an Error should be raised: "[NP401]: Connector error: Failed to convert node type: user, error: Connector error: Column 'id' with type 'string' cannot be used as primary key. Primary key must be integer type when option PRIMARY_KEY_AS_NODE_ID is enabled"
    And drop the graph "#invalid_data"
    And drop the graph type "invalid_data_type"
