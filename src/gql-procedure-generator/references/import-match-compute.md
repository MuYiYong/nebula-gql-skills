# IMPORT INTO GRAPH and Match Compute

## Scope

Apply this guardrail when a procedure mutates a temporary graph with `IMPORT INTO GRAPH` and the workflow also needs `match_compute_statement`.

## Unsafe Shapes

Do not generate either shape:

- One procedure imports into a graph and then performs match compute in that same procedure.
- A child imports into the graph, then an ancestor procedure performs match compute in the same active call chain.

Both can execute against a stale graph version and fail at runtime with `NR153` graph version mismatch.

## Safe Split

Separate mutation and computation into sibling procedures. Let the parent select the graph before each call.

```gql
CREATE OR REPLACE PROCEDURE <import_procedure>() AS {
  TABLE nodes TYPED TABLE {id INT} = {id: <id>}
  IMPORT INTO GRAPH {
    NODE (n@<node_type>{id: id}) FROM nodes
  } OPTIONS {PRIMARY_KEY_AS_NODE_ID: true}
}
```

```gql
CREATE OR REPLACE PROCEDURE <compute_procedure>() AS {
  NODE VALUE cnt SumAgg<INT> = 0
  MATCH (n@<node_type>)
  PER NODE (n) {
    SET n.@cnt += 1
  }
}
```

Parent skeleton:

```gql
CREATE OR REPLACE PROCEDURE <parent_procedure>() AS {
  GRAPH g TYPED <graph_type>
  USE g
  CALL <import_procedure>() FINISH
  USE g
  CALL <compute_procedure>() FINISH
}
```

Keep the calls as siblings. Do not merge import and compute back into one child.

## Evidence

- Feature: `analytic/BanInvalidMatchCompute.feature`
