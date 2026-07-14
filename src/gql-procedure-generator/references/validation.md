# Server Programming Skill Validation

生成过程代码前后都执行下面的本地检查。

## Pre-generation checks
- 这真的是服务端编程任务，而不是普通查询吗？
- 用户是要创建、修改、删除、调用，还是查看过程？
- 是否涉及图算法、逐轮遍历、状态传播？如果是，是否已经切换到 `match_compute_statement` 骨架？
- 是否明确目标是 Database 还是 Analytics？若涉及分布式表或 `PER PARTITION`，是否确认是 Analytics 5.3.0 环境？
- 若要把本地 BindingTable 导入分布式临时图，是否确认目标不是严格 `v5.3.0`，而是包含 current-master 扩展的已验证版本？
- 是否同时涉及 `IMPORT INTO GRAPH` 与 match compute？若是，是否已规划成 import/compute 两个 sibling 子过程？
- 是否存在关键签名或 schema 缺口？如果存在，是否已改为清晰占位符？
- 是否逐项盘点了准备生成的函数、成员方法和语法形态，并能在 v5.3.0 用户文档中确认对应名称、签名或语法？feature 和代码不能单独授权默认生成。
- 函数或成员方法是否已在 [documented-functions.md](documented-functions.md) 中按完整名称精确命中，并核对环境、接收者、签名、类型和前置条件？
- 不常见语法是否已在 [documented-syntax.md](documented-syntax.md) 或函数目录的非调用形式分区中按关键字命中并核对文档限制？若已命中，不得仅因 feature 或专题示例缺失而拒绝。

## Post-generation checks
- 如果是 `CREATE PROCEDURE`，体内是否直接是 `procedure_body`，没有 `USE ...` 外壳？
- 如果是算法/遍历场景，是否完全避免了普通 `MATCH` 版本？
- 多跳算法是否已经改写成 `WHILE` + 单轮 `match_compute_statement`？
- 如果输入来自 TigerGraph GSQL / 链式 `SELECT` 模式，是否没有把原始多跳链直接照搬成单个 `MATCH ... PER PATH` / `PER NODE`？
- 每个 `match_compute_statement` 的图模式是否都至多只有一条边段？
- 如果无法安全拆成单跳轮次，是否已经改成 staged skeleton / planning procedure，而不是输出不可执行的长链过程体？
- 分布式表是否使用 `TABLE ... PARTITION BY DEFAULT` 声明且没有初值？
- `PER PARTITION` 是否只操作分区别名，没有直接访问外层分布式表？
- `PER PARTITION` 内是否避免图 `MATCH`、任意过程调用、全局聚合器、活动集和表变量导出？
- 分布式表是否避免 `size(t)`、`table_split(t)`、直接 `FOR ... IN t` 和 `SET t.clear()`？
- 子过程若对 `t TABLE` 使用 `PER PARTITION`，调用方是否确实传入分布式表？
- 本地 BindingTable 作为分布式临时图导入源时，是否保留了明确版本前提；严格 `v5.3.0` 是否避免该组合？
- 是否避免在同一过程或祖先调用链中 `IMPORT INTO GRAPH` 后继续 match compute？
- 是否把全局聚合器 chunking 当作透明运行时能力，没有生成手工分块循环或拆分聚合语义？
- `ACTIVE_SET` 是否通过 `FINALLY` 更新？
- `PER PATH` / `PER NODE` 内是否没有 `FOR`？
- `NODE VALUE` 是否全部为点绑定聚合值变量？
- 全局聚合值变量在所有使用位置是否都写成 `@agg_name`？
- 点绑定聚合值变量在所有使用位置是否都写成 `node.@agg_name` 或 `NODE(id_expr).@agg_name`？
- 聚合器声明时是否只给“语法要求初始值”的类型写了 `= <value_expression>`？
- 如果用了 `SumAgg` / `MinAgg` / `MaxAgg` / `AndAgg` / `OrAgg`，是否确认声明时都带了初始值？
- 如果用了 `AvgAgg` / `ListAgg` / `SetAgg` / `MapAgg` / `TopKAgg`，是否确认声明时没有补初始值？
- 如果用了 `SumAgg` / `AvgAgg` / `MinAgg` / `MaxAgg`，是否确认类型参数只落在数值类型（整型族或 `DOUBLE`）上？
- 如果用了 `ListAgg`，是否确认元素类型只落在稳定标量、`LIST<data_type>` 或 `RECORD{...}`，而不是聚合器对象或未确认复杂结构？
- 如果用了 `SetAgg`，是否确认元素类型只落在整型族、`DOUBLE`、`STRING` 这类键型标量上？
- 如果用了 `MapAgg`，是否确认 key 只落在整型族、`DOUBLE`、`STRING` 上，且 value 只属于 `SumAgg` / `AvgAgg` / `MaxAgg` / `MinAgg` / `AndAgg` / `OrAgg` / `ListAgg` / `SetAgg` / `TopKAgg`，没有再嵌套 `MapAgg`？
- 如果用了 `SetAgg`，是否确认变量名本体不超过 15 个字符，且长度判断不把使用时的 `@` / `node.` 前缀算进去？
- 如果存在类型差异，是否先判断过该场景是否属于文档支持的隐式转换，而不是机械地一律补 `CAST(... AS ...)`？
- 只有在隐式转换不支持、会报错，或用户明确要求固定目标类型时，才显式写了 `CAST(... AS ...)`？
- 如果用了 `AndAgg` / `OrAgg`，是否确认声明没有类型参数，例如没有写成 `OrAgg<BOOLEAN>`？
- 如果用了 `TopKAgg`，是否确认排序字段类型只落在数值、字符串、布尔、日期时间上，且右值严格匹配 `RECORD` / `LIST<RECORD>` / 同类型 `TopKAgg` 的输入规则？
- 如果过程声明了 `RETURNS`，是否确认没有把任何返回列写成 `LIST<RECORD>`，也没有把 `TopKAgg` 的内部结果直接作为 procedure 返回类型暴露出去？
- `CALL` 是否跟了结果语句？
- `RETURNS` 与最终返回列是否一致？
- 是否逐项复核了所有函数、成员方法和语法形态的完整目录证据，既没有因为 feature/代码存在就保留目录外能力，也没有因为 feature/专题示例缺失就删除目录内能力？
- 是否避免输出路径、页面名、外部出处或“去查文档”的表述？

