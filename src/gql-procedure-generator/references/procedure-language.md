# Procedure Language Reference

Use this file as the detailed NebulaGraph 5.3.0 procedure and Analytics syntax reference. Search by statement, variable type, aggregator, or migration keyword instead of loading the whole file.

## Contents

- Task boundary, operating mode, and procedure skeletons
- Procedure DDL, calls, and inspection
- `match_compute_statement` and path-state expansion
- Value, node, active-set, table, file, graph, and aggregator variables
- Control flow, logging, import/export, and statement blocks
- Generation workflow, decision rules, and forbidden patterns

## What This Skill Produces
- 根据自然语言生成可直接使用或稍作替换的 GQL Procedure / UDP 草稿。
- 可输出命名过程定义、内联过程、命名过程调用、修改/删除语句、过程反查语句。
- 默认优先给“完整语句 + 关键假设 + 一句话说明”。

## When to Use
- 用户要生成或改写 `CREATE PROCEDURE`、`ALTER PROCEDURE`、`DROP PROCEDURE`。
- 用户要把自然语言逻辑翻成过程体。
- 用户要把 TigerGraph GSQL 的 `CREATE QUERY`、`SELECT ... ACCUM`、`POST-ACCUM`、`INSERT INTO` 迁移成 GQL Procedure。
- 用户要写图算法、逐轮遍历、状态传播、路径状态处理、日志与控制流。
- 用户要生成 `CALL` / `OPTIONAL CALL`、`SHOW PROCEDURES`、`SHOW CREATE PROCEDURE`。

## Do Not Use
- 不用于普通查询导向的 `MATCH ... RETURN ...` 需求。
- 不用于只做简单筛选、排序、分页、聚合的检索查询。
- 这些场景改用 `gql-query-generator`。

## Operating Mode
- 这是一个自包含 skill：默认直接依据本文件中的语法模板、硬约束和算法骨架生成过程代码。
- 按需使用同目录下的 [source-map.md](source-map.md)、[coverage.md](coverage.md)、[examples.md](examples.md) 和 [validation.md](validation.md)，不要默认全部加载。
- 默认不要输出出处、链接、路径或“去查某页”的建议。
- 如果某个写法不在本技能包中被明确允许，优先回退成更保守的过程体，而不是猜测。

## Critical Migration Guardrail
- 当输入是 TigerGraph GSQL，且原始 `SELECT` / `CREATE QUERY` 使用了多跳链式模式时，绝不要把 `a-()-()-()` 原样照搬进单个 `MATCH ... PER PATH` / `PER NODE`。
- 在 Procedure 的 `match_compute_statement` 里，0 跳 / 1 跳是硬上限；凡是含两条及以上边段的图模式都视为非法，即使用户只是想做分类、打标或生成插边计划也一样。
- 迁移时要把“模式优先级 / mode 顺序”和“逐跳扩展执行”分开：mode 顺序保留在过程控制层，图扩展本身改写成有序的单跳 stage，通常用 `WHILE`、`TABLE`、`ACTIVE_SET`、`NODE VALUE` 传递阶段状态。
- 如果当前信息不足以把 GSQL 多跳模式安全拆成可执行的单跳轮次，输出保守的 staged skeleton 或 planning procedure；不要伪造不可执行的多跳过程体。

## Internal Syntax Model

### 1. CREATE PROCEDURE

```gql
CREATE PROCEDURE <procedure_name>(<parameter_name> <parameter_type> [DEFAULT <default_value>], ...)
[RETURNS () | RETURNS <return_name> <return_type> | RETURNS (<return_name> <return_type>, ...)]
[COMMENT <comment_string>]
AS {
  <procedure_body>
}
```

可选变体：

```gql
CREATE PROCEDURE IF NOT EXISTS ...
CREATE OR REPLACE PROCEDURE ...
```

规则：
- `CREATE OR REPLACE PROCEDURE` 可替换已有定义，但不要借它修改名称、输入参数、输出参数。
- `procedure_name`、各输入参数名、各输出参数名都必须是标识符；同一个过程内入参名彼此唯一，出参名彼此唯一。
- 带默认值的参数必须从右向左连续出现。
- 参数默认值必须是常量，不要把变量表达式、子查询或运行时表达式塞进 `DEFAULT`。
- `RETURNS` 中声明的输出字段数量必须与 `procedure_body` 实际返回字段数量一致。
- `return_type` 必须落在文档定义的数据类型上；若使用 `LIST<T>`，`T` 只允许预定义数据类型或其它列表。不要生成 `RETURNS ret LIST<RECORD>`、`RETURNS (rows LIST<RECORD>)` 这类 procedure 返回类型。
- `TopKAgg` 的内部结果虽然是 `LIST<RECORD>`，但这不代表 procedure 出参可以直接声明成 `LIST<RECORD>`；如果用户要输出 top-k 记录，改成常规多列返回或其它受支持的扁平结果形态。
- `COMMENT` 后必须是字符串字面量。
- 支持重载；若用户明确是在可能重载的上下文中定位过程，生成或删除时应靠名称加参数签名唯一化。
- 若用户同时提到插件加载的同名 UDP 和当前 Schema 中的同名 UDP，要知道调用时插件定义的 UDP 优先。
- 无返回值过程可写成 `RETURNS ()`，也可省略 `RETURNS` 并以 `FINISH` 结束过程体。
- 过程定义体内部必须直接是 `procedure_body`，不要包 `USE graph`、`USE #graph` 或 `USE ... { ... }` 外壳。

### 2. ALTER PROCEDURE

```gql
ALTER PROCEDURE <procedure_name>(<parameter_type_or_declaration>, ...)
COMMENT <new_comment_string>
```

```gql
ALTER PROCEDURE <procedure_name>(<parameter_type_or_declaration>, ...)
RENAME TO <new_procedure_name>
```

规则：
- `ALTER PROCEDURE` 只用于改描述或改名称。
- 如果用户要改过程体，用 `CREATE OR REPLACE PROCEDURE`。
- 如果用户要改入参签名，先 `DROP PROCEDURE` 再重新 `CREATE PROCEDURE`。

### 3. DROP PROCEDURE

```gql
DROP PROCEDURE [IF EXISTS] <procedure_name>
DROP PROCEDURE [IF EXISTS] <procedure_name>(<parameter_type_or_declaration>, ...)
```

规则：
- 可能存在重载时，优先带参数类型签名删除。

### 4. CALL named procedure

```gql
CALL <procedure_name>(<argument_list>) [YIELD <yield_items>]
RETURN <return_items>
```

```gql
OPTIONAL CALL <procedure_name>(<argument_list>) [YIELD <yield_items>]
RETURN <return_items>
```

规则：
- `CALL` 后必须继续结果语句，默认补成 `RETURN ...`。
- 需要只取部分输出列时用 `YIELD`。

### 5. CALL inline procedure

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

规则：
- 适用于一次性的查询组合或局部逻辑封装。
- 不替代命名 UDP 定义。

### 6. SHOW commands

```gql
SHOW PROCEDURES
SHOW PROCEDURE <procedure_name>
SHOW CREATE PROCEDURE <procedure_name>
```

规则：
- 用户要查看签名、返回列、注释时优先用 `SHOW PROCEDURES` / `SHOW PROCEDURE`。
- 用户要反查创建语句时用 `SHOW CREATE PROCEDURE`。

## Procedure Body Model
- 过程体默认由变量声明、变量操作、控制流、匹配计算、日志、返回或结束语句组成。
- 过程体里能解决的问题，优先在过程体内闭环，不拆成查询 skill 的普通 DQL 版本。
- 过程输出要和 `RETURNS` 声明保持列数、列名、类型语义一致。
- 如果中间状态是 `TopKAgg` 或其它记录集合，不要把它直接暴露成 `LIST<RECORD>` 返回列；优先改写成稳定的多列结果，或继续保留为过程内状态。
- 过程体或任意 sub procedure 都应先连续放置该作用域内要用到的变量定义，再开始后续 `statement_block`；不要在执行了若干语句之后再插入新的变量定义。
- 如果某个值只能在后续步骤计算出来，优先“前置声明变量 + 后续 `SET` 赋值”，不要把 `VALUE x = ...` 放到过程体后半段临时声明。
- 过程体的保守骨架是：

```gql
(variable_definition+)? statement_block+
```

- `statement_block` 是一条或多条按顺序执行的语句块；多个可独立执行的语句通过 `NEXT` 连接。
- 只有最后一个语句块的输出会作为过程体结果返回。
- 只有过程体最后一条语句可以直接以 `RETURN` 结束。
- 非最后一条语句只有在结果会通过 `NEXT` 被后续语句使用时，才允许出现 `RETURN`。
- 若要提前终止且不返回结果，可使用 `FINISH`。
- 点绑定聚合值变量和活动集变量只应作用于过程调用的单个临时图。
- 内联过程的过程体中不要生成 DDL 或 DML 语句。
- 在普通过程的单个 `statement_block` 中，DDL 最多一条且必须独占整个语句块；DML 最多一条且必须是该语句块最后一条语句。

