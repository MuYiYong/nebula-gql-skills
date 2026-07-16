---
name: gql-procedure-generator
description: 根据自然语言生成、改写、补全或迁移 NebulaGraph 5.3.0 GQL Procedure/UDP。Use for TigerGraph GSQL migration, server-side programming, graph algorithms, traversal logic, match_compute_statement, named or inline procedures, CREATE/ALTER/DROP PROCEDURE, CALL or OPTIONAL CALL, control flow, variables, distributed tables, PER PARTITION, logging, and procedure inspection. Do not use for ordinary MATCH/RETURN retrieval queries.
---

# GQL Procedure Generator

生成以 NebulaGraph `5.3.0` 为兼容基线的过程定义、过程调用或分析型算法骨架。优先保证过程体可执行；信息不足时输出带占位符的保守 skeleton，不伪造 schema 或未验证能力。

## Workflow

1. 确认目标是创建、替换、修改、删除、调用、查看过程，还是把 TigerGraph GSQL/自然语言算法迁移为 GQL Procedure。
2. 提取过程名、参数、返回列、运行环境（Database 或 Analytics）、图类型、状态变量、控制流、副作用和终止条件。
3. 在过程作用域开头声明全部变量。把运行中才得到的值先声明，再在后续语句中赋值。
4. 普通过程逻辑使用 statement block；图遍历或算法逻辑使用 `match_compute_statement`。多跳算法拆成 `WHILE` 驱动的多轮 0/1 跳计算。
5. 按下方路由加载相关参考；函数和成员方法先在完整函数目录中精确检索，其它语法先在完整语法目录中精确检索。涉及分布式表时必须读取 [distributed-tables.md](references/distributed-tables.md)，涉及 `IMPORT INTO GRAPH` 后的匹配计算时必须读取 [import-match-compute.md](references/import-match-compute.md)。
6. 生成后执行 [validation.md](references/validation.md)；无法证明可执行时降级为 staged skeleton，并清楚保留用户的阶段、优先级和副作用意图。

## Reference Routing

- 过程 DDL、参数/返回、变量、控制流、`match_compute_statement`、聚合器与迁移规则：读取 [procedure-language.md](references/procedure-language.md) 的相关章节。
- 保留或生成任意函数、聚合器成员方法，或使用函数页记录的非调用形态：先在 [documented-functions.md](references/documented-functions.md) 中精确搜索名称、接收者、签名、运算符或关键字形式零参函数。
- 不常见的过程语句、子句、变量类型、谓词、表达式或数据类型：先在 [documented-syntax.md](references/documented-syntax.md) 中精确搜索关键字，再读取对应专题参考。
- `PARTITION BY DEFAULT`、`PER PARTITION`、`TABLE` 过程参数或本地表导入分布式临时图：读取 [distributed-tables.md](references/distributed-tables.md)。
- `IMPORT INTO GRAPH` 与后续 `match_compute_statement`：读取 [import-match-compute.md](references/import-match-compute.md)。
- 用户指定 BFS、SSSP、PageRank、Louvain、Leiden 等算法：先检索 `tests/features/analytic/algo/` 中对应 5.3.0 feature，再按其过程结构生成或改写。
- 大型全局聚合器或 `global_agg_chunk_size`：检索 `tests/features/analytic/aggregator/GlobalAggChunking.feature`；保持普通聚合器语法，不手工实现传输分块。
- 输出骨架、算法模式、TigerGraph 迁移与负例：读取 [examples.md](references/examples.md) 的对应小节。
- 最终静态检查：始终读取 [validation.md](references/validation.md)。
- 追溯文档、feature 与能力覆盖：需要维护或核实来源时读取 [source-map.md](references/source-map.md) 和 [coverage.md](references/coverage.md)。

不要一次性加载完整的长参考，也不要通读两个完整目录。先用函数名、成员方法、`CREATE PROCEDURE`、`MATCH COMPUTE`、`ACTIVE_SET`、`PER PARTITION`、聚合器名称或源语言关键字定位章节。

## Hard Guardrails

- `CREATE PROCEDURE ... AS { ... }` 的过程体内不要包 `USE graph`；调用方负责选择图。
- 算法/遍历场景使用 `match_compute_statement`，不要退化成普通查询式 `MATCH ... RETURN`。
- 每个 `match_compute_statement` 只生成 0 跳或 1 跳图模式。两条及以上边段必须拆成多轮单跳 stage。
- `match_compute_statement` 中只引用当前边或点和常量/参数的局部条件直接写入对应 pattern `WHERE`；活动集、跨元素和结果级条件保留在 graph pattern `WHERE` 或过程块中。不要为谓词下推引入多跳或 `ACYCLIC`。
- 将 `PER NODE`、`PER PATH` 和 `FINALLY` 直接放在 `MATCH <graph_pattern>` 后，不添加外层圆括号。
- 不要在执行语句开始后新增变量定义。
- `ACTIVE_SET` 默认只在 `FINALLY` 中更新；逐点状态优先使用 `NODE VALUE`，不要无理由提升为全局聚合器。
- TigerGraph GSQL 多跳 `SELECT` 迁移时，分别保留 mode/优先级、逐跳扩展与副作用落地，不要把长链原样翻成一个 `MATCH ... PER PATH`。
- 分布式表只能在 Analytics 能力明确且调用方以 `PARTITION BY DEFAULT` 声明时使用；读取、清空和遍历必须遵守 `PER PARTITION` 边界。
- `TABLE` 参数可接收分布式表引用，但不要据此假设 `size(t)`、直接 `FOR ... IN t` 或任意过程调用可用。
- 严格 5.3.0 不支持把本地 BindingTable 导入 `PARTITION BY DEFAULT` 的分布式临时图；只有目标明确为已验证的 current master/后续版本时才允许该来源组合。
- 不要在同一过程或其祖先调用链中执行 `IMPORT INTO GRAPH` 后继续 match-compute；将导入与计算拆成两个 sibling 子过程并顺序调用。
- 逐项检查输出中的函数、成员方法和语法形态。只有 v5.3.0 用户文档明确记录同名、同签名或对应语法时才默认生成；feature 和代码只验证实现边界，不能单独授权未文档化能力。无法确认时输出保守 skeleton 或说明缺失信息。
- 完整函数与语法目录中存在的能力，只要目标环境、接收者、签名、输入类型、前置条件和文档限制匹配，就允许生成；不得因为专题参考、feature 或算法示例未单独收录而判为不支持。

## Output Contract

- 默认输出完整语句、必要占位符和最多三条关键假设。
- 用户要求“只给过程”时只输出代码块。
- 过程签名变化不能安全由 `ALTER` 完成时，给出 `DROP` 后重新 `CREATE` 的方案。
- 只要求调用已有过程时不要附带虚构的过程定义。

## Evidence Policy

将 v5.3.0 Analytics/Database 用户文档作为完整公开能力白名单，将随包携带的 `.feature` 正反例和代码作为实现边界证据。目录内能力不需要 feature 或专题示例二次授权；目录外内部能力不得由 feature/代码单独授权。遇到 tag 后新增的成功场景时显式按运行版本门控；不能确认版本就保持严格 5.3.0 行为。
