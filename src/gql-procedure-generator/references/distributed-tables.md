# Distributed Tables and PER PARTITION

## Contents

- Scope
- Definition and consumption
- Allowed and forbidden operations
- Procedure arguments
- Evidence

## Scope

Use this capability only for NebulaGraph Analytics 5.3.0. Do not introduce `PARTITION BY DEFAULT` or `PER PARTITION` into an ordinary Database query or procedure unless the target environment is explicitly Analytics-compatible.

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
- Features: `analytic/PerPartition.feature`, `variable/DistributedTableProcedureArg.feature`
