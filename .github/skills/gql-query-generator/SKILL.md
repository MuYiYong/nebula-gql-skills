---
name: gql-query-generator
description: '根据自然语言生成、改写或补全 GQL 查询。Use when translating user intent into GQL query syntax, DQL, MATCH, FILTER, RETURN, WHERE, YIELD, ORDER BY, GROUP BY, LIMIT, OFFSET, CALL, graph patterns, expressions, variables, statement blocks, or query examples in this repo. Do not use for graph algorithms or traversal procedures that should use match_compute_statement.'
argument-hint: '要生成的 GQL 查询需求、筛选条件、返回字段或自然语言描述'
user-invocable: true
---

# GQL Query Generator

## What This Skill Produces
- 根据自然语言生成可直接使用或稍作替换的 GQL 查询草稿。
- 在需要时同时输出查询改写版、占位符假设、简短解释。
- 默认优先给“完整查询 + 关键假设 + 一句话说明”。

## When to Use
- 用户要把自然语言需求转成查询。
- 用户要补全 `MATCH`、`WHERE`、`RETURN`、`ORDER BY`、`OFFSET`、`LIMIT`、`CALL`、`YIELD`。
- 用户要把已有查询改写得更完整、更规范或更接近仓库里的 GQL 风格。
- 用户要生成普通查询、过程调用查询、语句块查询。

## Do Not Use
- 不用于 `CREATE PROCEDURE`、`ALTER PROCEDURE`、`DROP PROCEDURE`、过程体生成。
- 不用于图算法、逐轮遍历、路径状态传播、BFS/DFS、环检测等服务端编程场景。
- 这些场景改用 `gql-procedure-generator`。

## Operating Mode
- 这是一个自包含 skill：默认直接依据本文件中的规则生成查询。
- 同目录下如存在 `SOURCE_MAP.md`、`COVERAGE.md`、`EXAMPLES.md`、`VALIDATION.md`，它们只作为补充材料，而不是运行时依赖。
- 默认不要输出出处、链接、路径或“去查某页”的建议。
- 若某个语法点在本技能包中没有明确规则，优先退回到更保守、更短的查询写法，不要猜测外部语法。

## Internal Query Model

### 1. Canonical query skeleton
默认按下面的顺序组织查询：

```gql
MATCH <graph_pattern>
[WHERE <boolean_expression>]
[CALL <procedure_name>(<arguments>) [YIELD <yield_items>]]
RETURN <return_items>
[ORDER BY <sort_items>]
[OFFSET <offset_value>]
[LIMIT <limit_value>]
```

### 2. MATCH
- 基础形式是 `MATCH <graph_pattern>`。
- 需要“即使当前图模式未命中也继续返回后续列”时，可用 `OPTIONAL MATCH <graph_pattern>`；否则默认普通 `MATCH`，未命中时不返回该行。
- `OPTIONAL MATCH` 不会吞掉 schema / type 级错误；若标签或类型本身不存在，仍按普通 `MATCH` 一样报错，不要把它误写成“未知标签时返回 null”。
- 优先使用最小可读的图模式，不主动引入额外模式修饰符。
- 如果用户只描述对象和关系，按节点变量、边变量、终点变量组织图模式。
- 如果用户没有提供标签、边类型、属性名，使用清晰占位符，例如 `<Tag>`、`<EDGE_TYPE>`、`<property>`。
- 点模式由圆括号包围，边模式由边方向和可选填充器组成，路径模式由点模式和边模式交替构成。
- 如果用户要在后续 `RETURN`、函数或谓词里引用整条路径，可先声明路径变量：`p = <path_pattern>`；若后续只用点/边变量，不要额外引入路径变量。
- 未明确要求路径去重语义时，默认不要主动添加匹配模式或路径类型前缀；保守默认是 `REPEATABLE` 匹配模式和 `WALK` 路径类型。
- 匹配模式前缀只在用户明确约束边重复时生成：`REPEATABLE` 允许重复边和重复点，`DIFFERENT` 不允许重复边。
- 路径类型前缀只在用户明确约束路径结构时生成：`WALK` 允许重复边和点，`TRAIL` 不允许重复边，`ACYCLIC` 不允许重复点，`SIMPLE` 允许起点重复但其他点不重复。
- 若用户同时要求 `DIFFERENT` 且路径类型写成 `WALK` 或未写路径类型，实际应按 `TRAIL` 理解；不要再把这种组合解释成可重复边路径。
- `ALL`、`ANY`、`ALL SHORTEST`、`ANY SHORTEST`、`SHORTEST n` 都可与 `WALK | TRAIL | ACYCLIC | SIMPLE` 组合；其中 `ANY n` / `SHORTEST n` 的 `n` 必须是非负整数，未给出时默认只取 1 条。
- `MATCH` 里的索引提示只在用户明确要求优化器提示时才生成；不要在普通查询中主动编造 hint。
- 点模式填充器的稳定组件顺序是：点变量 -> 标签表达式或点类型 -> 点属性 -> `WHERE`。
- 单个点模式填充器至多使用三类不同组件：一个点变量、一个标签表达式或点类型、一个点属性或 `WHERE`；不要在一个点模式里混入超出这个上限的组合。
- 边模式填充器的稳定组件顺序是：边变量 -> 标签表达式或边类型 -> 边属性 -> `SAMPLE` -> `WHERE`。
- 单个边模式填充器至多使用四类不同组件：一个边变量、一个标签表达式或边类型、一个边属性或 `WHERE`、一个 `SAMPLE`；不要在一个边模式里混入超出这个上限的组合。
- 点模式中：
   - 标签表达式可写 `:Label` 或 `IS Label`
   - 点类型可写 `@Type` 或 `@[Type1, Type2]`
   - 属性过滤可写 `{prop: expr}`
