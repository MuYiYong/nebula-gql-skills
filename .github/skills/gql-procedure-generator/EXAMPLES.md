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

### 8. Node-bound aggregate
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

## Negative patterns
- 不要在 `CREATE PROCEDURE` 体里包 `USE graph` 或 `USE #graph`。
- 不要在用户显式指定本技能时退回普通 `MATCH ... RETURN ...`。
- 不要生成 `NODE VALUE seed_id INT` 这种点绑定标量变量。
- 不要在 `PER PATH` / `PER NODE` 内写 `FOR`。
- 不要直接生成多跳 `match_compute_statement`。

## Placeholder policy
- 过程名未知时使用 `<procedure_name>`。
- 参数未知时使用 `<arg_1>`、`<arg_2>`。
- 标签、边、属性未知时使用 `<Tag>`、`<EDGE_TYPE>`、`<property>`。
- 深度未知时使用 `<max_depth>`。