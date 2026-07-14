# Documented Syntax Catalog

Generated from NebulaGraph `5.3.0` user documentation by `scripts/refresh_documented_capabilities.py`. Do not edit manually.

This is the complete documented language-page index for `gql-procedure-generator` within the skill's declared scope. A listed capability must not be rejected merely because it lacks a vendored feature or a dedicated example. Apply its documented grammar, environment, prerequisites, and restrictions; feature/code evidence may only narrow a verified implementation boundary.

Search this file by exact keyword, clause, predicate, expression, data type, or documentation key. Pages without a standalone grammar block remain documented capabilities; use their summary and the specialized skill references for constraints.

## Coverage

- Documented pages: `118`
- Extracted syntax blocks: `99`

## control-flow

### 控制流语句

- Documentation key: `analytics-gql-reference/control-flow/`
- Summary: 控制流语句用于控制过程中的语句执行顺序。
- Documented syntax:

```text
while_statement ::=
  'WHILE' value_expression 'THEN' '{' procedure_body '}'

if_statement ::=
  'IF' value_expression 'THEN' '{'  procedure_body '}'
  ( 'ELSEIF' value_expression 'THEN' '{'  procedure_body  '}' )*
  ( 'ELSE' '{'  procedure_body  '}' )?

break_statement ::=
  'BREAK'

continue_statement ::=
  'CONTINUE'
```

### 控制流语句

- Documentation key: `database-gql-reference/control-flow/`
- Summary: 控制流语句用于控制过程中的语句执行顺序。
- Documented syntax:

```text
while_statement ::=
  'WHILE' value_expression 'THEN' '{' procedure_body '}'

if_statement ::=
  'IF' value_expression 'THEN' '{'  procedure_body '}'
  ( 'ELSEIF' value_expression 'THEN' '{'  procedure_body  '}' )*
  ( 'ELSE' '{'  procedure_body  '}' )?

break_statement ::=
  'BREAK'

continue_statement ::=
  'CONTINUE'
```

## data-types

### 数据类型

- Documentation key: `analytics-gql-reference/data-types/`
- Summary: 数据类型是变量的值的类型。在创建图类型时，需要指定每个属性值的数据类型。属性值的数据类型决定了该属性可以存储的值类型。在 GQL 中，数据类型通常也被称为值类型。本文介绍悦数图分析支持的数据类型以及相关约束。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 布尔

- Documentation key: `analytics-gql-reference/data-types/boolean-type/`
- Summary: 布尔类型通过BOOL或BOOLEAN关键字声明，可以设置为以下值：TRUE、FALSE和UNKNOWN。其中，UNKNOWN等同于NULL，表示未知。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 字符串

- Documentation key: `analytics-gql-reference/data-types/c-string-type/`
- Summary: 字符串类型使用STRING关键字声明，用于存储字符序列。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 地理空间

- Documentation key: `analytics-gql-reference/data-types/geo-type/`
- Summary: 地理空间类型是由经度和纬度坐标组成的复合数据类型，用于表示地理空间数据。GQL 支持三种地理空间类型：Point、LineString 和 Polygon。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 列表

- Documentation key: `analytics-gql-reference/data-types/list-type/`
- Summary: 列表类型是一个复合数据类型，可使用关键字LIST<E>或ARRAY<E>声明。其中，E代表列表元素的数据类型。列表元素可以是任意预定义数据类型，也可以是除记录和路径外的复合数据类型。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 映射

- Documentation key: `analytics-gql-reference/data-types/map-type/`
- Summary: 映射类型是一种复合数据类型，用于存储一组无序的键值对。映射中的每个键都是唯一的，并与特定的值相关联。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 数值

- Documentation key: `analytics-gql-reference/data-types/numeric-type/`
- Summary: GQL 支持整数、浮点数和任意精度数。整数可以有符号或无符号，而浮点数和任意精度数都是有符号的。
- Documented syntax:

```text
arbitrary_precision_number ::=
    ( 'DECIMAL' | 'DEC' ) (precision (',' scale)? )?
```

### 记录

- Documentation key: `analytics-gql-reference/data-types/record-type/`
- Summary: 记录类型是一个复合数据类型，可通过构造表达式定义记录类型的值。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 集合

- Documentation key: `analytics-gql-reference/data-types/set-type/`
- Summary: 集合类型是一种复合数据类型，用于存储一组无序且不重复的元素集合。与列表不同，集合中的元素没有索引概念，且自动去重。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 日期和时间

- Documentation key: `analytics-gql-reference/data-types/temporal-type/`
- Summary: 日期和时间类型的值用于存储、操作和检索日期和时间信息。GQL 内置支持日期和时间类型，可以将其存储为点和边上的属性值。本文介绍日期和时间类型及其用法。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 向量

- Documentation key: `analytics-gql-reference/data-types/vector-type/`
- Summary: 向量类型用于描述向量数据，通过指定的维度数和坐标的数据类型来定义。
- Documented syntax:

```text
vector ::=
    'VECTOR' '<' dimension ',' coordinate_type '>'
```

## ddl

### 数据定义概述

- Documentation key: `analytics-gql-reference/ddl/`
- Summary: 数据定义明确了数据库中的数据结构。本文介绍 GQL 支持的用于管理数据结构的数据定义语句（Data Definition Language，简称 DDL）。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### CREATE TEMPORARY GRAPH

- Documentation key: `analytics-gql-reference/ddl/graph-projection/create/`
- Summary: CREATE TEMPORARY GRAPH语句用于在悦数图分析中创建分布式临时图。
- Documented syntax:

```text
create_temporary_graph_statement ::=
  'CREATE' ('TEMPORARY'|'TEMP') 'GRAPH' ('IF NOT EXISTS')? temp_graph_name
  'TYPED' (schema_reference '/')? graph_type_name
  'PARTITION BY' partition_method

partition_method ::=
  'DEFAULT' | 'SRC' | 'DST' | 'HASH_2D' | 'GRID'
```

### CREATE GRAPH TYPE

- Documentation key: `analytics-gql-reference/ddl/graph-type/create/`
- Summary: CREATE GRAPH TYPE语句用于在当前会话中的 Schema 创建图类型。
- Documented syntax:

```text
create_graph_type_statement ::=
    'CREATE' 'PROPERTY'? 'GRAPH TYPE' ('IF NOT EXISTS')? (schema_reference '/')? graph_type_name 'AS'? '{'
        (
          (
            (('NODE' | 'VERTEX') 'TYPE'? node_type_name '(' node_type_filler ')')
            |
            (('EDGE' | 'RELATIONSHIP') 'TYPE'? edge_type_name
                (
                    '(' source_node_type_name ')' '-[' edge_type_filler ']->' '(' destination_node_type_name ')'
                    |
                    '(' destination_node_type_name ')' '<-[' edge_type_filler ']-' '(' source_node_type_name ')'
                    |
                    '(' source_node_type_name ')' '~[' edge_type_filler ']~' '(' destination_node_type_name ')'
                )
            )
          )
          (
            ','
            (
                (('NODE' | 'VERTEX') 'TYPE'? node_type_name '(' node_type_filler ')')
                |
                (('EDGE' | 'RELATIONSHIP') 'TYPE'? edge_type_name
                    (
                        '(' source_node_type_name ')' '-[' edge_type_filler ']->' '(' destination_node_type_name ')'
                        |
                        '(' destination_node_type_name ')' '<-[' edge_type_filler ']-' '(' source_node_type_name ')'
                        |
                        '(' source_node_type_name ')' '~[' edge_type_filler ']~' '(' destination_node_type_name ')'
                    )
                )
            )
          )*
        )?
    '}'

node_type_filler ::=
    ('LABEL' label_name | ( 'LABELS' | ( 'IS' | ':' ) ) label_name ('&' label_name)*)?
   ( ('{'
       (property_name ('::' | 'TYPED')? property_value_type ('NULL' | 'NOT NULL' | 'DEFAULT' value_expression | 'PRIMARY KEY' )*)
       (',' (property_name ('::' | 'TYPED')? property_value_type ('NULL' | 'NOT NULL' | 'DEFAULT' value_expression| 'PRIMARY KEY' )*))*
       (',' primary_key_list)?
    '}')
   )

primary_key_list ::=
    'PRIMARY KEY' '(' property_name (',' property_name)* ')'

edge_type_filler ::=

      ( 'LABEL' label_name | ( 'LABELS' | ( 'IS' | ':' ) ) label_name ('&' label_name)*)?
      ('{'
          (property_name ('::' | 'TYPED')? property_value_type ('NULL' | 'NOT NULL' | 'DEFAULT' value_expression | 'MULTIEDGE KEY' )*)
          (',' (property_name ('::' | 'TYPED')? property_value_type ('NULL' | 'NOT NULL' | 'DEFAULT' value_expression | 'MULTIEDGE KEY')*))*
          (',' multiedge_key_list)?
        '}'
      | '{' ('MULTIEDGE KEY ( )')? '}')

 multiedge_key_list ::=
     'MULTIEDGE KEY' '(' (property_name ( ',' property_name)* )? ')'
```