- 边模式中：
   - 标签表达式可写 `:Label` 或 `IS Label`
   - 边类型可写 `@Type` 或 `@[Type1, Type2]`
   - 属性过滤可写 `{prop: expr}`
   - `SAMPLE` 的保守骨架是 `SAMPLE [RIGHT] [<sampling_method>] <sample_size>`；只有在用户明确要采样邻边时才使用
   - 边方向的 7 种稳定写法是：`<-[...]-`、`~[...]~`、`-[...]->`、`<~[...]~`、`~[...]~>`、`<-[...]->`、`-[...]-`
- 当属性字面量过滤足够表达需求时，优先用 `{prop: value}`；需要更复杂布尔条件时再用模式内 `WHERE`。
- `(v{id:1})` 与 `(v WHERE v.id = 1)` 视为等价风格；`[e{id:1}]` 与 `[e WHERE e.id = 1]` 视为等价风格。
- 变长路径使用量词 `*`、`+`、`{n}`、`{m,n}`；只有在用户明确要求多跳或长度范围时才生成。
- 最短路相关需求可使用 `ALL SHORTEST`、`ANY SHORTEST`、`SHORTEST n`；未明确要求最短路时不要默认引入。

### 2A. MATCH YIELD
- `MATCH` 也支持图模式级 `YIELD`，但它和 `CALL ... YIELD` 不是一回事。
- `MATCH ... YIELD` 的稳定用途是只保留图模式中已经绑定的元素变量或路径变量；不要在这里生成任意表达式、聚合或别名改写。
- 保守骨架是：

```gql
MATCH <graph_pattern> YIELD <element_or_path_variable>, ...
RETURN <items>
```

- 只有当用户明确要裁剪 `MATCH` 暴露出的点/边/路径绑定集合时才生成 `MATCH ... YIELD`；否则直接在 `RETURN` 里投影更简单。

### 3. WHERE
- 过滤条件统一放在 `WHERE` 中。
- 可组合比较、范围、布尔表达式和成员判断。
- 多个条件默认用 `AND` 连接；只有用户明确给出“或者”“任一满足”才改成 `OR`。
- 不把排序、分页、投影逻辑塞进 `WHERE`。

### 3A. Core expressions and predicates
- 常量表达式的保守形式是直接使用字面量；稳定可用的字面量类型包括数值、布尔、字符串、日期时间、列表、记录、向量以及 `NULL`。
- 当用户只是要固定值、默认值、占位值或常量列表时，优先直接用字面量，不要额外包一层无意义函数或 `CAST`。
- 变量表达式的保守形式是直接引用当前结果中的列变量，例如 `a`、`b`、`col1`。
- 变量表达式只应引用当前数据集里已经可见的列、别名或绑定变量；它引用的是当前数据集中单个或多个记录的字段，不要引用未在当前作用域产出的名称。
- 字段名称既可以是常规标识符，也可以是分隔标识符；若名称明显依赖关键字或特殊字符，可保守地回退到带分隔的标识符写法。
- 属性表达式的保守形式是：

```gql
<node_variable>.<property_name>
<edge_variable>.<property_name>
<record_expression>.<field_name>
```

- 比较谓词支持 `=`, `<>`, `<`, `>`, `<=`, `>=`。
- 比较两侧应是相同值类型；如果类型不一致，不要强行生成比较表达式。
- 比较谓词任一侧为 `null` 时，结果视为 `null`，因此不要把它误写成普通布尔真值。
- 逻辑表达式的保守形式是：

```gql
<value_expression> AND <value_expression>
<value_expression> OR <value_expression>
```

