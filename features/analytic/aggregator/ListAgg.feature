@aggregator
Feature: ListAgg

  Scenario: member function
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE l_int ListAgg<INT>
        VALUE l_double ListAgg<DOUBLE>
        SET @l_int += 1
        SET @l_int += 1
        SET @l_int.clear()
        SET @l_int += 1
        SET @l_int += 1
        SET @l_double.clear()
        SET @l_double += 1.0
        SET @l_double += 1.0
        SET @l_double.clear()
        SET @l_double += 1.0
        RETURN @l_int,@l_double
      }
      """
    Then the result should be, in any order:
      | @l_int     | @l_double  |
      | LIST [1,1] | LIST [1.0] |
    When executing analytic query:
      """
      USE #analytic_ldbc {
          NODE VALUE list_node ListAgg<INT>
          TABLE t TYPED TABLE {id INT, neighbor LIST<INT>}
          MATCH (a@Person)-[:FOLLOWS]->(b)
          PER PATH {
            SET a.@list_node += b.id
          }
          PER NODE (a) {
            EXPORT a.id, a.@list_node INTO t
          }
          FOR r IN t
          RETURN r.id,r.neighbor
      }
      """
    Then the result should be, in any order:
      | r.id | r.neighbor |
      | 3    | LIST [1,2] |
      | 2    | LIST [3,4] |
      | 1    | LIST [2]   |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
          NODE VALUE list_node ListAgg<INT>
          TABLE t TYPED TABLE {id INT, neighbor LIST<INT>}
          MATCH (a@Person)-[:FOLLOWS]->(b)
          PER PATH {
            SET a.@list_node += b.id
          }
          PER NODE (a) {
            SET a.@list_node.clear()
          }
          PER NODE (a) {
            EXPORT a.id, a.@list_node INTO t
          }
          FOR r IN t
          RETURN r.id,r.neighbor
      }
      """
    Then the result should be, in any order:
      | r.id | r.neighbor |
      | 3    | LIST []    |
      | 2    | LIST []    |
      | 1    | LIST []    |

  Scenario: uninitialized test
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE list_agg ListAgg<INT>
        SET @list_agg.clear()
        RETURN @list_agg.size() as sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE list_agg ListAgg<INT>
        TABLE t TYPED TABLE {sz UINT}
        MATCH (a@Person{id:1})
        PER NODE (a) {
          EXPORT a.@list_agg.size() INTO t
        }
        FOR r IN t
        RETURN r.sz as sz
      }
      """
    Then the result should be, in any order:
      | sz |
      | 0  |
    Then the execution should be successful

  Scenario: assign
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 ListAgg<INT>
        VALUE global_agg_2 ListAgg<INT>
        VALUE x = LIST[1,2,3,3,2,1]
        SET @global_agg_1 = x
        SET @global_agg_2 = @global_agg_1
        RETURN @global_agg_2
      }
      """
    Then the result should be, in any order:
      | @global_agg_2      |
      | LIST [1,2,3,3,2,1] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 ListAgg<INT>
        NODE VALUE node_agg_2 ListAgg<INT>
        TABLE result_table TYPED TABLE {id INT, neighbors LIST<INT>}
        VALUE cur_iter = 0
        MATCH (a:Person)-[:KNOWS|FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_1 += b.id
        }
        PER NODE (a) {
          SET a.@node_agg_2 = a.@node_agg_1
        }
        PER NODE (a) {
          EXPORT a.id, a.@node_agg_2 INTO result_table
        }

        FOR r IN result_table
        FOR neighbor IN r.neighbors
        RETURN r.id as id, neighbor ORDER BY id, neighbor
      }
      """
    Then the result should be, in any order:
      | id | neighbor |
      | 1  | 1        |
      | 1  | 2        |
      | 2  | 2        |
      | 2  | 3        |
      | 2  | 4        |
      | 3  | 1        |
      | 3  | 2        |
      | 3  | 3        |

  Scenario: merge
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 ListAgg<INT>
        VALUE global_agg_2 ListAgg<INT>
        VALUE x = LIST[1,2,3,3,2,1]
        SET @global_agg_1 = x
        SET @global_agg_2 += @global_agg_1
        SET @global_agg_2 += @global_agg_1
        RETURN @global_agg_2
      }
      """
    Then the result should be, in any order:
      | @global_agg_2                  |
      | LIST [1,2,3,3,2,1,1,2,3,3,2,1] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 ListAgg<DOUBLE>
        VALUE global_agg_2 ListAgg<DOUBLE>
        VALUE x = LIST[1,2,3,3,2,1]
        SET @global_agg_1 = x
        SET @global_agg_2 += @global_agg_1
        SET @global_agg_2 += @global_agg_1
        RETURN @global_agg_2
      }
      """
    Then the result should be, in any order:
      | @global_agg_2                                          |
      | LIST [1.0,2.0,3.0,3.0,2.0,1.0,1.0,2.0,3.0,3.0,2.0,1.0] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 ListAgg<LIST<INT>>
        VALUE global_agg_2 ListAgg<LIST<INT>>
        VALUE x = LIST[LIST[1,2,3],LIST[3,2,1]]
        SET @global_agg_1 = x
        SET @global_agg_2 += @global_agg_1
        SET @global_agg_2 += @global_agg_1
        RETURN @global_agg_2
      }
      """
    Then the result should be, in any order:
      | @global_agg_2                                              |
      | LIST [LIST [1,2,3],LIST [3,2,1],LIST [1,2,3],LIST [3,2,1]] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 ListAgg<INT>
        NODE VALUE node_agg_2 ListAgg<INT>
        TABLE result_table TYPED TABLE {id INT, neighbors LIST<INT>}
        VALUE cur_iter = 0
        MATCH (a)
        PER NODE (a) {
          SET a.@node_agg_1 = LIST[a.id]
        }

        MATCH (a:Person)-[:KNOWS|FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@node_agg_2 += b.@node_agg_1
        }
        PER NODE (a) {
          EXPORT a.id, a.@node_agg_2 INTO result_table
        }

        FOR r IN result_table
        FOR neighbor IN r.neighbors
        RETURN r.id as id, neighbor ORDER BY id, neighbor
      }
      """
    Then the result should be, in any order:
      | id | neighbor |
      | 1  | 1        |
      | 1  | 2        |
      | 2  | 2        |
      | 2  | 3        |
      | 2  | 4        |
      | 3  | 1        |
      | 3  | 2        |
      | 3  | 3        |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg ListAgg<INT>
        VALUE global_agg ListAgg<INT>
        TABLE result_table TYPED TABLE {id INT, res LIST<INT>}
        SET @global_agg = LIST[1,2,3]
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg += @global_agg
        }

        MATCH (a@Person)
        PER NODE (a) {
          EXPORT a.id, a.@node_agg INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.res
      }
      """
    Then the result should be, in any order:
      | r.id | r.res        |
      | 2    | LIST [1,2,3] |
      | 4    | LIST [1,2,3] |
      | 3    | LIST [1,2,3] |
      | 1    | LIST [1,2,3] |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg ListAgg<INT>
        VALUE global_agg ListAgg<INT>
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg = LIST[1,2,3]
        }
        PER NODE (a) {
          SET @global_agg += a.@node_agg
        }
        RETURN @global_agg
      }
      """
    Then the result should be, in any order:
      | @global_agg                    |
      | LIST [1,2,3,1,2,3,1,2,3,1,2,3] |

  Scenario: NULL input
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE list_agg ListAgg<INT>
        VALUE list_agg_1 ListAgg<INT>
        SET @list_agg = [NULL,1,2]
        SET @list_agg_1 += NULL
        SET @list_agg_1 += 3
        SET @list_agg_1 = NULL
        RETURN @list_agg, @list_agg_1
      }
      """
    Then the result should be, in any order:
      | @list_agg  | @list_agg_1 |
      | LIST [1,2] | LIST [3]    |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE a ListAgg<RECORD{id INT, name STRING}>
        SET @a = [NULL,{id:1,name:"An"},{id:NULL,name:NULL}]
        RETURN @a
      }
      """
    Then the result should be, in any order:
      | @a                                                     |
      | LIST[RECORD{id:1,name:"An"},RECORD{id:NULL,name:NULL}] |

  Scenario: global LISTAGG
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test_list LISTAGG<RECORD{node_id INT, score DOUBLE}>
        SET @test_list += RECORD{node_id:1,score:1.0}
        SET @test_list += RECORD{node_id:2,score:2.0}
        SET @test_list += RECORD{node_id:3,score:3.0}
        FOR r IN @test_list
        RETURN r.node_id, r.score
      }
      """
    Then the result should be, in any order:
      | r.node_id | r.score |
      | 1         | 1.0     |
      | 2         | 2.0     |
      | 3         | 3.0     |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test_list LISTAGG<INT64>
        MATCH (s:Person)
        PER NODE(s) {
          SET @test_list += s.id
        }

        FOR r IN @test_list
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 2 |
      | 3 |
      | 4 |
      | 1 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE test_list LISTAGG<DOUBLE>
        MATCH (s:Person)
        PER NODE(s) {
          SET @test_list += 1.1
        }

        FOR r IN @test_list
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r   |
      | 1.1 |
      | 1.1 |
      | 1.1 |
      | 1.1 |
