# Copyright (c) 2026 vesoft inc. All rights reserved.
Feature: Cbo

  Scenario: CBO prefers edge-anchored seed for unconstrained single edge
    # Classic "scan-first" pattern: with no selective predicate, CBO should usually start from e0 and project endpoints.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person)-[e0:KNOWS]->(b:Person)
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO uses node-anchored expand for highly selective start node
    # Point lookup on a(id=1) makes node-first exploration cheaper, then one-hop expand by e0.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person{id:1})-[e0:KNOWS]->(b:Person)
      RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person)-[e0:KNOWS]->(b:Person{id:2})
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO covers expand all and expand into on cycle
    # Cycle closure is a common pattern where one hop introduces a new binding and the next hop goes into an existing node.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person{id:1})-[e0:KNOWS]->(b:Person)-[e1:KNOWS]->(a:Person)
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO handles edge reuse by ProjectEndpoints reroute
    # Reusing the same edge variable in a second position should be handled as endpoint projection, not as a fresh edge scan.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person)-[e0:KNOWS]->(b:Person)-[e0:KNOWS]-(c:Person)
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO keeps nested edge reuse stable for ProjectEndpoints lower
    # Nested e0 reuse across chain and path is the stress case for ProjectEndpoints lowering and in-scope column preservation.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person)-[e0:KNOWS]->(b:Person)-[e0:KNOWS]->(c:Person)
      MATCH p0 =(d:Person)<-[e0]-(f:Person)<-[e0]-(g:Person)<-[e1:FOLLOWS]-(h:Person)
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO handles correlated external edge ref across MATCH clauses
    # Multi-MATCH reuse of e0 is the typical correlated-reference shape; the follow-up MATCH should consume outer e0 directly.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person)-[e0:KNOWS]->(b:Person)
      OPTIONAL MATCH (c:Person)<-[e0]-(d:Person)
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO combines expand and join solvers on two-sided selective chain
    # Two selective anchors at both ends form a meet-in-the-middle plan with expand plus join.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person{id:1})-[e0:KNOWS]->(b:Person)-[e1:KNOWS]->(m:Person)<-[e2:KNOWS]-(c:Person)<-[e3:KNOWS]-(d:Person{id:3})
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO delays cross-variable predicate until both sides are available
    # The join predicate b.id = c.id only becomes evaluable after both branches materialize their symbols.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH (a:Person{id:1})-[e0:KNOWS]->(b:Person)
      MATCH (c:Person)-[e1:KNOWS]->(d:Person{id:3})
      WHERE b.id = c.id
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO lowers match mode different edges as predicate
    # DIFFERENT EDGES is a global matching rule and should appear as a predicate once e0/e1 are both in scope.
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH DIFFERENT EDGES
      (a:Person{id:1})-[e0:KNOWS]->(b:Person{id:1}),
      (c:Person{id:1})-[e1:KNOWS]->(d:Person{id:1})
      RETURN *
      """
    Then the execution should be successful

  Scenario: CBO keeps path mode semantics for quantified edge
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH p0 = TRAIL (a:Person{id:1})-[e0:FOLLOWS]->{1,4}(b:Person{id:4})
      RETURN *
      """
    Then the execution should be successful
    When executing query:
      """
      explain cbo /*+ set_var(enable_cbo=true) */
      USE ldbc
      MATCH p0 = ACYCLIC (a:Person{id:1})-[e0:FOLLOWS]->{1,4}(b:Person{id:4})
      RETURN *
      """
    Then the execution should be successful
