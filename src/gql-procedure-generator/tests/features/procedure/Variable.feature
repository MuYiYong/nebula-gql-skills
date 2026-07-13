# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: variable

  Scenario: variable assignment
    And use graph "ldbc"
    When executing query:
      """
      VALUE a = 1
      SET a = a + 1
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    When executing query:
      """
      VALUE v = [1,2]
      SET v = VALUE { RETURN v || [3] LIMIT 1}
      RETURN v
      """
    Then the result should be, in any order:
      | v            |
      | LIST [1,2,3] |
    # Currently, we do not support updating the fields of a record variable.
    # And actually, the syntax in the form `set a.b` is parsed as a DML set statement
    # rather than a variable assignment now.
    When executing query:
      """
      VALUE r = {a:3, b:4}
      SET r.a = 5
      """
    Then an Error should be raised: "[NR231]: The type of element r updated in the set statement must be Node or Edge"
    When executing query:
      """
      VALUE v = SET{1,2}
      SET v = VALUE { RETURN v || SET{3} LIMIT 1}
      RETURN v
      """
    Then the result should be, in any order:
      | v           |
      | SET {1,2,3} |
    When executing query:
      """
      VALUE v = MAP{"1":2, "2":3}
      SET v = VALUE { RETURN v || MAP{"3":4} LIMIT 1}
      RETURN v
      """
    Then the result should be, in any order:
      | v                        |
      | MAP {"1":2,"2":3, "3":4} |

  @skip
  Scenario: variable assignment in inline procedure
    Given a graph named "ldbc"
    When executing query:
      """
      VALUE a = 1
      CALL {
        SET a = a + 1
      }
      RETURN a
      """
    Then the result should be, in any order:
      | a |
      | 2 |
    # The operator || is used to concat strings
    When executing query:
      """
      MATCH (v:Person)
      CALL {
          VALUE a = v.firstName
          SET a = a || " " || v.lastName
          RETURN a
      }
      RETURN v.firstName AS firstName, v.lastName As lastName, a AS fullName
      """
    Then the result should be, in any order:
      | firstName | lastName  | fullName         |
      | "Sophie"  | "Marceau" | "Sophie Marceau" |
      | "Ming"    | "Yao"     | "Ming Yao"       |
      | "Tim"     | "Duncan"  | "Tim Duncan"     |
      | "Kyle"    | "cao"     | "Kyle cao"       |
    When executing query:
      """
      MATCH (v:Person)
      CALL {
          VALUE a = v.firstName
          CALL {
              SET a = a || " " || v.lastName
          }
          RETURN a
      }
      RETURN v.firstName AS firstName, v.lastName As lastName, a AS fullName
      """
    Then the result should be, in any order:
      | firstName | lastName  | fullName         |
      | "Sophie"  | "Marceau" | "Sophie Marceau" |
      | "Ming"    | "Yao"     | "Ming Yao"       |
      | "Tim"     | "Duncan"  | "Tim Duncan"     |
      | "Kyle"    | "cao"     | "Kyle cao"       |
    And reset graph

  Scenario: graph element variable cross graphs typed same graph type
    When executing query:
      """
      CREATE GRAPH TYPE cross_graph_var_test_gt {
        NODE nt (LABEL nt {id INT32 PRIMARY KEY}),
        EDGE et (nt)~[LABEL et {id INT32 MULTIEDGE KEY}]~(nt)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH cross_graph_var_test_g1 TYPED cross_graph_var_test_gt
      """
    Then the execution should be successful
    And graph "cross_graph_var_test_g1" should be ready to use
    When executing query:
      """
      TABLE t {id} = (1), (2), (10), (20)
      USE cross_graph_var_test_g1
      FOR i IN t
      INSERT (@nt{id:i.id})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {s, d, id} = (1, 10, 1), (2, 20, 2)
      USE cross_graph_var_test_g1
      FOR i IN t
      MATCH (src), (dst) WHERE src.id = i.s AND dst.id = i.d
      INSERT (src)~[@et{id: i.id}]~(dst)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH cross_graph_var_test_g2 TYPED cross_graph_var_test_gt
      """
    Then the execution should be successful
    And graph "cross_graph_var_test_g2" should be ready to use
    When executing query:
      """
      TABLE t {id} = (1), (2), (10), (20)
      USE cross_graph_var_test_g2
      FOR i IN t
      INSERT (@nt{id: i.id})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {s, d, id} = (1, 10, 1), (2, 20, 2)
      USE cross_graph_var_test_g2
      FOR i IN t
      MATCH (src), (dst) WHERE src.id = i.s AND dst.id = i.d
      INSERT (src)~[@et{id: i.id}]~(dst)
      """
    Then the execution should be successful
    When executing query:
      """
      USE cross_graph_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_graph_var_test_g2 MATCH (v) RETURN v
      """
    Then an Error should be raised:
      """
      [NS011]: Semantic error, variable `v` declared for different graphs: cross_graph_var_test_g1, cross_graph_var_test_g2
      """
    When executing query:
      """
      USE cross_graph_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_graph_var_test_g2 MATCH (v2) WHERE v2.id = v.id
      RETURN DISTINCT v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
      | 2    |
      | 10   |
      | 20   |
    When executing query:
      """
      USE cross_graph_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_graph_var_test_g2 MATCH (v2) RETURN [v, v2] AS l
      NEXT
      USE cross_graph_var_test_g1 MATCH (v3) WHERE v3 IN l
      RETURN DISTINCT v3.id
      """
    Then the result should be, in any order:
      | v3.id |
      | 1     |
      | 2     |
      | 10    |
      | 20    |
    When executing query:
      """
      USE cross_graph_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_graph_var_test_g2 MATCH (v2) WHERE v2 = v RETURN v.id
      """
    Then the result should be, in order:
      | v.id |
    When executing query:
      """
      CALL {
        USE cross_graph_var_test_g1 MATCH (v) RETURN v
        UNION
        USE cross_graph_var_test_g2 MATCH (v) RETURN v
      }
      RETURN count(v) AS cnt
      GROUP BY ()
      """
    # FIXME(wuu): wait vector to support multiple nodes
    # Then the result should be, in order:
    # | cnt |
    Then the execution should be successful
    When executing query:
      """
      VALUE v = 1
      USE cross_graph_var_test_g1
      MATCH (v) RETURN v
      """
    Then an Error should be raised:
      """
      [42N23]: Invalid syntax, redefined variable: `v` with conflict type(`Node` vs `INT32`)
      """
    When executing query:
      """
      USE cross_graph_var_test_g1 MATCH ()-[e]-() RETURN e
      NEXT
      USE cross_graph_var_test_g2 MATCH ()-[e]-() RETURN e
      """
    Then an Error should be raised:
      """
      [NS011]: Semantic error, variable `e` declared for different graphs: cross_graph_var_test_g1, cross_graph_var_test_g2
      """
    When executing query:
      """
      USE cross_graph_var_test_g1 MATCH ()-[e]-() RETURN e
      NEXT
      USE cross_graph_var_test_g2 MATCH ()-[e2]-() WHERE e2.id = e.id
      RETURN DISTINCT e.id
      """
    Then the result should be, in any order:
      | e.id |
      | 1    |
      | 2    |
    When executing query:
      """
      USE cross_graph_var_test_g1 MATCH ()-[e]-() RETURN e
      NEXT
      USE cross_graph_var_test_g2 MATCH ()-[e2]-() WHERE e2 = e RETURN e
      """
    Then the result should be, in order:
      | e |
    When executing query:
      """
      CALL {
        USE cross_graph_var_test_g1 MATCH ()-[e]-() RETURN e
        UNION
        USE cross_graph_var_test_g2 MATCH ()-[e]-() RETURN e
      }
      RETURN count(e) AS cnt
      GROUP BY ()
      """
    # FIXME(wuu): wait vector to support multiple nodes
    # Then the result should be, in order:
    # | cnt |
    Then the execution should be successful
    When executing query:
      """
      VALUE e = 1
      USE cross_graph_var_test_g1
      MATCH ()-[e]-() RETURN e
      """
    Then an Error should be raised:
      """
      [42N23]: Invalid syntax, redefined variable: `e` with conflict type(`Edge` vs `INT32`)
      """
    And drop the graph "cross_graph_var_test_g2"
    And drop the graph "cross_graph_var_test_g1"
    And drop the graph type "cross_graph_var_test_gt"

  Scenario: graph element variables cross graph types
    When executing query:
      """
      CREATE GRAPH TYPE cross_gt_var_test_gt1 {
        NODE nt (LABEL nt {id INT32 PRIMARY KEY}),
        EDGE et (nt)~[LABEL et {id INT32 MULTIEDGE KEY}]~(nt)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH cross_gt_var_test_g1 TYPED cross_gt_var_test_gt1
      """
    Then the execution should be successful
    And graph "cross_gt_var_test_g1" should be ready to use
    When executing query:
      """
      TABLE t {id} = (1), (2), (10), (20)
      USE cross_gt_var_test_g1
      FOR i IN t
      INSERT (@nt{id: i.id})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {s, d, id} = (1, 10, 1), (2, 20, 2)
      USE cross_gt_var_test_g1
      FOR i IN t
      MATCH (src), (dst) WHERE src.id = i.s AND dst.id = i.d
      INSERT (src)~[@et{id: i.id}]~(dst)
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH TYPE cross_gt_var_test_gt2 {
        NODE nt (LABEL nt {id INT32 PRIMARY KEY}),
        EDGE et (nt)~[LABEL et {id INT32 MULTIEDGE KEY}]~(nt)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH cross_gt_var_test_g2 TYPED cross_gt_var_test_gt2
      """
    Then the execution should be successful
    And graph "cross_gt_var_test_g2" should be ready to use
    When executing query:
      """
      TABLE t {id} = (1), (2), (10), (20)
      USE cross_gt_var_test_g2
      FOR i IN t
      INSERT (@nt{id: i.id})
      """
    Then the execution should be successful
    When executing query:
      """
      TABLE t {s, d, id} = (1, 10, 1), (2, 20, 2)
      USE cross_gt_var_test_g2
      FOR i IN t
      MATCH (src), (dst) WHERE src.id = i.s AND dst.id = i.d
      INSERT (src)~[@et{id: i.id}]~(dst)
      """
    Then the execution should be successful
    When executing query:
      """
      USE cross_gt_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_gt_var_test_g2 MATCH (v) RETURN v
      """
    Then an Error should be raised:
      """
      [NS011]: Semantic error, variable `v` declared for different graphs: cross_gt_var_test_g1, cross_gt_var_test_g2
      """
    When executing query:
      """
      USE cross_gt_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_gt_var_test_g2 MATCH (v2) WHERE v2.id = v.id
      RETURN DISTINCT v.id
      """
    Then the result should be, in any order:
      | v.id |
      | 1    |
      | 2    |
      | 10   |
      | 20   |
    When executing query:
      """
      USE cross_gt_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_gt_var_test_g2 MATCH (v2) RETURN [v, v2] AS l
      NEXT
      USE cross_gt_var_test_g1 MATCH (v3) WHERE v3 IN l
      RETURN DISTINCT v3.id
      """
    Then the result should be, in any order:
      | v3.id |
      | 1     |
      | 2     |
      | 10    |
      | 20    |
    When executing query:
      """
      USE cross_gt_var_test_g1 MATCH (v) RETURN v
      NEXT
      USE cross_gt_var_test_g2 MATCH (v2) WHERE v2 = v RETURN v
      """
    Then the result should be, in order:
      | v |
    When executing query:
      """
      CALL {
        USE cross_gt_var_test_g1 MATCH (v) RETURN v
        UNION
        USE cross_gt_var_test_g2 MATCH (v) RETURN v
      }
      RETURN count(v) AS cnt
      GROUP BY ()
      """
    # FIXME(wuu): wait vector to support multiple nodes
    # Then the result should be, in order:
    # | cnt |
    Then the execution should be successful
    When executing query:
      """
      VALUE v = 1
      USE cross_gt_var_test_g1
      MATCH (v) RETURN v
      """
    Then an Error should be raised:
      """
      [42N23]: Invalid syntax, redefined variable: `v` with conflict type(`Node` vs `INT32`)
      """
    When executing query:
      """
      USE cross_gt_var_test_g1 MATCH ()-[e]-() RETURN e
      NEXT
      USE cross_gt_var_test_g2 MATCH ()-[e]-() RETURN e
      """
    Then an Error should be raised:
      """
      [NS011]: Semantic error, variable `e` declared for different graphs: cross_gt_var_test_g1, cross_gt_var_test_g2
      """
    When executing query:
      """
      USE cross_gt_var_test_g1 MATCH ()-[e]-() RETURN e
      NEXT
      USE cross_gt_var_test_g2 MATCH ()-[e2]-() WHERE e2.id = e.id
      RETURN DISTINCT e.id
      """
    Then the result should be, in any order:
      | e.id |
      | 1    |
      | 2    |
    When executing query:
      """
      USE cross_gt_var_test_g1 MATCH ()-[e]-() RETURN e
      NEXT
      USE cross_gt_var_test_g2 MATCH ()-[e2]-() WHERE e2 = e RETURN e
      """
    Then the result should be, in order:
      | e |
    When executing query:
      """
      CALL {
        USE cross_gt_var_test_g1 MATCH ()-[e]-() RETURN e
        UNION
        USE cross_gt_var_test_g2 MATCH ()-[e]-() RETURN e
      }
      RETURN count(e) AS cnt
      GROUP BY ()
      """
    # FIXME(wuu): wait vector to support multiple nodes
    # Then the result should be, in order:
    # | cnt |
    Then the execution should be successful
    When executing query:
      """
      VALUE e = 1
      USE cross_gt_var_test_g1
      MATCH ()-[e]-() RETURN e
      """
    Then an Error should be raised:
      """
      [42N23]: Invalid syntax, redefined variable: `e` with conflict type(`Edge` vs `INT32`)
      """
    When executing query:
      """
      VALUE a = 1
      VALUE b = 2
      SET c = a + b
      RETURN c
      """
    Then an Error should be raised: "[42N18]: Invalid syntax, variable `c` not defined"
    And drop the graph "cross_gt_var_test_g2"
    And drop the graph "cross_gt_var_test_g1"
    And drop the graph type "cross_gt_var_test_gt2"
    And drop the graph type "cross_gt_var_test_gt1"

  Scenario: random element
    When executing query:
      """
      VALUE x = rand()
      RETURN x
      """
    Then the execution should be successful
