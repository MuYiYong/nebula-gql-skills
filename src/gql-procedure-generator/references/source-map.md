# Procedure Skill Source Map

## Version Baseline

- Documentation: NebulaGraph `5.3.0` Chinese HTML
- Feature corpus: NebulaGraph `5.3.0`
- Skill compatibility: NebulaGraph `5.3.0`
- Code audit: `nebula-ng` tag `v5.3.0` (`ff090434b`) and master `40ff12b51` (2026-07-10)

Refresh corpora: `v5.3.0_zh_html` and `v5.3.0_features`. The packaged skill is self-contained and does not require the original source directories.

## Documentation Mapping

| Skill area | v5.3.0 documentation |
| --- | --- |
| Procedure DDL and signatures | `analytics-gql-reference/procedures/`, `database-gql-reference/procedures/` |
| Match compute | `analytics-gql-reference/match-compute/` |
| Variables and aggregators | `analytics-gql-reference/variable-definition/` |
| Distributed table definitions | `analytics-gql-reference/variable-definition/table-variable/` |
| `PER PARTITION` | `analytics-gql-reference/dql/per-partition/` |
| Control flow and statement blocks | `analytics-gql-reference/control-flow/`, `analytics-gql-reference/statement-block/` |
| Named and inline procedure calls | `analytics-gql-reference/dql/call/` |
| Import, export, and logging | `analytics-gql-reference/in-out/`, `analytics-gql-reference/log/` |
| Database-side procedure management | `database-gql-reference/procedures/`, `database-gql-reference/data-admin/show/show-procedures/` |

## Feature Mapping

The vendored subset under `tests/features/` is the implementation-evidence layer.

| Skill area | Key feature evidence |
| --- | --- |
| Procedure lifecycle and calls | `procedure/*.feature` |
| Analytics traversal and algorithms | `analytic/**/*.feature` |
| Aggregators | `analytic/aggregator/*.feature` |
| Global aggregator transport chunking | `analytic/aggregator/GlobalAggChunking.feature` |
| Distributed tables and partitions | `analytic/PerPartition.feature` |
| Distributed table procedure arguments | `variable/DistributedTableProcedureArg.feature` |
| Variables and scope | `variable/*.feature` |
| Import/export and files | `DataImportExport/*.feature` |
| Version-gated local BindingTable import | `DataImportExport/BindingTableImport.feature`; strict `v5.3.0` rejects it, master after `c2fabed62` accepts it |
| Import/match-compute graph-version boundary | `analytic/BanInvalidMatchCompute.feature` |
| Temporary graphs and dry run | `tempgraph/*.feature`, `dry_run/*.feature` |
| DML inside procedures | `insert/InsertInsideProc.feature`, `delete/DeleteOnMem.feature` |

## Precedence

Use docs to establish syntax and intended semantics. Use feature scenarios to establish the currently validated implementation boundary. When Database and Analytics capabilities differ, require the target environment explicitly and avoid carrying Analytics-only syntax into Database procedures.

The vendored `BindingTableImport.feature` reflects the audited master behavior for local-to-distributed import and differs from the `v5.3.0` tag. Treat that scenario as a version-gated extension, not as default 5.3.0 compatibility.