- `AND` 与 `OR` 都遵循三值逻辑，不是简单的二值布尔运算。
- `AND` 中只要一侧稳定为 `false`，结果即可视为 `false`；若没有 `false` 且至少一侧为 `null`，结果视为 `null`。
- `OR` 中只要一侧稳定为 `true`，结果即可视为 `true`；若没有 `true` 且至少一侧为 `null`，结果视为 `null`。
- 当用户只是表达多个过滤条件同时成立或任一成立时，优先使用 `AND` / `OR` 组合现有谓词，不要为了布尔组合引入额外子查询。
- 条件分支表达式可用 searched case 的保守形式：

```gql
CASE
   WHEN <search_condition> THEN <value_expression>
   [WHEN <search_condition> THEN <value_expression>] ...
   [ELSE <value_expression>]
END
```

- `CASE` 按从上到下顺序匹配第一个为真的 `WHEN`；若所有条件为假或未知，返回 `ELSE`；若省略 `ELSE`，结果为 `NULL`。
- 显式类型转换使用：

```gql
CAST(<value_expression> AS <target_data_type>)
```

- `CAST` 只在用户明确要求类型转换、比较两侧需要稳定到同一类型、或下游函数需要特定类型时使用；不要无理由包裹表达式。
- 构造表达式只在用户明确要求复合值时使用，保守形式包括：

```gql
LIST [<value_expression>, ...]
{ <field_name>: <value_expression>, ... }
PATH [<node_reference>, <edge_reference>, <node_reference>, ...]
```

- `LIST` 的方括号是语法一部分，不能省略。
- `PATH` 构造值必须按“点、边、点、边、点”交替组织；若用户只是要路径匹配结果，不要改写成手工 `PATH [...]` 构造。
- 空值检查使用：

```gql
<value_expression> IS NULL
<value_expression> IS NOT NULL
```

- 当用户要检查图模式或子查询结果是否存在时，可用：

```gql
EXISTS { <graph_pattern> }
EXISTS { <match_statement> }
EXISTS { <procedure_body> }
```

- `EXISTS` 适合存在性判断，不替代外层主查询的结果返回。
- 子查询表达式的保守形式是：

```gql
VALUE { <procedure_body> }
EXISTS { <procedure_body> }
```

- `VALUE { ... }` 只在子查询能稳定收敛成单个值时使用：内部 `RETURN` 应包含聚合返回项，或由 `LIMIT 1` 约束成单行；若结果为空表，则该表达式结果为 `NULL`。
- `EXISTS { ... }` 在子查询结果非空时返回 `true`，空表时返回 `false`。
- 运算符优先级应保守记为：`.` > `[]` > `*`/`/` > `+`/`-` > 比较运算 `(<, >, <=, >=, =, <>)` > `IN`/`LIKE` > `IS NULL`/`IS NOT NULL` > `NOT` > `AND` > `OR`/`XOR`；一旦混合算术、比较和逻辑条件，优先显式加括号，不要赌默认结合顺序。
- `.` 只用于点/边属性或记录字段访问，`[]` 只用于列表按索引取值；若用户需求更像路径模式、标签过滤或过程输出列选择，不要误写成这两类运算符表达式。
- 标签表达式本身也有保守语法，可用于图模式或标签谓词内部：

```gql
<label_name>
%
!<label_name>
<label_factor> & <label_factor>
<label_factor> | <label_factor>
(<label_expression>)
```

- `%` 表示任意标签；仅在用户明确要“任意标签”或“不限制标签”时使用。
- `!` 表示排除标签，`&` 表示标签交集，`|` 表示标签并集；复杂标签条件优先写成标签表达式，不要错误下沉成属性过滤。
- 标签谓词的保守形式是：

```gql
<element_variable> IS LABELED <label_expression>
<element_variable> IS NOT LABELED <label_expression>
<element_variable> : <label_expression>
```

- 冒号形式可视为 `IS LABELED` 的简写；只在判断图元素标签时使用，不要和属性过滤混淆。
- 当用户要求多个图元素彼此不同或完全相同时，可分别使用：

```gql
ALL_DIFFERENT(<element_variable>, <element_variable>, ...)
SAME(<element_variable>, <element_variable>, ...)
```

- `ALL_DIFFERENT` 与 `SAME` 都要求至少两个图元素变量；它们适合放在 `WHERE` 中表达图元素之间的关系约束。

### 3B. Function family selection
- 当用户只说“做某种计算”而没有给出明确函数名时，优先根据需求落到函数家族，而不是编造具体函数。
- 保守的函数家族映射是：
   - 聚合统计需求：优先聚合函数，并检查是否需要 `GROUP BY`。
   - 列表处理需求：优先列表函数或 `FOR` 展开，不要混成路径遍历。
   - 字符串清洗与格式化：优先字符串函数。
   - 数值计算：优先数学函数。
   - 日期时间处理：优先 temporal 函数，并确保输入值是时间相关类型。
   - 向量相似度或近邻：优先已有 nearest-neighbor / vector 家族，不要退化成普通数值比较。
   - 全文检索、地理计算、图专用函数：只有当用户明确提出对应域需求时才考虑。
   - lambda 家族：只有在用户明确需要高阶列表处理时才生成。
