# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Import temporary graph dangling edge

  Scenario: Import temp graph of dangling edge, PRIMARY_KEY_AS_NODE_ID set true
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS int_dangling_edge_gt AS {
      NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #int_dangling_edge TYPED int_dangling_edge_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #int_dangling_edge_distributed TYPED int_dangling_edge_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/edge.csv"
      }
      USE #int_dangling_edge IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true, SKIP_DANGLING_EDGES:false}
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/edge.csv"
      }
      USE #int_dangling_edge IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true, SKIP_DANGLING_EDGES:true}
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #int_dangling_edge SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
      | "player"     | "Node"       | 5         |
      | "follow"     | "Edge"       | 6         |
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/edge.csv"
      }
      USE #int_dangling_edge_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true, SKIP_DANGLING_EDGES:false}
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/edge.csv"
      }
      USE #int_dangling_edge_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true, SKIP_DANGLING_EDGES:true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #int_dangling_edge_distributed SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    And drop the graph "#int_dangling_edge"
    And drop the graph "#int_dangling_edge_distributed"
    And drop the graph type "int_dangling_edge_gt"

  Scenario: Import temp graph of dangling edge, PRIMARY_KEY_AS_NODE_ID set false
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS str_dangling_edge_gt AS {
      NODE TYPE player (LABEL player {id INT, name STRING PRIMARY KEY}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #str_dangling_edge TYPED str_dangling_edge_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #str_dangling_edge_distributed TYPED str_dangling_edge_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/str_pk_edge.csv"
      }
      USE #str_dangling_edge IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false, SKIP_DANGLING_EDGES:false}
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/str_pk_edge.csv"
      }
      USE #str_dangling_edge IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false, SKIP_DANGLING_EDGES:true}
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #str_dangling_edge SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
      | "player"     | "Node"       | 5         |
      | "follow"     | "Edge"       | 6         |
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/str_pk_edge.csv"
      }
      USE #str_dangling_edge_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false, SKIP_DANGLING_EDGES:false}
      """
    Then an Error should be raised: "[NR124]: Failed to build temporary graph: There're dangling edges"
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/dangling_edge/str_pk_edge.csv"
      }
      USE #str_dangling_edge_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false, SKIP_DANGLING_EDGES:true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #str_dangling_edge_distributed SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 5         |
      | "Edge Total" | "Edge"       | 6         |
    And drop the graph "#str_dangling_edge"
    And drop the graph "#str_dangling_edge_distributed"
    And drop the graph type "str_dangling_edge_gt"

  # It is difficult to generate a graph with dangling edges directly from Nebula,
  # so here we only verify that the query can be executed successfully.
  @non_tls
  Scenario: SKIP_DANGLING_EDGES for nebula source
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #skip_dangling_edges_mutable TYPED ldbc_type
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #skip_dangling_edges_mutable
      IMPORT INTO GRAPH {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      OPTIONS {SKIP_DANGLING_EDGES:true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #skip_dangling_edges_analytic TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #skip_dangling_edges_analytic
      IMPORT INTO GRAPH {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      OPTIONS {SKIP_DANGLING_EDGES:true}
      """
    Then the execution should be successful
    And drop the graph "#skip_dangling_edges_mutable"
    And drop the graph "#skip_dangling_edges_analytic"
