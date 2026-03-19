@aggregator
Feature: MapAgg

  Scenario: basic
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS map_agg_basic_test_type {
        NODE TYPE Person (LABEL Person {id INT PRIMARY KEY , category INT, score INT}),
        EDGE TYPE KNOWS (Person)-[LABEL KNOWS]->(Person)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE GRAPH IF NOT EXISTS map_agg_basic_test map_agg_basic_test_type
      """
    Then the execution should be successful
    And graph "map_agg_basic_test" should be ready to use
    When executing graph query:
      """
      TABLE t {id, category, score} =
      (1, 1, 3), (2, 1, 5), (3, 2, 1),
      (4, 2, 3), (5, 3, 14), (6, 4, 5),
      (7, 3, 19), (8, 1, 19), (9, 2, 2),
      (10, 3, 14), (11, 3, 5), (13, 2, 2)
      USE map_agg_basic_test
      FOR r IN t
      INSERT (a@Person{id:r.id,category:r.category,score:r.score})
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
      USE map_agg_basic_test
      FOR r IN t
      MATCH (a@Person) WHERE a.id = r.src
      MATCH (b@Person) WHERE b.id = r.dst
      INSERT (a)-[@KNOWS]->(b)
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_map_agg_basic_test AS COPY OF map_agg_basic_test
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #dist_map_agg_basic_test TYPED map_agg_basic_test_type PARTITION BY DEFAULT
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #dist_map_agg_basic_test IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=map_agg_basic_test&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      USE #dist_map_agg_basic_test {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        SET @map_agg += TUPLE(1,1)
        SET @map_agg += TUPLE(1,2)
        SET @map_agg += TUPLE(2,2)
        SET @map_agg += TUPLE(2,3)
        SET @map_agg += TUPLE(3,3)
        FOR r IN @map_agg
        RETURN r._0 as k ,r._1 as v
      }
      """
    Then the result should be, in any order:
      | k | v |
      | 3 | 3 |
      | 2 | 5 |
      | 1 | 3 |
    When executing graph analytic query:
      """
      USE #dist_map_agg_basic_test {
        VALUE map_max_agg MapAgg<INT, MaxAgg<INT>>
        SET @map_max_agg += TUPLE(1,1)
        SET @map_max_agg += TUPLE(1,2)
        SET @map_max_agg += TUPLE(2,4)
        SET @map_max_agg += TUPLE(2,5)
        SET @map_max_agg += TUPLE(2,3)
        SET @map_max_agg += TUPLE(2,3)
        SET @map_max_agg += TUPLE(3,3)
        SET @map_max_agg += TUPLE(1,3)
        SET @map_max_agg += TUPLE(3,4)
        FOR r IN @map_max_agg
        RETURN r._0 as k ,r._1 as v
      }
      """
    Then the result should be, in any order:
      | k | v |
      | 3 | 4 |
      | 2 | 5 |
      | 1 | 3 |
    When executing graph analytic query:
      """
      USE #dist_map_agg_basic_test {
        VALUE map_max_agg MapAgg<INT, MaxAgg<INT>>
        SET @map_max_agg += TUPLE(1,1)
        SET @map_max_agg += TUPLE(1,2)
        SET @map_max_agg += TUPLE(2,4)
        SET @map_max_agg += TUPLE(2,5)
        SET @map_max_agg += TUPLE(2,3)
        SET @map_max_agg.clear()
        SET @map_max_agg += TUPLE(2,3)
        SET @map_max_agg += TUPLE(3,3)
        SET @map_max_agg += TUPLE(1,3)
        SET @map_max_agg += TUPLE(3,4)
        FOR r IN @map_max_agg
        RETURN r._0 as k ,r._1 as v
      }
      """
    Then the result should be, in any order:
      | k | v |
      | 1 | 3 |
      | 3 | 4 |
      | 2 | 3 |
    When executing graph analytic query:
      """
      USE #dist_map_agg_basic_test {
        VALUE map_max_agg MapAgg<INT, MaxAgg<INT>>
        SET @map_max_agg += TUPLE(2,5)
        SET @map_max_agg += TUPLE(2,6)
        SET @map_max_agg += TUPLE(3,3)
        SET @map_max_agg += TUPLE(1,3)
        SET @map_max_agg += TUPLE(3,4)
        RETURN
          @map_max_agg.get(1) as get_1,
          @map_max_agg.get(2) as get_2,
          @map_max_agg.get(3) as get_3,
          @map_max_agg.contains_key(1) as c_1,
          @map_max_agg.contains_key(2) as c_2,
          @map_max_agg.contains_key(3) as c_3,
          @map_max_agg.contains_key(4) as c_4
      }
      """
    Then the result should be, in any order:
      | get_1 | get_2 | get_3 | c_1  | c_2  | c_3  | c_4   |
      | 3     | 6     | 4     | true | true | true | false |
    When executing graph analytic query:
      """
      USE #dist_map_agg_basic_test {
        NODE VALUE node_neighbor MapAgg<INT, SumAgg<INT>>
        TABlE result_table TYPED TABLE {id INT, nei LIST<RECORD{_0 INT,_1 INT}>}
        MATCH (a)-[]->(b)
        PER PATH {
          SET a.@node_neighbor += TUPLE(b.category, b.score)
        }
        PER NODE (a) {
          EXPORT a.id, a.@node_neighbor INTO result_table
        }

        FOR r IN result_table
        FOR inner IN r.nei
        RETURN r.id as id, inner._0 as category, inner._1 as sum_score
      }
      """
    Then the result should be, in any order:
      | id | category | sum_score |
      | 5  | 2        | 3         |
      | 5  | 1        | 19        |
      | 4  | 3        | 5         |
      | 4  | 2        | 2         |
      | 2  | 2        | 1         |
      | 2  | 3        | 33        |
      | 3  | 4        | 5         |
      | 3  | 3        | 33        |
      | 1  | 2        | 4         |
      | 1  | 1        | 5         |
    When executing graph analytic query:
      """
      USE #dist_map_agg_basic_test {
        NODE VALUE node_neighbor MapAgg<INT, SumAgg<INT>>
        TABlE result_table TYPED TABLE {id INT, score INT}
        MATCH (a)-[]->(b)
        PER PATH {
          SET a.@node_neighbor += TUPLE(b.category, b.score)
        }
        PER NODE (a) {
          IF a.@node_neighbor.contains_key(a.id) THEN {
            EXPORT a.id, a.@node_neighbor.get(a.id) INTO result_table
          }
        }

        FOR r IN result_table
        RETURN r.id as id, r.score as score
      }
      """
    Then the result should be, in any order:
      | id | score |
      | 2  | 1     |
      | 3  | 33    |
      | 1  | 5     |
    When executing graph analytic query:
      """
      USE #dist_map_agg_basic_test {
        NODE VALUE node_neighbor MapAgg<INT, SumAgg<INT>>
        TABlE result_table TYPED TABLE {id INT, nei LIST<RECORD{_0 INT,_1 INT}>}
        MATCH (a)-[]->(b)
        PER PATH {
          SET a.@node_neighbor += TUPLE(b.category, b.score)
        }
        PER NODE (a) {
          SET a.@node_neighbor.clear()
          EXPORT a.id, a.@node_neighbor INTO result_table
        }
        FOR r IN result_table
        RETURN r.id as id, r.nei as nei
      }
      """
    Then the result should be, in any order:
      | id | nei     |
      | 5  | LIST [] |
      | 4  | LIST [] |
      | 2  | LIST [] |
      | 3  | LIST [] |
      | 1  | LIST [] |
    And drop the graph "#dist_map_agg_basic_test"
    And drop the graph "map_agg_basic_test"
    And drop the graph type "map_agg_basic_test_type"

  Scenario: uninitialized test
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        SET @map_agg.clear()
        RETURN
          @map_agg.size() as sz,
          @map_agg.contains_key(1) as con,
          @map_agg.get(1) as get_1
      }
      """
    Then the result should be, in any order:
      | sz | con   | get_1 |
      | 0  | false | 0     |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE map_agg MapAgg<INT, SumAgg<INT>>
        TABLE t TYPED TABLE {sz UINT, con BOOL, get_1 INT}
        MATCH (a@Person{id:1})
        PER NODE (a) {
          EXPORT a.@map_agg.size(), a.@map_agg.contains_key(1), a.@map_agg.get(1) INTO t
        }
        FOR r IN t
        RETURN r.sz, r.con, r.get_1
      }
      """
    Then the result should be, in any order:
      | r.sz | r.con | r.get_1 |
      | 0    | false | 0       |

  Scenario: nested container map
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, ListAgg<INT>>
        VALUE out_iter = 0
        VALUE inner_iter = 0
        WHILE out_iter < 5 THEN {
          SET inner_iter = 0
          WHILE inner_iter < out_iter THEN {
            SET @map_agg += TUPLE(out_iter,inner_iter)
            SET inner_iter = inner_iter + 1
          }
          SET out_iter = out_iter + 1
        }
        FOR r IN @map_agg
        RETURN r._0, r._1
      }
      """
    Then the result should be, in any order:
      | r._0 | r._1           |
      | 4    | LIST [0,1,2,3] |
      | 3    | LIST [0,1,2]   |
      | 2    | LIST [0,1]     |
      | 1    | LIST [0]       |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_map MapAgg<INT, ListAgg<INT>>
        TABLE t TYPED TABLE {src INT, id INT, iter_list List<INT>}
        VALUE cur_iter = 0
        WHILE cur_iter < 3 THEN {
          MATCH (a@Person)-[:KNOWS]->(b)
          PER PATH {
            SET a.@node_map += TUPLE(b.id, cur_iter)
          }
          SET cur_iter = cur_iter + 1
        }
        MATCH (a@Person)
        PER NODE (a) {
          VALUE l = a.@node_map
          VALUE iter = 0
          WHILE iter < length(l) THEN {
            VALUE element = l[iter]
            EXPORT a.id, element._0,  element._1 INTO t
            SET iter = iter + 1
          }
        }
        FOR r IN t
        RETURN r.src, r.id, r.iter_list
      }
      """
    Then the result should be, in any order:
      | r.src | r.id | r.iter_list  |
      | 3     | 3    | LIST [0,1,2] |
      | 2     | 2    | LIST [0,1,2] |
      | 1     | 1    | LIST [0,1,2] |

  Scenario: assign
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 MapAgg<INT,SumAgg<INT>>
        VALUE global_agg_2 MapAgg<INT,SumAgg<INT>>
        VALUE x = LIST[TUPLE(1,2),TUPLE(3,3),TUPLE(2,1)]
        SET @global_agg_1 = x
        SET @global_agg_2 = @global_agg_1
        FOR r IN @global_agg_2
        RETURN r._0 as key, r._1 as val
      }
      """
    Then the result should be, in any order:
      | key | val |
      | 1   | 2   |
      | 3   | 3   |
      | 2   | 1   |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 MapAgg<INT,ListAgg<INT>>
        VALUE global_agg_2 MapAgg<INT,ListAgg<INT>>
        VALUE x = LIST[TUPLE(1,LIST[1,2,3,3,2,1]),TUPLE(3,LIST[1,3,3,3,1]),TUPLE(2,LIST[1,1])]
        SET @global_agg_1 = x
        SET @global_agg_2 = @global_agg_1
        FOR r IN @global_agg_2
        RETURN r._0 as key, r._1 as val
      }
      """
    Then the result should be, in any order:
      | key | val                |
      | 1   | LIST [1,2,3,3,2,1] |
      | 3   | LIST [1,3,3,3,1]   |
      | 2   | LIST [1,1]         |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 MapAgg<INT,SetAgg<INT>>
        NODE VALUE node_agg_2 MapAgg<INT,SetAgg<INT>>
        TABLE result_table TYPED TABLE {id INT, neighbors_knows LIST<INT>, neighbor_follows LIST<INT>}
        VALUE cur_iter = 0
        MATCH (a:Person)-[:KNOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_1 += TUPLE(1,b.id)
        }
        MATCH (a:Person)-[:FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_1 += TUPLE(2,b.id)
        }

        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg_2 = a.@node_agg_1
        }
        PER NODE (a) {
          EXPORT a.id, a.@node_agg_2.get(1), a.@node_agg_2.get(2) INTO result_table
        }

        FOR r IN result_table
        RETURN r.id as id, r.neighbors_knows as knows, reduce(r.neighbor_follows,0,(stat,x)->stat+x) as sum_follows
      }
      """
    Then the result should be, in any order:
      | id | knows    | sum_follows |
      | 2  | LIST [2] | 7           |
      | 4  | LIST []  | 0           |
      | 3  | LIST [3] | 3           |
      | 1  | LIST [1] | 2           |

  Scenario: merge
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 MapAgg<INT,SumAgg<INT>>
        VALUE global_agg_2 MapAgg<INT,SumAgg<INT>>
        SET @global_agg_1 += TUPLE(1,1)
        SET @global_agg_1 += TUPLE(2,2)
        SET @global_agg_2 += @global_agg_1
        SET @global_agg_2 += @global_agg_1
        FOR r IN @global_agg_2
        RETURN r._0 as key, r._1 as val
      }
      """
    Then the result should be, in any order:
      | key | val |
      | 2   | 4   |
      | 1   | 2   |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 MapAgg<INT,ListAgg<INT>>
        VALUE global_agg_2 MapAgg<INT,ListAgg<INT>>
        VALUE x = LIST[TUPLE(1,LIST[1,2,3]),TUPLE(3,LIST[1,2]),TUPLE(2,LIST[1])]
        SET @global_agg_2 += @global_agg_1
        SET @global_agg_1 = x
        SET @global_agg_2 += @global_agg_1
        SET @global_agg_2 += @global_agg_1
        FOR r IN @global_agg_2
        RETURN r._0 as key, r._1 as val
      }
      """
    Then the result should be, in any order:
      | key | val                |
      | 2   | LIST [1,1]         |
      | 3   | LIST [1,2,1,2]     |
      | 1   | LIST [1,2,3,1,2,3] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 MapAgg<INT,SumAgg<INT>>
        NODE VALUE node_agg_2 MapAgg<INT,SumAgg<INT>>
        TABLE result_table TYPED TABLE {id INT, sum_1 INT, sum_2 INT}
        VALUE cur_iter = 0
        MATCH (a:Person)-[:KNOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_1 += TUPLE(1,b.id)
        }
        MATCH (a:Person)-[:FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_2 += TUPLE(2,b.id)
        }

        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg_2 += a.@node_agg_1
          SET a.@node_agg_2 += a.@node_agg_2
        }
        PER NODE (a) {
          EXPORT a.id, a.@node_agg_2.get(1), a.@node_agg_2.get(2) INTO result_table
        }

        FOR r IN result_table
        RETURN r.id as id, r.sum_1, r.sum_2
      }
      """
    Then the result should be, in any order:
      | id | r.sum_1 | r.sum_2 |
      | 2  | 4       | 14      |
      | 4  | 0       | 0       |
      | 3  | 6       | 6       |
      | 1  | 2       | 4       |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg MapAgg<INT,SumAgg<INT>>
        VALUE global_agg_1 MapAgg<INT,SumAgg<INT>>
        VALUE global_agg_2 MapAgg<INT,SumAgg<INT>>
        SET @global_agg_1 += TUPLE(1,1)
        SET @global_agg_1 += TUPLE(2,1)
        SET @global_agg_1 += TUPLE(3,1)
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg += @global_agg_1
          SET @global_agg_2 += a.@node_agg
        }

        FOR t IN @global_agg_2
        RETURN t._0, t._1
      }
      """
    Then the result should be, in any order:
      | t._0 | t._1 |
      | 2    | 4    |
      | 1    | 4    |
      | 3    | 4    |

  Scenario: empty result
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_sum MapAgg<INT, SumAgg<INT>>
        VALUE map_max MapAgg<INT, MaxAgg<INT>>
        VALUE map_min MapAgg<INT, MinAgg<INT>>
        VALUE map_avg MapAgg<INT, AvgAgg<INT>>
        VALUE map_and MapAgg<INT, AndAgg>
        VALUE map_or MapAgg<INT, OrAgg>
        VALUE map_list MapAgg<INT, ListAgg<INT>>
        VALUE map_set MapAgg<INT, SetAgg<INT>>
        VALUE map_topk MapAgg<INT, TopKAgg<1, test INT DESC>>

        RETURN
          @map_sum.get(999) as sum_empty,
          @map_max.get(999) as max_empty,
          @map_min.get(999) as min_empty,
          @map_avg.get(999) as avg_empty,
          @map_and.get(999) as and_empty,
          @map_or.get(999) as or_empty,
          @map_list.get(999) as list_empty,
          @map_set.get(999) as set_empty,
          @map_topk.get(999) as topk_empty
          }
      """
    Then the result should be, in any order:
      | sum_empty | max_empty            | min_empty           | avg_empty | and_empty | or_empty | list_empty | set_empty | topk_empty |
      | 0         | -9223372036854775808 | 9223372036854775807 | 0.0       | true      | false    | LIST[]     | LIST[]    | LIST[]     |

  Scenario: NULL input
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        VALUE map_agg_1 MapAgg<INT, SumAgg<INT>>

        SET @map_agg += TUPLE(1,NULL)
        SET @map_agg += TUPLE(1,2)
        SET @map_agg += TUPLE(NULL,2)
        SET @map_agg += TUPLE(NULL,NULL)
        SET @map_agg += NULL
        SET @map_agg = NULL

        SET @map_agg_1 = LIST[NULL, TUPLE(1,2),TUPLE(1,2),TUPLE(NULL,1),TUPLE(NULL,NULL), TUPLE(1,NULL)]

        RETURN @map_agg, @map_agg_1
      }
      """
    Then the result should be, in any order:
      | @map_agg                | @map_agg_1              |
      | LIST[RECORD{_0:1,_1:2}] | LIST[RECORD{_0:1,_1:2}] |

  Scenario: string key
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<STRING, SetAgg<STRING>>

        SET @map_agg += TUPLE("ABC", "A")
        SET @map_agg += TUPLE("ABC", "A")
        SET @map_agg += TUPLE("ABC", "B")
        SET @map_agg += TUPLE("ABC", "C")
        SET @map_agg += TUPLE("DEF", "D")
        SET @map_agg += TUPLE("DEF", "E")
        SET @map_agg += TUPLE("DEF", "F")

        FOR i IN @map_agg
        FOR j IN i._1
        RETURN i._0 as key , j as val
      }
      """
    Then the result should be, in any order:
      | key   | val |
      | "DEF" | "D" |
      | "DEF" | "E" |
      | "DEF" | "F" |
      | "ABC" | "B" |
      | "ABC" | "C" |
      | "ABC" | "A" |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE map_agg    MapAgg<STRING,SumAgg<INT>>
        VALUE global_agg MapAgg<STRING,SumAgg<INT>>
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@map_agg += TUPLE(a.firstName, 1)
          SET a.@map_agg += TUPLE(a.lastName, 1)
          SET a.@map_agg += a.@map_agg
          SET @global_agg += a.@map_agg
        }
        FOR r IN @global_agg
        RETURN r._0 as key , r._1 as val
      }
      """
    Then the result should be, in any order:
      | key       | val |
      | "Duncan"  | 2   |
      | "Kyle"    | 2   |
      | "cao"     | 2   |
      | "Marceau" | 2   |
      | "Sophie"  | 2   |
      | "Yao"     | 2   |
      | "Ming"    | 2   |
      | "Tim"     | 2   |

  Scenario: global MapAgg with SumAgg
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE map_agg MapAgg<INT, SumAgg<INT>>
        VALUE total SumAgg<INT> = 0
        SET @map_agg += TUPLE(1,1)
        SET @map_agg += TUPLE(2,3)
        MATCH (a@Person)
        PER NODE (a) {
          IF @map_agg.contains_key(a.id) THEN {
            SET @total += RECORD{id:@map_agg.get(a.id)}.id
          }
        }
        RETURN @total
      }
      """
    Then the result should be, in any order:
      | @total |
      | 4      |