- 若无法确认具体函数名、参数签名或返回类型，优先退回更保守的查询结构，例如 `MATCH + WHERE + RETURN`、聚合或 `CALL`，不要臆造函数调用。
- 向量函数只在输入明确是向量值时使用；若涉及两个向量的算术、距离或相似度计算，向量维度必须一致。
- 全文函数只在用户明确要全文检索评分时使用；若没有已建全文索引的前提，不要主动生成 `ftscore(...)` 一类调用。
- 地理空间函数只在输入明确是 `Geography` / WKT 语义时使用；若只是普通字符串或数值坐标条件，不要伪装成 `ST_*` 调用。
- 图函数只在处理路径、点、边或图元素标签/属性时使用，例如 `nodes(path)`、`edges(path)`、`labels(element)`；不要把它们用于普通标量或任意记录。

### 3C. Lambda expressions and lambda functions
- Lambda 表达式的保守形式是：

```gql
<variable> -> <value_expression>
```

- Lambda 只应出现在接受 lambda 参数的匿名函数中，不要把它当作独立的顶层值表达式、`RETURN` 主体或普通谓词直接生成。
- Lambda 主体可使用普通值表达式，但不要在其中放聚合表达式或子查询表达式。
- 当前最稳定的 lambda 函数语境是列表处理：

```gql
transform(<list_expression>, x -> <value_expression>)
filter(<list_expression>, x -> <predicate_expression>)
reduce(<list_expression>, <initial_value>, (acc, x) -> <value_expression>)
```

- `transform` 适合把列表元素映射成新列表；返回元素类型可以与原列表不同。
- `filter` 适合按布尔条件保留列表元素；lambda 结果应是谓词，而不是任意非布尔值。
- `reduce` 只在用户明确要求“累积”“折叠”“归并成单值”时使用；若累加器语义不清晰，不要主动生成。
- 若需求并非针对列表逐元素处理，优先不用 lambda，而回退到普通函数、`FOR`、`FILTER` 或标准查询结构。
- 不要生成嵌套 lambda；若一层 `transform`/`filter`/`reduce` 已不能清晰表达需求，优先回退到普通查询结构或过程式展开。

### 4. RETURN
- 基本语法：

```gql
RETURN [ALL | DISTINCT] <value_expression> [AS <alias>], ...
RETURN [ALL | DISTINCT] *
```

- 别名统一使用 `AS`。
- 需要去重时用 `DISTINCT`，否则默认省略 `ALL` / `DISTINCT`。
- 显式写 `ALL` 时表示保留所有行，这是 `RETURN` 的默认语义；除非用户明确要强调保留重复行，否则通常可省略。
- `AS` 后的别名必须是标识符；若返回列名会撞上关键字，优先改用合法别名，或在直接引用已有列名时使用分隔标识符。
- 只在用户明确要所有列或过程返回列全集时使用 `RETURN *`。

### 5. Aggregation and GROUP BY
- 只要 `RETURN` 中至少有一个聚合表达式，就进入聚合查询模式。
- 进入聚合查询模式后：
  - 非聚合返回项应是分组键。
  - 只有在确实需要按某些列分组时才显式给出 `GROUP BY`。
- 如果用户只说“统计数量”“求平均值”，默认同时返回必要的分组键和聚合列。
- `GROUP BY` 必须跟在至少包含一个聚合函数的 `RETURN` 后面使用。
- 语法骨架：

```gql
RETURN <group_keys_and_aggregates>
GROUP BY <variable_value_expression>, ...
```

- `GROUP BY ()` 表示把所有行归为同一组。
- 分组键应引用当前结果中的列或别名，不要凭空引用未出现的名称。

### 6. ORDER BY / OFFSET / LIMIT
- 分页和排序按固定顺序输出：`ORDER BY` -> `OFFSET` -> `LIMIT`。
- 只分页不排序时可直接用 `OFFSET` / `LIMIT`。
- 排序项默认写成 `<expr> ASC|DESC`。
- 用户只说“最新”“倒序”“Top N”时，优先补出 `ORDER BY ... DESC LIMIT N`。
- `ORDER BY` 支持 `ASC | ASCENDING | DESC | DESCENDING`，以及 `NULLS FIRST | NULLS LAST`。
- 默认空值顺序：升序时等价于 `NULLS LAST`，降序时等价于 `NULLS FIRST`。
- 多个排序键按从左到右依次生效。
- `OFFSET` 也可写作 `SKIP`，两者等价；参数是非负整数。
- `LIMIT` 参数是非负整数。
- 若 `OFFSET` 大于或等于总行数，结果为空；若 `LIMIT` 大于或等于总行数，返回所有剩余行。

