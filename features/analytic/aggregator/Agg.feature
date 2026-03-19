# Copyright (c) 2024 vesoft inc. All rights reserved.
@aggregator
Feature: Agg Test

  Scenario: Basic
    When executing graph analytic query:
      """
      EXPLAIN
      USE #analytic_ldbc {
        VALUE a = 1
        VALUE gAgg SumAgg<Int64> = 0
        SET @gAgg += a
        SET @gAgg = 2
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      EXPLAIN
      USE #analytic_ldbc {
        NODE VALUE lAgg MinAgg<double> = 1.2
        MATCH (v)
        PER NODE(v) {
            SET v.@lAgg += 2.4
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      EXPLAIN
      USE #analytic_ldbc {
        VALUE a = 1
        VALUE gAgg SumAgg<Int64> = 0
        NODE VALUE lAgg MinAgg<double> = 1.2
        NODE VALUE lAgg2 MaxAgg<double> = 100
        MATCH (v)
        PER NODE (v) {
          SET v.@lAgg += a + @gAgg + v.@lAgg
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      EXPLAIN
      NODE VALUE lAgg MinAgg<double> = 1.2
      MATCH (v)
      PER NODE(v) {
        SET v.@lAgg += 2.4
      }
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    # global agg should be referenced in the form of @gAgg
    # node agg should be referenced in the form of v.@lAgg
    When executing graph analytic query:
      """
      EXPLAIN
      USE #analytic_ldbc {
        VALUE lAgg MinAgg<double> = 1.2
        RETURN lAgg
      }
      """
    Then an Error should be raised: "[NS231]: Invalid variable access: `lAgg:Aggregator` cannot be referenced by binding variable expressions"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE lAgg MinAgg<double> = 1.2
        MATCH (v:Person&City)
        PER NODE (v) {
          SET @lAgg += v.id
        }
        RETURN @lAgg
      }
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(v:(Person) & (City))` was found"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE lAgg MinAgg<double> = 1.2
        MATCH (v)-[e:KNOWS&WORK_AT]->(v2)
        PER PATH {
          SET @lAgg += e.id
        }
        RETURN @lAgg
      }
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:(KNOWS) & (WORK_AT)]->` was found"

  Scenario: Supported agg match
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_edge SumAgg<INT> = 0
        MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
        PER PATH {
          SET @out_edge += 1
        }
        RETURN @out_edge AS oe
      }
      """
    Then the result should be, in any order:
      | oe |
      | 3  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_edge SumAgg<INT> = 0
        MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
        WHERE s1.firstName LIKE 'T%'
        PER PATH {
          SET @out_edge += 1
        }
        RETURN @out_edge AS oe
      }
      """
    Then the result should be, in any order:
      | oe |
      | 1  |
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #analytic_ldbc {
        VALUE out_edge SumAgg<INT> = 0
        MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
        PER NODE(s1) {
          SET @out_edge += s1.id
        }
        RETURN @out_edge AS oe
      }
      """
    Then the result should be, in any order:
      | oe |
      | 6  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_edge SumAgg<INT> = 0
        MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
        PER NODE(s1) {
          SET @out_edge += 1
        }
        RETURN @out_edge AS oe
      }
      """
    Then the result should be, in any order:
      | oe |
      | 3  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_edge SumAgg<INT> = 0
        MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
        PER PATH {
          SET @out_edge += 1
        }
        PER NODE(s1) {
          SET @out_edge += 1
        }
        RETURN @out_edge AS oe
      }
      """
    Then the result should be, in any order:
      | oe |
      | 6  |
    When executing graph analytic query:
      """
      /*+ SET_VAR(query_concurrency = 4) */
      USE #analytic_ldbc {
        VALUE out_nodes SumAgg<INT> = 0
        MATCH (s2:Person)
        PER NODE (s2) {
          SET @out_nodes += 1
        }
        RETURN @out_nodes AS num_nodes
      }
      """
    Then the result should be, in any order:
      | num_nodes |
      | 4         |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_nodes SumAgg<INT> = 0
        MATCH (s2:Person)
        PER NODE (s2) {
          SET s2.@out_nodes += 1
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_nodes SumAgg<INT> = 0
        MATCH (s:Person)-[]->(t:Person)
        PER NODE (s) {
          SET s.@out_nodes += 1
        }
        PER NODE (t) {
          SET t.@out_nodes += 2
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_edge SumAgg<INT> = 0
        NODE VALUE prop SumAgg<INT> = 0
        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER PATH {
          SET @out_edge += 1
          SET s.@prop += t.@prop + 1
        }
        PER NODE (s) {
          SET s.@prop += 10
        }
        PER NODE (t) {
          SET t.@prop += 20
        }
        RETURN @out_edge AS oe
      }
      """
    Then the result should be, in any order:
      | oe |
      | 3  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_nodes SumAgg<INT> = 0
        MATCH (s:Person)-[]->(t:Person)
        PER NODE (s) {
          SET s.@out_nodes = 1
        }
      }
      """
    Then the execution should be successful

  @skip
  Scenario: complex for path/node block
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_edge SumAgg<INT> = 0
        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER PATH {
          SET s.@out_edge += 2
          IF s.firstName LIKE 'T%' THEN {
            SET s.@out_edge += -1
          } ELSE {
            SET s.@out_edge += 1
          }
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_edge SumAgg<INT> = 0
        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER NODE (s) {
          SET s.@out_edge += CAST(2 AS INT)
          NEXT
          IF s.firstName LIKE 'T%' THEN {
            SET s.@out_edge += CAST(-1 AS INT)
          } ELSE {
            SET s.@out_edge += CAST(1 AS INT)
          }
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_edge SumAgg<INT> = 0
        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER PATH {
          SET s.@out_edge += CAST(2 AS INT)
          WHILE s.@out_edge > 10 THEN {
            SET s.@out_edge += CAST(-1 AS INT)
          }
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_edge SumAgg<INT> = 0
        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER NODE (s) {
          SET s.@out_edge += CAST(2 AS INT)
          WHILE s.@out_edge > 10 THEN {
            SET s.@out_edge += CAST(-1 AS INT)
          }
        }
      }
      """
    Then the execution should be successful

  Scenario: engine task with variable
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test_list LISTAGG<INT64>
        VALUE var = 1
        MATCH (s:Person)
        PER NODE(s) {
          SET @test_list += var
          LOG_INFO("------test-------")
        }
        RETURN @test_list
      }
      """
    Then the result should be, in any order:
      | @test_list     |
      | LIST [1,1,1,1] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test_list LISTAGG<INT64>
        VALUE var = 1
        VALUE iter = 0
        WHILE iter < 5 THEN {
          MATCH (s@Person)
          PER NODE(s) {
            SET @test_list += iter
          }
          SET iter = iter + 1
        }
        RETURN @test_list,length(@test_list) as len
      }
      """
    Then the result should be, in any order:
      | @test_list                                     | len |
      | LIST [0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4] | 20  |

  Scenario: Only Node Task
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_node SumAgg<INT> = 0
        MATCH (s1@Person)
        PER PATH {
          SET @sum_node += 1
        }
        RETURN @sum_node AS sn
      }
      """
    Then an Error should be raised: "[NS238]: Invalid match compute block: PER PATH clause cannot be used in single node pattern `(s1@Person)`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_node SumAgg<INT> = 0
        MATCH (s1@Person)
        PER NODE (s1) {
          SET @sum_node += 1
        }
        RETURN @sum_node AS sn
      }
      """
    Then the result should be, in any order:
      | sn |
      | 4  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_node_0 SumAgg<INT> = 0
        VALUE sum_node_1 SumAgg<INT> = 0
        VALUE sum_node_2 SumAgg<INT> = 0
        MATCH (s1@Person)
        PER NODE (s1) {
          SET @sum_node_0 += 1
        }
        PER NODE (s1) {
          SET @sum_node_1 += 1
        }
        PER NODE (s1) {
          SET @sum_node_2 += 1
        }
        RETURN @sum_node_0,@sum_node_1,@sum_node_2
      }
      """
    Then the result should be, in any order:
      | @sum_node_0 | @sum_node_1 | @sum_node_2 |
      | 4           | 4           | 4           |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE filter_node SumAgg<INT> = 0
        MATCH (s1@Person) WHERE s1.id < 2
        PER NODE (s1) {
          SET @filter_node += 1
        }
        RETURN @filter_node
      }
      """
    Then the result should be, in any order:
      | @filter_node |
      | 1            |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE active_set_1 :: ACTIVE_SET
        VALUE ids ListAgg<INT64>

        MATCH (s@Place) WHERE s.id = 5
        FINALLY {
            SET active_set = s
        }

        MATCH (v)
        WHERE v IN active_set
        PER NODE(v) {
          SET @ids += v.id
        }
        FINALLY {
          SET active_set_1 = v
        }

        MATCH (v1)
        WHERE v1 IN active_set_1
        PER NODE(v1) {
          SET @ids += v1.id
        }
        RETURN @ids
      }
      """
    Then the result should be, in any order:
      | @ids       |
      | LIST [5,5] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set :: ACTIVE_SET
        VALUE ids ListAgg<INT64>

        MATCH (v@Person) WHERE v.id > 1
        FINALLY {
          SET active_set = v
        }

        MATCH (v1@Person)
        WHERE v1 IN active_set
        PER NODE (v1) {
          SET @ids += v1.id
        }
        FOR i IN @ids
        RETURN i
      }
      """
    Then the result should be, in any order:
      | i |
      | 3 |
      | 2 |
      | 4 |

  Scenario: Only PER NODE Clauses
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE ids ListAgg<INT64>
        MATCH (s1@Person)-[e]->(t)
        PER NODE (s1) {
          SET @ids += s1.id
        }
        FOR i IN @ids
        RETURN i
      }
      """
    Then the result should be, in any order:
      | i |
      | 3 |
      | 2 |
      | 1 |

  @skip
  Scenario: Undirected edge
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS memory_graph_test_undirected_gt {
        NODE TYPE Place (LABEL Place {id INT PRIMARY KEY}),
        EDGE TYPE Connect (Place)~[LABEL Connect]~(Place)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH memory_graph_test_undirected memory_graph_test_undirected_gt
      """
    And graph "memory_graph_test_undirected" should be ready to use
    When executing graph query:
      """
      TABLE t {src, dst} =
      (1,2),(2,3),(3,1)
      USE memory_graph_test_undirected
      FOR r IN t
      INSERT OR REPLACE (@Place{id:r.src})~[@Connect{}]~(@Place{id:r.dst})
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #project_graph_test_undirected AS COPY OF memory_graph_test_undirected
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #project_graph_test_undirected TYPED memory_graph_test_undirected_gt PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #project_graph_test_undirected IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=memory_graph_test_undirected&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #project_graph_test_undirected {
        VALUE out_edge SumAgg<INT> = 0
        MATCH (s1)~[e1]~(t1)
        PER PATH {
          SET @out_edge += 1
        }
        RETURN @out_edge AS oe
      }
      """
    Then the result should be, in any order:
      | oe |
      | 6  |
    And drop the graph "#project_graph_test_undirected"
    And drop the graph "memory_graph_test_undirected"
    And drop the graph type "memory_graph_test_undirected_gt"

  Scenario: Aggregator Operation
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT> = 0
        SET @sum_agg += 1.0
      }
      """
    Then an Error should be raised: "[NS232]: += operation of `sum_agg(GLOBAL SumAgg<INT64>)` cannot accept `1.0(DECIMAL)` as input"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT> = 0
        SET @sum_agg = 1.0
      }
      """
    Then an Error should be raised: "[NS232]: = operation of `sum_agg(GLOBAL SumAgg<INT64>)` cannot accept `1.0(DECIMAL)` as input"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_agg SumAgg<INT> = 0
        MATCH (a)
        PER NODE (a) {
          SET a.@sum_agg += 1.0
        }
      }
      """
    Then an Error should be raised: "[NS232]: += operation of `sum_agg(NODE SumAgg<INT64>)` cannot accept `1.0(DECIMAL)` as input"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_agg SumAgg<INT> = 0
        MATCH (a)
        PER NODE (a) {
          SET a.@sum_agg = 1.0
        }
      }
      """
    Then an Error should be raised: "[NS232]: = operation of `sum_agg(NODE SumAgg<INT64>)` cannot accept `1.0(DECIMAL)` as input"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT> = 0
        SET @sum_agg.asdx_ads
      }
      """
    Then an Error should be raised: "[NS237]: Invalid member function: asdx_ads cannot be used as a member function of agg `sum_agg`"

  Scenario: Aggregator definition
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_agg SumAgg<INT> = 0
        NODE VALUE sum_agg SumAgg<INT> = 0
        SET @sum_agg += 1
      }
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `sum_agg`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT> = 0
        VALUE sum_agg SumAgg<INT> = 0
        SET @sum_agg += 1
      }
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `sum_agg`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT> = 0
        SET @sum_ac += 1
      }
      """
    Then an Error should be raised: "[42N56]: Invalid syntax, global agg `sum_ac` not defined"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT>
        SET @sum_agg += 1
      }
      """
    Then an Error should be raised: "[NS233]: Invalid aggregator definition: default value needs to be provided when defining `sum_agg(GLOBAL SumAgg<INT64>)`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE sum_agg SumAgg<INT> = NULL
        SET @sum_agg += 1
      }
      """
    Then an Error should be raised: "[NS233]: Invalid aggregator definition: `sum_agg(GLOBAL SumAgg<INT64>)` cannot be defined with default value NULL"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE topk TopKAgg<3, test INT ASC> = 1
        SET @topk += RECORD{test: 1}
      }
      """
    Then an Error should be raised: "[NS233]: Invalid aggregator definition: default value cannot be provided when defining `topk(GLOBAL TopKAgg<3,test INT64 ASC>)`"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE topk TopKAgg<0, test INT ASC>
        SET @topk += RECORD{test: 1}
      }
      """
    Then an Error should be raised: "[NS233]: Invalid aggregator definition: the maximum size of `topk(GLOBAL TopKAgg<0,test INT64 ASC>)` should be greater than 0"

  Scenario: Inplace Update Node Task
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_node_plus SumAgg<INT64> = 0
        NODE VALUE sum_node_assign SumAgg<INT64> = 0
        VALUE sum_total SumAgg<INT64> = 0

        MATCH (v@Person)
        PER NODE (v) {
          SET v.@sum_node_plus += 1
          SET v.@sum_node_assign = 2
          IF v.@sum_node_plus = 1 THEN {
            SET @sum_total += v.@sum_node_plus + v.@sum_node_assign
          }
        }
        RETURN @sum_total
      }
      """
    Then the result should be, in any order:
      | @sum_total |
      | 12         |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_node_plus SumAgg<INT64> = 0
        VALUE sum_total SumAgg<INT64> = 0

        MATCH (v@Person)-[]->(v)
        PER PATH {
          SET v.@sum_node_plus += 1
          IF v.@sum_node_plus = 1 THEN {
            SET @sum_total += v.@sum_node_plus
          }
        }
        RETURN @sum_total
      }
      """
    Then the result should be, in any order:
      | @sum_total |
      | 0          |

  Scenario: Uninitialized Global Agg
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE max_agg MaxAgg<INT> = 3
        TABLE t {id int}
        MATCH (v@Person{id:1})
        PER NODE(v) {
          EXPORT @max_agg INTO t
        }
        FOR r IN t
        RETURN r.id
      }
      """
    Then the result should be, in any order:
      | r.id |
      | 3    |

  Scenario: NULL input
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE max_agg MaxAgg<INT> = 3
        VALUE min_agg MaxAgg<INT> = 3
        SET @max_agg += NULL
        SET @max_agg += NULL
        SET @max_agg = NULL
        SET @max_agg = NULL
        RETURN @max_agg, @min_agg
      }
      """
    Then the result should be, in any order:
      | @max_agg | @min_agg |
      | 3        | 3        |

  Scenario: Master-Mirror sync
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE sum_agg SumAgg<INT> = 10
        VALUE global_sum SumAgg<INT> = 0
        VALUE global_sum_1 SumAgg<INT> = 0

        MATCH (a)
        PER NODE (a) {
          SET a.@sum_agg += 1
        }

        MATCH (a)-[]->(b)
        PER PATH {
          SET @global_sum += b.@sum_agg
        }

        MATCH (a)
        PER NODE (a) {
          SET a.@sum_agg += 1
        }

        MATCH (a)-[]->(b)
        PER PATH {
          SET @global_sum_1 += b.@sum_agg
        }

        RETURN @global_sum, @global_sum_1
      }
      """
    Then the result should be, in any order:
      | @global_sum | @global_sum_1 |
      | 814         | 888           |
