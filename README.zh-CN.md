# Nebula Skills

[English](README.md)

本仓库维护两个 NebulaGraph GQL skill：

- `gql-query-generator`：生成、改写和迁移 GQL 查询。
- `gql-procedure-generator`：生成 Procedure、Analytics 算法，以及迁移 TigerGraph GSQL。

## 兼容版本

| 项目 | 版本 |
| --- | --- |
| 中文文档基线 | `5.3.0` |
| Feature 测试基线 | `5.3.0` |
| Skill 适配版本 | NebulaGraph `5.3.0` |

本次刷新使用本地 `v5.3.0_zh_html` 文档语料和 `v5.3.0_features` 测试语料。打包后的每个 skill 都是自包含的，运行时不依赖这两个外部源目录。

## 仓库结构

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
  package_core_skills.py
README.md
README.zh-CN.md
```

skill 源文件只维护在 `src/` 下。`.github/workflows/` 仅用于发布自动化。原仓库级 `.github/skills/`、`site-zh/` 和 `features/` 不再作为源文件输入。

## Skill 设计

每个 `SKILL.md` 都是精简入口，只包含任务路由、工作流、硬约束和参考文件选择规则。详细语法、示例、校验清单、能力覆盖和来源追踪统一放在 `references/` 中，仅在相关场景按需加载。

随 skill 保存的 `tests/features/` 子集用于证明当前实现边界：

- Query skill：67 个 feature 文件，覆盖 K-hop、动态标签和 VC-index 路径场景等。
- Procedure skill：88 个 feature 文件，覆盖 `PER PARTITION`、分布式表参数和 Analytics 聚合器/算法等。

## 打包

执行：

```bash
RELEASE_VERSION=5.3.0 python3 scripts/package_core_skills.py
```

不设置 `RELEASE_VERSION` 时，脚本使用 `YY.MM.DD` 格式的构建日期。

脚本生成：

- `dist/gql-query-generator-<version>.zip`
- `dist/gql-procedure-generator-<version>.zip`
- `dist/nebula-skills-<version>.zip`

单 skill 压缩包包含一个完整 skill；合集压缩包将两个 skill 放在 `.github/skills/` 下，并携带仓库 README。`dist/` 是生成产物，不提交到 Git。

同时，GitHub Actions 会在 `main` 上针对 `src/`、`scripts/` 和顶层 README 的相关变更自动执行同一套打包流程，并发布 tag 为 `v<version>_Build<HHMM>`、标题为 `v<version> Build<HHMM>` 的 release。

## 安装

同时安装两个 skill 时，将 `nebula-skills-<version>.zip` 解压到目标工作区根目录，得到：

```text
.github/skills/
  gql-query-generator/
  gql-procedure-generator/
```

只安装一个 skill 时，将对应单 skill 压缩包解压到目标工作区的 `.github/skills/` 目录。skill 文件夹名必须与 `SKILL.md` 中的 `name` 一致。

## 维护

适配后续 NebulaGraph 版本时：

1. 根据新文档更新精简入口和相关参考文件。
2. 从同版本 feature 语料替换 `src/<skill>/tests/features/` 下的测试子集。
3. 同步更新两个 README 和两个 `references/source-map.md` 中的三类版本号。
4. 发布前执行结构校验和打包验证。

不要重新提交生成后的文档站点、仓库级 feature 全量目录、仓库级 `.github/skills/` 源目录或手工修改的 `dist/` 产物。