## Match Compute Model

### 1. Canonical syntax

```gql
MATCH <graph_pattern>
PER PATH {
  <procedure_body>
}
[PER NODE (<node_variable>) {
  <procedure_body>
}]...
[FINALLY { SET <active_set_variable> = <node_variable> | SET <active_set_variable> |= <node_variable> ... }]
```

或 0 跳图模式下的保守骨架：

```gql
MATCH <graph_pattern>
PER NODE (<node_variable>) {
  <procedure_body>
}
[FINALLY { SET <active_set_variable> = <node_variable> | SET <active_set_variable> |= <node_variable> ... }]
```

### 2. Hard facts
- `match_compute_statement` 仅支持 0 跳和 1 跳图模式。
- 不支持依赖多跳图模式来完成算法主循环。
- 这里的 1 跳是指单个边段图模式，例如 `(a)-[e]->(b)`；只要链上出现两条及以上边段，就属于不支持的多跳写法。
- 如果源语言是 TigerGraph GSQL 或其它链式图模式语言，不要把原始 `s-()-()-()` 链直接照搬到 `MATCH ... PER PATH` / `PER NODE`。
- `PER PATH` 不能和 0 跳图模式一起使用。
- Canonical syntax 中的分支关系是语义分组，不要把外层圆括号 `(` `)` 当作最终语句的一部分输出。
- 不要生成 `MATCH ... ( PER NODE ... FINALLY ... )`、`MATCH ... ( PER PATH ... )` 这类把 `PER NODE` / `PER PATH` / `FINALLY` 包进外层圆括号的写法。
- `FINALLY` 用于更新活动集，更新方式只有 `=` 和 `|=`。
- 活动集变量声明形式是：

```gql
VALUE <active_set_variable> ACTIVE_SET
```

### 3. Active set restrictions
- 在单个图模式里，只允许一个活动集变量约束一个点变量。
- 不要生成对同一点变量施加多个活动集约束的写法。
- 不要生成同时对两个点变量施加活动集约束的同一图模式写法。
- `ACTIVE_SET` 只适用于临时图；在普通图上不要声明或更新活动集变量。
- `ACTIVE_SET` 不能直接通过 `RETURN` 返回，必须结合 `MATCH COMPUTE` 中的 `WHERE n IN active_set` 一类约束来消费。
- `ACTIVE_SET` 的更新只放在 `FINALLY` 中完成，不要在 `PER PATH` / `PER NODE` 主体里直接写活动集更新。
- 不要把 `ACTIVE_SET` 当普通值变量使用；它不能作为通用 `value_expression` 被复制、暂存、比较，或通过绑定变量表达式在过程体外流转。
- 不要生成 `SET a = active_set`、`SET active_set = other_var`、`SET active_set = active_set2` 这类过程体外赋值；对 `ACTIVE_SET` 的合法更新默认只保留在 `FINALLY` 中。
- 若用户明确给的是一组具体元素 ID 作为初始 frontier，可保守生成 `SET active_set = [<element_id>, ...]` 这类初始化；这属于显式种子装载，不等同于通用变量搬运。
- `FINALLY { SET active_set = d }` 表示覆盖更新，用新点集合替换旧活动集。
- `FINALLY { SET active_set |= d }` 表示增量更新，把新点集合并入旧活动集。

## Variable and Mutation Rules

### 1. Non-aggregate variables
- 在 `match_compute_statement` 外部定义的非聚合值变量，不能在 `PER PATH` / `PER NODE` 内部做 `=` 或 `+=` 更新。
- 全局变量必须在过程体顶层声明，不能在任何嵌套块内部新声明。
- 全局变量声明应集中放在 procedure 开头；同一个 procedure 中，不要在若干 `MATCH`、`IF`、`WHILE`、`FOR` 或 `RETURN ... NEXT ...` 之后再回头声明新的全局变量。
- 局部 sub procedure 或局部块若确实需要局部变量，也应先在该 sub procedure / 块的起始位置完成声明，再进入后续语句；不要把局部变量声明散落在块中间。
- 原始值变量通过 `VALUE` 声明，保守写法包括：

```gql
VALUE name TYPE = <value_expression>
VALUE name = <value_expression>
```

- 文档也允许 `VALUE name :: TYPE = ...` 与 `VALUE name TYPED TYPE = ...`；默认优先更简洁的一般写法，只在用户明确要求时再保留 `::` 或 `TYPED` 变体。
- 原始值变量可显式类型，也可让类型从右值推断。
- 支持的高价值类型覆盖数值、字符串、布尔、日期时间、列表、记录与向量；若用户明确需要精确定点数或向量，可保守生成 `DECIMAL(p, s)`、`LIST<...>`、`VECTOR<dimension, element_type>` 一类类型。
- 原始值变量必须在引用之前定义。
- 若省略初始值，变量默认是 `null`；若需求依赖非空初始状态，不要省略右值。
- 对于后续步骤才可计算出的派生值，优先先声明 `VALUE total TYPE` 一类变量，再在合适的位置用 `SET total = <value_expression>` 赋值。
- 当用户明确要“把一个子查询结果先存起来再复用”时，可考虑值表达式初始化的值变量；如果该写法会让过程体明显更复杂，优先退回更直接的过程步骤。
- 局部值变量可以在 `PER NODE`、`PER PATH`、`IF`、`ELSE`、`WHILE` 等嵌套块内声明和更新；它们适合承载单点、单路径或单轮循环的临时状态。
- 局部值变量的作用域只限当前块及其子块；跨点、跨路径、跨轮次共享状态不要伪装成局部值变量。
- 全局值变量可在局部块内只读引用；如果需求只是把全局常量或阈值带入局部计算，优先“读全局 + 写局部”，不要反向在局部块里回写全局值变量。

### 2. Global aggregate variables
- 全局聚合值变量在 `PER PATH` / `PER NODE` 内只能做 `+=`，不能做 `=`。
- 它们的更新在整个匹配计算语句执行完成后才可见。
- 全局聚合值变量声明时保持普通变量名；但只要进入“使用位置”，一律写成 `@agg_name`，不要裸写聚合变量名。
- “使用位置”包括：`SET @agg_name = ...`、`SET @agg_name += ...`、`SET @agg_name.<member_function>(...)`、`LOG_INFO(@agg_name)`、`RETURN @agg_name`、`EXPORT @agg_name AS ...`、`FOR row IN @map_agg` 等任何把聚合值变量放进表达式或语句的位置。
- 能不放在全局的状态，默认就不要放在全局；全局状态会削弱 `PER NODE` / `PER PATH` 的分布式与流式处理优势，并放大单机或局部内存压力。
- 这条规则不仅是语义偏好，也是执行策略偏好：能随着 `PER NODE` / `PER PATH` 自然分发的状态，应尽量留在节点局部、路径局部、表变量、文件变量或活动集中，让计算更接近数据并减少全局汇聚。
- 只要某个状态能下沉到节点局部、路径局部、表变量、文件变量或活动集，就优先下沉，不要先生成全局聚合器版本。
- 只有在需求本身就是“跨所有点/路径做单个全局汇总”时，才优先使用全局聚合值变量。
- 如果某个聚合状态天然按点隔离、后续会按点读取，或可以通过 `node_var.@agg_name` / `NODE(id_var).@agg_name` 消费，默认优先改写成 `NODE VALUE`，不要先生成全局 `ListAgg` / `SetAgg` / `MapAgg` 再二次分发。
- 如果某个状态天然按路径批次、候选前沿或中间结果表来消费，优先改写成 `TABLE`、`EXPORT INTO <file_variable>` 或其它可流式消费的局部载体，不要先生成全局 `ListAgg<RECORD>` / `ListAgg<LIST<...>>` 再统一回放。

### 3. Node-bound aggregate variables
- `NODE VALUE` 只能声明点绑定聚合值变量，不能声明点绑定普通标量。
- 合法示意：

```gql
NODE VALUE node_sum SumAgg<INT> = 0
```

- 非法示意：

```gql
NODE VALUE seed_id INT
```

