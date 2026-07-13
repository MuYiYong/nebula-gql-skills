# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: call inline procedure

  Scenario: basic
    When executing query:
      """
      LET a = 1
      CALL { RETURN 2 AS b, 3 AS c  }
      RETURN *
      """
    Then the result should be, in any order:
      | a | b | c |
      | 1 | 2 | 3 |
    When executing query:
      """
      LET a = 1
      CALL { LET b = 2 FILTER false RETURN b  }
      RETURN *
      """
    Then the result should be, in any order:
      | a | b |
    When executing query:
      """
      LET a = 1
      OPTIONAL CALL { LET b = 2 FILTER FALSE RETURN b  }
      RETURN *
      """
    Then the result should be, in any order:
      | a | b    |
      | 1 | null |
    When executing query:
      """
      LET a = 1
      CALL { RETURN 2 AS a }
      RETURN a
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `a`"
    When executing query:
      """
      LET a = 1
      CALL { RETURN a }
      RETURN a
      """
    Then an Error should be raised: "[NS002]: Semantic error, duplicate defined variable: `a`"
    When executing query:
      """
      USE ldbc
      LET a = 1
      CALL { MATCH (v:Person) RETURN v.id AS b }
      RETURN *
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 1 |
      | 1 | 2 |
      | 1 | 3 |
      | 1 | 4 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      OPTIONAL CALL { MATCH (v:Person) RETURN v.id AS b }
      RETURN *
      """
    Then the result should be, in any order:
      | a | b |
      | 1 | 1 |
      | 1 | 2 |
      | 1 | 3 |
      | 1 | 4 |
    When executing query:
      """
      USE ldbc
      LET a = 1
      OPTIONAL CALL { MATCH (v:Person) FILTER FALSE RETURN v.id AS b }
      RETURN *
      """
    Then the result should be, in any order:
      | a | b    |
      | 1 | null |
    When executing query:
      """
      USE ldbc
      LET a = 100
      CALL { MATCH (v:Person)-[e:KNOWS]->(v2:Person) RETURN v2.id AS b }
      RETURN *
      """
    Then the result should be, in any order:
      | a   | b |
      | 100 | 1 |
      | 100 | 2 |
      | 100 | 3 |
    When executing query:
      """
      USE ldbc
      LET a = 2
      CALL { RETURN a + 3 AS b, VALUE { RETURN a + 10 LIMIT 1} AS c }
      RETURN a, b, c
      """
    Then the result should be, in any order:
      | a | b | c  |
      | 2 | 5 | 12 |
    # sort the unioned result
    When executing query:
      """
      CALL {
        RETURN 3 AS a, 100 AS b
        UNION ALL
        RETURN 1 AS a, 200 AS b
      }
      ORDER BY a
      RETURN a, b
      """
    Then the result should be, in any order:
      | a | b   |
      | 1 | 200 |
      | 3 | 100 |
    When executing query:
      """
      VALUE a = 1
      VALUE b = 0.1
      CALL {
        LET c = a + 2
        RETURN c, b + c + 3 AS d
      } RETURN c, d
      """
    Then the result should be, in any order:
      | c | d    |
      | 3 | 6.1M |
    When executing query:
      """
      VALUE a = 1
      VALUE b = 0.1
      CALL {
        LET c = a * 2
        CALL {
            LET d = a + b + c
            LET e = 5
            RETURN d, e
        }
        RETURN c, d, b * 3 AS f, a + e  AS g
      } RETURN a, c, d, g
      """
    Then the result should be, in any order:
      | a | c | d    | g |
      | 1 | 2 | 3.1M | 6 |
    When executing query:
      """
      TABLE t {name} = ("Kyle"), ("Tim")
      USE ldbc
      FOR r IN t
      CALL {
        MATCH (:Person {firstName: r.name})-[:WORK_AT]->(v)
        RETURN v.name AS company
      }
      RETURN company
      """
    Then the result should be, in any order:
      | company |
      | "org1"  |
      | "org2"  |

  Scenario: linear ends rule for inline CALL
    When executing query:
      """
      CALL { RETURN 1 AS a }
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement"
    When executing query:
      """
      IF true THEN { CALL { RETURN 1 AS a } }
      RETURN 2 AS b
      """
    Then an Error should be raised: "[42N47]: Invalid syntax, linear query should ends with RETURN or FINISH statement"

  Scenario: unsupported
    # FIXME(jie): enable it after https://github.com/vesoft-inc/nebula-ng/issues/8613 is fixed
    # When executing query:
    # """
    # USE ldbc
    # FOR i IN range(1,10)
    # CALL {
    # INSERT(a@Person{id:i})
    # }
    # """
    # Then an Error should be raised: "[NT000]: Insert statement is not supported in the nested query for now"
    When executing query:
      """
      CALL { CREATE GRAPH TYPE inline_call_nested_type AS {} }
      """
    Then an Error should be raised: "[NS241]: Only DQL is allowed in subquery"

  Scenario: Multi threads window
    When executing query:
      """
      /*+SET_VAR(query_concurrency = 2)*/
      USE ldbc
      FOR id IN range(1,4)
      CALL {
        MATCH (current:Person{id:id})-[e:KNOWS]->(next_node:Person)
        ORDER BY e.creationDate LIMIT 1 RETURN collect(next_node.id)
      }
      RETURN *
      """
    Then the result should be, in any order:
      | collect(next_node.id) | id |
      | LIST [1]              | 1  |
      | LIST [2]              | 2  |
      | LIST [3]              | 3  |
      | LIST []               | 4  |

  Scenario: Control Flow inside inline CALL
    When executing query:
      """
      VALUE a = 1
      CALL {
        IF a = 1 THEN {
          RETURN a AS b
        } ELSE {
          RETURN 2 AS b
        }
      }
      RETURN b
      """
    Then the result should be, in any order:
      | b |
      | 1 |
    When executing query:
      """
      VALUE a = 2
      CALL {
        WHILE a > 0 THEN {
          SET a = a - 1
          LOG_INFO(a)
        }
        RETURN a AS b
      }
      RETURN b
      """
    Then the result should be, in any order:
      | b |
      | 0 |
    # nested call
    When executing query:
      """
      VALUE a = 2
      CALL {
        VALUE b = a + 3
        CALL {
          WHILE b > 0 THEN {
            SET b = b - 1
            LOG_INFO(b)
          }
          RETURN b AS c
        }
        RETURN c AS d
      }
      RETURN d
      """
    Then the result should be, in any order:
      | d |
      | 0 |
    When executing query:
      """
      CREATE OR REPLACE PROCEDURE inline_proc_in_proc(a INT) RETURNS ret int AS {
        CALL {
          VALUE b = a
          WHILE b > 0 THEN {
            SET b = b - 1
            LOG_INFO(b)
          }
          RETURN b
        }
        RETURN b AS ret
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CALL inline_proc_in_proc(2) RETURN ret
      """
    Then the result should be, in any order:
      | ret |
      | 0   |
    And drop the procedure "inline_proc_in_proc"
    When executing query:
      """
      VALUE v1 = EXISTS { RETURN 1 AS v1, 2 AS v2 LIMIT 1}
      VALUE v2 = EXISTS { RETURN 1 AS v1, 2 AS v2 LIMIT 1}
      RETURN v1, v2
      """
    Then the result should be, in any order:
      | v1   | v2   |
      | true | true |
    When executing query:
      """
      VALUE v1 = 5
      CALL {
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
          IF v1 = 2 THEN {
            BREAK
          }
        }
        RETURN v1 AS val
      }
      RETURN val
      """
    Then the result should be, in any order:
      | val |
      | 2   |
    When executing query:
      """
      VALUE v1 = 5
      CALL {
        VALUE v2 = 0
        WHILE v1 > 0 THEN {
          SET v1 = v1 - 1
          IF v1 <= 2 THEN {
            CONTINUE
          }
          SET v2 = v2 + 1
        }
        RETURN v2
      }
      RETURN v2
      """
    Then the result should be, in any order:
      | v2 |
      | 2  |

  @sf01
  Scenario: sf01 Control Flow inside inline CALL
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 15393162789604})
      CALL {
        IF v.id > 0 THEN {
          MATCH (t:Person)-[:KNOWS]->(v) RETURN t.id AS b ORDER BY b LIMIT 1
        } ELSE {
          RETURN -1 AS b
        }
      }
      RETURN b
      """
    Then the result should be, in any order:
      | b  |
      | 94 |
    # complex node/edge reference
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 15393162789604})
      CALL {
        IF v.id > 0 THEN {
          MATCH (v WHERE v.id = 0) RETURN v.id AS b
        } ELSE {
          RETURN -1 AS b
        }
      }
      RETURN b
      """
    Then the result should be, in any order:
      | b |
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 15393162789604})
      CALL {
        IF v.id > 0 THEN {
          OPTIONAL MATCH (v WHERE v.id = 0) RETURN v.id AS b
        } ELSE {
          RETURN -1 AS b
        }
      }
      RETURN b
      """
    Then the result should be, in any order:
      | b              |
      | 15393162789604 |
    When executing query:
      """
      USE sf01
      MATCH (v:Person{id: 15393162789604})-[:KNOWS]->(f:Person{id: 15393162790510})
      CALL {
        IF v.id > 0 THEN {
          MATCH (f)<-[:KNOWS]-(v) RETURN v.id AS b ORDER BY b
        } ELSE {
          RETURN -1 AS b
        }
      }
      RETURN v.id AS vid, f.id AS fid, b
      """
    Then the result should be, in any order:
      | vid            | fid            | b              |
      | 15393162789604 | 15393162790510 | 15393162789604 |
    When executing query:
      """
      USE sf01 {
        VALUE v1 = 5
        MATCH (v:Person{id: 8796093022449})
        LET v2 = VALUE {
          IF v.id > 0 THEN {
            RETURN v.id AS val
          } ELSE {
            RETURN v1 AS val
          }
        }
        RETURN v2
      }
      """
    Then the result should be, in any order:
      | v2            |
      | 8796093022449 |
    When executing query:
      """
      USE sf01 {
        VALUE v1 = 5
        MATCH (v:Person{id: 8796093022449})
        LET v2 = VALUE {
          IF v.id > 0 THEN {
            RETURN v1 AS val
          } ELSE {
            RETURN v.id AS val
          }
        }
        RETURN v2
      }
      """
    Then the result should be, in any order:
      | v2 |
      | 5  |
    When executing query:
      """
      USE sf01
      RETURN VALUE{
        MATCH (v:Person{id: -1})
        DELETE v
        NEXT RETURN 1 LIMIT 1
      } AS v2
      """
    Then an Error should be raised: "[NS251]: Unsupported statement in subquery: DML"
    # nested inline proc and subquery
    When executing query:
      """
      USE sf01 {
        MATCH (v1:Person{id: 8796093022449})
        CALL {
          VALUE fac = 3
          VALUE v1id = v1.id
          VALUE v2id = VALUE { MATCH (v2:Person{id: v1.id}) RETURN v2.id + 1 AS v1id LIMIT 1 }
          IF v1.id > 0 THEN {
              CALL {
                  VALUE val = 1
                  WHILE fac > 0 THEN {
                      SET val = val * fac
                      SET fac = fac - 1
                  }
                  RETURN val
              }
              RETURN v2id AS ret, val
          } ELSE {
              RETURN v1id AS ret, 0 as val
          }
        }
        RETURN ret, val
      }
      """
    Then the result should be, in any order:
      | ret           | val |
      | 8796093022450 | 6   |
    # call inline procedure within subquery
    When executing query:
      """
      USE sf01 {
        MATCH (v1:Person{id: 8796093022449})
        LET msg = VALUE {
          MATCH (v1)-[:KNOWS]->(f:Person)
          RETURN COUNT(f) AS fcnt
          NEXT
          CALL {
            IF fcnt > 0 THEN {
              RETURN "We have friends" AS msg
            } ELSE {
              RETURN "No friends" AS msg
            }
          }
          RETURN msg
        }
        RETURN msg
      }
      """
    Then the result should be, in any order:
      | msg               |
      | "We have friends" |

  Scenario: CALL with PER NODE on temporary graph
    When executing graph analytic query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS gt_movie_temp_graph AS {
        NODE movie (LABEL movie {id INT PRIMARY KEY, title STRING}),
                 NODE TYPE `Actor` (LABEL `Person`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `birthDate` DATE DEFAULT NULL, PRIMARY KEY (`id`)}),
                 NODE TYPE `Director` (LABEL `Person`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, `birthDate` DATE DEFAULT NULL, PRIMARY KEY (`id`)}),
                 NODE TYPE `User` (LABEL `Person`{`id` INT64 NOT NULL, PRIMARY KEY (`id`)}),
                 NODE TYPE `Movie` (LABEL `Movie`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
                 NODE TYPE `Genre` (LABEL `Genre`{`id` INT64 NOT NULL, `name` STRING DEFAULT NULL, PRIMARY KEY (`id`)}),
                 EDGE TYPE `Act` (`Actor`)-[LABEL `Act`{}]->(`Movie`),
                 EDGE TYPE `Direct` (`Director`)-[LABEL `Direct`{}]->(`Movie`),
                 EDGE TYPE `Watch` (`User`)-[LABEL `Watch`{`rate` FLOAT DEFAULT NULL}]->(`Movie`),
                 EDGE TYPE `WithGenre` (`Movie`)-[LABEL `WithGenre`{}]->(`Genre`)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS g_movie_temp_graph TYPED gt_movie_temp_graph
      """
    Then the execution should be successful
    When executing query:
      """
      USE g_movie_temp_graph
      INSERT OR REPLACE (@movie {id:1, title: "Movie 1"}), (@movie {id:2, title: "Movie 2"}), (@movie {id:3, title: "Movie 3"}), (@movie {id:4, title: "Movie 4"})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {Actor_id, Actor_name, Movie_id, Movie_name} =
      {Actor_id:11, Actor_name:"actor11", Movie_id:11, Movie_name:"movie11"},
      {Actor_id:12, Actor_name:"actor11", Movie_id:13, Movie_name:"movie13"},
      {Actor_id:12, Actor_name:"actor11", Movie_id:13, Movie_name:"movie13"},
      {Actor_id:11, Actor_name:"actor11", Movie_id:12, Movie_name:"movie12"},
      {Actor_id:13, Actor_name:"actor11", Movie_id:11, Movie_name:"movie11"}
      USE g_movie_temp_graph
      FOR r in t
      INSERT OR REPLACE (@Actor{id:r.Actor_id, name:r.Actor_name})-[:Act]->(@Movie{id:r.Movie_id, name:r.Movie_name})
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #movie_temporary_graph AS COPY OF g_movie_temp_graph
      """
    Then the execution should be successful
    When executing query:
      """
      USE #movie_temporary_graph
      CALL {
        MATCH (a) WHERE a.id IN [1,2,3]
        PER NODE (a) {
          LOG_INFO(a)
        }
      }
      """
    Then the execution should be successful
    When executing query:
      """
      USE #movie_temporary_graph
      {
        TABLE person_rows TYPED TABLE {flag INT}
        MATCH (v)-[e]->() WHERE v IS LABELED Person
        PER NODE (v) {
          EXPORT 1 AS flag INTO person_rows
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      DROP GRAPH IF EXISTS #movie
      """
    Then the execution should be successful
    When executing analytic query:
      """
      CREATE TEMPORARY GRAPH IF NOT EXISTS #movie typed gt_movie_temp_graph partition by default
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #movie IMPORT INTO GRAPH
      {
        GRAPH FROM NEBULA{
          PATH:"nebula://root:NebulaGraph01@${TCK_GRAPH_ADDRESS}?graph=g_movie_temp_graph&tls_enable=${TCK_GRAPH_TLS_ENABLED}&tls_ca=${TCK_GRAPH_TLS_CA_CERT}&tls_cert=${TCK_GRAPH_TLS_CERT}&tls_key=${TCK_GRAPH_TLS_KEY}&tls_peer_name=graph.server.vesoft.com"
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #movie
      {
        TABLE person_rows TYPED TABLE {flag INT}
        MATCH (v)-[e]->() WHERE v IS LABELED Person
        PER NODE (v) {
          EXPORT 1 AS flag INTO person_rows
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #movie
      CALL {
        MATCH (v:Person)-[e]->() WHERE v IS LABELED Person
        PER NODE (v) {
          LOG_INFO(v)
        }
      }
      """
    Then the execution should be successful
    When executing analytic query:
      """
      USE #movie {
          VALUE sampleUniqueNeighbor SumAgg<INT64> = 0
          MATCH (s@Movie{id: 18})-[e SAMPLE RIGHT UNIQUE_NEIGHBOR 2]->(t)
          PER PATH {SET @sampleUniqueNeighbor += 1}
          RETURN @sampleUniqueNeighbor
      }
      """
    Then the execution should be successful
    And drop the graph "#movie_temporary_graph"
    And drop the graph "g_movie_temp_graph"
    And drop the graph type "gt_movie_temp_graph"
