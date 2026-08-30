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
  audit_skill_capabilities.py
  package_core_skills.py
  refresh_documented_capabilities.py
README.md
README.zh-CN.md
```

skill 源文件只维护在 `src/` 下。`.github/workflows/` 仅用于发布自动化。原仓库级 `.github/skills/`、`site-zh/` 和 `features/` 不再作为源文件输入。

## Skill 设计

每个 `SKILL.md` 都是精简入口，只包含任务路由、工作流、硬约束和参考文件选择规则。`references/` 下自动生成的函数与语法目录负责完整承接文档公开能力，手写参考负责高频选型和约束；目录内能力不需要 feature 二次授权。

随 skill 保存的 `tests/features/` 子集用于证明当前实现边界：

- Query skill：74 个 feature 文件，覆盖 K-hop、动态标签、VC-index 路径场景和优化器证据等。
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

单 skill 压缩包包含一个完整 skill；合集压缩包将两个 skill 目录和仓库 README 直接放在压缩包根目录，不包含版本外层目录或 `.github/` 路径。打包命令只有在重新读取每个 zip 并通过逐文件内容、必需 skill 资源、feature 索引、本地 Markdown 引用、安全归档路径和本机工作区路径检查后才会成功；合集包还会校验严格的根目录白名单，并拒绝任何 `.github` 路径组件。CI 执行同一套失败即停止的检查。`dist/` 是生成产物，不提交到 Git。

同时，GitHub Actions 会在 `main` 上针对 `src/`、`scripts/` 和顶层 README 的相关变更自动执行同一套打包流程，并发布 tag 为 `v<version>_Build<HHMM>`、标题为 `v<version> Build<HHMM>` 的 release。

## 安装

同时安装两个 skill 时，解压 `nebula-skills-<version>.zip`，压缩包根目录为：

```text
gql-query-generator/
gql-procedure-generator/
README.md
README.zh-CN.md
```

将需要的 skill 目录复制到目标 Agent 或运行时识别的 skills 目录。压缩包不会主动创建 `.github/skills/`；如果目标运行时使用这个工作区级安装位置，请自行创建目标目录后再复制 skill。只安装一个 skill 时，也可以直接将对应单 skill 压缩包解压到目标 skills 目录。skill 文件夹名必须与 `SKILL.md` 中的 `name` 一致。

## 维护

适配后续 NebulaGraph 版本时：

1. 重新生成完整文档能力目录：`python3 scripts/refresh_documented_capabilities.py --docs-root <path-to-versioned-html>`。
2. 只在文档语义发生变化时更新精简入口和手写约束参考。
3. 从同版本 feature 语料替换 `src/<skill>/tests/features/` 下的测试子集。
4. 同步更新两个 README 和两个 `references/source-map.md` 中的三类版本号。
5. 发布前执行 `python3 scripts/refresh_documented_capabilities.py --docs-root <path-to-versioned-html> --check`、`python3 scripts/audit_skill_capabilities.py`、结构校验和打包验证。

生成的 `documented-functions.md` 和 `documented-syntax.md` 是随 skill 提交的资源文件，不要手工编辑。

不要重新提交生成后的文档站点、仓库级 feature 全量目录、仓库级 `.github/skills/` 源目录或手工修改的 `dist/` 产物。
