# Nebula Skills

[简体中文](README.zh-CN.md)

This repository maintains two skills for NebulaGraph GQL work:

- `gql-query-generator`: generate, rewrite, and migrate GQL queries.
- `gql-procedure-generator`: generate procedures, Analytics algorithms, and TigerGraph GSQL migrations.

## Compatibility

| Item | Version |
| --- | --- |
| Chinese documentation baseline | `5.3.0` |
| Feature-test baseline | `5.3.0` |
| Skill compatibility | NebulaGraph `5.3.0` |

The current refresh used the local `v5.3.0_zh_html` documentation corpus and `v5.3.0_features` test corpus. Each skill is self-contained after packaging; neither external source directory is required at runtime.

## Repository Layout

```text
src/
  gql-query-generator/
    SKILL.md
    agents/openai.yaml
    references/
    tests/features/
  gql-procedure-generator/
    SKILL.md
    agents/openai.yaml
    references/
    tests/features/
scripts/
  package_core_skills.py
README.md
README.zh-CN.md
```

Maintained skill sources live only under `src/`. The former repository-level `.github/skills/`, `site-zh/`, and `features/` trees are no longer source inputs.

## Skill Design

Each `SKILL.md` is a concise entrypoint containing task routing, workflow, hard guardrails, and reference-selection rules. Detailed syntax, examples, validation checks, capability coverage, and source provenance live under `references/` and are loaded only when relevant.

The vendored `tests/features/` subsets serve as implementation evidence:

- Query skill: 67 feature files, including K-hop expansion, dynamic labels, and VC-index path cases.
- Procedure skill: 88 feature files, including `PER PARTITION`, distributed table arguments, and Analytics aggregators/algorithms.

## Build Packages

Run:

```bash
RELEASE_VERSION=5.3.0 python3 scripts/package_core_skills.py
```

If `RELEASE_VERSION` is omitted, the script uses the build date in `YY.MM.DD` format.

The script creates:

- `dist/gql-query-generator-<version>.zip`
- `dist/gql-procedure-generator-<version>.zip`
- `dist/nebula-skills-<version>.zip`

Standalone archives contain one complete skill. The mega archive contains both skills under `.github/skills/` plus the repository README files. `dist/` is generated output and is not committed.

## Install

For both skills, extract `nebula-skills-<version>.zip` into the target workspace root. The result contains:

```text
.github/skills/
  gql-query-generator/
  gql-procedure-generator/
```

For one skill, extract its standalone archive into the target workspace's `.github/skills/` directory. Keep the skill folder name identical to the `name` in `SKILL.md`.

## Maintenance

When refreshing to a later NebulaGraph version:

1. Update each skill's concise entrypoint and relevant references from the new documentation.
2. Replace the vendored feature subsets under `src/<skill>/tests/features/` from the matching feature corpus.
3. Update the three compatibility values in both README files and both `references/source-map.md` files.
4. Run structural validation and package verification before publishing.

Do not reintroduce generated documentation sites, a repository-level feature corpus, or hand-edited `dist/` artifacts.
