# 正则技能发布：证据差异与验收（2026-11-06）

旧版本的验收基于提交 `c93f01024c615556721c00532a93539d595adfef`。本次正则修复改变了技能源码和执行器，因此需要重新生成与执行证据。指纹过期本身不表示查询结果发生语义冲突。

## 哪些指纹不匹配

| 检查项 | 旧证据指纹 | 当前正则版本指纹 | 是否一致 |
| --- | --- | --- | --- |
| `skills_sha256` | `e4354fe75c3f7fd08b86668b8747e39fbf169e634f5299471cc45d4625e1de51` | `b83188c0e520c214a93946059ae055562dba9f924fc6f122b076b20abf75176b` | 否 |
| `runner_sha256` | `0d16e32f162360817e067a620d0bc975d6c7f3097ee38bece112153a2ab5a7c1` | `abac1c6b4128d3639a17838a6bc72aa40a865ffeba36b9ff1871ef05baa42e4c` | 否 |
| `suite_sha256` | `1ef49b157eee45c0e05f1225f1b6a399f0b10d2c2dbf95fe0a7e8255571ba564` | `1ef49b157eee45c0e05f1225f1b6a399f0b10d2c2dbf95fe0a7e8255571ba564` | 是 |

升级前，`evals/quality/evidence/current/model-run.json` 和 `calibration.json` 都绑定旧技能与旧执行器。校验器在第一处技能指纹错误时停止，因此上一条错误信息没有继续列出执行器差异。

## 11 个技能文件的具体变化

共修改 9 个文件、新增 2 个文件；两个技能各自携带完整参考与独立脚本。

| 文件 | 变化 | 内容及判定依据 |
| --- | --- | --- | --- |
| [src/gql-procedure-generator/SKILL.md](../src/gql-procedure-generator/SKILL.md) | 修改 | 将正则请求路由到专项参考，并要求保持 regexp_like 的匹配与转义语义 |
| [src/gql-procedure-generator/references/checklist.md](../src/gql-procedure-generator/references/checklist.md) | 修改 | 将正则请求路由到专项参考，并要求保持 regexp_like 的匹配与转义语义 |
| [src/gql-procedure-generator/references/regular-expressions.md](../src/gql-procedure-generator/references/regular-expressions.md) | 新增 | 新增整串匹配、选项、两层转义、参数、NULL、错误及迁移说明 |
| [src/gql-procedure-generator/scripts/skill_tools.py](../src/gql-procedure-generator/scripts/skill_tools.py) | 修改 | 新增 =~ 静态检测，字符串与注释中的相同文本不报错 |
| [src/gql-query-generator/SKILL.md](../src/gql-query-generator/SKILL.md) | 修改 | 将正则请求路由到专项参考，并要求保持 regexp_like 的匹配与转义语义 |
| [src/gql-query-generator/references/checklist.md](../src/gql-query-generator/references/checklist.md) | 修改 | 将正则请求路由到专项参考，并要求保持 regexp_like 的匹配与转义语义 |
| [src/gql-query-generator/references/expressions.md](../src/gql-query-generator/references/expressions.md) | 修改 | 将正则请求路由到专项参考，并要求保持 regexp_like 的匹配与转义语义 |
| [src/gql-query-generator/references/functions.md](../src/gql-query-generator/references/functions.md) | 修改 | 将正则请求路由到专项参考，并要求保持 regexp_like 的匹配与转义语义 |
| [src/gql-query-generator/references/migration.md](../src/gql-query-generator/references/migration.md) | 修改 | 将正则请求路由到专项参考，并要求保持 regexp_like 的匹配与转义语义 |
| [src/gql-query-generator/references/regular-expressions.md](../src/gql-query-generator/references/regular-expressions.md) | 新增 | 新增整串匹配、选项、两层转义、参数、NULL、错误及迁移说明 |
| [src/gql-query-generator/scripts/skill_tools.py](../src/gql-query-generator/scripts/skill_tools.py) | 修改 | 新增 =~ 静态检测，字符串与注释中的相同文本不报错 |

执行器指纹另包含下列两个仓库脚本变化：

