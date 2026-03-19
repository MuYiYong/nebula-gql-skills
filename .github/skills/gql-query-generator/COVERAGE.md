# Query Skill Coverage

本文件说明 `gql-query-generator` 对技能包内嵌知识能力的覆盖状态。

状态说明：
- `supported`: 已内置为默认生成能力
- `partial`: 只支持保守子集，或仅用于识别/改写
- `deferred`: 文档存在，但暂不内置为默认生成能力
- `out-of-scope`: 不属于本技能包职责

## Coverage table

| Topic | Status | Notes |
|---|---|---|
| 数据查询总览 | supported | 用于整体任务路由与查询主干选择 |
| `MATCH` | supported | 支持基础模式匹配主干 |
| `WHERE` | supported | 支持常见布尔过滤 |
| `RETURN` | supported | 支持别名、`*`、`DISTINCT`、聚合入口 |
| `GROUP BY` | partial | 仅在聚合查询中保守生成 |
| `ORDER BY` | supported | 支持基础排序项 |
| `OFFSET` | supported | 支持分页偏移 |
| `LIMIT` | supported | 支持分页大小 |
| 分页组合 | supported | 固定输出顺序 `ORDER BY -> OFFSET -> LIMIT` |
| 命名过程调用 | supported | 支持 `CALL` / `OPTIONAL CALL` / `YIELD` / `RETURN` |
| 内联过程调用 | supported | 支持 `CALL { ... }` 与 `OPTIONAL CALL { ... }` |
| `YIELD` | supported | 仅用于过程调用后取列 |
| `FILTER` | partial | 可识别和改写，但不作为默认首选主干 |
| 复合查询 | partial | 目前优先用 `CALL { ... }` 表达稳定子集 |
| 线性查询 | partial | 识别为可改写查询形态，不默认扩展 |
| primitive result | partial | 主要作为 `CALL` 后结果约束知识 |
| `USE` | deferred | 默认不生成，避免切图依赖 |
| `FOR` | deferred | 不作为普通查询包默认输出 |
| `LET` | deferred | 暂未内置为查询包默认语法 |
| `SAMPLE` | deferred | 未纳入默认稳定子集 |
| 最近邻查询 | deferred | 需要单独模板和语义约束 |

## Completion criteria
- `supported` 项必须在 `SKILL.md` 或 `EXAMPLES.md` 中有明确模板或决策规则。
- `partial` 项必须说明保守边界，不能假装完整支持。
- `deferred` 项默认不生成，除非后续明确升级技能包。

## Distribution rule
- 本表仅表达技能包内已压缩的能力，不依赖外部文档。
- 对外分发时，不要求接收方具备源码仓库或站点页面。

## Next expansion candidates
- `FILTER`
- 复合查询与线性查询的固定骨架
- 最近邻查询专用模板
- `LET` 与 `FOR` 的查询侧安全子集