### 6A. YIELD
- `CALL ... YIELD` 用于选择或重命名过程输出列；`MATCH ... YIELD` 则只用于选择图模式已绑定的元素变量或路径变量。
- 语法骨架：

```gql
CALL <procedure_name>(<arguments>)
YIELD <column_name> [, <column_name> AS <alias>] ...
RETURN <items>
```

- `CALL ... YIELD` 只选过程已返回的列，不要臆造过程输出字段。
- 若用户要重命名过程输出列，优先在 `YIELD` 中用 `AS`，然后在外层 `RETURN` 使用新列名。

### 7. CALL named procedure
- 命名过程调用语法：

```gql
CALL <procedure_name>(<argument_list>) [YIELD <yield_items>]
RETURN <return_items>
```

```gql
OPTIONAL CALL <procedure_name>(<argument_list>) [YIELD <yield_items>]
RETURN <return_items>
```

- `CALL` 后必须继续给结果语句；默认补成 `RETURN ...`，不要只停在 `CALL`。
- 命名过程调用后必须跟 primitive result 语句；最保守的收口写法就是 `RETURN ...` 或 `RETURN *`，不要只输出孤立的 `CALL ...`。
- 若用户要挑出部分过程返回列，优先用 `YIELD` 再 `RETURN`。
- `OPTIONAL CALL` 的保守语义是“未命中时保留该行并产出 `null` 列”；普通 `CALL` 未命中时则不返回结果行。
- 过程的字符串参数值必须用单引号或双引号包围；不要把裸字符串直接塞进参数列表。
- 若过程返回列名本身是关键字，例如 `schema`，在后续 `RETURN` / `FILTER` / `ORDER BY` 中引用它时应改用分隔标识符。
- 若用户没有指定返回列，优先给 `RETURN *` 作为最小可用版本。

### 8. CALL inline procedure
- 内联过程调用语法：

```gql
CALL {
  <procedure_body>
}
RETURN <return_items>
```

```gql
OPTIONAL CALL {
  <procedure_body>
}
RETURN <return_items>
```

- 当用户想把一组查询封装起来再做二次排序、过滤、聚合时，优先考虑内联过程。
- 内联过程适合查询组合，不适合替代命名过程定义。

### 9. FILTER
- `FILTER` 用于从前一个语句生成的数据集中筛出子集。
- 语法骨架：

```gql
FILTER [WHERE] <search_condition>
```

- `FILTER` 可以接在 `MATCH`、`CALL`、`FOR` 等前置语句之后。
- 当过滤条件只是对上一步结果做二次筛选时，可优先使用 `FILTER`，而不是回写到更早的 `WHERE`。
- 如果过滤发生在聚合之后，必须先把前一段结果通过 `NEXT` 传给后续语句，再执行 `FILTER`。

### 10. LET
- `LET` 用于声明后续语句可使用的变量。
- 语法骨架：

```gql
LET <variable_name> = <value_expression>, ...
```

- `LET` 通过在当前结果表上新增列定义变量。
- 想在 `NEXT` 之后继续使用 `LET` 变量时，必须先把变量放进 `RETURN` 中。
- 同一个 `LET` 子句里的变量名必须唯一。
- 同一个 `LET` 子句里不要让后定义变量依赖前定义变量；若用户要逐步派生中间值，拆成多个连续 `LET` 更保守。
- 适合常量、中间表达式、属性投影、子查询结果缓存。

### 11. FOR
- `FOR` 用于展开列表或表中的元素，供后续语句逐个处理。
- 语法骨架：

```gql
FOR <variable_name> IN <list_expression>
FOR <variable_name> IN <table_reference_expression>
```

- 如果用户要把多个列表首尾拼接后再统一展开，可在 `IN` 右侧使用 `<list_expr> || <list_expr>` 形成单个列表源。
- 多个 `FOR` 级联时生成笛卡尔积。
- `FOR` 可用于展开嵌套列表，也可遍历表变量。
- 在查询 skill 中，`FOR` 只作为数据展开原语，不承担图遍历语义。
- 当前不要生成 `FOR ... WITH ORDINALITY ...` 或 `FOR ... WITH OFFSET ...` 这类标准变体；本地文档明确该能力当前不支持。

### 12. Primitive result and FINISH
- 线性查询最终必须以 primitive result 结束。
- 可用形式：

```gql
RETURN <items> [ORDER BY ...] [OFFSET ...] [LIMIT ...]
FINISH
```

- `FINISH` 用于结束查询且不返回数据。
- 如果用户明确要求“执行但不返回结果”，可生成 `FINISH`。