## Fail-safe rewrite rules
- 如果某个算法只能想到普通 `MATCH` 写法，停止输出并改写成 `WHILE` + 单轮 `match_compute_statement`。
- 如果某个 `MATCH ... PER PATH` / `PER NODE` 里出现了两条及以上边段，立刻拆成有序的单跳 stage；如果状态交接仍不明确，降级为 staged skeleton / planning procedure，不要保留长链。
- 如果输入是 TigerGraph GSQL 多跳 `SELECT`，而输出仍然是一种 mode 对应一个长链 `MATCH`，直接回退到“mode 优先级 + 单跳扩展 stage”结构。
- 如果直接读取、遍历或清空分布式表，改写为 `PER PARTITION (part) OF t` 并只操作 `part`。
- 如果严格 `v5.3.0` 过程把本地 BindingTable 导入分布式临时图，停止生成该组合并改用受支持来源；只有运行版本明确包含 current-master 扩展时才保留。
- 如果 `PER PARTITION` 内出现不允许的外部状态、图匹配、过程调用或表导出，移出分区块；无法安全移动时删除该行为并保留最小分区处理骨架。
- 如果导入和 match compute 位于同一过程或祖先调用链，拆成 sibling import/compute 子过程，并在父过程每次调用前显式 `USE g`。
- 如果聚合值变量被裸用或被写成普通属性访问，统一重写成 `@agg_name`、`node.@agg_name` 或 `NODE(id_expr).@agg_name`。
- 如果给 `AvgAgg`、`ListAgg`、`SetAgg`、`MapAgg`、`TopKAgg` 声明补了初始值，直接删掉声明期初始化；若需求是重置内容，改写为后续 `SET` / `clear()`。
- 如果 `SetAgg` 变量名超过 15 个字符，直接缩短声明名，并同步重写所有 `@name`、`node.@name`、`NODE(id_expr).@name` 引用。
- 如果漏写了 `SumAgg`、`MinAgg`、`MaxAgg`、`AndAgg`、`OrAgg` 的声明初始值，停下来补齐与声明类型匹配的初始化右值。
- 如果数值聚合器被写成 `SumAgg<STRING>`、`AvgAgg<BOOLEAN>`、`MinAgg<RECORD{...}>` 一类非数值类型，直接改写成数值类型聚合器，或退回更合适的 `ListAgg` / `TABLE` / 标量流程。
- 如果聚合值变量存在类型差异，先判断文档是否支持该隐式转换；只有不支持、会报错，或用户明确要求固定目标类型时，再补 `CAST(... AS ...)`。
- 如果生成了 `OrAgg<BOOLEAN>`、`AndAgg<BOOLEAN>` 或其它带类型参数的布尔聚合器声明，直接改写成 `OrAgg` / `AndAgg` 无类型参数形式。
- 如果 `SetAgg` 元素类型不是整型族、`DOUBLE`、`STRING` 这类键型标量，直接改写为 `ListAgg`、`TABLE` 或其它更保守的载体，不要硬保留非法 `SetAgg`。
- 如果 `MapAgg` 的 key 不是键型标量，或 value 是 `MapAgg` / 普通标量 / 未列出的聚合器，直接改写成 `MapAgg<K, supported_agg>`、`TABLE` 或多个扁平聚合器；不要保留嵌套 `MapAgg`。
- 如果 `TopKAgg` 被喂入标量、列表外的普通值，或排序字段类型不在数值/字符串/布尔/日期时间范围内，直接改写为合法 `RECORD` 输入或退回其它聚合方式。
- 如果生成了 `RETURNS ret LIST<RECORD>`、`RETURNS (rows LIST<RECORD>)` 或其它把 `TopKAgg` 内部结果直接外露为 procedure 返回类型的写法，直接改写成普通多列返回、受支持的列表元素类型，或更保守的表格化结果。
- 如果不确定聚合器元素类型是否合法，简化成标量结果列或更保守的聚合器。
- 如果函数、成员方法或语法形态无法在完整目录中确认，不得用 feature/代码中的内部名称绕过；改为目录内公开构造，或明确说明不支持并保留最小 skeleton。若已经命中目录，则按文档环境和限制生成，不要求 feature 二次授权。
- 如果不确定某个过程体子句是否合法，删掉可疑子句，保留最小可用过程骨架。
