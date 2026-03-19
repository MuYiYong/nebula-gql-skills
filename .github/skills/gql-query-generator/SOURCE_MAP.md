# Query Skill Knowledge Map

本文件描述 `gql-query-generator` 的内嵌知识版图。它不是引用索引，而是技能包内部的主题分层。

## Core knowledge
- 数据查询总览
- `MATCH`
- `WHERE`
- `RETURN`
- `GROUP BY`
- `ORDER BY`
- `OFFSET`
- `LIMIT`
- 分页组合规则
- 命名过程调用
- 内联过程调用
- `YIELD`

## Secondary knowledge
- `FILTER`
- 复合查询
- 线性查询
- primitive result

## Deferred knowledge
- `USE`
- `FOR`
- `LET`
- `SAMPLE`
- 最近邻查询

## Packaging rule
- 默认只把 Core knowledge 和 Secondary knowledge 的稳定子集作为默认生成能力。
- Deferred knowledge 可以被识别，但未必作为默认输出。
- 如果后续扩容技能包，应先更新本文件，再同步更新 `COVERAGE.md`、`EXAMPLES.md` 和 `VALIDATION.md`。