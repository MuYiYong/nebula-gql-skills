# Server Programming Skill Examples

本文件给出 `gql-procedure-generator` 的高频正例与反例，用于稳定技能包输出。

分发约束：示例必须自解释，不依赖“见某页”或“参考某文档”。

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

## Placeholder policy
- 过程名未知时使用 `<procedure_name>`。
- 参数未知时使用 `<arg_1>`、`<arg_2>`。
- 标签、边、属性未知时使用 `<Tag>`、`<EDGE_TYPE>`、`<property>`。
- 深度未知时使用 `<max_depth>`。
