# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Leiden on synthetic dataset

  Scenario: Leiden analytic implementation on synthetic dataset
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS algo_leiden_cora_analytic_feature_gt {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE DEFAULT 1.0, MULTIEDGE KEY()} ]~(Person)
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_algo_leiden_cora_analytic_feature_g
      TYPED algo_leiden_cora_analytic_feature_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_algo_leiden_cora_analytic_feature_g {
        FILE node_file {f0 INT} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/leiden_synthetic/nodes.csv",
          AUTOGENERATE_COLUMN_NAMES:true
        }
        FILE edge_file {f0 INT, f1 INT, f2 DOUBLE} = DATAFILE {
          FORMAT:"csv",
          PATH:"file://${TEST_DIR}/dataset/leiden_synthetic/edges.csv",
          AUTOGENERATE_COLUMN_NAMES:true
        }

        IMPORT INTO GRAPH {
          NODE (v@Person{id:f0}) FROM node_file,
          EDGE (id:f0)~[@KNOWS{weight:f2}]~(id:f1) FROM edge_file
        } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true, SKIP_DANGLING_EDGES:true}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS leiden_cora_work_analytic_feature_gt AS {
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
      CREATE OR REPLACE PROCEDURE leiden_import_graph(nodes TABLE, edges TABLE) AS {
        IMPORT INTO GRAPH {
          NODE (v@community {id:id, cid:cid}) FROM nodes,
          EDGE (id:src)~[e@edge{weight:weight}]~(id:dst) FROM edges
        } OPTIONS {PRIMARY_KEY_AS_NODE_ID:true}
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE leiden_outer(max_layer INT, max_iter INT, refine_iter INT, resolution DOUBLE) RETURNS (node_id INT, community_id INT) AS {
        GRAPH g TYPED leiden_cora_work_analytic_feature_gt PARTITION BY DEFAULT
        TABLE nodes TYPED TABLE {id INT, cid INT} PARTITION BY DEFAULT
        TABLE edges TYPED TABLE {src INT, dst INT, weight DOUBLE} PARTITION BY DEFAULT
        VALUE i = 0

        WHILE (i < max_layer) THEN {
          LOG_DEBUG("----------- leiden_outer layer start, i = ", i)
          IF (i = 0) THEN {
            CALL leiden_initial_inner(max_iter, refine_iter, resolution, nodes, edges) FINISH
          } ELSE {
            USE g
            CALL leiden_inner(max_iter, refine_iter, resolution, nodes, edges) FINISH
          }

          IF (i <> max_layer - 1) THEN {
            SET g.clear()
            // LOG_INFO("Create Graph from NodeTable: ", size(nodes), " EdgeTable: ", size(edges))
            USE g
            CALL leiden_import_graph(nodes, edges) FINISH
            PER PARTITION (nodes_part) OF nodes {
              SET nodes_part.clear()
            }
            PER PARTITION (edges_part) OF edges {
              SET edges_part.clear()
            }
          }
          LOG_DEBUG("----------- leiden_outer layer finish, i = ", i)
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
      CREATE OR REPLACE PROCEDURE leiden_initial_inner(max_iter INT, refine_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // Initial-layer Leiden inner procedure operating on the original graph directly.
        // Specializes the first local-moving iteration for singleton communities,
        // deferring community_weight build to after the first pass (PR #10493 pattern).
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE      local_moved_count     SumAgg<INT64> = 0
        VALUE      primaryid_2_nodeid    MapAgg<INT64, MaxAgg<INT64>>
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      macro_community_seen  SetAgg<INT64>
        VALUE      refined_community_seen SetAgg<INT64>
        NODE VALUE local_community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      local_modularity_q      SumAgg<DOUBLE> = 0
        VALUE      local_community_cnt     SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET

        // Refinement phase variables
        NODE VALUE refined_community_id          SumAgg<INT64> = 0
        NODE VALUE refined_prev_community_id     SumAgg<INT64> = -1
        NODE VALUE refined_seed_eligible         OrAgg = false
        NODE VALUE node_macro_internal_weight    SumAgg<DOUBLE> = 0
        VALUE      refined_community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      refined_community_size        MapAgg<INT64, SumAgg<INT64>>
        VALUE      refined_community_cut_to_rest MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      refined_community_macro_weight MapAgg<INT64, MaxAgg<DOUBLE>>
        NODE VALUE node_refined_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE refined_best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      refine_active                 OrAgg = true
        VALUE      refine_iter_count = 0
        VALUE      refine_moved_count            SumAgg<INT64> = 0

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
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = s.id
        }

        // ============================================================
        // Phase 1: Local Moving
        // ============================================================
        IF max_iter > 0 THEN {
          LOG_DEBUG("----------- Local Moving iter == ", iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1
          SET @local_moved_count = 0

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          // Use half-edge accumulation: store each undirected edge only once on the
          // smaller endpoint and mirror-read it when needed.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
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
                SET @local_moved_count += 1
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          // Build community_weight after first pass
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
          LOG_DEBUG("----------- Local Moving iter == ", iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1
          SET @local_moved_count = 0

          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

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

          // Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                // LOG_DEBUG("move node ", s.id, " from ", s.@community_id, " to ", move.community_id, " delta_q=", move.delta_q)
                SET @new_active += true
                SET @community_weight += TUPLE(s.@community_id, -s.@node_weight)
                SET s.@community_id = move.community_id
                SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
                SET @local_moved_count += 1
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }
          // LOG_INFO("Local moving iter moved nodes = ", @local_moved_count)
        }
        LOG_INFO("Local moving done, iteration = ", iter)
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @macro_community_seen += s.@community_id
        }

        // Build primaryid_2_nodeid (needed for modularity logging and Phase 3)
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
        }

        // Log modularity right before refinement starts, based on local-moving partition.
        MATCH (s)-[e]-(t)
        WHERE s.id <= t.id
        PER PATH {
          VALUE s_comm = s.@community_id
          VALUE t_comm = t.@community_id
          VALUE node_comm = @primaryid_2_nodeid.get(s_comm)
          IF s.id = t.id THEN {
            SET NODE(node_comm).@local_community_edge_weight += TUPLE(s_comm, e.weight / 2)
          } ELSE {
            IF s_comm = t_comm THEN {
              SET NODE(node_comm).@local_community_edge_weight += TUPLE(s_comm, e.weight)
            } ELSE {
              SET NODE(node_comm).@local_community_edge_weight += TUPLE(t_comm, e.weight)
            }
          }
        }
        MATCH (s)
        PER NODE (s) {
          IF s.@local_community_edge_weight.size() <> 0 THEN {
            VALUE local_community_id = s.@community_id
            VALUE a_c = @community_weight.get(local_community_id)
            VALUE e_c = s.@local_community_edge_weight.get(local_community_id)
            SET @local_modularity_q += e_c / @total_weight
              - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @local_community_cnt += 1
            SET s.@local_community_edge_weight.clear()
          }
        }
        LOG_INFO("Local moving modularity Q = ", @local_modularity_q, ", community_cnt = ", @local_community_cnt)
        // LOG_INFO("Refinement start, macro community count = ", length(@macro_community_seen))

        // ============================================================
        // Phase 2: Refinement (Leiden-specific)
        // Start from singletons, merge only within same macro community.
        // Only process active nodes (s.@node_weight > 0).
        // ============================================================
        MATCH (s)
        WHERE s.@node_weight > 0
        PER NODE (s) {
          SET s.@refined_community_id = s.id
          SET s.@refined_prev_community_id = -1
          SET @refined_community_weight += TUPLE(s.id, s.@node_weight)
          SET @refined_community_size += TUPLE(s.id, 1)
        }

        // Leiden sufficient connectivity gate for initial refinement seeds:
        // E({v}, C\{v}) >= gamma * ||v|| * ||C\{v}||
        MATCH (s)-[e]-(t)
        WHERE s.@community_id = t.@community_id
        PER PATH {
          IF s.id <> t.id THEN {
            SET s.@node_macro_internal_weight += e.weight
          }
        }

        MATCH (s)
        WHERE s.@node_weight > 0
        PER NODE (s) {
          VALUE macro_rest_weight = @community_weight.get(s.@community_id) - s.@node_weight
          IF s.@node_macro_internal_weight >= (resolution / @total_weight) * s.@node_weight * macro_rest_weight THEN {
            SET s.@refined_seed_eligible += true
          }
        }

        SET @refine_active = true
        WHILE refine_iter > 0 AND @refine_active AND refine_iter_count < refine_iter THEN {
          LOG_DEBUG("----------- Refinement iter == ", refine_iter_count, " -----------")
          SET @refine_active = false
          SET refine_iter_count = refine_iter_count + 1
          SET @refine_moved_count = 0
          SET @refined_community_cut_to_rest.clear()
          SET @refined_community_macro_weight.clear()

          // Only consider s and t in the same macro community
          MATCH (s)-[e]-(t)
          WHERE s.@community_id = t.@community_id
          PER PATH {
            SET s.@node_refined_community_weight += TUPLE(t.@refined_community_id, e.weight)
            IF s.@refined_community_id <> t.@refined_community_id THEN {
              // Community-level target gate term: E(D, S\D), where S is macro community.
              SET @refined_community_cut_to_rest += TUPLE(s.@refined_community_id, e.weight)
            }
          }

          MATCH (s)
          WHERE s.@node_weight > 0
          PER NODE (s) {
            SET @refined_community_macro_weight += TUPLE(
              s.@refined_community_id,
              @community_weight.get(s.@community_id)
            )
          }

          // Candidate pruning follows local moving style: keep one directed side
          // per iteration by node id ordering, while delta uses full snapshot stats.
          MATCH (s)-[e]-(t)
          WHERE s.@community_id = t.@community_id
            AND s.@refined_seed_eligible
            AND ((s.id < t.id AND refine_iter_count % 2 = 0)
              OR (s.id > t.id AND refine_iter_count % 2 = 1))
          PER PATH {
            IF s.@refined_community_id <> t.@refined_community_id THEN {
              VALUE target_refined_community_id = t.@refined_community_id

              // Leiden target-community gate:
              // E(D, S\D) >= gamma * ||D|| * ||S\D||, where S is macro community.
              VALUE target_weight = @refined_community_weight.get(target_refined_community_id)
              VALUE target_cut_to_rest = @refined_community_cut_to_rest.get(target_refined_community_id)
              VALUE target_macro_weight = @refined_community_macro_weight.get(target_refined_community_id)

              IF target_cut_to_rest >= (resolution / @total_weight) * target_weight
                * (target_macro_weight - target_weight) THEN {
                VALUE edge_to_target = s.@node_refined_community_weight.get(target_refined_community_id)
                VALUE delta = edge_to_target
                  - s.@node_refined_community_weight.get(s.@refined_community_id)
                  + (resolution / @total_weight) * s.@node_weight *
                    (@refined_community_weight.get(s.@refined_community_id)
                      - target_weight)

                SET s.@refined_best_move += RECORD {
                  delta_q: delta,
                  community_id: target_refined_community_id
                }
              }
            }
          }

          MATCH (s)
          WHERE s.@node_weight > 0
          PER NODE (s) {
            VALUE move_list = s.@refined_best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @refine_active += true
                SET @refined_community_size += TUPLE(s.@refined_community_id, -1)
                SET @refined_community_weight += TUPLE(s.@refined_community_id, -s.@node_weight)
                SET s.@refined_prev_community_id = s.@refined_community_id
                SET s.@refined_community_id = move.community_id
                SET @refined_community_size += TUPLE(s.@refined_community_id, 1)
                SET @refined_community_weight += TUPLE(s.@refined_community_id, s.@node_weight)
                SET @refine_moved_count += 1
              }
            }
            SET s.@node_refined_community_weight.clear()
            SET s.@refined_best_move.clear()
          }
          LOG_INFO("Refinement iter moved nodes = ", @refine_moved_count)
        }
        LOG_INFO("Refinement done, iteration = ", refine_iter_count)

        MATCH (s)
        WHERE s.@node_weight > 0
        PER NODE (s) {
          SET @refined_community_seen += s.@refined_community_id
        }
        LOG_INFO(
          "Refinement adjusted community count from ", length(@macro_community_seen), " to ", length(@refined_community_seen)
        )
        // ============================================================
        // Phase 3: Aggregation (based on REFINED communities, not macro)
        // This is the key difference from Louvain's aggregation.
        // ============================================================
        MATCH (s)-[e]-(t)
        WHERE s.id <= t.id
        PER PATH {
          VALUE s_comm = s.@community_id
          VALUE t_comm = t.@community_id
          VALUE node_comm = @primaryid_2_nodeid.get(s_comm)
          IF refine_iter > 0 THEN {
            SET s_comm = s.@refined_community_id
            SET t_comm = t.@refined_community_id
            SET node_comm = @primaryid_2_nodeid.get(s_comm)
          }
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

        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c
        // m:   total edge weight (= @total_weight)
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE modularity_community_id = s.@community_id
            VALUE a_c = @community_weight.get(modularity_community_id)
            VALUE e_c DOUBLE = 0.0
            IF refine_iter > 0 THEN {
              SET modularity_community_id = s.@refined_community_id
              SET a_c = @refined_community_weight.get(modularity_community_id)
            }
            SET e_c = s.@community_edge_weight.get(modularity_community_id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("leiden modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)

        // ------------------------------------------------------------
        // Export: layer 0 — cid is directly the community assignment,
        // no backtracking lookup needed.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE export_community_id = s.@community_id
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            IF refine_iter > 0 THEN {
              SET export_community_id = s.@refined_community_id
            }
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT export_community_id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          IF refine_iter > 0 THEN {
            EXPORT s.id AS id, s.@refined_community_id AS cid INTO nodes
          } ELSE {
            EXPORT s.id AS id, s.@community_id AS cid INTO nodes
          }
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE OR REPLACE PROCEDURE leiden_inner(max_iter INT, refine_iter INT, resolution DOUBLE, nodes TABLE, edges TABLE) AS {
        // This is a pragmatic Leiden-style variant for the graph-variable runtime.
        // It keeps one persistent cid per node for cross-layer backtracking, while
        // refinement is used to build the next coarse graph inside each macro community.
        VALUE      total_weight          SumAgg<DOUBLE> = 0
        VALUE      community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE node_weight           SumAgg<DOUBLE> = 0
        NODE VALUE node_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE community_id          SumAgg<INT64> = 0
        NODE VALUE best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      new_active            OrAgg = true
        VALUE      iter = 0
        VALUE      local_moved_count     SumAgg<INT64> = 0
        VALUE      primaryid_2_nodeid    MapAgg<INT64, MaxAgg<INT64>>
        VALUE      node2_community_id    MapAgg<INT64, MaxAgg<INT64>>
        NODE VALUE community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      modularity_q          SumAgg<DOUBLE> = 0
        VALUE      community_cnt         SumAgg<INT64> = 0
        VALUE      macro_community_seen  SetAgg<INT64>
        VALUE      refined_community_seen SetAgg<INT64>
        NODE VALUE local_community_edge_weight MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      local_modularity_q      SumAgg<DOUBLE> = 0
        VALUE      local_community_cnt     SumAgg<INT64> = 0
        VALUE      active_set            ACTIVE_SET

        // Refinement phase variables
        NODE VALUE refined_community_id          SumAgg<INT64> = 0
        NODE VALUE refined_prev_community_id     SumAgg<INT64> = -1
        NODE VALUE refined_seed_eligible         OrAgg = false
        NODE VALUE node_macro_internal_weight    SumAgg<DOUBLE> = 0
        VALUE      refined_community_weight      MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      refined_community_size        MapAgg<INT64, SumAgg<INT64>>
        VALUE      refined_community_cut_to_rest MapAgg<INT64, SumAgg<DOUBLE>>
        VALUE      refined_community_macro_weight MapAgg<INT64, MaxAgg<DOUBLE>>
        NODE VALUE node_refined_community_weight MapAgg<INT64, SumAgg<DOUBLE>>
        NODE VALUE refined_best_move             TopKAgg<1, delta_q DOUBLE DESC, community_id INT64 DESC>
        VALUE      refine_active                 OrAgg = true
        VALUE      refine_iter_count = 0
        VALUE      refine_moved_count            SumAgg<INT64> = 0

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
        // - Defer community_weight and primaryid_2_nodeid until needed.
        // ------------------------------------------------------------
        MATCH (s)
        PER NODE (s) {
          SET s.@community_id = s.id
        }

        // ============================================================
        // Phase 1: Local Moving
        // ============================================================
        IF max_iter > 0 THEN {
          LOG_DEBUG("----------- Local Moving iter == ", iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1
          SET @local_moved_count = 0

          // 3.1 First iteration on singleton communities.
          // community_weight(c) equals node_weight(c), so we avoid prebuilding the map.
          // Use half-edge accumulation: store each undirected edge only once on the
          // smaller endpoint and mirror-read it when needed.
          MATCH (s)-[e]-(t)
          WHERE s IN active_set AND s.id <= t.id
          PER PATH {
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
                SET @local_moved_count += 1
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }

          // Build community_weight after first pass
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
          LOG_DEBUG("----------- Local Moving iter == ", iter, " -----------")
          SET @new_active = false
          SET iter = iter + 1
          SET @local_moved_count = 0

          MATCH (s)-[e]-(t)
          WHERE s IN active_set
          PER PATH {
            SET s.@node_community_weight += TUPLE(t.@community_id, e.weight)
          }

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

          // Apply best positive move per node and refresh related states.
          MATCH (s)
          WHERE s IN active_set
          PER NODE (s) {
            VALUE move_list = s.@best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                // LOG_DEBUG("move node ", s.id, " from ", s.@community_id, " to ", move.community_id, " delta_q=", move.delta_q)
                SET @new_active += true
                SET @community_weight += TUPLE(s.@community_id, -s.@node_weight)
                SET s.@community_id = move.community_id
                SET @community_weight += TUPLE(s.@community_id, s.@node_weight)
                SET @local_moved_count += 1
              }
            }
            SET s.@node_community_weight.clear()
            SET s.@best_move.clear()
          }
          // LOG_INFO("Local moving iter moved nodes = ", @local_moved_count)
        }
        LOG_INFO("Local moving done, iteration = ", iter)
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @macro_community_seen += s.@community_id
        }

        // Build primaryid_2_nodeid (needed for modularity logging and Phase 3)
        MATCH (s)
        WHERE s IN active_set
        PER NODE (s) {
          SET @primaryid_2_nodeid += TUPLE(s.id, element_id(s))
        }

        // Log modularity right before refinement starts, based on local-moving partition.
        MATCH (s)-[e]-(t)
        WHERE s.id <= t.id
        PER PATH {
          VALUE s_comm = s.@community_id
          VALUE t_comm = t.@community_id
          VALUE node_comm = @primaryid_2_nodeid.get(s_comm)
          IF s.id = t.id THEN {
            SET NODE(node_comm).@local_community_edge_weight += TUPLE(s_comm, e.weight / 2)
          } ELSE {
            IF s_comm = t_comm THEN {
              SET NODE(node_comm).@local_community_edge_weight += TUPLE(s_comm, e.weight)
            } ELSE {
              SET NODE(node_comm).@local_community_edge_weight += TUPLE(t_comm, e.weight)
            }
          }
        }
        MATCH (s)
        PER NODE (s) {
          IF s.@local_community_edge_weight.size() <> 0 THEN {
            VALUE local_community_id = s.@community_id
            VALUE a_c = @community_weight.get(local_community_id)
            VALUE e_c = s.@local_community_edge_weight.get(local_community_id)
            SET @local_modularity_q += e_c / @total_weight
              - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @local_community_cnt += 1
            SET s.@local_community_edge_weight.clear()
          }
        }
        LOG_INFO("Local moving modularity Q = ", @local_modularity_q, ", community_cnt = ", @local_community_cnt)
        // LOG_INFO("Refinement start, macro community count = ", length(@macro_community_seen))

        // ============================================================
        // Phase 2: Refinement (Leiden-specific)
        // Start from singletons, merge only within same macro community.
        // Only process active nodes in current coarse graph (s.@node_weight > 0);
        // backtracking-only nodes have no incident edges here and must be excluded.
        // ============================================================
        MATCH (s)
        WHERE s.@node_weight > 0
        PER NODE (s) {
          SET s.@refined_community_id = s.id
          SET s.@refined_prev_community_id = -1
          SET @refined_community_weight += TUPLE(s.id, s.@node_weight)
          SET @refined_community_size += TUPLE(s.id, 1)
        }

        // Leiden sufficient connectivity gate for initial refinement seeds:
        // E({v}, C\{v}) >= gamma * ||v|| * ||C\{v}||
        MATCH (s)-[e]-(t)
        WHERE s.@community_id = t.@community_id
        PER PATH {
          IF s.id <> t.id THEN {
            SET s.@node_macro_internal_weight += e.weight
          }
        }

        MATCH (s)
        WHERE s.@node_weight > 0
        PER NODE (s) {
          VALUE macro_rest_weight = @community_weight.get(s.@community_id) - s.@node_weight
          IF s.@node_macro_internal_weight >= (resolution / @total_weight) * s.@node_weight * macro_rest_weight THEN {
            SET s.@refined_seed_eligible += true
          }
        }

        SET @refine_active = true
        WHILE refine_iter > 0 AND @refine_active AND refine_iter_count < refine_iter THEN {
          LOG_DEBUG("----------- Refinement iter == ", refine_iter_count, " -----------")
          SET @refine_active = false
          SET refine_iter_count = refine_iter_count + 1
          SET @refine_moved_count = 0
          SET @refined_community_cut_to_rest.clear()
          SET @refined_community_macro_weight.clear()

          // Only consider s and t in the same macro community
          MATCH (s)-[e]-(t)
          WHERE s.@community_id = t.@community_id
          PER PATH {
            SET s.@node_refined_community_weight += TUPLE(t.@refined_community_id, e.weight)
            IF s.@refined_community_id <> t.@refined_community_id THEN {
              // Community-level target gate term: E(D, S\D), where S is macro community.
              SET @refined_community_cut_to_rest += TUPLE(s.@refined_community_id, e.weight)
            }
          }

          MATCH (s)
          WHERE s.@node_weight > 0
          PER NODE (s) {
            SET @refined_community_macro_weight += TUPLE(
              s.@refined_community_id,
              @community_weight.get(s.@community_id)
            )
          }

          // Candidate pruning follows local moving style: keep one directed side
          // per iteration by node id ordering, while delta uses full snapshot stats.
          MATCH (s)-[e]-(t)
          WHERE s.@community_id = t.@community_id
            AND s.@refined_seed_eligible
            AND ((s.id < t.id AND refine_iter_count % 2 = 0)
              OR (s.id > t.id AND refine_iter_count % 2 = 1))
          PER PATH {
            IF s.@refined_community_id <> t.@refined_community_id THEN {
              VALUE target_refined_community_id = t.@refined_community_id

              // Leiden target-community gate:
              // E(D, S\D) >= gamma * ||D|| * ||S\D||, where S is macro community.
              VALUE target_weight = @refined_community_weight.get(target_refined_community_id)
              VALUE target_cut_to_rest = @refined_community_cut_to_rest.get(target_refined_community_id)
              VALUE target_macro_weight = @refined_community_macro_weight.get(target_refined_community_id)

              IF target_cut_to_rest >= (resolution / @total_weight) * target_weight
                * (target_macro_weight - target_weight) THEN {
                VALUE edge_to_target = s.@node_refined_community_weight.get(target_refined_community_id)
                VALUE delta = edge_to_target
                  - s.@node_refined_community_weight.get(s.@refined_community_id)
                  + (resolution / @total_weight) * s.@node_weight *
                    (@refined_community_weight.get(s.@refined_community_id)
                      - target_weight)

                SET s.@refined_best_move += RECORD {
                  delta_q: delta,
                  community_id: target_refined_community_id
                }
              }
            }
          }

          MATCH (s)
          WHERE s.@node_weight > 0
          PER NODE (s) {
            VALUE move_list = s.@refined_best_move
            IF length(move_list) <> 0 THEN {
              VALUE move = move_list[0]
              IF move.delta_q > 0 THEN {
                SET @refine_active += true
                SET @refined_community_size += TUPLE(s.@refined_community_id, -1)
                SET @refined_community_weight += TUPLE(s.@refined_community_id, -s.@node_weight)
                SET s.@refined_prev_community_id = s.@refined_community_id
                SET s.@refined_community_id = move.community_id
                SET @refined_community_size += TUPLE(s.@refined_community_id, 1)
                SET @refined_community_weight += TUPLE(s.@refined_community_id, s.@node_weight)
                SET @refine_moved_count += 1
              }
            }
            SET s.@node_refined_community_weight.clear()
            SET s.@refined_best_move.clear()
          }
          LOG_INFO("Refinement iter moved nodes = ", @refine_moved_count)
        }
        LOG_INFO("Refinement done, iteration = ", refine_iter_count)

        MATCH (s)
        WHERE s.@node_weight > 0
        PER NODE (s) {
          SET @refined_community_seen += s.@refined_community_id
        }
        LOG_INFO(
          "Refinement adjusted community count from ", length(@macro_community_seen), " to ", length(@refined_community_seen)
        )
        // ============================================================
        // Phase 3: Aggregation (based on REFINED communities, not macro)
        // This is the key difference from Louvain's aggregation.
        // Note: this implementation uses refined communities only to build the
        // next coarse graph. The carried cid and modularity logging below still
        // follow the macro partition from local moving.
        // ============================================================
        MATCH (s)-[e]-(t)
        WHERE s.id <= t.id
        PER PATH {
          VALUE s_comm = s.@community_id
          VALUE t_comm = t.@community_id
          VALUE node_comm = @primaryid_2_nodeid.get(s_comm)
          IF refine_iter > 0 THEN {
            SET s_comm = s.@refined_community_id
            SET t_comm = t.@refined_community_id
            SET node_comm = @primaryid_2_nodeid.get(s_comm)
          }
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
          VALUE node_export_community_id = s.@community_id
          IF refine_iter > 0 THEN {
            SET node_export_community_id = s.@refined_community_id
          }
          SET @node2_community_id += TUPLE(s.id, node_export_community_id)
        }

        // Compute modularity Q(γ) = Σ_c [ e_c/m - γ·(a_c/(2m))^2 ]
        // e_c: total internal edge weight of community c (each undirected edge counted once)
        // a_c: total degree weight of all nodes in community c
        // m:   total edge weight (= @total_weight)
        // Community representative nodes satisfy s.id = selected community id.
        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE modularity_community_id = s.@community_id
            VALUE a_c = @community_weight.get(modularity_community_id)
            VALUE e_c DOUBLE = 0.0
            IF refine_iter > 0 THEN {
              SET modularity_community_id = s.@refined_community_id
              SET a_c = @refined_community_weight.get(modularity_community_id)
            }
            SET e_c = s.@community_edge_weight.get(modularity_community_id)
            SET @modularity_q += e_c / @total_weight - resolution * (a_c / (2.0 * @total_weight)) * (a_c / (2.0 * @total_weight))
            SET @community_cnt += 1
          }
        }
        LOG_INFO("leiden modularity Q = ", @modularity_q, ", community_cnt = ", @community_cnt)

        MATCH (s)
        PER NODE (s) {
          IF s.@community_edge_weight.size() <> 0 THEN {
            VALUE community_edge_weight_list = s.@community_edge_weight
            VALUE export_community_id = s.@community_id
            VALUE i = 0
            VALUE list_size = size(community_edge_weight_list)
            IF refine_iter > 0 THEN {
              SET export_community_id = s.@refined_community_id
            }
            WHILE (i < list_size) THEN {
              VALUE r = community_edge_weight_list[i]
              EXPORT export_community_id AS src, r._0 AS dst, r._1 AS weight INTO edges
              SET i = i + 1
            }
          }
          // cid keeps one-step backtracking mapping to the partition used to
          // build next-layer coarse nodes (macro without refinement, refined with refinement).
          EXPORT s.id AS id, @node2_community_id.get(s.cid) AS cid INTO nodes
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #dist_algo_leiden_cora_analytic_feature_g
      CALL leiden_outer(4, 25, 1, 1.0) RETURN count(DISTINCT community_id) AS community_cnt
      """
    Then the execution should be successful
    And drop the procedure "leiden_import_graph"
    And drop the procedure "leiden_outer"
    And drop the procedure "leiden_initial_inner"
    And drop the procedure "leiden_inner"
    And drop the graph "#dist_algo_leiden_cora_analytic_feature_g"
    And drop the graph type "leiden_cora_work_analytic_feature_gt"
    And drop the graph type "algo_leiden_cora_analytic_feature_gt"
