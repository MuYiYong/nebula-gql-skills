# Changelog

Notable changes to the Nebula GQL skills are documented here. Package versions follow the repository's YY.MM.DD convention; release tags also include a build number.

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
