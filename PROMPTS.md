# Nebula Skills Prompt Collection

这份文档提供可直接复制的 prompts，分别对应两个核心 skill。

This file provides copy-paste prompts for the two core skills.

## gql-query-generator

适合查询生成、查询改写、分页排序、聚合和过程调用查询。

Best for query generation, query rewriting, pagination, aggregation, and procedure-call queries.

### Basic Query

- 生成一个 GQL 查询，找出 2024 年后创建的用户，返回姓名和邮箱。
- Generate a GQL query that finds users created after 2024 and returns name and email.

### Pagination And Sorting

- 生成一个查询，返回最近创建的 20 条订单，跳过前 40 条，并按创建时间倒序排序。
- Generate a query that returns the latest 20 orders, skips the first 40, and sorts by creation time descending.

### Aggregation

- 生成一个查询，按城市统计用户数，并按用户数倒序返回。
- Generate a query that counts users by city and returns the result sorted by user count descending.

### Procedure Call Query

- 生成一个调用过程的查询，执行 `my_proc(1, 2)`，只返回 `score` 和 `path` 两列。
- Generate a procedure-call query for `my_proc(1, 2)` and return only `score` and `path`.

### Query Rewrite

- 把下面这段自然语言改写成完整 GQL 查询，缺失的标签和属性用占位符补齐。
- Rewrite the following natural language request into a complete GQL query, using placeholders for missing labels or properties.

## gql-procedure-generator

适合过程定义、控制流、match_compute、图算法和过程调用。

Best for procedure definitions, control flow, match_compute, graph algorithms, and procedure calls.

### Create Procedure

- 生成一个 `CREATE PROCEDURE`，输入两个点 ID，返回共同邻居列表和共同邻居数量。
- Generate a `CREATE PROCEDURE` that takes two vertex IDs and returns the common-neighbor list and count.

### Graph Algorithm

- 生成一个 BFS 过程，输入起点 ID 和最大深度，返回每一层访问到的点。
- Generate a BFS procedure that takes a start vertex ID and max depth, and returns vertices reached at each level.

### Cycle Detection

- 生成一个 cycle detection 过程，输入最大深度，返回所有环路径。
- Generate a cycle detection procedure that takes a max depth and returns all cycle paths.

### Procedure Refactor

- 把下面这段算法需求翻成 `CREATE PROCEDURE`，优先使用 `WHILE + match_compute_statement` 骨架。
- Turn the following algorithm requirement into a `CREATE PROCEDURE`, preferring a `WHILE + match_compute_statement` skeleton.

### Inline Procedure Or Call

- 生成一个 `CALL` 查询，调用 `pagerank_proc(graph_name, 20)`，并返回节点 ID 和分数。
- Generate a `CALL` query for `pagerank_proc(graph_name, 20)` and return vertex ID and score.

## Selection Hint

- 如果你想“查数据”，用 `gql-query-generator`。
- 如果你想“定义过程或写算法”，用 `gql-procedure-generator`。
- If you want to query data, use `gql-query-generator`.
- If you want to define procedures or algorithms, use `gql-procedure-generator`.