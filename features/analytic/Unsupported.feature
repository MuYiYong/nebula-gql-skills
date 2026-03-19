# Copyright (c) 2025 vesoft inc. All rights reserved.
Feature: Unsupported match compute statement

  Scenario: Invalid symbol
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE prop SumAgg<INT> = 0
        MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
        PER PATH {
          SET s.@prop += 1
        }
      }
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `s` not defined"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_nodes SumAgg<INT> = 0
        MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
        PER NODE (e1) {
          SET @out_nodes += 1
        }
      }
      """
    Then an Error should be raised:
      """
      [42N54]: Invalid syntax, invalid node variable reference: `e1`
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE out_nodes SumAgg<INT> = 0
        MATCH (s:Person)-[]->(t:Person)
        PER NODE (s) {
          SET t.@out_nodes += CAST(1 AS INT)
        }
      }
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `t` not defined"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        TABLE t TYPED TABLE {id INT}
        MATCH (s@Person)
        PER NODE (s) {
          EXPORT x INTO t
        }
      }
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `x` not defined"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s@Person)-[e]->(t)
        PER NODE (s) {
          LOG_INFO(e)
        }
      }
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `e` not defined"

  Scenario: Unsupported aggregator assignment
    When executing graph analytic query:
      """
      VALUE out_nodes SumAgg<INT> = 0
      MATCH (s1:Person)-[e1:KNOWS]->(t1:Person)
      PER PATH {
        SET @out_edge += 1
      }
      """
    Then an Error should be raised: "[NS209]: Current working graph not found"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE prop SumAgg<INT> = 0
        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER PATH {
          SET s.@prop = 1
        }
      }
      """
    Then an Error should be raised:
      """
      [NS238]: Invalid match compute block: NODE aggregator assignment `s.@prop = CAST(1 AS INT64)` is not allowed in the PER PATH clause
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE prop SumAgg<INT> = 0
        MATCH (s:Person)-[e:KNOWS]->(t:Person)
        PER PATH {
          VALUE i = 0
          WHILE i < 10 THEN {
            IF s.id > 1 THEN {
              SET s.@prop = 1
            }
          }
        }
      }
      """
    Then an Error should be raised:
      """
      [NS238]: Invalid match compute block: NODE aggregator assignment `s.@prop = CAST(1 AS INT64)` is not allowed in the PER PATH clause
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_nodes SumAgg<INT> = 0
        MATCH (s:Person)-[]->(t:Person)
        PER PATH {
          SET @out_nodes = 1
        }
      }
      """
    Then an Error should be raised:
      """
      [NS238]: Invalid match compute block: GLOBAL aggregator assignment `@out_nodes = CAST(1 AS INT64)` is not allowed in the PER PATH clause
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE out_nodes SumAgg<INT> = 0
        MATCH (s:Person)-[]->(t:Person)
        PER NODE (s) {
          SET @out_nodes = 1
        }
      }
      """
    Then an Error should be raised:
      """
      [NS238]: Invalid match compute block: GLOBAL aggregator assignment `@out_nodes = CAST(1 AS INT64)` is not allowed in the PER NODE clause
      """

  Scenario: Unsupported aggregator member function
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE l_int ListAgg<INT>
        MATCH (s:Person)-[]->(t:Person)
        PER NODE (s) {
          VALUE iter = 0
          WHILE iter < 1 THEN {
            SET iter = iter + 1
            SET @l_int.clear()
          }
        }
      }
      """
    Then an Error should be raised:
      """
      [NS238]: Invalid match compute block: GLOBAL aggregator mutable member function `@l_int.clear()` is not allowed in the PER NODE clause
      """
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        NODE VALUE l_int ListAgg<INT>
        MATCH (s:Person)-[]->(t:Person)
        PER PATH {
          VALUE iter = 0
          WHILE iter < 1 THEN {
            SET iter = iter + 1
            SET s.@l_int.clear()
          }
        }
      }
      """
    Then an Error should be raised:
      """
      [NS238]: Invalid match compute block: NODE aggregator mutable member function `s.@l_int.clear()` is not allowed in the PER PATH clause
      """

  Scenario: Unsupported common expressions
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s)
        PER NODE (s) {
          VALUE x = VALUE{ return 1 LIMIT 1}
          LOG_INFO(x)
        }
      }
      """
    Then an Error should be raised:
      """
      [NS238]: Invalid match compute block: Subquery `VALUE { RETURN 1 LIMIT 1 }` is not allowed in the PER NODE clause
      """

  Scenario: Unsupported definition
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s)
        PER NODE (s) {
          TABLE t TYPED TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING}
          LOG_INFO("invalid definition")
        }
      }
      """
    Then an Error should be raised: "Invalid variable definition: `t:TABLE {prop1 INT8, prop2 FLOAT, prop3 STRING}` can only be defined in the global scope"
    When executing graph query:
      """
      USE #analytic_ldbc {
        MATCH (s)
        PER NODE (s) {
          GRAPH g = GRAPH{ USE #analytic_ldbc MATCH (a) RETURN a }
          LOG_INFO("invalid definition")
        }
      }
      """
    Then an Error should be raised: "g:GRAPH<NODES[(Comment),(Forum),(Organisation),(Person),(Place),(Post),(Tag),(TagClass)],EDGES[(Comment)-[HAS_CREATOR_2]->(Person),(Comment)-[HAS_TAG_3]->(Tag),(Comment)-[IS_LOCATED_IN_2]->(Place),(Comment)-[REPLY_OF_1]->(Post),(Comment)-[REPLY_OF_2]->(Comment),(Forum)-[CONTAINER_OF]->(Post),(Forum)-[HAS_MEMBER]->(Person),(Forum)-[HAS_MODERATOR]->(Person),(Forum)-[HAS_TAG_1]->(Tag),(Organisation)-[IS_LOCATED_IN_4]->(Place),(Person)-[FOLLOWS]->(Person),(Person)-[HAS_INTEREST]->(Tag),(Person)-[IS_LOCATED_IN_1]->(Place),(Person)-[KNOWS]->(Person),(Person)-[LIKES_1]->(Post),(Person)-[LIKES_2]->(Comment),(Person)-[STUDY_AT]->(Organisation),(Person)-[WORK_AT]->(Organisation),(Place)-[IS_PART_OF]->(Place),(Post)-[HAS_CREATOR_1]->(Person),(Post)-[HAS_TAG_2]->(Tag),(Post)-[IS_LOCATED_IN_3]->(Place),(Tag)-[HAS_TYPE]->(TagClass),(TagClass)-[IS_SUBCLASS_OF]->(TagClass)]>`"

  Scenario: Unsupported common statements
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s)
        PER NODE (s) {
          MATCH (s) PER NODE (s) {
            LOG_INFO("invalid statement")
          }
        }
      }
      """
    Then an Error should be raised: "[42N51]: Invalid syntax, `MatchCompute` statement is not supported in the PER NODE clause"
    When executing graph query:
      """
      USE #analytic_ldbc {
        MATCH (s)
        PER NODE (s) {
          IF true THEN {
            MATCH (a) RETURN a
          }
        }
      }
      """
    Then an Error should be raised: "[42N51]: Invalid syntax, `Match` statement is not supported in the PER NODE clause"
    When executing graph query:
      """
      USE #analytic_ldbc {
        MATCH (s)
        PER NODE (s) {
          IF true THEN {
            RETURN 1
          }
        }
      }
      """
    Then an Error should be raised: "[42N51]: Invalid syntax, `Return` statement is not supported in the PER NODE clause"

  Scenario: Unsupported graph pattern
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH DIFFERENT EDGES (a)-[e]->(b)
        PER NODE (v) {
          LOG_INFO("test")
        }
        FINISH
      }
      """
    Then an Error should be raised: "[NT302]: Match mode `DIFFERENT EDGES` is not supported in MATCH COMPUTE statement"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s),(t)
        PER NODE (s) {
          LOG_INFO("test")
        }
        FINISH
      }
      """
    Then an Error should be raised: "[NT302]: Multi path patterns `(s),(t)` is not supported in MATCH COMPUTE statement"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH TRAIL (s)-[e]->(t)
        PER NODE (s) {
          LOG_INFO("test")
        }
        FINISH
      }
      """
    Then an Error should be raised: "[NT302]: Path search mode `ALL TRAIL` is not supported in MATCH COMPUTE statement"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s)-[e]->(v)-[e1]->(t)
        PER NODE (s) {
          LOG_INFO("test")
        }
        FINISH
      }
      """
    Then an Error should be raised: "[NT302]: Multi hop path pattern `(s)-[e]->(v)-[e1]->(t)` is not supported in MATCH COMPUTE statement"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s)-[e]->{1,3}(t)
        PER NODE (s) {
          LOG_INFO("test")
        }
        FINISH
      }
      """
    Then an Error should be raised: "[NT302]: Path factor `-[e]->{1,3}` is not supported in MATCH COMPUTE statement"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        MATCH (s)((v)-[e]->(u)){1,3}(t)
        PER NODE (s) {
          LOG_INFO("test")
        }
        FINISH
      }
      """
    Then an Error should be raised: "[NT302]: Path factor `(WALK (v)-[e]->(u)){1,3}` is not supported in MATCH COMPUTE statement"

  Scenario: Unsupported variable assignment
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE x = 1
        MATCH (s)-[e]->(t)
        PER NODE (s) {
          SET x = 2
        }
      }
      """
    Then an Error should be raised: "[NS238]: Invalid match compute block: Assignment to INT32 variable `x` not defined in the PER NODE clause is not allowed"
    When executing graph analytic query:
      """
      USE #analytic_ldbc {
        VALUE active_set ACTIVE_SET

        MATCH (s)-[e]->(t)
        PER NODE (s) {
          SET active_set = []
        }
      }
      """
    Then an Error should be raised: "[NS238]: Invalid match compute block: Assignment to ActiveSet variable `active_set` not defined in the PER NODE clause is not allowed"

  Scenario: Unsupported analyticd features
    When executing analytic query:
      """
      USE #analytic_ldbc MATCH (v) RETURN v
      """
    Then an Error should be raised: "[AN002]: `Match` is not supported by analytic service"

  Scenario: Unsupported dml mixes match-compute
    When executing graph query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS unsupported_dml_mix_match_compute_t AS {
        NODE player ( LABEL player {id INT PRIMARY KEY} ),
        EDGE knows (player)-[ LABEL knows {} ]->(player)
      }
      """
    Then the execution should be successful
    When executing graph query:
      """
      CREATE TEMPORARY GRAPH #unsupported_dml_mix_match_compute_g TYPED unsupported_dml_mix_match_compute_t
      """
    Then the execution should be successful
    When executing graph query:
      """
      USE #unsupported_dml_mix_match_compute_g
      INSERT (v1@player {id: 1}), (v2@player {id: 2}), (v3@player {id: 3}), (v1)-[@knows]->(v2), (v1)-[@knows]->(v3)
      """
    Then the execution should be successful
    When executing graph query:
      # place the DML statements at the end is ok
      """
      USE #unsupported_dml_mix_match_compute_g {
        NODE VALUE cnt SumAgg<INT> = 0

        MATCH (p1@player)-[k@knows]->(p2@player)
        PER NODE (p1) {
          SET p1.@cnt += 1
        }

        MATCH (p1@player)-[k@knows]->(p2@player)
        PER NODE (p1) {
          SET p1.@cnt += 1
        }

        INSERT (@player {id: 4})
      }
      """
    Then the execution should be successful
    When executing graph query:
      # interleave DML statements with match-compute is not allowed
      """
      USE #unsupported_dml_mix_match_compute_g {
        NODE VALUE cnt SumAgg<INT> = 0

        MATCH (p1@player)-[k@knows]->(p2@player)
        PER NODE (p1) {
          SET p1.@cnt += 1
        }

        INSERT (@player {id: 5})

        MATCH (p1@player)-[k@knows]->(p2@player)
        PER NODE (p1) {
          SET p1.@cnt += 1
        }
      }
      """
    Then an Error should be raised: "[NR153]: Temporary graph failed to execute match-compute: LocalID map expired. Probably match-compute is mixed with DML operations."
    And drop the graph "#unsupported_dml_mix_match_compute_g"
    And drop the graph type "unsupported_dml_mix_match_compute_t"
