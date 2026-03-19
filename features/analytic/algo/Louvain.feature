# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Louvain

  # karate_club_graph from python networkx
  Scenario: Louvain procedure
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS algo_louvain_test_gt {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS algo_louvain_test_g algo_louvain_test_gt
      """
    Then the execution should be successful
    And graph "algo_louvain_test_g" should be ready to use
    When executing graph query:
      """
      USE algo_louvain_test_g
      FOR i IN range(0, 33)
      INSERT (a@Person{id:i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src,dst,weight} =
      (0,1,4),(0,2,5),(0,3,3),(0,4,3),(0,5,3),
      (0,6,3),(0,7,2),(0,8,2),(0,10,2),(0,11,3),
      (0,12,1),(0,13,3),(0,17,2),(0,19,2),(0,21,2),
      (0,31,2),(1,2,6),(1,3,3),(1,7,4),(1,13,5),
      (1,17,1),(1,19,2),(1,21,2),(1,30,2),(2,3,3),
      (2,7,4),(2,8,5),(2,9,1),(2,13,3),(2,27,2),
      (2,28,2),(2,32,2),(3,7,3),(3,12,3),(3,13,3),
      (4,6,2),(4,10,3),(5,6,5),(5,10,3),(5,16,3),
      (6,16,3),(8,30,3),(8,32,3),(8,33,4),(9,33,2),
      (13,33,3),(14,32,3),(14,33,2),(15,32,3),(15,33,4),
      (18,32,1),(18,33,2),(19,33,1),(20,32,3),(20,33,1),
      (22,32,2),(22,33,3),(23,25,5),(23,27,4),(23,29,3),
      (23,32,5),(23,33,4),(24,25,2),(24,27,3),(24,31,2),
      (25,31,7),(26,29,4),(26,33,2),(27,33,4),(28,31,2),
      (28,33,2),(29,32,4),(29,33,2),(30,32,3),(30,33,3),
      (31,32,4),(31,33,4),(32,33,5)
      USE algo_louvain_test_g
      FOR r IN t
      MATCH (a@Person{id:r.src}),(b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_algo_louvain_test_g AS COPY OF algo_louvain_test_g
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_algo_louvain_test_g TYPED algo_louvain_test_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_algo_louvain_test_g IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=algo_louvain_test_g&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS louvain_origin(max_iter INT) RETURNS (max_id INT, min_id INT, community_size INT) AS {
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT, SumAgg<DOUBLE>> //total edge weight of each community
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0 //total edge weight of each node
        NODE VALUE node_community_weight MapAgg<INT, SumAgg<DOUBLE>> // total edge weight of each node for each community
        NODE VALUE community_id          SumAgg<INT> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT DESC>
        TABLE result_table TYPED         TABLE {id INT64, community_id INT}
        VALUE new_active                 OrAgg = true
        VALUE iter = 0

        // Initialize
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }

        SET @total_weight = @total_weight / 2
        LOG_INFO("total_weight = ", @total_weight)

        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = s.id
          SET @community_weight += TUPLE(s.id, s.@node_weight)
        }

        WHILE iter < max_iter AND @new_active THEN  {
          LOG_INFO("----------- iter == ",iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1
          // Calculate the contribution of each node to each community
          MATCH (s)-[e]-(t)
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // Choose the best direction to move
          MATCH (s)-[e]-(t)
          WHERE s.id < t.id AND iter % 2 = 0 OR s.id > t.id AND iter % 2 = 1 // avoid the exchange between two communities
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id) - s.@node_community_weight.get(s.@community_id)
              + 1 / @total_weight * s.@node_weight * (@community_weight.get(s.@community_id) - @community_weight.get(t.@community_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          // Move the node to the new community
          MATCH (s)
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET @community_weight += TUPLE(s.@community_id,-s.@node_weight)
                SET s.@community_id = move.community_id
                SET @community_weight += TUPLE(s.@community_id,s.@node_weight)
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }
        }

        MATCH (s)
        PER NODE (s) {
          EXPORT s.id, s.@community_id INTO result_table
        }

        FOR r IN result_table
        RETURN r.community_id as cid, max(r.id) as max_id, min(r.id) as min_id, count(r.id) as sz
        NEXT
        RETURN max_id,min_id, sz
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_algo_louvain_test_g CALL louvain_origin(10) RETURN max_id, min_id, community_size as sz
      """
    Then the result should be, in any order:
      | max_id | min_id | sz |
      | 7      | 2      | 2  |
      | 28     | 25     | 2  |
      | 16     | 0      | 6  |
      | 33     | 8      | 8  |
      | 21     | 1      | 8  |
      | 29     | 23     | 5  |
      | 32     | 14     | 3  |
    # NOTE(yuxuan.wang): In the Louvain algorithm, using cross-neighbor communication does not always yield positive effects.
    # Although we no longer need to maintain a global aggregator for community_weight, we still need to perform additional
    # operations to update community_weight for each node.
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_cross_neighbor(max_iter INT) RETURNS (max_id INT, min_id INT, community_size INT) AS {
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0               // total edge weight of each node
        NODE VALUE node_community_weight MapAgg<INT, SumAgg<DOUBLE>>      // total edge weight of each node for each community
        NODE VALUE community_weight      SumAgg<DOUBLE> = 0               // total edge weight of each community
        NODE VALUE community_id          SumAgg<INT> = 0
        NODE VALUE community_members     ListAgg<INT>
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT DESC>
        TABLE      result_table          TYPED TABLE {id INT64, community_id INT}
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0

        // Initialize
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }

        SET @total_weight = @total_weight / 2
        LOG_INFO("total_weight = ", @total_weight)

        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = element_id(s)
        }

        WHILE iter < max_iter AND @new_active THEN  {
          LOG_INFO("----------- iter == ",iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1

          MATCH (s)
          PER NODE (s) {
            SET s.@community_weight = 0
            SET s.@community_members.clear()
          }
          PER NODE (s) {
            VALUE community_center = s.@community_id
            SET NODE(community_center).@community_weight += s.@node_weight
            SET NODE(community_center).@community_members += element_id(s)
          }

          MATCH (s) WHERE s.@community_members.size() > 0
          PER NODE (s) {
            VALUE i = 0
            VALUE members = s.@community_members
            VALUE len = length(members)
            WHILE i < len THEN {
              VALUE member = members[i]
              SET i = i + 1
              IF member = element_id(s) THEN {
                CONTINUE
              }
              SET NODE(member).@community_weight += s.@community_weight
            }
          }

          // Calculate the contribution of each node to each community
          MATCH (s)-[e]-(t)
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
            // LOG_INFO(s.id," weight += [",t.id, ",", t.@community_id, ",", e.weight,"]")
          }

          // Choose the best direction to move
          MATCH (s)-[e]-(t)
          WHERE s.id < t.id AND iter % 2 = 0 OR s.id > t.id AND iter % 2 = 1 // avoid the exchange between two communities
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
                        - s.@node_community_weight.get(s.@community_id)
                        + 1 / @total_weight * s.@node_weight * (s.@community_weight - t.@community_weight)
            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          // Move the node to the new community
          MATCH (s)
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                // LOG_INFO(s.id," move to ",move.community_id, " delta: ",move.delta_q)
                SET @new_active += true
                SET s.@community_id = move.community_id
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }
        }

        MATCH (s)
        PER NODE (s) {
          EXPORT s.id, s.@community_id INTO result_table
        }

        FOR r IN result_table
        RETURN r.community_id as cid, max(r.id) as max_id, min(r.id) as min_id, count(r.id) as sz
        NEXT
        RETURN max_id,min_id, sz
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_algo_louvain_test_g CALL louvain_cross_neighbor(10) RETURN max_id, min_id, community_size as sz
      """
    Then the result should be, in any order:
      | max_id | min_id | sz |
      | 7      | 2      | 2  |
      | 28     | 25     | 2  |
      | 16     | 0      | 6  |
      | 33     | 8      | 8  |
      | 21     | 1      | 8  |
      | 29     | 23     | 5  |
      | 32     | 14     | 3  |
    # NOTE(yuxuan.wang): Some parts of the Louvain algorithm are independent for each node,
    # so we can split them into multiple batches to reduce the memory overhead caused by intermediate results.
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_batch(max_iter INT, num_of_batch INT) RETURNS (max_id INT, min_id INT, community_size INT) AS {
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0               // total edge weight of each node
        NODE VALUE node_community_weight MapAgg<INT, SumAgg<DOUBLE>>      // total edge weight of each node for each community
        NODE VALUE community_weight      SumAgg<DOUBLE> = 0               // total edge weight of each community
        NODE VALUE community_id          SumAgg<INT> = 0
        NODE VALUE temp_community_id     SumAgg<INT> = 0
        NODE VALUE community_members     ListAgg<INT>
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT DESC>
        TABLE      result_table          TYPED TABLE {id INT64, community_id INT}
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE batch_active_set ACTIVE_SET

        // Initialize
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }

        SET @total_weight = @total_weight / 2
        LOG_INFO("total_weight = ", @total_weight)

        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = element_id(s)
          SET s.@temp_community_id = element_id(s)
        }

        WHILE iter < max_iter AND @new_active THEN  {
          VALUE cur_batch = 0
          LOG_INFO("----------- iter == ",iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1

          MATCH (s)
          PER NODE (s) {
            SET s.@community_weight = 0
            SET s.@community_members.clear()
          }
          PER NODE (s) {
            VALUE community_center = s.@community_id
            SET NODE(community_center).@community_weight += s.@node_weight
            SET NODE(community_center).@community_members += element_id(s)
          }

          MATCH (s) WHERE s.@community_members.size() > 0
          PER NODE (s) {
            VALUE i = 0
            VALUE members = s.@community_members
            VALUE len = length(members)
            WHILE i < len THEN {
              VALUE member = members[i]
              SET i = i + 1
              IF member = element_id(s) THEN {
                CONTINUE
              }
              SET NODE(member).@community_weight += s.@community_weight
            }
          }


          WHILE cur_batch < num_of_batch THEN {
            MATCH (s)
            WHERE element_id(s) % num_of_batch = cur_batch
            FINALLY {
              SET batch_active_set = s
            }

            // Calculate the contribution of each node to each community
            MATCH (s)-[e]-(t)
            WHERE s IN batch_active_set
            PER PATH {
              SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
              // LOG_INFO(s.id," weight += [",t.id, ",", t.@community_id, ",", e.weight,"]")
            }

            // Choose the best direction to move
            MATCH (s)-[e]-(t)
            WHERE (s.id < t.id AND iter % 2 = 0 OR s.id > t.id AND iter % 2 = 1) // avoid the exchange between two communities
                AND s IN batch_active_set
            PER PATH {
              VALUE delta = s.@node_community_weight.get(t.@community_id)
                          - s.@node_community_weight.get(s.@community_id)
                          + 1 / @total_weight * s.@node_weight * (s.@community_weight - t.@community_weight)
              SET s.@best_move += RECORD {
                delta_q: delta,
                community_id: t.@community_id
              }
            }

            // Move the node to the new community
            MATCH (s)
            PER NODE (s) {
              VALUE move_list = s.@best_move
              IF length(move_list) <> 0 THEN {
                VALUE move = move_list[0]
                // LOG_INFO(s.id," move to ",move.community_id, " delta: ",move.delta_q)
                IF move.delta_q > 0 THEN {
                  // LOG_INFO(s.id," move to ",move.community_id, " delta: ",move.delta_q)
                  SET @new_active += true
                  // cannot update community_id directly here, as this may affect the computation of other batches
                  SET s.@temp_community_id = move.community_id
                }
              }
              SET s.@node_community_weight.clear()
              SET s.@best_move.clear()
            }
            SET cur_batch = cur_batch + 1
          }
          MATCH (s)
          PER NODE (s) {
            SET s.@community_id = s.@temp_community_id
          }
        }

          MATCH (s)
          PER NODE (s) {
            EXPORT s.id, s.@community_id INTO result_table
          }

          FOR r IN result_table
          RETURN r.community_id as cid, max(r.id) as max_id, min(r.id) as min_id, count(r.id) as sz
          NEXT
          RETURN max_id,min_id, sz
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_algo_louvain_test_g CALL louvain_batch(10, 3) RETURN max_id, min_id, community_size as sz
      """
    Then the result should be, in any order:
      | max_id | min_id | sz |
      | 7      | 2      | 2  |
      | 28     | 25     | 2  |
      | 16     | 0      | 6  |
      | 33     | 8      | 8  |
      | 21     | 1      | 8  |
      | 29     | 23     | 5  |
      | 32     | 14     | 3  |
    And drop the graph "#dist_algo_louvain_test_g"
    And drop the graph "algo_louvain_test_g"
    And drop the graph type "algo_louvain_test_gt"
    And drop the procedure "louvain_origin"
    And drop the procedure "louvain_cross_neighbor"
    And drop the procedure "louvain_batch"

  Scenario: Louvain graph variable implementation
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS algo_louvain_full_test_gt {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #algo_louvain_test_g algo_louvain_full_test_gt
      """
    Then the execution should be successful
    And graph "#algo_louvain_test_g" should be ready to use
    When executing graph query:
      """
      USE #algo_louvain_test_g
      FOR i IN range(0, 14)
      INSERT (a@Person{id:i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src,dst,weight} =
      (0,1,4),(1,2,4),(2,3,4),(3,4,4),(4,0,4),
      (0,2,3),(1,3,3),(2,4,3),(3,0,3),(4,1,3),
      (5,6,4),(6,7,4),(7,8,4),(8,9,4),(9,5,4),
      (5,7,3),(6,8,3),(7,9,3),(8,5,3),(9,6,3),
      (10,11,4),(11,12,4),(12,13,4),(13,14,4),(14,10,4),
      (10,12,3),(11,13,3),(12,14,3),(13,10,3),(14,11,3),
      (2,5,1),(4,7,1),
      (7,10,1),(9,12,1),
      (1,11,1),(3,14,1)
      USE #algo_louvain_test_g
      FOR r IN t
      MATCH (a@Person{id:r.src}),(b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS louvain_work_gt AS {
        NODE TYPE community (
          LABEL community {
            id INT PRIMARY KEY,
            cid INT
          }
        ),
        EDGE TYPE edge (community)-[:edge{
          weight DOUBLE,
          MULTIEDGE KEY()
        }]->(community)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_import_graph(nodes TABLE, edges TABLE) AS {
        IMPORT INTO GRAPH {
          NODE (v@community {id:id, cid:cid}) FROM nodes,
          EDGE (id:src)-[e@edge{weight:weight}]->(id:dst) FROM edges
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_outer(max_layer INT, max_iter INT) RETURNS (node_id INT, community_id INT) AS {
        GRAPH g TYPED louvain_work_gt
        TABLE nodes TYPED TABLE {id INT, cid INT}
        TABLE edges TYPED TABLE {src INT, dst INT, weight DOUBLE}
        VALUE i = 0

        MATCH (v)
        PER NODE (v) {
          EXPORT v.id AS id, v.id AS cid INTO nodes
        }
        MATCH (s)-[e]-(t)
        PER PATH {
          EXPORT s.id AS src, t.id AS dst, e.weight AS weight INTO edges
        }

        USE g
        CALL louvain_import_graph(nodes, edges) FINISH

        SET nodes.clear()
        SET edges.clear()

        WHILE (i < max_layer) THEN {
          LOG_INFO("----------- louvain_outer layer start, i = ", i)
          USE g
          CALL louvain_inner(max_iter, nodes, edges) FINISH
          LOG_INFO("-----------  louvain_outer layer done, i = ", i)

          IF (i <> max_layer - 1) THEN {
            SET g.clear()
            USE g
            CALL louvain_import_graph(nodes, edges) FINISH
            SET nodes.clear()
            SET edges.clear()
          }
          SET i = i + 1
        }

        FOR r IN nodes
        RETURN r.id AS node_id, r.cid AS community_id
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_inner(max_iter INT, nodes TABLE, edges TABLE) AS {
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE      primaryid_2_nodeid    MapAgg<INT64, MaxAgg<INT64>>
        VALUE      node2_community_id    MapAgg<INT64, MaxAgg<INT64>>
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>

        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }
        SET @total_weight = @total_weight / 2
        LOG_INFO("Iter start, total_weight = ", @total_weight)

        MATCH (s)
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
          SET s.@community_id = s.id
          SET @community_weight += TUPLE(s.id, s.@node_weight)
        }

        WHILE iter < max_iter AND @new_active THEN {
          LOG_INFO("----------- iter == ",iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1

          MATCH (s)-[e]-(t)
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          MATCH (s)-[e]-(t)
          WHERE (s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1)
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
              - s.@node_community_weight.get(s.@community_id)
              + (1.0 / @total_weight) * s.@node_weight *
                (@community_weight.get(s.@community_id)
                 - @community_weight.get(t.@community_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          MATCH (s)
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                VALUE old_comm = s.@community_id
                // LOG_INFO("move node ", s.id, " from ", old_comm, " to ", move.community_id, " delta_q=", move.delta_q)
                SET @new_active += true
                SET @community_weight += TUPLE(s.@community_id, -s.@node_weight)
                SET s.@community_id = move.community_id
                SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }
        }
        LOG_INFO("louvain_inner done, iter = ", iter)

        MATCH (s)-[e]-(t)
        WHERE s.id <= t.id
        PER PATH {
          VALUE s_comm = s.@community_id
          VALUE t_comm = t.@community_id
          VALUE node_comm = @primaryid_2_nodeid.get(s_comm)
          IF s.id = t.id THEN {
            SET NODE(node_comm).@community_edge_weight += TUPLE(s_comm, e.weight / 2)
          } ELSE {
            IF s_comm = t_comm THEN {
              SET NODE(node_comm).@community_edge_weight += TUPLE(s_comm, e.weight)
            } ELSE {
              SET NODE(node_comm).@community_edge_weight += TUPLE(t_comm, e.weight)
            }
          }
        }

        MATCH (s)
        PER NODE (s) {
          SET @node2_community_id += TUPLE(s.id, s.@community_id)
        }

        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT s.@community_id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          EXPORT s.id AS id, @node2_community_id.get(s.cid) AS cid INTO nodes
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #algo_louvain_test_g
      CALL louvain_outer(6, 6) RETURN count(DISTINCT community_id) AS community_cnt
      """
    Then the result should be, in any order:
      | community_cnt |
      | 3             |
    And drop the procedure "louvain_import_graph"
    And drop the procedure "louvain_outer"
    And drop the procedure "louvain_inner"
    And drop the graph "#algo_louvain_test_g"
    And drop the graph type "louvain_work_gt"
    And drop the graph type "algo_louvain_full_test_gt"
