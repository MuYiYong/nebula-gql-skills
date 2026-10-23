# Error-driven repair contract

1. Record target version/environment, original GQL, schema/parameters, diagnostic code and failing stage. Do not infer a different schema from an error.
2. Check the exact function/signature or syntax section with the bundled lookup. Documentation authorizes capability; a feature/code example alone does not.
3. Repair the smallest responsible fragment. Preserve return names/types, duplicates, NULL rows, ordering/ties, path mode/hop range, optional/correlated scope and procedure side effects/termination.
4. Recheck the repaired statement and boundary cases. Compare typed ordered rows or multisets according to the original contract. A changed failure code is not a successful repair.
5. Report what was checked: static lint, server parser/EXPLAIN, execution, result comparison. Lint cannot prove grammar or semantics. Do not execute DDL/DML or a named procedure with unknown effects merely to test generation.
6. If no documented equivalent exists, explain the missing capability or ask for material schema/intent; never silently remove an unsupported requirement. For repeat failures, preserve the failed attempt and use new diagnostic evidence before another edit.

Procedure repair also preserves signature/defaults, declaration order, zero/one-hop match-compute, aggregation receiver types and Database/Analytics boundaries. Do not claim a skeleton is executable.

Performance repair first proves row/error equivalence. Keep unbounded paths, duplicate semantics and optional NULL preservation unless the user changes the contract; reduced rows or a syntactic rewrite is not evidence of a speedup.