### 13. Linear query
- 线性查询由若干简单查询语句顺序执行，最终接一个 primitive result。
- 在本技能中，线性查询可由以下稳定子句组成：
   - `MATCH`
   - `LET`
   - `FOR`
   - `FILTER`
   - `CALL`
   - 排序与分页
   - 最终 `RETURN` 或 `FINISH`
- 当用户描述的是“先做 A，再做 B，再做 C”的顺序式查询，优先按线性查询生成。

### 14. Composite query
- 复合查询用于合并多个线性查询的结果集。
- 支持的集合连接词：

```gql
UNION [DISTINCT | ALL]
EXCEPT [DISTINCT | ALL]
INTERSECT [DISTINCT | ALL]
```

- 两侧结果集必须列数一致、列名一致、顺序一致，且同名列类型可比较。
- 默认用 `DISTINCT` 语义；只有用户明确要求保留重复项时才用 `ALL`。

### 15. USE
- `USE` 用于声明查询的工作图或临时图。
- 语法骨架：

```gql
USE <graph_name>
USE <schema_reference>/<graph_name>
USE <temp_graph_name>
```

- 仅当查询明显依赖特定工作图且无法安全省略时才生成 `USE`。
- 若用户明确要切到临时图，临时图名必须以 `#` 开头。
- 如果用户没有提供图上下文，默认不要主动添加 `USE`。

### 16. SAMPLE
- `SAMPLE` 是边模式中的采样子句，用于在遍历过程中对边采样。
- 语法骨架：

```gql
SAMPLE [RIGHT] [FIRST_FETCH | RANDOM | UNIQUE_NEIGHBOR | UNQ_NBR] <sample_size>
```

- 当前仅支持向右采样。
- `SAMPLE` 属于边模式填充器的一部分，且若同处边模式中有 `WHERE`，则 `SAMPLE` 必须出现在 `WHERE` 之前。
- 省略方向关键字时默认仍是向右采样；省略采样方法时默认是 `FIRST_FETCH`。
- `sample_size` 只能是正整数，或 `[0, 100]` 范围内的百分比整数；百分比计算结果出现小数时按向上取整理解。
- 不要对无向边类型生成 `SAMPLE`；在临时图里也不要对左向边模式生成采样。
- 只有当用户明确要求边采样时才生成，不默认引入。

### 17. INSERT / SET / DELETE
- 只有当用户明确要求写操作时才生成 DML；纯检索需求不要主动升级成 `INSERT`、`SET` 或 `DELETE`。
- 查询侧 DML 默认作为语句块中的最后一步输出，不要在写操作后继续拼接额外查询子句。

#### 17A. INSERT
- `INSERT` 的稳定骨架是：

```gql
INSERT <insert_graph_pattern>
INSERT OR REPLACE <insert_graph_pattern>
INSERT OR IGNORE <insert_graph_pattern>
INSERT OR UPDATE <insert_graph_pattern>
```

- 只有在用户明确给出冲突处理偏好时才选 `OR REPLACE`、`OR IGNORE`、`OR UPDATE`；未说明时默认普通 `INSERT`，冲突时报错。
- 点冲突的稳定判定是“同点类型且主键相同”；边冲突的稳定判定是“同边类型且起点/终点相同”，若定义了多边键，还必须同时比较多边键。
- 冲突行为应保守理解为：`INSERT` 报错，`INSERT OR REPLACE` 用新图元素替换旧图元素，`INSERT OR IGNORE` 保留旧图元素并忽略新图元素，`INSERT OR UPDATE` 只更新已存在图元素的属性值。
- 需要基于已匹配到的点继续插边或补新点时，可在插入图模式中引用已有元素变量；若只是插入全新点/边，不要额外先写 `MATCH`。
- 插入模式里的新点或新边应显式给出类型或标签以及属性集合；只有在明确引用已存在图元素时，才允许只写元素变量本身。
- 插入边模式的稳定方向只使用 `<-[...]-`、`-[...]->`、`~[...]~` 三种；不要把查询匹配里的更宽边方向族直接照搬到 `INSERT`。

#### 17B. SET
- `SET` 的稳定骨架是：

```gql
SET <element_variable>.<property_name> = <value_expression> [, <element_variable>.<property_name> = <value_expression>] ...
```

- `SET` 当前只用于更新已有属性值，不要把它写成“新增属性”“批量覆盖所有属性”或“修改标签”的语法。
- 被更新的点或边应来自单一类型的匹配结果；如果上游模式让元素同时落在多个类型语义上，不要贸然生成 `SET`。
- `SET` 后当前不要继续追加其它语句；把它当作该写操作链路的终点。

#### 17C. DELETE
- `DELETE` 的稳定骨架是：

```gql
[DETACH | NODETACH] DELETE <value_expression> [, <value_expression>] ...
```

