# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: BindingTableFileMix

  Scenario: Import nodes from CSV file and edges from binding table
    And drop the graph type "import_mixed_file_table_gt"
    And drop the graph "#import_mixed_file_table_g"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_mixed_file_table_gt AS {
        NODE Vertex (
          LABEL Vertex {
            id INT64 PRIMARY KEY,
            name STRING
          }
        ),
        EDGE Link (Vertex)-[:Link{
          score INT,
          MULTIEDGE KEY()
        }]->(Vertex)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_mixed_file_table_g TYPED import_mixed_file_table_gt
      """
    Then the execution should be successful
    # Test 1: concurrency=1, PRIMARY_KEY_AS_NODE_ID=true
    When executing query:
      """
      /*+ set_var(query_concurrency=1) */
      USE #import_mixed_file_table_g {
        FILE node_file {id INT64, name STRING } = DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/table_scan_mini_graph_csv/table_scan_mini_graph.v"
        }

        TABLE edge_data TYPED TABLE {src_id INT64, dst_id INT64, score INT} =
          {src_id: 0, dst_id: 1, score: 1},
          {src_id: 1, dst_id: 2, score: 3},
          {src_id: 2, dst_id: 4, score: 4}

        IMPORT INTO GRAPH {
          NODE (v@Vertex{ id: id, name: name }) FROM node_file,
          EDGE (id:src_id)-[e@Link{ score: score }]->(id:dst_id) FROM edge_data
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_mixed_file_table_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 3         |
    # Verify nodes from CSV file
    When executing query:
      """
      USE #import_mixed_file_table_g {
        MATCH (v@Vertex)
        RETURN v.id, v.name
        ORDER BY v.id
      }
      """
    Then the result should be, in order:
      | v.id | v.name |
      | 0    | "aaa"  |
      | 1    | "bbb"  |
      | 2    | "ccc"  |
      | 3    | "ddd"  |
      | 4    | "eee"  |
    # Verify edges from binding table
    When executing query:
      """
      USE #import_mixed_file_table_g {
        MATCH (v1@Vertex)-[e@Link]->(v2@Vertex)
        RETURN v1.id, v2.id, e.score
        ORDER BY v1.id, v2.id
      }
      """
    Then the result should be, in order:
      | v1.id | v2.id | e.score |
      | 0     | 1     | 1       |
      | 1     | 2     | 3       |
      | 2     | 4     | 4       |
    And drop the graph "#import_mixed_file_table_g"
    # Test 2: concurrency=10, PRIMARY_KEY_AS_NODE_ID=false
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_mixed_file_table_g TYPED import_mixed_file_table_gt
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ set_var(query_concurrency=10) */
      USE #import_mixed_file_table_g {
        FILE node_file {id INT64, name STRING } = DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/table_scan_mini_graph_csv/table_scan_mini_graph.v"
        }
        TABLE edge_data TYPED TABLE {src_id INT64, dst_id INT64, score INT} =
          {src_id: 0, dst_id: 1, score: 1},
          {src_id: 1, dst_id: 3, score: 2}

        IMPORT INTO GRAPH {
          NODE (v@Vertex{ id: id, name: name }) FROM node_file,
          EDGE (id:src_id)-[e@Link{ score: score }]->(id:dst_id) FROM edge_data
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_mixed_file_table_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 2         |
    # Test 3: reverse - edges from file, nodes from table with PRIMARY_KEY_AS_NODE_ID=true
    And drop the graph "#import_mixed_file_table_g"
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_mixed_file_table_g TYPED import_mixed_file_table_gt
      """
    Then the execution should be successful
    When executing query:
      """
      /*+ set_var(query_concurrency=4) */
      USE #import_mixed_file_table_g {
        TABLE node_data TYPED TABLE {id INT64, name STRING} =
          {id: 0, name: "aaa"},
          {id: 1, name: "bbb"},
          {id: 2, name: "ccc"},
          {id: 3, name: "ddd"},
          {id: 4, name: "eee"}

        FILE edge_file {src_id INT64, dst_id INT64, score INT64 } = DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/table_scan_mini_graph_csv/table_scan_mini_graph.e"
        }

        IMPORT INTO GRAPH {
          NODE (v@Vertex{ id: id, name: name }) FROM node_data,
          EDGE (id:src_id)-[e@Link{ score: score }]->(id:dst_id) FROM edge_file
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #import_mixed_file_table_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    # Verify edges from CSV file
    When executing query:
      """
      USE #import_mixed_file_table_g {
        MATCH (v1@Vertex)-[e@Link]->(v2@Vertex)
        RETURN v1.id, v2.id, e.score
        ORDER BY e.score
      }
      """
    Then the result should be, in order:
      | v1.id | v2.id | e.score |
      | 0     | 1     | 1       |
      | 1     | 3     | 2       |
      | 1     | 2     | 3       |
      | 2     | 4     | 4       |
      | 3     | 4     | 5       |
      | 4     | 2     | 6       |
    And drop the graph "#import_mixed_file_table_g"
    And drop the graph type "import_mixed_file_table_gt"

  Scenario: Import nodes from CSV file and edges from binding table analytic
    And drop the graph type "import_mixed_file_table_analytic_gt"
    And drop the graph "#import_mixed_file_table_analytic_g"
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS import_mixed_file_table_analytic_gt AS {
        NODE Vertex (
          LABEL Vertex {
            id INT64 PRIMARY KEY,
            name STRING
          }
        ),
        EDGE Link (Vertex)-[:Link{
          score INT,
          MULTIEDGE KEY()
        }]->(Vertex)
      }
      """
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #import_mixed_file_table_analytic_g TYPED import_mixed_file_table_analytic_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    # Test 1: concurrency=1, PRIMARY_KEY_AS_NODE_ID=true
    When executing analytic query:
      """
      /*+ set_var(query_concurrency=16) */
        FILE edge_file {src_id INT64, dst_id INT64, score INT64 } = DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/table_scan_mini_graph_csv/table_scan_mini_graph.e"
        }
        TABLE node_data TYPED TABLE { id INT64, name STRING } PARTITION BY DEFAULT

        USE #analytic_ldbc {
          MATCH (v@Place)
          PER NODE (v) {
            EXPORT v.id - 1 AS id, v.name AS name INTO node_data
          }
        }

        USE #import_mixed_file_table_analytic_g
        IMPORT INTO GRAPH {
          NODE (v@Vertex{ id: id, name: name }) FROM node_data,
          EDGE (id:src_id)-[e@Link{ score: score }]->(id:dst_id) FROM edge_file
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: false }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #import_mixed_file_table_analytic_g SHOW STATS
      """
    Then the result should contain:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 6         |
      | "Edge Total" | "Edge"       | 6         |
    When executing analytic query:
      """
      USE #import_mixed_file_table_analytic_g {
      TABLE result_table TYPED TABLE {id INT, name STRING}
      MATCH (v)
      PER NODE (v) {
        EXPORT v.id AS id, v.name AS name INTO result_table
      }
      FOR r IN result_table
        RETURN r.id AS id, r.name AS name
      }
      """
    Then the result should be, in any order:
      | id | name        |
      | 5  | "Shenzhen"  |
      | 4  | "Chengdu"   |
      | 0  | "Beijing"   |
      | 3  | "Chongqing" |
      | 2  | "Hangzhou"  |
      | 1  | "Shanghai"  |
    And drop the graph "#import_mixed_file_table_analytic_g"
    And drop the graph type "import_mixed_file_table_analytic_gt"
