# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Distributed Graph Projection - Basic Operations

  Scenario: Creating and dropping distributed temporary graph
    # drop if exists
    When executing graph analytic query:
      """
      DROP GRAPH IF EXISTS #dist_graph_projection
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_projection AS COPY OF ldbc
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_graph_projection TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_graph_projection IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_graph_projection SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name   | element_type | total_num |
      | "Node Total" | "Node"       | 34        |
      | "Edge Total" | "Edge"       | 74        |
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #copy_from_temp_graph AS COPY OF #dist_graph_projection PARTITION BY DEFAULT
      """
    Then an Error should be raised: "[NT501]: Unsupported temporary graph operation: create distributed temporary graph from temporary graph"
    When executing query:
      """
      USE #dist_graph_projection SHOW STATS
      """
    Then the result should be, in any order:
      | entry_name        | element_type | total_num |
      | "Node Total"      | "Node"       | 34        |
      | "Edge Total"      | "Edge"       | 74        |
      | "Place"           | "Node"       | 6         |
      | "Forum"           | "Node"       | 4         |
      | "Comment"         | "Node"       | 4         |
      | "Person"          | "Node"       | 4         |
      | "Tag"             | "Node"       | 4         |
      | "Post"            | "Node"       | 4         |
      | "TagClass"        | "Node"       | 4         |
      | "Organisation"    | "Node"       | 4         |
      | "HAS_INTEREST"    | "Edge"       | 3         |
      | "WORK_AT"         | "Edge"       | 3         |
      | "IS_LOCATED_IN_1" | "Edge"       | 3         |
      | "IS_LOCATED_IN_2" | "Edge"       | 3         |
      | "IS_LOCATED_IN_3" | "Edge"       | 3         |
      | "IS_LOCATED_IN_4" | "Edge"       | 3         |
      | "IS_PART_OF"      | "Edge"       | 3         |
      | "HAS_TYPE"        | "Edge"       | 3         |
      | "REPLY_OF_1"      | "Edge"       | 3         |
      | "REPLY_OF_2"      | "Edge"       | 3         |
      | "KNOWS"           | "Edge"       | 3         |
      | "FOLLOWS"         | "Edge"       | 5         |
      | "CONTAINER_OF"    | "Edge"       | 3         |
      | "HAS_MEMBER"      | "Edge"       | 3         |
      | "HAS_MODERATOR"   | "Edge"       | 3         |
      | "STUDY_AT"        | "Edge"       | 3         |
      | "IS_SUBCLASS_OF"  | "Edge"       | 3         |
      | "HAS_TAG_1"       | "Edge"       | 3         |
      | "HAS_TAG_2"       | "Edge"       | 3         |
      | "HAS_TAG_3"       | "Edge"       | 3         |
      | "HAS_CREATOR_1"   | "Edge"       | 3         |
      | "HAS_CREATOR_2"   | "Edge"       | 3         |
      | "LIKES_1"         | "Edge"       | 3         |
      | "LIKES_2"         | "Edge"       | 3         |
    When executing analytic query:
      """
      USE #dist_graph_projection SHOW VERBOSE STATS
      """
    Then the result should be, in any order:
      | entry_name          | element_type | total_num | partitioned_num                                                    |
      | "Node Total"        | "Node"       | 34        | ""                                                                 |
      | "Edge Total"        | "Edge"       | 74        | ""                                                                 |
      | "Node Local Total"  | "Node"       | 62        | /127\.0\.0\.1:\d+: 27, 127\.0\.0\.1:\d+: 19, 127\.0\.0\.1:\d+: 16/ |
      | "Node Local Master" | "Node"       | 34        | /127\.0\.0\.1:\d+: 15, 127\.0\.0\.1:\d+: 11, 127\.0\.0\.1:\d+: 8/  |
      | "Node Local Mirror" | "Node"       | 28        | /127\.0\.0\.1:\d+: 12, 127\.0\.0\.1:\d+: 8, 127\.0\.0\.1:\d+: 8/   |
      | "Edge Local Total"  | "Edge"       | 74        | /127\.0\.0\.1:\d+: 40, 127\.0\.0\.1:\d+: 20, 127\.0\.0\.1:\d+: 14/ |
    When executing analytic query:
      """
      SHOW GRAPHS
      """
    Then the result should contain:
      | name                     | graph_type  | schema        | owner  | extra              |
      | "#dist_graph_projection" | "ldbc_type" | "/tmp_schema" | "root" | "distributed:true" |
    When executing graph analytic query:
      """
      DROP GRAPH #dist_graph_projection
      """
    Then the execution should be successful
    When executing query:
      """
      SHOW GRAPHS
      """
    Then the result should not contain:
      | name                     | schema            | owner  |
      | "#dist_graph_projection" | "/default_schema" | "root" |
    When executing graph analytic query:
      """
      DROP GRAPH #dist_graph_projection
      """
    Then an Error should be raised: "[NR123]: Temporary graph not found: `#dist_graph_projection`"

  Scenario: Load distributed temporary graph concurrently
    When executing graph query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_projection_con AS COPY OF ldbc
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #graph_projection_con TYPED ldbc_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #graph_projection_con IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=ldbc&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      DROP GRAPH #graph_projection_con
      """
    Then the execution should be successful
