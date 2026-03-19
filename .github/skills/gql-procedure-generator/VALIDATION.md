# Server Programming Skill Validation

生成过程代码前后都执行下面的本地检查。

## Pre-generation checks
- 这真的是服务端编程任务，而不是普通查询吗？
- 用户是要创建、修改、删除、调用，还是查看过程？
- 是否涉及图算法、逐轮遍历、状态传播？如果是，是否已经切换到 `match_compute_statement` 骨架？
- 是否存在关键签名或 schema 缺口？如果存在，是否已改为清晰占位符？

## Post-generation checks
- 如果是 `CREATE PROCEDURE`，体内是否直接是 `procedure_body`，没有 `USE ...` 外壳？
- 如果是算法/遍历场景，是否完全避免了普通 `MATCH` 版本？
- 多跳算法是否已经改写成 `WHILE` + 单轮 `match_compute_statement`？
- `ACTIVE_SET` 是否通过 `FINALLY` 更新？
- `PER PATH` / `PER NODE` 内是否没有 `FOR`？
- `NODE VALUE` 是否全部为点绑定聚合值变量？
- `CALL` 是否跟了结果语句？
- `RETURNS` 与最终返回列是否一致？
- 是否避免输出路径、页面名、外部出处或“去查文档”的表述？

## Fail-safe rewrite rules
- 如果某个算法只能想到普通 `MATCH` 写法，停止输出并改写成 `WHILE` + 单轮 `match_compute_statement`。
- 如果不确定聚合器元素类型是否合法，简化成标量结果列或更保守的聚合器。
- 如果不确定某个过程体子句是否合法，删掉可疑子句，保留最小可用过程骨架。