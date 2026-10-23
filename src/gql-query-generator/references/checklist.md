# Final check: route only the applicable details

Read this short checklist on every generation. Open the matching sections of
[validation.md](validation.md) only for the constructs present; do not read the
whole validation or examples file for a simple query. Preserve the complete
catalog as the capability authority.

- Intent/version: query versus procedure, Database versus Analytics, documented 5.3.0 forms. CALL alone does not select the procedure skill.
- Schema: graph/type/label/property, primary versus internal IDs, direction and parameter bindings come from the request. Never invent a missing filter or anchor.
- Functions: exact name, documented overload, receiver, arity, argument types and environment. Use bounded function lookup; static lint flags only known errors.
- Result contract: columns/types, grouping key, duplicates, NULL preservation, ordering/ties and paging remain unchanged. Quote reserved aliases such as `values` and `big` with backticks.
- Paths/optional/subqueries: preserve hop range, path mode, edge/node uniqueness, optional filter scope and correlation. Load the relevant validation section only when present.
- Procedures: declarations precede statements; Database definitions may use a documented explicit USE; default to the caller graph; 0/1-hop match-compute; no RETURN inside PER NODE/PER PATH. Analytics does not use ordinary MATCH RETURN; export and return via documented table/partition patterns. Read specialized references for distributed tables or import/compute lifecycles.
- Repair: retain diagnostic evidence; recheck the changed contract. Executability alone does not prove equivalence. Follow [repair.md](repair.md).
- Performance: require result/error equivalence before plans/timing; report current evidence and unknowns; syntax changes or a single run cannot establish optimality.
- Output: query/definition plus necessary assumptions; distinguish placeholders/skeleton, static checked, server parsed and executed/result-compared.

When a check cannot be decided from available evidence, state that specific
uncertainty or request the material missing input. Do not silently narrow intent.
