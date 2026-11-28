# Error-driven repair contract

1. Record target version/environment, original GQL, schema/parameters, diagnostic code and failing stage. Do not infer a different schema from an error.
2. Check the exact function/signature or syntax section with the bundled lookup. Documentation authorizes capability; a feature/code example alone does not.
3. Repair the smallest responsible fragment. Preserve return names/types, duplicates, NULL rows, ordering/ties, path mode/hop range, optional/correlated scope and procedure side effects/termination.
4. Recheck the repaired statement and boundary cases. Compare typed ordered rows or multisets according to the original contract. A changed failure code is not a successful repair.
5. Report what was checked: static lint, server parser/EXPLAIN, execution, result comparison. Lint cannot prove grammar or semantics. Do not execute DDL/DML or a named procedure with unknown effects merely to test generation.
6. If no documented equivalent exists, explain the missing capability or ask for material schema/intent; never silently remove an unsupported requirement. For repeat failures, preserve the failed attempt and use new diagnostic evidence before another edit.

Procedure repair also preserves signature/defaults, declaration order, zero/one-hop match-compute, aggregation receiver types and Database/Analytics boundaries. Do not claim a skeleton is executable.

Performance repair first proves row/error equivalence. Keep unbounded paths, duplicate semantics and optional NULL preservation unless the user changes the contract; reduced rows or a syntactic rewrite is not evidence of a speedup.

Follow [identifiers.md](identifiers.md) when repairing GQL. Delimit each identifier in its declaration and every reference. Preserve spelling, case, schema and result column names; do not rename a field or turn a string value or syntax token into an identifier.

For `42001` near a backtick-quoted `NOT` or `NULL` in a NULL predicate, restore
`IS NOT NULL` or `IS NULL`. Keep identifier quoting on the operand and preserve
the surrounding comparisons, grouping and filter placement.

## Database procedure diagnostics

Use the reported line and column to locate the declaration, reference, call or compute clause. For a server error, inspect its message as well as the code.

| Diagnostic | Repair |
| --- | --- |
| NS002, duplicate defined variable | Compare the reported name with the first visible declaration. Reuse the original or rename the conflicting local and its references. Sibling procedure blocks can have independent locals. |
| 42N56, `global agg … not defined` | Read a scalar `VALUE` or formal parameter directly by name. For genuine shared aggregation, declare a global `VALUE` with the intended aggregator type and use `@name`. |
| 42N56, `node agg … not defined` | For `n.@name`, find the exact visible `NODE VALUE` declaration or add one before the compute stage. Preserve spelling and case. Keep ordinary properties and element-type annotations in their own syntax. |
| NR002, undefined scalar `node(...)` | Bind a node by its declared label and business primary key using `MATCH`. The 5.3 grammar separately supports the cross-node update `SET NODE(id_variable).@state += contribution` within match-compute, using an internal element ID. |
| NS208, incompatible size assignment | `size(list/set/map)` returns `INT32`, local `size(table)` returns `INT64`, and `ListAgg`, `SetAgg`, `MapAgg` and `TopKAgg` member `.size()` returns `UINT64`. Match the target type or, for an intentional numeric conversion, check its range and use e.g. `CAST(size(keys) AS UINT64)`. For unknown arguments or compound expressions, use the real schema and server type information. |
| NS238, PER PATH on a single-node pattern | Preserve the binding, WHERE predicates and aggregation intent. For per-node contributions use `PER NODE (b)`. For contributions per relationship, match the required edge type, direction and endpoints before `PER PATH`. Other NS238 messages describe different compute restrictions. |

The 5.3.0 reference cases are [Only Node Task and Aggregator definition](../tests/features/analytic/aggregator/Agg.feature) and [cross-node updates using element IDs](../tests/features/analytic/aggregator/ExternalMessage.feature). The [function catalog](documented-functions.md) lists the size signatures.
