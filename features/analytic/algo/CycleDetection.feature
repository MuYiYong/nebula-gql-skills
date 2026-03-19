# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Cycle Detection

  Scenario: Cycle Detection
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS cycle_detection_gt AS {
        NODE TYPE cd_node (LABEL cd_node {id INT PRIMARY KEY}),
        EDGE TYPE cd_edge (cd_node)-[LABEL cd_edge {MULTIEDGE KEY()}]->(cd_node)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #cycle_detection_g TYPED cycle_detection_gt
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #cycle_detection_g TYPED cycle_detection_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #cycle_detection_g IMPORT INTO GRAPH {
        NODE (v@cd_node{id: id}) FROM DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/cycle_detection/cycle_detection_nodes.csv"
        },
        EDGE (id:src_id)-[e@cd_edge{}]->(id:dst_id) FROM DATAFILE {
          FORMAT: "csv",
          PATH: "file://${TEST_DIR}/dataset/external_source/cycle_detection/cycle_detection_edges.csv"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE cycle_detection (depth INT64) RETURNS (cycle LIST<INT64>) AS {
        VALUE frontier ACTIVE_SET
        VALUE has_active OrAgg = true
        VALUE iter INT64 = 0

        TABLE cycles_table TYPED TABLE {cycle LIST<INT64>}

        NODE VALUE curr_list ListAgg<LIST<INT64>>
        NODE VALUE new_list ListAgg<LIST<INT64>>

        MATCH (s)
        PER NODE (s) {
          SET s.@curr_list = [[s.id]]
        }
        FINALLY {
          SET frontier = s
        }

        WHILE @has_active = true AND iter < depth THEN {
          SET @has_active = false

          MATCH (s)-[e]->(t)
          WHERE s IN frontier
          PER PATH {
            VALUE t_id INT64 = t.id
            VALUE curr_sequences LIST<LIST<INT64>> = s.@curr_list
            VALUE seq_idx INT64 = 0
            VALUE seq_count INT64 = length(curr_sequences)

            WHILE seq_idx < seq_count THEN {
              VALUE sequence LIST<INT64> = curr_sequences[seq_idx]
              VALUE t_is_min BOOL = true
              VALUE v_idx INT64 = 0
              VALUE seq_len INT64 = length(sequence)

              IF t_id = sequence[0] THEN {
                WHILE v_idx < seq_len THEN {
                  VALUE v_id INT64 = sequence[v_idx]
                  IF v_id < t_id THEN {
                    SET t_is_min = false
                    BREAK
                  }
                  SET v_idx = v_idx + 1
                }

                IF t_is_min = true THEN {
                    EXPORT sequence INTO cycles_table
                }
              } ELSE {
                VALUE contains_id BOOL = false
                VALUE c_idx INT64 = 0
                WHILE c_idx < seq_len THEN {
                  IF sequence[c_idx] = t_id THEN {
                    SET contains_id = true
                    BREAK
                  }
                  SET c_idx = c_idx + 1
                }

                IF contains_id = false THEN {
                  SET t.@new_list += (sequence || [t_id])
                }
              }

              SET seq_idx = seq_idx + 1
            }
          }
          PER NODE (s) {
            SET s.@curr_list = []
          }
          FINALLY {
            SET frontier = t
          }

          MATCH (t)
          WHERE t IN frontier
          PER NODE (t) {
            SET t.@curr_list = t.@new_list
            SET t.@new_list = []
          }

          MATCH (t)
          WHERE t IN frontier and t.@curr_list.size() > 0
          PER NODE (t) {
            SET @has_active += true
          }
          FINALLY {
            SET frontier = t
          }

          SET iter = iter + 1
        }

        FOR r IN cycles_table
        RETURN r.cycle AS cycle
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #cycle_detection_g
      CALL cycle_detection(10) RETURN *
      """
    Then the result should be, in any order:
      | cycle          |
      | LIST[3,4,5]    |
      | LIST[1,2,3]    |
      | LIST[6,7,8]    |
      | LIST[7,9,10]   |
      | LIST[7,8,9,10] |
    And drop the procedure "cycle_detection"
    And drop the graph "#cycle_detection_g"
    And drop the graph type "cycle_detection_gt"
