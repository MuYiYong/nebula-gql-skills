# Server Programming Skill Knowledge Map

本文件描述 `gql-procedure-generator` 的内嵌知识版图。它不是引用索引，而是技能包内部的主题分层。

## Core knowledge
- 服务端编程总览
- 过程总览
- `CREATE PROCEDURE`
- `ALTER PROCEDURE`
- `DROP PROCEDURE`
- 调用命名过程
- 调用内联过程
- `SHOW PROCEDURES`
- `SHOW CREATE PROCEDURE`
- `match_compute_statement`
- 变量总览
- 原始值变量
- 活动集变量
- 聚合值变量总览
- 变量操作
- 控制流
- 日志语句

## Aggregator knowledge
- `ListAgg`
- `SetAgg`
- `MapAgg`
- `SumAgg`
- `MinAgg`
- `MaxAgg`
- `AvgAgg`
- `AndAgg`
- `OrAgg`
- `TopKAgg`

## Secondary knowledge
- 表变量
- 图变量
- 文件变量
- `FOR`

## Packaging rule
- 默认只把 Core knowledge 与稳定的 aggregator 规则压缩进技能包。
- Secondary knowledge 只在确有需要时加载，不作为默认生成基线。