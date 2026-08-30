# Copyright (c) 2026 vesoft inc. All rights reserved.
@sf01
Feature: Cbo

  Background:
    And executes "SESSION SET enable_reorder = true"

  Scenario: CBO prefers edge-anchored seed for one-hop pattern with selective edge
    # A one-hop Person-STUDY_AT-University pattern with a selective edge predicate should start from the edge and project both endpoints.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[e0:STUDY_AT]->(b:University)
      WHERE e0.classYear = 2000
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "ProjectEndpoints"
    And the plan should contain "GetEdges"

  Scenario: CBO respects inferred direction for undirected syntax with typed endpoint
    # A Person-Tag pattern written with undirected syntax still has only one legal orientation, so CBO should keep one outgoing expansion.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[r]-(b:Tag)
      RETURN count(*) AS cnt GROUP BY ()
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "Direction: {outgoing}"
    And the plan should contain "ToNode: b"

  Scenario: CBO uses node-anchored expand for highly selective start node
    # On a one-hop pattern, a selective endpoint should become the anchor and determine the expansion direction.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person{id:0})-[e0:KNOWS]->(b:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: a"
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[e0:KNOWS]->(b:Person{id:1})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: b"
    And the plan should contain "Direction: {incoming}"

  Scenario: CBO covers expand all and expand into on cycle
    # A two-hop cycle should open with one expansion and close back into the bound start node.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person{id:0})-[e0:KNOWS]->(b:Person)-[e1:KNOWS]->(a:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(Into)"
    And the plan should contain "Extend(All)"

  Scenario: CBO handles edge reuse by ProjectEndpoints reroute
    # Reusing the same KNOWS edge in a later hop should stay on that bound edge instead of rescanning.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[e0:KNOWS]->(b:Person)-[e0]-(c:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "ProjectEndpoints"
    And the plan should contain "RefDir: {outgoing,incoming}"

  Scenario: Linear fallback handles edge reuse before the repeated edge endpoints are bound
    # This component has more than six edges, so DP enumeration is skipped and planning falls
    # back to LinearExpandPlanner. The second textual edge only shares the edge variable `e`
    # with the prefix; its source node `c` is not bound yet. Linear planning must therefore
    # handle the repeated edge with ProjectEndpoints before checking whether `c` is available.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[e:KNOWS]->(b:Person),
            (c:Person)-[e]->(d:Person),
            (d)-[:KNOWS]->(x1:Person)-[:KNOWS]->(x2:Person)-[:KNOWS]->(x3:Person)-[:KNOWS]->(x4:Person)-[:KNOWS]->(x5:Person)
      RETURN c, d, e, x5
      """
    Then the execution should be successful
    And the plan should contain "ProjectEndpoints"
    And the plan should contain "Edge: e"

  Scenario: Linear fallback joins a seeded edge when textual left expansion is impossible
    # This is another forced linear fallback case. The second textual edge shares only the
    # already-bound node `b` with the prefix, but its syntactic left node `c` is not available.
    # LinearExpandPlanner should seed that edge independently and join it back on `b`.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[:KNOWS]->(b:Person),
            (c:Person)-[:KNOWS]->(b),
            (c)-[:KNOWS]->(x1:Person)-[:KNOWS]->(x2:Person)-[:KNOWS]->(x3:Person)-[:KNOWS]->(x4:Person)-[:KNOWS]->(x5:Person)
      RETURN b, c, x5
      """
    Then the execution should be successful
    And the plan should contain "LogicalJoin(Inner)"

  Scenario: CBO keeps nested edge reuse stable for ProjectEndpoints lowering
    # When a later MATCH and a path pattern both reuse the same outer edge, the plan should keep that edge binding correlated end to end.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[e0:KNOWS]->(b:Person)-[e0:KNOWS]->(c:Person)
      MATCH p0 = (d:Person)<-[e0]-(f:Person)<-[e0]-(g:Person)<-[e1:KNOWS]-(h:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Apply(Inner)"
    And the plan should contain "ref: e0"
    And the plan should contain "ProjectEndpoints"

  Scenario: CBO handles correlated external edge ref across MATCH clauses
    # When OPTIONAL MATCH reuses an outer edge binding, the optional branch should stay correlated with the outer row.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a:Person)-[e0:KNOWS]->(b:Person)
      OPTIONAL MATCH (c:Person)<-[e0]-(d:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Apply(LeftOuter)"
    And the plan should contain "ref: e0"

  Scenario: CBO external edge reference matrix with readable variable names
    # Correlated ref: the second MATCH reuses one outer edge while source and destination can be local, partially bound, or fully bound.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (src_bound:Person)-[e:KNOWS]->(dst_bound:Person)
      MATCH (src_local:Person)-[e]->(dst_local:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "ref: e"
    And the plan should contain "ProjectEndpoints"
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (src_bound:Person)-[e:KNOWS]->(dst_bound:Person)
      MATCH (src_bound)-[e]->(dst_local:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "ref: e"
    And the plan should contain "ProjectEndpoints"
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (src_bound:Person)-[e:KNOWS]->(dst_bound:Person)
      MATCH (src_local:Person)-[e]->(dst_bound)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "ref: e"
    And the plan should contain "ProjectEndpoints"
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (src_bound:Person)-[e:KNOWS]->(dst_bound:Person)
      MATCH (src_bound)-[e]->(dst_bound)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "ref: e"
    And the plan should contain "ProjectEndpoints"
    # Context var ref: the edge comes from VALUE instead of a previous MATCH row.
    When executing query:
      """
      explain cbo
      USE sf01 {
      VALUE edge_ctx = VALUE {
        MATCH (src_seed:Person)-[e_seed:KNOWS]->(dst_seed:Person)
        RETURN e_seed
        LIMIT 1
      }
      MATCH (src_local:Person)-[edge_ctx]->(dst_local:Person)
      RETURN *
      }
      """
    Then the execution should be successful
    And the plan should contain "ProjectEndpoints"
    And the plan should contain "Project: src=true, dst=true"
    And the plan should contain "ref: edge_ctx"
    When executing query:
      """
      explain cbo
      USE sf01 {
      VALUE src_ctx = VALUE {
        MATCH (src_seed:Person{id:0})
        RETURN src_seed
        LIMIT 1
      }
      VALUE edge_ctx = VALUE {
        MATCH (edge_src_seed:Person)-[e_seed:KNOWS]->(edge_dst_seed:Person)
        RETURN e_seed
        LIMIT 1
      }
      MATCH (src_ctx)-[edge_ctx]->(dst_local:Person)
      RETURN *
      }
      """
    Then the execution should be successful
    And the plan should contain "ProjectEndpoints"
    And the plan should contain "Project: src=false, dst=true"
    When executing query:
      """
      explain cbo
      USE sf01 {
      VALUE dst_ctx = VALUE {
        MATCH (dst_seed:Person{id:1})
        RETURN dst_seed
        LIMIT 1
      }
      VALUE edge_ctx = VALUE {
        MATCH (edge_src_seed:Person)-[e_seed:KNOWS]->(edge_dst_seed:Person)
        RETURN e_seed
        LIMIT 1
      }
      MATCH (src_local:Person)-[edge_ctx]->(dst_ctx)
      RETURN *
      }
      """
    Then the execution should be successful
    And the plan should contain "ProjectEndpoints"
    And the plan should contain "Project: src=true, dst=false"
    When executing query:
      """
      explain cbo
      USE sf01 {
      VALUE src_ctx = VALUE {
        MATCH (src_seed:Person{id:0})
        RETURN src_seed
        LIMIT 1
      }
      VALUE dst_ctx = VALUE {
        MATCH (dst_seed:Person{id:1})
        RETURN dst_seed
        LIMIT 1
      }
      VALUE edge_ctx = VALUE {
        MATCH (edge_src_seed:Person)-[e_seed:KNOWS]->(edge_dst_seed:Person)
        RETURN e_seed
        LIMIT 1
      }
      MATCH (src_ctx)-[edge_ctx]->(dst_ctx)
      RETURN *
      }
      """
    Then the execution should be successful
    And the plan should contain "ProjectEndpoints"
    And the plan should contain "Project: src=false, dst=false"

  Scenario: CBO combines expand and join solvers on two-sided selective chain
    # On the Country-Post-Forum motif, one anchored forum yields a single chain, while two free ends meet by joining on the shared post.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (country:Country)<-[:IS_LOCATED_IN]-(post:Post)<-[:CONTAINER_OF]-(forum:Forum{id:2819})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "GetNodes"
    And the plan should contain "FromNode: forum"
    And the plan should contain "ToNode: post"
    And the plan should not contain "LogicalJoin(Inner)"
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (country:Country)<-[:IS_LOCATED_IN]-(post:Post)<-[:CONTAINER_OF]-(forum:Forum)
      RETURN country.id, post.id, forum.id
      """
    Then the execution should be successful
    And the plan should contain "LogicalJoin(Inner)"
    And the plan should contain "Extend(All)"
    And the plan should contain "ToNode: post"

  Scenario: CBO delays cross-variable predicate until both sides are available
    # Two MATCH branches tied later by post.id = post2.id should keep their own local shapes before the equality is applied.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (country:Country)<-[:IS_LOCATED_IN]-(post:Post)
      MATCH (forum:Forum)-[:CONTAINER_OF]->(post2:Post)
      WHERE post.id = post2.id
      RETURN country.id, post.id, forum.id
      """
    Then the execution should be successful
    And the plan should contain "Apply(Inner)"

  Scenario: CBO lowers match mode different edges as predicate
    # In a two-branch KNOWS pattern, DIFFERENT EDGES should become a predicate after both edge bindings are produced.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH DIFFERENT EDGES
      (a:Person{id:0})-[e0:KNOWS]->(b:Person{id:1}),
      (c:Person{id:0})-[e1:KNOWS]->(d:Person{id:1})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Filter"
    And the plan should contain "e0 <> e1"
    And the plan should contain "LogicalJoin(Cross)"

  Scenario: CBO keeps path mode semantics for quantified edge
    # Quantified path planning should keep whether the path is TRAIL or ACYCLIC in the resulting operator.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH p0 = TRAIL (a:Person{id:0})-[e0:KNOWS]->{1,4}(b:Person{id:1})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(Into, TRAIL,"
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH p0 = ACYCLIC (a:Person{id:0})-[e0:KNOWS]->{1,4}(b:Person{id:1})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(Into, ACYCLIC,"

  Scenario: CBO prefers cartesian-into seed for selective quantified endpoints
    # CP+Into binds both endpoints, CrossJoins endpoint pairs, then checks each pair with VarLenExpand(Into).
    When executing query:
      """
      EXPLAIN CBO
      USE sf01 {
      MATCH p = (v WHERE v.id IN [1,2])-[e]-{1,5}(w WHERE w.id IN [3,4])
      RETURN count(p), length(p)
      }
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(Into, WALK,"
    And the plan should contain "LogicalJoin(Cross)"
    # A selective endpoint set can still make CP+Into cheaper than expanding from only one side.
    When executing query:
      """
      EXPLAIN CBO
      USE sf01 {
      MATCH (v:Person WHERE v.id < 1000)-[e:KNOWS]-{1,3}(w:Person WHERE w.id < 1000)
      RETURN count(e), size(e)
      }
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(Into, WALK,"
    And the plan should contain "LogicalJoin(Cross)"
    # When endpoint cardinality grows to the full Person set, node-anchored VarLenExpand(All) wins.
    When executing query:
      """
      EXPLAIN CBO
      USE sf01 {
      MATCH (v:Person)-[e:KNOWS]-{1,2}(w:Person)
      RETURN count(e), size(e)
      }
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(All, WALK,"
    And the plan should not contain "LogicalJoin(Cross)"

  # FIX: https://github.com/vesoft-inc/nebula-ng/issues/10772
  @sf01
  Scenario: CBO prefers streaming plan for limited var-length path
    When executing query:
      """
      EXPLAIN CBO /*+ SET_VAR(streaming_join_batches = 64) */
      USE sf01
      MATCH p = WALK (v1@Person{id:318})((@Person)-[e1]->(@Person)){0,10}(v2)-(v3)
      RETURN v3.id AS cid, type(v3) AS ctyp, length(p) AS len
      LIMIT 1000
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(All, WALK, stream)"
    And the plan should not contain "VarLenExpand(Into"
    When executing query:
      """
      EXPLAIN CBO /*+ SET_VAR(streaming_join_batches = 64) */
      USE sf01
      MATCH p = SIMPLE (v1@Person{id:318})((@Person)-[e1]->(@Person)){0,10}(v2)-(v3)
      RETURN v3.id AS cid, type(v3) AS ctyp, length(p) AS len
      LIMIT 1000
      """
    Then the execution should be successful
    # A multi-segment SIMPLE path lowers the quantified inner segment to ACYCLIC.
    And the plan should contain "VarLenExpand(All, ACYCLIC, stream)"
    And the plan should not contain "VarLenExpand(Into"
    When executing query:
      """
      EXPLAIN CBO /*+ SET_VAR(streaming_join_batches = 64) */
      USE sf01
      MATCH p = ACYCLIC (v1@Person{id:318})((@Person)-[e1]->(@Person)){0,10}(v2)-(v3)
      RETURN v3.id AS cid, type(v3) AS ctyp, length(p) AS len
      LIMIT 1000
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(All, ACYCLIC, stream)"
    And the plan should not contain "VarLenExpand(Into"
    When executing query:
      """
      EXPLAIN CBO /*+ SET_VAR(streaming_join_batches = 64) */
      USE sf01
      MATCH p = TRAIL (v1@Person{id:318})((@Person)-[e1]->(@Person)){0,10}(v2)-(v3)
      RETURN v3.id AS cid, type(v3) AS ctyp, length(p) AS len
      LIMIT 1000
      """
    Then the execution should be successful
    And the plan should contain "VarLenExpand(All, TRAIL, stream)"
    And the plan should not contain "VarLenExpand(Into"

  Scenario: NO_REORDER hint
    # Single hop: CBO would reorder and start from b{id:2}, while NO_REORDER keeps the textual country -> post opening step.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (country:Country)<-[:IS_LOCATED_IN]-(post:Post{id:54780})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: post"
    And the plan should contain "ToNode: country"
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH /*+ NO_REORDER */ (country:Country)<-[:IS_LOCATED_IN]-(post:Post{id:54780})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: country"
    And the plan should contain "ToNode: post"
    # Three-hop chain: the hint keeps the left-to-right opening step.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH /*+ NO_REORDER */ (country:Country)<-[:IS_LOCATED_IN]-(post:Post)<-[:CONTAINER_OF]-(forum:Forum{id:2819})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: country"
    And the plan should contain "ToNode: post"
    And the plan should contain "FromNode: post"
    And the plan should contain "ToNode: forum"
    # Selective middle node: the hint still pins the opening step.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH /*+ NO_REORDER */ (country:Country)<-[:IS_LOCATED_IN]-(post:Post{id:54780})<-[:CONTAINER_OF]-(forum:Forum)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: country"
    And the plan should contain "ToNode: post"
    And the plan should contain "FromNode: post"
    And the plan should contain "ToNode: forum"
    # Mixed paths: only the hinted path is pinned.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH
        /*+ NO_REORDER */ (country:Country)<-[:IS_LOCATED_IN]-(post:Post)<-[:CONTAINER_OF]-(forum:Forum{id:2819}),
        (person:Person{id:0})-[:IS_LOCATED_IN]->(city:City)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "FromNode: country"
    And the plan should contain "ToNode: post"
    And the plan should contain "FromNode: post"
    And the plan should contain "ToNode: forum"
    # EXISTS subpattern: the hint is local to the correlated subpattern.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (country:Country)<-[:IS_LOCATED_IN]-(post:Post)
      WHERE EXISTS {
        /*+ NO_REORDER */ (post)-[:HAS_CREATOR]->(creator:Person)-[:IS_LOCATED_IN]->(city:City)
      }
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "ref: post"
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: post"
    And the plan should contain "ToNode: creator"
    And the plan should contain "FromNode: creator"
    And the plan should contain "ToNode: city"
    # Scalar subquery: the hinted subquery stays preserved inside the VALUE expression.
    When executing query:
      """
      explain cbo
      USE sf01
      RETURN VALUE {
        MATCH /*+ NO_REORDER */ (country:Country)<-[:IS_LOCATED_IN]-(post:Post)<-[:CONTAINER_OF]-(forum:Forum{id:2819})
        RETURN count(*) AS n
      } AS cnt
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: country"
    And the plan should contain "ToNode: post"
    And the plan should contain "FromNode: post"
    And the plan should contain "ToNode: forum"
    # Combined with quantified path: the hinted fixed path keeps its opening step.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH
        ANY SHORTEST (a:Person{id:0})-[e:KNOWS]->{1,3}(b:Person),
        /*+ NO_REORDER */ (b)-[:IS_LOCATED_IN]->(city:City)-[:IS_PART_OF]->(country:Country)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "FromNode: b"
    And the plan should contain "ToNode: city"
    And the plan should contain "FromNode: city"
    And the plan should contain "ToNode: country"
    # TRAIL path mode: NO_REORDER pins a -> b -> c despite c{id:2}.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH /*+ NO_REORDER */ TRAIL (a:Person)-[e0:KNOWS]->(b:Person)-[e1:KNOWS]->(c:Person{id:1})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    And the plan should contain "Filter: e0 <> e1"
    # Path variable with TRAIL mode: NO_REORDER still forces a -> b -> c despite c{id:2}.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH /*+ NO_REORDER */ p0 = TRAIL (a:Person)-[e0:KNOWS]->(b:Person)-[e1:KNOWS]->(c:Person{id:1})
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Extend(All)"
    # Correlated structural edge ref on the second hop cannot be lowered as Extend;
    # NO_REORDER must keep textual order and fall back to a join with the referenced edge seed.
    When executing query:
      """
      explain cbo
      USE sf01
      MATCH (a0:Person)-[e0:KNOWS]->(b0:Person)
      MATCH /*+ NO_REORDER */ (x:Person)-[e1:KNOWS]->(y:Person)-[e0]->(z:Person)
      RETURN *
      """
    Then the execution should be successful
    And the plan should contain "Apply(Inner)"
    And the plan should contain "LogicalJoin(Inner)"
    And the plan should contain "ref: e0"
    # Unsupported hint raises error
    When executing query:
      """
      USE sf01
      MATCH /*+ INDEX(some_index) */ (a:Person)-[e0:KNOWS]->(b:Person)
      RETURN *
      """
    Then an Error should be raised: "[NT000]: Only the NO_REORDER hint is supported as a path pattern hint."
