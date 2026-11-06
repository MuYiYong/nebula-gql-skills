# Regular expressions

正则表达式使用 `regexp_like(str: STRING, pattern: STRING [, options: STRING]) -> BOOLEAN`，Database 和 Analytics 均有文档支持。5.3 GQL 不使用 Cypher/nGQL 的 `=~` 运算符；过程中的条件也遵循同一规则。

**匹配语义与函数选型**

- `regexp_like()` 匹配整个字符串，不是搜索任意子串。`regexp_like('hello, world', 'hello')` 为 `false`，`regexp_like('hello, world', '.*hello.*')` 为 `true`。
- 原有 `=~` 迁移时保留 pattern 的锚点、量词、字符类、分组和大小写处理；不要自动补删 `.*`、`^` 或 `$`。只有需求明确为子串正则搜索时才构造相应的 `.*` 模式；包含换行时还要核对选项。
- 纯字面量包含可以用 `contains(str, literal)`；`LIKE` 的 `%`、`_` 是通配符，不能用它直接替换正则。正则中的 `_` 是普通字符，`.` 才是任意字符。
- `str` 和 `pattern` 都可以是返回 STRING 的表达式或参数。默认 NULL 传播：`regexp_like(NULL, '.*')` 和它的 `NOT` 结果均为 NULL。不要为迁移擅自补 `COALESCE(..., false)`。

**迁移与属性路径**

源方言示例（不要生成）：

```cypher
lower(n.job_name) =~ '.+\\.[psv]_.+'
```

已知 `Job` 直接具有 `job_name STRING` 属性时，目标 GQL 为：

```gql
MATCH (n:`Job`)
WHERE regexp_like(lower(n.job_name), '.+\\.[psv]_.+')
RETURN n.job_name AS job_name
```

这保留了小写转换、至少一个字符的前后缀、字面点号、`p/s/v` 字符类和下划线。否定条件写为 `NOT regexp_like(value, pattern)`，保留原来的 `AND`/`OR` 括号与作用域。

正则改写只改变运算符及函数调用，不授权改写 schema。`n.job.job_name` 是否应变成 `n.job_name` 取决于实际属性/记录结构；不要在没有 schema 证据时删除中间层。3.x 的标签属性路径另按迁移规则核实。

**大小写、换行和 options**

| 选项 | 5.3 行为 |
| --- | --- |
| 省略或 `''` | 默认区分大小写，`.` 不跨换行 |
| `'i'` | 不区分大小写 |
| `'c'` | 区分大小写 |
| `'n'` 或 `'m'` | 两者同义，允许 `.` 匹配换行；不能套用其他引擎对 `m` 的解释 |

```gql
RETURN regexp_like('HELLO', 'hello', 'i') AS insensitive,
       regexp_like('a\nb', 'a.b', 'n') AS across_newline
```

选项可组合，例如 `'im'`。不要为迁移悄悄加入大小写不敏感选项，也不要把已有 `lower(value)` 的逻辑任意改成 `'i'`。文档说明其他选项字符会被忽略；不要把 `'g'` 等字符解释成全局搜索。遇到冲突选项或源引擎专属语法时先核对目标行为。

**两层转义与参数**

先区分正则引擎收到的 pattern 和 GQL 源码中的字符串字面量：

| 正则含义 | 引擎收到的 pattern | GQL 字符串源码 |
| --- | --- | --- |
| 任意字符 | `.` | `'.'` |
| 字面点号 | `\.` | `'\\.'` |
| 数字字符类 | `\d+` | `'\\d+'` |
| 字面下划线 | `_` | `'_'` |

代码块给的是可直接使用的 GQL，不要把 JSON/Python 的额外转义层照搬进去。经 JSON/SDK 发送时由对应序列化器处理外层字符串，避免手工重复转义。也不要把字符串中的 `=~`、括号或注释符号误当作代码。

```gql
RETURN regexp_like($text, $pattern, 'i') AS matched
```

`$pattern` 是已解码的 STRING 参数值：匹配字面点号时值包含一个反斜杠和一个点。不要把它写成 `'$pattern'`，也不要再按 GQL 字符串字面量加倍转义。若直接生成字面量，在源码层逐项核对反斜杠和引号。

**错误与验证边界**

- 非法 pattern（如未闭合分组 `(abc`）会报参数错误，不能当作 `false`。保留原始 pattern 与诊断；未经用户授权不要“修复”为另一种匹配条件。
- 静态 lint 会发现代码中的 `=~` 及已知函数签名错误，但不编译正则。实现使用 RE2；Python/Java/PCRE 的编译结果不能证明目标可用。参数化 pattern 也需要运行时验证。
- 最小验证应包括完整匹配、仅子串匹配、大小写、字面点号与任意字符的反例；含换行或 NULL 时加入对应边界。未执行目标数据库时明确标注。

公开依据：5.3.0 `database-gql-reference/fe/functions/string/`、`analytics-gql-reference/fe/functions/string/` 的 `regexp_like()`；整串匹配、选项与非法 pattern 的实现边界见 query 技能随包的 `tests/features/function/String.feature` 的 `Scenario: REGEXP_LIKE`。版本固定源码 `src/function/impl/simple/Re2Functions.h` 使用 `RE2::FullMatch`，`n/m` 设置 `dot_nl`。
