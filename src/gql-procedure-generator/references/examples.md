# Server Programming Skill Examples

本文件给出 `gql-procedure-generator` 的高频正例与反例，用于稳定技能包输出。

分发约束：示例必须自解释，不依赖“见某页”或“参考某文档”。

## Contents

- Named and inline procedure patterns
- Match-compute and algorithm patterns
- Aggregator and return patterns
- TigerGraph GSQL staged migration
- Distributed tables and procedure arguments
- Negative patterns and placeholder policy

## Positive patterns

### 1. Basic named procedure
Input intent:
- 创建一个无入参、返回整数的命名过程

Output skeleton:
```gql
CREATE PROCEDURE <procedure_name>() RETURNS ret INT AS {
  RETURN 1
}
```

### 2. Procedure with parameters and comment
Input intent:
- 创建一个带默认参数和注释的命名过程

Output skeleton:
```gql
CREATE PROCEDURE <procedure_name>(a INT DEFAULT 1, b STRING DEFAULT 'x')
RETURNS ret INT
COMMENT 'description'
AS {
  RETURN a
}
```

### 3. Alter procedure metadata
Input intent:
- 修改过程描述

Output skeleton:
```gql
ALTER PROCEDURE <procedure_name>(INT, STRING) COMMENT 'new comment'
```

### 4. Drop overloaded procedure
Input intent:
- 删除一个有重载风险的过程

Output skeleton:
```gql
DROP PROCEDURE <procedure_name>(INT, STRING)
```

### 5. Named procedure call
Input intent:
- 调用命名过程并返回全部列

Output skeleton:
```gql
CALL <procedure_name>(<arg_1>, <arg_2>)
RETURN *
```

### 6. Match-compute single-round pattern
Input intent:
- 在活动集上做单轮扩展，并更新下轮 frontier

Output skeleton:
```gql
VALUE frontier ACTIVE_SET
MATCH (a)-[e]->(b) WHERE a IN frontier
PER PATH {
  LOG_INFO('visit edge')
}
FINALLY {
  SET frontier = b
}
```

### 6A. Match-compute edge-local predicate pushdown
Input intent:
- 只沿满足局部属性条件的边扩展活动集

Output skeleton:
```gql
VALUE frontier ACTIVE_SET
MATCH (a)-[e:<edge_type> WHERE e.percent > 0]->(b)
WHERE a IN frontier
PER PATH {
  LOG_INFO('visit eligible edge')
}
FINALLY {
  SET frontier = b
}
```

边属性条件在扩展时直接过滤；活动集条件仍放在 graph pattern `WHERE`。不要先扩展全部边后在 `PER PATH` 中模拟过滤，也不要把单轮 match-compute 扩成多跳 `ACYCLIC`。

### 7. Multi-round algorithm skeleton
Input intent:
- 做多轮按层推进的遍历

Output skeleton:
```gql
VALUE frontier ACTIVE_SET
VALUE depth = 0

WHILE depth < <max_depth> {
  MATCH (a)-[e]->(b) WHERE a IN frontier
  PER PATH {
    LOG_INFO('expand')
  }
  FINALLY {
    SET frontier = b
  }
  SET depth = depth + 1
}

RETURN depth
```

### 8. Node-bound aggregate without unnecessary cast
Input intent:
- 为每个点累计访问次数

Output skeleton:
```gql
NODE VALUE visits SumAgg<INT> = 0
MATCH (a)-[e]->(b)
PER PATH {
  SET a.@visits += 1
}
PER NODE (a) {
  LOG_INFO(a.@visits)
}
```

### 9. Explicit cast only when the target type must be fixed
Input intent:
- 计算相似度，要求除法前把分子稳定成 `DOUBLE`