## dql

### 数据查询概述

- Documentation key: `analytics-gql-reference/dql/`
- Summary: 数据查询语言（Data query language，简称 DQL）用于在查询流程中组织数据读取、筛选、聚合与结果输出。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 使用 CALL 调用内联过程

- Documentation key: `analytics-gql-reference/dql/call/call-inline-procedure/`
- Summary: 在 GQL 中，为了实现更复杂的查询组合和结果处理，可以使用 CALL 语句将一组语句封装成一个语句块，然后对该语句块的结果进行进一步的操作，如排序、限制、聚合等。这种方式类似于在表达式中使用圆括号将子表达式括起来，以确保其结果可以被引用和处理。这种语句块被称为内联过程。本文描述如何使用CALL调用内联过程。
- Documented syntax:

```text
call_inline_procedure_statement ::=
    'OPTIONAL'? 'CALL' '{' procedure_body '}'
```

### 使用 CALL 调用命名过程

- Documentation key: `analytics-gql-reference/dql/call/call-procedure/`
- Summary: 本文介绍如何在悦数图分析中使用CALL语句调用命名过程。
- Documented syntax:

```text
call_procedure_statement ::=
    'OPTIONAL'? 'CALL' procedure_name '(' argument_list? ')' ('YIELD' yield_clause)?
```

### GROUP BY

- Documentation key: `analytics-gql-reference/dql/clauses/group-by/`
- Summary: GROUP BY子句基于指定的列对行进行分组。列的取值相同的行被分为同一组，并对每个组执行聚合计算。
- Documented syntax:

```text
group_by_clause ::=
    'GROUP BY' ( '()' | variable_value_expression ( ',' variable_value_expression )* )
```

### LIMIT

- Documentation key: `analytics-gql-reference/dql/clauses/limit/`
- Summary: LIMIT子句指定返回行数的上限。
- Documented syntax:

```text
limit_clause ::=
    'LIMIT' number_of_rows
```

### OFFSET

- Documentation key: `analytics-gql-reference/dql/clauses/offset/`
- Summary: OFFSET子句在返回结果时跳过一定数量的行。
- Documented syntax:

```text
offset_clause ::=
    ( 'OFFSET' | 'SKIP' ) number_of_rows_to_skip
```

### ORDER BY

- Documentation key: `analytics-gql-reference/dql/clauses/order-by/`
- Summary: ORDER BY子句基于一个或多个列对行进行排序。
- Documented syntax:

```text
order_by_clause ::=
    'ORDER BY' (value_expression ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')?) ( ',' (value_expression ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')?) )*
```

### SAMPLE

- Documentation key: `analytics-gql-reference/dql/clauses/sample/`
- Summary: SAMPLE子句用于在遍历过程中对边采样。在处理超大数据集时，可通过该子句选取较小且易于处理的样本进行分析。取决于遍历的方向，SAMPLE子句可分为两种类型：向右采样（SAMPLE RIGHT）和向左采样（SAMPLE LEFT）。目前仅支持向右采样（SAMPLE RIGHT）。
- Documented syntax:

```text
sample_clause ::=
    'SAMPLE' 'RIGHT'? sampling_method? sample_size

sampling_method ::=
    'FIRST_FETCH' | 'RANDOM' | 'UNIQUE_NEIGHBOR' | 'UNQ_NBR'

sample_size ::=
    unsigned_integer '%'?
```

### USE

- Documentation key: `analytics-gql-reference/dql/clauses/use-graph/`
- Summary: USE子句用于在悦数图分析中声明当前工作图，也就是后续语句所作用的图上下文。
- Documented syntax:

```text
use_graph_clause ::=
    'USE' graph_reference

graph_reference ::=
      temp_graph_name
    | graph_variable
```

### WHERE

- Documentation key: `analytics-gql-reference/dql/clauses/where/`
- Summary: WHERE子句以布尔表达式的形式声明一个或多个过滤条件。该子句通常指定点或边的多个属性值以过滤由前模式匹配子句或语句生成的结果。
- Documented syntax:

```text
where_clause ::=
    'WHERE' value_expression
```

### YIELD

- Documentation key: `analytics-gql-reference/dql/clauses/yield/`
- Summary: YIELD子句用于选定或重命名后续语句使用的列。
- Documented syntax:

```text
yield_clause ::=
    'YIELD' yield_item_name ( 'AS' variable )? ( ',' yield_item_name ( 'AS' variable )? )*
```

### 复合查询

- Documentation key: `analytics-gql-reference/dql/composite-query/`
- Summary: 复合查询语句将多个线性查询语句的结果集合并在一起。
- Documented syntax:

```text
composite_query_statement ::=
  linear_query_statement query_conjunction linear_query_statement ( query_conjunction linear_query_statement )*

query_conjunction ::=
    'UNION' ('DISTINCT' | 'ALL')?
  | 'EXCEPT' ('DISTINCT' | 'ALL')?
  | 'INTERSECT' ('DISTINCT' | 'ALL')?
```

### FILTER

- Documentation key: `analytics-gql-reference/dql/filter/`
- Summary: FILTER语句用于从前一个语句的结果中筛选子集。
- Documented syntax:

```text
filter_statement ::=
  'FILTER' 'WHERE'? search_condition
```

### FOR

- Documentation key: `analytics-gql-reference/dql/for/`
- Summary: FOR语句用于遍历列表或表变量中的元素，并将元素逐条展开给后续语句处理。
- Documented syntax:

```text
for_statement ::=
  'FOR' variable_name 'IN' ( list_value_expression ('||' list_value_expression)* | table_reference_value_expression ) for_ordinality_or_offset?

for_ordinality_or_offset ::=
  ('WITH ORDINALITY' | 'WITH OFFSET') index_variable_name
```

### LET

- Documentation key: `analytics-gql-reference/dql/let/`
- Summary: LET语句用于声明可以在后续语句中使用的变量。
- Documented syntax:

```text
let_statement ::=
  'LET' variable_name '=' value_expression (',' variable_name '=' value_expression)*
```

### 线性查询

- Documentation key: `analytics-gql-reference/dql/linear-query/`
- Summary: 线性查询由一组简单查询语句串联组成，按顺序执行并输出最终结果。
- Documented syntax:

```text
linear_query_statement ::=
    ((use_graph_clause simple_query_statement+)+)? use_graph_clause simple_query_statement+ primitive_result_statement
  | use_graph_clause primitive_result_statement
  | (simple_query_statement+)? primitive_result_statement
  | use_graph_clause? '{' procedure_body '}'

simple_query_statement ::=
    let_statement
  | for_statement
  | filter_statement
  | paging_statement
  | call_procedure_statement
```

