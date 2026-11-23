# GQL 关键字标识符检查

5.3.0 的 `src/parser/Keywords.h`（固定标签 `v5.3.0`）与 Database、
Analytics 两份“标识符和关键字”文档逐类完全一致：

| 类别 | 源码 | Database 文档 | Analytics 文档 |
| --- | ---: | ---: | ---: |
| 保留关键字 | 224 | 224 | 224 |
| 非保留关键字 | 207 | 207 | 207 |

核对时排除源码中已注释的宏。版本、文档键与摘要见
[源检查记录](../evals/keywords/source-check.json)；完整词表在两项技能各自的
`references/documented-keywords.json` 中，包含 `reserved` 和 `non_reserved`。

两项技能生成、迁移和修复 GQL 时，对每个标识符的声明和引用使用反引号。
此规则覆盖普通名称及关键字名称。限定名逐段引用，标签和类型集合逐项引用。

```gql
USE `social`
MATCH (`p`@![`Archived`, `date`])
RETURN `p`.`property` AS `version`, `p`.`id` AS `person_id`
ORDER BY `version` ASC, `person_id` ASC
```

语法关键字、内置类型、函数、字符串、外部参数 `$name` 和临时图 token `#name`
使用各自的语法。包内 `quote-identifiers` 可格式化单个或多个原始名称，
`lint` 检查可识别的名称位置。详见[生成规则](../src/gql-query-generator/references/identifiers.md)。

## 当前源码的发布验证（2026-11-23）

37 条新模型输出通过静态契约，16 条新路由判断通过。12 条可独立执行的模型查询在 5.3.2 测试库上通过 EXPLAIN 和结果比对。历史输出中有 32 条漏引标识符，已保留原始文件供对照。[模型输出与生成条件](../evals/observations/README.md) · [数据库结果](../evals/reports/database-current.json)

测试库验证了 431 个关键字的大写、小写两种别名，以及含中文、空格、外部参数、过程变量、记录字段和聚合器的用例。每一批均比对返回列的原始拼写与结果值。[标识符实测](../evals/keywords/runtime-check.json)

语义评测为 13 个案例各启动两个独立上下文。26 份原始候选在隐藏输入上通过 92 次结果比对，其中图查询 48 次、Database 过程体 22 次、本地临时图计算 22 次。13 组校准均能区分正确程序与故意引入的语义错误，自有临时图清理成功。命名过程生命周期与分布式 Analytics 的执行覆盖仍属证据不足。[当前运行记录](../evals/quality/evidence/current/model-run.json) · [校准记录](../evals/quality/evidence/current/calibration.json)

## 以往发布记录

26.10.23 语义收据已按原样归档。本次发布准备为修改后源重新独立生成了 26 份候选，
92 组输入结果比对与 13 组 oracle 校准全部通过，当前证据的离线重算和完整离线发布门禁也已通过。
源码变化引起的旧收据失效没有被绕过；本次重新生成与执行结果见
[26.10.25 发布验证](quality-assessment-2026-10-25.md)。这仍是既有定向案例的回归，
不代表完整命名过程生命周期、分布式 Analytics 或总体生成正确率验收。