- 删除点时，若用户明确要连同相连边一起删除，使用 `DETACH DELETE`；若未说明，默认按 `NODETACH DELETE` 理解，有连接边时会报错。
- `DELETE` 可同时删除点和边，但删除目标都应来自当前作用域中已绑定的图元素值表达式；不要编造不存在的元素引用。

### 18. Nearest-neighbor query
- 最近邻查询属于向量搜索查询。
- KNN 依赖 `ORDER BY` 加相似度函数，再配 `LIMIT`。
- ANN 依赖：

```gql
ORDER BY <vector_similarity_function>(...) ASC|DESC
APPROX | APPROXIMATE
LIMIT <k>
OPTIONS { METRIC: <L2|IP>, TYPE: <IVF|HNSW>, NPROBE: <n>, EFSEARCH: <n> }
```

- `euclidean()` 在 ANN 中要求升序；`inner_product()` 在 ANN 中要求降序；`cosine()` 仅支持 KNN。
- ANN 中 `METRIC` 会随排序函数自动约束：`euclidean()` 对应 `L2`，`inner_product()` 对应 `IP`；若用户手写了相互矛盾的 `METRIC`，不要继续生成。
- ANN 若未指定 `TYPE`，保守默认是 `IVF`；当 `TYPE: IVF` 且未写 `NPROBE` 时默认 `8`，当 `TYPE: HNSW` 且未写 `EFSEARCH` 时默认 `16`。
- 最近邻查询不与 `SAMPLE` 混用到近似边匹配场景。

### 19. NEXT bridging rule
- 当用户要把上一段结果传递给下一段查询继续处理时，使用 `NEXT`。
- 典型场景：
   - 聚合之后再过滤
   - 先 `RETURN` / `LET` 出中间列，再在后续语句中复用
- 使用 `NEXT` 时，只有进入前一段 `RETURN` 的列才能在后一段使用。
- 语句块由一条或多条可独立执行的查询语句组成，`NEXT` 用于顺序连接这些语句。
- 一个语句块里：
   - DDL 语句最多一条，且必须独占整个语句块。
   - DML 语句最多一条，且必须是语句块中的最后一条语句。
   - 多段查询之间只通过显式 `NEXT` 传递结果。
- 不要在 `NEXT` 之后直接引用前一段未 `RETURN` 出来的列。

## Inputs to Infer
先从自然语言中提取：

1. 查询对象
   - 节点、边、路径、已有过程结果
2. 过滤条件
   - 属性比较、范围、时间区间、布尔组合、是否去重
3. 返回结果
   - 返回列、别名、聚合、是否返回全部列
4. 排序分页
   - 排序字段、升降序、起始偏移、返回条数
5. 查询形态
   - 普通 `MATCH`、命名过程 `CALL`、内联过程 `CALL { ... }`
6. 缺失信息
   - 图名、schema 名、标签、边类型、属性、过程名、参数名

## Procedure
1. 先判断用户要的是：新生成查询、改写查询、补全子句、解释查询，还是基于过程调用生成查询。
2. 再确定查询主干：`MATCH`、`CALL procedure(...)`，或 `CALL { ... }`。
3. 抽取图模式、过滤条件、返回列、聚合要求、排序分页。
4. 如果 schema 信息不足，继续生成可执行草稿，并把不确定部分改成占位符。
5. 如果请求涉及过程调用：
   - 命名过程用 `CALL ... [YIELD ...] RETURN ...`
   - 查询组合用 `CALL { ... } RETURN ...`
6. 如果请求涉及聚合，确保返回项与分组逻辑一致。
7. 如果请求涉及过程输出列裁剪或重命名，优先在 `YIELD` 中完成。
8. 如果请求涉及排序或分页，按 `ORDER BY` -> `OFFSET` -> `LIMIT` 排列。
9. 如果请求是多步顺序查询，检查是否需要 `NEXT`，并把中间可见列显式放进前一步 `RETURN`。
8. 默认输出顺序：
   - GQL 查询
   - 关键假设
   - 简短说明