- 在 `PER PATH` 中，点绑定聚合值变量只能 `+=`，不能 `=`。
- 在 `PER NODE` 中，点绑定聚合值变量既可 `+=`，也可 `=`。
- `PER PATH` 中的点绑定聚合更新在该路径子句结束后才可见。
- `PER NODE` 中的赋值和聚合更新立即可见。
- 点绑定聚合值变量在任何使用位置都必须写成 `node_var.@agg_name` 或 `NODE(id_expr).@agg_name`；不要写成 `node_var.agg_name`、`NODE(id_expr).agg_name`，也不要把它当普通属性名。
- 这条 `@` 规则同时覆盖读取、赋值、聚合、成员函数调用、日志、返回、导出等所有消费场景；只要在用点绑定聚合值变量，就保留 `.@` 前缀。
- 只要状态可以稳定地挂在节点上，且后续逻辑按节点局部读取、覆盖或累积，默认优先使用 `NODE VALUE`；这通常比把逐点状态先堆进全局聚合器再回查更高效。
- 典型适用场景包括：节点分数、节点访问标记、逐轮传播值、按点累积候选记录、按点维护去重集合。
- 只有当结果语义本身就是全局单值、全局单列表，或必须跨点整体排序/整体合并后再消费时，再回退到全局聚合值变量。

### 4. Type discipline
- 聚合值变量的声明类型、操作符和右值/消费位置类型必须匹配。
- 聚合值变量定义时，不要默认补 `= <value_expression>`。只有声明语法明确要求初始值的聚合器，才在声明时写初始化右值。
- 当前必须声明时初始化的稳定聚合器是：`SumAgg<T>`、`MinAgg<T>`、`MaxAgg<T>`、`AndAgg`、`OrAgg`。
- 当前声明时不要初始化的稳定聚合器是：`AvgAgg<T>`、`ListAgg<T>`、`SetAgg<T>`、`MapAgg<K, V>`、`TopKAgg<K, SortFields>`。
- 文档语法图中常用 `INT` 表示整型输入；若当前上下文已经明确使用 `INT64` 等整型别名，可沿用同类整型，但不要把这条放宽成列表、记录、向量、地理空间、`MAP` 或聚合器类型。
- 聚合器类型参数必须按文档白名单收紧，不要“看起来像能装进去”就继续嵌套：
  - 数值聚合器 `SumAgg<T>`、`AvgAgg<T>`、`MinAgg<T>`、`MaxAgg<T>` 的 `T` 只允许数值类型，即整型族或 `DOUBLE`；不要生成 `STRING`、`BOOLEAN`、`LIST`、`RECORD`、`VECTOR`、地理空间或其它聚合器作为其输入类型。
  - 布尔聚合器 `AndAgg`、`OrAgg` 只接受 `BOOLEAN` 输入，且本身不带类型参数。
  - `ListAgg<T>` 的 `T` 只允许文档明确的值载荷类型：稳定标量、`LIST<data_type>` 或 `RECORD{...}`；不要把另一个聚合器、`ACTIVE_SET`、表变量、图变量、文件变量或匿名未确认对象当作 `T`。
  - `SetAgg<T>` 的 `T` 只允许去重键型标量：整型族、`DOUBLE`、`STRING`；不要生成 `BOOLEAN`、`LIST`、`RECORD`、`VECTOR`、地理空间或任意聚合器元素类型。
  - `MapAgg<K, V>` 的 `K` 只允许键型标量：整型族、`DOUBLE`、`STRING`；`V` 只允许显式白名单里的嵌套聚合器：`SumAgg<T>`、`AvgAgg<T>`、`MaxAgg<T>`、`MinAgg<T>`、`AndAgg`、`OrAgg`、`ListAgg<T>`、`SetAgg<T>`、`TopKAgg<K, SortFields>`。
  - `MapAgg` 的 value 白名单里没有 `MapAgg` 自身，因此不要生成递归 map 聚合链；`MapAgg<INT64,MapAgg<INT64,SumAgg<DOUBLE>>>`、`MapAgg<STRING,MapAgg<INT,SetAgg<STRING>>>` 这类声明都视为不支持。
  - 当 `MapAgg` 嵌套 `ListAgg<T>`、`SetAgg<T>` 或 `TopKAgg<...>` 时，内层类型参数仍必须继续满足各自的限制；不要因为外层是 `MapAgg` 就放宽内层类型约束。
- 如果用户想要多层 map、map of map、set of record、sum of string 之类文档未列出的类型，优先改写为更保守的 `TABLE`、多个标量聚合器或扁平化后的 `MapAgg<K, supported_agg>`。
- 默认不要为了“看起来更安全”而滥加 `CAST`；若源值与目标类型本来一致，或文档已明确该场景支持隐式转换，就优先保持更直接的写法。
- 只有在以下情况才显式写 `CAST(<expr> AS <target_type>)`：
  - 用户明确要求强制类型转换或固定目标类型。
  - 文档不支持相应隐式转换，或该隐式转换很可能报错。
  - 需要把结果稳定到特定类型后再参与后续计算、返回、导出或比较。
- 仓库文档已明确会尝试隐式转换的典型场景包括：函数入参、列表表达式、条件表达式分支、联合运算符、`INSERT`/`SET` 中与图属性类型对齐、`CALL` 过程入参与参数签名对齐。对这些场景，不要默认多包一层 `CAST`。
- 这条规则同时适用于全局聚合值变量和 `NODE VALUE`。例如，`SET s.@out_edge += 1`、`SET @test_or += false` 这类已被 feature 验证的直写场景，不要强行改成 `CAST`；而 `VALUE similarity = CAST(t.@intersection AS DOUBLE) / union_size` 这类为了稳定后续数值计算结果的写法是合理的。
- 当聚合值变量被赋给普通值变量、返回列、表列、导出列、日志函数参数或另一个聚合器时，先判断文档是否已支持隐式转换；只有在不支持或用户明确要求固定目标类型时，才写 `CAST(@agg_name AS TARGET_TYPE)` 或 `CAST(node.@agg_name AS TARGET_TYPE)`。
- `ListAgg<T>`、`SetAgg<T>`、`MapAgg<K, V>` 的元素类型不要凭空扩展到未确认的匿名复杂结构。
- 如果复杂返回结构不稳妥，优先退回多个标量返回列。
- 聚合器选型可按需求粗分：
  - 数值累计/均值/极值：`SumAgg`, `AvgAgg`, `MaxAgg`, `MinAgg`
  - 布尔汇总：`AndAgg`, `OrAgg`
  - 保序收集：`ListAgg`
  - 去重收集：`SetAgg`
  - 键值聚合：`MapAgg`
  - 前 K 保留：`TopKAgg`
