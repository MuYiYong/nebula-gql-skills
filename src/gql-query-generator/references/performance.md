# Query Performance Reference

Use this reference only when the user asks for performance, supplies a slow query/PROFILE, or the query shape can obviously multiply work. Correct results and error behavior are the first gate; an optimization that changes rows, duplicates, NULL preservation, path sets, ordering, or write effects is invalid.

## Contents

- Evidence levels and output contract
- Expansion order, CBO, and hints
- Predicate and index decisions
- Paths, projection, aggregation, and row multiplication
- ORDER BY, LIMIT, and TopN
- Correlated subqueries and OPTIONAL branches
- PROFILE and fair comparison workflow
- Engine-informed decision matrix

## Evidence Levels and Output Contract

Label performance statements with the strongest evidence actually obtained:

1. **Structure-only candidate**: justified by query shape, but schema/index/data distribution is unknown.
2. **Static plan checked**: `EXPLAIN`, `EXPLAIN CBO`, or `EXPLAIN DECORRELATED` confirms a plan shape; the query was not timed.
3. **Isolated PROFILE checked**: equivalent results and runtime fields were checked on a named isolated graph/data set.
4. **Business-data checked**: equivalent results and repeated measurements were run on the actual target graph with representative parameters.

Never call a structure-only or empty-graph result “optimal”, “production-ready”, or a business SLA. When performance is requested, output:

- baseline/optimized GQL;
- schema and index prerequisites;
- semantic difference: `none` or an explicit approximation;
- evidence level and unverified items.

## Expansion Order, CBO, and Hints

### Default planning

`enable_reorder` defaults to `false`. For ordinary, executable MATCH paths, prefer an already-bound or highly selective anchor on the left:

```gql
MATCH (u:User{node_id: <id>})-[:FOLLOWS]->(v:User)
RETURN v.node_id
```

This is a conservative source form, not proof that every later operator follows the text literally. Dedicated shortest-path, K-hop, index, join, and fallback rules can still change the physical plan.

### CBO and path locking

When reorder is explicitly enabled, the optimizer can choose a different seed, direction, or join order from statistics. Compare CBO only when the query has multiple plausible anchors or joins and current statistics exist.

- Do not enable reorder globally or add `SET_VAR(enable_reorder=true)` by default.
- Do not add `NO_REORDER` merely to make the plan look stable. Use it when the user requests text order or an equivalent PROFILE comparison shows CBO regression/instability.
- CBO has bounded enumeration and fallback paths; `EXPLAIN CBO` is evidence of the selected logical shape, not runtime speed.

### Bound variables

For a correlated subquery, later MATCH, or `NEXT` segment, place an already-bound variable on the left when that preserves the requested edge direction. If decorrelation or reorder is not available, this avoids opening the path from an unconstrained domain.

## Predicate and Index Decisions

### Predicate scope before placement

Classify each predicate by dependencies:

| Predicate shape | Default placement | Reason |
| --- | --- | --- |
| One local node/edge + constants | property map for simple equality; otherwise pattern `WHERE` | makes the anchor/index condition explicit |
| Two or more local variables | MATCH-level `WHERE` | wait until all variables exist |
| Path variable or path position | result-level/path predicate | path is finalized later |
| Outer variable in a correlated query | keep correlated scope | may require Apply/decorrelation |
| Subquery predicate | `EXISTS`/`NOT EXISTS` or correct subquery scope | cannot be treated as a scalar local filter |

The optimizer can attach many same-MATCH predicates to scans and expands even if written in a MATCH-level `WHERE`. Do not promise a speedup from syntax movement alone. Never move a condition across `OPTIONAL MATCH`, `NEXT`, aggregation, or NULL-producing boundaries without proving row equivalence.

### Index prerequisites

- Prefer equality on the primary/business key when that is the actual selection intent.
- For a composite normal index, useful constraints normally begin with its leading properties; ORDER elimination additionally requires compatible property order, direction, NULL ordering, and equality-fixed prefixes.
- An index that exists but has no usable constraint is not automatically faster; a non-covering unconstrained index can lose to a table scan.
- A covering/index-only plan can avoid fetching non-indexed properties. Return only required fields so the optimizer can prune columns/properties.
- VC edge indexes are direction-sensitive and anchor-sensitive. Match the source/destination side and constant edge predicates; do not invent an index name or force an incompatible direction.
- Runtime/external predicates may use a different dynamic or correlated index path than constants. Verify the actual `details` instead of assuming the static index is used.
- Preserve user-provided `INDEX`/`IGNORE_INDEX` only after checking it is valid for the current schema. Add a new hint only from metadata plus plan evidence.

