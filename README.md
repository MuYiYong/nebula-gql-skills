# Nebula Skills

这是一个面向 Nebula GQL 场景的 skill 分发仓库，当前对外发布两个核心 skill。

This repository distributes two core skills for Nebula GQL workflows.

## Skills

- `gql-query-generator`
  - 把自然语言需求转换成 GQL 查询
  - 适合 `MATCH`、`WHERE`、`RETURN`、分页、排序、聚合、子查询和过程调用查询
  - Translates natural language into GQL queries
  - Best for `MATCH`, `WHERE`, `RETURN`, paging, sorting, aggregation, subqueries, and procedure-call queries
- `gql-procedure-generator`
  - 把自然语言需求转换成 GQL Procedure / UDP / 算法过程体
  - 适合 `CREATE PROCEDURE`、`CALL`、控制流、`match_compute_statement` 和图算法
  - Translates natural language into GQL Procedure / UDP / algorithm bodies
  - Best for `CREATE PROCEDURE`, `CALL`, control flow, `match_compute_statement`, and graph algorithms

`planning-with-files` 仅用于本仓库整理过程，不进入最终发布包。

`planning-with-files` is only used for repository maintenance and is excluded from release packages.

## 发布内容

## Release Contents

当前正式发布产物位于 `dist/`。

The current release artifacts are under `dist/`.

当前版本号：由打包脚本按构建日期自动生成（格式：`vYYYYMMDD`）。

Current package version is generated automatically by build date (format: `vYYYYMMDD`).

- `dist/nebula-skills-v<release_version>.zip`
- `dist/gql-query-generator-v<release_version>.zip`
- `dist/gql-procedure-generator-v<release_version>.zip`

推荐优先分发 `dist/nebula-skills-v<release_version>.zip`。它是一个包含两个核心 skill 和根级说明文档的总包。

The recommended distribution artifact is `dist/nebula-skills-v<release_version>.zip`. It is an all-in-one package containing both core skills and the top-level documentation.

每个压缩包都包含这些面向使用者的文件：

Each archive contains these user-facing files:

- `SKILL.md`
- `README.md`
- `INSTALL.md`
- `PROMPTS.md`
- `EXAMPLES.md`
- `FEATURES_INDEX.md`
- `tests/features/`

发布包不会包含这些偏内部维护或打包链路的文件：

Release packages do not include these internal maintenance files:

- `COVERAGE.md`
- `SOURCE_MAP.md`
- `VALIDATION.md`
- `FEATURES.manifest`

如果只是给其它工作区分发，直接提供这两个 zip 即可。

If you only need redistribution, these two zip files are the final deliverables.

## 快速开始

## Quick Start

### 从 zip 安装

### Install From Zip

1. 选择需要的压缩包：
  - `dist/nebula-skills-v<release_version>.zip`
  - `dist/gql-query-generator-v<release_version>.zip`
  - `dist/gql-procedure-generator-v<release_version>.zip`
2. 如果你要一次性安装两个 skill，优先使用 `nebula-skills-v<release_version>.zip` 并解压到目标工作区根目录。
3. 如果你只需要单个 skill，再使用单独的 skill zip，并解压到目标工作区的 `.github/skills/` 目录下。
4. 解压总包后，目录结构应类似这样：

```text
<workspace>/
  README.md
  INSTALL.md
  PROMPTS.md
  .github/
    skills/
      gql-query-generator/
      gql-procedure-generator/
```

5. 解压单个 skill 包后，目录结构应类似这样：

```text
.github/skills/
  gql-query-generator/
    SKILL.md
    README.md
    INSTALL.md
  gql-procedure-generator/
    SKILL.md
    README.md
    INSTALL.md
```

  6. 确认目录名与 `SKILL.md` 里的 `name` 一致，不要额外多套一层目录。

4. Make sure the folder name matches the `name` field in `SKILL.md`, without an extra nested directory.

### 从源码重新打包

### Rebuild From Source

如果你在维护这个仓库本身，可以直接运行：

```bash
python3 scripts/package_core_skills.py
```

脚本会自动：