- 如果用户只说“收集全部结果”，优先 `ListAgg`；明确要求去重时再选 `SetAgg`。
- 如果用户要按 key 维护累积状态，优先考虑 `MapAgg`，但不要在没有稳定 key/value 结构时强行生成它。
- `SumAgg<T>`、`MinAgg<T>`、`MaxAgg<T>` 声明时必须指定初始值；若用户没给稳定初值，不要擅自猜一个看似合理的数字。
- `AvgAgg<T>` 声明时无须指定初始值，返回类型始终是 `DOUBLE`；不要生成 `VALUE avg AvgAgg<DOUBLE> = 0` 这类声明期初始化。
- `AndAgg` 与 `OrAgg` 的输入类型必须是布尔值；若源值本来就是稳定布尔表达式，直接写入；只有源值不是布尔类型且确实需要强制转成布尔时，才使用 `CAST(<expr> AS BOOLEAN)`。
- `AndAgg` / `OrAgg` 声明时必须指定初始值；它们的返回类型始终是 `BOOLEAN`。
- `AndAgg` / `OrAgg` 本身不带类型参数；`AndAgg<BOOLEAN>`、`OrAgg<BOOLEAN>` 都是错误写法。合法形态是 `VALUE flag OrAgg = false`、`NODE VALUE flag AndAgg = true`。
- `AndAgg` 的稳定初值是 `true`，`OrAgg` 的稳定初值是 `false`；若用户未给出初值，不要替他猜测或省略。
- `AndAgg` / `OrAgg` 既可用 `+=` 聚合布尔值，也可用 `=` 直接覆盖布尔值；若需求是“累计是否还活跃/是否命中”，优先 `+=`。
- `ListAgg<T>` 的高价值特性是保留插入顺序；它适合“完整保序收集”，不适合表达去重语义。
- `ListAgg<T>` 声明时无须指定初始值；不要生成 `VALUE ids ListAgg<INT64> = []` 之类声明期初始化。
- `ListAgg<T>` 的稳定元素形状应收敛在文档明确的载荷类型上：标量、`LIST<data_type>`、`RECORD{...}`。如果用户想收集“聚合器对象”“map 对象”或其它未确认复合结构，优先改写成 `TABLE`、`TopKAgg`、多个标量列或扁平化 `RECORD`。
- `ListAgg<T>` 支持 `=` 右值为 `LIST<T>` 或同类型 `ListAgg<T>`，也支持 `+=` 右值为单个 `T`、`LIST<T>` 或同类型 `ListAgg<T>`；若文档已支持相应隐式转换，就不要默认补 `CAST`；只有需要强制固定元素类型时，再把元素或列表显式 `CAST(...)` 到 `T` 或 `LIST<T>`。
- `ListAgg<LIST<T>>` 是稳定形态，适合路径集合、随机游走轨迹、候选序列批次等嵌套列表状态；不要无端把这类结构降格成字符串拼接或匿名 RECORD 变体。
- `SetAgg<T>` 的元素类型必须收紧为文档白名单里的键型标量：整型族、`DOUBLE`、`STRING`；`SetAgg<BOOLEAN>`、`SetAgg<LIST<INT>>`、`SetAgg<RECORD{...}>`、`SetAgg<MapAgg<...>>` 都不要生成。
- `SetAgg<T>` 虽然返回 `LIST<T>`，但语义是去重集合；不要依赖其返回顺序表达业务含义。
- `SetAgg<T>` 声明时无须指定初始值；不要生成 `VALUE seen SetAgg<STRING> = []` 之类声明期初始化。
- `SetAgg` 变量名的声明标识符本体必须控制在 15 个字符以内；使用时附加的 `@` 前缀与 `node.` / `NODE(id_expr).` 访问前缀不计入长度。当前实现中，超过这个上限容易触发 bug，因此默认优先生成短名，如 `seen`、`seen_ids`、`frontier`。
- `SetAgg<T>` 支持 `=` 右值为 `LIST<T>` 或同类型 `SetAgg<T>`，也支持 `+=` 右值为单个 `T`、`LIST<T>` 或同类型 `SetAgg<T>`；若文档已支持相应隐式转换，就不要默认补 `CAST`；只有需要强制固定元素类型时，再显式 `CAST(...)` 到 `T` 或 `LIST<T>`；其合并语义始终保持去重，不要把它当保序列表使用。
- `MapAgg<K, V>` 的 key 类型必须收紧为键型标量：整型族、`DOUBLE`、`STRING`；不要把 `BOOLEAN`、`LIST`、`RECORD`、`VECTOR`、地理空间或其它聚合器写成 key。
- `MapAgg<K, V>` 声明时无须指定初始值；不要生成 `VALUE buckets MapAgg<INT, SumAgg<INT>> = []`、`= {}` 或其它声明期初始化。
- `MapAgg<K, V>` 的稳定输入应是 `TUPLE(key, value)`、等价的 `RECORD{_0: key, _1: value}`，或由这些键值对组成的 `LIST[...]`；若 key 或 value 已可按文档规则隐式转换，就不要默认补 `CAST`；只有需要强制固定键值类型时，再对字段显式 `CAST(...)` 后构造输入；若用户没有明确稳定 key/value 形状，不要生成 `MapAgg`。
- 对同声明类型的 `MapAgg<K, V>` 变量，可做赋值或聚合；不同声明类型之间不要互相赋值或聚合。
- `MapAgg` 的 value 类型必须落在文档显式允许的嵌套聚合器白名单内：`SumAgg<T>`、`AvgAgg<T>`、`MaxAgg<T>`、`MinAgg<T>`、`AndAgg`、`OrAgg`、`ListAgg<T>`、`SetAgg<T>`、`TopKAgg<K, SortFields>`；不要把它写成普通标量 map，也不要再嵌套 `MapAgg`。
- `FOR row IN @map_agg` 的稳定消费结果是 `RECORD{_0: key, _1: value}`；若用户要展开 `MapAgg` 内容，默认按 `row._0` / `row._1` 生成。

### 5. TopKAgg
- `TopKAgg<K, SortFields>` 用于维护按指定排序字段保留的前 K 条记录。
- `K` 必须是大于 0 的整数；若用户没有明确的前 K 需求，不要引入 `TopKAgg`。
- `SortFields` 必须显式给出排序字段及其数据类型；支持的稳定排序类型是数值、字符串、布尔、日期时间。
- `TopKAgg` 的输入语义始终是“记录 top-k”，不要把它当标量 top-k。`=` 只接受 `LIST<RECORD>` 或同类型 `TopKAgg`，`+=` 只接受 `RECORD` 或同类型 `TopKAgg`，输入记录字段必须与声明的排序字段逐一匹配。
- 多个排序字段时按声明顺序依次比较；若前一排序字段相同，再比较后一字段。
- `TopKAgg` 的排序方向应在每个排序字段上显式写出 `ASC` 或 `DESC`；若用户给了多字段前 K 需求，不要省略方向。
- `NULLS FIRST` / `NULLS LAST` 可跟在排序字段后；缺省时，升序默认 `NULLS LAST`，降序默认 `NULLS FIRST`。
- 可声明为全局聚合值变量，也可声明为点绑定聚合值变量。
- 它支持：
  - `=` 右值为 `LIST<RECORD>` 或同类型 `TopKAgg`
  - `+=` 右值为 `RECORD` 或同类型 `TopKAgg`
- `=` 不能直接接单条 `RECORD`；`+=` 不能直接接 `LIST<RECORD>`。输入记录中的字段必须与声明中的排序字段匹配；若字段值按文档可隐式转换，就不要默认补 `CAST`；只有需要强制固定字段类型时，才在 `RECORD` 内对字段显式 `CAST(...)`。
- `TopKAgg` 声明时无须指定初始值；不要生成 `VALUE topk TopKAgg<...> = ...`。其返回类型是排序后截断到前 K 条的 `LIST<RECORD>`。
- 即使 `TopKAgg` 的内部结果是 `LIST<RECORD>`，也不要把 procedure `RETURNS` 写成 `LIST<RECORD>`；若需要对外输出 top-k 结果，改成普通返回列 `(id INT64, score DOUBLE, ...)` 或其它已确认受支持的列类型。
- `SET @topk = []` 是稳定的“用空记录列表替换当前内容”写法，语义上可用于清空；若需求只是清空已有聚合器，优先 `SET @topk.clear()`，若需求是显式用一个记录列表整体替换，再使用 `=`。
- `@topk.min()` / `node.@topk.min()` 返回当前保留的前 K 结果中按其排序规则排在最后的一条 `RECORD`；它更接近“当前 top-k 中最差的一条”，不是普通最小值函数。
- 如果用户明确要“保留前 K 个候选记录”而不是简单数值聚合，可优先考虑 `TopKAgg`。

### 5A. Collection aggregator member functions
- `ListAgg` 与 `SetAgg` 都支持 `size()` 与 `clear()`；只有在用户明确需要容器大小或清空语义时才生成这些成员函数调用。
- `SET @list_agg = []` 也是稳定的清空写法；如果用户想表达“替换成一个新列表”或“用空列表重置”，可以用 `=`，如果只是过程式清空已有容器，优先 `SET @list_agg.clear()`。
- `SetAgg` 还可使用 `contains_key(value)` 做成员检查；这只适合查询集合中是否已有某个值。
- 未初始化或刚清空的 `@list_agg` / `@set_agg` 上，`size()` 稳定返回 `0`；如果需求只是判断容器当前是否为空，优先 `@agg.size()` 而不是编造额外状态位。
- `MapAgg` 还可使用 `@map_agg.get(key)` 与 `@map_agg.contains_key(key)`；前者用于读取某个键对应的聚合值，后者用于判断键是否存在。
- 未初始化或刚清空的 `@map_agg` 上，`size()` 稳定返回 `0`，`contains_key(key)` 稳定返回 `false`；若其 value 聚合器有稳定零值，`@map_agg.get(key)` 可作为保守默认值读取。
- `TopKAgg` 也支持 `size()` 与 `clear()`；分别返回记录数量和清空内容。
- `@topk.min()` / `node.@topk.min()` 返回按其排序规则排在最后一位的那条 `RECORD`；它不是普通数值最小值函数，不要在非 `TopKAgg` 语境里套用。

### 6. Table variable
- 表变量用于以表格形式存储数据，适合批量记录、批量插入输入、中间结果表和 `FOR` 外部展开。
- 保守语法骨架：

```gql
TABLE <table_name> { <field_1>, <field_2>, ... } = (<value_1>, <value_2>, ...), ...
```

或：

```gql
TABLE <table_name> TYPED TABLE { <field_1> <type_1>, ... } = { <field_1>: <value_1>, ... }, ...
```

- 若用户明确要固定字段类型、后续还要多次复用字段，优先 `TYPED TABLE`。
- 若用户只需要一次性小批量行数据，可使用未类型化 `TABLE { field1, field2, ... } = (v1, v2, ...), ...`。
- 表变量初始化右值应是与字段定义对应的常量式或不依赖其它变量的值表达式；不要把依赖运行时行变量的表达式塞进表变量定义。
- 在本技能中，表变量优先用于：
  - 批量输入
  - `FOR` 外部结果展开
  - 过程体外部的结构化中间状态