## Paths, Projection, Aggregation, and Row Multiplication

### Paths

- Do not bind `p =` unless the query returns the path or calls a path function.
- Use the narrowest hop range allowed by the requirement. Never cap an unbounded requirement only for speed.
- Use `TRAIL`, `ACYCLIC`, or `SIMPLE` only when it is the requested path-set semantics; path modes are not interchangeable tuning switches.
- Push an edge-local `ALL` condition into each corresponding quantified edge pattern only under the equivalence rules in [patterns.md](patterns.md).
- Fixed chains are appropriate when intermediate nodes/edge types have distinct meaning. A quantified edge is appropriate when only one repeated segment and its endpoint/hop range matter.
- Shortest-path plans can use bidirectional traversal only for supported shapes. Check that both endpoint filters are applied before traversal and inspect the actual plan.

### Projection and materialization

- Return only requested columns. Avoid `RETURN *`, whole nodes, whole edges, or whole paths when scalar IDs/properties are sufficient.
- Avoid `nodes(p)`, `edges(p)`, `collect_list(...)`, or large RECORD/LIST construction when the user only needs a count, existence test, or Top K score.
- Compute expensive expressions after cardinality has been safely reduced, but do not move expressions across an operation that changes their input set.

### Duplicates and aggregation

- Add `DISTINCT` only when duplicate elimination is part of the result contract. It introduces grouping/hash/sort work and can hide an unintended join multiplication.
- `UNION` removes duplicates by default; use `UNION ALL` only when duplicate preservation is correct or a single later deduplication is intentionally cheaper.
- Do not place `LIMIT` before aggregation, `DISTINCT`, or set consolidation unless the requirement is explicitly a sample/partial aggregate.
- Chaining independent one-to-many `OPTIONAL MATCH` arms can create a product of their fan-outs. If the output is a union of independent arms rather than combinations, consider same-shape `UNION ALL` branches followed by one consolidation; verify node/edge identity sets and NULL cases before accepting it.

## ORDER BY, LIMIT, and TopN

Use a deterministic tie-breaker when repeatable pages or Top K order matters:

```gql
MATCH (u:User{node_id: <id>})-[e:FOLLOWS]->(v:User)
RETURN v.node_id AS candidate_id, e.weight AS weight
ORDER BY weight DESC, candidate_id ASC
LIMIT 20
```

- Within one paging fragment, use `ORDER BY -> OFFSET/SKIP -> LIMIT`.
- 5.3 accepts the paging fragment before `RETURN` or as its suffix. Keep one style consistent; never generate `RETURN ... LIMIT ... ORDER BY ...`.
- `ORDER BY + LIMIT` is eligible for a TopN rewrite. Preserve both at the final candidate-set boundary.
- A no-sort LIMIT may be pushed toward a single planned unit, but a final LIMIT is not independently valid for every component/UNION arm.
- Large OFFSET still requires producing/skipping earlier rows. Prefer a stable keyset predicate only when the API contract allows changing from offset pagination and the relevant ordered key is known.
- An index can satisfy ordering only when its key order, direction, NULL ordering, and fixed leading prefix match. Confirm the missing Sort/TopN and the chosen index in the plan; do not infer it from DDL alone.

## Correlated Subqueries and OPTIONAL Branches

- Use `EXISTS { MATCH ... }` / `NOT EXISTS { MATCH ... }` for existence semantics; they can become semi/anti shapes, while count/list materialization does unnecessary work.
- A correlated `CALL`, `VALUE`, or `EXISTS` may be decorrelated, pushed to an index, or remain Apply-like. For a high-cardinality outer input, inspect `EXPLAIN DECORRELATED` and PROFILE rows before choosing it over a join/aggregation form.
- Do not introduce nested `CALL` layers only to shorten text. Each layer can add Apply, delim, aggregation, or materialization overhead.
- `OPTIONAL MATCH` must preserve the outer row on no match. A condition inside the optional branch is not equivalent to filtering NULL rows after `NEXT`.
- When two alternatives are semantically equivalent, compare both on low-, high-, and zero-match cases; fewer plan operators or rows alone does not guarantee lower elapsed time.