Output skeleton:
```gql
NODE VALUE intersection SumAgg<INT64> = 0
VALUE union_size INT64 = <union_size>
MATCH (s)-[]->(t)
PER PATH {
  SET t.@intersection += 1
}
PER NODE (t) {
  VALUE similarity DOUBLE = CAST(t.@intersection AS DOUBLE) / union_size
  LOG_INFO(similarity)
}
```

### 10. Aggregator declarations follow initializer syntax
Input intent:
- 定义多种聚合器，并确保只有必须初始化的聚合器才写初始值

Output skeleton:
```gql
VALUE total SumAgg<INT> = 0
VALUE any_hit OrAgg = false
VALUE avg_score AvgAgg<DOUBLE>
VALUE ids ListAgg<INT64>
VALUE seen SetAgg<STRING>
VALUE buckets MapAgg<INT, SumAgg<INT>>
VALUE topk TopKAgg<3, score INT DESC>
```

### 11. Top-k procedure output stays in ordinary return columns
Input intent:
- 返回 top-k 结果时，保持 procedure 出参为普通列，而不是 `LIST<RECORD>`

Output skeleton:
```gql
CREATE PROCEDURE <procedure_name>(...)
RETURNS (node_id INT64, score DOUBLE)
AS {
  ...
  RETURN <node_id_expr> AS node_id, <score_expr> AS score
}
```

### 12. TigerGraph GSQL multi-hop migration stays staged
Input intent:
- 把 TigerGraph GSQL 里按 mode 优先级匹配的多跳 `SELECT` 链迁移成 GQL Procedure

Output skeleton:
```gql
CREATE PROCEDURE <procedure_name>(...)
RETURNS (<result_columns>)
AS {
  TABLE stage_result TYPED TABLE {
    mode_no INT64,
    <stage_columns>
  }

  MATCH (<start_node>)-[e:<EDGE_TYPE_1>]-(<next_node>)
  PER PATH {
    EXPORT <mode_1_row> INTO stage_result
  }

  WHILE <need_next_stage> {
    MATCH (<frontier_node>)-[e:<EDGE_TYPE_N>]-(<next_node>)
    PER PATH {
      EXPORT <stage_n_row> INTO stage_result
    }
  }

  FOR r IN stage_result
  RETURN <final_projection>
}
```

Key rule:
- 保留 mode 顺序，但每个 `MATCH ... PER PATH` 只能做单跳扩展；不要把 GSQL 长链 `SELECT` 直接翻成单个多跳 `MATCH`。

### 13. Distributed table post-processing (5.3.0 Analytics)
Input intent:
- 将分布式匹配结果按分区返回

Output skeleton:
```gql
TABLE result_table TYPED TABLE {id INT, score DOUBLE} PARTITION BY DEFAULT

MATCH (a@<node_type>)
PER NODE (a) {
  EXPORT a.id, <score_expression> INTO result_table
}

PER PARTITION (part) OF result_table {
  FOR r IN part
  RETURN r.id AS id, r.score AS score
}
```

Key rule:
- `PER PARTITION` 内只遍历分区别名 `part`，不要直接访问外层 `result_table`。

### 14. Distributed table procedure argument (5.3.0 Analytics)
Input intent:
- 子过程接收调用方的分布式表并按引用写入

Output skeleton:
```gql
CREATE OR REPLACE PROCEDURE <procedure_name>(t TABLE) AS {
  MATCH (a@<node_type>)
  PER NODE (a) {
    EXPORT a.id, <value_expression> INTO t
  }
}
```

Caller skeleton:
```gql
USE #<analytic_graph> {
  TABLE t TYPED TABLE {id INT, value STRING} PARTITION BY DEFAULT
  CALL <procedure_name>(t) FINISH
  PER PARTITION (part) OF t {
    FOR r IN part
    RETURN r.id, r.value
  }
}
```

Key rule:
- `t TABLE` 可接收分布式表引用，但不因此支持 `size(t)`、直接 `FOR ... IN t` 或其它整表操作。

