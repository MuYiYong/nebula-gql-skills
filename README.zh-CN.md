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

## CC Switch 发现、安装与更新

CC Switch 可以直接从这个公开 GitHub 仓库发现并安装两个 skill：

1. 打开 **Skills → Repository Management → Add Repository**。
2. 填写 **Owner** `MuYiYong`、**Name** `nebula-skills`、**Branch** `main`，以及 **Subdirectory** `src`。
3. 点击 **Refresh**，应看到 `gql-query-generator` 和 `gql-procedure-generator` 两个独立 skill。
4. 安装需要的 skill。CC Switch 会保存仓库坐标，后续可以据此检查更新。

CC Switch 通过比较远程 skill 的 SHA-256 内容哈希检测变化。点击 **Refresh** 重新扫描仓库，发现新版本后使用 skill 卡片上的更新操作。`src/` 是有意保留的子目录，用于将 skill 源文件与打包脚本、发布元数据分开。

仓库公开后，也可能在 CC Switch 的 `skills.sh` 搜索中出现；公共注册表的索引由外部服务完成，新公开仓库可能需要等待。上面的自定义仓库配置是立即可用且确定的路径。

## 公开仓库与隐私

只发布可复用的 skill 源文件、文档、测试夹具和发布自动化。不要提交 API Key、密码、私有 URL、导出的配置、会话日志、个人数据或本机路径。`.gitignore` 已忽略本地规划状态、虚拟环境、构建产物、常见凭据文件和本地数据库文件；推送前仍应检查 `git status`。

feature 文件中保留了上游测试语料使用的固定集成测试值和环境变量占位符；它们不是生产凭据，运行测试时也不要替换成真实服务凭据。

## 维护

适配后续 NebulaGraph 版本时：

1. 重新生成完整文档能力目录：`python3 scripts/refresh_documented_capabilities.py --docs-root <path-to-versioned-html>`。
2. 只在文档语义发生变化时更新精简入口和手写约束参考。
3. 从同版本 feature 语料替换 `src/<skill>/tests/features/` 下的测试子集。
4. 同步更新两个 README 和两个 `references/source-map.md` 中的三类版本号。
5. 发布前执行 `python3 scripts/refresh_documented_capabilities.py --docs-root <path-to-versioned-html> --check`、`python3 scripts/audit_skill_capabilities.py`、结构校验和打包验证。

生成的 `documented-functions.md` 和 `documented-syntax.md` 是随 skill 提交的资源文件，不要手工编辑。

不要重新提交生成后的文档站点、仓库级 feature 全量目录、仓库级 `.github/skills/` 源目录或手工修改的 `dist/` 产物。
