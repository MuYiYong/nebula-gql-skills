---
name: gql-query-generator
description: 根据自然语言生成、改写、补全或迁移 NebulaGraph 5.3.0 GQL 查询。Use for DQL, MATCH, FILTER, RETURN, WHERE, YIELD, ORDER BY, GROUP BY, LIMIT, OFFSET, CALL, graph patterns, expressions, variables, statement blocks, nearest-neighbor queries, parameterized queries, error-driven rewrites, and Cypher/openCypher or nGQL-to-GQL migration. Do not use for graph algorithms or traversal procedures that require match_compute_statement.
---

# GQL Query Generator

生成以 NebulaGraph `5.3.0` 为兼容基线的可执行 GQL 查询。优先输出查询本身；只在 schema、图名或业务语义不完整时补充最少假设。

## Workflow

1. 判断目标是查询还是过程。若用户要定义过程、实现图算法或使用 `match_compute_statement`，切换到 `gql-procedure-generator`。
2. 提取图名、节点/边类型与标签、属性、方向、过滤、聚合、排序、分页和返回列。未知标识符使用 `<graph_name>`、`<node_type>` 等占位符，不臆造 schema。
3. 选择最小查询骨架：单段 `MATCH ... RETURN`、线性查询、复合查询、命名/内联过程调用、DML 或 statement block。
4. 按下方路由只加载与请求相关的参考。对不确定语法先检索 `tests/features/` 中的正反例。
5. 生成后逐项执行 [validation.md](references/validation.md) 的检查；发现能力边界不确定时回退到更保守、已有测试覆盖的写法。

## Reference Routing

- 查询骨架、子句顺序、DML、statement block 与硬约束：读取 [query-language.md](references/query-language.md) 的相关章节。
- `MATCH`、节点/边/路径模式、方向、路径模式与性能锚点：读取 [patterns.md](references/patterns.md)。
- 动态标签、K-hop 和 5.3.0 新边界：读取 [v5.3.md](references/v5.3.md)。
- 表达式、谓词、标签表达式或优先级：读取 [expressions.md](references/expressions.md)。
- 函数选择：读取 [functions.md](references/functions.md)。
- KNN/ANN：读取 [nearest-neighbor.md](references/nearest-neighbor.md)。
- Cypher/openCypher 或 nGQL 迁移：读取 [migration.md](references/migration.md)。
- 已有错误码驱动的最小改写：读取 [error-codes.md](references/error-codes.md)。
- 需要完整输出范式或负例时：读取 [examples.md](references/examples.md) 的对应小节。

不要一次性加载全部参考。使用标题或关键字定位相关章节；只有复杂迁移或多类语法组合时才组合多个参考。

## Core Generation Rules

- 使用 GQL 语法，不混入 Cypher 的 `*1..3`、`WITH`、`UNWIND`、`MERGE` 或 nGQL 的 `GO`、管道、`==`。
- 将有高选择性过滤条件的锚点放在模式左侧。单变量属性过滤优先下沉到该变量的 pattern filler；跨变量条件放在外层 `WHERE`。
- 使用边后量词表达可变长度路径，例如 `(a)-[:KNOWS]->{1,3}(d)`；不要生成 `[:KNOWS*1..3]`。
- 只在标签名来自字符串 `VALUE` 或绑定变量时生成动态标签表达式。不要把聚合器、文件、表或非字符串值当作标签。
- 不要在同一个节点或边模式中同时使用标签表达式 `:` 和元素类型表达式 `@`。
- 区分元素内部标识与业务属性。仅在用户明确说明兼容语义时才把旧式 `id(v)` 当作业务主键。
- 在线性查询中保证末尾是 `RETURN`、`FINISH` 或更新语句；跨段传递结果时明确使用 `NEXT`。
- 参数化查询使用 `$name`，不要把参数名写成字符串字面量。
- 用户要求“只给查询”时只输出代码块；否则最多补充关键假设和必要说明。

## Evidence Policy

将 v5.3.0 文档作为语法定义，将随包携带的 `.feature` 正反例作为当前实现边界。两者冲突或缺少覆盖时，优先选择 feature 已验证的保守写法，并明确指出剩余假设。