## Decision Points
- 如果用户只给业务意图，不给 schema，照样生成查询，并显式列出占位符假设。
- 如果同一需求既可用普通 `MATCH` 也可用 `CALL`，优先选择更短、更直接的一种。
- 如果用户明确要“完整最终语句”，先给查询，解释保持极短。
- 如果用户只是想从一个命名过程取结果，直接生成 `CALL ... RETURN ...`，不要扩展成过程定义。
- 如果用户想先做子查询再做外层排序/聚合，优先生成 `CALL { ... }`。
- 如果用户只想挑选过程输出列或给过程输出列改名，优先用 `YIELD`，不是把所有列都交给外层 `RETURN` 再处理。
- 如果用户只给了简单属性等值条件，优先用模式属性 `{...}`，不要一开始就把全部过滤塞进模式内 `WHERE`。
- 如果用户给了复杂布尔逻辑、空值判断或存在性判断，优先用外层 `WHERE` / `EXISTS` / `IS NULL` 表达。
- 如果用户要对前一步结果做二次筛选，优先考虑 `FILTER`。
- 如果用户要复用中间表达式或给下游语句准备变量，优先考虑 `LET`。
- 如果用户要展开列表、嵌套列表或表变量，优先考虑 `FOR`。
- 如果用户描述的是顺序式多步查询，优先生成线性查询。
- 如果用户描述的是两个或多个结果集的集合运算，优先生成复合查询。
- 如果用户明确要求采样边或向量最近邻，再启用 `SAMPLE` 或最近邻查询模式；否则保持普通查询骨架。
- 如果用户要求聚合后的再筛选或继续加工，优先拆成 `RETURN ... NEXT ...`，不要越过结果可见性规则。
- 如果请求滑向过程定义、过程体、算法遍历，停止扩展，切到 `gql-procedure-generator` 的规则。
- 如果不确定某个高级子句是否合法，优先删除该子句，保留核心查询可用性。

## Hard Constraints
- 不要把普通查询需求扩展成 `CREATE PROCEDURE`。
- 不要臆造未在本 skill 中说明的外部 GQL/SQL/Cypher 语法糖。
- 不要输出只有 `CALL` 没有结果语句的查询。
- 不要把 `YIELD` 用到普通 `MATCH` 查询上；它只服务于过程输出列选择。
- 不要打乱点模式或边模式填充器的组件顺序。
- 不要在没有明确多跳需求时默认引入路径量词或最短路前缀。
- 不要用不同值类型直接做比较谓词。
- 不要为了“看起来更强”而引入复杂但未被当前规则覆盖的模式修饰符。
- 不要在没有明确图上下文时默认加入 `USE`。
- 不要在没有明确采样需求时默认加入 `SAMPLE`。
- 不要把 `FOR` 误用成图遍历原语。
- 不要在需要 `NEXT` 的场景里直接跨段引用未返回的列。
- 不要在没有聚合函数的情况下生成 `GROUP BY`。
- 不要打乱 `ORDER BY`、`OFFSET/SKIP`、`LIMIT` 的相对顺序。
- 不要假设 `OFFSET` 可以接受负数或非整数。
- 不要假设复合查询两侧列名或列顺序可以不一致。

## Quality Bar
完成前检查：

- 是否真的给出了完整 GQL，而不是只解释思路？
- 查询是否至少包含主干和结果部分？
- 占位符和假设是否写清楚了？
- 如果用了点模式或边模式填充器，组件顺序是否符合稳定规则？
- 聚合场景下，分组逻辑是否自洽？
- 如果用了 `GROUP BY`，是否真的存在聚合函数，且分组键来自当前结果列？
- 排序分页顺序是否正确？
- 如果用了 `YIELD`，它是否只引用过程实际输出列，并且别名是否在后续 `RETURN` 中一致使用？
- 如果用了属性表达式，引用对象是否确实是点、边或记录？
- 如果用了比较谓词，比较两侧的值类型是否兼容？
- 如果用了 `IS NULL` 或 `EXISTS`，它是否真的服务于过滤/判断，而不是被误当成返回结构本身？
- `CALL` 场景下，是否跟了 `RETURN` 或等价结果语句？
- 如果用了 `FILTER`，它是否确实作用于前一步结果而不是更适合前移到 `WHERE`？
- 如果用了 `LET`，后续复用变量时是否满足 `RETURN` / `NEXT` 可见性要求？
- 如果用了 `FOR`，输入是否确实是列表或表，而不是图模式？
- 如果用了复合查询，两侧结果集的列名、列数和顺序是否一致？
- 如果用了 `SAMPLE`，它是否出现在边模式中且只用于明确采样需求？
- 如果用了最近邻查询，排序函数、方向、`LIMIT` 与 ANN 选项是否匹配？
- 如果用了 `NEXT`，前一步真正暴露给后一步的列是否齐全？
- 是否避免了过程定义、算法过程体或其他越界内容？

## Output Preferences
- 先输出 GQL，再输出说明。
- 默认中文说明，关键字保留 GQL 原文。
- 信息不足时继续给草稿，不先停下来追问。
- 除非用户明确要求，否则不要把回答写成文档导航。

## Example Requests
- “帮我生成一个查询：找出 2024 年后创建的用户，并返回姓名和邮箱，按创建时间倒序。”
- “把这个自然语言需求改写成 GQL：查两跳好友关系并过滤城市是杭州。”
- “生成一个带分页和排序的 MATCH 查询。”
- “调用某个过程后，只保留 name 和 score 两列并按 score 倒序。”
