# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Distributed Graph Variable

  @non_tls
  Scenario: Distributed graph variable with aggregation computation
    # Setup graph type and base graph
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dgv_agg_type_001 {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS dgv_agg_base_001 TYPED dgv_agg_type_001
      """
    Then the execution should be successful
    And graph "dgv_agg_base_001" should be ready to use
    When executing graph query:
      """
      USE dgv_agg_base_001
      FOR i IN range(0, 9)
      INSERT (a@Person{id:i, name: 'person', age: 20 + i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edge_data {src, dst, weight} =
      (0, 1, 1.0), (0, 2, 2.0), (1, 2, 1.5),
      (2, 3, 2.5), (3, 4, 1.0), (4, 5, 3.0),
      (5, 6, 1.5), (6, 7, 2.0), (7, 8, 1.0),
      (8, 9, 2.5), (9, 0, 1.5), (1, 3, 2.0),
      (2, 4, 1.0), (3, 5, 2.5), (4, 6, 1.5)
      USE dgv_agg_base_001
      FOR r IN edge_data
      MATCH (a@Person{id:r.src}), (b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    # Define procedure for aggregation computation
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS dgv_proc_agg_001()
      RETURNS (id INT64, degree INT) AS {
        VALUE      total_edges     SumAgg<INT> = 0
        NODE VALUE degree          SumAgg<INT> = 0
        TABLE      result_table    TYPED TABLE {id INT64, degree INT}

        MATCH (s@Person)-[@KNOWS]-(t@Person)
        PER PATH {
          SET @total_edges += 1
          SET s.@degree += 1
        }

        MATCH (p@Person)
        PER NODE (p) {
          IF (p.@degree > 2) THEN {
            EXPORT p.id, p.@degree INTO result_table
          }
        }

        FOR r IN result_table
        RETURN r.id, r.degree
        ORDER BY r.degree DESC, r.id
      }
      """
    Then the execution should be successful
    # Test SumAgg and degree computation in one query
    When executing analytic query:
      """
      GRAPH dgv_agg_001 TYPED dgv_agg_type_001 PARTITION BY DEFAULT

      USE dgv_agg_001
      IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_agg_base_001&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }

      IF (true) THEN {
        USE dgv_agg_001 CALL dgv_proc_agg_001() RETURN id, degree
      }
      """
    Then the result should be, in any order:
      | id | degree |
      | 2  | 4      |
      | 3  | 4      |
      | 4  | 4      |
      | 0  | 3      |
      | 1  | 3      |
      | 5  | 3      |
      | 6  | 3      |
    And drop the procedure "dgv_proc_agg_001"
    And drop the graph "dgv_agg_base_001"
    And drop the graph type "dgv_agg_type_001"

  Scenario: Distributed graph variable with WHILE loop
    # Setup graph type and base graph
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dgv_bfs_type_001 {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS dgv_bfs_base_001 TYPED dgv_bfs_type_001
      """
    Then the execution should be successful
    And graph "dgv_bfs_base_001" should be ready to use
    When executing graph query:
      """
      USE dgv_bfs_base_001
      FOR i IN range(0, 9)
      INSERT (a@Person{id:i, name: 'person', age: 20 + i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edge_data {src, dst, weight} =
      (0, 1, 1.0), (0, 2, 2.0), (1, 2, 1.5),
      (2, 3, 2.5), (3, 4, 1.0), (4, 5, 3.0),
      (5, 6, 1.5), (6, 7, 2.0), (7, 8, 1.0),
      (8, 9, 2.5), (9, 0, 1.5), (1, 3, 2.0),
      (2, 4, 1.0), (3, 5, 2.5), (4, 6, 1.5)
      USE dgv_bfs_base_001
      FOR r IN edge_data
      MATCH (a@Person{id:r.src}), (b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    # Define procedure for BFS computation
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS dgv_proc_bfs_001()
      RETURNS (id INT64, distance INT) AS {
        NODE VALUE distance        MinAgg<INT> = 999
        NODE VALUE visited         OrAgg = false
        VALUE      new_active      OrAgg = true
        VALUE      iter            = 0
        VALUE      v_set           ACTIVE_SET
        TABLE      result_table    TYPED TABLE {id INT64, distance INT}

        MATCH (s@Person) WHERE s.id = 0
        FINALLY {
          SET v_set = s
        }

        MATCH (s@Person)
        WHERE s IN v_set
        PER NODE (s) {
          SET s.@visited = true
          SET s.@distance = 0
        }

        WHILE @new_active = true AND iter < 5 THEN {
          SET @new_active = false
          SET iter = iter + 1

          MATCH (v@Person)-[@KNOWS]-(d@Person)
          WHERE d.@visited = false AND v IN v_set
          PER PATH {
            SET d.@visited += true
            SET d.@distance += v.@distance + 1
            SET @new_active += true
          }
          FINALLY {
            SET v_set = d
          }
        }

        MATCH (p@Person)
        PER NODE (p) {
          IF (p.@distance < 999) THEN {
            EXPORT p.id, p.@distance INTO result_table
          }
        }

        FOR r IN result_table
        RETURN r.id AS id, r.distance AS distance
      }
      """
    Then the execution should be successful
    # Test iterative BFS computation in one query
    When executing analytic query:
      """
      GRAPH dgv_iter_001 TYPED dgv_bfs_type_001 PARTITION BY DEFAULT

      USE dgv_iter_001
      IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_bfs_base_001&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }

      IF (true) THEN {
        USE dgv_iter_001 CALL dgv_proc_bfs_001() RETURN id, distance
      }
      """
    Then the result should be, in any order:
      | id | distance |
      | 4  | 2        |
      | 2  | 1        |
      | 9  | 1        |
      | 5  | 3        |
      | 7  | 3        |
      | 6  | 3        |
      | 0  | 0        |
      | 3  | 2        |
      | 8  | 2        |
      | 1  | 1        |
    And drop the procedure "dgv_proc_bfs_001"
    And drop the graph "dgv_bfs_base_001"
    And drop the graph type "dgv_bfs_type_001"

  @non_tls
  Scenario: Distributed graph variable with procedure call
    # Setup graph type and base graph
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dgv_proc_type_001 {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS dgv_proc_base_001 TYPED dgv_proc_type_001
      """
    Then the execution should be successful
    And graph "dgv_proc_base_001" should be ready to use
    When executing graph query:
      """
      USE dgv_proc_base_001
      FOR i IN range(0, 9)
      INSERT (a@Person{id:i, name: 'person', age: 20 + i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edge_data {src, dst, weight} =
      (0, 1, 1.0), (0, 2, 2.0), (1, 2, 1.5),
      (2, 3, 2.5), (3, 4, 1.0), (4, 5, 3.0),
      (5, 6, 1.5), (6, 7, 2.0), (7, 8, 1.0),
      (8, 9, 2.5), (9, 0, 1.5), (1, 3, 2.0),
      (2, 4, 1.0), (3, 5, 2.5), (4, 6, 1.5)
      USE dgv_proc_base_001
      FOR r IN edge_data
      MATCH (a@Person{id:r.src}), (b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    # Define procedure first
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS dgv_proc_degree_002() RETURNS (node_id INT, deg INT) AS {
        NODE VALUE degree     SumAgg<INT> = 0
        TABLE result_table    TYPED TABLE {id INT64, degree INT}

        MATCH (s@Person)-[@KNOWS]-(t@Person)
        PER PATH {
          SET s.@degree += 1
        }

        MATCH (p@Person)
        PER NODE (p) {
          EXPORT p.id, p.@degree INTO result_table
        }

        FOR r IN result_table
        RETURN r.id as node_id, r.degree as deg
        ORDER BY r.degree DESC, r.id
      }
      """
    Then the execution should be successful
    # Test calling procedure on distributed graph variable in one query
    When executing analytic query:
      """
      GRAPH dgv_proc_001 TYPED dgv_proc_type_001 PARTITION BY DEFAULT

      USE dgv_proc_001
      IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_proc_base_001&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }

      IF (true) THEN {
        USE dgv_proc_001 CALL dgv_proc_degree_002() RETURN node_id, deg
      }
      """
    Then the result should be, in any order:
      | node_id | deg |
      | 2       | 4   |
      | 3       | 4   |
      | 4       | 4   |
      | 0       | 3   |
      | 1       | 3   |
      | 5       | 3   |
      | 6       | 3   |
      | 7       | 2   |
      | 8       | 2   |
      | 9       | 2   |
    And drop the procedure "dgv_proc_degree_002"
    And drop the graph "dgv_proc_base_001"
    And drop the graph type "dgv_proc_type_001"

  @non_tls
  Scenario: Distributed graph variable with MapAgg
    # Setup graph type and base graph
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dgv_map_type_001 {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS dgv_map_base_001 TYPED dgv_map_type_001
      """
    Then the execution should be successful
    And graph "dgv_map_base_001" should be ready to use
    When executing graph query:
      """
      USE dgv_map_base_001
      FOR i IN range(0, 9)
      INSERT (a@Person{id:i, name: 'person', age: 20 + i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edge_data {src, dst, weight} =
      (0, 1, 1.0), (0, 2, 2.0), (1, 2, 1.5),
      (2, 3, 2.5), (3, 4, 1.0), (4, 5, 3.0),
      (5, 6, 1.5), (6, 7, 2.0), (7, 8, 1.0),
      (8, 9, 2.5), (9, 0, 1.5), (1, 3, 2.0),
      (2, 4, 1.0), (3, 5, 2.5), (4, 6, 1.5)
      USE dgv_map_base_001
      FOR r IN edge_data
      MATCH (a@Person{id:r.src}), (b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    # Define procedure for MapAgg computation
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS dgv_proc_mapagg_001()
      RETURNS (id INT64, neighbor_count INT) AS {
        NODE VALUE neighbor_weights    MapAgg<INT, SumAgg<DOUBLE>>
        TABLE      result_table        TYPED TABLE {id INT64, neighbor_count INT}

        MATCH (s@Person)-[e@KNOWS]-(t@Person)
        PER PATH {
          SET s.@neighbor_weights += TUPLE(t.id, e.weight)
        }

        MATCH (p@Person)
        PER NODE (p) {
          VALUE nb_count = length(p.@neighbor_weights)
          EXPORT p.id, nb_count INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.neighbor_count
        ORDER BY r.neighbor_count DESC, r.id
      }
      """
    Then the execution should be successful
    # Test MapAgg for neighbor weights in one query
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 20) */
      GRAPH dgv_map_001 TYPED dgv_map_type_001 PARTITION BY DEFAULT

      USE dgv_map_001
      IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_map_base_001&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }

      IF (true) THEN {
        USE dgv_map_001 CALL dgv_proc_mapagg_001() RETURN id, neighbor_count
      }
      """
    Then the result should be, in any order:
      | id | neighbor_count |
      | 2  | 4              |
      | 3  | 4              |
      | 4  | 4              |
      | 0  | 3              |
      | 1  | 3              |
      | 5  | 3              |
      | 6  | 3              |
      | 7  | 2              |
      | 8  | 2              |
      | 9  | 2              |
    And drop the procedure "dgv_proc_mapagg_001"
    And drop the graph "dgv_map_base_001"
    And drop the graph type "dgv_map_type_001"

  @non_tls
  Scenario: Distributed graph variable comprehensive test
    # Setup graph type and base graph
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dgv_comp_type_001 {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS dgv_comp_base_001 TYPED dgv_comp_type_001
      """
    Then the execution should be successful
    And graph "dgv_comp_base_001" should be ready to use
    When executing graph query:
      """
      USE dgv_comp_base_001
      FOR i IN range(0, 9)
      INSERT (a@Person{id:i, name: 'person', age: 20 + i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edge_data {src, dst, weight} =
      (0, 1, 1.0), (0, 2, 2.0), (1, 2, 1.5),
      (2, 3, 2.5), (3, 4, 1.0), (4, 5, 3.0),
      (5, 6, 1.5), (6, 7, 2.0), (7, 8, 1.0),
      (8, 9, 2.5), (9, 0, 1.5), (1, 3, 2.0),
      (2, 4, 1.0), (3, 5, 2.5), (4, 6, 1.5)
      USE dgv_comp_base_001
      FOR r IN edge_data
      MATCH (a@Person{id:r.src}), (b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    # Create procedure with complex computation
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS dgv_comprehensive_002(max_iter INT)
      RETURNS (node_id INT, final_value DOUBLE, iteration INT) AS {
        NODE VALUE node_value      SumAgg<DOUBLE> = 0
        NODE VALUE neighbor_sum    SumAgg<DOUBLE> = 0
        VALUE      converged       OrAgg = false
        VALUE      iter            = 0
        TABLE      result_table    TYPED TABLE {id INT64, val DOUBLE, iter INT}

        MATCH (s@Person)
        PER NODE (s) {
          SET s.@node_value = cast(s.id AS DOUBLE)
        }

        WHILE NOT @converged AND iter < max_iter THEN {
          SET iter = iter + 1
          SET @converged += true

          MATCH (s@Person)-[e@KNOWS]-(t@Person)
          PER PATH {
            SET t.@neighbor_sum += s.@node_value * e.weight
          }

          MATCH (p@Person)
          PER NODE (p) {
            VALUE old_value = p.@node_value
            VALUE new_value = 0.15 * cast(p.id AS DOUBLE) + 0.85 * p.@neighbor_sum
            IF abs(new_value - old_value) > 0.01 THEN {
              SET @converged += false
              SET p.@node_value = new_value
            }
            SET p.@neighbor_sum = 0
          }
        }

        MATCH (p@Person)
        PER NODE (p) {
          EXPORT p.id AS id, p.@node_value AS val, iter INTO result_table
        }

        FOR r IN result_table
        RETURN r.id as node_id, r.val as final_value, r.iter as iteration
        ORDER BY r.id
      }
      """
    Then the execution should be successful
    # Test comprehensive procedure call on distributed graph variable in one query
    When executing analytic query:
      """
      GRAPH dgv_comp_001 TYPED dgv_comp_type_001 PARTITION BY DEFAULT

      USE dgv_comp_001
      IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_comp_base_001&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }

      IF (true) THEN {
        USE dgv_comp_001 CALL dgv_comprehensive_002(10) RETURN node_id, final_value, iteration
      }
      """
    Then the result should contain:
      | node_id | final_value        | iteration |
      | 0       | 15.725             | 1         |
      | 1       | 7.8                | 1         |
      | 2       | 11.35              | 1         |
      | 3       | 20.424999999999997 | 1         |
      | 4       | 25.25              | 1         |
      | 5       | 24.974999999999998 | 1         |
      | 6       | 24.275             | 1         |
      | 7       | 18.05              | 1         |
      | 8       | 26.275             | 1         |
      | 9       | 18.35              | 1         |
    And drop the procedure "dgv_comprehensive_002"
    And drop the graph "dgv_comp_base_001"
    And drop the graph type "dgv_comp_type_001"

  @non_tls
  Scenario: Multiple distributed graph variables in one query
    # Define procedure for multi-graph test
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS dgv_proc_multi_001()
      RETURNS (id INT64, name STRING) AS {
        TABLE result_table TYPED TABLE {id INT64, name STRING}

        MATCH (p@Person)
        PER NODE (p) {
          EXPORT p.id, p.name INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.name
        ORDER BY r.id
      }
      """
    Then the execution should be successful
    # Test using multiple distributed graph variables in one query
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dgv_test_type_002 {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS dgv_base_graph_002 dgv_test_type_002
      """
    Then the execution should be successful
    And graph "dgv_base_graph_002" should be ready to use
    When executing graph query:
      """
      USE dgv_base_graph_002
      FOR i IN range(0, 4)
      INSERT (a@Person{id:i, name: 'pPpP'})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edges {src, dst} = (0, 1), (1, 2), (2, 3), (3, 4)
      USE dgv_base_graph_002
      FOR r IN edges
      MATCH (a@Person{id:r.src}), (b@Person{id:r.dst})
      INSERT (a)~[@KNOWS]~(b)
      """
    Then the execution should be successful
    # Test two distributed graph variables in same query
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 16) */
      GRAPH dgv_multi_001 TYPED dgv_test_type_002 PARTITION BY DEFAULT
      GRAPH dgv_multi_002 TYPED dgv_test_type_002 PARTITION BY DEFAULT

      USE dgv_multi_001
      IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_base_graph_002&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }

      IF (true) THEN {
        USE dgv_multi_002
        IMPORT INTO GRAPH
        {
          GRAPH FROM NEBULA{
            PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_base_graph_002&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
          }
        }
      }

      IF (true) THEN {
        USE dgv_multi_001 CALL dgv_proc_multi_001() FINISH
      }

      IF (true) THEN {
        USE dgv_multi_001 CALL dgv_proc_multi_001() RETURN id, name
      }
      """
    Then the result should be, in any order:
      | id | name   |
      | 0  | "pPpP" |
      | 1  | "pPpP" |
      | 2  | "pPpP" |
      | 3  | "pPpP" |
      | 4  | "pPpP" |
    And drop the procedure "dgv_proc_multi_001"
    And drop the graph "dgv_base_graph_002"
    And drop the graph type "dgv_test_type_002"

  @non_tls
  Scenario: Distributed graph variable with nested WHILE loops
    # Setup graph type and base graph
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dgv_nested_type_001 {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY, name STRING, age INT}),
        EDGE TYPE KNOWS (Person)~[LABEL KNOWS {weight DOUBLE}]~(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS dgv_nested_base_001 TYPED dgv_nested_type_001
      """
    Then the execution should be successful
    And graph "dgv_nested_base_001" should be ready to use
    When executing graph query:
      """
      USE dgv_nested_base_001
      FOR i IN range(0, 9)
      INSERT (a@Person{id:i, name: 'person', age: 20 + i})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE edge_data {src, dst, weight} =
      (0, 1, 1.0), (0, 2, 2.0), (1, 2, 1.5),
      (2, 3, 2.5), (3, 4, 1.0), (4, 5, 3.0),
      (5, 6, 1.5), (6, 7, 2.0), (7, 8, 1.0),
      (8, 9, 2.5), (9, 0, 1.5), (1, 3, 2.0),
      (2, 4, 1.0), (3, 5, 2.5), (4, 6, 1.5)
      USE dgv_nested_base_001
      FOR r IN edge_data
      MATCH (a@Person{id:r.src}), (b@Person{id:r.dst})
      INSERT (a)~[@KNOWS{weight:r.weight}]~(b)
      """
    Then the execution should be successful
    # Define procedure for nested loops computation
    When executing graph analytic query:
      """
      CREATE PROCEDURE IF NOT EXISTS dgv_proc_nested_001()
      RETURNS (id INT64, label_id INT) AS {
        NODE VALUE label           SumAgg<INT> = 0
        NODE VALUE label_count_map MapAgg<INT, SumAgg<INT>>
        VALUE      iter            = 0
        VALUE      active          OrAgg = true
        TABLE      result_table    TYPED TABLE {id INT64, label_id INT}

        MATCH (a@Person)
        PER NODE (a) {
          SET a.@label = a.id
        }

        WHILE @active AND iter < 3 THEN {
          SET @active += false
          SET iter = iter + 1

          MATCH (s@Person)-[@KNOWS]-(t@Person)
          PER PATH {
            SET t.@label_count_map += TUPLE(s.@label, 1)
          }

          MATCH (t@Person)
          PER NODE (t) {
            VALUE max_count INT = 0
            VALUE max_label INT = -1
            VALUE cur_iter = 0
            VALUE label_list = t.@label_count_map

            WHILE cur_iter < length(label_list) THEN {
              VALUE val = label_list[cur_iter]
              IF val._1 > max_count THEN {
                SET max_count = val._1
                SET max_label = val._0
              }
              SET cur_iter = cur_iter + 1
            }

            IF max_label <> -1 AND max_label <> t.@label THEN {
              SET @active += true
              SET t.@label = max_label
            }
            SET t.@label_count_map.clear()
          }
        }

        MATCH (p@Person)
        PER NODE (p) {
          EXPORT p.id, p.@label INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.label_id
        ORDER BY r.label_id, r.id
      }
      """
    Then the execution should be successful
    # Test nested control flow in one query
    When executing analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      GRAPH dgv_nested_001 TYPED dgv_nested_type_001 PARTITION BY DEFAULT

      USE dgv_nested_001
      IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=dgv_nested_base_001&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }

      IF (true) THEN {
        USE dgv_nested_001 CALL dgv_proc_nested_001() RETURN id, label_id
      }
      """
    Then the execution should be successful
    And drop the procedure "dgv_proc_nested_001"
    And drop the graph "dgv_nested_base_001"
    And drop the graph type "dgv_nested_type_001"
