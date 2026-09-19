# Nebula GQL Skills

[简体中文](README.zh-CN.md)

Two skills for NebulaGraph GQL work:

- `gql-query-generator`: generate, rewrite, and migrate GQL queries.
- `gql-procedure-generator`: generate procedures, procedure calls, graph algorithms, and TigerGraph GSQL migrations.

## Compatibility

Skill versions use the GitHub Release tag. The table lists the latest compatible skill release for the current NebulaGraph version.

| NebulaGraph | Latest compatible skill release | All-in-one package |
| --- | --- | --- |
| `5.3.0` | [`v26.09.19_Build1404`](https://github.com/MuYiYong/nebula-gql-skills/releases/tag/v26.09.19_Build1404) | [`nebula-gql-skills-26.09.19.zip`](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/nebula-gql-skills-26.09.19.zip) |

## Install with CC Switch

1. Open **Skills → Repository Management → Add Repository**.
2. Enter **Owner** `MuYiYong`, **Name** `nebula-gql-skills`, **Branch** `main`, and **Subdirectory** `src`.
3. Click **Refresh**, then install `gql-query-generator` or `gql-procedure-generator`.
4. Click **Refresh** again when you want CC Switch to check for updates, then use the skill card's update action.

## Install manually

Download the [latest release](https://github.com/MuYiYong/nebula-gql-skills/releases/latest):

- [Both skills](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/nebula-gql-skills-26.09.19.zip)
- [`gql-query-generator`](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/gql-query-generator-26.09.19.zip)
- [`gql-procedure-generator`](https://github.com/MuYiYong/nebula-gql-skills/releases/download/v26.09.19_Build1404/gql-procedure-generator-26.09.19.zip)

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
