# Server Programming Skill Coverage

本文件说明 `gql-procedure-generator` 对技能包内嵌服务端编程能力的覆盖状态。

状态说明：
- `supported`: 已内置为默认生成能力
- `partial`: 只支持保守子集，或带硬约束生成
- `deferred`: 文档存在，但暂不内置为默认生成能力
- `out-of-scope`: 不属于本技能包职责

## Coverage table

| Topic | Status | Notes |
|---|---|---|
| 服务端编程总览 | supported | 用于任务识别与路由 |
| 过程总览 | supported | 用于区分命名过程与内联过程 |
| `CREATE PROCEDURE` | supported | 支持参数、返回、注释、替换策略 |
| `ALTER PROCEDURE` | supported | 仅支持改名和改注释 |
| `DROP PROCEDURE` | supported | 支持按名称或签名删除 |
| 命名过程调用 | supported | 支持 `CALL` / `OPTIONAL CALL` / `YIELD` / `RETURN` |
| 内联过程调用 | supported | 支持 `CALL { ... }` 和 `OPTIONAL CALL { ... }` |
| `SHOW PROCEDURES` | supported | 支持查看过程信息 |
| `SHOW CREATE PROCEDURE` | supported | 支持反查创建语句 |
| 匹配计算 | supported | 作为算法与遍历的核心遍历原语 |
| 原始值变量 | supported | 支持保守声明与使用 |
| 活动集变量 | supported | 支持 `VALUE <name> ACTIVE_SET` 和 `FINALLY` 更新 |
| 聚合值变量总览 | supported | 用于全局聚合器和点绑定聚合器规则，使用时统一要求 `@`，仅在文档不支持隐式转换或目标类型必须固定时显式 `CAST(... AS ...)`，并按声明语法区分“必须初始化”与“声明时不要初始化” |
| `ListAgg` | partial | 支持文档明确的标量、`LIST<data_type>`、`RECORD{...}` 载荷，不扩展到聚合器对象或未确认复杂结构 |
| `SetAgg` | partial | 只支持键型标量元素：整型族、`DOUBLE`、`STRING` |
| `MapAgg` | partial | 只支持键型标量 key，value 只允许显式白名单聚合器，禁止嵌套 `MapAgg` |
| `SumAgg` | supported | 可直接用于数值累计 |
| `MinAgg` | supported | 支持保守使用 |
| `MaxAgg` | supported | 支持保守使用 |
| `AvgAgg` | partial | 支持基础聚合，不扩展复杂派生模式 |
| `AndAgg` | partial | 支持布尔汇总 |
| `OrAgg` | partial | 支持布尔汇总 |
| `TopKAgg` | partial | 支持记录型 top-k，排序字段类型收紧为数值、字符串、布尔、日期时间 |
| 变量操作 | supported | 支持 `=`、`+=` 等保守子集 |
| 控制流 | supported | 重点内置 `WHILE`、`BREAK`、`CONTINUE` 边界 |
| 日志语句 | supported | 支持过程体中日志输出 |
| 表变量 | partial | 可识别但不作为默认算法主状态 |
| 图变量 | deferred | 暂不纳入默认模板 |
| 文件变量 | deferred | 暂不纳入默认模板 |
| `FOR` | partial | 仅允许匹配计算外部展开列表或表 |

## Completion criteria
- `supported` 项必须在 `SKILL.md` 或 `EXAMPLES.md` 中有明确模板或硬约束。
- `partial` 项必须写清限制条件，避免生成超出边界的代码。
- `deferred` 项默认不生成，后续要扩容时先补示例和验证规则。

## Distribution rule
- 本表仅表达技能包内已压缩的能力，不依赖外部文档。
- 对外分发时，不要求接收方具备源码仓库或站点页面。

## Next expansion candidates
- `TopKAgg` 的稳定模板
- 表变量驱动的后处理模板
- 图变量和文件变量在过程包中的职责边界
- 更细的 `ListAgg` / `TopKAgg` 复杂载荷模板
