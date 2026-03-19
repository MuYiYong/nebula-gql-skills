# Copyright (c) 2024 vesoft inc. All rights reserved.
Feature: Type inference cases

  # https://github.com/vesoft-inc/nebula-ng/issues/3269
  Scenario: Collapse subtypes
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS graph_with_pk_null_value_datatype as {
        NODE Place (LABEL Place  {id INT primary key,intprop4 INT64,bprpo boolean}),
        NODE Place2 (LABEL Place2 {id INT,intprop4 INT64,bprpo boolean, name STRING primary key})
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS graph_with_pk_null_value graph_with_pk_null_value_datatype
      """
    Then the execution should be successful
    And graph "graph_with_pk_null_value" should be ready to use
    When executing query:
      """
      USE graph_with_pk_null_value INSERT (@Place{id:12, intprop4:64, bprpo:true})
      """
    Then the execution should be successful
    When executing query:
      """
      USE graph_with_pk_null_value MATCH (v) RETURN v.id as vid
      """
    Then the result should be, in any order:
      | vid |
      | 12  |
    And drop the graph "graph_with_pk_null_value"
    And drop the graph type "graph_with_pk_null_value_datatype"

  @sf01
  Scenario: Complex type inference
    # KNOWS is directed, so the generated plan should not contain a undirected edge scan of KNOWS.
    When executing query:
      """
      EXPLAIN USE sf01 MATCH ()-[e:KNOWS]-() RETURN e
      """
    Then the execution should be successful
    When executing query:
      """
      EXPLAIN USE sf01 MATCH ()~[e:KNOWS]~() RETURN e
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `~[e:KNOWS]~` was found"
    When executing query:
      """
      EXPLAIN USE sf01 MATCH REPEATABLE ELEMENTS p = (v1:University)-[e:KNOWS]->(v2:City) RETURN *
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(v1:University)-[e:KNOWS]->(v2:City)` was found"
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = TRAIL (v1:University)-[e:KNOWS]->*(v2:City) RETURN *
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:KNOWS]->{0,}` was found"
    When executing query:
      """
      EXPLAIN USE sf01 MATCH DIFFERENT EDGES p = (v1)-[e:IS_LOCATED_IN]->{1,}(v2) RETURN *
      """
    Then the execution should be successful
    # v1: empty;    e; empty;           v2: empty
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = TRAIL (v1)-[e:IS_LOCATED_IN]->{2,}(v2) RETURN *
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:IS_LOCATED_IN]->{2,}` was found"
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = TRAIL (v1:Person)-[e:IS_LOCATED_IN]->{1,}(v2:City) RETURN *
      """
    Then the execution should be successful
    # v1: City;     e: empty;           v2: City
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = SIMPLE (v1)-[e:STUDY_AT]->*(v2:City) RETURN *
      """
    Then the execution should be successful
    # v1: empty;   e: empty;            v2: empty
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = ACYCLIC (v1)-[e:STUDY_AT]->+(v2:City) RETURN *
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:STUDY_AT]->{1,}` was found"
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = (v1)-[e:STUDY_AT]->{0, 1}(v2:City) RETURN *
      """
    Then the execution should be successful
    # v1: City;     e: empty;           v2: City
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = (v1)-[e:STUDY_AT]->{0, 2}(v2:City) RETURN *
      """
    Then the execution should be successful
    # v1: Person;   e: PERSON_STUDY_AT_UNIVERSITY, UNIVERSITY_IS_LOCATED_IN_CITY;   v2: City
    # v1: Person;   e: PERSON_KNOWS_PERSON, PERSON_IS_LOCATED_IN_CITY               v2: City
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = (v1:Person)-[e]->{2}(v2:City) RETURN *
      """
    Then the execution should be successful
    # v1: empty;     e: empty;          v2: empty
    When executing query:
      """
      EXPLAIN USE sf01 MATCH p = (v1:Person)-[e:STUDY_AT]->{2}(v2:City) RETURN *
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:STUDY_AT]->{2}` was found"
    When executing query:
      """
      USE sf01 MATCH ANY SHORTEST (v1{id:318})-[e:STUDY_AT]->*(v2:Tag) RETURN v1.id, v2.id
      """
    Then the result should be, in any order:
      | v1.id | v2.id |
      | 318   | 318   |
    When executing query:
      """
      use ldbc match p=(n:Person)-[e:WORK_AT]-{2}(m:Person) return count(p)
      """
    Then the result should be, in any order:
      | count(p) |
      | 3        |

  Scenario: Type infer for quantified path pattern
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS transfer_network AS {
      NODE Address (:Address {address_id INT PRIMARY KEY, is_contract bool}),
      NODE Transfer (:Transfer {amount float, amount_in_usd float, block_number int,transaction_index int, transfer_index int ,token_address_id int, PRIMARY KEY(block_number,transaction_index,transfer_index)}),
      NODE FLAG (:FLAG {flagid string PRIMARY KEY}),
      EDGE `FROM` (Transfer)-[:`FROM`]->(Address),
      EDGE TO (Transfer)-[:TO]->(Address),
      EDGE FLAGGED_AS (Address)-[:FLAGGED_AS]->(FLAG)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS transfer_network :: transfer_network
      """
    Then the execution should be successful
    And graph "transfer_network" should be ready to use
    When executing query:
      """
      explain use transfer_network
      match p = trail (:Address{address_id:1002})(()<-[:`FROM`]-(T1:Transfer)-[:TO]->()<-[:`FROM`]-(T2:Transfer)-[:TO]->() where T2.block_number > T1.block_number){1,10}(:Address)->(v3:FLAG) return p
      """
    Then the execution should be successful
    And drop the graph "transfer_network"

  # Edge cases for path pattern type inference refactoring
  Scenario: Edge direction semantics - all 7 direction types
    # PointingRight (-[]->) with directed edge
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e:KNOWS]->(b) RETURN count(*)
      """
    Then the execution should be successful
    # PointingLeft (<-[]-) with directed edge - reverse traversal
    When executing query:
      """
      USE ldbc MATCH (a:Person)<-[e:KNOWS]-(b) RETURN count(*)
      """
    Then the execution should be successful
    # Undirected (~[]~) with directed edge - should fail (KNOWS is directed)
    When executing query:
      """
      USE ldbc MATCH (a:Person)~[e:KNOWS]~(b) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `~[e:KNOWS]~` was found"
    # LeftOrRight (<-[]->) with directed edge - can traverse either direction
    When executing query:
      """
      USE ldbc MATCH (a:Person)<-[e:KNOWS]->(b) RETURN count(*)
      """
    Then the execution should be successful
    # AnyDirection (-[]-) with directed edge - can traverse either direction
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e:KNOWS]-(b) RETURN count(*)
      """
    Then the execution should be successful

  Scenario: Quantifier edge cases - boundary conditions
    # Quantifier {0,0} - zero hops not supported
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS]->{0,0}(b) RETURN a.id, b.id
      """
    Then an Error should be raised: "[NS103]: Semantic error, the value of upper bound of graph pattern quantifier shall be greater than 0"
    # Quantifier {1,1} - exactly one hop
    # Person{id:1} has a self-loop KNOWS edge
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS]->{1,1}(b:Person) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    # Quantifier {0,1} - questioned edge equivalent
    # 0-hop returns the start node, 1-hop returns the self-loop destination
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS]->{0,1}(b:Person) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Impossible quantifier range - types don't connect at step 2
    When executing query:
      """
      USE ldbc MATCH (a:University)-[e:IS_LOCATED_IN]->{2}(b:Country) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:IS_LOCATED_IN]->{2}` was found"

  Scenario: Backward propagation - endpoint constraints narrow earlier types
    # Endpoint constraint on destination narrows source types
    When executing query:
      """
      USE ldbc MATCH (a)-[e:IS_LOCATED_IN]->(b:Country) RETURN count(*)
      """
    Then the execution should be successful
    # Complex chain with backward propagation
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e1:KNOWS]->(b)-[e2:IS_LOCATED_IN]->(c:City) RETURN count(*)
      """
    Then the execution should be successful
    # Three-hop chain with end constraint - backward propagation should work
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e1]->(b)-[e2]->(c:Country) RETURN count(*)
      """
    Then the execution should be successful

  Scenario: Multi-pattern shared variables - intersection refinement
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS shared_var_test AS {
        NODE Person (:Person {id INT PRIMARY KEY}),
        NODE Company (:Company {id INT PRIMARY KEY}),
        NODE Post (:Post {id INT PRIMARY KEY}),
        EDGE knows (Person)-[:knows]->(Person),
        EDGE works_at (Person)-[:works_at]->(Company),
        EDGE posted (Person)-[:posted]->(Post),
        EDGE supplies (Company)-[:supplies]->(Company)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS shared_var_test :: shared_var_test
      """
    Then the execution should be successful
    And graph "shared_var_test" should be ready to use
    # Shared variable 'b' must satisfy both patterns
    # Pattern 1: (a:Person)-[e]->(b) -> b can be Person, Company, or Post
    # Pattern 2: (b)-[f]->(c:Company) -> b must have edges to Company -> b is Person or Company
    # Intersection: b = {Person, Company}
    When executing query:
      """
      USE shared_var_test MATCH (a:Person)-[e]->(b), (b)-[f]->(c:Company) RETURN count(*)
      """
    Then the execution should be successful
    # Conflicting patterns - no valid type for shared variable
    When executing query:
      """
      USE shared_var_test MATCH (a:Person)-[e:posted]->(b), (b)-[f:supplies]->(c) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:Person)-[e:posted]->(b),(b)-[f:supplies]->(c)` was found"
    And drop the graph "shared_var_test"
    And drop the graph type "shared_var_test"

  Scenario: Multi-pattern with three shared variables
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS triple_shared AS {
        NODE A (:A {id INT PRIMARY KEY}),
        NODE B (:B {id INT PRIMARY KEY}),
        NODE C (:C {id INT PRIMARY KEY}),
        EDGE ab (A)-[:ab]->(B),
        EDGE bc (B)-[:bc]->(C),
        EDGE ca (C)-[:ca]->(A)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS triple_shared :: triple_shared
      """
    Then the execution should be successful
    And graph "triple_shared" should be ready to use
    # Three patterns sharing all three variables - should form a valid triangle
    When executing query:
      """
      USE triple_shared MATCH (a:A)-[e1:ab]->(b:B), (b)-[e2:bc]->(c:C), (c)-[e3:ca]->(a) RETURN count(*)
      """
    Then the execution should be successful
    # Incompatible label on shared variable
    When executing query:
      """
      USE triple_shared MATCH (a:A)-[e1:ab]->(b), (b:C)-[e2]->(c) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:A)-[e1:ab]->(b),(b:C)-[e2]->(c)` was found"
    And drop the graph "triple_shared"
    And drop the graph type "triple_shared"

  Scenario: Fixpoint detection - chains that reach schema fixpoint early
    # Chain that reaches fixpoint quickly (Person→Person cycle via KNOWS)
    # Person{id:1} has a self-loop KNOWS edge, so {1,5} should return 5 results
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS]->{1,5}(b:Person) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 5   |
    # Unbounded with path mode to prevent infinite result
    # DIFFERENT EDGES mode should return only 1 result (the single self-loop edge)
    When executing query:
      """
      USE ldbc MATCH DIFFERENT EDGES (a:Person{id:1})-[e:KNOWS]->{1,}(b:Person) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: Questioned path pattern edge cases
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS question_test AS {
        NODE StartNode (:StartNode {id INT PRIMARY KEY}),
        NODE MiddleNode (:MiddleNode {id INT PRIMARY KEY}),
        NODE EndNode (:EndNode {id INT PRIMARY KEY}),
        EDGE sm (StartNode)-[:sm]->(MiddleNode),
        EDGE me (MiddleNode)-[:me]->(EndNode)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS question_test :: question_test
      """
    Then the execution should be successful
    And graph "question_test" should be ready to use
    # Questioned edge pattern - optional edge (not supported yet)
    When executing query:
      """
      USE question_test MATCH (s:StartNode)-[e:sm]->?(m) RETURN count(*)
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    # Chain with questioned edge in middle (not supported yet)
    When executing query:
      """
      USE question_test MATCH (s:StartNode)-[e1:sm]->?(m)-[e2:me]->(t:EndNode) RETURN count(*)
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    And drop the graph "question_test"
    And drop the graph type "question_test"

  Scenario: Empty type set detection - invalid patterns
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS empty_test AS {
        NODE Island1 (:Island1 {id INT PRIMARY KEY}),
        NODE Island2 (:Island2 {id INT PRIMARY KEY}),
        EDGE self1 (Island1)-[:self1]->(Island1),
        EDGE self2 (Island2)-[:self2]->(Island2)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS empty_test :: empty_test
      """
    Then the execution should be successful
    And graph "empty_test" should be ready to use
    # No edge connects Island1 to Island2
    When executing query:
      """
      USE empty_test MATCH (a:Island1)-[e]->(b:Island2) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e]->` was found"
    # Multi-hop still can't connect
    When executing query:
      """
      USE empty_test MATCH (a:Island1)-[e]->{1,10}(b:Island2) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e]->{1,10}` was found"
    And drop the graph "empty_test"
    And drop the graph type "empty_test"

  Scenario: Quantified path pattern type inference
    # Quantified sub-pattern with type constraints
    When executing query:
      """
      USE ldbc MATCH (a:Person)((x)-[e:KNOWS]->(y)){1,3}(b:Person) RETURN count(*)
      """
    Then the execution should be successful
    # Quantified sub-pattern that can't match
    When executing query:
      """
      USE ldbc MATCH (a:Person)((x:University)-[e:KNOWS]->(y)){1}(b) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:KNOWS]->` was found"
    # Quantified sub-pattern with endpoint mismatch
    When executing query:
      """
      USE ldbc MATCH (a:University)((x:Person)-[e:KNOWS]->(y:Person)){1}(b:City) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(WALK (x:Person)-[e:KNOWS]->(y:Person)){1}` was found"

  # =====================================================
  # Phase 1: High-Confidence Error Codes (Previously Untested)
  # =====================================================
  Scenario: NS104 - Quantifier lower bound exceeds upper bound
    # Lower bound 3 > Upper bound 2
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e:KNOWS]->{3,2}(b) RETURN count(*)
      """
    Then an Error should be raised: "[NS104]: Semantic error, lower bound of graph pattern quantifier shall be less than or equal to upper bound"
    # Lower bound 5 > Upper bound 3 in quantified path pattern
    When executing query:
      """
      USE ldbc MATCH (a:Person)((x)-[e:KNOWS]->(y)){5,3}(b:Person) RETURN count(*)
      """
    Then an Error should be raised: "[NS104]: Semantic error, lower bound of graph pattern quantifier shall be less than or equal to upper bound"
    # Edge case: equal bounds should work
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS]->{2,2}(b:Person) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |

  Scenario: Questioned path pattern in quantified pattern
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS nested_questioned_test AS {
        NODE A (:A {id INT PRIMARY KEY}),
        NODE B (:B {id INT PRIMARY KEY}),
        EDGE ab (A)-[:ab]->(B),
        EDGE bb (B)-[:bb]->(B)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS nested_questioned_test :: nested_questioned_test
      """
    Then the execution should be successful
    And graph "nested_questioned_test" should be ready to use
    # Questioned path pattern is not supported yet (parser rejects before semantic check)
    When executing query:
      """
      USE nested_questioned_test MATCH (a:A)(()-[e:bb]->?()){1,3}(b) RETURN count(*)
      """
    Then an Error should be raised: "[NT000]: Questioned path pattern is not supported yet"
    And drop the graph "nested_questioned_test"
    And drop the graph type "nested_questioned_test"

  Scenario: NS207 - Duplicate SET property items
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS dup_set_test AS {
        NODE Person (:Person {id INT PRIMARY KEY, name STRING})
      }
      """
    Then the execution should be successful
    And drop the graph "dup_set_test"
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS dup_set_test :: dup_set_test
      """
    Then the execution should be successful
    And graph "dup_set_test" should be ready to use
    When executing query:
      """
      USE dup_set_test INSERT (@Person{id:1, name:"Alice"})
      """
    Then the execution should be successful
    # Setting the same property twice in one SET clause should fail
    When executing query:
      """
      USE dup_set_test MATCH (v:Person{id:1}) SET v.name = "Bob", v.name = "Charlie"
      """
    Then an Error should be raised: "[NS207]: Variable and property name between any two SetPropertyItem should not be the same"
    And drop the graph "dup_set_test"
    And drop the graph type "dup_set_test"

  # =====================================================
  # Phase 2: Edge Case Expansions
  # =====================================================
  Scenario: Path modes with all direction types
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS path_mode_test AS {
        NODE N (:N {id INT PRIMARY KEY}),
        EDGE dir (N)-[:dir]->(N),
        EDGE undir (N)~[:undir]~(N)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS path_mode_test :: path_mode_test
      """
    Then the execution should be successful
    And graph "path_mode_test" should be ready to use
    # TRAIL with PointingRight
    When executing query:
      """
      USE path_mode_test MATCH p = TRAIL (a:N)-[e:dir]->*(b:N) RETURN count(*)
      """
    Then the execution should be successful
    # TRAIL with PointingLeft
    When executing query:
      """
      USE path_mode_test MATCH p = TRAIL (a:N)<-[e:dir]-*(b:N) RETURN count(*)
      """
    Then the execution should be successful
    # TRAIL with AnyDirection (directed edge)
    When executing query:
      """
      USE path_mode_test MATCH p = TRAIL (a:N)-[e:dir]-*(b:N) RETURN count(*)
      """
    Then the execution should be successful
    # TRAIL with LeftOrRight
    When executing query:
      """
      USE path_mode_test MATCH p = TRAIL (a:N)<-[e:dir]->*(b:N) RETURN count(*)
      """
    Then the execution should be successful
    # SIMPLE with PointingRight
    When executing query:
      """
      USE path_mode_test MATCH p = SIMPLE (a:N)-[e:dir]->*(b:N) RETURN count(*)
      """
    Then the execution should be successful
    # ACYCLIC with PointingRight
    When executing query:
      """
      USE path_mode_test MATCH p = ACYCLIC (a:N)-[e:dir]->*(b:N) RETURN count(*)
      """
    Then the execution should be successful
    # DIFFERENT EDGES with undirected edge
    When executing query:
      """
      USE path_mode_test MATCH DIFFERENT EDGES p = (a:N)~[e:undir]~*(b:N) RETURN count(*)
      """
    Then the execution should be successful
    And drop the graph "path_mode_test"
    And drop the graph type "path_mode_test"

  Scenario: Complex multi-pattern with four shared variables
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS quad_shared AS {
        NODE A (:A {id INT PRIMARY KEY}),
        NODE B (:B {id INT PRIMARY KEY}),
        NODE C (:C {id INT PRIMARY KEY}),
        NODE D (:D {id INT PRIMARY KEY}),
        EDGE ab (A)-[:ab]->(B),
        EDGE bc (B)-[:bc]->(C),
        EDGE cd (C)-[:cd]->(D),
        EDGE da (D)-[:da]->(A)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS quad_shared :: quad_shared
      """
    Then the execution should be successful
    And graph "quad_shared" should be ready to use
    When executing query:
      """
      USE quad_shared
      INSERT
      (a1@A{id:1}), (b1@B{id:1}), (c1@C{id:1}), (d1@D{id:1}),
      (a1)-[@ab]->(b1), (b1)-[@bc]->(c1), (c1)-[@cd]->(d1), (d1)-[@da]->(a1)
      """
    Then the execution should be successful
    # Four patterns sharing all four variables - should form a valid cycle
    When executing query:
      """
      USE quad_shared
      MATCH (a:A)-[e1:ab]->(b:B), (b)-[e2:bc]->(c:C), (c)-[e3:cd]->(d:D), (d)-[e4:da]->(a)
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 1   |
    And drop the graph "quad_shared"
    And drop the graph type "quad_shared"

  Scenario: Backward propagation with quantifiers
    # Backward propagation should correctly infer types for multi-hop patterns
    # IS_LOCATED_IN connects: Person->City, Organisation->City, Comment->Country, Post->Country, City->Country
    # IS_PART_OF connects: City->Country
    When executing query:
      """
      USE ldbc MATCH (a)-[e:IS_LOCATED_IN|IS_PART_OF]->{1,2}(b:Country) RETURN count(*)
      """
    Then the execution should be successful
    # With explicit source constraint
    When executing query:
      """
      USE ldbc MATCH (a:City)-[e:IS_PART_OF]->{1}(b:Country) RETURN count(*)
      """
    Then the execution should be successful

  Scenario: Empty type detection in multi-hop patterns
    # Person cannot directly reach University via KNOWS
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS]->(b:University) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:Person"
    # University cannot reach City via IS_LOCATED_IN in 3 hops
    When executing query:
      """
      USE ldbc MATCH (a:University)-[e:IS_LOCATED_IN]->{3}(b:City) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `-[e:IS_LOCATED_IN]->{3}` was found"

  Scenario: Label intersection producing empty set
    # Person and University have no overlap
    When executing query:
      """
      USE ldbc MATCH (a:Person&University) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:(Person) & (University))` was found"
    # Multiple incompatible labels
    When executing query:
      """
      USE ldbc MATCH (a:Person&City&Country) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:(Person) & (City) & (Country))` was found"

  Scenario: Negated type predicates in patterns
    # Find edges that are NOT KNOWS, WORK_AT, or STUDY_AT
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:!KNOWS&!WORK_AT&!STUDY_AT]->(b) RETURN DISTINCT type(e) AS t ORDER BY t
      """
    Then the execution should be successful
    # Negation combined with positive type
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e:IS_LOCATED_IN&!STUDY_AT]->(b:City) RETURN count(*)
      """
    Then the execution should be successful

  Scenario: Complex endpoint constraints with quantifiers
    # Multi-hop where intermediate types must be inferred
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e]->{2}(b:Country) RETURN count(*)
      """
    Then the execution should be successful
    # Three hops with constraints on both ends
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e]->{3}(b:Country) RETURN count(*)
      """
    Then the execution should be successful

  Scenario: Quantified pattern with zero lower bound edge cases
    # {0,1} should include zero-hop (identity) case
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS]->{0,1}(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # {0,0} should fail
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e:KNOWS]->{0,0}(b) RETURN count(*)
      """
    Then an Error should be raised: "[NS103]:"
    # Star quantifier equivalent to {0,}
    When executing query:
      """
      USE ldbc MATCH DIFFERENT EDGES (a:Person{id:1})-[e:KNOWS]->*(b:Person) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |

  Scenario: Edge patterns with label expressions
    # Union of edge types
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS|WORK_AT]->(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Wildcard edge type
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:%]->(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 8   |

  # =====================================================
  # Phase 3: Label Expression Edge Cases
  # =====================================================
  Scenario: Complex negation expressions producing empty set
    # Negate all node labels - should produce empty set
    # ldbc has: Person, Forum, Comment, Tag, Post, TagClass, Organisation, Place
    # Place has labels: City, Country, Continent
    # Organisation has labels: University, Company
    # Comment has labels: Comment, Message
    # Post has labels: Post, Message
    When executing query:
      """
      USE ldbc MATCH (a:!Person&!Forum&!Comment&!Tag&!Post&!TagClass&!University&!Company&!City&!Country&!Continent&!Message) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern"
    # Negate all edge labels that can come from Person - should produce empty set
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e:!KNOWS&!FOLLOWS&!HAS_INTEREST&!WORK_AT&!STUDY_AT&!IS_LOCATED_IN&!LIKES]->(b) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern"

  Scenario: Union with endpoint constraint producing empty set
    # Person|Comment as source with KNOWS edge - Comment cannot be source of KNOWS
    # This should still work because Person can be source of KNOWS
    When executing query:
      """
      USE ldbc MATCH (a:Person|Comment)-[e:KNOWS]->(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # Tag|TagClass as source - neither can reach Person directly
    # Tag has: HAS_TYPE -> TagClass
    # TagClass has: IS_SUBCLASS_OF -> TagClass
    # Neither has edges to Person, so this should fail
    When executing query:
      """
      USE ldbc MATCH (a:Tag|TagClass)-[e]->(b:Person) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern"
    # Forum|Post as source to reach Tag - both can reach Tag via HAS_TAG
    When executing query:
      """
      USE ldbc MATCH (a:Forum|Post)-[e:HAS_TAG]->(b:Tag) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 6   |
    # TagClass|Place as source with any edge to Person - neither can reach Person
    When executing query:
      """
      USE ldbc MATCH (a:TagClass|City|Country|Continent)-[e]->(b:Person) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern"

  Scenario: Multi-pattern with union type intersection
    When executing query:
      """
      CREATE GRAPH TYPE IF NOT EXISTS union_intersection_test AS {
        NODE A (:A {id INT PRIMARY KEY}),
        NODE B (:B {id INT PRIMARY KEY}),
        NODE C (:C {id INT PRIMARY KEY}),
        NODE D (:D {id INT PRIMARY KEY}),
        EDGE ab (A)-[:ab]->(B),
        EDGE ac (A)-[:ac]->(C),
        EDGE bd (B)-[:bd]->(D),
        EDGE cd (C)-[:cd]->(D)
      }
      """
    Then the execution should be successful
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS union_intersection_test :: union_intersection_test
      """
    Then the execution should be successful
    And graph "union_intersection_test" should be ready to use
    # Pattern 1: (a:A)-[e]->(b) => b can be B or C
    # Pattern 2: (b:B|D) => b must be B or D
    # Intersection: b = B (only B is in both sets)
    When executing query:
      """
      USE union_intersection_test MATCH (a:A)-[e]->(b), (b:B|D) RETURN count(*)
      """
    Then the execution should be successful
    # Pattern 1: (a:A)-[e]->(b) => b can be B or C
    # Pattern 2: (b:D) => b must be D
    # Intersection: empty (neither B nor C is D)
    When executing query:
      """
      USE union_intersection_test MATCH (a:A)-[e]->(b), (b:D) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:A)-[e]->(b),(b:D)` was found"
    # Three patterns with union narrowing
    # Pattern 1: (a)-[e1]->(b) from A => b = B|C
    # Pattern 2: (b)-[e2]->(c) => if b=B then c=D, if b=C then c=D => b = B|C, c = D
    # Pattern 3: (c:D) => c = D (consistent)
    When executing query:
      """
      USE union_intersection_test MATCH (a:A)-[e1]->(b), (b)-[e2]->(c), (c:D) RETURN count(*)
      """
    Then the execution should be successful
    # Conflict: b must satisfy both B|C (from pattern 1) and A|D (explicit)
    # Intersection of {B,C} and {A,D} is empty
    When executing query:
      """
      USE union_intersection_test MATCH (a:A)-[e]->(b), (b:A|D) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:A)-[e]->(b),(b:(A) | (D))` was found"
    And drop the graph "union_intersection_test"
    And drop the graph type "union_intersection_test"

  Scenario: Edge union with incompatible endpoint constraints
    # KNOWS goes Person->Person, WORK_AT goes Person->Organisation
    # Union should work when destination is unconstrained
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:KNOWS|WORK_AT]->(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # But with destination constraint Tag, neither KNOWS nor WORK_AT can reach Tag
    When executing query:
      """
      USE ldbc MATCH (a:Person)-[e:KNOWS|WORK_AT]->(b:Tag) RETURN count(*)
      """
    Then an Error should be raised: "[NS239]: No element type matching pattern `(a:Person)-[e:(KNOWS) | (WORK_AT)]->(b:Tag)` was found"
    # CONTAINER_OF goes Forum->Post, HAS_TAG goes Forum/Post/Comment->Tag
    # With source Forum and destination Tag, only HAS_TAG is valid
    When executing query:
      """
      USE ldbc MATCH (a:Forum)-[e:CONTAINER_OF|HAS_TAG]->(b:Tag) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # HAS_CREATOR goes Post/Comment->Person, CONTAINER_OF goes Forum->Post
    # Source Post can only use HAS_CREATOR (not CONTAINER_OF since Post is not Forum)
    When executing query:
      """
      USE ldbc MATCH (a:Post)-[e:HAS_CREATOR|CONTAINER_OF]->(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |

  Scenario: Negation combined with union in complex expressions
    # (Person | !Tag) - matches Person, or anything that is not Tag
    # This should match: Person, Forum, Comment, Post, TagClass, Organisation, Place
    When executing query:
      """
      USE ldbc MATCH (a:Person|!Tag) RETURN DISTINCT labels(a) AS lbls
      """
    Then the execution should be successful
    # (!Person & !Forum) | Tag - matches Tag, or anything that is neither Person nor Forum
    When executing query:
      """
      USE ldbc MATCH (a:Tag|!Person&!Forum) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the execution should be successful
    # Edge: (KNOWS | !FOLLOWS) & !WORK_AT - KNOWS or (not FOLLOWS), but not WORK_AT
    # From Person: KNOWS, HAS_INTEREST, STUDY_AT, IS_LOCATED_IN, LIKES match
    When executing query:
      """
      USE ldbc MATCH (a:Person{id:1})-[e:(KNOWS|!FOLLOWS)&!WORK_AT]->(b) RETURN count(*) AS cnt GROUP BY ()
      """
    Then the result should be, in any order:
      | cnt |
      | 6   |

  Scenario: Chained quantified path patterns
    # Multiple consecutive quantified edges with different ranges
    # Before type inference refactoring, this query would take extremely long to plan
    # due to combinatorial explosion in type resolution across chained quantifiers
    When executing query:
      """
      EXPLAIN USE ldbc MATCH (a)-[e]->{1,4}(b)-[e2]->{3,6}(c)-[e3]-{4,7}(d) RETURN count(*)
      """
    Then the execution should be successful
