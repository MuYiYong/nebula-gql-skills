@aggregator
Feature: TopKAgg

  Scenario: basic
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS topk_agg_basic_test_type {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY , score INT}),
        EDGE TYPE KNOWS (Person)-[LABEL KNOWS]->(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS topk_agg_basic_test topk_agg_basic_test_type
      """
    Then the execution should be successful
    And graph "topk_agg_basic_test" should be ready to use
    When executing graph query:
      """
      TABLE t {id, score} =
      (1, 3), (2, 5), (3, 1),
      (4, 3), (5, 14), (6, 5),
      (7, 19), (8, 19), (9, 2),
      (10, 14), (11, 5), (13, 2)
      USE topk_agg_basic_test
      FOR r IN t
      INSERT (a@Person{id:r.id, score:r.score})
      """
    Then the execution should be successful
    When executing graph query:
      """
      TABLE t {src,dst} =
      (1, 2),(1, 3), (1 ,4),
      (2, 3),(2, 5), (2 ,7),
      (3, 6),(3, 7), (3 ,10),
      (4, 11),(4 ,13),
      (5, 9), (5, 8), (5, 3)
      USE topk_agg_basic_test
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[@KNOWS]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_topk_agg_basic_test AS COPY OF topk_agg_basic_test
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_topk_agg_basic_test TYPED topk_agg_basic_test_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_topk_agg_basic_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=topk_agg_basic_test&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_topk_agg_basic_test {
        VALUE topk TopKAgg<3, test INT ASC>
        SET @topk += Record{test:1}
        SET @topk += Record{test:3}
        SET @topk += Record{test:4}
        SET @topk += Record{test:2}
        SET @topk += Record{test:-1}

        RETURN transform(@topk, x -> x.test) as sorted
      }
      """
    Then the result should be, in any order:
      | sorted        |
      | LIST [-1,1,2] |
    When executing graph analytic query:
      """
      USE #dist_topk_agg_basic_test {
        VALUE topk TopKAgg<3, test INT ASC>
        SET @topk += Record{test:1}
        SET @topk += Record{test:3}
        SET @topk.min() // No special meaning, just to test whether min() can be executed
        SET @topk.clear()
        FOR r IN @topk
        RETURN r.test
      }
      """
    Then the result should be, in any order:
      | r.test |
    When executing graph analytic query:
      """
      USE #dist_topk_agg_basic_test {
        NODE VALUE score SumAgg<INT> = 0
        VALUE topk TopKAgg<5, score INT DESC, id INT DESC>

        MATCH (a)
        PER NODE (a) {
          SET @topk += RECORD{id:a.id,score:a.score}
        }

        RETURN transform(@topk, x -> x.score) as score, transform(@topk, x->x.id) as id
      }
      """
    Then the result should be, in any order:
      | score                | id                 |
      | LIST [19,19,14,14,5] | LIST [8,7,10,5,11] |
    When executing graph analytic query:
      """
      USE #dist_topk_agg_basic_test {
        NODE VALUE topk_nei TopKAgg<2, score INT DESC, neigh_id INT DESC>
        TABLE result_table TYPED TABLE {id INT, topk_nei LIST<RECORD{score INT, neigh_id INT}>}
        MATCH (a)-[]->(b)
        PER PATH {
          SET a.@topk_nei += RECORD{score:b.score, neigh_id:b.id}
        }
        MATCH (a)
        PER NODE (a) {
          SET a.@topk_nei += RECORD{score:a.score,neigh_id:a.id}
        }
        PER NODE (a) {
          LOG_INFO(a.id, " topk_nei = " ,a.@topk_nei)
          EXPORT a.id, a.@topk_nei INTO result_table
        }

        FOR r IN result_table
        FOR nei IN r.topk_nei
        RETURN r.id as id, nei.neigh_id, nei.score ORDER BY id
      }
      """
    Then the result should be, in any order:
      | id | nei.neigh_id | nei.score |
      | 1  | 4            | 3         |
      | 1  | 2            | 5         |
      | 2  | 7            | 19        |
      | 2  | 5            | 14        |
      | 3  | 7            | 19        |
      | 3  | 10           | 14        |
      | 4  | 11           | 5         |
      | 4  | 4            | 3         |
      | 5  | 8            | 19        |
      | 5  | 5            | 14        |
      | 6  | 6            | 5         |
      | 7  | 7            | 19        |
      | 8  | 8            | 19        |
      | 9  | 9            | 2         |
      | 10 | 10           | 14        |
      | 11 | 11           | 5         |
      | 13 | 13           | 2         |
    When executing graph analytic query:
      """
      USE #dist_topk_agg_basic_test {
        NODE VALUE topk_nei TopKAgg<2, score INT DESC, neigh_id INT DESC>
        TABLE result_table TYPED TABLE {id INT, topk_nei LIST<RECORD{score INT, neigh_id INT}>}
        MATCH (a)-[]->(b)
        PER PATH {
          SET a.@topk_nei += RECORD{score:b.score, neigh_id:b.id}
        }
        MATCH (a)
        PER NODE (a) {
          SET a.@topk_nei += RECORD{score:a.score,neigh_id:a.id}
        }
        PER NODE (a) {
          SET a.@topk_nei.clear()
          EXPORT a.id, a.@topk_nei INTO result_table
        }

        FOR r IN result_table
        FOR nei IN r.topk_nei
        RETURN r.id as id, nei.neigh_id, nei.score ORDER BY id
      }
      """
    Then the result should be, in any order:
      | id | nei.neigh_id | nei.score |
    When executing graph analytic query:
      """
      USE #dist_topk_agg_basic_test {
        VALUE topk TopKAgg<3, score INT DESC>
        VALUE min_1 INT = 0
        VALUE min_2 INT = 0
        VALUE min_3 INT = 0
        VALUE sz_1  UINT = 0
        VALUE sz_2  UINT = 0
        VALUE sz_3  UINT = 0
        SET @topk += Record{score:1}
        SET sz_1 = @topk.size()
        SET @topk += Record{score:3}
        SET sz_2 = @topk.size()
        SET @topk += Record{score:4}
        SET sz_3 = @topk.size()
        SET min_1 = @topk.min().score
        SET @topk += Record{score:5}
        SET min_2 = @topk.min().score
        SET @topk += Record{score:6}
        SET min_3 = @topk.min().score
        RETURN min_1,min_2,min_3,sz_1,sz_2,sz_3
      }
      """
    Then the result should be, in any order:
      | min_1 | min_2 | min_3 | sz_1 | sz_2 | sz_3 |
      | 1     | 3     | 4     | 1    | 2    | 3    |
    When executing graph analytic query:
      """
      USE #dist_topk_agg_basic_test {
        NODE VALUE topk_nei TopKAgg<10, score INT DESC>
        TABLE result_table TYPED TABLE {id INT, min_score INT, sz UINT}
        MATCH (a)-[]->(b)
        PER PATH {
          SET a.@topk_nei += RECORD{score:b.score}
        }
        PER NODE (a) {
          EXPORT a.id, a.@topk_nei.min().score, a.@topk_nei.size() INTO result_table
        }

        FOR r IN result_table
        RETURN r.id as id, r.min_score, r.sz ORDER BY id
      }
      """
    Then the result should be, in order:
      | id | r.min_score | r.sz |
      | 1  | 1           | 3    |
      | 2  | 1           | 3    |
      | 3  | 5           | 3    |
      | 4  | 2           | 2    |
      | 5  | 1           | 3    |
    And drop the graph "#dist_topk_agg_basic_test"
    And drop the graph "topk_agg_basic_test"
    And drop the graph type "topk_agg_basic_test_type"

  Scenario: uninitialized test
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE uninit_topk TopkAgg<1, score INT DESC>
        RETURN @uninit_topk.size() as sz, @uninit_topk.min() as min
      }
      """
    Then the result should be, in any order:
      | sz | min                 |
      | 0  | RECORD {score:null} |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE uninit_topk TopkAgg<1, score INT DESC>
        TABLE t TYPED TABLE {sz UINT, mn RECORD{score INT}}
        MATCH (a@Person{id:1})
        PER NODE (a) {
          EXPORT a.@uninit_topk.size(), a.@uninit_topk.min() INTO t
        }
        FOR r IN t
        RETURN r.sz, r.mn
      }
      """
    Then the result should be, in any order:
      | r.sz | r.mn                |
      | 0    | RECORD {score:null} |

  Scenario: assign
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 TopKAgg<3,score INT DESC>
        VALUE global_agg_2 TopKAgg<3,score INT DESC>
        VALUE list_rec = LIST[
          RECORD{score:1},RECORD{score:2},RECORD{score:3},
          RECORD{score:3},RECORD{score:2},RECORD{score:1}
        ]

        SET @global_agg_1 = list_rec
        SET @global_agg_2 = @global_agg_1
        RETURN @global_agg_1, @global_agg_2
      }
      """
    Then the result should be, in any order:
      | @global_agg_1                                             | @global_agg_2                                             |
      | LIST [RECORD {score:3},RECORD {score:3},RECORD {score:2}] | LIST [RECORD {score:3},RECORD {score:3},RECORD {score:2}] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 TopKAgg<3,id INT DESC>
        NODE VALUE node_agg_2 TopKAgg<3,id INT DESC>
        TABLE result_table TYPED TABLE {id INT, neighbors LIST<INT>}
        MATCH (a:Person)-[:KNOWS|FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_1 += RECORD{id: b.id}
        }
        PER NODE (a) {
          SET a.@node_agg_2 = a.@node_agg_1
        }
        PER NODE (a) {
          EXPORT a.id, transform(a.@node_agg_2, x->x.id) INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.neighbors
      }
      """
    Then the result should be, in any order:
      | r.id | r.neighbors  |
      | 2    | LIST [4,3,2] |
      | 3    | LIST [3,2,1] |
      | 1    | LIST [2,1]   |

  Scenario: merge
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 TopKAgg<3,score INT DESC>
        VALUE global_agg_2 TopKAgg<3,score INT DESC>
        VALUE list_rec = LIST[
          RECORD{score:1},RECORD{score:2},RECORD{score:3}
        ]
        SET @global_agg_1 = list_rec
        SET @global_agg_2 += @global_agg_1
        SET @global_agg_2 += @global_agg_1
        RETURN transform(@global_agg_2, x->x.score) as res
      }
      """
    Then the result should be, in any order:
      | res          |
      | LIST [3,3,2] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 TopKAgg<3,score INT DESC>
        NODE VALUE node_agg_2 TopKAgg<3,score INT DESC>
        TABLE result_table TYPED TABLE {id INT, topk_score LIST<INT>}
        MATCH (a)
        PER NODE (a) {
          SET a.@node_agg_1 += RECORD{score:a.id}
        }

        MATCH (a:Person)-[:KNOWS|FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_2 += b.@node_agg_1
        }
        PER NODE (a) {
          EXPORT a.id, transform(a.@node_agg_2, x->x.score) INTO result_table
        }

        FOR r IN result_table
        RETURN r.id as id, r.topk_score
      }
      """
    Then the result should be, in any order:
      | id | r.topk_score |
      | 2  | LIST [4,3,2] |
      | 3  | LIST [3,2,1] |
      | 1  | LIST [2,1]   |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg TopKAgg<3,score INT DESC>
        NODE VALUE node_agg TopKAgg<3,score INT DESC>
        TABLE result_table TYPED TABLE {id INT, res LIST<INT>}
        SET @global_agg = LIST[RECORD{score:1},RECORD{score:2}]
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg += @global_agg
          SET a.@node_agg += @global_agg
        }

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, transform(a.@node_agg, x->x.score) INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.res
      }
      """
    Then the result should be, in any order:
      | r.id | r.res        |
      | 2    | LIST [2,2,1] |
      | 4    | LIST [2,2,1] |
      | 3    | LIST [2,2,1] |
      | 1    | LIST [2,2,1] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg TopKAgg<3,score INT DESC>
        NODE VALUE node_agg TopKAgg<3,score INT DESC>
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg += RECORD{score:a.id}
        }
        PER NODE (a) {
          SET @global_agg += a.@node_agg
        }
        RETURN transform(@global_agg, x->x.score) as res
      }
      """
    Then the result should be, in any order:
      | res          |
      | LIST [4,3,2] |

  Scenario: NULL input
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE topk_agg TopKAgg<3,score INT DESC>
        VALUE topk_agg_1 TopKAgg<3,score INT DESC>
        SET @topk_agg = [NULL,RECORD{score:3},RECORD{score:1}]
        SET @topk_agg_1 += NULL
        SET @topk_agg_1 += RECORD{score:null}
        SET @topk_agg_1 = NULL
        RETURN
        transform(@topk_agg, x->x.score) as res,
        transform(@topk_agg_1, x->x.score) as res_1
      }
      """
    Then the result should be, in any order:
      | res       | res_1       |
      | LIST[3,1] | LIST [null] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE topk_agg TopKAgg<5, field_int INT, field_double DOUBLE>
        SET @topk_agg += RECORD{field_int:NULL,field_double:1.0}
        SET @topk_agg += RECORD{field_int:NULL,field_double:2.0}
        SET @topk_agg += RECORD{field_int:2,field_double:NULL}
        SET @topk_agg += RECORD{field_int:1,field_double:NULL}
        SET @topk_agg += RECORD{field_int:2,field_double:2.0}
        RETURN @topk_agg
      }
      """
    Then the result should be, in any order:
      | @topk_agg                                                                                                                                                                                                 |
      | LIST [RECORD {field_double:null,field_int:1},RECORD {field_double:2.0,field_int:2},RECORD{field_double:null,field_int:2},RECORD{field_double:1.0,field_int:null},RECORD{field_double:2.0,field_int:null}] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE topk_agg TopKAgg<5, field_int INT DESC, field_double DOUBLE DESC NULLS LAST>
        SET @topk_agg += RECORD{field_int:NULL,field_double:1.0}
        SET @topk_agg += RECORD{field_int:NULL,field_double:2.0}
        SET @topk_agg += RECORD{field_int:2,field_double:NULL}
        SET @topk_agg += RECORD{field_int:1,field_double:NULL}
        SET @topk_agg += RECORD{field_int:2,field_double:2.0}
        RETURN @topk_agg
      }
      """
    Then the result should be, in any order:
      | @topk_agg                                                                                                                                                                                                   |
      | LIST[RECORD {field_double:2.0,field_int:null},RECORD {field_double:1.0,field_int:null},RECORD {field_double:null,field_int:2},RECORD {field_double:2.0,field_int:2},RECORD {field_double:null,field_int:1}] |

  Scenario: fix init
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE topk_agg TopKAgg<6,score INT DESC>
        VALUE global_agg TopKAgg<6,score INT DESC>
        SET @topk_agg = [NULL,RECORD{score:3},RECORD{score:1}]
        MATCH (a@Person)-[@KNOWS]->(b)
        PER PATH {
          VALUE l = @topk_agg
          VALUE i = 0
          LOG_INFO("---")
          WHILE i < length(l) THEN {
           SET @global_agg += l[i]
           SET i = i + 1
          }
        }
        RETURN @global_agg
      }
      """
    Then the result should be, in any order:
      | @global_agg                                                                                           |
      | LIST[RECORD{score:3},RECORD{score:3},RECORD{score:3},RECORD{score:1},RECORD{score:1},RECORD{score:1}] |

  Scenario: Aggregator definition
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