### K 最近邻查询

- Documentation key: `analytics-gql-reference/dql/nearest-neighbor/`
- Summary: K 最近邻（k-nearest neighbor，简称 KNN）查询用于按向量相似度返回前K个候选结果。它不依赖于向量索引，适用于小型的图和低维度的向量。
- Documented syntax:

```text
knn_search_statement ::= order_by_clause limit_clause
```

### 分页

- Documentation key: `analytics-gql-reference/dql/order-by-page/`
- Summary: ORDER BY、OFFSET和LIMIT子句可以一起使用，将查询结果数据集划分为离散的子集或页面。这种过程通常称为分页。
- Documented syntax:

```text
paging_statement ::=
    order_by_clause offset_clause? limit_clause?
  | offset_clause limit_clause?
  | limit_clause
```

### PER PARTITION

- Documentation key: `analytics-gql-reference/dql/per-partition/`
- Summary: PER PARTITION语句用于按分区处理分布式表变量。
- Documented syntax:

```text
per_partition_statement ::=
    'PER PARTITION' '(' identifier ')' 'OF' distributed_table_variable '{' per_partition_body '}'
```

### 最终输出语句

- Documentation key: `analytics-gql-reference/dql/primitive-result/`
- Summary: 最终输出语句定义线性查询的最终输出行为：
- Documented syntax:

```text
primitive_result ::=
    return_statement paging_statement?
  | FINISH
```

### RETURN

- Documentation key: `analytics-gql-reference/dql/return/`
- Summary: RETURN语句用于选择输出列，或在输出前完成聚合计算。
- Documented syntax:

```text
return_statement ::=
    'RETURN' ( 'ALL' | 'DISTINCT' )?  ( ( (value_expression ('AS' identifier)? ) ( ',' (value_expression ('AS' identifier)? ) )* )
      | '*' ) group_by_clause?
```

### 使用 CALL 调用内联过程

- Documentation key: `database-gql-reference/dql/call/call-inline-procedure/`
- Summary: 在 GQL 中，为了实现更复杂的查询组合和结果处理，可以使用 CALL 语句将一组语句封装成一个语句块，然后对该语句块的结果进行进一步的操作，如排序、限制、聚合等。这种方式类似于在表达式中使用圆括号将子表达式括起来，以确保其结果可以被引用和处理。这种语句块被称为内联过程。本文描述如何使用CALL调用内联过程。
- Documented syntax:

```text
call_inline_procedure_statement ::=
    'OPTIONAL'? 'CALL' '{' procedure_body '}'
```

### 使用 CALL 调用命名过程

- Documentation key: `database-gql-reference/dql/call/call-procedure/`
- Summary: 本文介绍如何使用CALL语句调用命名过程。
- Documented syntax:

```text
call_procedure_statement ::=
    'OPTIONAL'? 'CALL' procedure_name '(' argument_list? ')' ('YIELD' yield_clause)?
```

## executions

### 查询配置

- Documentation key: `analytics-gql-reference/executions/`
- Summary: 悦数图分析提供以下配置用于控制查询的解析和执行方式：
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 配置资源限制

- Documentation key: `analytics-gql-reference/executions/limits/`
- Summary: GQL 支持在查询中使用变量设置提示SET_VAR来配置资源用量限制。这些限制作用于当前查询，仅在当前查询中生效。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 配置参数

- Documentation key: `analytics-gql-reference/executions/parameters/`
- Summary: 在悦数图分析中，向过程（Procedure）或查询传递值的方式主要有以下三种：
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 配置异步执行

- Documentation key: `analytics-gql-reference/executions/submit/`
- Summary: 默认情况下，所有查询都是同步执行的。SUBMIT命令用于提交查询实现异步执行。建议在执行耗时较长的查询时使用该命令。在悦数图分析可视化编辑面板中执行 IMPORT 语句时，必须使用SUBMIT命令。
- Documented syntax:

```text
submit_command ::=
    'SUBMIT' gql_statement
```

## fe

### 聚合表达式

- Documentation key: `analytics-gql-reference/fe/expressions/aggregate/`
- Summary: 聚合表达式包含一个聚合函数实例，并返回聚合函数的执行结果。
- Documented syntax:

```text
aggregate_value_expression ::=
    aggregate_function '(' ( 'DISTINCT' | 'ALL' )? value_expression ( ',' value_expression )* ')'
```

### 变量表达式

- Documentation key: `analytics-gql-reference/fe/expressions/binding-variable/`
- Summary: 变量表达式用于引用当前记录中的字段或绑定变量。
- Documented syntax:

```text
variable_value_expression ::=
    variable
```

### 条件表达式

- Documentation key: `analytics-gql-reference/fe/expressions/case/`
- Summary: 条件表达式根据一个或多个条件的真假返回一个值。
- Documented syntax:

```text
case_value_expression ::=
    'CASE' ( 'WHEN' search_condition 'THEN' value_expression )+ ( 'ELSE' value_expression )? 'END'
  | 'coalesce' '(' value_expression ( ',' value_expression )+ ')'
```

### 类型转换表达式

- Documentation key: `analytics-gql-reference/fe/expressions/cast/`
- Summary: 类型转换表达式将表达式的数据类型转换为指定的目标数据类型。
- Documented syntax:

```text
cast_value_expression ::=
    'CAST' '(' (value_expression | 'NULL') 'AS' target_data_type ')'
```

### 常量表达式

- Documentation key: `analytics-gql-reference/fe/expressions/constant/`
- Summary: 常量表达式返回一个常量字面量。常量字面量是可以在查询中直接使用的固定值，并且在操作过程中不会被改变。
- Documented syntax:

```text
constant_value_expression ::=
    literal
```

### 构造表达式

- Documentation key: `analytics-gql-reference/fe/expressions/construct/`
- Summary: 构造表达式是用于创建复合数据类型（例如，列表和记录）的表达式。关于数据类型LIST和RECORD的更多信息，请参见数据类型。
- Documented syntax:

```text
construct_value_expression ::=
    'LIST' '[' value_expression ( ',' value_expression )* ']'
  | ( 'RECORD' )? '{' ( (field_name ':' value_expression) ( ',' (field_name ':' value_expression) )* )? '}'
```

### 函数表达式

- Documentation key: `analytics-gql-reference/fe/expressions/function/`
- Summary: 函数表达式包含一个函数实例并返回该函数的执行结果。
- Documented syntax:

```text
function_value_expression ::=
    function_name '(' value_expression ( ',' value_expression )* ')'
  | function_name '()'
```

### 标签表达式

- Documentation key: `analytics-gql-reference/fe/expressions/label/`
- Summary: 标签表达式可以引用图元素的标签。
- Documented syntax:

```text
label_expression ::=
    (label_factor ( '&' label_factor )* ) ( '|' (label_factor ( '&' label_factor )*) )*

label_factor ::=
    label_name
    | '%'
    | '(' label_expression ')'
    | '!' label_name
    | '!' '%'
    | '!' '(' label_expression ')'
```

### 匿名表达式

- Documentation key: `analytics-gql-reference/fe/expressions/lambda/`
- Summary: 匿名表达式（也被称作 Lambda 表达式）用于定义作用于列表中每个元素的操作。匿名表达式采用x -> expr的形式，其中x是输入参数，expr是表达式主体。
- Documented syntax:

```text
lambda_value_expression ::=
    variable '->' value_expression
```

### 逻辑表达式

- Documentation key: `analytics-gql-reference/fe/expressions/logical/`
- Summary: 逻辑表达式执行逻辑操作并返回布尔类型的结果。
- Documented syntax:

```text
logical_value_expression ::=
    value_expression ( 'AND' | 'OR' ) value_expression
```

