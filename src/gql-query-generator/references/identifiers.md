# Identifier quoting in generated GQL

For generation, rewriting and repair, quote **both reserved and non-reserved
keywords** with backticks when they serve as identifiers. Match keywords without
regard to case; preserve the identifier's original spelling and case. Ordinary
legal identifiers may remain unquoted.

The complete [keyword catalog](documented-keywords.json) contains 224 reserved
and 207 non-reserved keywords. The Database and Analytics 5.3.0 manuals agree
with the active macros in `src/parser/Keywords.h` at tag `v5.3.0`.
The language permits non-reserved words as regular identifiers; this generation
policy deliberately quotes them too. A policy finding is not proof of a server
syntax error. The keyword catalog does not authorize syntax capabilities.

## Apply to identifier positions

- Graph/schema/procedure names, types and labels, properties and record/table fields.
- Variables, path bindings, procedure formal parameters, output names and aliases.
- Every reference to those names: projections, predicates, sorting/grouping,
  assignments and qualified names. Quote each identifier segment separately.
- Keep the `@` prefix outside a backtick-quoted aggregator name.
- External query parameters such as `$left`, `$right` and `$version` are complete
  lexical tokens, not bare keyword identifiers. Preserve `$name` exactly; do not
  concatenate `$` with a quoted identifier. The server rejects that spelling.
  Procedure formal parameter names are ordinary identifiers and follow the
  keyword-quoting rule.

Do not quote language tokens used for their syntax (`MATCH`, `RETURN`, `AS`,
`ORDER BY`, `TRUE`, `NULL`), data types (`STRING`, `INT64`), or documented
built-in functions (`date(...)`, `CURRENT_DATE`). Keep string values as strings;
changing `'version'` into a quoted identifier changes its meaning.

## Example

Here `schema` is reserved; `date`, `property` and `version` are non-reserved.
`n`, `id` and `person_id` are ordinary identifiers.

```gql
USE `schema`
MATCH (n:`date`)
RETURN n.`property` AS `version`, n.id AS person_id
ORDER BY `version` ASC, person_id ASC
```

The same rule applies to procedure declarations and references:

```gql
VALUE `version` INT64 = 1
RETURN `version` AS `property`
```

## Package tools

From the skill root:

```sh
python3 scripts/skill_tools.py quote-identifiers property version person_id
python3 scripts/skill_tools.py lint candidate.gql --scope database
```

`quote-identifiers` accepts raw individual names and returns a JSON mapping to
their GQL spelling. It also delimits names that cannot be regular identifiers.
Do not pass an expression, qualified name, or already quoted GQL fragment.
Names outside the documented 1..127 character limit, control characters and
embedded backticks require review rather than invented escaping.

Lint checks clear identifier positions and bound references, not a complete
syntax tree. It ignores comments and string values, preserves already quoted
names, and distinguishes CAST type syntax from aliases. An empty lint report
does not prove all identifiers, grammar, types or semantics have been validated.
