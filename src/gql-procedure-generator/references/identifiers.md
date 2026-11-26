# Identifier quoting in generated GQL

In generated, rewritten and repaired GQL, enclose **every identifier** in
backticks in its declaration and at each use. Preserve spelling and case.
Apply this when adapting examples from the manual or native feature files.
Replace a name placeholder inside backticks with the actual name. Expression,
type and value placeholders take the syntax of their replacement.

The complete [keyword catalog](documented-keywords.json) contains 224 reserved
and 207 non-reserved keywords. The Database and Analytics 5.3.0 manuals agree
with the active macros in `src/parser/Keywords.h` at tag `v5.3.0`.
The language permits non-reserved words as regular identifiers; this generation
policy deliberately quotes them too. A policy finding is not proof of a server
syntax error. The keyword catalog does not authorize syntax capabilities.

## Graph Type DDL

In each node or edge definition, quote the type name, each label, each property
name inside the braces, and each reference to an endpoint type or key property.
For composite keys, quote each member in its original order. Keep DDL keywords
and scalar type declarations in their grammar form.

```gql
CREATE GRAPH TYPE `LedgerType` AS {
  NODE TYPE `Account` (LABEL `Account` {
    `account_id` STRING, `balance` DECIMAL, `as_of` DATE, PRIMARY KEY (`account_id`)
  }),
  EDGE TYPE `Transfer` (`Account`)-[LABEL `Transfer` {
    `sequence` INT64, MULTIEDGE KEY (`sequence`)
  }]->(`Account`)
}
```

A bare property named `balance` collides with the reserved keyword `BALANCE`.
For a 42001 at a property, check the whole definition and its key lists with
the bundled lint command. Preserve the supplied numeric precision and scale.

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
  same quoting rule. Temporary graph tokens (`#name`) also retain their prefix
  and unquoted spelling. The 5.3.x scanner matches the whole token.
- Inside optimizer hint comments, the separate hint grammar accepts regular
  identifiers for index and configuration arguments (e.g. `/*+ INDEX(idx) */`).
  Use the native hint spelling when the request calls for a hint.
- In a schema path, delimit each name between separators. In a type set,
  label expression or list of output columns, delimit each name individually.
  Preserve the operators and the syntax of built-in types and methods.

Do not quote language tokens used for their syntax (`MATCH`, `RETURN`, `AS`,
`ORDER BY`, `TRUE`, `NULL`), data types (`STRING`, `INT64`), or documented
built-in functions (`date(...)`, `CURRENT_DATE`). Keep string values as strings;
changing `'version'` into a quoted identifier changes its meaning.

Write NULL tests as `IS NULL` and `IS NOT NULL`. Quote only identifiers in the
operand. A property named `NOT` still needs backticks when used as a name.

```gql
MATCH (`n`:`Report`)
WHERE `n`.`NOT` IS NOT NULL OR `n`.`branch_code` IS NULL
RETURN `n`.`branch_code` AS `code`
```

## Example

Here `schema` is reserved; `date`, `property` and `version` are non-reserved.
`n`, `id` and `person_id` are ordinary identifiers.

```gql
USE `schema`
MATCH (`n`:`date`)
RETURN `n`.`property` AS `version`, `n`.`id` AS `person_id`
ORDER BY `version` ASC, `person_id` ASC
```

The element type predicate and its operand follow the same rule.

```gql
MATCH (`p`@![`Type`, `Archived`])
RETURN `p`.`name` AS `match`
```

The same rule applies to procedure declarations and references.

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
their GQL spelling. It applies the same delimiters to ordinary and keyword names.
Do not pass an expression, qualified name, or already quoted GQL fragment.
Names outside the documented 1..127 character limit, control characters and
embedded backticks or a leading `@` require review rather than invented escaping.

Lint checks clear identifier positions and bound references, not a complete
syntax tree. It ignores comments and string values, preserves already quoted
names, and distinguishes CAST type syntax from aliases. An empty lint report
does not prove all identifiers, grammar, types or semantics have been validated.