### 属性表达式

- Documentation key: `analytics-gql-reference/fe/expressions/property/`
- Summary: 属性表达式用于引用图元素的属性或记录的字段。
- Documented syntax:

```text
property_value_expression ::=
    node_variable '.' property_name
  | edge_variable '.' property_name
  | record_value_expression '.' property_name
```

### 子查询表达式

- Documentation key: `analytics-gql-reference/fe/expressions/subquery/`
- Summary: 子查询表达式返回从某个查询中提取出的单个值或布尔值。
- Documented syntax:

```text
subquery_value_expression ::=
    'VALUE' '{' procedure_body '}'
  | 'EXISTS' '{' procedure_body '}'
```

### ALL_DIFFERENT 谓词

- Documentation key: `analytics-gql-reference/fe/predicates/all_different/`
- Summary: ALL_DIFFERENT谓词用于检查多个图元素是否两两不同。
- Documented syntax:

```text
all_different_predicate ::=
    ALL_DIFFERENT '(' element_variable_reference (',' element_variable_reference)+ ')'
```

### 比较谓词

- Documentation key: `analytics-gql-reference/fe/predicates/comparison/`
- Summary: 比较谓词比较两个值，并在比较为真时返回true，为假时返回false。在任一值为null时，返回null。
- Documented syntax:

```text
comparison_predicate ::=
    comparison_predicand comp_op comparison_predicand

comp_op ::= '=' | '<>'  | '<' | '>' | '<=' | '>='
```

### EXISTS 谓词

- Documentation key: `analytics-gql-reference/fe/predicates/exists/`
- Summary: EXISTS谓词用于检查某个图模式是否存在，或某段查询/过程逻辑的结果是否非空。
- Documented syntax:

```text
exists_predicate ::=
    EXISTS ( '{' graph_pattern '}' | '(' graph_pattern ')' | '{' procedure_body '}' )
```

### 标签谓词

- Documentation key: `analytics-gql-reference/fe/predicates/labeled/`
- Summary: 标签谓词检查图元素是否具有特定标签。
- Documented syntax:

```text
labeled_predicate ::=
    element_variable_reference ( ('IS' 'NOT'? 'LABELED') | ':') label_expression
```

### NULL 谓词

- Documentation key: `analytics-gql-reference/fe/predicates/null/`
- Summary: NULL 谓词用于检查表达式结果是否为null。
- Documented syntax:

```text
null_predicate ::=
    value_expression 'IS' 'NOT'? 'NULL'
```

### SAME 谓词

- Documentation key: `analytics-gql-reference/fe/predicates/same/`
- Summary: SAME谓词用于检查多个图元素是否相同。
- Documented syntax:

```text
same_predicate ::=
    SAME '(' element_variable_reference (',' element_variable_reference)+ ')'
```

## in-out

### EXPORT

- Documentation key: `analytics-gql-reference/in-out/export/`
- Summary: EXPORT语句用于将查询结果导出到表、文件、或远程的悦数图数据库的持久图中。
- Documented syntax:

```text
export_statement ::=
        'EXPORT' ( (value_expression ('AS' identifier)? ) ( ',' (value_expression ('AS' identifier)? ) )* ) 'INTO' variable
```

### IMPORT

- Documentation key: `analytics-gql-reference/in-out/import/`
- Summary: IMPORT语句用于向临时图导入数据。在悦数图分析中，数据可以来自文件、悦数图数据库持久图或分布式表变量。
- Documented syntax:

```text
import_statement ::=
    'IMPORT' 'INTO' 'GRAPH' '{' ( ( (node_definition (file_source | graph_source | table_source) | edge_definition (file_source | graph_source | table_source)) (',' (node_definition (file_source | graph_source | table_source) | edge_definition (file_source | graph_source | table_source) ))* )| 'GRAPH' graph_source ) '}' ( 'OPTIONS' '{' data_option ( ',' data_option )* '}' )?

node_definition ::=
    'NODE' '(' node_variable '@' node_type_name '{' (property_name ':' field_name) (',' (property_name ':' field_name))* '}' ')'

edge_definition ::=
    'EDGE' '(' (primary_key_property_name ':' field_name) (',' (primary_key_property_name ':' field_name) )* ')' ( ( '-[' edge_variable '@' edge_type_name '{' ((property_name ':' field_name) (',' (property_name ':' field_name))*)? '}' ']->' )
    |  ('<-[' edge_variable '@' edge_type_name '{' ((property_name ':' field_name) (',' (property_name ':' field_name))*)? '}' ']-' )
    |  ('~[' edge_variable '@' edge_type_name '{' ((property_name ':' field_name) (',' (property_name ':' field_name))*)? '}' ']~' ) )
    '(' (primary_key_property_name ':' field_name) (','(primary_key_property_name ':' field_name) )* ')'

file_source ::=
    'FROM' ( file_variable | ( 'DATAFILE' '{' file_options  '}' ) )

file_options ::=
    ('PATH' ':' file_path) ',' ('FORMAT' ':' ('"' 'CSV' '"'|'"' 'PARQUET' '"'|'"' 'ORC' '"')(',' additional_options)* )

file_path ::=
    '"' 'file://' path '"'
    | '"' 'hdfs://' hostname ':' port '/' path '"'
    | '"' 's3://' (access_key ':' secret_key '@')? bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'
    | '"' 'gs://' ((access_key ':' secret_key) | 'anonymous') '@' bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'

graph_source ::=
    'FROM' 'NEBULA' '{' 'PATH' ':' '"' nebula_uri_string '"' ',' 'FORMAT' ':' ('"' 'NEBULA' '"') '}'

nebula_uri_string ::=
    'nebula://' username ':' password '@' graph_address '?' ( 'graph' '=' graph_name) ('&' 'schema' '=' schema_path)? (('&' 'node_type' '=' source_node_type_name) | ('&' 'edge_type' '=' source_edge_type_name))? ('&' ( tls_parameter_name '=' tls_parameter_value))*

table_source ::=
    'FROM' table_variable

data_option ::=
    'PRIMARY_KEY_AS_NODE_ID' ':' ( 'true' | 'false' )
    | 'SKIP_CONFLICT_PK_NODES' ':' ( 'true' | 'false' )
    | 'SKIP_DANGLING_EDGES' ':' ( 'true' | 'false' )
```

### nebula_exec

- Documentation key: `analytics-gql-reference/in-out/nebula-exec/`
- Summary: nebula_exec过程用于在远程的悦数图数据库集群上执行 GQL 查询。您可以调用此过程将数据导入到悦数图数据库的图中。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### EXPORT

- Documentation key: `database-gql-reference/in-out/export/`
- Summary: EXPORT语句用于将查询结果导出到表、文件、或悦数图数据库的持久图中。
- Documented syntax:

```text
export_statement ::=
    'EXPORT' ( (value_expression ('AS' identifier)? ) ( ',' (value_expression ('AS' identifier)? ) )* ) 'INTO' variable
```

### IMPORT

- Documentation key: `database-gql-reference/in-out/import/`
- Summary: IMPORT语句用于向临时图导入数据。该语句通常与 USE 子句配合使用，后者用于指定目标临时图。数据可以来自文件、悦数图数据库或表变量。
- Documented syntax:

