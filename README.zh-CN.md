# Nebula GQL Skills

[English](README.md)

面向 NebulaGraph GQL 的两个 skill：

- `gql-query-generator`：生成、改写和迁移 GQL 查询。
- `gql-procedure-generator`：生成过程、过程调用、图算法和 TigerGraph GSQL 迁移。

## 兼容版本

Skill 版本使用 GitHub Release tag 表示。下表只维护当前 NebulaGraph 版本对应的最新兼容 skill 版本。

| NebulaGraph 版本 | 最新兼容 skill 版本 | 全量压缩包 |
| --- | --- | --- |
| `5.3.0` | [`v26.09.19_Build1404`](https://github.com/MuYiYong/nebula-gql-skills/releases/tag/v26.09.19_Build1404) | [`nebula-gql-skills-26.09.19.zip`](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/nebula-gql-skills-26.09.19.zip) |

## 使用 CC Switch 安装

1. 打开 **Skills → Repository Management → Add Repository**。
2. 填写 **Owner** `MuYiYong`、**Name** `nebula-gql-skills`、**Branch** `main`、**Subdirectory** `src`。
3. 点击 **Refresh**，然后安装 `gql-query-generator` 或 `gql-procedure-generator`。
4. 需要检查更新时再次点击 **Refresh**，然后使用 skill 卡片上的更新操作。

## 手动安装

从 [最新 Release](https://github.com/MuYiYong/nebula-gql-skills/releases/latest) 下载：

- [两个 skill](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/nebula-gql-skills-26.09.19.zip)
- [`gql-query-generator`](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/gql-query-generator-26.09.19.zip)
- [`gql-procedure-generator`](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/gql-procedure-generator-26.09.19.zip)

解压后，将需要的 skill 目录复制到 Agent 或运行时使用的 skills 目录。目录名保持不变：

```text
gql-query-generator/
gql-procedure-generator/
```

## 如何选择 skill

- 查询、`MATCH`、`WHERE`、`RETURN`、过滤、排序、分页、聚合、子查询和过程调用查询：使用 `gql-query-generator`。
- `CREATE/ALTER/DROP PROCEDURE`、`CALL`、控制流、`match_compute_statement` 和图算法：使用 `gql-procedure-generator`。
- 如果任务需要先定义过程再调用过程，先使用 `gql-procedure-generator`，再使用 `gql-query-generator`。

## 隐私提示

这是公开仓库。不要提交密码、API Key、私有 URL、导出的配置、会话日志、个人数据或本机路径。
