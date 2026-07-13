# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Louvain

  Scenario: Louvain implementation support outer-inner iteration and modularity calculation
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
      (1,11,1),(3,14,1),
      (0,6,2),(0,8,2),
      (5,11,2),(5,13,2),
      (10,1,2),(10,3,2)
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
      EDGE TYPE edge (community)~[:edge{
      weight DOUBLE,
      MULTIEDGE KEY()
      }]~(community)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_full_import_graph(nodes TABLE, edges TABLE) AS {
      IMPORT INTO GRAPH {
      NODE (v@community {id:id, cid:cid}) FROM nodes,
      EDGE (id:src)~[e@edge{weight:weight}]~(id:dst) FROM edges
      }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_full_outer(max_layer INT, max_iter INT, resolution DOUBLE) RETURNS (node_id INT, community_id INT) AS {
        GRAPH g TYPED louvain_work_gt
        TABLE nodes TYPED TABLE {id INT, cid INT}
        TABLE edges TYPED TABLE {src INT, dst INT, weight DOUBLE}
        VALUE i = 0

        WHILE (i < max_layer) THEN {
          LOG_DEBUG("----------- louvain_outer layer start, i = ", i)
          IF (i = 0) THEN {
            CALL louvain_full_initial_inner(max_iter, resolution, nodes, edges) FINISH
          } ELSE {
            USE g
            CALL louvain_full_inner(max_iter, resolution, nodes, edges) FINISH
          }

          IF (i <> max_layer - 1) THEN {
            SET g.clear()
            LOG_DEBUG("Create Graph from NodeTable: ", size(nodes), " EdgeTable", size(edges))
            USE g
            CALL louvain_full_import_graph(nodes, edges) FINISH
            SET nodes.clear()
            SET edges.clear()
          }
          LOG_DEBUG("----------- louvain_outer layer finish, i = ", i)
          SET i = i + 1
        }

        FOR r IN nodes
        RETURN r.id AS node_id, r.cid AS community_id
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_full_initial_inner(max_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // ------------------------------------------------------------
        // Section 0: Working state and aggregators used by one Louvain layer
        // ------------------------------------------------------------
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE community_primary_id  SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE      primaryid_2_nodeid    MapAgg<INT64, MaxAgg<INT64>>
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET

        // ------------------------------------------------------------
        // Section 1: Graph statistics initialization
        // - total_weight: total edge weight m (undirected)
        // - node_weight: weighted degree of each node
        // Note: MATCH (s)-[e]-(t) scans each undirected edge twice, so divide by 2.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }
        FINALLY {
          SET active_set = s
        }
        SET @total_weight = @total_weight / 2
        LOG_DEBUG("Iter start, total_weight = ", @total_weight)

        // ------------------------------------------------------------
        // Section 2: Initial partition setup
        // - Start from singleton communities: community_id = node id.
        // - Defer community_weight materialization until after the first move pass.
        // - Defer primaryid_2_nodeid materialization until aggregation, where NODE(...) first needs it.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = s.id
        }

        // ------------------------------------------------------------
        // Section 3: Local moving iterations (Louvain core)
        // Repeatedly move nodes to neighboring communities that improve ΔQ.
        // Stop when no node moves or max_iter is reached.
        // ------------------------------------------------------------
        IF max_iter > 0 THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
            // In the singleton phase, community_id equals node id. Store each undirected
            // edge only once on the smaller endpoint and mirror-read it when needed.
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE edge_to_target DOUBLE = 0.0
            VALUE delta DOUBLE = 0.0
            IF s.id <= t.id THEN {
              SET edge_to_target = s.@node_community_weight.get(t.@community_id)
            } ELSE {
              SET edge_to_target = t.@node_community_weight.get(s.@community_id)
            }
            SET delta = edge_to_target
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight * (s.@node_weight - t.@node_weight)

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET s.@community_id = move.community_id
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        } ELSE {
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        }

        // 3.2 Later iterations reuse the generic community_weight-based formula.
        WHILE iter < max_iter AND @new_active THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.2.1 Accumulate, for each node, total edge weight to each neighbor community.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // 3.2.2 Build move candidates with modularity gain ΔQ under resolution γ.
          // Odd/even ordering reduces update conflicts in one pass.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight *
                (@community_weight.get(s.@community_id)
                 - @community_weight.get(t.@community_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          // 3.2.3 Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
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
        LOG_DEBUG("louvain_inner done, iter = ", iter)

        // ------------------------------------------------------------
        // Section 4: Build coarse inter-community edge weights
        // Accumulate edge weights between resulting communities for next layer.
        // For self-loop in input, count half to keep undirected semantics consistent.
        // ------------------------------------------------------------
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
        }

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
        SET @primaryid_2_nodeid.clear()

        // ------------------------------------------------------------
        // Section 5: Compute modularity Q(γ) for current partition
        // ------------------------------------------------------------
        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c (= @community_weight.get(c))
        // m:   total edge weight (= @total_weight)
        // The bucket owner is the node whose s.id equals the community label;
        // s.@community_id may differ if the owner moved in a later iteration.
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE e_c = s.@community_edge_weight.get(s.id)
            VALUE a_c = @community_weight.get(s.id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("louvain modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)
        SET @community_weight.clear()

        // ------------------------------------------------------------
        // Section 6: Export coarse graph and original-node backtracking table
        // - edges: community-level weighted edges for next outer layer
        // - nodes: keep every original node id and update its current community id
        //          after the first layer
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT s.id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          EXPORT s.id AS id, s.@community_id AS cid INTO nodes
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_full_inner(max_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // ------------------------------------------------------------
        // Section 0: Working state and aggregators used by one Louvain layer
        // ------------------------------------------------------------
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE community_primary_id  SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE      primaryid_2_nodeid    MapAgg<INT64, MaxAgg<INT64>>
        VALUE      node2_community_id    MapAgg<INT64, MaxAgg<INT64>>
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET

        // ------------------------------------------------------------
        // Section 1: Graph statistics initialization
        // - total_weight: total edge weight m (undirected)
        // - node_weight: weighted degree of each node
        // Note: MATCH (s)-[e]-(t) scans each undirected edge twice, so divide by 2.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }
        FINALLY {
          SET active_set = s
        }
        SET @total_weight = @total_weight / 2
        LOG_DEBUG("Iter start, total_weight = ", @total_weight)

        // ------------------------------------------------------------
        // Section 2: Initial partition setup
        // - Start from singleton communities: community_id = node id.
        // - Defer community_weight materialization until after the first move pass.
        // - Defer primaryid_2_nodeid materialization until aggregation, where NODE(...) first needs it.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = s.id
        }

        // ------------------------------------------------------------
        // Section 3: Local moving iterations (Louvain core)
        // Repeatedly move nodes to neighboring communities that improve ΔQ.
        // Stop when no node moves or max_iter is reached.
        // ------------------------------------------------------------
        IF max_iter > 0 THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
            // In the singleton phase, community_id equals node id. Store each undirected
            // edge only once on the smaller endpoint and mirror-read it when needed.
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE edge_to_target DOUBLE = 0.0
            VALUE delta DOUBLE = 0.0
            IF s.id <= t.id THEN {
              SET edge_to_target = s.@node_community_weight.get(t.@community_id)
            } ELSE {
              SET edge_to_target = t.@node_community_weight.get(s.@community_id)
            }
            SET delta = edge_to_target
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight * (s.@node_weight - t.@node_weight)

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET s.@community_id = move.community_id
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        } ELSE {
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        }

        // 3.2 Later iterations reuse the generic community_weight-based formula.
        WHILE iter < max_iter AND @new_active THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.2.1 Accumulate, for each node, total edge weight to each neighbor community.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // 3.2.2 Build move candidates with modularity gain ΔQ under resolution γ.
          // Odd/even ordering reduces update conflicts in one pass.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight *
                (@community_weight.get(s.@community_id)
                 - @community_weight.get(t.@community_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          // 3.2.3 Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
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
        LOG_DEBUG("louvain_inner done, iter = ", iter)

        // ------------------------------------------------------------
        // Section 4: Build coarse inter-community edge weights
        // Accumulate edge weights between resulting communities for next layer.
        // For self-loop in input, count half to keep undirected semantics consistent.
        // ------------------------------------------------------------
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
        }

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
        SET @primaryid_2_nodeid.clear()

        // ------------------------------------------------------------
        // Section 5: Build node -> community mapping for backtracking
        // This includes all nodes (including isolated ones), so upper layers can
        // propagate original-node community ids.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET @node2_community_id += TUPLE(s.id, s.@community_id)
        }

        // ------------------------------------------------------------
        // Section 6: Compute modularity Q(γ) for current partition
        // ------------------------------------------------------------
        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c (= @community_weight.get(c))
        // m:   total edge weight (= @total_weight)
        // The bucket owner is the node whose s.id equals the community label;
        // s.@community_id may differ if the owner moved in a later iteration.
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE e_c = s.@community_edge_weight.get(s.id)
            VALUE a_c = @community_weight.get(s.id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("louvain modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)
        SET @community_weight.clear()

        // ------------------------------------------------------------
        // Section 7: Export coarse graph and original-node backtracking table
        // - edges: community-level weighted edges for next outer layer
        // - nodes: keep every original node id and update its current community via
        //          one-step mapping node2_community_id.get(s.cid)
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT s.id AS src, r._0 AS dst, r._1 AS weight INTO edges
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
      CALL louvain_full_outer(6, 6, 1.0) RETURN count(DISTINCT community_id) AS community_cnt
      """
    Then the result should be, in any order:
      | community_cnt |
      | 3             |
    And drop the procedure "louvain_full_import_graph"
    And drop the procedure "louvain_full_outer"
    And drop the procedure "louvain_full_initial_inner"
    And drop the procedure "louvain_full_inner"
    And drop the graph "#algo_louvain_test_g"
    And drop the graph type "louvain_work_gt"
    And drop the graph type "algo_louvain_full_test_gt"

  Scenario: Louvain analytic implementation support outer-inner iteration and modularity calculation
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS algo_louvain_full_test_analytic_feature_gt {
      NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
      EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS algo_louvain_full_test_analytic_feature_g algo_louvain_full_test_analytic_feature_gt
      """
    Then the execution should be successful
    And graph "algo_louvain_full_test_analytic_feature_g" should be ready to use
    When executing graph query:
      """
      USE algo_louvain_full_test_analytic_feature_g
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
      (1,11,1),(3,14,1),
      (0,6,2),(0,8,2),
      (5,11,2),(5,13,2),
      (10,1,2),(10,3,2)
      USE algo_louvain_full_test_analytic_feature_g
      FOR r IN t
      MATCH (a@Person{id:r.src}),(b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_algo_louvain_full_test_analytic_feature_g
      TYPED algo_louvain_full_test_analytic_feature_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_algo_louvain_full_test_analytic_feature_g IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=algo_louvain_full_test_analytic_feature_g&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS louvain_work_analytic_feature_gt AS {
      NODE TYPE community (
      LABEL community {
      id INT PRIMARY KEY,
      cid INT
      }
      ),
      EDGE TYPE edge (community)~[:edge{
      weight DOUBLE,
      MULTIEDGE KEY()
      }]~(community)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_feature_import_graph(nodes TABLE, edges TABLE) AS {
      IMPORT INTO GRAPH {
      NODE (v@community {id:id, cid:cid}) FROM nodes,
      EDGE (id:src)~[e@edge{weight:weight}]~(id:dst) FROM edges
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_feature_outer(max_layer INT, max_iter INT, resolution DOUBLE) RETURNS (node_id INT, community_id INT) AS {
        GRAPH g TYPED louvain_work_analytic_feature_gt PARTITION BY DEFAULT
        TABLE nodes TYPED TABLE {id INT, cid INT} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src INT, dst INT, weight DOUBLE} PARTITION BY DEFAULT
        VALUE i = 0

        WHILE (i < max_layer) THEN {
          LOG_DEBUG("----------- louvain_outer layer start, i = ", i)
          IF (i = 0) THEN {
            CALL louvain_analytic_feature_initial_inner(max_iter, resolution, nodes, edges) FINISH
          } ELSE {
            USE g
            CALL louvain_analytic_feature_inner(max_iter, resolution, nodes, edges) FINISH
          }

          IF (i <> max_layer - 1) THEN {
            SET g.clear()
            // LOG_DEBUG("Create Graph from NodeTable: ", size(nodes), " EdgeTable", size(edges))
            USE g
            CALL louvain_analytic_feature_import_graph(nodes, edges) FINISH
            PER PARTITION (nodes_part) OF nodes {
              SET nodes_part.clear()
            }
            PER PARTITION (edges_part) OF edges {
              SET edges_part.clear()
            }
          }
          LOG_DEBUG("----------- louvain_outer layer finish, i = ", i)
          SET i = i + 1
        }

        PER PARTITION (nodes_part) OF nodes {
          FOR r IN nodes_part
          RETURN r.id AS node_id, r.cid AS community_id
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_feature_initial_inner(max_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // ------------------------------------------------------------
        // Section 0: Working state and aggregators used by one Louvain layer
        // ------------------------------------------------------------
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE      primaryid_2_nodeid    MapAgg<INT64, MaxAgg<INT64>>
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET

        // ------------------------------------------------------------
        // Section 1: Graph statistics initialization
        // - total_weight: total edge weight m (undirected)
        // - node_weight: weighted degree of each node
        // Note: MATCH (s)-[e]-(t) scans each undirected edge twice, so divide by 2.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }
        FINALLY {
          SET active_set = s
        }
        SET @total_weight = @total_weight / 2
        LOG_DEBUG("Iter start, total_weight = ", @total_weight)

        // ------------------------------------------------------------
        // Section 2: Initial partition setup
        // - Start from singleton communities: community_id = node id.
        // - Defer community_weight materialization until after the first move pass.
        // - Defer primaryid_2_nodeid materialization until aggregation, where NODE(...) first needs it.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = s.id
        }

        // ------------------------------------------------------------
        // Section 3: Local moving iterations (Louvain core)
        // Repeatedly move nodes to neighboring communities that improve ΔQ.
        // Stop when no node moves or max_iter is reached.
        // ------------------------------------------------------------
        IF max_iter > 0 THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
            // In the singleton phase, community_id equals node id. Store each undirected
            // edge only once on the smaller endpoint and mirror-read it when needed.
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE edge_to_target DOUBLE = 0.0
            VALUE delta DOUBLE = 0.0
            IF s.id <= t.id THEN {
              SET edge_to_target = s.@node_community_weight.get(t.@community_id)
            } ELSE {
              SET edge_to_target = t.@node_community_weight.get(s.@community_id)
            }
            SET delta = edge_to_target
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight * (s.@node_weight - t.@node_weight)

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET s.@community_id = move.community_id
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        } ELSE {
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        }

        // 3.2 Later iterations reuse the generic community_weight-based formula.
        WHILE iter < max_iter AND @new_active THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.2.1 Accumulate, for each node, total edge weight to each neighbor community.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // 3.2.2 Build move candidates with modularity gain ΔQ under resolution γ.
          // Odd/even ordering reduces update conflicts in one pass.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight *
                (@community_weight.get(s.@community_id)
                 - @community_weight.get(t.@community_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          // 3.2.3 Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
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
        LOG_DEBUG("louvain_inner done, iter = ", iter)

        // ------------------------------------------------------------
        // Section 4: Build coarse inter-community edge weights
        // Accumulate edge weights between resulting communities for next layer.
        // For self-loop in input, count half to keep undirected semantics consistent.
        // ------------------------------------------------------------
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
        }

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
        SET @primaryid_2_nodeid.clear()

        // ------------------------------------------------------------
        // Section 5: Compute modularity Q(γ) for current partition
        // ------------------------------------------------------------
        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c (= @community_weight.get(c))
        // m:   total edge weight (= @total_weight)
        // The bucket owner is the node whose s.id equals the community label;
        // s.@community_id may differ if the owner moved in a later iteration.
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE e_c = s.@community_edge_weight.get(s.id)
            VALUE a_c = @community_weight.get(s.id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("louvain modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)
        SET @community_weight.clear()

        // ------------------------------------------------------------
        // Section 6: Export coarse graph and original-node backtracking table
        // - edges: community-level weighted edges for next outer layer
        // - nodes: keep every original node id and update its current community id
        //          after the first layer
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT s.id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          EXPORT s.id AS id, s.@community_id AS cid INTO nodes
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_feature_inner(max_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // ------------------------------------------------------------
        // Section 0: Working state and aggregators used by one Louvain layer
        // ------------------------------------------------------------
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
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET
        // ------------------------------------------------------------
        // Section 1: Graph statistics initialization
        // - total_weight: total edge weight m (undirected)
        // - node_weight: weighted degree of each node
        // Note: MATCH (s)-[e]-(t) scans each undirected edge twice, so divide by 2.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }
        FINALLY {
          SET active_set = s
        }
        SET @total_weight = @total_weight / 2
        LOG_DEBUG("Iter start, total_weight = ", @total_weight)

        // ------------------------------------------------------------
        // Section 2: Initial partition setup
        // - Start from singleton communities: community_id = node id.
        // - Defer community_weight materialization until after the first move pass.
        // - Defer primaryid_2_nodeid materialization until aggregation, where NODE(...) first needs it.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = s.id
        }

        // ------------------------------------------------------------
        // Section 3: Local moving iterations (Louvain core)
        // Repeatedly move nodes to neighboring communities that improve ΔQ.
        // Stop when no node moves or max_iter is reached.
        // ------------------------------------------------------------
        IF max_iter > 0 THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
            // In the singleton phase, community_id equals node id. Store each undirected
            // edge only once on the smaller endpoint and mirror-read it when needed.
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE edge_to_target DOUBLE = 0.0
            VALUE delta DOUBLE = 0.0
            IF s.id <= t.id THEN {
              SET edge_to_target = s.@node_community_weight.get(t.@community_id)
            } ELSE {
              SET edge_to_target = t.@node_community_weight.get(s.@community_id)
            }
            SET delta = edge_to_target
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight * (s.@node_weight - t.@node_weight)

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET s.@community_id = move.community_id
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        } ELSE {
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
          }
        }

        // 3.2 Later iterations reuse the generic community_weight-based formula.
        WHILE iter < max_iter AND @new_active THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.2.1 Accumulate, for each node, total edge weight to each neighbor community.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // 3.2.2 Build move candidates with modularity gain ΔQ under resolution γ.
          // Odd/even ordering reduces update conflicts in one pass.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight *
                (@community_weight.get(s.@community_id)
                 - @community_weight.get(t.@community_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id
            }
          }

          // 3.2.3 Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
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
        LOG_DEBUG("louvain_inner done, iter = ", iter)

        // ------------------------------------------------------------
        // Section 4: Build coarse inter-community edge weights
        // Accumulate edge weights between resulting communities for next layer.
        // For self-loop in input, count half to keep undirected semantics consistent.
        // ------------------------------------------------------------
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
        }

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
        SET @primaryid_2_nodeid.clear()

        // ------------------------------------------------------------
        // Section 5: Build node -> community mapping for backtracking
        // This includes all nodes (including isolated ones), so upper layers can
        // propagate original-node community ids.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET @node2_community_id += TUPLE(s.id, s.@community_id)
        }

        // ------------------------------------------------------------
        // Section 6: Compute modularity Q(γ) for current partition
        // ------------------------------------------------------------
        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c (= @community_weight.get(c))
        // m:   total edge weight (= @total_weight)
        // The bucket owner is the node whose s.id equals the community label;
        // s.@community_id may differ if the owner moved in a later iteration.
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE e_c = s.@community_edge_weight.get(s.id)
            VALUE a_c = @community_weight.get(s.id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("louvain modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)
        SET @community_weight.clear()

        // ------------------------------------------------------------
        // Section 7: Export coarse graph and original-node backtracking table
        // - edges: community-level weighted edges for next outer layer
        // - nodes: keep every original node id and update its current community via
        //          one-step mapping node2_community_id.get(s.cid)
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT s.id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          EXPORT s.id AS id, @node2_community_id.get(s.cid) AS cid INTO nodes
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_algo_louvain_full_test_analytic_feature_g
      CALL louvain_analytic_feature_outer(6, 6, 1.0) RETURN count(DISTINCT community_id) AS community_cnt
      """
    Then the result should be, in any order:
      | community_cnt |
      | 3             |
    And drop the procedure "louvain_analytic_feature_import_graph"
    And drop the procedure "louvain_analytic_feature_outer"
    And drop the procedure "louvain_analytic_feature_initial_inner"
    And drop the procedure "louvain_analytic_feature_inner"
    And drop the graph "#dist_algo_louvain_full_test_analytic_feature_g"
    And drop the graph "algo_louvain_full_test_analytic_feature_g"
    And drop the graph type "louvain_work_analytic_feature_gt"
    And drop the graph type "algo_louvain_full_test_analytic_feature_gt"

  Scenario: Louvain analytic implementation support element_id community ids without primaryid to nodeid map
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS algo_louvain_full_test_analytic_eid_gt {
      NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
      EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS algo_louvain_full_test_analytic_eid_g algo_louvain_full_test_analytic_eid_gt
      """
    Then the execution should be successful
    And graph "algo_louvain_full_test_analytic_eid_g" should be ready to use
    When executing graph query:
      """
      USE algo_louvain_full_test_analytic_eid_g
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
      (1,11,1),(3,14,1),
      (0,6,2),(0,8,2),
      (5,11,2),(5,13,2),
      (10,1,2),(10,3,2)
      USE algo_louvain_full_test_analytic_eid_g
      FOR r IN t
      MATCH (a@Person{id:r.src}),(b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_algo_louvain_full_test_analytic_eid_g
      TYPED algo_louvain_full_test_analytic_eid_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_algo_louvain_full_test_analytic_eid_g IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=algo_louvain_full_test_analytic_eid_g&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS louvain_work_analytic_eid_gt AS {
      NODE TYPE community (
      LABEL community {
      id INT PRIMARY KEY,
      cid INT
      }
      ),
      EDGE TYPE edge (community)~[:edge{
      weight DOUBLE,
      MULTIEDGE KEY()
      }]~(community)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_eid_import_graph(nodes TABLE, edges TABLE) AS {
      IMPORT INTO GRAPH {
      NODE (v@community {id:id, cid:cid}) FROM nodes,
      EDGE (id:src)~[e@edge{weight:weight}]~(id:dst) FROM edges
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_eid_outer(max_layer INT, max_iter INT, resolution DOUBLE) RETURNS (node_id INT, community_id INT) AS {
        GRAPH g TYPED louvain_work_analytic_eid_gt PARTITION BY DEFAULT
        TABLE nodes TYPED TABLE {id INT, cid INT} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src INT, dst INT, weight DOUBLE} PARTITION BY DEFAULT
        VALUE i = 0

        WHILE (i < max_layer) THEN {
          LOG_DEBUG("----------- louvain_outer layer start, i = ", i)
          IF (i = 0) THEN {
            CALL louvain_analytic_eid_initial_inner(max_iter, resolution, nodes, edges) FINISH
          } ELSE {
            USE g
            CALL louvain_analytic_eid_inner(max_iter, resolution, nodes, edges) FINISH
          }

          IF (i <> max_layer - 1) THEN {
            SET g.clear()
            USE g
            CALL louvain_analytic_eid_import_graph(nodes, edges) FINISH
            PER PARTITION (nodes_part) OF nodes {
              SET nodes_part.clear()
            }
            PER PARTITION (edges_part) OF edges {
              SET edges_part.clear()
            }
          }
          LOG_DEBUG("----------- louvain_outer layer finish, i = ", i)
          SET i = i + 1
        }

        PER PARTITION (nodes_part) OF nodes {
          FOR r IN nodes_part
          RETURN r.id AS node_id, r.cid AS community_id
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_eid_initial_inner(max_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // ------------------------------------------------------------
        // Section 0: Working state and aggregators used by one Louvain layer
        // ------------------------------------------------------------
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE community_primary_id  SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC, community_primary_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET

        // ------------------------------------------------------------
        // Section 1: Graph statistics initialization
        // - total_weight: total edge weight m (undirected)
        // - node_weight: weighted degree of each node
        // Note: MATCH (s)-[e]-(t) scans each undirected edge twice, so divide by 2.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }
        FINALLY {
          SET active_set = s
        }
        SET @total_weight = @total_weight / 2
        LOG_DEBUG("Iter start, total_weight = ", @total_weight)

        // ------------------------------------------------------------
        // Section 2: Initial partition setup
        // - Start from singleton communities: community_id = element_id(s).
        // - Defer community_weight materialization until after the first move pass.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = element_id(s)
          SET s.@community_primary_id = s.id
        }

        // ------------------------------------------------------------
        // Section 3: Local moving iterations (Louvain core)
        // Repeatedly move nodes to neighboring communities that improve ΔQ.
        // Stop when no node moves or max_iter is reached.
        // ------------------------------------------------------------
        IF max_iter > 0 THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
            // In the singleton phase, community_id equals element_id(s). Store each
            // undirected edge only once on the smaller endpoint and mirror-read it when needed.
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE edge_to_target DOUBLE = 0.0
            VALUE delta DOUBLE = 0.0
            IF s.id <= t.id THEN {
              SET edge_to_target = s.@node_community_weight.get(t.@community_id)
            } ELSE {
              SET edge_to_target = t.@node_community_weight.get(s.@community_id)
            }
            SET delta = edge_to_target
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight * (s.@node_weight - t.@node_weight)

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id,
              community_primary_id: t.@community_primary_id
            }
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET s.@community_id = move.community_id
                SET s.@community_primary_id = move.community_primary_id
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_primary_id, s.@node_weight)
          }
        } ELSE {
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_primary_id, s.@node_weight)
          }
        }

        // 3.2 Later iterations reuse the generic community_weight-based formula.
        WHILE iter < max_iter AND @new_active THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.2.1 Accumulate, for each node, total edge weight to each neighbor community.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // 3.2.2 Build move candidates with modularity gain ΔQ under resolution γ.
          // Odd/even ordering reduces update conflicts in one pass.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight *
                (@community_weight.get(s.@community_primary_id)
                 - @community_weight.get(t.@community_primary_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id,
              community_primary_id: t.@community_primary_id
            }
          }

          // 3.2.3 Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET @community_weight += TUPLE(s.@community_primary_id, -s.@node_weight)
                SET s.@community_id = move.community_id
                SET s.@community_primary_id = move.community_primary_id
                SET @community_weight += TUPLE(s.@community_primary_id, s.@node_weight)
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }
        }
        LOG_DEBUG("louvain_inner done, iter = ", iter)

        // ------------------------------------------------------------
        // Section 4: Build coarse inter-community edge weights
        // Accumulate edge weights between resulting communities for next layer.
        // For self-loop in input, count half to keep undirected semantics consistent.
        // community_id stores the representative node element_id directly, so NODE(...)
        // can be addressed without a primary-id to node-id map.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        WHERE s.id <= t.id
        PER PATH {
          VALUE s_comm = s.@community_id
          VALUE t_comm = t.@community_id
          VALUE s_primary = s.@community_primary_id
          VALUE t_primary = t.@community_primary_id
          IF s.id = t.id THEN {
            SET NODE(s_comm).@community_edge_weight += TUPLE(s_primary, e.weight / 2)
          } ELSE {
            IF s_comm = t_comm THEN {
              SET NODE(s_comm).@community_edge_weight += TUPLE(s_primary, e.weight)
            } ELSE {
              SET NODE(s_comm).@community_edge_weight += TUPLE(t_primary, e.weight)
            }
          }
        }

        // ------------------------------------------------------------
        // Section 5: Compute modularity Q(γ) for current partition
        // ------------------------------------------------------------
        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c (= @community_weight.get(c))
        // m:   total edge weight (= @total_weight)
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE e_c = s.@community_edge_weight.get(s.id)
            VALUE a_c = @community_weight.get(s.id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("louvain modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)
        SET @community_weight.clear()

        // ------------------------------------------------------------
        // Section 6: Export coarse graph and original-node backtracking table
        // - edges: community-level weighted edges for next outer layer
        // - nodes: keep every original node id and update its current community id
        //          after the first layer
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT s.id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          EXPORT s.id AS id, s.@community_primary_id AS cid INTO nodes
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE louvain_analytic_eid_inner(max_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // ------------------------------------------------------------
        // Section 0: Working state and aggregators used by one Louvain layer
        // ------------------------------------------------------------
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE community_primary_id  SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC, community_primary_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE      node2_community_id    MapAgg<INT64, MaxAgg<INT64>>
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET
        // ------------------------------------------------------------
        // Section 1: Graph statistics initialization
        // - total_weight: total edge weight m (undirected)
        // - node_weight: weighted degree of each node
        // Note: MATCH (s)-[e]-(t) scans each undirected edge twice, so divide by 2.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        PER PATH {
          SET @total_weight += e.weight
          SET s.@node_weight += e.weight
        }
        FINALLY {
          SET active_set = s
        }
        SET @total_weight = @total_weight / 2
        LOG_DEBUG("Iter start, total_weight = ", @total_weight)

        // ------------------------------------------------------------
        // Section 2: Initial partition setup
        // - Start from singleton communities: community_id = element_id(s).
        // - Defer community_weight materialization until after the first move pass.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = element_id(s)
          SET s.@community_primary_id = s.id
        }

        // ------------------------------------------------------------
        // Section 3: Local moving iterations (Louvain core)
        // Repeatedly move nodes to neighboring communities that improve ΔQ.
        // Stop when no node moves or max_iter is reached.
        // ------------------------------------------------------------
        IF max_iter > 0 THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
            // In the singleton phase, community_id equals element_id(s). Store each
            // undirected edge only once on the smaller endpoint and mirror-read it when needed.
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE edge_to_target DOUBLE = 0.0
            VALUE delta DOUBLE = 0.0
            IF s.id <= t.id THEN {
              SET edge_to_target = s.@node_community_weight.get(t.@community_id)
            } ELSE {
              SET edge_to_target = t.@node_community_weight.get(s.@community_id)
            }
            SET delta = edge_to_target
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight * (s.@node_weight - t.@node_weight)

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id,
              community_primary_id: t.@community_primary_id
            }
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET s.@community_id = move.community_id
                SET s.@community_primary_id = move.community_primary_id
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_primary_id, s.@node_weight)
          }
        } ELSE {
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            SET @community_weight += TUPLE(s.@community_primary_id, s.@node_weight)
          }
        }

        // 3.2 Later iterations reuse the generic community_weight-based formula.
        WHILE iter < max_iter AND @new_active THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.2.1 Accumulate, for each node, total edge weight to each neighbor community.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // 3.2.2 Build move candidates with modularity gain ΔQ under resolution γ.
          // Odd/even ordering reduces update conflicts in one pass.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND ((s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1))
          PER PATH {
            VALUE delta = s.@node_community_weight.get(t.@community_id)
              - s.@node_community_weight.get(s.@community_id)
              + (resolution / @total_weight) * s.@node_weight *
                (@community_weight.get(s.@community_primary_id)
                 - @community_weight.get(t.@community_primary_id))

            SET s.@best_move += RECORD {
              delta_q: delta,
              community_id: t.@community_id,
              community_primary_id: t.@community_primary_id
            }
          }

          // 3.2.3 Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @new_active += true
                SET @community_weight += TUPLE(s.@community_primary_id, -s.@node_weight)
                SET s.@community_id = move.community_id
                SET s.@community_primary_id = move.community_primary_id
                SET @community_weight += TUPLE(s.@community_primary_id, s.@node_weight)
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }
        }
        LOG_DEBUG("louvain_inner done, iter = ", iter)

        // ------------------------------------------------------------
        // Section 4: Build coarse inter-community edge weights
        // Accumulate edge weights between resulting communities for next layer.
        // For self-loop in input, count half to keep undirected semantics consistent.
        // community_id stores the representative node element_id directly, so NODE(...)
        // can be addressed without a primary-id to node-id map.
        // ------------------------------------------------------------
        MATCH (s)-[e]-(t)
        WHERE s.id <= t.id
        PER PATH {
          VALUE s_comm = s.@community_id
          VALUE t_comm = t.@community_id
          VALUE s_primary = s.@community_primary_id
          VALUE t_primary = t.@community_primary_id
          IF s.id = t.id THEN {
            SET NODE(s_comm).@community_edge_weight += TUPLE(s_primary, e.weight / 2)
          } ELSE {
            IF s_comm = t_comm THEN {
              SET NODE(s_comm).@community_edge_weight += TUPLE(s_primary, e.weight)
            } ELSE {
              SET NODE(s_comm).@community_edge_weight += TUPLE(t_primary, e.weight)
            }
          }
        }

        // ------------------------------------------------------------
        // Section 5: Build node -> community mapping for backtracking
        // This includes all nodes (including isolated ones), so upper layers can
        // propagate original-node community ids.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET @node2_community_id += TUPLE(s.id, s.@community_primary_id)
        }

        // ------------------------------------------------------------
        // Section 6: Compute modularity Q(γ) for current partition
        // ------------------------------------------------------------
        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c (= @community_weight.get(c))
        // m:   total edge weight (= @total_weight)
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE e_c = s.@community_edge_weight.get(s.id)
            VALUE a_c = @community_weight.get(s.id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("louvain modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)
        SET @community_weight.clear()

        // ------------------------------------------------------------
        // Section 7: Export coarse graph and original-node backtracking table
        // - edges: community-level weighted edges for next outer layer
        // - nodes: keep every original node id and update its current community via
        //          one-step mapping node2_community_id.get(s.cid)
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT s.id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          EXPORT s.id AS id, @node2_community_id.get(s.cid) AS cid INTO nodes
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_algo_louvain_full_test_analytic_eid_g
      CALL louvain_analytic_eid_outer(6, 6, 1.0) RETURN count(DISTINCT community_id) AS community_cnt
      """
    Then the result should be, in any order:
      | community_cnt |
      | 3             |
    And drop the procedure "louvain_analytic_eid_import_graph"
    And drop the procedure "louvain_analytic_eid_outer"
    And drop the procedure "louvain_analytic_eid_initial_inner"
    And drop the procedure "louvain_analytic_eid_inner"
    And drop the graph "#dist_algo_louvain_full_test_analytic_eid_g"
    And drop the graph "algo_louvain_full_test_analytic_eid_g"
    And drop the graph type "louvain_work_analytic_eid_gt"
    And drop the graph type "algo_louvain_full_test_analytic_eid_gt"