```text
import_statement ::=
    'IMPORT' 'INTO' 'GRAPH' '{' ( ( (node_definition (file_source | graph_source | table_source) | edge_definition (file_source | graph_source | table_source)) (',' (node_definition (file_source | graph_source | table_source) | edge_definition (file_source | graph_source | table_source) ))* )| 'GRAPH' graph_source ) '}' ( 'OPTIONS' '{' data_option ( ',' data_option )* '}' )?

node_definition ::=
    'NODE' '(' node_variable '@' node_type_name '{' (property_name ':' field_name) (',' (property_name ':' field_name))* '}' ')'

edge_definition ::=
    'EDGE' '(' (primary_key_property_name ':' field_name) (',' (primary_key_property_name ':' field_name) )* ')' ( ( '-[' edge_variable '@' edge_type_name '{' ((property_name ':' field_name) (',' (property_name ':' field_name))*)? '}' ']->' )
    |  ('<-[' edge_variable '@' edge_type_name '{' ((property_name ':' field_name) (',' (property_name ':' field_name))*)? '}' ']-' )
    |  ('~[' edge_variable '@' edge_type_name '{' ((property_name ':' field_name) (',' (property_name ':' field_name))*)? '}' ']~' ) )
    '(' (primary_key_property_name ':' field_name) (','(primary_key_property_name ':' field_name) )* ')'

file_source ::=
    'FROM' ( file_variable | ( 'DATAFILE' '{' file_options  '}' ) )

file_options ::=
    ('PATH' ':' file_path) ',' ('FORMAT' ':' ('"' 'CSV' '"'|'"' 'PARQUET' '"'|'"' 'ORC' '"')(',' additional_options)* )

file_path ::=
    '"' 'file://' path '"'
    | '"' 'hdfs://' hostname ':' port '/' path '"'
    | '"' 's3://' (access_key ':' secret_key '@')? bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'
    | '"' 'gs://' ((access_key ':' secret_key) | 'anonymous') '@' bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'

graph_source ::=
    'FROM' 'NEBULA' '{' 'PATH' ':' '"' nebula_uri_string '"' ',' 'FORMAT' ':' ('"' 'NEBULA' '"') '}'

nebula_uri_string ::=
    'nebula://' username ':' password '@' graph_address '?' ( 'graph' '=' graph_name) ('&' 'schema' '=' schema_path)? (('&' 'node_type' '=' source_node_type_name) | ('&' 'edge_type' '=' source_edge_type_name))? ('&' ( tls_parameter_name '=' tls_parameter_value))*

table_source ::=
    'FROM' table_variable

data_option ::=
    'PRIMARY_KEY_AS_NODE_ID' ':' ( 'true' | 'false' )
    | 'SKIP_CONFLICT_PK_NODES' ':' ( 'true' | 'false' )
    | 'SKIP_DANGLING_EDGES' ':' ( 'true' | 'false' )
```

### nebula_exec

- Documentation key: `database-gql-reference/in-out/nebula-exec/`
- Summary: nebula_exec过程用于在远程的悦数图数据库集群上执行 GQL 查询。您可以调用此过程将数据导入到悦数图数据库的图中。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

## log

### 日志语句

- Documentation key: `analytics-gql-reference/log/`
- Summary: 日志语句用于在过程执行期间，输出调试或监控等日志信息。您可以根据所创建过程的具体情况，指定打印的日志位置、级别和内容。
- Documented syntax:

```text
log_statement ::= ('LOG_DEBUG' | 'LOG_INFO' | 'LOG_WARN' | 'LOG_ERROR' | 'LOG_FATAL') '(' log_message (',' log_message)* ')'
```

### 日志语句

- Documentation key: `database-gql-reference/log/`
- Summary: 日志语句用于在过程执行期间，输出调试或监控等日志信息。您可以根据所创建过程的具体情况，指定打印的日志位置、级别和内容。
- Documented syntax:

```text
log_statement ::= ('LOG_DEBUG' | 'LOG_INFO' | 'LOG_WARN' | 'LOG_ERROR' | 'LOG_FATAL') '(' log_message (',' log_message)* ')'
```

## match-compute

### 匹配计算语句

- Documentation key: `analytics-gql-reference/match-compute/`
- Summary: 匹配计算语句用于在临时图上执行迭代计算。它允许匹配特定的图模式，然后在匹配的子图上执行计算或更新操作。
- Documented syntax:

```text
match_compute_statement ::=
    'MATCH' graph_pattern (( per_block active_set_operation? ) | active_set_operation)

per_block ::=
    ( ('PER PATH' '{' procedure_body '}') ( 'PER NODE' '(' node_variable ')' '{' procedure_body '}' )* )
    | ('PER NODE' '(' node_variable ')' '{' procedure_body '}')+

active_set_operation ::=
    'FINALLY' '{' ('SET' active_set_variable ('=' | '|=') node_variable)+ '}'
```

## patterns

### 图模式

- Documentation key: `analytics-gql-reference/patterns/`
- Summary: 在悦数图分析中，图模式用于匹配计算语句中描述要遍历的图结构。与悦数图数据库的通用 MATCH 不同，图分析的匹配计算仅支持受限的图模式子集。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 边模式

- Documentation key: `analytics-gql-reference/patterns/edge-patterns/`
- Summary: 在悦数图分析的匹配计算语句中，边模式用于匹配图中的边。边模式与两端的点模式组合，形成单跳路径模式(s)-[e]->(t)。
- Documented syntax:

```text
edge_pattern_filler ::=
    edge_variable?
    ( ( ':' | 'IS' ) label_expression | '@' edge_type_specification )?
    ( property_specification | 'WHERE' search_condition )?
```

### 点模式

- Documentation key: `analytics-gql-reference/patterns/node-patterns/`
- Summary: 在悦数图分析的匹配计算语句中，点模式用于匹配图中的点。点模式由圆括号（()）包围的点模式填充器组成。
- Documented syntax:

```text
node_pattern_filler ::=
    node_variable?
    ( ( ':' | 'IS' ) label_expression | '@' node_type_specification )?
    ( property_specification | 'WHERE' search_condition )?
```

## procedures

### CREATE PROCEDURE

- Documentation key: `analytics-gql-reference/procedures/create/`
- Summary: CREATE PROCEDURE语句用于在当前 Schema 中创建用户定义的过程（User-Defined Procedure，简称 UDP）。在悦数图分析中，过程用于将图类型定义、临时图创建和数据检索等步骤组织为可复用的执行单元。
- Documented syntax:

```text
create_procedure_statement ::=
    'CREATE' (('PROCEDURE' ('IF NOT EXISTS')?) | ('OR REPLACE' 'PROCEDURE')) procedure_name '(' ( parameter_declaration ( ',' parameter_declaration )* )? ')' returns_clause? ('COMMENT' comment_string)? 'AS'? '{' procedure_body '}'

parameter_declaration  ::=
    parameter_name parameter_type ('DEFAULT' default_value )?

returns_clause ::=
      'RETURNS' '(' ')'
    | 'RETURNS' return_name return_type
    | 'RETURNS' '(' return_name return_type (',' return_name return_type )+ ')'
```

### 过程概述

- Documentation key: `database-gql-reference/procedures/`
- Summary: 本文介绍 GQL 中的过程（Procedure）的定义、类型及使用方法。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### ALTER PROCEDURE

- Documentation key: `database-gql-reference/procedures/alter/`
- Summary: ALTER PROCEDURE语句用于修改当前 Schema 中用户定义的过程（User-Defined Procedure，简称 UDP），包括修改 UDP 的名称和描述。
- Documented syntax:

```text
alter_procedure_statement ::=
    'ALTER' 'PROCEDURE' procedure_name '(' ( parameter_declaration ( ',' parameter_declaration )* )? ')'
    ( ('COMMENT' new_comment_string) |
    ('RENAME' 'TO' new_procedure_name) )

parameter_declaration  ::=
    parameter_name? parameter_type ('DEFAULT' default_value )?
```

### CREATE PROCEDURE

- Documentation key: `database-gql-reference/procedures/create/`
- Summary: CREATE PROCEDURE语句用于在当前 Schema 中创建用户定义的过程（User-Defined Procedure，简称 UDP）。所有 UDP 必须是命名过程。
- Documented syntax:

