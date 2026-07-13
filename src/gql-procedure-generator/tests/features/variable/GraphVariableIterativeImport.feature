# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Graph Variable Iterative Import

  Scenario: Graph variable iterative import/export with active set and aggregation
    And drop the graph "#gv_iter_base"
    And drop the graph type "gv_iter_gt"
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gv_iter_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY,
            val INT
          }
        ),
        EDGE Link (Person)-[:Link{
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #gv_iter_base gv_iter_gt
      """
    Then the execution should be successful
    And graph "#gv_iter_base" should be ready to use
    When executing query:
      """
      USE #gv_iter_base
      FOR i IN range(0, 5)
      INSERT (a@Person{id:i, val:0})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {src,dst,eid} =
      (0,1,1),(1,2,2),(2,3,3),(3,4,4),(4,5,5)
      USE #gv_iter_base
      FOR r IN t
      MATCH (a@Person{id:r.src}),(b@Person{id:r.dst})
      INSERT (a)-[@Link{id:r.eid}]->(b)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE gv_iter_import(nodes TABLE, edges TABLE) AS {
        IMPORT INTO GRAPH {
          NODE (p@Person{ id:id, val:val }) FROM nodes,
          EDGE (id:src)-[e@Link{ id:eid }]->(id:dst) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE gv_iter_step(iter INT, nodes TABLE, edges TABLE) AS {
        VALUE active_set ACTIVE_SET
        VALUE active_cnt SumAgg<INT> = 0
        NODE VALUE next_val SumAgg<INT> = 0

        MATCH (v@Person)
        PER NODE (v) {
          SET v.@next_val = v.val
        }

        MATCH (v@Person) WHERE v.id = iter
        FINALLY {
          SET active_set = v
        }

        MATCH (v@Person)
        WHERE v IN active_set
        PER NODE (v) {
          SET v.@next_val = v.val + 1
          SET @active_cnt += 1
        }

        MATCH (v@Person)
        PER NODE (v) {
          EXPORT v.id AS id, v.@next_val AS val INTO nodes
        }

        MATCH (s@Person)-[e@Link]->(t@Person)
        PER PATH {
          EXPORT s.id AS src, t.id AS dst, e.id AS eid INTO edges
        }

        LOG_INFO("gv_iter_step iter=", iter, " active_cnt=", @active_cnt)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE gv_iter_outer(max_iter INT) RETURNS (id INT, val INT) AS {
        GRAPH g TYPED gv_iter_gt
        TABLE nodes TYPED TABLE {id INT, val INT}
        TABLE edges TYPED TABLE {src INT, dst INT, eid INT}
        VALUE iter = 0

        MATCH (v@Person)
        PER NODE (v) {
          EXPORT v.id AS id, v.val AS val INTO nodes
        }
        MATCH (s@Person)-[e@Link]->(t@Person)
        PER PATH {
          EXPORT s.id AS src, t.id AS dst, e.id AS eid INTO edges
        }

        USE g
        CALL gv_iter_import(nodes, edges) FINISH

        SET nodes.clear()
        SET edges.clear()

        WHILE (iter < max_iter) THEN {
          USE g
          CALL gv_iter_step(iter, nodes, edges) FINISH

          IF (iter <> max_iter - 1) THEN {
            SET g.clear()
            USE g
            CALL gv_iter_import(nodes, edges) FINISH
            SET nodes.clear()
            SET edges.clear()
          }
          SET iter = iter + 1
        }

        FOR r IN nodes
        RETURN r.id AS id, r.val AS val
        ORDER BY r.id
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #gv_iter_base
      CALL gv_iter_outer(3) RETURN id, val
      """
    Then the result should be, in order:
      | id | val |
      | 0  | 1   |
      | 1  | 1   |
      | 2  | 1   |
      | 3  | 0   |
      | 4  | 0   |
      | 5  | 0   |
    And drop the procedure "gv_iter_import"
    And drop the procedure "gv_iter_step"
    And drop the procedure "gv_iter_outer"
    And drop the graph "#gv_iter_base"
    And drop the graph type "gv_iter_gt"

  Scenario: Graph variable iterative import/export with active set and aggregation on analytic distributed graph
    And drop the graph "#dist_gv_iter_base_analytic"
    And drop the graph "gv_iter_base_analytic"
    And drop the graph type "gv_iter_analytic_gt"
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gv_iter_analytic_gt AS {
        NODE Person (
          LABEL Person {
            id INT PRIMARY KEY,
            val INT
          }
        ),
        EDGE Link (Person)-[:Link{
          id INT,
          MULTIEDGE KEY()
        }]->(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS gv_iter_base_analytic gv_iter_analytic_gt
      """
    Then the execution should be successful
    And graph "gv_iter_base_analytic" should be ready to use
    When executing graph query:
      """
      USE gv_iter_base_analytic
      FOR i IN range(0, 5)
      INSERT (a@Person{id:i, val:0})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src,dst,eid} =
      (0,1,1),(1,2,2),(2,3,3),(3,4,4),(4,5,5)
      USE gv_iter_base_analytic
      FOR r IN t
      MATCH (a@Person{id:r.src}),(b@Person{id:r.dst})
      INSERT (a)-[@Link{id:r.eid}]->(b)
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_gv_iter_base_analytic
      TYPED gv_iter_analytic_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_gv_iter_base_analytic IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=gv_iter_base_analytic&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE gv_iter_analytic_import(nodes TABLE, edges TABLE) AS {
        IMPORT INTO GRAPH {
          NODE (p@Person{ id:id, val:val }) FROM nodes,
          EDGE (id:src)-[e@Link{ id:eid }]->(id:dst) FROM edges
        } OPTIONS { PRIMARY_KEY_AS_NODE_ID: true }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE gv_iter_analytic_step(iter INT, nodes TABLE, edges TABLE) AS {
        VALUE active_set ACTIVE_SET
        VALUE active_cnt SumAgg<INT> = 0
        NODE VALUE next_val SumAgg<INT> = 0

        MATCH (v@Person)
        PER NODE (v) {
          SET v.@next_val = v.val
        }

        MATCH (v@Person) WHERE v.id = iter
        FINALLY {
          SET active_set = v
        }

        MATCH (v@Person)
        WHERE v IN active_set
        PER NODE (v) {
          SET v.@next_val = v.val + 1
          SET @active_cnt += 1
        }

        MATCH (v@Person)
        PER NODE (v) {
          EXPORT v.id AS id, v.@next_val AS val INTO nodes
        }

        MATCH (s@Person)-[e@Link]->(t@Person)
        PER PATH {
          EXPORT s.id AS src, t.id AS dst, e.id AS eid INTO edges
        }

        LOG_INFO("gv_iter_analytic_step iter=", iter, " active_cnt=", @active_cnt)
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE gv_iter_analytic_outer(max_iter INT) RETURNS (id INT, val INT) AS {
        GRAPH g TYPED gv_iter_analytic_gt PARTITION BY DEFAULT
        TABLE nodes TYPED TABLE {id INT, val INT} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src INT, dst INT, eid INT} PARTITION BY DEFAULT
        VALUE iter = 0

        MATCH (v@Person)
        PER NODE (v) {
          EXPORT v.id AS id, v.val AS val INTO nodes
        }
        MATCH (s@Person)-[e@Link]->(t@Person)
        PER PATH {
          EXPORT s.id AS src, t.id AS dst, e.id AS eid INTO edges
        }

        USE g
        CALL gv_iter_analytic_import(nodes, edges) FINISH

        PER PARTITION (nodes_part) OF nodes {
          SET nodes_part.clear()
        }
        PER PARTITION (edges_part) OF edges {
          SET edges_part.clear()
        }

        WHILE (iter < max_iter) THEN {
          USE g
          CALL gv_iter_analytic_step(iter, nodes, edges) FINISH

          IF (iter <> max_iter - 1) THEN {
            SET g.clear()
            USE g
            CALL gv_iter_analytic_import(nodes, edges) FINISH
            PER PARTITION (nodes_part) OF nodes {
              SET nodes_part.clear()
            }
            PER PARTITION (edges_part) OF edges {
              SET edges_part.clear()
            }
          }
          SET iter = iter + 1
        }

        PER PARTITION (nodes_part) OF nodes {
          FOR r IN nodes_part
          RETURN r.id AS id, r.val AS val
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_gv_iter_base_analytic
      CALL gv_iter_analytic_outer(3) RETURN id, val
      """
    Then the result should be, in any order:
      | id | val |
      | 0  | 1   |
      | 1  | 1   |
      | 2  | 1   |
      | 3  | 0   |
      | 4  | 0   |
      | 5  | 0   |
    And drop the procedure "gv_iter_analytic_import"
    And drop the procedure "gv_iter_analytic_step"
    And drop the procedure "gv_iter_analytic_outer"
    And drop the graph "#dist_gv_iter_base_analytic"
    And drop the graph "gv_iter_base_analytic"
    And drop the graph type "gv_iter_analytic_gt"