## Write Queries

- Preserve the requested conflict behavior (`INSERT`, `OR IGNORE`, `OR REPLACE`, or `OR UPDATE`) before considering throughput; these forms are not interchangeable tuning options.
- When the input is already a list/table and each item performs the same independent mutation, prefer one `FOR`-driven statement block over emitting many client round trips. Keep each item's mutation semantics explicit and do not create a cross product from multiple independent `FOR` clauses.
- Avoid reading whole nodes/paths only to update one known property. Match by the real key, carry only the target element and required values, then perform the single requested DML.
- `PROFILE` executes its query. For DML, use an isolated graph/transaction-safe test or a non-executing plan where supported; never PROFILE a business write merely to inspect speed.
- Compare write effects, conflicts, retries, and final property/edge identity state in addition to elapsed time.

## PROFILE and Fair Comparison Workflow

### Correctness gate

Before timing, compare:

- output column names and types;
- ordered rows or element identity multisets/sets, according to the contract;
- duplicate counts and NULL rows;
- error behavior for missing/invalid inputs;
- write effects for DML.

### Plan inspection

Use `EXPLAIN` for a non-executing plan, `EXPLAIN CBO` for the reorder stage when enabled, and `EXPLAIN DECORRELATED` for correlated subqueries. Use `PROFILE` only when executing the query is safe.

Inspect every relevant operator field:

| Field | What to check |
| --- | --- |
| `plan` | scans, joins, Apply, traversal, aggregate, Sort/TopN, repeated branches |
| `details` | actual index name/constraint, residual filter, direction, projected properties, limit |
| `rows` | largest intermediate cardinality and unexpected fan-out |
| `memory` | materialized paths/lists, hash aggregation/join, sort pressure |
| `time` | expensive operators and total runtime |
| `blocked` | storage/network/backpressure rather than pure CPU work |

An operator labeled `NodesScan`/`EdgesScan` can still show an index method in `details`; inspect both.

### Runtime comparison

- Use the same graph snapshot, parameters, result consumption, session settings, Hint set, and client.
- Warm both candidates, then alternate their order across multiple runs to reduce cache/order bias.
- Report sample count and at least median; include tail/spread when it materially differs.
- Compare PROFILE rows/memory as diagnostics, not substitutes for elapsed time.
- State graph scale and whether it is isolated or representative. Clean only objects created for the validation.

## Engine-Informed Decision Matrix

| Query signal | Engine path to verify | Generator action |
| --- | --- | --- |
| Selective key equality | PK/normal IndexScan or constrained scan details | make the anchor explicit; do not invent a hint |
| Multiple possible anchors/joins | default linear plan vs CBO DP/fallback | keep selective left by default; compare CBO only with evidence |
| Local predicate | scan/extend/varlen filter attachment | keep correct scope; prefer local form for clarity |
| Dynamic/correlated predicate | Apply/decorrelation/correlated index pushdown | inspect DECORRELATED/PROFILE; avoid per-row assumptions |
| Fixed repeated chain | KHopExpand or per-hop scans/VC indexes | preserve intermediate semantics; inspect every hop |
| Supported shortest path | BiBFS or recursive fallback | bind/filter both endpoints; verify chosen operator |
| `ORDER BY + LIMIT` | TopN or index-ordered scan | keep global boundary and stable tie-breaker |
| `LIMIT` without sort | local limit/streaming only when valid | never copy the final limit into independent units |
| Wide return/path/list | column/property pruning vs materialization | return scalars/elements actually requested |
| Independent OPTIONAL arms | left outer joins and fan-out product | split/consolidate only after equivalence proof |
| Correlated subquery | Apply, delim, semi/anti join | prefer existence semantics; profile high outer cardinality |

## Fail-Safe Rules

- If schema/index metadata is missing, emit placeholders and a structure-only candidate; do not fabricate DDL or index names.
- If two rewrites are not provably equivalent, return the correct baseline and describe the candidate separately as unverified.
- If PROFILE cannot run safely, stop at EXPLAIN/static evidence and say so.
- If a candidate is faster only under a non-default Hint/config, report that dependency explicitly and compare like with like.
- Do not turn an isolated benchmark into a universal rule in this skill; retain only the query-shape decision and its preconditions.