1. 排除 `planning-with-files`
2. 复制两个核心 skill 到 `dist/`
3. 按各自的 `FEATURES.manifest` 打入测试文件
4. 生成 `FEATURES_INDEX.md`
5. 生成版本化 zip 包
6. 复制 `README.md`、`INSTALL.md` 和 `PROMPTS.md` 到每个分发包

The script will automatically:

1. Exclude `planning-with-files`
2. Copy the two core skills into `dist/`
3. Bundle feature subsets according to each `FEATURES.manifest`
4. Generate `FEATURES_INDEX.md`
5. Generate versioned zip archives
6. Copy `README.md`, `INSTALL.md`, and `PROMPTS.md` into each package

## 如何使用

## Usage

两个 skill 都声明为 `user-invocable: true`，适合在支持自定义 skill 的 Copilot Chat / Agent 环境中直接调用。

Both skills are `user-invocable: true` and are intended for Copilot Chat / Agent environments that support custom skills.

### gql-query-generator

使用它处理这些任务：

- 生成普通 GQL 查询
- 改写筛选、排序、分页、聚合查询
- 生成 `CALL ... YIELD ... RETURN` 查询
- 补全 `LET`、`FILTER`、`NEXT`、子查询等查询结构

Use it for:

- generating standard GQL queries
- rewriting filtered, sorted, paged, or aggregated queries
- producing `CALL ... YIELD ... RETURN` queries
- filling in `LET`, `FILTER`, `NEXT`, and subquery structures

可直接复制的提示词见 `PROMPTS.md`，输出骨架示例见 `EXAMPLES.md`。

Use `PROMPTS.md` for copy-paste prompts and `EXAMPLES.md` for output skeletons.

### gql-procedure-generator

使用它处理这些任务：

- 生成 `CREATE PROCEDURE` / `ALTER PROCEDURE` / `DROP PROCEDURE`
- 生成 `CALL` / `OPTIONAL CALL`
- 编写 `WHILE`、`IF`、`RETURN ... NEXT ...` 等过程逻辑
- 编写图算法、状态传播和 `match_compute_statement`

Use it for:

- generating `CREATE PROCEDURE` / `ALTER PROCEDURE` / `DROP PROCEDURE`
- generating `CALL` / `OPTIONAL CALL`
- writing `WHILE`, `IF`, and `RETURN ... NEXT ...` procedure logic
- building graph algorithms, state propagation, and `match_compute_statement` workflows

可直接复制的提示词见 `PROMPTS.md`，输出骨架示例见 `EXAMPLES.md`。

Use `PROMPTS.md` for copy-paste prompts and `EXAMPLES.md` for output skeletons.

## 如何选用

## How To Choose

- 如果目标是查询数据，使用 `gql-query-generator`
- 如果目标是定义或生成过程，使用 `gql-procedure-generator`
- 如果一个任务同时包含“先定义过程，再调用过程”，先用 `gql-procedure-generator`，再用 `gql-query-generator`
- If the goal is querying data, use `gql-query-generator`
- If the goal is defining procedures or algorithms, use `gql-procedure-generator`
- If a task includes both “define a procedure” and “call the procedure”, use `gql-procedure-generator` first and `gql-query-generator` second

## 测试资产如何进入分发包

## How Test Assets Are Packaged

每个 skill 目录都维护自己的 `FEATURES.manifest`。打包时会从仓库根目录 `features/` 中按 manifest 收集对应的 `.feature` 文件，并复制到分发包的 `tests/features/` 中。

Each skill keeps its own `FEATURES.manifest`. During packaging, matching `.feature` files are collected from the repository-level `features/` directory and copied into `tests/features/` inside the package.

这意味着：

- 源仓只维护一份测试资产
- 分发包仍然是自包含的
- 不需要手工复制 feature 文件

That means:

- the source repository keeps only one copy of test assets
- release packages remain self-contained
- no manual feature copying is needed

## 仓库结构

## Repository Layout

- 源 skill：`.github/skills/`
- 原始 feature：`features/`
- 打包脚本：`scripts/package_core_skills.py`
- 分发目录：`dist/`

If you are an end user, start with `INSTALL.md` inside each package.