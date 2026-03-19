@aggregator
Feature: SetAgg

  Scenario: basic
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE set_agg SetAgg<INT>
        SET @set_agg += 1
        SET @set_agg += 2
        SET @set_agg.clear()
        SET @set_agg += 3
        SET @set_agg += 4
        SET @set_agg += 4
        SET @set_agg += 3
        FOR i IN @set_agg
        RETURN i
      }
      """
    Then the result should be, in any order:
      | i |
      | 4 |
      | 3 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE set_agg SetAgg<INT>
        VALUE cur_iter = 0

        WHILE cur_iter < 2 THEN {
          SET @set_agg += 1
          SET @set_agg += 2
          SET @set_agg += 3
          SET cur_iter = cur_iter + 1
        }

        RETURN
          @set_agg.contains_key(1) as count_1,
          @set_agg.contains_key(2) as count_2,
          @set_agg.contains_key(3) as count_3,
          @set_agg.contains_key(4) as count_4,
          @set_agg.size() as sz
      }
      """
    Then the result should be, in any order:
      | count_1 | count_2 | count_3 | count_4 | sz |
      | true    | true    | true    | false   | 3  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE neighbor_set SetAgg<INT>
        // TABLE result_table TYPED TABLE {id INT, neighbors LIST<INT>, sz INT, count_4 BOOL}
        TABLE result_table TYPED TABLE {id INT, neighbors LIST<INT>}

        MATCH (a:Person)-[:KNOWS|FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@neighbor_set += b.id
        }

        MATCH (a:Person)
        PER NODE (a) {
          // EXPORT a.id, @neighbor_set, @neighbor_set.size(), @neighbor_set.contains_key(4) INTO result_table
          EXPORT a.id, a.@neighbor_set INTO result_table
        }

        FOR r IN result_table
        FOR neighbor IN r.neighbors
        RETURN r.id as id, neighbor ORDER BY id, neighbor
      }
      """
    Then the result should be, in order:
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
        NODE VALUE neighbor_set SetAgg<INT>
        TABLE result_table TYPED TABLE {id INT, neighbor_sz UINT, count_4 BOOL}

        MATCH (a:Person)-[:KNOWS|FOLLOWS]->(b:Person)
        PER PATH {
          SET a.@neighbor_set += b.id
        }

        MATCH (a:Person)
        PER NODE (a) {
          EXPORT a.id, a.@neighbor_set.size(), a.@neighbor_set.contains_key(4) INTO result_table
        }

        FOR r IN result_table
        RETURN r.id, r.neighbor_sz, r.count_4
      }
      """
    Then the result should be, in any order:
      | r.id | r.neighbor_sz | r.count_4 |
      | 2    | 3             | true      |
      | 4    | 0             | false     |
      | 3    | 3             | false     |
      | 1    | 2             | false     |

  Scenario: assign
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE global_agg_1 SetAgg<INT>
        VALUE global_agg_2 SetAgg<INT>
        VALUE list_int = LIST[1,2,3,3,2,1]
        SET @global_agg_1 = list_int
        SET @global_agg_2 = @global_agg_1
        FOR r In @global_agg_2
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 1 |
      | 2 |
      | 3 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 SetAgg<INT>
        NODE VALUE node_agg_2 SetAgg<INT>
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
        VALUE global_agg_1 SetAgg<INT>
        VALUE global_agg_2 SetAgg<INT>
        VALUE x = LIST[1,2,1]
        SET @global_agg_2 = @global_agg_1
        SET @global_agg_1 = x
        SET @global_agg_2 = [4,5]
        SET @global_agg_2 += @global_agg_1
        FOR r IN @global_agg_2
        RETURN r
      }
      """
    Then the result should be, in any order:
      | r |
      | 1 |
      | 2 |
      | 5 |
      | 4 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg_1 SetAgg<INT>
        NODE VALUE node_agg_2 SetAgg<INT>
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
        NODE VALUE node_agg SetAgg<INT>
        VALUE global_agg SetAgg<INT>
        TABLE result_table TYPED TABLE {id INT, res LIST<INT>}
        SET @global_agg = LIST[1,2,3]
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg += @global_agg
        }

        MATCH (a@Person) WHERE a.id < 3
        PER NODE (a) {
          EXPORT a.id, a.@node_agg INTO result_table
        }

        FOR r IN result_table
        FOR t IN r.res
        RETURN r.id, t
      }
      """
    Then the result should be, in any order:
      | r.id | t |
      | 2    | 2 |
      | 2    | 1 |
      | 2    | 3 |
      | 1    | 2 |
      | 1    | 1 |
      | 1    | 3 |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg SetAgg<INT>
        VALUE global_agg SetAgg<INT>
        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg += @global_agg
        }
        PER NODE (a) {
          SET a.@node_agg = LIST[a.id]
        }
        PER NODE (a) {
          SET a.@node_agg += @global_agg
        }
        PER NODE (a) {
          SET @global_agg += a.@node_agg
        }
        FOR id IN @global_agg
        RETURN id
      }
      """
    Then the result should be, in any order:
      | id |
      | 4  |
      | 2  |
      | 3  |
      | 1  |

  Scenario: NULL input
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE set_agg SetAgg<INT>
        VALUE set_agg_1 SetAgg<INT>
        SET @set_agg = [NULL,1, 1]
        SET @set_agg_1 += NULL
        SET @set_agg_1 += 3
        SET @set_agg_1 = NULL
        RETURN @set_agg, @set_agg_1
      }
      """
    Then the result should be, in any order:
      | @set_agg | @set_agg_1 |
      | LIST [1] | LIST [3]   |

  Scenario: string key
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE set_agg SetAgg<STRING>
        SET @set_agg += "ABC"
        SET @set_agg += "DEF"
        SET @set_agg += "ABC"
        SET @set_agg += "DEF"
        SET @set_agg += "GH"

        FOR res IN @set_agg
        RETURN res
      }
      """
    Then the result should be, in any order:
      | res   |
      | "ABC" |
      | "DEF" |
      | "GH"  |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE set_agg SetAgg<STRING>
        SET @set_agg += "ABC"
        SET @set_agg.clear()
        SET @set_agg += "DEF"
        SET @set_agg += "D"

        RETURN @set_agg.size() as sz,
          @set_agg.contains_key("DEF") as res_1,
          @set_agg.contains_key("ABC") as res_2
      }
      """
    Then the result should be, in any order:
      | sz | res_1 | res_2 |
      | 2  | true  | false |
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE node_agg SetAgg<STRING>
        VALUE global_agg SetAgg<STRING>

        MATCH (a:Person)
        PER NODE (a) {
          SET a.@node_agg += a.firstName
          SET a.@node_agg += a.lastName
          SET @global_agg += a.@node_agg
        }

        FOR res IN @global_agg
        RETURN res
      }
      """
    Then the result should be, in any order:
      | res       |
      | "Kyle"    |
      | "Marceau" |
      | "Yao"     |
      | "Tim"     |
      | "cao"     |
      | "Duncan"  |
      | "Sophie"  |
      | "Ming"    |

  Scenario: fix issues 10258
    When executing graph analytic query:
      """
      CREATE OR REPLACE PROCEDURE long_setagg_name() RETURNS (searched_target INT) AS {
        NODE VALUE SearchedTarget    OrAgg = false
        NODE VALUE OtherCompanyNames SetAgg<STRING>
        RETURN 0
      }
      """
    Then the execution should be successful
    When executing graph analytic query:
      """
      use #analytic_ldbc call long_setagg_name() return *
      """
    Then the execution should be successful
