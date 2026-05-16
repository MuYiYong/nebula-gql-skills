# ISO/IEC 39075:2024 与 nebula-ng 实现差异清单（Query 侧）

更新时间：2026-05-07

## 分析范围与方法
- 标准全文：`/Users/muyi/Documents/Vesoft/05 产品设计/GQL/ISO_IEC_39075_2024(en).pdf`（已全文抽取为 `ISO_IEC_39075_2024_en.txt`）。
- 代码真值源：`/Users/muyi/Documents/Vesoft/workspace/nebula-ng` 的 parser、function registration、tests/features。
- 冲突处理原则：**以代码实现为准**。
- 本文聚焦 `gql-query-generator` 直接相关的查询语法与函数能力。

## 关键标准锚点（已通读定位）
- `<match statement>`（14.4）
- `<call query statement>`（14.5）
- `<filter statement>`（14.6）
- `<let statement>`（14.7）
- `<for statement>`（14.8）
- `<order by and page statement>`（14.9）
- `<return statement>`（14.11）
- `<procedure specification>`（9.1）
- `<inline procedure call>`（15.1）
- `<named procedure call>`（15.2）
- `<element_id function>`（20.10）

## A. 标准定义但当前代码未实现/禁用

| 条目 | 标准侧状态 | nebula-ng 状态 | 证据 |
|---|---|---|---|
| `MATCH ... YIELD` | 标准有对应语法概念 | 当前实现报错 `[42N45]`，不支持 graph pattern 后的 `YIELD` | `src/parser/parser.yy` (`INVALID_SYNTAX_YIELD_CLAUSE_AFTER_GRAPH_PATTERN_NOT_SUPPORTED`), `tests/features/match/MatchYeild.feature` |
| 路径并集/多集合交替（`|` / `|+|`） | 标准有路径组合能力 | 当前实现抛 `UNSUPPORTED_MULTIPLE_PATH_PATTERN` | `src/parser/parser.yy` (`path_pattern_union`, `path_multiset_alternation`) |
| 存疑路径（`?` questioned path） | 标准有对应能力 | 当前实现明确 not supported | `src/parser/parser.yy` (`questioned_path_primary`) |
| `KEEP` 子句 | 标准有对应能力 | 当前实现 not supported | `src/parser/parser.yy` (`keep_clause`) |
| `SHORTEST n GROUPS` | 标准有 counted shortest group 搜索 | 当前实现语法分支直接报 not supported，测试也 skip | `src/parser/parser.yy` (`counted_shortest_group_search`), `tests/features/match/PathPattern.feature` |
| `IS DIRECTED` 相关谓词 | 标准有方向谓词体系 | 词法/语法入口存在，但语义不支持 | `src/parser/scanner.lex`, `src/parser/parser.yy` (`directed_predicate`), `tests/features/unsupported/expr.feature` |
| `NORMALIZE(str, form)` | 标准有规范化形式参数语义 | 当前实现直接 `Not implemented yet` | `src/parser/parser.yy` (`NORMALIZE ... COMMA normal_form`) |

## B. 标准定义且代码实现与常见预期存在差异/仅部分支持

| 条目 | 差异说明 | 证据 |
|---|---|---|
| `NORMALIZE` 整体支持度 | 仅看到单参语法入口；双参禁用；函数注册层未见明确注册项，属于部分支持/高风险能力 | `src/parser/parser.yy`, `src/function/registration/RegisterStringFunctions.cpp` |
| `element_id` 与关键字策略 | 函数 `element_id(...)` 可用；但 `ELEMENT_ID` 关键字在关键词表中被注释，表现为“函数可用但关键字策略非标准化” | `src/function/registration/RegisterGraphFunctions.cpp`, `src/parser/Keywords.h` |
| 量词边界 `{m,}` / `{,n}` | 语法支持开放边界，但特定值语义有限制（如 `{0}` 上界报 `[NS103]`） | `src/parser/parser.yy` (`general_quantifier`), `tests/features/match/Match.feature` |
| `SHORTEST n GROUPS` | 有语法路径，但执行能力未落地（半实现） | `src/parser/parser.yy`, `tests/features/match/PathPattern.feature` |
| 方向谓词族 (`IS DIRECTED`/`IS SOURCE`/`IS DESTINATION`) | lexer/parser 有入口，执行层禁用（半实现） | `src/parser/scanner.lex`, `src/parser/parser.yy`, `tests/features/unsupported/expr.feature` |

## C. 标准定义且当前实现已稳定支持（用于 skill 白名单）

| 条目 | 代码状态 | 证据 |
|---|---|---|
| `FOR ... WITH ORDINALITY` / `WITH OFFSET` | 支持，且序号语义明确（1-based / 0-based） | `src/parser/parser.yy`, `tests/features/for/for.feature` |
| `GROUP BY ()` | 支持 | `src/parser/parser.yy`, `tests/features/return/Return.feature` |
| `ORDER BY` 禁止子查询因子 | 明确限制（`[NS248]`） | `tests/features/order_by_and_page/OrderByAndPage.feature` |
| 参数化查询 (`PARAMETERS` / `$param`) | 支持 | `tests/features/parameter/Parameter.feature` |
| 图元素身份函数 `element_id(...)` | 支持 | `src/function/registration/RegisterGraphFunctions.cpp`, `tests/features/match/Match.feature` |

## 对 skill 优化的直接结论
- `gql-query-generator` 必须继续禁止 `MATCH ... YIELD`，统一改写为 `MATCH ... RETURN ...`。
- `gql-query-generator` 必须继续禁止路径组合高级语法（`|`, `|+|`, `?`, `KEEP`, `SHORTEST n GROUPS`, `IS DIRECTED`）。
- `NORMALIZE` 只能作为“谨慎尝试”的部分能力，不得默认生成；`NORMALIZE(str, form)` 必须禁用。
- 图元素标识必须使用 `element_id(...)`，不得生成 `id()`。

## 后续建议（供下一轮优化）
- 在 `nebula-ng` 增补 `NORMALIZE(str)` 的函数注册与 feature 测试，或在 parser 层完全禁用以消除歧义。
- 若要逐步对齐 ISO 路径高级能力，建议优先实现 `SHORTEST n GROUPS` 或 `IS DIRECTED` 之一，并同步补充错误码与 feature 用例。
