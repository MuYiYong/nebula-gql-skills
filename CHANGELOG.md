# Changelog

Notable changes to the Nebula GQL skills are documented here. Package versions follow the repository's YY.MM.DD convention; release tags also include a build number.

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