- 当用户要维护路径前沿、候选记录批次、下一轮待扩展集合或其它天然按批次消费的状态时，表变量通常比全局聚合器更稳妥；它更接近 `PER NODE` / `PER PATH` 的分布式生产与流式消费方式。
- 表变量最稳定的消费方式是 `FOR row IN <table_var>` 后通过 `row.field` 访问列值。
- 当用户要批量 `INSERT`、`SET`、`DELETE` 或导出结构化结果时，表变量是比一组散乱标量更稳定的承载形式。
- 如果中间结果可以边生成边落表或边写文件，就不要先把它们全部攒进全局 `ListAgg` 再统一处理；这类写法更容易造成局部内存压力。
- 对 `PER NODE` / `PER PATH` 中天然逐批产生的结果，优先考虑“边产生边写入表变量或文件变量”的流式路径，而不是先做全局缓存再二次消费。
- 不要把表变量误当作图变量或单个标量返回值；如果用户只要单行单值，优先普通值变量或直接 `RETURN`。

### 6A. Active-set usage details
- 活动集变量的保守声明为：

```gql
VALUE <active_set_name> ACTIVE_SET
```

- 文档还允许 `VALUE <active_set_name> :: ACTIVE_SET` 的等价声明；默认优先更简洁的不带 `::` 形式。
- 在匹配计算中消费活动集时，稳定写法是：

```gql
WHERE <node_variable> IN <active_set_name>
```

- 活动集的稳定更新必须落在 `FINALLY` 中完成；不要把活动集更新扩散到其它不明确的语句形式。
- 不要把活动集当作列表、普通值变量或普通聚合器去做过程体外复制、重置、交换或“下一轮覆盖”；如果需要轮次状态切换，应通过新的 `MATCH COMPUTE ... FINALLY` 重新产生活动集，而不是写 `SET active_set = ...`。

### 7. Graph variable
- 图变量用于存储通过 `MATCH` 检索得到的子图。
- 它适合表达“先截取子图，再对该子图做后续处理”的需求。
- 图变量可在定义时预声明子图包含的点类型和边类型，也可以不预声明类型，直接由 `MATCH` 检索子图。
- 若图变量预声明了点类型或边类型，后续用于填充它的 `MATCH` / `RETURN` 也必须显式出现对应类型，并保持属性/标签语义一致。
- 用于填充图变量的子图结果至少应包含一个点；不要把纯边集合或空图假装写成稳定图变量结果。
- 若用户明确要求携带类型约束的子图容器，可考虑 `GRAPH <name> TYPED GRAPH { ... } = MATCH ...` 一类保守写法；否则优先保持未类型化的简洁形式。
- 由于图变量无法像普通标量那样直接 `RETURN`，在本技能中仅当用户明确要“子图”这个状态载体时才生成。
- 不要把图变量当作普通标量、普通表列或简单属性容器来生成；它的角色是子图状态，而不是单值结果。
- 如果只是普通遍历或算法状态传播，优先仍用 `match_compute_statement`、活动集和聚合器，而不是图变量。

### 8. File variable
- 文件变量用于定义基于文件的数据源或数据目的地，主要服务于导入导出。
- 保守语法骨架：

```gql
FILE <file_var> { <column_name> <value_type>, ... } = DATAFILE { PATH: <file_path>, FORMAT: <CSV|PARQUET|ORC>, ... }
```

- `PATH` 应显式指向受支持的文件地址形式；稳定族包括 `file://...`、`hdfs://...`、`s3://...`、`gs://...`。
- `PATH` 与 `FORMAT` 是必填项；其它文件选项都是按格式选配，不要在没有格式语义的情况下堆砌参数。
- `FILE` 列定义支持的高价值类型包括数值、字符串、布尔、日期时间、列表、向量和地理空间；若导出/导入字段不需要复杂类型，优先保持基础标量类型。
- CSV 相关高价值选项包括 `SKIP_ROWS`、`SKIP_ROWS_AFTER_NAMES`、`DELIMITER`、`QUOTE_CHAR`、`DOUBLE_QUOTE`、`ESCAPE_CHAR`、`NULL_VALUES`、`INCLUDE_COLUMNS`。
- 若用户明确要导出带表头的 CSV，可补 `INCLUDE_HEADER: true`；若未提及文件头行为，不要默认附加导出侧文件格式选项。
- Parquet/ORC 相关高价值选项包括 `BATCH_SIZE`、`WRITE_BATCH_SIZE`、`BUFFER_SIZE`、`BLOCK_SIZE`、`USE_THREADS`；只有当用户明确需要文件性能调优时才生成这些选项。
- 文件变量描述的是文件列结构与文件选项，不应被当作普通过程内状态变量、数值变量或图变量替代物。
- 在本技能中，文件变量不作为默认过程模板的一部分；只有当用户明确要导入/导出过程逻辑时才生成。
- 同一过程内不要为两个文件变量生成同一个 `PATH`；测试表明重复路径定义会报错。
- 如果需求只是在图内继续计算而没有文件边界，不要为了“中转”而引入文件变量。

## Control Flow Rules
- 迭代计算默认用 `WHILE` 驱动。
- `PER PATH` / `PER NODE` 内如果需要循环，只能使用 `WHILE`，不要生成 `FOR`。
- `FOR` 只允许出现在匹配计算外部，并且只用于列表或表结果展开，不用于图遍历。
- `WHILE` 循环内部不要直接 `RETURN` 最终结果；循环体内更新变量、聚合器或活动集，循环结束后再 `RETURN`。
- 控制流保守语法：

```gql
WHILE <boolean_expression> THEN { <procedure_body> }
IF <boolean_expression> THEN { <procedure_body> }
ELSEIF <boolean_expression> THEN { <procedure_body> }
ELSE { <procedure_body> }
BREAK
CONTINUE
```

- `WHILE` 不得返回结果；要把值带出循环，更新外部变量后再 `BREAK` 或在循环后 `RETURN`。
- 若 `IF` 是过程体最后一条语句，其分支可使用 `RETURN`。
- 若 `IF` 不是过程体最后一条语句，其分支不得以 `RETURN` 结束，应改为更新变量。
- `BREAK` 与 `CONTINUE` 只在循环上下文中使用。
- `BREAK` 与 `CONTINUE` 都只生成裸关键字形式；不要编造带标签、带层数或带返回值的变体。
- 对路径包含性检查、环闭合判定、邻居扫描这类“找到即可停止”的局部循环，优先在 `WHILE` 中配合 `BREAK` 提前退出，而不是继续无意义遍历剩余列表元素。

## Variable manipulation and logging rules
- `SET` 支持三类操作：
  - 原始值变量赋值：`SET <primitive_var> = <value_expression>`
  - 全局聚合值变量赋值或聚合：`SET @<aggregator_var> = <value_expression>`、`SET @<aggregator_var> += <value_expression>`
  - 全局聚合值变量成员函数：`SET @<aggregator_var>.<member_function>(<args>)`
- `ACTIVE_SET` 不适用这里的通用赋值规则；除 `FINALLY { SET active_set = ... | |= ... }` 外，不要生成针对 `ACTIVE_SET` 的 `SET` 语句。
- 聚合器成员函数的保守支持范围：
  - `ListAgg`: `size()`, `clear()`
  - `SetAgg`: `size()`, `clear()`, `contains_key()`
  - `MapAgg`: `size()`, `clear()`, `contains_key()`, `get()`
  - `TopKAgg`: `size()`, `clear()`, `min()`
- 凡是全局聚合值变量进入表达式、日志、返回、导出、`FOR`、成员函数或 `SET` 语句，都必须写成 `@agg_name`；不要裸写聚合变量名。
- 点绑定聚合值变量在聚合、赋值、读取、日志、返回和成员函数场景中都通过 `node_var.@agg_name` 或 `NODE(id_var).@agg_name` 引用。
- `NODE(id_var).@agg_name` 适合跨节点更新或回写其它节点上的点绑定聚合状态；只有当 `id_var` 明确是稳定元素 ID 时才生成。
- 如果聚合值变量在 `SET`、`LOG_*`、`RETURN`、`EXPORT`、表写入或其它表达式消费中遇到目标类型约束，先判断文档是否支持该隐式转换；只有不支持、会报错，或用户明确要求固定目标类型时，才显式 `CAST(... AS ...)`。
- 日志语句保守语法：

```gql
LOG_DEBUG(...)
LOG_INFO(...)
LOG_WARN(...)
LOG_ERROR(...)
LOG_FATAL(...)
```

- 日志级别从低到高为 `DEBUG < INFO < WARN < ERROR < FATAL`。
- 默认最小输出级别视为 `INFO`；`LOG_DEBUG` 默认可能不输出。
- `LOG_FATAL` 会终止过程执行，不要在还希望继续返回结果的路径上生成它。
- 单个过程日志大小上限是 64MB；不要在高基数 `PER NODE` / `PER PATH` 中默认大量打印日志。

## Import and export rules
- `IMPORT` 只在用户明确要求向临时图导入数据时生成。
- 保守骨架：

