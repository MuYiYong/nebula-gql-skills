# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Temporary graph primary key related case

  Scenario: Import temp graph with primary key conflict, PRIMARY_KEY_AS_NODE_ID set true
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS int_pk_conflict_gt AS {
      NODE TYPE player (LABEL player {id INT PRIMARY KEY, name STRING}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #int_pk_conflict TYPED int_pk_conflict_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #int_pk_conflict_distributed TYPED int_pk_conflict_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/edge.csv"
      }
      USE #int_pk_conflict IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      }
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation for node"
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/edge.csv"
      }
      USE #int_pk_conflict IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      } OPTIONS {SKIP_CONFLICT_PK_NODES:true}
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #int_pk_conflict SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 2         |
      | "Edge Total" | "Edge"       | 1         |
      | "player"     | "Node"       | 2         |
      | "follow"     | "Edge"       | 1         |
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/edge.csv"
      }
      USE #int_pk_conflict_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      }
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation for node"
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_id INT, dst_id INT, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/edge.csv"
      }
      USE #int_pk_conflict_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (id:ef.src_id)-[e@follow{score: ef.score}]->(id:ef.dst_id) FROM ef
      } OPTIONS {SKIP_CONFLICT_PK_NODES:true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #int_pk_conflict_distributed SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 2         |
      | "Edge Total" | "Edge"       | 1         |
    And drop the graph "#int_pk_conflict"
    And drop the graph "#int_pk_conflict_distributed"
    And drop the graph type "int_pk_conflict_gt"

  Scenario: Import temp graph with primary key conflict, PRIMARY_KEY_AS_NODE_ID set false
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS str_pk_conflict_gt AS {
      NODE TYPE player (LABEL player {id INT, name STRING PRIMARY KEY}),
      EDGE TYPE follow (player)-[LABEL follow {score INT, MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #str_pk_conflict TYPED str_pk_conflict_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #str_pk_conflict_distributed TYPED str_pk_conflict_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/str_pk_edge.csv"
      }
      USE #str_pk_conflict IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation for node"
    When executing graph query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/str_pk_edge.csv"
      }
      USE #str_pk_conflict IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {SKIP_CONFLICT_PK_NODES:true}
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #str_pk_conflict SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 2         |
      | "Edge Total" | "Edge"       | 1         |
      | "player"     | "Node"       | 2         |
      | "follow"     | "Edge"       | 1         |
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/str_pk_edge.csv"
      }
      USE #str_pk_conflict_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then an Error should be raised: "[NR205]: Insert node failed, primary key constraint violation for node"
    When executing analytic query:
      """
      FILE nf {id INT, name STRING} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/node.csv"
      }
      FILE ef {src_name STRING, dst_name STRING, score INT} = DATAFILE {
          FORMAT: "csv",
          PATH:"file://${TEST_DIR}/dataset/external_source/pk_conflict/str_pk_edge.csv"
      }
      USE #str_pk_conflict_distributed IMPORT INTO GRAPH
      {
        NODE (v@player{id:nf.id, name:nf.name}) FROM nf,
        EDGE (name:ef.src_name)-[e@follow{score: ef.score}]->(name:ef.dst_name) FROM ef
      } OPTIONS {SKIP_CONFLICT_PK_NODES:true}
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #str_pk_conflict_distributed SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 2         |
      | "Edge Total" | "Edge"       | 1         |
    And drop the graph "#str_pk_conflict"
    And drop the graph "#str_pk_conflict_distributed"
    And drop the graph type "str_pk_conflict_gt"

  Scenario: Import temp graph from nebula, skip conflict primary key nodes not supported
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS a_pk_conflict_gt AS {
        NODE Person (label Person {id INT PRIMARY KEY , age INT, name STRING }),
        EDGE know (Person)-[:know{MULTIEDGE key()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH a_pk_conflict TYPED a_pk_conflict_gt
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE a_pk_conflict INSERT
      (a@Person{id:1,age:1,name:"A"}),
      (b@Person{id:2,age:1,name:"C"}),
      (c@Person{id:3,age:3,name:"E"}),
      (a)-[e0@know]->(b),
      (a)-[e1@know]->(c),
      (b)-[e2@know]->(c)
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH #tmp_a_pk_conflict TYPED a_pk_conflict_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #tmp_a_pk_conflict IMPORT INTO GRAPH {
        NODE (v@Person{id:id, age:age}) FROM NEBULA {
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=a_pk_conflict&node_type=Person&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      } OPTIONS {SKIP_CONFLICT_PK_NODES:true}
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: SKIP_CONFLICT_PK_NODES is not supported when importing from Nebula"
    And drop the graph "#tmp_a_pk_conflict"
    And drop the graph "a_pk_conflict"
    And drop the graph type "a_pk_conflict_gt"

  Scenario: Import temp graph with null int primary key
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE test_null_int_pk_node AS {NODE person ({id int32, age int, score int not null, primary key(id)})}
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH #test_null_int_pk_node TYPED test_null_int_pk_node
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH #test_null_int_pk_node TYPED test_null_int_pk_node PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #test_null_int_pk_node IMPORT INTO GRAPH {
        NODE (v@person{id:id,age:age,score:score})
        FROM DATAFILE {
          PATH:"file://${TEST_DIR}/dataset/external_source/null_pk/nodes.csv",
          FORMAT:'CSV'
        }
      }
      """
    Then an Error should be raised: "[NP401]: Connector error: Failed to convert node type: person, error: Property `id` of type `person` is not nullable"
    When executing analytic query:
      """
      USE #test_null_int_pk_node IMPORT INTO GRAPH {
        NODE (v@person{id:id,age:age,score:score})
        FROM DATAFILE {
          PATH:"file://${TEST_DIR}/dataset/external_source/null_pk/nodes.csv",
          FORMAT:'CSV'
        }
      }
      """
    Then an Error should be raised: "[NP401]: Connector error: Failed to convert node type: person, error: Property `id` of type `person` is not nullable"
    And drop the graph "#test_null_int_pk_node"
    And drop the graph type "test_null_int_pk_node"

  Scenario: Import temp graph with null primary key in edge
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE test_null_int_pk_edge AS {
        NODE person ({id int32, age int, score int not null, primary key(id)}),
        EDGE follow (person)-[LABEL follow {MULTIEDGE KEY()}]->(person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH #test_null_int_pk_edge TYPED test_null_int_pk_edge
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH #test_null_int_pk_edge TYPED test_null_int_pk_edge PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #test_null_int_pk_edge IMPORT INTO GRAPH {
        NODE (v@person{id:id,age:age,score:score})
        FROM DATAFILE {
          PATH:"file://${TEST_DIR}/dataset/external_source/null_pk/valid_nodes.csv",
          FORMAT:'CSV'
        },

        EDGE (id:src)-[e@follow{}]->(id:dst)
        FROM DATAFILE {
          PATH:"file://${TEST_DIR}/dataset/external_source/null_pk/edges.csv",
          FORMAT:'CSV'
        }
      }
      """
    Then an Error should be raised: "[NP401]: Connector error: Failed to convert edge type: follow, error: Property `id` of type `person` is not nullable"
    When executing analytic query:
      """
      USE #test_null_int_pk_edge IMPORT INTO GRAPH {
        NODE (v@person{id:id,age:age,score:score})
        FROM DATAFILE {
          PATH:"file://${TEST_DIR}/dataset/external_source/null_pk/nodes.csv",
          FORMAT:'CSV'
        }
      }
      """
    Then an Error should be raised: "[NP401]: Connector error: Failed to convert node type: person, error: Property `id` of type `person` is not nullable"
    And drop the graph "#test_null_int_pk_edge"
    And drop the graph type "test_null_int_pk_edge"

  Scenario: Import temp graph with null composite primary key
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE test_composite_pk AS {NODE person ({id int, age int, score int not null, primary key(id,age)})}
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH #test_composite_pk TYPED test_composite_pk
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH #test_composite_pk TYPED test_composite_pk PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #test_composite_pk IMPORT INTO GRAPH {
        NODE (v@person{id:id,age:age,score:score})
        FROM DATAFILE {
          PATH:"file://${TEST_DIR}/dataset/external_source/null_pk/nodes.csv",
          FORMAT:'CSV'
        }
      }
      """
    Then an Error should be raised: "[NP401]: Connector error: Failed to convert node/edge type: person, error: Property `id` of type `person` is not nullable"
    When executing analytic query:
      """
      USE #test_composite_pk IMPORT INTO GRAPH {
        NODE (v@person{id:id,age:age,score:score})
        FROM DATAFILE {
          PATH:"file://${TEST_DIR}/dataset/external_source/null_pk/nodes.csv",
          FORMAT:'CSV'
        }
      }
      """
    Then an Error should be raised: "[NP401]: Connector error: Failed to convert node/edge type: person, error: Property `id` of type `person` is not nullable"
    And drop the graph "#test_composite_pk"
    And drop the graph type "test_composite_pk"
