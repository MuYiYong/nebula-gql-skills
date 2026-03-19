# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: FastRP

  Scenario: FastRP
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS fastrp_gt AS {
        NODE TYPE fr_node (LABEL fr_node {id INT PRIMARY KEY}),
        EDGE TYPE fr_edge (fr_node)~[LABEL fr_edge {MULTIEDGE KEY()}]~(fr_node)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #fastrp_g TYPED fastrp_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #fastrp_g TYPED fastrp_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #fastrp_g IMPORT INTO GRAPH {
        NODE (v@fr_node{id: id}) FROM DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/fastrp/fastrp_nodes.csv"
        },
        EDGE (id:src_id)~[e@fr_edge{}]~(id:dst_id) FROM DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/fastrp/fastrp_edges.csv"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE fastRP(
        iteration_weights LIST<DOUBLE>,
        beta DOUBLE,
        embedding_dimension INT64,
          sampling_constant INT64 DEFAULT 3,
          random_seed INT64 DEFAULT 42
      ) RETURNS (id INT64, embedding LIST<DOUBLE>) AS {
          NODE VALUE embedding_arr        MapAgg<INT64, SumAgg<DOUBLE>>
          NODE VALUE final_embedding_arr  MapAgg<INT64, SumAgg<DOUBLE>>
          NODE VALUE final_embedding_list ListAgg<DOUBLE>
          NODE VALUE L                    SumAgg<DOUBLE> = 0.0
          NODE VALUE out_degree           SumAgg<INT64> = 0
          VALUE m                         SumAgg<DOUBLE> = 0.0

          // PRNG constants for a linear congruential generator: r = (r * mult + inc_v) % mod_v.
          // Using the same random_seed yields identical projections across runs.
          VALUE mod_v INT64 = 2147483647
          VALUE mult INT64  = 1664525
          VALUE inc_v INT64 = 1013904223
          // Sparse random projection for initialization:
          // - With prob p1: project to +√s (v1)
          // - With prob p2: project to -√s (v2)
          // - With prob (1 - p1 - p2): project to 0 (v3, for sparsity)
          VALUE p1 DOUBLE = 0.5 / sampling_constant
          VALUE p2 DOUBLE = p1
          VALUE v1 DOUBLE = sqrt(sampling_constant)
          VALUE v2 DOUBLE = -sqrt(sampling_constant)
          VALUE v3 DOUBLE = 0.0

          VALUE depth INT64 = 0
          VALUE max_depth INT64 = size(iteration_weights) - 1

          VALUE verts ACTIVE_SET

          // Row-oriented output table.
          TABLE embeddings_table TYPED TABLE {vid INT64, embedding LIST<DOUBLE>}

          MATCH (s)-[e]-(t)
          PER PATH {
              // Collect degree and edge count for normalization.
              SET s.@out_degree += 1
              SET @m += 1.0
          }
          FINALLY {
              SET verts = s
          }

          MATCH (s)
          WHERE s IN verts
          PER NODE (s) {
              VALUE base_val DOUBLE = s.@out_degree / @m

              // Initial node strength: (deg / m)^beta.
              SET s.@L = power(base_val, beta)
          }

          // Initialize embeddings by projecting each source node into its neighbors.
          MATCH (s)-[e]-(t)
          WHERE s IN verts
          PER PATH {
              VALUE act_inc INT64 = s.id + inc_v
              VALUE r INT64 = (act_inc + mult * random_seed) % mod_v
              VALUE mr DOUBLE = 0.0
              VALUE i INT64 = 0

              WHILE i < embedding_dimension THEN {
                  SET r = ((r * mult) + act_inc) % mod_v
                  SET mr = (r * 1.0) / mod_v

                  // Sparse random projection per dimension.
                  IF mr <= p1 THEN {
                      SET t.@embedding_arr += TUPLE(i, v1 * s.@L)
                  } ELSE {
                      IF mr <= (p1 + p2) THEN {
                          SET t.@embedding_arr += TUPLE(i, v2 * s.@L)
                      } ELSE {
                          SET t.@embedding_arr += TUPLE(i, v3 * s.@L)
                      }
                  }

                  SET i = i + 1
              }
          }

          WHILE depth <= max_depth THEN {
              MATCH (s)-[e]-(t)
              WHERE s IN verts
              PER PATH {
                  // Propagate embeddings to neighbors at current depth.
                  SET t.@embedding_arr += s.@embedding_arr
              }
              FINALLY {
                  SET verts = s
              }

              MATCH (t)
              WHERE t IN verts
              PER NODE (t) {
                  VALUE square_sum DOUBLE = 0.0
                  VALUE outv DOUBLE = t.@out_degree
                  VALUE idx INT64 = 0
                  VALUE embedding_list = t.@embedding_arr
                  VALUE i INT64 = 0
                  VALUE weight DOUBLE = iteration_weights[depth]

                  IF outv < 1.0 THEN {
                      SET outv = 1.0
                  }
                  WHILE idx < length(embedding_list) THEN {
                      VALUE pair = embedding_list[idx]
                      VALUE val DOUBLE = pair._1
                      VALUE base_val DOUBLE = val / outv
                      SET square_sum = square_sum + (base_val * base_val)
                      SET idx = idx + 1
                  }
                  SET square_sum = sqrt(square_sum)

                  IF square_sum > 0.0 THEN {
                      WHILE i < embedding_dimension THEN {
                          VALUE current_val DOUBLE = t.@embedding_arr.get(i)
                          VALUE val DOUBLE = current_val / outv / square_sum

                          // Accumulate weighted, normalized embedding for this depth.
                          SET t.@final_embedding_arr += TUPLE(i, val * weight)

                          // Update working embedding with normalized values.
                          SET t.@embedding_arr += TUPLE(i, -current_val)
                          SET t.@embedding_arr += TUPLE(i, val)

                          SET i = i + 1
                      }
                  }
              } // END PER NODE

              SET depth = depth + 1
          }


          MATCH (s)
          WHERE s IN verts
          PER NODE (s) {
              VALUE i INT64 = 0
              // Average over depths into a final embedding list.
              WHILE i < embedding_dimension THEN {
                  SET s.@final_embedding_list += (s.@final_embedding_arr.get(i) / (max_depth + 1))
                  SET i = i + 1
              }
              EXPORT s.id, s.@final_embedding_list INTO embeddings_table
          }

          FOR r IN embeddings_table
          RETURN r.vid AS id, transform(r.embedding, x -> round(x,5))AS embedding
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #fastrp_g
      CALL fastRP([1.0,0.5,0.25], -0.5, 4)
      RETURN id, embedding
      """
    Then the result should be, in any order:
      | id | embedding                                |
      | 6  | LIST[-0.57722,-0.03564,0.00092,0.06213]  |
      | 5  | LIST[-0.56361,-0.01248,0.14596,-0.00529] |
      | 3  | LIST[-0.56215,0.01227,0.14946,-0.03554]  |
      | 4  | LIST[-0.55761,0.01836,0.16216,-0.04786]  |
      | 7  | LIST[-0.57977,-0.00408,-0.01832,0.04049] |
      | 2  | LIST[-0.57428,0.0042,0.0769,-0.05473]    |
      | 1  | LIST[-0.57787,0.00422,0.0773,-0.01049]   |
      | 8  | LIST[-0.58156,-0.036,0.00091,0.01238]    |
    And drop the procedure "fastRP"
    And drop the graph "#fastrp_g"
    And drop the graph type "fastrp_gt"
