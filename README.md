# Nebula GQL Skills

[简体中文](README.zh-CN.md)

Two skills for NebulaGraph GQL work:

- `gql-query-generator`: generate, rewrite, and migrate GQL queries.
- `gql-procedure-generator`: generate procedures, procedure calls, graph algorithms, and TigerGraph GSQL migrations.

## Compatibility

Skill package versions use the version in the archive filename. The table lists the latest compatible skill package for the current NebulaGraph version.

| NebulaGraph | Latest compatible skill release | All-in-one package |
| --- | --- | --- |
| `5.3.0` | `26.09.19` | [Latest release](https://github.com/MuYiYong/nebula-gql-skills/releases/latest) |

## Install with CC Switch

1. Open **Skills → Repository Management → Add Repository**.
2. Enter **Owner** `MuYiYong`, **Name** `nebula-gql-skills`, **Branch** `main`, and **Subdirectory** `src`.
3. Click **Refresh**, then install `gql-query-generator` or `gql-procedure-generator`.
4. Click **Refresh** again when you want CC Switch to check for updates, then use the skill card's update action.

## Install manually

Download the [latest release](https://github.com/MuYiYong/nebula-gql-skills/releases/latest):

- `nebula-gql-skills-<version>.zip` — both skills
- `gql-query-generator-<version>.zip` — query skill only
- `gql-procedure-generator-<version>.zip` — procedure skill only

Download these assets from the [latest release](https://github.com/MuYiYong/nebula-gql-skills/releases/latest).

Extract the archive and copy the required skill directory into the skills directory used by your agent or runtime. Keep the directory name unchanged:

```text
gql-query-generator/
gql-procedure-generator/
```

## Which skill should I use?

- Use `gql-query-generator` for queries, `MATCH`, `WHERE`, `RETURN`, filtering, sorting, paging, aggregation, subqueries, and procedure-call queries.
- Use `gql-procedure-generator` for `CREATE/ALTER/DROP PROCEDURE`, `CALL`, control flow, `match_compute_statement`, and graph algorithms.
- If a task defines a procedure and then calls it, use `gql-procedure-generator` first and `gql-query-generator` second.

## Privacy

This is a public repository. Do not commit passwords, API keys, private URLs, exported configuration, session logs, personal data, or machine-local paths.
