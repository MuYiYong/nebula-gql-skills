# Nebula Skills 中文说明

[English](./README.md)

## 快速跳转

- [仓库概览](#cn-overview)
- [技能列表](#cn-skills)
- [发布内容](#cn-release)
- [快速开始](#cn-quick-start)
- [如何使用](#cn-usage)
- [如何选用](#cn-how-to-choose)
- [测试资产如何进入分发包](#cn-test-assets)
- [仓库结构](#cn-layout)

<a id="cn-overview"></a>
## 仓库概览

这是一个面向 Nebula GQL 场景的 skill 分发仓库，当前对外发布两个核心 skill：

- `gql-query-generator`
- `gql-procedure-generator`

`planning-with-files` 仅用于本仓库整理过程，不进入最终发布包。

<a id="cn-skills"></a>
## 技能列表

### `gql-query-generator`

适合把自然语言需求转换成 GQL 查询，尤其适用于：

- `MATCH`
- `WHERE`
- `RETURN`
- 分页
- 排序
- 聚合
- 子查询
- 过程调用查询

### `gql-procedure-generator`

适合把自然语言需求转换成 GQL Procedure / UDP / 算法过程体，尤其适用于：

- `CREATE PROCEDURE`
- `CALL`
- 控制流
- `match_compute_statement`
- 图算法

<a id="cn-release"></a>
## 发布内容

正式发布产物由 GitHub Actions 构建，并附在 GitHub Releases 中。

当前版本号由打包脚本按构建日期自动生成，格式为 `vYYYYMMDD`。

主要产物如下：

- `nebula-skills-v<release_version>.zip`
- `gql-query-generator-v<release_version>.zip`
- `gql-procedure-generator-v<release_version>.zip`

推荐优先分发 `nebula-skills-v<release_version>.zip`。它是一个包含两个核心 skill 和根级说明文档的总包。

每个压缩包都会包含以下面向使用者的文件：

- `SKILL.md`
- `README.md`
- `README.zh-CN.md`
- `INSTALL.md`
- `PROMPTS.md`
- `EXAMPLES.md`
- `FEATURES_INDEX.md`
- `tests/features/`

发布包不会包含这些偏内部维护或打包链路的文件：

- `COVERAGE.md`
- `SOURCE_MAP.md`
- `VALIDATION.md`
- `FEATURES.manifest`

如果只是给其他工作区分发，直接提供 zip 包即可。

<a id="cn-quick-start"></a>
## 快速开始

### 从 zip 安装

1. 从 GitHub Releases 下载需要的压缩包：
   - `nebula-skills-v<release_version>.zip`
   - `gql-query-generator-v<release_version>.zip`
   - `gql-procedure-generator-v<release_version>.zip`
2. 如果要一次性安装两个 skill，优先使用 `nebula-skills-v<release_version>.zip`，并解压到目标工作区根目录。
3. 如果只需要单个 skill，则使用单独的 skill zip，并解压到目标工作区的 `.github/skills/` 目录下。
4. 解压总包后，目录结构应类似这样：

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

5. 解压单个 skill 包后，目录结构应类似这样：

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

6. 确认目录名与 `SKILL.md` 里的 `name` 一致，不要额外多套一层目录。

### 在 GitHub 上发布

日常维护时，只更新 `.github/skills/` 下的源 skill。

维护约定：
- skill 源文件只改 `.github/skills/`
- 不要手改 `dist/`，它是生成出来的发布产物
- 不再以本地 `dist/` 目录作为发布方式
- 如果要发布，使用 `.github/workflows/build-skills-zip.yml`

该工作流会在 CI 中运行 `python3 scripts/package_core_skills.py`，并自动：

1. 排除 `planning-with-files`
2. 复制两个核心 skill 到 `dist/`
3. 按各自的 `FEATURES.manifest` 打入测试文件
4. 生成 `FEATURES_INDEX.md`
5. 生成版本化 zip 包
6. 复制 `README.md`、`README.zh-CN.md`、`INSTALL.md` 和 `PROMPTS.md` 到每个分发包

<a id="cn-usage"></a>
## 如何使用

两个 skill 都声明为 `user-invocable: true`，适合在支持自定义 skill 的 Copilot Chat / Agent 环境中直接调用。

### 使用 `gql-query-generator` 处理这些任务

- 生成普通 GQL 查询
- 改写筛选、排序、分页、聚合查询
- 生成 `CALL ... YIELD ... RETURN` 查询
- 补全 `LET`、`FILTER`、`NEXT`、子查询等查询结构

可直接复制的提示词见 `PROMPTS.md`，输出骨架示例见 `EXAMPLES.md`。

### 使用 `gql-procedure-generator` 处理这些任务

- 生成 `CREATE PROCEDURE` / `ALTER PROCEDURE` / `DROP PROCEDURE`
- 生成 `CALL` / `OPTIONAL CALL`
- 编写 `WHILE`、`IF`、`RETURN ... NEXT ...` 等过程逻辑
- 编写图算法、状态传播和 `match_compute_statement`

可直接复制的提示词见 `PROMPTS.md`，输出骨架示例见 `EXAMPLES.md`。

<a id="cn-how-to-choose"></a>
## 如何选用

- 如果目标是查询数据，使用 `gql-query-generator`
- 如果目标是定义或生成过程，使用 `gql-procedure-generator`
- 如果一个任务同时包含“先定义过程，再调用过程”，先用 `gql-procedure-generator`，再用 `gql-query-generator`

<a id="cn-test-assets"></a>
## 测试资产如何进入分发包

每个 skill 目录都维护自己的 `FEATURES.manifest`。打包时会从仓库根目录 `features/` 中按 manifest 收集对应的 `.feature` 文件，并复制到分发包的 `tests/features/` 中。

这意味着：

- 源仓只维护一份测试资产
- 分发包仍然是自包含的
- 不需要手工复制 feature 文件

<a id="cn-layout"></a>
## 仓库结构

- 源 skill：`.github/skills/`
- 原始 feature：`features/`
- 打包脚本：`scripts/package_core_skills.py`
- 发布工作流：`.github/workflows/build-skills-zip.yml`
- 临时构建目录：`dist/`（已 gitignore，不提交）

如果你是最终使用者，建议从每个分发包里的 `INSTALL.md` 开始。
