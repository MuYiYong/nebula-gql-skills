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
- 全局聚合值变量在所有使用位置是否都写成 `@agg_name`？
- 点绑定聚合值变量在所有使用位置是否都写成 `node.@agg_name` 或 `NODE(id_expr).@agg_name`？
- 聚合器声明时是否只给“语法要求初始值”的类型写了 `= <value_expression>`？
- 如果用了 `SumAgg` / `MinAgg` / `MaxAgg` / `AndAgg` / `OrAgg`，是否确认声明时都带了初始值？
- 如果用了 `AvgAgg` / `ListAgg` / `SetAgg` / `MapAgg` / `TopKAgg`，是否确认声明时没有补初始值？
- 如果存在类型差异，是否先判断过该场景是否属于文档支持的隐式转换，而不是机械地一律补 `CAST(... AS ...)`？
- 只有在隐式转换不支持、会报错，或用户明确要求固定目标类型时，才显式写了 `CAST(... AS ...)`？
- 如果用了 `AndAgg` / `OrAgg`，是否确认声明没有类型参数，例如没有写成 `OrAgg<BOOLEAN>`？
- `CALL` 是否跟了结果语句？
- `RETURNS` 与最终返回列是否一致？
- 是否避免输出路径、页面名、外部出处或“去查文档”的表述？

## Fail-safe rewrite rules
- 如果某个算法只能想到普通 `MATCH` 写法，停止输出并改写成 `WHILE` + 单轮 `match_compute_statement`。
- 如果聚合值变量被裸用或被写成普通属性访问，统一重写成 `@agg_name`、`node.@agg_name` 或 `NODE(id_expr).@agg_name`。
- 如果给 `AvgAgg`、`ListAgg`、`SetAgg`、`MapAgg`、`TopKAgg` 声明补了初始值，直接删掉声明期初始化；若需求是重置内容，改写为后续 `SET` / `clear()`。
- 如果漏写了 `SumAgg`、`MinAgg`、`MaxAgg`、`AndAgg`、`OrAgg` 的声明初始值，停下来补齐与声明类型匹配的初始化右值。
- 如果聚合值变量存在类型差异，先判断文档是否支持该隐式转换；只有不支持、会报错，或用户明确要求固定目标类型时，再补 `CAST(... AS ...)`。
- 如果生成了 `OrAgg<BOOLEAN>`、`AndAgg<BOOLEAN>` 或其它带类型参数的布尔聚合器声明，直接改写成 `OrAgg` / `AndAgg` 无类型参数形式。
- 如果不确定聚合器元素类型是否合法，简化成标量结果列或更保守的聚合器。
- 如果不确定某个过程体子句是否合法，删掉可疑子句，保留最小可用过程骨架。
