# Install Nebula Skills

这份文档面向最终使用 zip 发布包的使用者。

This file is for end users who receive the zip release packages.

## 你会拿到什么

发布包通常是以下两个文件中的一个或两个：

Release packages usually include one or both of the following:

- `nebula-skills-v<release_version>.zip`
- `gql-query-generator-v<release_version>.zip`
- `gql-procedure-generator-v<release_version>.zip`

如果你希望一次性安装两个 skill，优先使用 `nebula-skills-v<release_version>.zip`。

If you want both skills in one step, use `nebula-skills-v<release_version>.zip`.

## 安装步骤

1. 打开你的目标工作区。
2. 如果你使用的是 `nebula-skills-v<release_version>.zip`，直接解压到工作区根目录。
3. 如果你使用的是单独 skill 的 zip，先在工作区根目录下确认存在 `.github/skills/` 目录；如果没有，就创建它，然后把 zip 解压到 `.github/skills/` 下。
4. 使用总包时，解压完成后目录应该类似这样：

```text
<workspace>/
  README.md
  README.zh-CN.md
  INSTALL.md
  PROMPTS.md
  .github/
    skills/
      gql-query-generator/
      gql-procedure-generator/
```

5. 使用单独 skill 包时，目录应该类似这样：

```text
.github/skills/
  gql-query-generator/
    SKILL.md
  gql-procedure-generator/
    SKILL.md
```

6. 确认没有出现额外嵌套，例如：

```text
.github/skills/gql-query-generator/gql-query-generator/SKILL.md
```

如果出现这种双层目录，需要把内层目录内容上移一层。

If you see this double nesting, move the inner folder contents up by one level.

## 怎么用

### gql-query-generator

适合让 Copilot 直接帮你生成或改写 GQL 查询。

可直接使用类似提示：

- “生成一个 GQL 查询，返回最近创建的 20 条订单。”
- “把这段需求改成 MATCH 查询。”

More examples are available in `PROMPTS.md`.

### gql-procedure-generator

适合让 Copilot 直接帮你生成或改写 GQL Procedure / UDP。

可直接使用类似提示：

- “生成一个 CREATE PROCEDURE，输入两个点 ID，返回共同邻居。”
- “帮我写一个基于 match_compute_statement 的 BFS 过程。”

More examples are available in `PROMPTS.md`.

## 怎么确认安装成功

检查以下几点：

1. 目录名与 skill 名一致：
   - `gql-query-generator`
   - `gql-procedure-generator`
2. 每个目录里都存在 `SKILL.md`
3. 每个目录里都能看到 `README.md`、`INSTALL.md` 和 `tests/`
4. 如果需要中文说明，根目录或 skill 目录下应存在 `README.zh-CN.md`
5. 如果包内存在 `PROMPTS.md`，可直接用其中的示例提示词验证 skill 是否可调用
6. 若你没有看到 `COVERAGE.md`、`SOURCE_MAP.md`、`VALIDATION.md` 之类文件，这是正常的；这些文件不属于最终面向使用者的发布内容

## 更新方式

如果你拿到了新的 zip 版本，直接用新版本覆盖旧目录即可。

如果你同时修改了本地 skill 内容，建议先备份，再覆盖。
