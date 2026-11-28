# Changelog

Notable changes to the Nebula GQL skills are documented here. ZIP versions use the Beijing date in `YY.MM.DD` format. GitHub release tags use `vYY.MM.DD_BuildHHMM`, with `HHMM` from the Beijing time when the workflow resolves the version.

## 26.11.28 - 2026-11-28

### Fixed

- Procedure lint reports conflicting declarations, unresolved node and global aggregators, scalar `node()` lookups, incompatible cardinality assignments and single-node `PER PATH` clauses. Diagnostics include positions and repair guidance. The procedure skill now distinguishes business-key lookup, internal-ID cross-node updates, and the return types of collection, table and aggregator cardinality operations.

### Validation

- Reproduced NS002, both 42N56 reference errors, NR002, NS208 and NS238 on a NebulaGraph 5.3.2 temporary graph. Confirmed the native size return types and successful explicit conversion to UINT64.

## 26.11.27 - 2026-11-27

### Fixed

- Both skills use `DATE` for calendar-day fields, including source values of type `LocalDate`. Before delivery, the bundled lint reports the location of each mistyped `LOCAL DATE` and returns the repaired statement in `corrected_gql` for a second check. The repair preserves `LOCAL DATETIME`, `LOCAL TIME`, quoted names, strings and comments.

### Validation

- On NebulaGraph 5.3.2, `EXPLAIN` returned syntax error 42001 for a graph type with three `LOCAL DATE` declarations and accepted the corrected DDL. All 26 independent benchmark outputs passed 92 database result comparisons.

## 26.11.26 - 2026-11-26

### Fixed

- Both bundled linters now flag backticks on `PRIMARY KEY` and `MULTIEDGE KEY` in inline and list constraints and identify bare property names in the same key list.
- Both skills generate `IS NULL` and `IS NOT NULL` with bare predicate keywords. The bundled lint flags quoted predicate keywords and accepts quoted identifiers that share those names.
- Graph Type DDL now quotes property declarations and every member of primary and multiedge keys. Both bundled checkers recognize the edge label introducer and accept parameterized decimal property types.

### Validation

- On NebulaGraph 5.3.2, `EXPLAIN` accepted all four valid key declarations and returned syntax error 42001 for all 16 quoted-keyword variants. Both bundled linters cover these forms in regression tests.
- Reproduced both syntax errors on NebulaGraph 5.3.2 and verified the corrected queries against synthetic fixtures. All 26 independently generated candidates passed 92 database result comparisons.
- On 5.3.2, reproduced the 42001 error for a bare property named `balance` and verified the fully quoted schema with `EXPLAIN`.

## 26.11.23 - 2026-11-23

### Fixed

- Both skills now enclose every identifier in backticks at declaration and at each use, including ordinary names and keywords used as names. Qualified names and type sets are quoted one component at a time.
- Updated the bundled formatter, lint checks and examples to cover labels, element types, properties, variables, procedure parameters and output aliases. External parameters and temporary graph tokens retain their native spelling.

### Validation

- All 37 generated answers passed their static contracts. On NebulaGraph 5.3.2, 26 independently generated queries and procedure bodies passed 92 result comparisons. Both case variants of all 431 documented keywords passed as column aliases. See the [identifier validation results](docs/keyword-identifiers.md).

## 26.11.18 - 2026-11-18

### Changed

- Consider primary-key constraints, traversal anchors, projected properties and ordering indexes during normal query generation. Preserve row multiplicity, NULL handling and path order when comparing candidates.
- Check index and partition limit details when reading a TopN plan. A storage scan can stop early while the global TopN still merges results across partitions.

### Fixed

- Document a statement-scoped workaround for the tested 5.3.2 build when reordered reverse `ACYCLIC` expansion returns paths with repeated nodes. The workaround preserves the requested path set.

### Validation

- All 12 independently generated query attempts passed 48 result comparisons on 5.3.2. The full scoped suite passed 92 result comparisons, including unchanged procedure examples.
- On the isolated benchmark graph, the median fell from 2.91 ms to 2.06 ms for a primary-key hit and from 4.03 ms to 3.28 ms for an indexed page. The high-fan-out incoming-edge case slightly favored the baseline. See the [benchmark data and plans](evals/reports/query-performance-2026-11-18.json).

## 26.11.06 - 2026-11-06

### Fixed

- Generate `regexp_like(value, pattern[, options])` instead of the removed `=~` operator in both query and procedure skills. Preserve whole-string matching, case handling, pattern escaping, negation, NULL behavior and schema-dependent property paths.
- Detect unsupported regex operators in standalone lint while ignoring strings, quoted identifiers and comments.

### Added

- Self-contained regular-expression guidance covering documented options, newline handling, parameter values and regex-versus-GQL escaping.
- Eight targeted regex generation contracts and five graph-free typed-result fixtures, with explicit case selection in the read-only database validator.
- A file-by-file evidence mismatch audit explaining source/runner fingerprint changes and the unchanged semantic suite.

### Validation

- All five regex execution fixtures and the original twelve graph-free fixtures passed server parsing and typed-result comparison on the compatible 5.3.2 runtime. Thirteen independent oracle calibration pairs passed with owned-fixture cleanup.
- Freshly generated all 26 semantic candidates in separate contexts and matched all 92 input executions against independent oracles, with owned-fixture cleanup. Previous source-bound evidence is retained in dated archives; see the release evidence audit.

## 26.10.25 - 2026-10-25

### Changed

- Quote reserved and non-reserved keywords consistently when they are used as identifiers; ordinary legal names may remain unquoted. Both skill catalogs contain the 224 reserved and 207 non-reserved words verified against the 5.3.0 parser and both manuals.
- Apply the identifier policy to declarations, properties, labels, variables, procedure formal parameters and references, while preserving GQL syntax, built-in functions, data types and string values.

### Added

- Standalone `quote-identifiers` command, expanded static identifier checks, and focused regression coverage.
- Pinned parser/manual keyword consistency checks and keyword-quoting verification of extracted packages.

### Fixed

- Correct identifier delimiters in curated GQL examples. Preserve external `$name` parameter tokens instead of emitting unsupported backtick syntax after `$`.

### Validation

- Freshly generated all 26 semantic candidates for the current source and matched 92 input executions against independent oracles; 13 calibration pairs and the full offline release gate passed. These are scoped regressions, with named-procedure lifecycle and distributed Analytics still unverified.
- Executed 862 uppercase/lowercase keyword alias spellings and checked quoted variables, record fields and top-level aggregation.

## 26.10.23 - 2026-10-23

### Added

- Standalone Python tools for bounded reference lookup and targeted static checks, plus generation and repair checklists in both skill packages.
- Reproducible semantic evaluation with independent result oracles, saved execution evidence, and offline evidence verification.

### Changed

- Route existing-signature CALL/YIELD retrieval to the query skill and procedure definitions, signature design, and stateful algorithms to the procedure skill.
- Validate packaging and extracted standalone tools before publishing the exact checked archives.

### Fixed

- Correct procedure-stage sequencing, Database graph-selection guidance, long SetAgg identifiers, STRING aggregation, and function environment metadata.
- Preserve path uniqueness and duplicate contributions when migrating queries instead of applying non-equivalent replacements.

### Validation scope

- The recorded benchmark passes 26 generation attempts and 92 input comparisons for the covered query, Database procedure-body, and local match-compute cases. These figures do not establish general accuracy.
- Named-procedure lifecycle and distributed Analytics execution remain unverified. The public capability baseline is 5.3.0, with 5.3.2 accepted as a compatible validation environment.
