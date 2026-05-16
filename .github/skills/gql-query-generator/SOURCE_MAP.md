# Query Skill Knowledge Map

本文件描述 `gql-query-generator` 的知识版图与文件组织。

## File Structure

| 文件 | 职责 |
|------|------|
| `SKILL.md` | 主指令文件（<300 行），查询骨架、核心子句、流程、约束 |
| `references/expressions.md` | 表达式、谓词、运算符详细规则 |
| `references/patterns.md` | 图模式、路径、量词、过滤放置优先级 |
| `references/functions.md` | 函数家族选择、lambda、legacy 迁移 |
| `references/error-codes.md` | 错误码改写映射与决策树 |
| `references/nearest-neighbor.md` | KNN/ANN 查询模板 |
| `EXAMPLES.md` | 高频正例与边界例 |
| `VALIDATION.md` | 生成前后检查清单 |
| `COVERAGE.md` | 能力覆盖状态表 |

## Core knowledge（SKILL.md 直接包含）
- 查询骨架（MATCH/WHERE/RETURN/ORDER BY/OFFSET/LIMIT）
- 过滤放置三级优先级
- 聚合与 GROUP BY
- CALL（命名 + 内联）与 YIELD
- LET / FOR / FILTER / NEXT
- 复合查询（UNION/EXCEPT/INTERSECT）
- USE 与图变量
- DML（INSERT/SET/DELETE）
- 参数化查询
- 语句块规则
- 路由守卫（何时切到 procedure skill）

## Reference knowledge（按需加载）
- 完整表达式与谓词体系 → `references/expressions.md`
- 完整图模式规则 → `references/patterns.md`
- 函数家族与 legacy 迁移 → `references/functions.md`
- 错误码修复 → `references/error-codes.md`
- 最近邻查询 → `references/nearest-neighbor.md`

## Stability notes
- 参数化查询按 `PARAMETERS $x=...` 与 `$param` 引用的保守子集收敛。
- legacy nGQL 迁移按"业务主键 → `{id: ...}`；图元素身份值 → `element_id(...)`"的保守子集收敛。
- 不支持路径语法：`|+|`、`|`、`?`、`KEEP`、`SHORTEST n GROUPS`、`IS DIRECTED`。
