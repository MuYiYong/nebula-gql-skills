# Changelog

Notable changes to the Nebula GQL skills are documented here. Package versions follow the repository's YY.MM.DD convention; release tags also include a build number.

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