```text
create_procedure_statement ::=
    'CREATE' (('PROCEDURE' ('IF NOT EXISTS')?) | ('OR REPLACE' 'PROCEDURE')) procedure_name '(' ( parameter_declaration ( ',' parameter_declaration )* )? ')' returns_clause? ('COMMENT' comment_string)? 'AS'? '{' procedure_body '}'

parameter_declaration  ::=
    parameter_name parameter_type ('DEFAULT' default_value )?

returns_clause ::=
      'RETURNS' '(' ')'
    | 'RETURNS' return_name return_type
    | 'RETURNS' '(' return_name return_type (',' return_name return_type )+ ')'
```

### DROP PROCEDURE

- Documentation key: `database-gql-reference/procedures/drop/`
- Summary: DROP PROCEDURE语句用于删除当前 Schema 中用户定义的过程（User-Defined Procedure，简称 UDP）。
- Documented syntax:

```text
drop_procedure_statement ::=
    'DROP' 'PROCEDURE' ('IF EXISTS')? procedure_name ( '(' ( parameter_declaration ( ',' parameter_declaration )* )? ')' )?

parameter_declaration  ::=
    parameter_name? parameter_type ('DEFAULT' default_value )?
```

### 子图过程（algo.subgraph）

- Documentation key: `database-gql-reference/procedures/subgraph/`
- Summary: algo.subgraph是一个内置命名过程，用于在持久图上按多源 BFS 方式提取子图。可以指定起始点、遍历步数、边类型、遍历方向，以及边和点的属性过滤条件。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

## server-prog

### 服务端编程概述

- Documentation key: `analytics-gql-reference/server-prog/`
- Summary: GQL 支持通过用户定义过程（User-defined Procedure，简称 UDP）进行服务端编程。开发者可以编写能在服务器上直接执行的自定义逻辑，进而扩展 GQL 的功能。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 服务端编程概述

- Documentation key: `database-gql-reference/server-prog/`
- Summary: GQL 支持通过用户定义过程（User-defined Procedure，简称 UDP）进行服务端编程。开发者可以编写能在服务器上直接执行的自定义逻辑，进而扩展 GQL 的功能。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

## set

### 变量操作

- Documentation key: `analytics-gql-reference/set/`
- Summary: SET语句用于对变量执行赋值、聚合和函数调用等操作。
- Documented syntax:

```text
assignment_statement ::=
    'SET' ( primitive_value_variable | aggregator_value_variable | active_set_variable ) '=' value_expression

aggregation_statement ::=
    'SET' aggregator_value_variable '+=' value_expression

function_call_statement ::=
    'SET' (aggregator_value_variable | table_variable) '.' member_function '(' ( argument (',' argument)* )? ')'
```

## statement-block

### 语句块

- Documentation key: `analytics-gql-reference/statement-block/`
- Summary: 在悦数图分析中，语句块是由一条或多条按顺序执行的语句组成的执行单元。
- Documented syntax:

```text
statement_block ::=
    ( ( linear_catalog_modifying_statement | linear_data_modifying_statement | composite_query_statement ) ( 'NEXT' ( linear_catalog_modifying_statement | linear_data_modifying_statement | composite_query_statement ) )*
    | match_compute_statement
    | control_flow_statement
    | variable_manipulation_statement
    | import_statement
    | export_statement
    | logging_statement )
```

### 语句块

- Documentation key: `database-gql-reference/statement-block/`
- Summary: 在 GQL 中，语句块是一条或多条按顺序执行的语句组成的集合。
- Documented syntax:

```text
statement_block ::=
   ( ( linear_catalog_modifying_statement | linear_data_modifying_statement | composite_query_statement ) ( 'NEXT' ( linear_catalog_modifying_statement | linear_data_modifying_statement | composite_query_statement ) )*
   | match_compute_statement
   | control_flow_statement
   | variable_manipulation_statement
   | import_statement
   | export_statement
   | logging_statement )
```

## variable-definition

### 变量

- Documentation key: `analytics-gql-reference/variable-definition/`
- Summary: 在 GQL 中，变量是一种用于表示特定数据类型的实例集合的标识符。变量可用于在过程中存储值，从而进行数据检索和操作等。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 活动集变量

- Documentation key: `analytics-gql-reference/variable-definition/active-set-variable/`
- Summary: 活动集变量用于在过程执行期间存储需要处理的点的集合。活动集变量可以被更新，以便下一步只针对这些点继续计算。
- Documented syntax:

```text
active_set_variable_definition ::=
    'VALUE' active_set_variable '::'? 'ACTIVE_SET'
```

### 聚合值变量

- Documentation key: `analytics-gql-reference/variable-definition/agg/`
- Summary: 聚合值变量用于定义对嵌套值的聚合操作。在引用聚合值变量时，必须在变量名前加上@符号，以区别于原始值变量。
- Documented syntax:

```text
aggregator_value_variable_definition ::=
    'NODE'? 'VALUE' aggregator_value_variable aggr_type ('=' value_expression)?

aggr_type ::=
    SumAgg
    | AvgAgg
    | MaxAgg
    | MinAgg
    | AndAgg
    | OrAgg
    | ListAgg
    | SetAgg
    | MapAgg
    | TopKAgg
```

### AndAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/and_agg/`
- Summary: AndAgg 聚合值变量 (AndAgg) 维护对所有布尔类型的输入进行逻辑AND运算的结果。
- Documented syntax:

```text
and_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'AndAgg' '=' value_expression
```

### AvgAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/avg_agg/`
- Summary: AvgAgg 聚合值变量（AvgAgg<T>）用于对所有类型为T的输入进行平均值计算。
- Documented syntax:

```text
avg_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'AvgAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE') '>'
```

### ListAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/list_agg/`
- Summary: ListAgg 聚合值变量（ListAgg<T>）将所有类型为T的输入按照插入顺序聚合为一个列表。如需聚合不含重复值的集合，参见 SetAgg。
- Documented syntax:

```text
list_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'ListAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING'|'LIST' '<' data_type '>' |( 'RECORD' )? '{' ( (field_name data_type) ( ',' (field_name data_type) )* )? '}') '>'
```

### MapAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/map_agg/`
- Summary: MapAgg 聚合值变量（MapAgg<K, V>）是一组键值对的映射，其中每个键映射到一个聚合值。K表示键的数据类型，V表示嵌套的聚合器类型。
- Documented syntax:

```text
map_agg_declaration ::=
  'NODE'? 'VALUE' aggregator_value_variable 'MapAgg' '<' key_type ',' nested_aggregator '>'

scalar_type ::= 'INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING'

key_type ::= scalar_type

nested_aggregator ::=
    'SumAgg' '<' scalar_type '>'
  | 'AvgAgg' '<' ('INT64'|'FLOAT'|'DOUBLE') '>'
  | 'MaxAgg' '<' scalar_type '>'
  | 'MinAgg' '<' scalar_type '>'
  | 'AndAgg'
  | 'OrAgg'
  | 'ListAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING'|'LIST'|'RECORD') '>'
  | 'SetAgg' '<' scalar_type '>'
  | 'TopKAgg' '<' 'RECORD' '>'
```

### MaxAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/max_agg/`
- Summary: MaxAgg 聚合值变量（MaxAgg<T>）用于保存所有类型为T的输入中的最大值。如需保存最小值，请参见 MinAgg。
- Documented syntax:

```text
max_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'MaxAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>' '=' value_expression
```

### MinAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/min_agg/`
- Summary: MinAgg 聚合值变量（MinAgg<T>）用于保存所有类型为T的输入中的最小值。如需保存最大值，请参见 MaxAgg。
- Documented syntax:

```text
min_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'MinAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>' '=' value_expression
```

### OrAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/or_agg/`
- Summary: OrAgg 聚合值变量 (OrAgg) 维护对所有布尔类型的输入进行逻辑OR运算的结果。
- Documented syntax:

