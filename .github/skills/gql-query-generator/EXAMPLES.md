# Query Skill Examples

本文件给出 `gql-query-generator` 的高频正例与边界例。示例都基于本地 `site-zh` 查询章节整理，用于稳定输出风格。

分发约束：示例必须自解释，不依赖“见某页”或“参考某文档”。

## Positive patterns

### 1. Basic match with filter
Input intent:
- 查找 2024 年后创建的用户，返回姓名和邮箱

Output skeleton:
```gql
MATCH (u:<UserTag>)
WHERE u.<created_at> > <date_value>
RETURN u.<name> AS name, u.<email> AS email
```

### 2. Sorted page query
Input intent:
- 查最近创建的 20 条订单，跳过前 40 条

Output skeleton:
```gql
MATCH (o:<OrderTag>)
RETURN o.<id> AS id, o.<created_at> AS created_at
ORDER BY o.<created_at> DESC
OFFSET 40
LIMIT 20
```

### 3. Aggregate query
Input intent:
- 按城市统计用户数

Output skeleton:
```gql
MATCH (u:<UserTag>)
RETURN u.<city> AS city, count(u) AS user_count
GROUP BY u.<city>
```

### 4. Named procedure call
Input intent:
- 调用某个过程并返回全部结果

Output skeleton:
```gql
CALL <procedure_name>(<arg_1>, <arg_2>)
RETURN *
```

### 5. Named procedure call with yield
Input intent:
- 调用过程后只取 name 和 score 两列

Output skeleton:
```gql
CALL <procedure_name>(<arg_1>) YIELD name, score
RETURN name, score
ORDER BY score DESC
```

### 6. Inline procedure composition
Input intent:
- 先执行一段查询，再对结果做外层排序和分页

Output skeleton:
```gql
CALL {
  MATCH (n:<Tag>)
  RETURN n.<field> AS field, n.<score> AS score
}
RETURN field, score
ORDER BY score DESC
LIMIT 10
```

## Negative patterns
- 不要把普通检索需求改写成 `CREATE PROCEDURE`。
- 不要输出只有 `CALL` 没有结果语句的查询。
- 不要在没有稳定规则时主动引入 `USE`、`LET`、`FOR`、`SAMPLE`。
- 不要把图算法或逐轮遍历需求伪装成普通查询。

## Placeholder policy
- 标签未知时使用 `<Tag>`。
- 边类型未知时使用 `<EDGE_TYPE>`。
- 属性未知时使用 `<property>`。
- 过程名未知时使用 `<procedure_name>`。
- 参数未知时使用 `<arg_1>`、`<arg_2>`。