```gql
USE <temporary_graph>
IMPORT INTO GRAPH { ... } [OPTIONS { ... }]
```

- `IMPORT` 的目标必须是临时图，不要把它生成到普通图写入流程里。
- 若从文件导入，稳定来源是 `FROM <file_variable>` 或内联 `DATAFILE { ... }`；若从图库导入，稳定来源是 `FROM NEBULA { PATH: "nebula://...", FORMAT: "NEBULA" }`。
- 从图库导入完整图时，目标临时图的图类型定义必须与源图保持一致。
- 单条 `IMPORT` 语句中不要同时混用 `file_source` 和 `graph_source`。
- 若使用 `FROM <file_variable>`，该文件变量必须先定义好。
- 若用户要导入整个图或图库中的指定点/边，源图与目标临时图不应被写成同一 Graph 服务实例上的复制。
- 若从文件导入，或仅从图库导入指定类型的点/边数据，临时图边类型应满足文档要求的 `MULTIEDGE KEY()` 约束；如果用户未给出这类 schema 前提，不要假装该导入一定可直接运行。
- 若某个目标属性未显式映射源字段，应按图类型中定义的默认值理解；不要擅自补不存在的源列名。
- 当通过 `node_definition` 读取指定点类型时，`PRIMARY KEY(...)` 的列数量和顺序必须与目标点类型定义完全一致；列名可以不同，但结构不能乱。
- 当通过 `edge_definition` 读取指定边类型时，边的起点/终点点类型拓扑必须与目标边定义一一对应；不要只对齐边名而忽略两端点类型。
- 若单条 `IMPORT` 语句里出现多个 `graph_source`，它们的 `nebula_uri_string` 必须完全一致；不要拼装多个不同图源到同一条语句里。
- `nebula://...` 中若显式给出 `schema`，它必须是绝对路径；若省略，则按主 Schema 理解。
- `OPTIONS` 中高价值数据选项包括 `PRIMARY_KEY_AS_NODE_ID`、`SKIP_CONFLICT_PK_NODES`、`SKIP_DANGLING_EDGES`。
- `PRIMARY_KEY_AS_NODE_ID` 只在基于图类型创建的临时图、单列且不超过 4 字节整数主键、并且数据源来自图库之外时才稳定适用；否则不要主动开启。
- 当外部数据存在主键重复点时，只有显式 `SKIP_CONFLICT_PK_NODES: true` 才适合跳过冲突；否则导入会失败。
- 当外部数据存在悬挂边时，只有显式 `SKIP_DANGLING_EDGES: true` 才适合跳过悬挂边；否则导入会失败。
- 若 `IMPORT` 使用 `nebula://...` 图源地址，可附带 TLS 相关参数；高价值参数包括 `tls_enable`、`tls_cert`、`tls_key`、`tls_ca`、`tls_cadir`、`tls_peer_name`、`tls_peer_name_verify`、`tls_passfile`、`tls_ciphers`、`tls_ciphersuites`、`tls_versions`。
- 若源 Graph 服务本身启用了 TLS，`tls_enable` 必须显式为 `true`；不要在 TLS 场景下遗漏它。
- 这些 TLS 参数只在用户明确处于启用 TLS 的图源导入场景时才生成；普通文件导入或未说明安全配置时不要臆造。
- 如果用户没有给出临时图或数据来源变量，不要臆造复杂 `IMPORT` 细节；保留为占位符骨架即可。
- `EXPORT` 用于把结果导出到表或文件，在过程中有四种稳定形态：
  - 顶层直接 `EXPORT ... INTO ...`
  - 顶层 `MATCH ... EXPORT ...`
  - `MATCH COMPUTE` 的 `PER NODE` / `PER PATH` 内部 `EXPORT ...`
  - `TABLE ... EXPORT ...`
- `EXPORT` 的稳定语法是：

```gql
EXPORT <value_expression> [AS <identifier>], ... INTO <table_or_file_variable>
```

- `EXPORT INTO` 的目标变量必须事先定义为表变量或文件变量；不要把普通值变量、图变量或活动集变量当作导出目标。
- 若给导出列起别名，`AS` 后必须是合法标识符；不要把字符串字面量、路径片段或其它表达式伪装成别名。
- 目标表/文件变量的字段数必须与导出的值表达式数量一致。
- 若导出项是代表点或边的变量表达式，对应目标字段类型应为 `STRING`；否则目标字段类型应与导出表达式结果兼容。
- 顶层直接 `EXPORT ... INTO ...` 适合常量结果、单次结构化输出或不依赖图遍历的简单落盘；不要把这种场景强行改写成 `MATCH` 或 `TABLE` 包裹版本。
- 当结果可以在 `PER NODE` / `PER PATH` 中逐批产生时，`EXPORT` 到表或文件通常比先聚合到全局变量再统一返回更稳妥，也更符合分布式与流式处理优势。
- 执行环境限制应保守处理：
  - 普通图上的 Graph 服务：只支持 `MATCH ... EXPORT ...` 或 `TABLE ... EXPORT ...`
  - 单机模式临时图上的 Graph 服务：三种 `EXPORT` 形态都可考虑
  - Analytics 上的分布式模式临时图：只支持 `MATCH COMPUTE ... EXPORT ...` 或 `TABLE ... EXPORT ...`
- 如果用户没有明确导出目标、字段结构或执行环境，不要编造一个看似完整但无法成立的 `EXPORT` 方案。
- 当用户只是要普通返回值，不要把 `RETURN` 擅自改写成 `EXPORT`。

## Algorithm Traversal Rule
- 只要需求属于图算法、遍历、逐轮扩展、状态传播、环检测、按深度推进，就必须用 `match_compute_statement` 作为每轮遍历原语。
- 用户显式指定本 skill 时，任何最终输出都禁止退回到普通 `MATCH` / 普通 `match_statement` 版本。
- 如果需求是多跳算法，要改写成：
  - `WHILE` 驱动轮次
  - 每轮单跳 `match_compute_statement`
  - 用变量、聚合器、活动集在轮次间传递状态
- 如果输入是 TigerGraph GSQL，并且一个 `SELECT` 模式里串了多段边、多个 CN/设备点位或多种设备分支，先把“mode 编号 / 优先级”和“逐跳扩展”拆开；不要生成“一种 mode 对应一个长链 MATCH”的翻译。
- 对 GSQL 中 `ACCUM` / `POST-ACCUM` / `INSERT INTO` 这类副作用，默认在某个 mode 被分阶段确认之后，再写入 `TABLE`、返回列或后续 DML 计划；不要把副作用绑定到非法多跳 `PER PATH` 上。
- 如果精确可执行翻译仍然依赖当前不支持的多跳路径捕获，回退成保守的 staged skeleton / planning procedure，并明确保留 mode 顺序与副作用意图。
- 不要直接臆造多跳 `match_compute_statement`。

## Path State Expansion Rule
- 图遍历由 `match_compute_statement` 完成。
- 路径或列表状态的消费、拆分、拼接，可在匹配计算外部用 `FOR`、列表连接 `||`、列表索引 `[]`。
- `FOR` 不是图遍历原语，不替代每轮 `match_compute_statement`。
- 即使某个状态保存在 `ListAgg<LIST<T>>` 中，也不要在 `PER PATH` / `PER NODE` 内生成 `FOR` 去展开它。
- 对环枚举、路径扩展、候选 frontier 批次这类状态，默认优先表变量或文件变量这类可流式消费的载体，而不是全局聚合器双缓冲。
- 如果用户要表达 `frontier` / `next_frontier` 一类路径批次切换，优先生成 `TABLE`、`EXPORT INTO` 或 `RETURN ... NEXT ...` 风格的中间状态传递；不要默认生成 `SET frontier_paths = next_frontier_paths` 这类全局聚合器整体赋值切换。
- 如果中间状态只是单点、单路径或单轮循环里的临时计数、局部累乘、局部条件分支结果，优先局部 `VALUE` 变量，而不是把这类短生命周期状态升级成全局值变量。
- 如果需求属于随机游走、随机扩展或有界随机探索，可在图模式里保守生成 `SAMPLE RIGHT <count>` 一类单向采样边模式；不要把采样语义退回普通全量扩展。
- 对环检测、路径枚举、序列传播这类算法，若状态天然是“每个节点维护一批路径列表”，可稳定使用 `NODE VALUE <name> ListAgg<LIST<INT64>>` 或同类嵌套列表载体；逐条展开时优先局部 `WHILE + index`，不要在 `PER PATH` / `PER NODE` 内生成 `FOR`。

