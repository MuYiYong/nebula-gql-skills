# Procedure Skill Source Map

## Version Baseline

- Documentation: NebulaGraph `5.3.0` Chinese HTML
- Feature corpus: NebulaGraph `5.3.0`
- Skill compatibility: NebulaGraph `5.3.0`
- Code audit: `nebula-ng` tag `v5.3.0` (`ff090434b`) and master `40ff12b51` (2026-07-10)

Refresh corpora: `v5.3.0_zh_html` and `v5.3.0_features`. The packaged skill is self-contained and does not require the original source directories.

## Documentation Mapping

The generated [documented-functions.md](documented-functions.md) is the complete callable allowlist for Database and Analytics functions plus documented receiver methods. It contains 146 Database names, 143 Analytics names, 143 shared names, three non-call forms, and 12 receiver-specific method signatures. The generated [documented-syntax.md](documented-syntax.md) indexes all 118 documentation pages in the procedure skill's declared scope. Regenerate both files instead of maintaining a hand-picked allowlist.

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

Use docs as the complete allowlist for public syntax, functions, and member methods. A cataloged capability does not require a feature or specialized example as a second authorization. Feature scenarios and code only establish confirmed implementation boundaries and cannot promote an undocumented internal capability into default output. When Database and Analytics capabilities differ, require the target environment explicitly and avoid carrying Analytics-only syntax into Database procedures.

The vendored `BindingTableImport.feature` reflects the audited master behavior for local-to-distributed import and differs from the `v5.3.0` tag. Treat that scenario as a version-gated extension, not as default 5.3.0 compatibility.
