# Nebula Skills

[简体中文](./README.zh-CN.md)

## Quick Links

- [Repository Overview](#en-overview)
- [Recent Updates](#en-updates)
- [Skills](#en-skills)
- [Release Contents](#en-release)
- [Quick Start](#en-quick-start)
- [Usage](#en-usage)
- [How To Choose](#en-how-to-choose)
- [How Test Assets Are Packaged](#en-test-assets)
- [Repository Layout](#en-layout)

<a id="en-overview"></a>
## Repository Overview

This repository distributes two core skills for Nebula GQL workflows:

- `gql-query-generator`
- `gql-procedure-generator`

`planning-with-files` is only used for repository maintenance and is excluded from release packages.

<a id="en-updates"></a>
## Recent Updates

Updated on 2026-05-16:

- Refreshed `gql-query-generator` documentation and validation references for independent release quality.
- Added reusable query reference docs under `.github/skills/gql-query-generator/references/`:
  - `patterns.md`
  - `error-codes.md`
  - `expressions.md`
  - `functions.md`
  - `nearest-neighbor.md`
  - `migration.md`
- Added `ISO_39075_nebula_ng_query_gap_report.md` to summarize ISO GQL and Nebula query-layer gaps.

Note:
- These repository-level reference files are for maintenance and skill hardening.
- Release zips keep user-facing files as listed in [Release Contents](#en-release).

<a id="en-skills"></a>
## Skills

### `gql-query-generator`

Use it to translate natural language requirements into GQL queries, especially for:

- `MATCH`
- `WHERE`
- `RETURN`
- paging
- sorting
- aggregation
- subqueries
- procedure-call queries

### `gql-procedure-generator`

Use it to translate natural language requirements into GQL procedures, UDP bodies, or algorithm bodies, especially for:

- `CREATE PROCEDURE`
- `CALL`
- control flow
- `match_compute_statement`
- graph algorithms

<a id="en-release"></a>
## Release Contents

Release artifacts are built by GitHub Actions and attached to GitHub Releases.

The package version is generated automatically from the build date in the format `vYYYYMMDD`.

Primary artifacts:

- `nebula-skills-v<release_version>.zip`
- `gql-query-generator-v<release_version>.zip`
- `gql-procedure-generator-v<release_version>.zip`

The recommended distribution artifact is `nebula-skills-v<release_version>.zip`. It is an all-in-one package containing both core skills and the top-level documentation.

Each archive contains these user-facing files:

- `SKILL.md`
- `README.md`
- `README.zh-CN.md`
- `INSTALL.md`
- `PROMPTS.md`
- `EXAMPLES.md`
- `FEATURES_INDEX.md`
- `tests/features/`

Release packages do not include these internal maintenance files:

- `COVERAGE.md`
- `SOURCE_MAP.md`
- `VALIDATION.md`
- `FEATURES.manifest`

If you only need redistribution, the zip archives are the final deliverables.

<a id="en-quick-start"></a>
## Quick Start

### Install From Zip

1. Download one of the release archives from GitHub Releases:
   - `nebula-skills-v<release_version>.zip`
   - `gql-query-generator-v<release_version>.zip`
   - `gql-procedure-generator-v<release_version>.zip`
2. If you want both skills at once, prefer `nebula-skills-v<release_version>.zip` and extract it into the target workspace root.
3. If you only need one skill, use the corresponding skill zip and extract it into `.github/skills/` inside the target workspace.
4. After extracting the mega bundle, the layout should look like this:

```text
<workspace>/
  README.md
  README.zh-CN.md
  INSTALL.md
  PROMPTS.md
  .github/
    skills/
      gql-query-generator/
      gql-procedure-generator/
```

5. After extracting a single-skill archive, the layout should look like this:

```text
.github/skills/
  gql-query-generator/
    SKILL.md
    README.md
    README.zh-CN.md
    INSTALL.md
  gql-procedure-generator/
    SKILL.md
    README.md
    README.zh-CN.md
    INSTALL.md
```

6. Make sure the folder name matches the `name` field in `SKILL.md`, without introducing an extra nested directory.

### Release From GitHub

Normal repository maintenance should update only `.github/skills/`.

Maintenance rule:
- edit source skills only under `.github/skills/`
- do not hand-edit `dist/`; it is generated release output
- do not publish from a local `dist/` directory
- for release packaging, use `.github/workflows/build-skills-zip.yml`

The workflow runs `python3 scripts/package_core_skills.py` in CI and will automatically:

1. Exclude `planning-with-files`
2. Copy the two core skills into `dist/`
3. Bundle feature subsets according to each `FEATURES.manifest`
4. Generate `FEATURES_INDEX.md`
5. Generate versioned zip archives
6. Copy `README.md`, `README.zh-CN.md`, `INSTALL.md`, and `PROMPTS.md` into each package

<a id="en-usage"></a>
## Usage

Both skills are declared as `user-invocable: true` and are intended for Copilot Chat / Agent environments that support custom skills.

### Use `gql-query-generator` for these tasks

- generating standard GQL queries
- rewriting filtered, sorted, paged, or aggregated queries
- producing `CALL ... YIELD ... RETURN` queries
- filling in `LET`, `FILTER`, `NEXT`, and subquery structures

Use `PROMPTS.md` for copy-paste prompts and `EXAMPLES.md` for output skeletons.

### Use `gql-procedure-generator` for these tasks

- generating `CREATE PROCEDURE` / `ALTER PROCEDURE` / `DROP PROCEDURE`
- generating `CALL` / `OPTIONAL CALL`
- writing `WHILE`, `IF`, and `RETURN ... NEXT ...` procedure logic
- building graph algorithms, state propagation, and `match_compute_statement` workflows

Use `PROMPTS.md` for copy-paste prompts and `EXAMPLES.md` for output skeletons.

<a id="en-how-to-choose"></a>
## How To Choose

- If the goal is querying data, use `gql-query-generator`
- If the goal is defining procedures or algorithms, use `gql-procedure-generator`
- If a task includes both "define a procedure" and "call the procedure", use `gql-procedure-generator` first and `gql-query-generator` second

<a id="en-test-assets"></a>
## How Test Assets Are Packaged

Each skill keeps its own `FEATURES.manifest`. During packaging, matching `.feature` files are collected from the repository-level `features/` directory and copied into `tests/features/` inside the package.

That means:

- the source repository keeps only one copy of test assets
- release packages remain self-contained
- no manual feature copying is needed

<a id="en-layout"></a>
## Repository Layout

- source skills: `.github/skills/`
- source features: `features/`
- packaging script: `scripts/package_core_skills.py`
- release workflow: `.github/workflows/build-skills-zip.yml`
- temporary build output: `dist/` (gitignored, not committed)

If you are an end user, start with `INSTALL.md` inside each package.