## Broader Capability Map
- 命名过程定义与元数据修改：`CREATE PROCEDURE`、`ALTER PROCEDURE`、`DROP PROCEDURE`
- 过程调用与查看：`CALL`、`OPTIONAL CALL`、`SHOW PROCEDURES`、`SHOW CREATE PROCEDURE`
- 算法与遍历：`match_compute_statement`、活动集、`WHILE`
- 状态载体：原始值变量、活动集变量、聚合值变量、表变量、图变量、文件变量
- 结果保留：标量返回列、聚合器、必要时 `TopKAgg`
- 日志与控制：日志语句、控制流、变量操作

## Inputs to Infer
先从自然语言中提取：

1. 目标类型
   - 新建过程、修改过程、删除过程、调用过程、查看过程、内联过程
2. 过程职责
   - 检索、更新、日志、算法遍历、结果整形
3. 输入输出
   - 参数、默认值、返回列、返回类型
4. 过程体能力
   - 变量、聚合器、活动集、控制流、日志、是否逐轮迭代
5. 状态载体
  - 普通值变量、全局聚合器、点绑定聚合器、活动集、列表状态
  - 哪些状态能下沉到局部 `VALUE`、`NODE VALUE`、`TABLE`、文件变量或活动集，哪些才必须保留为全局聚合器
6. 缺失信息
   - 过程名、参数名、返回名、标签、边类型、属性、深度变量

## Procedure
1. 先判断用户是在要：`CREATE PROCEDURE`、`ALTER PROCEDURE`、`DROP PROCEDURE`、`CALL`、`SHOW ...`，还是要把自然语言逻辑转成过程体。
2. 如果请求带有算法、遍历、逐层推进，先套用算法规则：后续输出不得退回普通 `MATCH`。
3. 选择外壳：
   - 可复用逻辑优先命名过程。
   - 一次性组合逻辑可用内联过程。
4. 抽取参数、返回、过程步骤、变量需求、日志需求。
5. 先列出当前 procedure 或 sub procedure 需要的变量，并把它们统一放到该作用域的开头；运行过程中才得到的值也先声明，再在后续语句里赋值。
6. 如果是多跳算法，先改写成 `WHILE` + 单轮 `match_compute_statement`；若输入来自 TigerGraph GSQL 的多跳 `SELECT`，先拆成“有序 mode stage + 每 stage 单跳扩展 + 独立副作用落地”。
7. 如果要维护活动集，优先声明 `VALUE <name> ACTIVE_SET`，并在 `FINALLY` 更新。
8. 如果用户想表达“下一轮 frontier / visited 集合”，先判断它是否真的是活动集；若是活动集，默认通过下一轮 `MATCH COMPUTE ... FINALLY` 重新更新；只有用户明确给出元素 ID 种子时，才考虑 `SET active_set = [<id>, ...]` 这类初始化。
9. 如果要按点维护状态，优先使用 `NODE VALUE <name> <AggType> = <init>`。
10. 如果某个聚合状态既能写成全局聚合器，也能自然挂在点上，默认先选 `NODE VALUE`；只有确实需要全局单值/全局单列表时才用全局聚合器。
11. 一旦选择了聚合值变量，后续所有使用位置统一写成 `@agg_name`、`node.@agg_name` 或 `NODE(id_expr).@agg_name`，不要混入裸变量名或普通属性访问。
12. 每次对聚合值变量做赋值、聚合、返回、导出、记录日志或继续参与表达式时，都检查类型是否匹配；若文档已支持该隐式转换，则优先保持简洁；只有隐式转换不支持、会报错，或用户明确要求固定目标类型时，才显式补 `CAST(... AS ...)`。
13. 如果某个状态只服务于单点、单路径或单轮局部计算，优先局部 `VALUE` 变量；不要把短生命周期临时状态抬升成全局值变量。
14. 如果某个状态天然是路径批次、候选记录集或下一轮待扩展集合，优先使用 `TABLE`、文件变量或 `RETURN ... NEXT ...` 做中间状态传递，不要先生成全局聚合器双缓冲。
15. 如果某个结果能在 `PER NODE` / `PER PATH` 中边产生边消费或边落盘，优先保留这种流式路径，不要为了“统一汇总”而过早引入全局缓存。
16. 如果过程需要多阶段汇总或“先分组聚合、再继续结果整形”，显式用 `RETURN ... NEXT ...` 组织语句块。
17. 若缺少命名信息，继续生成草稿，用清晰占位符补齐。
18. 默认输出顺序：
   - 完整过程或调用语句
   - 关键假设
   - 简短说明

## Decision Points
- 如果用户没有说明过程类型，默认优先命名过程。
- 如果用户只是要执行现有过程，生成 `CALL` / `OPTIONAL CALL`，不要扩展成定义。
- 如果用户要改描述或改名，生成 `ALTER PROCEDURE`。
- 如果用户要改过程体，生成 `CREATE OR REPLACE PROCEDURE`。
- 如果用户要改签名，生成“先 `DROP` 再 `CREATE`”方案，而不是伪造 `ALTER` 改签名。
- 如果用户要查看单个过程的信息，优先用 `SHOW PROCEDURE <name>`；如果用户要按名称模式筛一批过程，可用带正则的 `SHOW PROCEDURE "..."`。
- 如果需求是算法遍历，必须使用 `match_compute_statement` 作为遍历骨架。
- 如果用户给的是 TigerGraph GSQL 多跳 `SELECT` / mode 枚举，保留原有 mode 顺序，但每个执行阶段只允许 0/1 跳图模式；不要生成“一种 mode 对应一个长链 MATCH”的翻译。
- 生成 `match_compute_statement` 时，`PER PATH` / `PER NODE` / `FINALLY` 直接跟在 `MATCH <graph_pattern>` 之后，不要额外包一层圆括号。
- 如果需求里既有单轮图扩展又有列表状态展开，先用 `match_compute_statement` 做图扩展，再在外部用 `FOR` 处理列表状态。
- 如果逐点状态既能放进全局聚合器，也能挂到节点上，默认优先 `NODE VALUE`；不要先生成全局聚合器版本。
- 如果后续消费模式是按节点读取或更新局部状态，优先 `NODE VALUE`；如果后续消费模式是一次性全局返回、全局排序或跨点整体合并，再考虑全局聚合器。
- 如果状态只在 `PER NODE` / `PER PATH` 或循环体内部短暂存在，优先局部 `VALUE`，不要提升成全局值变量。
- 如果用户要批量结构化输入或中间表，优先考虑表变量，而不是把所有状态塞进列表。
- 如果中间状态可以随着 `PER NODE` / `PER PATH` 产生而分发、落表或落文件，就不要先堆到全局变量里；优先保留分布式和流式处理路径。
- 如果状态表示的是路径前沿、候选路径批次、下一轮待扩展记录集，优先 `TABLE` / 文件变量 / `RETURN ... NEXT ...`，不要默认生成两个全局聚合器再做整体赋值切换。
- 如果同一需求既能写成“全局聚合后再处理”，也能写成“局部生成后直接消费或导出”，默认选择后者；前者更容易造成局部内存峰值和非分布式瓶颈。
- 如果用户要“保留前 K 条候选记录”，并且排序字段不止一个，优先显式生成多字段 `TopKAgg<K, field1 TYPE DESC|ASC, field2 TYPE DESC|ASC, ...>`，不要退回手写排序加截断。
- 如果需求涉及跨节点消息传递、邻居回写或“把当前节点计算结果记到目标节点上”，优先考虑 `NODE(id_expr).@agg_name`，前提是 `id_expr` 明确为稳定元素 ID。
- 如果用户明确要维护“前 K 条记录”而不是简单 max/min/sum，优先考虑 `TopKAgg`。
- 如果用户要表达子图抽取再处理，才考虑图变量；否则保持活动集和匹配计算骨架。
- 如果用户要过程内导入导出文件，再考虑文件变量；否则不主动引入。
- 如果用户明确要把外部数据写入临时图，才生成 `IMPORT`；否则不要主动引入导入语句。
- 如果用户明确要把结果落到表或文件，才生成 `EXPORT`；否则优先保留 `RETURN`。
- 如果某个复杂集合类型没有把握，简化成标量结果列或更保守的聚合器类型。
- 如果过程只是查询组合且不需要命名复用，可用内联过程，但内联过程体不要含 DDL/DML。