- [scripts/skill_tools.py](../scripts/skill_tools.py)：与两个独立技能中的副本一致，新增不受支持的正则运算符检查。
- [scripts/validate_database.py](../scripts/validate_database.py)：新增 `--cases`，可以选择新增的只读正则测试集；默认仍为原测试集。

其余参与执行器指纹的文件未改变。原 13 案例语义测试集指纹也未改变。新增的 8 条正则参考用例单独存放在 `evals/regex-cases.json`，没有替换或放宽原语义标准。

## 旧生成与运行证据为什么失效

- 旧 26 份生成结果绑定旧技能指纹。兼容性检查要求每份结果所属的完整技能目录相同；两个技能都发生变化，因此 26/26 份不满足当前版本兼容性。
- 旧模型运行报告与校准报告的技能、执行器指纹都过期；旧结果仍可证明旧发布版本，不能证明本次新版本。旧证据已逐字节保存在 [2026-10-25 归档](../evals/quality/evidence/2026-10-25/)。
- 不能只修改旧 JSON 里的指纹，也不能为了继续使用旧证据而回退已确认的正则修复。

另发现 [关键字运行报告](../evals/keywords/runtime-check.json) 也携带旧整包指纹。关键字目录本身未改变，仍已重新运行 862 个大小写别名及 4 个固定程序，全部通过；旧报告保存在 [历史归档](../evals/keywords/history/runtime-check-2026-10-25.json)。`generation.json` 同样需要随 26 个新候选更新生成来源与摘要。

## 以哪个为准

1. **语法与能力以公开 5.3.0 手册为准**；固定版本源码和 feature 用于确认实现限制。本次 `regexp_like`、整串匹配与选项均已按这三类来源核对。
2. **发布内容以修复后的当前源码为准**。服务端固定负例确认 `=~` 返回 `42001`，非法 pattern 返回 `NR003`；修复方向有实际依据。
3. **测试标准保留原有 oracle、校准变体和新鲜度检查**。重新独立生成全部候选，再执行校准、语义结果比对和自有临时图清理验证。
4. **发布资格以当前源码的新终态证据为准**。只有本地完整门禁通过、同一提交的 GitHub CI 发布任务成功，并核对实际资产字节后，才算发布完成。

## 当前验收进展

- 新校准：13/13 组通过，自有临时图清理成功。
- 新正则执行用例：5/5 通过服务端 EXPLAIN 和实际类型化结果比对，见 [regex-current.json](../evals/reports/regex-current.json)。
- 原有只读参考执行用例：12/12 通过，见 [database-fixtures-2026-11-06.json](../evals/reports/database-fixtures-2026-11-06.json)。历史模型的 12 条可执行输出也在新执行器上重跑通过，见 [database-current.json](../evals/reports/database-current.json)；该重跑未宣称是重新生成。
- 两个固定错误控制均通过：移除的运算符 `42001`、非法正则 `NR003`，见 [regex-error-controls.json](../evals/reports/regex-error-controls.json)。
- 26/26 份候选均在独立新上下文生成，92/92 次输入比对通过，所有自有临时图清理成功。新证据见 [model-run.json](../evals/quality/evidence/current/model-run.json)、[calibration.json](../evals/quality/evidence/current/calibration.json) 和 [generation.json](../evals/quality/evidence/current/generation.json)。

| 范围 | 新候选通过 | 输入结果比对 |
| --- | ---: | ---: |
| 图查询 | 12/12 | 48/48 |
| Database 过程体 | 6/6 | 22/22 |
| 本地匹配计算 | 8/8 | 22/22 |

这是原有 13 个定向案例的重新验收，不是新的总体准确率测量。命名过程生命周期、分布式 Analytics 和业务性能 SLA 仍未获得本轮执行验收。精确模型快照与采样参数未由代理工具暴露；读取隔离按指令约束，没有声称操作系统沙箱。

本地完整发布门禁 `python3 scripts/check_all.py` 已全部通过：80 项单元测试、37 条原参考合约、8 条正则参考合约、37 条历史输出静态合约、16 条路由合约、新语义证据重算、三个 ZIP 以及解压后的独立工具检查。六个生成能力目录也与固定手册和 parser 一致。发布继续使用 main 上既有的验证、打包、同提交 CI 资产发布机制；实际发布身份与资产以对应 GitHub Actions 和 Release 为准。
