# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Distributed Graph Projection - Nebula Service

  Scenario: Load from remote nebula service group special characters in password
    # The password contains character '?','#'
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #nebula_uri_password_test TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #nebula_uri_password_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:Nebula#Graph01::?#?@123456@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    # The error should not be parsing error, but authentication error
    Then an Error should be raised: "invalid username or password"
    When executing analytic query:
      """
      USE #nebula_uri_password_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:Nebula#!@#$%^&*():=?@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    # The error should not be parsing error, but authentication error
    Then an Error should be raised: "invalid username or password"
    And drop the graph "#nebula_uri_password_test"

  @non_tls
  Scenario: Load data from remote nebula service group distributed
    # load whole graph
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      """
    Then the execution should be successful
    # Check the node data
    When executing analytic query:
      """
      USE #dist_cross_group_graph {
        TABLE t {id INT, firstName STRING}
        MATCH (v@Person) PER NODE (v){  export v.id, v.firstName into t }
        FOR r in t RETURN r.id, r.firstName
      }
      """
    Then the result should be, in any order:
      | r.id | r.firstName |
      | 2    | "Tim"       |
      | 3    | "Ming"      |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
    When executing analytic query:
      """
      USE #dist_cross_group_graph SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 34        |
      | "Edge Total" | "Edge"       | 74        |
    # data from remote group does not match the local graph type
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS mismatch_graph_type AS {
        NODE TYPE player (LABEL player {id INT PRIMARY KEY}),
        EDGE TYPE follow (player)-[LABEL follow {MULTIEDGE KEY()}]->(player)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_multiple_mismatch_type TYPED mismatch_graph_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_multiple_mismatch_type IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Node type count mismatch: remote=8, local=1"
    And drop the graph "#dist_cross_group_graph_multiple_mismatch_type"
    And drop the graph "#dist_cross_group_graph"
    And drop the graph type "mismatch_graph_type"
    # Using TLS parameters connect to a non-TLS graph server
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_tls TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_tls IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then an Error should be raised: "Tls handshake failed: SSL_ERROR_SSL"
    And drop the graph "#dist_cross_group_graph_tls"
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/9033
    When executing analytic query:
      """
      USE #dist_cross_group_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=中文graph"
        }
      }
      """
    Then an Error should be raised: "Graph `中文graph` not found in schema `/default_schema`"
    # Error: Use the analytic service address as the URI
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_analytic_service TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_analytic_service IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_ANALYTIC_ADDRESS}?graph=ldbc"
        }
      }
      """
    Then an Error should be raised: "Graph `ldbc` not found in schema `/default_schema`"
    And drop the graph "#dist_cross_group_graph_analytic_service"
    And drop the graph "#dist_cross_group_graph"
    # ERROR non-exist property in remote type
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_invalid_property TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_invalid_property IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id, firstName:firstName}) FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        NODE (v@Tag{id:id, name:firstName}) FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Comment"
        }
      }
      """
    Then an Error should be raised: "Property `firstName` of type `Comment` not found"
    And drop the graph "#dist_cross_group_graph_invalid_property"

  @non_tls
  Scenario: Load data from remote nebula service with specified schema name
    And drop the graph "#nebula_connector_schema_temp_graph"
    # Prepare schema in the remote nebula service
    And create a new session with username "root" and password "NebulaGraph01"
    When executing query:
      """
      CREATE SCHEMA IF NOT EXISTS /test/nebula_connector
      """
    Then the execution should be successful
    When executing query:
      """
      SESSION SET SCHEMA /test/nebula_connector
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS nebula_connector_schema_gt AS {
        NODE Place (LABELS City&Country&Continent {id INT PRIMARY KEY, name STRING, url STRING, kind STRING}),
        EDGE IS_PART_OF (Place)-[:IS_PART_OF{MULTIEDGE KEY()}]->(Place)
       }
      """
    Then the execution should be successful
    And graph type "nebula_connector_schema_gt" should be ready to use
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_nebula_connector_schema_graph TYPED nebula_connector_schema_gt
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, name, url, kind} =
        {id:1, name:"Beijing", url:"https://beijing.com", kind:"city"},
        {id:2, name:"Shanghai", url:"https://shanghai.com", kind:"city"},
        {id:3, name:"Hangzhou", url:"https://hangzhou.com", kind:"city"},
        {id:4, name:"Chongqing", url:"https://chongqing.com", kind:"city"},
        {id:5, name:"Chengdu", url:"https://chengdu.com", kind:"city"},
        {id:6, name:"Shenzhen", url:"https://shenzhen.com", kind:"city"}
        USE remote_nebula_connector_schema_graph
        FOR r IN t
        INSERT OR REPLACE (@Place{id:r.id,name:r.name,url:r.url,kind:r.kind})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst} =
        (1,4),
        (2,5),
        (3,6)
      USE remote_nebula_connector_schema_graph
      FOR r IN t
        MATCH (a@Place) WHERE a.id = r.src
        MATCH (b@Place) WHERE b.id = r.dst
        INSERT OR REPLACE (a)-[@IS_PART_OF{}]->(b)
      """
    Then the execution should be successful
    # Load data from remote nebula service with specified schema name
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #nebula_connector_schema_temp_graph TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #nebula_connector_schema_temp_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_nebula_connector_schema_graph&schema=/test/nebula_connector"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Node type count mismatch: remote=1, local=8"
    And drop the graph "remote_nebula_connector_schema_graph"
    And drop the graph type "nebula_connector_schema_gt"
    When executing query:
      """
      DROP SCHEMA IF EXISTS /test/nebula_connector
      """
    Then the execution should be successful
    And close the current session

  @non_tls
  Scenario: Load data from remote nebula service group contains null prop
    And drop the graph "#dist_cross_group_graph_null_prop"
    And drop the graph "cross_group_graph_null_prop"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS cross_group_graph_null_prop TYPED ldbc_type
      """
    Then the execution should be successful
    And graph "cross_group_graph_null_prop" should be ready to use
    When executing query:
      """
      TABLE t {id, firstName, lastName, gender, birthday, creationDate, locationIP, browserUsed} =
        {id:100, firstName:"Nullia", lastName:NULL, gender:"female", birthday:date("1990-01-01", "%Y-%m-%d"), creationDate:local_datetime("2024-01-01T10:00:00", "%Y-%m-%dT%H:%M:%S"), locationIP:"10.0.0.1", browserUsed:NULL},
        {id:101, firstName:"Nullon", lastName:"Doe", gender:NULL, birthday:date("1992-02-02", "%Y-%m-%d"), creationDate:local_datetime("2024-01-02T10:00:00", "%Y-%m-%dT%H:%M:%S"), locationIP:"10.0.0.2", browserUsed:"Safari"}
      USE cross_group_graph_null_prop
      FOR r IN t
      INSERT OR REPLACE (@Person{id:r.id, firstName:r.firstName, lastName:r.lastName, gender:r.gender, birthday:r.birthday, creationDate:r.creationDate, locationIP:r.locationIP, browserUsed:r.browserUsed, vec:NULL})
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_null_prop TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_null_prop IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=cross_group_graph_null_prop"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_null_prop {
        TABLE t {id INT, lastName STRING, browserUsed STRING}
        MATCH (v@Person) WHERE v.id IN [100, 101]
        PER NODE (v) {
          EXPORT v.id, v.lastName, v.browserUsed INTO t
        }
        FOR r IN t RETURN r.id, r.lastName, r.browserUsed
      }
      """
    Then the result should be, in any order:
      | r.id | r.lastName | r.browserUsed |
      | 100  | NULL       | NULL          |
      | 101  | "Doe"      | "Safari"      |
    # Test PROPERTY_NOT_NULLABLE error when loading NULL into non-nullable property
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS cross_group_graph_non_nullable_gt AS {
        NODE TYPE Person (LABEL Person {
          id INT PRIMARY KEY,
          firstName STRING,
          lastName STRING NOT NULL
        })
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_non_nullable TYPED cross_group_graph_non_nullable_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_non_nullable IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id, firstName:firstName, lastName:lastName}) FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=cross_group_graph_null_prop&node_type=Person"
        }
      }
      """
    Then an Error should be raised: "[ND008]: Property `lastName` of type `Person` is not nullable"
    And drop the graph "cross_group_graph_non_nullable"
    And drop the graph "#dist_cross_group_graph_non_nullable"
    And drop the graph type "cross_group_graph_non_nullable_gt"
    And drop the graph "cross_group_graph_null_prop"
    And drop the graph "#dist_cross_group_graph_null_prop"

  @non_tls
  Scenario: Load data from remote nebula service with string primary key
    # The remote graph use STRING as primary key
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS cross_group_graph_string_pk_gt AS {
        NODE node_type_1 (label person{id INT NOT NULL,name string PRIMARY KEY}),
        EDGE edge_type_1 (node_type_1)-[label follow{followness INT,MULTIEDGE KEY()}]->(node_type_1)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS cross_group_graph_string_pk TYPED cross_group_graph_string_pk_gt
      """
    Then the execution should be successful
    And graph "cross_group_graph_string_pk" should be ready to use
    # Insert nodes
    When executing query:
      """
      TABLE t {id, name} =
        (1, "name_1"),
        (2, "name_2"),
        (3, "name_3")
      USE cross_group_graph_string_pk
      FOR r IN t
      INSERT OR REPLACE (@node_type_1{id:r.id, name:r.name})
      """
    Then the execution should be successful
    # Insert edges
    When executing query:
      """
      TABLE t {src,dst,followness} =
        (1,1,10),
        (2,2,20),
        (3,3,30)
      USE cross_group_graph_string_pk
        FOR r IN t
      MATCH (a@node_type_1{id:r.src})
      MATCH (b@node_type_1{id:r.dst})
      INSERT OR REPLACE (a)-[@edge_type_1{followness:r.followness}]->(b)
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_cross_group_graph_string_pk_gt {
        NODE TYPE node_type_1 ({id INT NOT NULL, name STRING PRIMARY KEY}),
        EDGE TYPE edge_type_1 (node_type_1)-[LABEL edge_type_1 {followness INT, MULTIEDGE KEY()}]->(node_type_1)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_string_pk TYPED dist_cross_group_graph_string_pk_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_string_pk IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=cross_group_graph_string_pk"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_string_pk SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 3         |
      | "Edge Total" | "Edge"       | 3         |
    # Use mapping
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_string_pk_with_mapping TYPED dist_cross_group_graph_string_pk_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_string_pk_with_mapping IMPORT INTO GRAPH
      {
        NODE (v@node_type_1{id:id, name:name}) FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=cross_group_graph_string_pk&node_type=node_type_1"
        },
        EDGE (name:name)-[e@edge_type_1{followness:followness}]->(name:name) FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=cross_group_graph_string_pk&edge_type=edge_type_1"
        }
      }
      """
    Then the execution should be successful
    And drop the graph "cross_group_graph_string_pk"
    And drop the graph "#dist_cross_group_graph_string_pk"
    And drop the graph "#dist_cross_group_graph_string_pk_with_mapping"
    And drop the graph type "dist_cross_group_graph_string_pk_gt"
    And drop the graph type "cross_group_graph_string_pk_gt"

  @non_tls
  Scenario: Load data from remote nebula service group distributed with mapping
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dist_cross_group_graph_with_mapping_gt {
        NODE TYPE n_Person ({id INT PRIMARY KEY, firstName STRING}),
        NODE TYPE n_Comment ({id INT PRIMARY KEY, postDate LOCAL DATETIME}),
        NODE TYPE n_POST ({id INT PRIMARY KEY, contentString STRING}),
        EDGE TYPE e_KNOWS (n_Person)-[LABEL e_KNOWS {startDate LOCAL DATETIME,MULTIEDGE KEY()}]->(n_Person),
        EDGE TYPE e_REPLY_OF (n_Comment)-[LABEL e_REPLY_OF {MULTIEDGE KEY()}]->(n_POST),
        EDGE TYPE e_LIKES (n_Person)-[LABEL e_LIKES {likeDate LOCAL DATETIME,MULTIEDGE KEY()}]->(n_POST)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_with_mapping TYPED dist_cross_group_graph_with_mapping_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_with_mapping IMPORT INTO GRAPH
      {
        NODE (v@n_Person{id:id, firstName:firstName}) FROM NEBULA {
          FORMAT:"csv",
          PATH: "nebula://root:NebulaGraph01@127.0.0.1:12704?graph=ldbc&node_type=Person"
        }
      }
      """
    Then an Error should be raised: "[NI000]: Invalid parameter: The 'FORMAT' parameter must be 'NEBULA' for From Nebula Source, but got 'CSV'"
    When executing analytic query:
      """
      USE #dist_cross_group_graph_with_mapping IMPORT INTO GRAPH
      {
        NODE (v@n_Person{id:id, firstName:firstName}) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        NODE (v@n_Comment{id:id, postDate:creationDate}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Comment"
        },
        NODE (v@n_POST{id:id, contentString:content}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Post"
        },
        EDGE (id:id)-[e@e_KNOWS{startDate:creationDate}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&edge_type=KNOWS"
        },
        EDGE (id:id)-[e@e_REPLY_OF{}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&edge_type=REPLY_OF_1"
        },
        EDGE (id:id)-[e@e_LIKES{likeDate:creationDate}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&edge_type=LIKES_1"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_with_mapping SHOW STATS
      """
    # Manually checked
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 12        |
      | "Edge Total" | "Edge"       | 9         |
    # Check the node data
    When executing analytic query:
      """
      USE #dist_cross_group_graph_with_mapping {
        TABLE t {id INT, firstName STRING}
        MATCH (v@n_Person) PER NODE (v){  export v.id, v.firstName into t }
        FOR r in t RETURN r.id, r.firstName
      }
      """
    Then the result should be, in any order:
      | r.id | r.firstName |
      | 2    | "Tim"       |
      | 3    | "Ming"      |
      | 4    | "Sophie"    |
      | 1    | "Kyle"      |
    # Check the edge data
    When executing analytic query:
      """
      USE #dist_cross_group_graph_with_mapping {
        TABLE t {creationDate STRING, src INT, dst INT}
        MATCH (v1)-[e:e_KNOWS]->(v2)
        PER PATH  {
          EXPORT  CAST(e.startDate AS STRING), v1.id, v2.id INTO t
        }
        FOR r in t RETURN r.src,r.creationDate, r.dst
      }
      """
    Then the result should be, in any order:
      | r.src | r.creationDate               | r.dst |
      | 2     | "2021-01-01T10:00:40.213000" | 2     |
      | 3     | "2021-01-01T10:00:40.213000" | 3     |
      | 1     | "2021-01-01T10:00:40.213000" | 1     |
    # Error: Import when mapping LOCAL DATETIME prop to a Integer temp graph prop
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/8982
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_import_prop_cast_gt {
        NODE TYPE n_Person ({id INT PRIMARY KEY, firstName STRING}),
        EDGE TYPE e_KNOWS (n_Person)-[LABEL e_KNOWS {int_prop INT,MULTIEDGE KEY()}]->(n_Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_import_prop_cast TYPED test_import_prop_cast_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_import_prop_cast IMPORT INTO GRAPH
      {
        NODE (v@n_Person{id:id, firstName:firstName}) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        EDGE (id:src)-[e@e_KNOWS{int_prop:creationDate}]->(id:dst) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&edge_type=KNOWS"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Type mismatch for mapping 'int_prop' <- 'creationDate' of edge 'e_KNOWS' : local type INT64 vs input type LOCALDATETIME"
    # Try to cast remote int prop to a local int prop
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_import_prop_cast_gt2 {
        NODE TYPE n_Person ({id INT PRIMARY KEY, int_8_prop INT8}),
        EDGE TYPE e_KNOWS (n_Person)-[LABEL e_KNOWS {int_prop INT, MULTIEDGE KEY()}]->(n_Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_import_prop_cast2 TYPED test_import_prop_cast_gt2 PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_import_prop_cast2 IMPORT INTO GRAPH
      {
        NODE (v@n_Person{id:id, int_8_prop:extent}) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Comment"
        },
        EDGE (id:src)-[e@e_KNOWS{int_prop:creationDate}]->(id:dst) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&edge_type=KNOWS"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: Type mismatch for mapping 'int_prop' <- 'creationDate' of edge 'e_KNOWS' : local type INT64 vs input type LOCALDATETIME"
    # Error: Try to export LOCAL DATETIME prop to a Integer table column
    When executing analytic query:
      """
      USE #dist_cross_group_graph_with_mapping {
        TABLE t {creationDate INT, src INT, dst INT}
        MATCH (v1)-[e:e_KNOWS]->(v2)
        PER PATH  {
          EXPORT  e.startDate, v1.id, v2.id INTO t
        }
        FOR r in t RETURN r.src,r.creationDate, r.dst
      }
      """
    Then an Error should be raised: "Type mismatch in table column 0 (0-indexed), column type: INT64 vs input type: LOCALDATETIME"
    And drop the graph "#test_import_prop_cast"
    And drop the graph "#test_import_prop_cast2"
    And drop the graph "#dist_cross_group_graph_with_mapping"
    And drop the graph type "dist_cross_group_graph_with_mapping_gt"
    And drop the graph type "test_import_prop_cast_gt"
    And drop the graph type "test_import_prop_cast_gt2"

  @sf01
  # Used for tuning with large LDBC dataset
  Scenario: Load data from remote nebula service group distributed test
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS sf_type AS {
        NODE City (LABELS City&Place {id INT64 PRIMARY KEY, name STRING, url STRING}),
        NODE Country (LABELS Country&Place {id INT64 PRIMARY KEY, name STRING, url STRING}),
        NODE Continent (LABELS Continent&Place {id INT64 PRIMARY KEY, name STRING, url STRING}),
        NODE University (LABELS University&Organisation {id INT64 PRIMARY KEY, name STRING, url STRING}),
        NODE Company (LABELS Company&Organisation {id INT64 PRIMARY KEY, name STRING, url STRING}),
        NODE Person (LABEL Person {id INT64 PRIMARY KEY, firstName STRING, lastName STRING, gender STRING, birthday DATE, creationDate LOCAL DATETIME, locationIP STRING, browserUsed STRING, email STRING, speaks STRING }),
        NODE Forum (LABEL Forum {id INT64 PRIMARY KEY, title STRING, creationDate LOCAL DATETIME}),
        NODE Post (LABELS Post&Message {id INT64 PRIMARY KEY, imageFile STRING, creationDate LOCAL DATETIME, locationIP STRING, browserUsed STRING, language STRING, content STRING, extent INT}),
        NODE Comment (LABELS Comment&Message {id INT64 PRIMARY KEY, creationDate LOCAL DATETIME, locationIP STRING, browserUsed STRING, content STRING, extent INT}),
        NODE Tag (LABEL Tag {id INT64 PRIMARY KEY, name STRING, url STRING}),
        NODE TagClass (LABEL TagClass {id INT64 PRIMARY KEY, name STRING, url STRING}),
        EDGE CITY_IS_PART_OF_COUNTRY (City)-[:IS_PART_OF]->(Country),
        EDGE COUNTRY_IS_PART_OF_CONTINENT (Country)-[:IS_PART_OF]->(Continent),
        EDGE UNIVERSITY_IS_LOCATED_IN_CITY (University)-[:IS_LOCATED_IN]->(City),
        EDGE COMPANY_IS_LOCATED_IN_COUNTRY (Company)-[:IS_LOCATED_IN]->(Country),
        EDGE PERSON_IS_LOCATED_IN_CITY (Person)-[:IS_LOCATED_IN]->(City),
        EDGE PERSON_STUDY_AT_UNIVERSITY (Person)-[:STUDY_AT{classYear INT32}]->(University),
        EDGE PERSON_WORK_AT_COMPANY (Person)-[:WORK_AT{workFrom INT32}]->(Company),
        EDGE PERSON_LIKES_POST (Person)-[:LIKES{creationDate LOCAL DATETIME}]->(Post),
        EDGE PERSON_LIKES_COMMENT (Person)-[:LIKES{creationDate LOCAL DATETIME}]->(Comment),
        EDGE PERSON_HAS_INTEREST_TAG (Person)-[:HAS_INTEREST]->(Tag),
        EDGE PERSON_KNOWS_PERSON (Person)-[:KNOWS{creationDate LOCAL DATETIME}]->(Person),
        EDGE POST_IS_LOCATED_IN_COUNTRY (Post)-[:IS_LOCATED_IN]->(Country),
        EDGE POST_HAS_CREATOR_PERSON (Post)-[:HAS_CREATOR]->(Person),
        EDGE POST_HAS_TAG_TAG (Post)-[:HAS_TAG]->(Tag),
        EDGE COMMENT_IS_LOCATED_IN_COUNTRY (Comment)-[:IS_LOCATED_IN]->(Country),
        EDGE COMMENT_HAS_CREATOR_PERSON (Comment)-[:HAS_CREATOR]->(Person),
        EDGE COMMENT_HAS_TAG_TAG (Comment)-[:HAS_TAG]->(Tag),
        EDGE COMMENT_REPLY_OF_POST (Comment)-[:REPLY_OF]->(Post),
        EDGE COMMENT_REPLY_OF_COMMENT (Comment)-[:REPLY_OF]->(Comment),
        EDGE FORUM_CONTAINER_OF_POST (Forum)-[:CONTAINER_OF]->(Post),
        EDGE FORUM_HAS_MEMBER_PERSON (Forum)-[:HAS_MEMBER{joinDate LOCAL DATETIME}]->(Person),
        EDGE FORUM_HAS_MODERATOR_PERSON (Forum)-[:HAS_MODERATOR]->(Person),
        EDGE FORUM_HAS_TAG_TAG (Forum)-[:HAS_TAG]->(Tag),
        EDGE TAG_HAS_TYPE_TAGCLASS (Tag)-[:HAS_TYPE]->(TagClass),
        EDGE TAGCLASS_IS_SUBCLASS_OF_TAGCLASS (TagClass)-[:IS_SUBCLASS_OF]->(TagClass)
        }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #sf_cross_group_graph TYPED sf_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+SET_VAR(query_concurrency = 2) */
      USE #sf_cross_group_graph IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=sf01"
        }
      }
      """
    Then the execution should be successful
    And drop the graph "#sf_cross_group_graph"
    And drop the graph type "sf_type"

  @tls
  Scenario: Load data from remote nebula service group distributed with tls
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_tls TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_tls IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_tls SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 34        |
      | "Edge Total" | "Edge"       | 74        |
    And drop the graph "#dist_cross_group_graph_tls"
    # With peer name verification
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_tls TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_tls IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    And drop the graph "#dist_cross_group_graph_tls"
    # Error: wrong peer name
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_tls TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_tls IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.invalid.server.com"
        }
      }
      """
    Then an Error should be raised: "UNAUTHENTICATED: Hostname Verification Check failed."
    And drop the graph "#dist_cross_group_graph_tls"
    # Error: Missing required parameters: tls_key
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_1 TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_1 IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then an Error should be raised: "Missing required tls_key parameter when TLS is enabled"
    And drop the graph "#dist_cross_group_graph_1"
    # Error: Invalid CA certificate
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_tls TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_tls IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=true&tls_ca=${TCK_GRAPH_TLS_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}"
        }
      }
      """
    Then an Error should be raised: "ls handshake failed: SSL_ERROR_SSL: error:1416F086:SSL routines:tls_process_server_certificate:certificate verify failed"
    And drop the graph "#dist_cross_group_graph_tls"

  @non_tls
  Scenario: Edge type topology consistency check
    # Test topology consistency with node type name mappings:
    # Remote: User, Article, Label, Company
    # Local:  Person, Post, Tag, Org
    # Edges: AUTHORED(User->Article), TAGGED(Article->Label), WORKS_AT(User->Company), FOLLOWS(User->User)
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS remote_complex_topology_gt AS {
        NODE TYPE User ({id INT PRIMARY KEY, username STRING}),
        NODE TYPE Article ({id INT PRIMARY KEY, title STRING}),
        NODE TYPE Label ({id INT PRIMARY KEY, name STRING}),
        NODE TYPE Company ({id INT PRIMARY KEY, companyName STRING}),
        EDGE TYPE AUTHORED (User)-[LABEL AUTHORED {publishedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(Article),
        EDGE TYPE TAGGED (Article)-[LABEL TAGGED {MULTIEDGE KEY()}]->(Label),
        EDGE TYPE WORKS_AT (User)-[LABEL WORKS_AT {since DATE, MULTIEDGE KEY()}]->(Company),
        EDGE TYPE FOLLOWS (User)-[LABEL FOLLOWS {followedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(User)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_complex_topology_graph TYPED remote_complex_topology_gt
      """
    Then the execution should be successful
    And graph "remote_complex_topology_graph" should be ready to use
    When executing query:
      """
      TABLE t {id, username} =
        (1, "alice"),
        (2, "bob"),
        (3, "charlie")
      USE remote_complex_topology_graph
      FOR r IN t
      INSERT OR REPLACE (@User{id:r.id, username:r.username})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, title} =
        (101, "Graph Databases"),
        (102, "Distributed Systems")
      USE remote_complex_topology_graph
      FOR r IN t
      INSERT OR REPLACE (@Article{id:r.id, title:r.title})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, name} =
        (201, "database"),
        (202, "distributed")
      USE remote_complex_topology_graph
      FOR r IN t
      INSERT OR REPLACE (@Label{id:r.id, name:r.name})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {id, companyName} =
        (301, "TechCorp"),
        (302, "DataInc")
      USE remote_complex_topology_graph
      FOR r IN t
      INSERT OR REPLACE (@Company{id:r.id, companyName:r.companyName})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst,publishedAt} =
        (1,101,local_datetime("2024-01-01T10:00:00", "%Y-%m-%dT%H:%M:%S")),
        (2,102,local_datetime("2024-01-02T10:00:00", "%Y-%m-%dT%H:%M:%S"))
      USE remote_complex_topology_graph
      FOR r IN t
      MATCH (a@User{id:r.src})
      MATCH (b@Article{id:r.dst})
      INSERT OR REPLACE (a)-[@AUTHORED{publishedAt:r.publishedAt}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst} =
        (101,201),
        (102,202)
      USE remote_complex_topology_graph
      FOR r IN t
      MATCH (a@Article{id:r.src})
      MATCH (b@Label{id:r.dst})
      INSERT OR REPLACE (a)-[@TAGGED{}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst,since} =
        (1,301,date("2023-01-01", "%Y-%m-%d")),
        (2,302,date("2023-02-01", "%Y-%m-%d"))
      USE remote_complex_topology_graph
      FOR r IN t
      MATCH (a@User{id:r.src})
      MATCH (b@Company{id:r.dst})
      INSERT OR REPLACE (a)-[@WORKS_AT{since:r.since}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst,followedAt} =
        (1,2,local_datetime("2024-01-01T10:00:00", "%Y-%m-%dT%H:%M:%S")),
        (2,3,local_datetime("2024-01-02T10:00:00", "%Y-%m-%dT%H:%M:%S"))
      USE remote_complex_topology_graph
      FOR r IN t
      MATCH (a@User{id:r.src})
      MATCH (b@User{id:r.dst})
      INSERT OR REPLACE (a)-[@FOLLOWS{followedAt:r.followedAt}]->(b)
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_complex_mismatch_gt {
        NODE TYPE Person ({id INT PRIMARY KEY, username STRING}),
        NODE TYPE Post ({id INT PRIMARY KEY, title STRING}),
        NODE TYPE Tag ({id INT PRIMARY KEY, name STRING}),
        NODE TYPE Org ({id INT PRIMARY KEY, companyName STRING}),
        EDGE TYPE AUTHORED (Person)-[LABEL AUTHORED {publishedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(Post),
        EDGE TYPE TAGGED (Post)-[LABEL TAGGED {MULTIEDGE KEY()}]->(Tag),
        EDGE TYPE WORKS_AT (Person)-[LABEL WORKS_AT {since DATE, MULTIEDGE KEY()}]->(Org),
        EDGE TYPE FOLLOWS (Person)-[LABEL FOLLOWS {followedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #complex_topology_mismatch TYPED local_complex_mismatch_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    # This should succeed - TAGGED topology actually matches (Article->Label == Post->Tag)
    When executing analytic query:
      """
      USE #complex_topology_mismatch IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id, username:username}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=User"
        },
        NODE (v@Post{id:id, title:title}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Article"
        },
        NODE (v@Tag{id:id, name:name}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Label"
        },
        NODE (v@Org{id:id, companyName:companyName}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Company"
        },
        EDGE (id:id)-[e@AUTHORED{publishedAt:publishedAt}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=AUTHORED"
        },
        EDGE (id:id)-[e@TAGGED{}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=TAGGED"
        },
        EDGE (id:id)-[e@WORKS_AT{since:since}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=WORKS_AT"
        },
        EDGE (id:id)-[e@FOLLOWS{followedAt:followedAt}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=FOLLOWS"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #complex_topology_mismatch SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 9         |
      | "Edge Total" | "Edge"       | 8         |
    And drop the graph "#complex_topology_mismatch"
    And drop the graph type "local_complex_mismatch_gt"
    # Test Case 2: Source node mismatch - AUTHORED edge (Remote: User→Article, Local: Org→Post ✗)
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_complex_wrong_topology_gt {
        NODE TYPE Person ({id INT PRIMARY KEY, username STRING}),
        NODE TYPE Post ({id INT PRIMARY KEY, title STRING}),
        NODE TYPE Tag ({id INT PRIMARY KEY, name STRING}),
        NODE TYPE Org ({id INT PRIMARY KEY, companyName STRING}),
        EDGE TYPE AUTHORED (Org)-[LABEL AUTHORED {publishedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(Post),
        EDGE TYPE TAGGED (Post)-[LABEL TAGGED {MULTIEDGE KEY()}]->(Tag),
        EDGE TYPE WORKS_AT (Person)-[LABEL WORKS_AT {since DATE, MULTIEDGE KEY()}]->(Org),
        EDGE TYPE FOLLOWS (Person)-[LABEL FOLLOWS {followedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #complex_wrong_topology TYPED local_complex_wrong_topology_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #complex_wrong_topology IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id, username:username}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=User"
        },
        NODE (v@Post{id:id, title:title}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Article"
        },
        NODE (v@Tag{id:id, name:name}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Label"
        },
        NODE (v@Org{id:id, companyName:companyName}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Company"
        },
        EDGE (id:id)-[e@AUTHORED{publishedAt:publishedAt}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=AUTHORED"
        },
        EDGE (id:id)-[e@TAGGED{}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=TAGGED"
        },
        EDGE (id:id)-[e@WORKS_AT{since:since}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=WORKS_AT"
        },
        EDGE (id:id)-[e@FOLLOWS{followedAt:followedAt}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=FOLLOWS"
        }
      }
      """
    Then an Error should be raised: "Edge type topology mismatch for `AUTHORED`: remote (User)-[AUTHORED]->(Article) source node `User` maps to `Person`, but local (Org)-[AUTHORED]->(Post) expects `Org`"
    And drop the graph "#complex_wrong_topology"
    And drop the graph type "local_complex_wrong_topology_gt"
    # Test Case 3: Destination node mismatch - FOLLOWS edge (Remote: User→User, Local: Person→Org ✗)
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_self_ref_wrong_gt {
        NODE TYPE Person ({id INT PRIMARY KEY, username STRING}),
        NODE TYPE Post ({id INT PRIMARY KEY, title STRING}),
        NODE TYPE Tag ({id INT PRIMARY KEY, name STRING}),
        NODE TYPE Org ({id INT PRIMARY KEY, companyName STRING}),
        EDGE TYPE AUTHORED (Person)-[LABEL AUTHORED {publishedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(Post),
        EDGE TYPE TAGGED (Post)-[LABEL TAGGED {MULTIEDGE KEY()}]->(Tag),
        EDGE TYPE WORKS_AT (Person)-[LABEL WORKS_AT {since DATE, MULTIEDGE KEY()}]->(Org),
        EDGE TYPE FOLLOWS (Person)-[LABEL FOLLOWS {followedAt LOCAL DATETIME, MULTIEDGE KEY()}]->(Org)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #self_ref_wrong TYPED local_self_ref_wrong_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #self_ref_wrong IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id, username:username}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=User"
        },
        NODE (v@Post{id:id, title:title}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Article"
        },
        NODE (v@Tag{id:id, name:name}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Label"
        },
        NODE (v@Org{id:id, companyName:companyName}) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&node_type=Company"
        },
        EDGE (id:id)-[e@AUTHORED{publishedAt:publishedAt}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=AUTHORED"
        },
        EDGE (id:id)-[e@TAGGED{}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=TAGGED"
        },
        EDGE (id:id)-[e@WORKS_AT{since:since}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=WORKS_AT"
        },
        EDGE (id:id)-[e@FOLLOWS{followedAt:followedAt}]->(id:id) FROM NEBULA {
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_complex_topology_graph&edge_type=FOLLOWS"
        }
      }
      """
    Then an Error should be raised: "Edge type topology mismatch for `FOLLOWS`: remote (User)-[FOLLOWS]->(User) destination node `User` maps to `Person`, but local (Person)-[FOLLOWS]->(Org) expects `Org`"
    And drop the graph "#self_ref_wrong"
    And drop the graph type "local_self_ref_wrong_gt"
    And drop the graph "remote_complex_topology_graph"
    And drop the graph type "remote_complex_topology_gt"

  @non_tls
  Scenario: Primary key mapping validation
    # Prepare remote graph with composite primary keys
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS remote_pk_mapping_gt AS {
        NODE TYPE NProduct ({productId INT, regionId INT, name STRING, price DOUBLE, PRIMARY KEY(productId, regionId)}),
        NODE TYPE Customer ({customerId INT, email STRING, PRIMARY KEY(customerId)})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS remote_pk_mapping_graph TYPED remote_pk_mapping_gt
      """
    Then the execution should be successful
    And graph "remote_pk_mapping_graph" should be ready to use
    When executing query:
      """
      TABLE t {productId, regionId, name, price} =
        (1001, 1, "Laptop", 999.99),
        (1002, 1, "Mouse", 29.99),
        (1001, 2, "Laptop-EU", 1099.99)
      USE remote_pk_mapping_graph
      FOR r IN t
      INSERT OR REPLACE (@NProduct{productId:r.productId, regionId:r.regionId, name:r.name, price:r.price})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {customerId, email} =
        (2001, "alice@example.com"),
        (2002, "bob@example.com")
      USE remote_pk_mapping_graph
      FOR r IN t
      INSERT OR REPLACE (@Customer{customerId:r.customerId, email:r.email})
      """
    Then the execution should be successful
    # Test Case 1: Error - Remote primary key is not mapped
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_pk_unmapped_gt {
        NODE TYPE NProduct ({productId INT, regionId INT, name STRING, price DOUBLE, PRIMARY KEY(productId, regionId)})
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #pk_unmapped TYPED local_pk_unmapped_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #pk_unmapped IMPORT INTO GRAPH
      {
        NODE (v@NProduct{productId:productId, name:name, price:price}) FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_pk_mapping_graph&node_type=NProduct"
        }
      }
      """
    Then an Error should be raised: "Remote type `NProduct` primary key `regionId` is not mapped"
    And drop the graph "#pk_unmapped"
    And drop the graph type "local_pk_unmapped_gt"
    # Test Case 2: Error - Remote primary key is mapped to a non-primary-key property in local type
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_pk_not_primary_gt {
        NODE TYPE NProduct ({productId INT, regionCode INT, name STRING, price DOUBLE, PRIMARY KEY(productId)})
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #pk_not_primary TYPED local_pk_not_primary_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #pk_not_primary IMPORT INTO GRAPH
      {
        NODE (v@NProduct{productId:productId, regionCode:regionId, name:name, price:price}) FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_pk_mapping_graph&node_type=NProduct"
        }
      }
      """
    Then an Error should be raised: "Remote type `NProduct` primary key `regionId` is mapped to `regionCode`, but `regionCode` is not a primary key in local type `NProduct`"
    And drop the graph "#pk_not_primary"
    And drop the graph type "local_pk_not_primary_gt"
    # Test Case 3: Error - Primary key count mismatch (remote has 2, local has 3)
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS local_pk_count_mismatch_gt {
        NODE TYPE NProduct ({prodId INT, regId INT, categoryId INT, name STRING, price DOUBLE, PRIMARY KEY(prodId, regId, categoryId)})
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #pk_count_mismatch TYPED local_pk_count_mismatch_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #pk_count_mismatch IMPORT INTO GRAPH
      {
        NODE (v@NProduct{prodId:productId, regId:regionId, name:name, price:price}) FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=remote_pk_mapping_graph&node_type=NProduct"
        }
      }
      """
    Then an Error should be raised: "Type `NProduct` primary key count mismatch: remote has 2 keys, local has 3 keys"
    And drop the graph "#pk_count_mismatch"
    And drop the graph type "local_pk_count_mismatch_gt"
    And drop the graph "remote_pk_mapping_graph"
    And drop the graph type "remote_pk_mapping_gt"

  @non_tls
  Scenario: Unsupported options
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #unsupported_nebula_recoding TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #unsupported_nebula_recoding
      IMPORT INTO GRAPH {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      OPTIONS {PRIMARY_KEY_AS_NODE_ID:false}
      """
    Then an Error should be raised: "The PRIMARY_KEY_AS_NODE_ID option is not supported when importing from a Nebula source"

  @non_tls
  Scenario: Invalid URI
    # No graph name in the URI
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_no_graph_name TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_no_graph_name IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA {
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}"
        }
      }
      """
    Then an Error should be raised: "Missing required graph parameter in URI"
    And drop the graph "#dist_cross_group_graph_no_graph_name"
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_no_element_type TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_no_element_type IMPORT INTO GRAPH
      {
        EDGE (id:src)-[e@KNOWS{creationDate:creationDate}]->(id:dst) FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: No edge type found in URI"
    When executing analytic query:
      """
      USE #dist_cross_group_graph_no_element_type IMPORT INTO GRAPH
      {
        NODE (@Person{id:id}) FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      """
    Then an Error should be raised: "[NR129]: Import into temporary graph failed: No node type found in URI"
    And drop the graph "#dist_cross_group_graph_no_element_type"
    # Error: Invalid uri parameter
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/8419
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_cross_group_graph_analytic_service_invalid_uri_param TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_cross_group_graph_analytic_service_invalid_uri_param IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_ANALYTIC_ADDRESS}?graph=ldbc&invalid_param=true"
        }
      }
      """
    Then an Error should be raised: "Unknown URI parameter: `invalid_param`"
    # Error: Invalid schema name
    When executing analytic query:
      """
      USE #dist_cross_group_graph_analytic_service_invalid_uri_param IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&schema=invalid_schema"
        }
      }
      """
    Then an Error should be raised: " Catalog schema not found: `/default_schema/invalid_schema`"
    # Fix https://github.com/vesoft-inc/nebula-ng/issues/9031
    When executing analytic query:
      """
      USE #dist_cross_group_graph_analytic_service_invalid_uri_param IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=#ldbc"
        }
      }
      """
    Then an Error should be raised: "Temporary graph name is not supported in the Nebula URI"
    When executing analytic query:
      """
      USE #dist_cross_group_graph_analytic_service_invalid_uri_param IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph"
        }
      }
      """
    Then an Error should be raised: "Graph name parameter is empty in URI"
    And drop the graph "#dist_cross_group_graph_analytic_service_invalid_uri_param"

  @non_tls
  Scenario: rank generation
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS test_rank_gen_gt {
        NODE TYPE Person ({id INT PRIMARY KEY}),
        EDGE TYPE KNOWS (Person)-[LABEL KNOWS {MULTIEDGE KEY()}]->(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_rank_gen TYPED test_rank_gen_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_rank_gen IMPORT INTO GRAPH
      {
        NODE (v@Person{id:id}) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&node_type=Person"
        },
        EDGE (id:_)-[e@KNOWS{}]->(id:_) FROM NEBULA {
          FORMAT:"nebula",
          PATH: "nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&edge_type=KNOWS"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_rank_gen {
        VALUE l ListAgg<INT>

        MATCH (a)-[e]->(b)
        PER PATH {
          SET @l += multiedge_id(e)
        }
        FOR i IN @l
        FILTER i <> 0
        RETURN count(i)
      }
      """
    Then the result should be, in any order:
      | count(i) |
      | 3        |
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS `test_rank_gen_ldbc` AS {
        NODE TYPE `Place` (LABELS `City`&`Continent`&`Country`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, `kind` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
        NODE TYPE `Forum` (LABEL `Forum`{`id` INT64 NOT NULL, `title` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, PRIMARY KEY (`id`)}),
        NODE TYPE `Comment` (LABELS `Comment`&`Message`{`id` INT64 NOT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, PRIMARY KEY (`id`)}),
        NODE TYPE `Person` (LABEL `Person`{`id` INT64 NOT NULL, `firstName` STRING DEFAULT NULL, `lastName` STRING DEFAULT NULL, `gender` STRING DEFAULT NULL, `birthday` DATE DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL, PRIMARY KEY (`id`)}),
        NODE TYPE `Tag` (LABEL `Tag`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
        NODE TYPE `Post` (LABELS `Message`&`Post`{`id` INT64 NOT NULL, `imageFile` STRING DEFAULT NULL, `creationDate` LOCAL DATETIME DEFAULT NULL, `locationIP` STRING DEFAULT NULL, `browserUsed` STRING DEFAULT NULL, `content` STRING DEFAULT NULL, `extent` INT8 DEFAULT NULL, `language` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
        NODE TYPE `TagClass` (LABEL `TagClass`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
        NODE TYPE `Organisation` (LABELS `Company`&`University`{`id` INT64 NOT NULL, `kind` STRING DEFAULT NULL, `name` STRING DEFAULT NULL, `url` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
        EDGE TYPE `HAS_INTEREST` (`Person`)-[LABEL `HAS_INTEREST`{}]->(`Tag`),
        EDGE TYPE `WORK_AT` (`Person`)-[LABEL `WORK_AT`{`workFrom` INT64 DEFAULT NULL}]->(`Organisation`),
        EDGE TYPE `IS_LOCATED_IN_1` (`Person`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),
        EDGE TYPE `IS_LOCATED_IN_2` (`Comment`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),
        EDGE TYPE `IS_LOCATED_IN_3` (`Post`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),
        EDGE TYPE `IS_LOCATED_IN_4` (`Organisation`)-[LABEL `IS_LOCATED_IN`{}]->(`Place`),
        EDGE TYPE `IS_PART_OF` (`Place`)-[LABEL `IS_PART_OF`{}]->(`Place`),
        EDGE TYPE `HAS_TYPE` (`Tag`)-[LABEL `HAS_TYPE`{}]->(`TagClass`),
        EDGE TYPE `REPLY_OF_1` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Post`),
        EDGE TYPE `REPLY_OF_2` (`Comment`)-[LABEL `REPLY_OF`{}]->(`Comment`),
        EDGE TYPE `KNOWS` (`Person`)-[LABEL `KNOWS`{`creationDate` LOCAL DATETIME DEFAULT NULL, `vec` VECTOR<3, FLOAT> DEFAULT NULL}]->(`Person`),
        EDGE TYPE `FOLLOWS` (`Person`)-[LABEL `FOLLOWS`{`src` INT64 DEFAULT NULL, `dst` INT64 DEFAULT NULL}]->(`Person`),
        EDGE TYPE `CONTAINER_OF` (`Forum`)-[LABEL `CONTAINER_OF`{}]->(`Post`),
        EDGE TYPE `HAS_MEMBER` (`Forum`)-[LABEL `HAS_MEMBER`{}]->(`Person`),
        EDGE TYPE `HAS_MODERATOR` (`Forum`)-[LABEL `HAS_MODERATOR`{}]->(`Person`),
        EDGE TYPE `STUDY_AT` (`Person`)-[LABEL `STUDY_AT`{`classYear` INT64 DEFAULT NULL}]->(`Organisation`),
        EDGE TYPE `IS_SUBCLASS_OF` (`TagClass`)-[LABEL `IS_SUBCLASS_OF`{}]->(`TagClass`),
        EDGE TYPE `HAS_TAG_1` (`Forum`)-[LABEL `HAS_TAG`{}]->(`Tag`),
        EDGE TYPE `HAS_TAG_2` (`Post`)-[LABEL `HAS_TAG`{}]->(`Tag`),
        EDGE TYPE `HAS_TAG_3` (`Comment`)-[LABEL `HAS_TAG`{}]->(`Tag`),
        EDGE TYPE `HAS_CREATOR_1` (`Post`)-[LABEL `HAS_CREATOR`{}]->(`Person`),
        EDGE TYPE `HAS_CREATOR_2` (`Comment`)-[LABEL `HAS_CREATOR`{}]->(`Person`),
        EDGE TYPE `LIKES_1` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Post`),
        EDGE TYPE `LIKES_2` (`Person`)-[LABEL `LIKES`{`creationDate` LOCAL DATETIME DEFAULT NULL}]->(`Comment`)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #test_rank_ldbc TYPED test_rank_gen_ldbc PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_rank_ldbc IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          FORMAT:"nebula",
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #test_rank_ldbc {
        VALUE l ListAgg<INT>

        MATCH (a)-[e]->(b)
        PER PATH {
          SET @l += multiedge_id(e)
        }
        FOR i IN @l
        FILTER i = 0
        RETURN count(i)
      }
      """
    Then the result should be, in any order:
      | count(i) |
      | 74       |
    And drop the graph "#test_rank_gen"
    And drop the graph type "test_rank_gen_gt"
    And drop the graph "#test_rank_ldbc"
    And drop the graph type "test_rank_gen_ldbc"
