# Functions Reference

## Function Family Selection
当用户没给明确函数名时，按需求落到函数家族：

| 需求域 | 优先函数家族 |
|--------|-------------|
| 聚合统计 | 聚合函数 + 检查 `GROUP BY` |
| 列表处理 | 列表函数或 `FOR` |
| 字符串清洗 | 字符串函数 |
| 数值计算 | 数学函数 |
| 日期时间 | temporal 函数 |
| 向量相似度 | vector 家族 |
| 全文检索 | fulltext 家族（需已建索引） |
| 地理计算 | ST_* 家族（需 Geography 类型） |
| 高阶列表处理 | lambda 家族 |

无法确认具体函数时，退回 `MATCH + WHERE + RETURN` 结构。

## Graph Element Functions
- `element_id(<element>)` — 图元素身份值
- `left_node_id(<edge>)` / `right_node_id(<edge>)` — 边的端点 ID
- `labels(<element>)` — 元素标签列表
- `type(<edge>)` — 边类型
- `nodes(<path>)` / `edges(<path>)` — 路径中的点/边列表
- `property_exists(<element>, '<prop>')` — 属性存在检查
- `typeof(<expr>)` — 值类型名称字符串

**注意**：当前没有内置 `id()` 函数；涉及身份值只用 `element_id()`。

## Temporal Functions
- `duration_between(<t1>, <t2>)` — 时间差；可附加 `DAY TO SECOND` / `YEAR TO MONTH`。
- 两侧应是相同时间类型。

## String Functions
- `NORMALIZE(<str>)` — Unicode 规范化（仅单参数形态）；`NORMALIZE(str, form)` 不支持。
- 只在用户明确要求时谨慎尝试。

## Lambda Expressions
```gql
<variable> -> <value_expression>
```

只出现在接受 lambda 参数的函数中：
```gql
transform(<list>, x -> <expr>)
filter(<list>, x -> <predicate>)
reduce(<list>, <init>, (acc, x) -> <expr>)
```

规则：
- `transform` — 列表映射。
- `filter` — 按布尔条件保留元素。
- `reduce` — 累积折叠，只在用户明确要求时使用。
- 不生成嵌套 lambda；复杂需求退回普通查询结构。
- Lambda 主体不放聚合或子查询。

## Vector Functions
- 只在输入是向量值时使用。
- 两向量维度必须一致。
- `euclidean()` — 欧氏距离。
- `inner_product()` — 内积。
- `cosine()` — 余弦相似度（仅 KNN）。

## Fulltext Functions
- 只在用户明确要全文检索且已有全文索引时使用。
- 不要主动生成 `ftscore(...)` 一类调用。
- `ftscore()` 不支持 `OR` 组合：不能在同一 WHERE/FILTER 中写 `ftscore(n.a, q) > 0 OR ftscore(n.b, q) > 0`。
- 每个 MATCH 分支中只能对同一节点变量调用一次 `ftscore()`。
- 多属性全文搜索必须拆成多个 MATCH + UNION，最后用 `sum()` 聚合分数。

## Geo Functions
- 只在输入是 `Geography` / WKT 语义时使用。
- 不要把普通坐标条件伪装成 `ST_*` 调用。

## Legacy nGQL Migration
- `id(v)` / `id(e)` 承担业务主键语义 → 改写为 `{id: ...}` 或 `WHERE v.id ...`
- `id(v)` / `id(e)` 承担图元素身份值语义 → 改写为 `element_id(...)`
- 不要机械翻译成 `element_id(...)`，先判断语义。
