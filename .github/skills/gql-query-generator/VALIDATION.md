# Query Skill Validation

生成查询前后都执行下面的本地检查。

## Pre-generation checks
- 这是普通查询、过程调用，还是其实应该落到服务端编程 skill？
- 是否需要聚合？如果需要，分组键是否明确？
- 是否需要排序和分页？如果需要，字段和方向是否明确？
- 是否存在关键 schema 缺口？如果存在，是否改成了明确占位符？

## Post-generation checks
- 是否包含结果语句，例如 `RETURN`？
- `CALL` 后是否跟了结果语句？
- 分页顺序是否是 `ORDER BY -> OFFSET -> LIMIT`？
- 聚合查询里是否混入了没有分组语义的普通返回项？
- 是否误用了本技能包未覆盖的高级语法？
- 是否把过程定义、算法过程体或 `match_compute_statement` 带进了查询输出？
- 是否避免输出路径、页面名、外部出处或“去查文档”的表述？

## Fail-safe rewrite rules
- 如果不确定高级语法是否合法，删除高级语法，保留核心 `MATCH/WHERE/RETURN`。
- 如果不确定能否直接组合复杂查询，改写成 `CALL { ... } RETURN ...` 的保守版本。
- 如果用户请求其实是过程体、遍历或算法，停止生成普通查询，改路由到 `gql-procedure-generator`。