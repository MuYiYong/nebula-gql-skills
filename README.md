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
.github/
  workflows/
    build-skills-zip.yml
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
  audit_skill_capabilities.py
  package_core_skills.py
  refresh_documented_capabilities.py
README.md
README.zh-CN.md
```

Maintained skill sources live only under `src/`. `.github/workflows/` is retained solely for release automation. The former repository-level `.github/skills/`, `site-zh/`, and `features/` trees are no longer source inputs.

## Skill Design

Each `SKILL.md` is a concise entrypoint containing task routing, workflow, hard guardrails, and reference-selection rules. Generated function and syntax catalogs under `references/` provide complete documentation-backed capability discovery; hand-written references provide high-frequency selection and constraints. Cataloged capabilities do not require feature files as a second authorization.

The vendored `tests/features/` subsets serve as implementation evidence:

- Query skill: 74 feature files, including K-hop expansion, dynamic labels, VC-index path cases, and optimizer evidence.
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

Standalone archives contain one complete skill. The mega archive places both skill directories and the repository README files directly at the archive root; it contains neither a version wrapper nor a `.github/` path. Before returning success, the packaging command reads each zip back and verifies its exact file content, required skill resources, feature index, local Markdown links, safe archive paths, and absence of machine-local workspace paths. It also enforces the mega archive's exact root allowlist and rejects `.github` path components. The same fail-closed check runs in CI. `dist/` is generated output and is not committed.

GitHub Actions also runs the same packaging flow automatically on `main` when release-relevant files change under `src/`, `scripts/`, or the top-level README files. The workflow publishes a release tagged as `v<version>_Build<HHMM>` and titled `v<version> Build<HHMM>`.

## Install

For both skills, extract `nebula-skills-<version>.zip`. Its archive root contains:

```text
gql-query-generator/
gql-procedure-generator/
README.md
README.zh-CN.md
```

Copy the desired skill directories into the skills directory recognized by your agent or runtime. The archive intentionally does not create `.github/skills/`; if a target runtime uses that repository-local destination, create it separately and copy the skill directories there. For one skill, you can instead extract its standalone archive directly into the destination skills directory. Keep the skill folder name identical to the `name` in `SKILL.md`.

## Maintenance

When refreshing to a later NebulaGraph version:

1. Regenerate the complete documentation-backed catalogs: `python3 scripts/refresh_documented_capabilities.py --docs-root <path-to-versioned-html>`.
2. Update each skill's concise entrypoint and hand-written constraint references only where the documentation semantics changed.
3. Replace the vendored feature subsets under `src/<skill>/tests/features/` from the matching feature corpus.
4. Update the three compatibility values in both README files and both `references/source-map.md` files.
5. Run `python3 scripts/refresh_documented_capabilities.py --docs-root <path-to-versioned-html> --check`, `python3 scripts/audit_skill_capabilities.py`, structural validation, and package verification before publishing.

The generated `documented-functions.md` and `documented-syntax.md` files are checked-in skill resources. Do not edit them manually.

Do not reintroduce generated documentation sites, a repository-level feature corpus, a repository-level `.github/skills/` source tree, or hand-edited `dist/` artifacts.