```text
or_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'OrAgg' '=' value_expression
```

### SetAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/set_agg/`
- Summary: SetAgg 聚合值变量（SetAgg<T>）将所有类型为T的输入聚合为不包含重复值的集合。如需聚合包含重复值的列表，参见 ListAgg。
- Documented syntax:

```text
set_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'SetAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>'
```

### SumAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/sum_agg/`
- Summary: SumAgg聚合器值变量（SumAgg<T>）用于维护所有输入值的聚合结果，其中T表示输入值的数据类型。其聚合行为取决于所指定的数据类型：
- Documented syntax:

```text
sum_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'SumAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>' '=' value_expression
```

### TopKAgg

- Documentation key: `analytics-gql-reference/variable-definition/agg/topk_agg/`
- Summary: TopKAgg 聚合值变量（TopKAgg<K, SortFields>）根据指定的排序字段（SortFields）维护前 K 条记录。该变量自动保留根据排序规则（升序或降序）排序后的前 K 条记录，并在记录数量超过 K 时丢弃其他记录。
- Documented syntax:

```text
topk_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'TopKAgg' '<' top_k ',' (sort_field data_type ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')? ) (',' (sort_field data_type ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')? ))* '>'
```

### 文件变量

- Documentation key: `analytics-gql-reference/variable-definition/file-variable/`
- Summary: 文件变量用于定义基于文件的数据源和数据目的地。它们主要用于数据的导入或导出操作，可处理多种文件格式，包括 CSV、Parquet 和 ORC。每个文件变量可以对应一个或多个文件。
- Documented syntax:

```text
file_variable_definition ::=
    'FILE' file_variable '{' (column_definitions) ( ',' (column_definitions))* '}' '=' 'DATAFILE' '{' file_options '}'

column_definitions ::=
    column_name value_type

file_options ::=
    ('PATH' ':' file_path) ',' ('FORMAT' ':' ('"' 'CSV' '"'|'"' 'PARQUET' '"'|'"' 'ORC' '"')(',' additional_options)* )

file_path ::=
      '"' 'file://' path '"'
    | '"' 'hdfs://' hostname ':' port '/' path '"'
    | '"' 's3://' (access_key ':' secret_key '@')? bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'
    | '"' 'gs://' ((access_key ':' secret_key) | 'anonymous') '@' bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'
```

### 图变量

- Documentation key: `analytics-gql-reference/variable-definition/graph-variable/`
- Summary: 在悦数图分析中的图变量用于在过程或查询中保存分布式子图，以便后续执行导入、匹配计算和结果返回。关键字GRAPH用于定义图变量。
- Documented syntax:

```text
graph_variable_definition_from_type ::=
  'PROPERTY'? 'GRAPH' graph_variable 'TYPED' graph_type_name 'PARTITION BY DEFAULT'
```

```text
graph_variable_clear ::=
   'SET' graph_variable '.clear()'
```

### 表变量

- Documentation key: `analytics-gql-reference/variable-definition/table-variable/`
- Summary: 在悦数图分析中，表变量用于保存中间结果、跨过程传递数据，以及收集最终返回结果。根据使用方式不同，表变量可分为本地表和分布式表两类；在分布式模式下，推荐优先使用分布式表。
- Documented syntax:

```text
table_variable_definition ::=
    'BINDING'? 'TABLE' table_variable (
    ((( '::' | 'TYPED' ) 'BINDING TABLE')?
    '{' (field_name value_type) (',' (field_name value_type))* '}' ('=' table_value_constructor)?
    )
    | '{' field_name (',' field_name)* '}' '=' table_value_constructor
    | '=' table_value_constructor
)

table_value_constructor ::=
    table_expression
    | '{' procedure_body '}'

table_expression ::=
    ( '{' (field_name ':' value_expression) (',' (field_name ':' value_expression))* '}' ) (',' ( '{' (field_name ':' value_expression) (',' (field_name ':' value_expression))* '}' ) )*
    | ( '(' value_expression (',' value_expression)* ')' ) ( ',' ( '(' value_expression (',' value_expression)* ')' ) )*
```

```text
distributed_table_variable_definition ::=
    'BINDING'? 'TABLE' table_variable
    ((( '::' | 'TYPED' ) 'BINDING TABLE')?
    '{' (field_name value_type) (',' (field_name value_type))* '}' 'PARTITION BY DEFAULT')
```

### 原始值变量

- Documentation key: `analytics-gql-reference/variable-definition/value-variable/`
- Summary: 原始值变量用于在 GQL 过程中存储值或在过程执行中传递值。原始值变量通过关键字VALUE声明。
- Documented syntax:

```text
primitive_value_variable_definition ::=
    'VALUE' primitive_value_variable (('TYPED' | '::')? value_type)? ('=' value_expression)?
```

### 变量

- Documentation key: `database-gql-reference/variable-definition/`
- Summary: 在 GQL 中，变量是一种用于表示特定数据类型的实例集合的标识符。变量可用于在过程中存储值，从而进行数据检索和操作等。
- Documented syntax: no standalone grammar block in the rendered page; do not treat the capability as unsupported.

### 活动集变量

- Documentation key: `database-gql-reference/variable-definition/active-set-variable/`
- Summary: 活动集变量用于在过程执行期间存储需要处理的点的集合。活动集变量可以被更新，以便下一步只针对这些点继续计算。
- Documented syntax:

```text
active_set_variable_definition ::=
    'VALUE' active_set_variable '::'? 'ACTIVE_SET'
```

### 聚合值变量

- Documentation key: `database-gql-reference/variable-definition/agg/`
- Summary: 聚合值变量用于定义对嵌套值的聚合操作。在引用聚合值变量时，必须在变量名前加上@符号，以区别于原始值变量。
- Documented syntax:

```text
aggregator_value_variable_definition ::=
    'NODE'? 'VALUE' aggregator_value_variable aggr_type ('=' value_expression)?

aggr_type ::=
    SumAgg
    | AvgAgg
    | MaxAgg
    | MinAgg
    | AndAgg
    | OrAgg
    | ListAgg
    | SetAgg
    | MapAgg
    | TopKAgg
```

### AndAgg

- Documentation key: `database-gql-reference/variable-definition/agg/and_agg/`
- Summary: AndAgg 聚合值变量 (AndAgg) 维护对所有布尔类型的输入进行逻辑AND运算的结果。
- Documented syntax:

```text
and_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'AndAgg' '=' value_expression
```

### AvgAgg

- Documentation key: `database-gql-reference/variable-definition/agg/avg_agg/`
- Summary: AvgAgg 聚合值变量（AvgAgg<T>）用于对所有类型为T的输入进行平均值计算。
- Documented syntax:

```text
avg_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'AvgAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE') '>'
```

### ListAgg

- Documentation key: `database-gql-reference/variable-definition/agg/list_agg/`
- Summary: ListAgg 聚合值变量（ListAgg<T>）将所有类型为T的输入按照插入顺序聚合为一个列表。如需聚合不含重复值的集合，参见 SetAgg。
- Documented syntax:

```text
list_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'ListAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING'|'LIST' '<' data_type '>' |( 'RECORD' )? '{' ( (field_name data_type) ( ',' (field_name data_type) )* )? '}') '>'
```

### MapAgg

- Documentation key: `database-gql-reference/variable-definition/agg/map_agg/`
- Summary: MapAgg 聚合值变量（MapAgg<K, V>）是一组键值对的映射，其中每个键映射到一个聚合值。K表示键的数据类型，V表示嵌套的聚合器类型。
- Documented syntax:

