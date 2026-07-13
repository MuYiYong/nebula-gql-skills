# Distributed Tables and PER PARTITION

## Contents

- Scope
- Definition and consumption
- Version-gated local BindingTable import
- Allowed and forbidden operations
- Procedure arguments
- Evidence

## Scope

Use this capability only for NebulaGraph Analytics; keep `v5.3.0` as the default compatibility baseline. Do not introduce `PARTITION BY DEFAULT` or `PER PARTITION` into an ordinary Database query or procedure unless the target environment is explicitly Analytics-compatible.

Keep the release boundary explicit: strict `v5.3.0` rejects importing a non-distributed local BindingTable into a distributed temporary graph. Current `nebula-ng` master after `c2fabed62` supports that source combination. Do not infer the extension from `PARTITION BY DEFAULT` alone.

## Definition and Consumption

Define an empty distributed binding table with `PARTITION BY DEFAULT`, export rows during distributed match compute, then consume each partition through its alias.

```gql
TABLE result_table TYPED TABLE {id INT, name STRING} PARTITION BY DEFAULT

MATCH (a@Person)
PER NODE (a) {
  EXPORT a.id, a.firstName INTO result_table
}

PER PARTITION (part) OF result_table {
  FOR r IN part
  RETURN r.id AS id, r.name AS name
}
```

Do not initialize a distributed table with a literal or query result. Do not iterate the outer table directly.

## Version-Gated Local BindingTable Import

Use this shape only when the target runtime is explicitly verified to include the current-master extension. The source tables remain local; the target temporary graph is distributed.

Treat the following as a caller-side statement block. For a named procedure, put the `TABLE` declarations and `IMPORT` in the procedure body without `USE`, then let the caller select the graph before `CALL`.

```gql
USE #<distributed_temporary_graph> {
  TABLE nodes TYPED TABLE {id INT, name STRING} =
    {id: <id>, name: <name>}

  TABLE edges TYPED TABLE {src_id INT, dst_id INT, id INT} =
    {src_id: <src_id>, dst_id: <dst_id>, id: <edge_id>}

  IMPORT INTO GRAPH {
    NODE (v@<node_type>{id: id, name: name}) FROM nodes,
    EDGE (id:src_id)-[e@<edge_type>{id: id}]->(id:dst_id) FROM edges
  } OPTIONS {PRIMARY_KEY_AS_NODE_ID: true}
}
```

For a strict `v5.3.0` target, do not generate this local-source shape; it raises `NR125`. Use a supported distributed/file source or ask the user to confirm a newer runtime.

## Allowed and Forbidden Operations

Inside `PER PARTITION (part) OF t { ... }`:

- Use the partition alias `part`, not the outer distributed table `t`.
- Allow `FOR r IN part`, `SET part.clear()`, `RETURN`, logging, and `EXPORT ... INTO <file>` when the surrounding statement permits them.
- Do not issue graph `MATCH` statements.
- Do not call arbitrary procedures.
- Do not access outer distributed tables, global aggregators, or active sets.
- Do not export into another binding table; file export is the supported export target.

Outside `PER PARTITION`, do not generate `FOR r IN t`, `size(t)`, `table_split(t)`, or `SET t.clear()` for a distributed table.

## Procedure Arguments

Declare a reusable table parameter as `t TABLE`. When the caller passes a distributed table, the child procedure receives it by reference and can export into it or use `PER PARTITION`.

```gql
CREATE OR REPLACE PROCEDURE <procedure_name>(t TABLE) AS {
  MATCH (a@Person)
  PER NODE (a) {
    EXPORT a.id, a.firstName INTO t
  }
}
```

Caller:

```gql
USE #<analytic_graph> {
  TABLE t TYPED TABLE {id INT, name STRING} PARTITION BY DEFAULT
  CALL <procedure_name>(t) FINISH
  PER PARTITION (part) OF t {
    FOR r IN part
    RETURN r.id, r.name
  }
}
```

Apply these boundaries:

- A child containing `PER PARTITION` still requires the actual argument to be distributed.
- Passing by reference allows nested child procedures to contribute rows to the same table.
- Do not infer whole-table operations from pass-by-reference; `size(t)` remains unsupported for a distributed table argument.

## Evidence

- Docs: `analytics-gql-reference/variable-definition/table-variable/`, `analytics-gql-reference/dql/per-partition/`, `analytics-gql-reference/procedures/create/`
- Features: `analytic/PerPartition.feature`, `variable/DistributedTableProcedureArg.feature`, `DataImportExport/BindingTableImport.feature`
- Code boundary: `v5.3.0` rejects local-to-distributed BindingTable import; `c2fabed62` and master `40ff12b51` accept it.