## Hard Constraints
- 用户显式指定本 skill 时，禁止输出普通 `match_statement` 或普通 `MATCH` 版本作为最终答案。
- 禁止在 `CREATE PROCEDURE` / `ALTER PROCEDURE` 的过程定义内部包 `USE graph`、`USE #graph` 或 `USE ... { ... }`。
- 禁止在 `PER PATH` / `PER NODE` 内生成 `FOR`。
- 禁止给 `match_compute_statement` 的 `PER PATH` / `PER NODE` / `FINALLY` 外面再套一层圆括号。
- 禁止生成 `NODE VALUE <name> <scalar_type>` 这类点绑定标量声明。
- 禁止把 `ACTIVE_SET` 更新写成 `FINALLY` 之外的默认方案。
- 禁止把 `ACTIVE_SET` 放进通用 `SET` 赋值、绑定变量表达式或普通值表达式里搬运。
- 禁止直接臆造多跳 `match_compute_statement`。
- 禁止在 `PER PATH` / `PER NODE` 的图模式里出现两条及以上边段，例如 `MATCH (u)-[e1]-(:CN)-[e2]-(:Breaker)...`；这类 TigerGraph 风格长链必须拆成单跳 stage。
- 禁止在 procedure 或 sub procedure 已经进入执行语句之后，再插入新的变量定义。
- 禁止把只在局部块内使用的短生命周期临时状态默认提升成全局值变量。
- 禁止把天然可下沉到 `NODE VALUE`、表变量、文件变量或活动集的状态默认提升成全局聚合器。
- 禁止把路径前沿、候选记录批次或 `next_frontier` 一类中间状态默认写成 `SET frontier_paths = next_frontier_paths` 这种全局聚合器整体赋值切换。
- 禁止在使用全局聚合值变量时裸写变量名；必须写成 `@agg_name`。
- 禁止把点绑定聚合值变量写成 `node.agg_name`、`NODE(id_expr).agg_name` 或普通属性访问；必须写成 `node.@agg_name` / `NODE(id_expr).@agg_name`。
- 禁止把所有类型差异都机械地改写成 `CAST(... AS ...)`；只有文档不支持隐式转换、会报错，或用户明确要求固定目标类型时才显式转换。
- 禁止给 `SumAgg` / `AvgAgg` / `MinAgg` / `MaxAgg` 生成非数值类型参数，如 `SumAgg<STRING>`、`AvgAgg<RECORD{...}>`。
- 禁止生成 `AndAgg<BOOLEAN>`、`OrAgg<BOOLEAN>` 或任何给 `AndAgg` / `OrAgg` 添加类型参数的写法。
- 禁止生成 `SetAgg<BOOLEAN>`、`SetAgg<LIST<...>>`、`SetAgg<RECORD{...}>`、`SetAgg<MapAgg<...>>` 等非键型 `SetAgg`。
- 禁止生成 `MapAgg<K, MapAgg<...>>` 或任何 value 不在文档白名单内的 `MapAgg<K, V>`。
- 禁止把 `TopKAgg` 当作标量聚合器使用，例如 `SET @topk += 1` 或 `TopKAgg<3, score LIST<INT> DESC>`。
- 禁止在多字段 top-k 需求里省略排序方向或排序字段类型，迫使模型靠默认行为猜测。
- 禁止在没有明确需求时主动引入图变量或文件变量，增加无关复杂度。
- 禁止把表变量、图变量、文件变量当作普通标量变量处理。
- 禁止在单条 `IMPORT` 语句里同时混用文件源和图源。
- 禁止在用户未要求导出时把过程结果默认改写成 `EXPORT`。
- 禁止在 `WHILE` 体内直接返回最终结果。
- 禁止在非最后语句块里随意生成 `RETURN`，除非后续确实通过 `NEXT` 消费该结果。
- 禁止在内联过程体中生成 DDL/DML。
- 禁止把 `LOG_FATAL` 放在还要继续执行正常返回的路径上。

## Quality Bar
完成前检查：

- 是否真的输出了过程、调用或 SHOW 语句，而不是只解释概念？
- `CREATE PROCEDURE` 的外壳、参数、返回、过程体是否完整？
- 过程体内部是否避免了 `USE ...` 外壳？
- 如果是算法/遍历场景，是否完全避免了普通 `MATCH` 版本？
- 多跳算法是否已改写为 `WHILE` + 单轮 `match_compute_statement`？
- `match_compute_statement` 是否没有把 `PER PATH` / `PER NODE` / `FINALLY` 包进额外的外层圆括号？
- procedure 或 sub procedure 的变量定义是否都集中在该作用域开头，而不是散落在后续语句之间？
- 过程体中 `RETURN` 的位置是否合法，是否只有最后语句块直接产出最终结果？
- 对于后算出的派生值，是否采用了“前置声明 + 后续 `SET`”而不是在过程体后半段新写 `VALUE ... = ...`？
- `NODE VALUE` 是否全部是点绑定聚合值变量？
- 如果存在临时局部状态，是否优先使用了局部 `VALUE`，而不是不必要的全局值变量？
- 如果存在逐点状态，是否优先使用了 `NODE VALUE`，而不是默认退回全局聚合器？
- 如果使用了全局聚合器，是否确实因为需要全局单值、全局列表、全局排序或跨点整体合并？
- 所有全局聚合值变量在使用位置是否都写成了 `@agg_name`？
- 所有点绑定聚合值变量在使用位置是否都写成了 `node.@agg_name` 或 `NODE(id_expr).@agg_name`？
- 如果存在类型差异，是否先判断过文档是否支持该隐式转换，而不是机械地一律补 `CAST(... AS ...)`？
- 只有在隐式转换不支持、会报错，或用户明确要求固定目标类型时，才显式补上了 `CAST(... AS ...)`？
- 如果用了 `SumAgg` / `AvgAgg` / `MinAgg` / `MaxAgg`，是否确认类型参数只落在数值类型上？
- 如果用了 `AndAgg` / `OrAgg`，是否确认其声明没有附带类型参数，例如没有生成 `OrAgg<BOOLEAN>`？
- 如果用了 `ListAgg`，是否确认元素类型只落在稳定标量、`LIST<data_type>` 或 `RECORD{...}` 上，而不是再塞入聚合器或未确认复杂对象？
- 如果用了 `SetAgg`，是否确认元素类型只落在整型族、`DOUBLE`、`STRING` 这类键型标量上？
- 如果用了 `MapAgg`，是否确认 key 只落在整型族、`DOUBLE`、`STRING` 上，且 value 只落在显式白名单聚合器上，没有再嵌套 `MapAgg`？
- 是否把能下沉到节点局部、路径局部、表变量、文件变量或活动集的状态尽量留在局部，而不是过早提升到全局？
- 如果存在路径前沿、候选批次或下一轮待扩展集合，是否优先采用 `TABLE` / 文件变量 / `RETURN ... NEXT ...`，而不是全局聚合器双缓冲？
- 是否保留了 `PER NODE` / `PER PATH` 的分布式与流式处理优势，而不是为了统一汇总把大量中间状态提前收敛到全局变量？
- 如果用了 `TopKAgg`，是否显式写清了每个排序字段的类型与方向，并确认 `min()` 被理解为“当前 top-k 中最差的一条”？
- 如果用了 `TopKAgg`，右值是否严格落在 `RECORD` / `LIST<RECORD>` / 同类型 `TopKAgg` 上，而不是标量或其它容器？
- 如果过程有 `RETURNS`，是否确认没有把任一返回列声明成 `LIST<RECORD>`，也没有把 `TopKAgg` 的内部结果直接外露为 procedure 返回类型？
- 如果用了跨节点更新，`NODE(id_expr).@agg_name` 中的 `id_expr` 是否真的是稳定元素 ID？
- `PER PATH` / `PER NODE` 内是否没有 `FOR`？
- `ACTIVE_SET` 更新是否放在 `FINALLY`？
- 如果用了活动集，消费方式是否稳定为 `WHERE n IN active_set` 一类写法？
- 是否避免了把 `ACTIVE_SET` 写进过程体外的 `SET ... = ...`、普通表达式或绑定变量引用？
- 返回列和 `RETURNS` 是否一致？
- 如果用了 `SET` 成员函数，成员函数是否属于该聚合器类型的已知支持范围？
- 如果用了日志，是否避免了高基数默认刷日志，且 `LOG_FATAL` 只出现在确实要终止的分支？
- 如果用了表变量，它是否只承担表格数据或批量输入职责？
- 如果用了图变量，它是否真的是子图状态，而不是可由普通变量替代？
- 如果用了文件变量，是否确实存在导入导出需求？
- 如果用了 `IMPORT`，是否明确作用于临时图且没有混用图源/文件源？
- 如果用了 `EXPORT`，是否真的是用户要求把结果导出，而不是普通返回？
- 如果用了 `TopKAgg`，右值类型和操作符是否与其输入规则一致？
- 所有占位符和假设是否都写明了？

## Output Preferences
- 先输出完整语句，再输出说明。
- 默认中文说明，关键字保留 GQL 原文。
- 信息不足时继续给草稿，不先停下来追问。
- 除非用户要求，否则不要把回答写成文档导航。

## Example Requests
- “帮我生成一个命名过程：输入用户 ID，返回该用户最近 10 条交互记录。”
- “把这个自然语言流程转成 GQL Procedure：先查用户，再按状态分支记录日志并返回结果。”
- “生成一个 `CREATE PROCEDURE` 和对应 `CALL` 示例。”
- “生成一个 cycle detection 算法，入参为深度，出参为所有路径。”