```text
map_agg_declaration ::=
  'NODE'? 'VALUE' aggregator_value_variable 'MapAgg' '<' key_type ',' nested_aggregator '>'

scalar_type ::= 'INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING'

key_type ::= scalar_type

nested_aggregator ::=
    'SumAgg' '<' scalar_type '>'
  | 'AvgAgg' '<' ('INT64'|'FLOAT'|'DOUBLE') '>'
  | 'MaxAgg' '<' scalar_type '>'
  | 'MinAgg' '<' scalar_type '>'
  | 'AndAgg'
  | 'OrAgg'
  | 'ListAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING'|'LIST'|'RECORD') '>'
  | 'SetAgg' '<' scalar_type '>'
  | 'TopKAgg' '<' 'RECORD' '>'
```

### MaxAgg

- Documentation key: `database-gql-reference/variable-definition/agg/max_agg/`
- Summary: MaxAgg 聚合值变量（MaxAgg<T>）用于保存所有类型为T的输入中的最大值。如需保存最小值，请参见 MinAgg。
- Documented syntax:

```text
max_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'MaxAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>' '=' value_expression
```

### MinAgg

- Documentation key: `database-gql-reference/variable-definition/agg/min_agg/`
- Summary: MinAgg 聚合值变量（MinAgg<T>）用于保存所有类型为T的输入中的最小值。如需保存最大值，请参见 MaxAgg。
- Documented syntax:

```text
min_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'MinAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>' '=' value_expression
```

### OrAgg

- Documentation key: `database-gql-reference/variable-definition/agg/or_agg/`
- Summary: OrAgg 聚合值变量 (OrAgg) 维护对所有布尔类型的输入进行逻辑OR运算的结果。
- Documented syntax:

```text
or_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'OrAgg' '=' value_expression
```

### SetAgg

- Documentation key: `database-gql-reference/variable-definition/agg/set_agg/`
- Summary: SetAgg 聚合值变量（SetAgg<T>）将所有类型为T的输入聚合为不包含重复值的集合。如需聚合包含重复值的列表，参见 ListAgg。
- Documented syntax:

```text
set_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'SetAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>'
```

### SumAgg

- Documentation key: `database-gql-reference/variable-definition/agg/sum_agg/`
- Summary: SumAgg聚合器值变量（SumAgg<T>）用于维护所有输入值的聚合结果，其中T表示输入值的数据类型。其聚合行为取决于所指定的数据类型：
- Documented syntax:

```text
sum_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'SumAgg' '<' ('INT8'|'INT16'|'INT32'|'INT64'|'FLOAT'|'DOUBLE'|'STRING') '>' '=' value_expression
```

### TopKAgg

- Documentation key: `database-gql-reference/variable-definition/agg/topk_agg/`
- Summary: TopKAgg 聚合值变量（TopKAgg<K, SortFields>）根据指定的排序字段（SortFields）维护前 K 条记录。该变量自动保留根据排序规则（升序或降序）排序后的前 K 条记录，并在记录数量超过 K 时丢弃其他记录。
- Documented syntax:

```text
topk_agg_declaration ::=
    'NODE'? 'VALUE' aggregator_value_variable 'TopKAgg' '<' top_k ',' (sort_field data_type ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')? ) (',' (sort_field data_type ( 'ASC' | 'ASCENDING' | 'DESC' | 'DESCENDING' )? ('NULLS FIRST' | 'NULLS LAST')? ))* '>'
```

### 文件变量

- Documentation key: `database-gql-reference/variable-definition/file-variable/`
- Summary: 文件变量用于定义基于文件的数据源和数据目的地。它们主要用于数据的导入或导出操作，可处理多种文件格式，包括 CSV、Parquet 和 ORC。每个文件变量可以对应一个或多个文件。
- Documented syntax:

```text
file_variable_definition ::=
    'FILE' file_variable '{' (column_definitions) ( ',' (column_definitions))* '}' '=' 'DATAFILE' '{' file_options '}'

column_definitions ::=
    column_name value_type

file_options ::=
    ('PATH' ':' file_path) ',' ('FORMAT' ':' ('"' 'CSV' '"'|'"' 'PARQUET' '"'|'"' 'ORC' '"')(',' additional_options)* )

file_path ::=
      '"' 'file://' path '"'
    | '"' 'hdfs://' hostname ':' port '/' path '"'
    | '"' 's3://' (access_key ':' secret_key '@')? bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'
    | '"' 'gs://' ((access_key ':' secret_key) | 'anonymous') '@' bucket '/' path ( '?' ( parameter_name '=' parameter_value) ('&' ( parameter_name '=' parameter_value))* )? '"'
```

### 图变量

- Documentation key: `database-gql-reference/variable-definition/graph-variable/`
- Summary: 图变量用于存储子图以进行查询和计算。关键字GRAPH用于定义图变量。
- Documented syntax:

```text
graph_variable_definition_from_query ::=
     'PROPERTY'? 'GRAPH' graph_variable
        ( 'TYPED'? 'GRAPH' '{'
        (
            (('NODE' | 'VERTEX') 'TYPE'? node_type_name '(' node_type_filler ')')
            |
            (('EDGE' | 'RELATIONSHIP') 'TYPE'? edge_type_name
                (
                    '(' source_node_type_name ')' '-[' edge_type_filler ']->' '(' destination_node_type_name ')'
                    |
                    '(' destination_node_type_name ')' '<-[' edge_type_filler ']-' '(' source_node_type_name ')'
                    |
                    '(' source_node_type_name ')' '~[' edge_type_filler ']~' '(' destination_node_type_name ')'
                )
            )
        )
        (
            ','
            (
                (('NODE' | 'VERTEX') 'TYPE'? node_type_name '(' node_type_filler ')')
                |
                (('EDGE' | 'RELATIONSHIP') 'TYPE'? edge_type_name
                    (
                        '(' source_node_type_name ')' '-[' edge_type_filler ']->' '(' destination_node_type_name ')'
                        |
                        '(' destination_node_type_name ')' '<-[' edge_type_filler ']-' '(' source_node_type_name ')'
                        |
                        '(' source_node_type_name ')' '~[' edge_type_filler ']~' '(' destination_node_type_name ')'
                    )
                )
            )
        )*
    '}' )? '=' 'GRAPH' '{' use_clause? match_statement return_statement '}'
```

```text
graph_variable_definition_from_type ::=
     'PROPERTY'? 'GRAPH' graph_variable 'TYPED' graph_type_name
```

```text
graph_variable_clear ::=
     'SET' graph_variable '.clear()'
```

### 表变量

- Documentation key: `database-gql-reference/variable-definition/table-variable/`
- Summary: 表变量以表格形式存储数据。在悦数图数据库中，表变量主要用于保存查询结果、遍历中间结果，以及驱动批量插入、更新或删除点和边。
- Documented syntax:

```text
table_variable_definition ::=
    'BINDING'? 'TABLE' table_variable (
        ((( '::' | 'TYPED' ) 'BINDING TABLE')?
            '{' (field_name value_type) (',' (field_name value_type))* '}' ('=' table_value_constructor)?
        )
        | '{' field_name (',' field_name)* '}' '=' table_value_constructor
        | '=' table_value_constructor
    )

table_value_constructor ::=
    table_expression
    | '{' procedure_body '}'

table_expression ::=
    ( '{' (field_name ':' value_expression) (',' (field_name ':' value_expression))* '}' ) (',' ( '{' (field_name ':' value_expression) (',' (field_name ':' value_expression))* '}' ) )*
    | ( '(' value_expression (',' value_expression)* ')' ) ( ',' ( '(' value_expression (',' value_expression)* ')' ) )*
```

### 原始值变量

- Documentation key: `database-gql-reference/variable-definition/value-variable/`
- Summary: 原始值变量用于在 GQL 过程中存储值或在过程执行中传递值。原始值变量通过关键字VALUE声明。
- Documented syntax:

```text
primitive_value_variable_definition ::=
    'VALUE' primitive_value_variable (('TYPED' | '::')? value_type)? ('=' value_expression)?
```
