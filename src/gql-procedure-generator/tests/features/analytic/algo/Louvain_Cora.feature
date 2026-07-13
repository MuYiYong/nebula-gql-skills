# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Louvain on Cora dataset

  # Cora citation network dataset.
  # Node data comes from tests/dataset/cora/cora.content (only first column paper_id).
  # Edge data comes from tests/dataset/cora/cora.cites (src, dst).
  Scenario: Louvain graph variable implementation
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS algo_louvain_cora_test_gt {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE DEFAULT 1.0, MULTIEDGE KEY()} ]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #algo_louvain_cora_test_g algo_louvain_cora_test_gt
      """
    Then the execution should be successful
    And graph "#algo_louvain_cora_test_g" should be ready to use
    When executing graph query:
      """
      FILE node_file {f0 INT} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/cora/cora.content",
        AUTOGENERATE_COLUMN_NAMES:true,
        DELIMITER:"\t"
      }
      FILE edge_file {f0 INT, f1 INT} = DATAFILE {
        FORMAT:"csv",
        PATH:"file://${TEST_DIR}/dataset/cora/cora.cites",
        AUTOGENERATE_COLUMN_NAMES:true,
        DELIMITER:"\t"
      }
      USE #algo_louvain_cora_test_g IMPORT INTO GRAPH {
        NODE (v@Person{id:f0}) FROM node_file,
        EDGE (id:f0)~[@KNOWS{}]~(id:f1) FROM edge_file
      } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true, SKIP_DANGLING_EDGES:true}
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS louvain_cora_work_gt AS {
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
      CREATE OR REPLACE PROCEDURE louvain_cora_import_graph(nodes TABLE, edges TABLE) AS {
        IMPORT INTO GRAPH {
          NODE (v@community {id:id, cid:cid}) FROM nodes,
          EDGE (id:src)-[e@edge{weight:weight}]->(id:dst) FROM edges
        }
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE OR REPLACE PROCEDURE louvain_cora_outer(max_layer INT, max_iter INT, resolution DOUBLE) RETURNS (node_id INT, community_id INT) AS {
        GRAPH g TYPED louvain_cora_work_gt
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
        LOG_DEBUG("Create Graph from NodeTable: ", size(nodes), " EdgeTable", size(edges))

        USE g
        CALL louvain_cora_import_graph(nodes, edges) FINISH
        SET nodes.clear()
        SET edges.clear()

        WHILE (i < max_layer) THEN {
          LOG_DEBUG("----------- louvain_outer layer start, i = ", i)
          USE g
          CALL louvain_cora_inner(max_iter, resolution, nodes, edges) FINISH

          IF (i <> max_layer - 1) THEN {
            SET g.clear()
            LOG_DEBUG("Create Graph from NodeTable: ", size(nodes), " EdgeTable", size(edges))
            USE g
            CALL louvain_cora_import_graph(nodes, edges) FINISH
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
      CREATE OR REPLACE PROCEDURE louvain_cora_inner(max_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
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
        SET @total_weight = @total_weight / 2
        LOG_DEBUG("Iter start, total_weight = ", @total_weight)

        // ------------------------------------------------------------
        // Section 2: Initial partition setup
        // - Start from singleton communities: community_id = node id.
        // - Build map from primary id to internal node id for fast NODE(...) updates.
        // - Initialize community_weight with node degree sums.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
          SET s.@community_id = s.id
          SET @community_weight += TUPLE(s.id, s.@node_weight)
        }

        // ------------------------------------------------------------
        // Section 3: Local moving iterations (Louvain core)
        // Repeatedly move nodes to neighboring communities that improve ΔQ.
        // Stop when no node moves or max_iter is reached.
        // ------------------------------------------------------------
        WHILE iter < max_iter AND @new_active THEN {
          LOG_DEBUG("--------------- iter == ",iter)
          SET @new_active = false
          SET iter = iter + 1

          // 3.1 Accumulate, for each node, total edge weight to each neighbor community.
          MATCH (s)-[e]-(t)
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

          // 3.2 Build move candidates with modularity gain ΔQ under resolution γ.
          // Odd/even ordering reduces update conflicts in one pass.
          MATCH (s)-[e]-(t)
          WHERE (s.id < t.id AND iter % 2 = 0) OR (s.id > t.id AND iter % 2 = 1)
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
          // 3.3 Apply best positive move per node and refresh related states.
          MATCH (s)
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                LOG_DEBUG("move node ", s.id, " from ", s.@community_id, " to ", move.community_id, " delta_q=", move.delta_q)
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

        // ------------------------------------------------------------
        // Section 5: Build node -> community mapping for backtracking
        // This includes all nodes (including isolated ones), so upper layers can
        // propagate original-node community ids via s.cid.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET @node2_community_id += TUPLE(s.id, s.@community_id)
        }

        LOG_DEBUG("louvain_inner community_weight size = ", length(@community_weight))
        LOG_DEBUG("louvain_inner node2_community_id size = ", length(@node2_community_id))

        // ------------------------------------------------------------
        // Section 6: Compute modularity Q(γ) for current partition
        // ------------------------------------------------------------
        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c (= @community_weight.get(c))
        // m:   total edge weight (= @total_weight)
        // Community representative nodes satisfy s.id = s.@community_id
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE e_c = s.@community_edge_weight.get(s.@community_id)
            VALUE a_c = @community_weight.get(s.@community_id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("louvain modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)

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
      USE #algo_louvain_cora_test_g
      CALL louvain_cora_outer(4, 25, 1.0) RETURN count(DISTINCT community_id) AS community_cnt
      """
    Then the execution should be successful
    And drop the procedure "louvain_cora_import_graph"
    And drop the procedure "louvain_cora_outer"
    And drop the procedure "louvain_cora_inner"
    And drop the graph "#algo_louvain_cora_test_g"
    And drop the graph type "louvain_cora_work_gt"
    And drop the graph type "algo_louvain_cora_test_gt"