## Negative patterns
- 不要在 `CREATE PROCEDURE` 体里包 `USE graph` 或 `USE #graph`。
- 不要在用户显式指定本技能时退回普通 `MATCH ... RETURN ...`。
- 不要生成 `NODE VALUE seed_id INT` 这种点绑定标量变量。
- 不要在 `PER PATH` / `PER NODE` 内写 `FOR`。
- 不要直接生成多跳 `match_compute_statement`。
- 不要把全局聚合值变量裸写成 `total_weight`；使用时应写 `@total_weight`。
- 不要把点绑定聚合值变量写成 `a.visits`；使用时应写 `a.@visits`。
- 不要把所有类型差异都机械地改写成 `CAST(... AS ...)`；只有文档不支持隐式转换或目标类型必须固定时才显式转换。
- 不要生成 `OrAgg<BOOLEAN>`、`AndAgg<BOOLEAN>` 这种带类型参数的布尔聚合器声明；应写成 `VALUE flag OrAgg = false`、`VALUE flag AndAgg = true`。
- 不要给 `AvgAgg`、`ListAgg`、`SetAgg`、`MapAgg`、`TopKAgg` 的声明默认补初始值，例如 `VALUE avg AvgAgg<DOUBLE> = 0`、`VALUE ids ListAgg<INT64> = []`、`VALUE topk TopKAgg<3, score INT DESC> = 1` 都是错误方向。
- 不要给 `SetAgg` 生成超过 15 个字符的变量名，例如 `VALUE deduplicated_vertex_ids SetAgg<STRING>` 是高风险写法；应缩短成 `VALUE seen_ids SetAgg<STRING>`、`VALUE frontier SetAgg<STRING>` 这类短名。
- 不要生成 `SumAgg<STRING>`、`AvgAgg<BOOLEAN>`、`MinAgg<RECORD{...}>` 这类非数值聚合器类型参数。
- 不要生成 `SetAgg<BOOLEAN>`、`SetAgg<LIST<INT>>`、`SetAgg<RECORD{...}>` 或其它非键型标量 `SetAgg`。
- 不要生成 `MapAgg<INT64,MapAgg<INT64,SumAgg<DOUBLE>>>`；`MapAgg` 的 value 只能是文档白名单里的嵌套聚合器，不能再嵌套 `MapAgg`。
- 不要把 `TopKAgg` 当成标量聚合器，例如 `SET @topk += 1`、`TopKAgg<3, score LIST<INT> DESC>` 都是错误方向。
- 不要生成 `RETURNS ret LIST<RECORD>`、`RETURNS (rows LIST<RECORD>)` 或把 `TopKAgg` 的内部结果直接作为 procedure 返回类型暴露出去；如果要输出 top-k 记录，改成普通多列返回。
- 不要把 TigerGraph GSQL 的多跳 `SELECT` 链直接照搬成下面这种过程体：

```gql
MATCH (u:unit)-[e1:connected_Unit_CN]-(cn1:CN)-[e2:connected_Breaker_CN]-(b1:Breaker)-[e3:connected_Breaker_CN]-(cn2:CN)-[e4:connected_Bus_CN]-(bus:BUS)
PER PATH {
  ...
}
```

正确方向是保留 mode 顺序，但拆成多轮单跳 `MATCH`，或在信息不足时退回 staged skeleton / planning procedure。
- 不要直接遍历或清空外层分布式表，例如 `FOR r IN t`、`size(t)`、`SET t.clear()`；使用 `PER PARTITION (part) OF t` 并操作 `part`。
- 不要在 `PER PARTITION` 内生成图 `MATCH`、任意过程调用、全局聚合器/活动集访问，或导出到另一个表变量。

## Placeholder policy
- 过程名未知时使用 `<procedure_name>`。
- 参数未知时使用 `<arg_1>`、`<arg_2>`。
- 标签、边、属性未知时使用 `<Tag>`、`<EDGE_TYPE>`、`<property>`。
- 深度未知时使用 `<max_depth>`。
