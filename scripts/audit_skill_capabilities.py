#!/usr/bin/env python3
"""Audit positive GQL examples against generated documentation catalogs."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS = ("gql-query-generator", "gql-procedure-generator")
CATALOG_FILES = {"documented-functions.md", "documented-syntax.md"}

FUNCTION_HEADING = re.compile(r"^### `([A-Za-z_][A-Za-z0-9_]*)\(\)`$")
CALL = re.compile(r"(?<![.@$])\b([A-Za-z_][A-Za-z0-9_]*)\s*\(")
MARKDOWN_LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
PROCEDURE_PREFIX = re.compile(
    r"(?:CREATE(?:\s+OR\s+REPLACE)?\s+PROCEDURE|ALTER\s+PROCEDURE|"
    r"DROP\s+PROCEDURE|(?:OPTIONAL\s+)?CALL)\s+(?:IF\s+(?:NOT\s+)?EXISTS\s+)?$",
    flags=re.I,
)
NEGATIVE_MARKERS = (
    "反例",
    "错误示例",
    "无效示例",
    "禁止示例",
    "不要生成",
    "incorrect example",
    "invalid example",
    "negative example",
    "do not generate",
)
STRUCTURAL_WORDS = {
    "acyclic",
    "call",
    "edge",
    "for",
    "graph",
    "if",
    "insert",
    "list",
    "map",
    "match",
    "node",
    "path",
    "record",
    "set",
    "table",
    "trail",
    "tuple",
    "update",
    "vector",
    "walk",
    "while",
}
REQUIRED_DOCUMENTED_CALLS = {
    "coalesce",
    "collect_list",
    "list_distinct",
    "st_geogfromwkt",
    "transform",
}
FORBIDDEN_UNDOCUMENTED_CALLS = {
    "array_distinct",
    "property_exists",
    "toset",
}
REQUIRED_DOCUMENTED_NON_CALLS = {
    "### `CURRENT_TIME`",
    "### `CURRENT_TIMESTAMP`",
    "LIKE pattern: STRING",
}
FORBIDDEN_HIDDEN_DOC_SNIPPETS = {
    "<case abbreviation>",
    "SHORTEST number_of_groups",
    "not supported yet",
}
FORBIDDEN_POLICY_SNIPPETS = {
    "和 [functions.md](functions.md) 中存在精确签名证据",
}
PATH_PUSHDOWN_HEADING = "### M6B. Cypher path predicates to pattern constraints"
PATH_PUSHDOWN_REQUIRED = {
    "MATCH p = ACYCLIC",
    "-[r:股权出资 WHERE r.percent > 0]->{1,6}",
    "(company:Corporation {uid: $uid})",
}
PATH_PUSHDOWN_FORBIDDEN = {
    "size(filter(edges(p), rel -> rel.percent > 0))",
    "size(nodes(p)) = size(list_distinct(nodes(p)))",
}
DUPLICATE_PATH_HEADING = "### M6A. Cypher toSet and list projection"
DUPLICATE_PATH_REQUIRED = {
    "MATCH path = TRAIL",
    "FILTER WHERE length(pathNodes) <> length(list_distinct(pathNodes))",
}
DUPLICATE_PATH_FORBIDDEN = {"MATCH path = ACYCLIC"}
PROCEDURE_PUSHDOWN_REQUIRED = {
    "边局部谓词下推",
    "[e:<edge_type> WHERE <edge_local_predicate>]",
    "不要为谓词下推引入多跳或 `ACYCLIC`",
}


@dataclass(frozen=True)
class CodeBlock:
    path: Path
    line: int
    language: str
    context: str
    code: str


def parse_blocks(path: Path) -> list[CodeBlock]:
    lines = path.read_text(encoding="utf-8").splitlines()
    headings: list[tuple[int, str]] = []
    blocks: list[CodeBlock] = []
    index = 0
    while index < len(lines):
        heading = re.match(r"^(#{1,6})\s+(.*)$", lines[index])
        if heading:
            level = len(heading.group(1))
            headings = [item for item in headings if item[0] < level]
            headings.append((level, heading.group(2)))

        fence = re.match(r"^```([^`]*)$", lines[index])
        if not fence:
            index += 1
            continue

        language = fence.group(1).strip().lower()
        start = index
        index += 1
        body: list[str] = []
        while index < len(lines) and lines[index] != "```":
            body.append(lines[index])
            index += 1
        nearby = " ".join(lines[max(0, start - 4) : start])
        context = " ".join(title for _, title in headings) + " " + nearby
        blocks.append(
            CodeBlock(
                path=path,
                line=start + 1,
                language=language,
                context=context.lower(),
                code="\n".join(body),
            )
        )
        index += 1
    return blocks


def catalog_function_names(skill_root: Path) -> set[str]:
    path = skill_root / "references/documented-functions.md"
    names = {
        match.group(1).lower()
        for line in path.read_text(encoding="utf-8").splitlines()
        if (match := FUNCTION_HEADING.match(line))
    }
    if not names:
        raise SystemExit(f"No function names found in {path.relative_to(ROOT)}")
    return names


def catalog_syntax_calls(skill_root: Path) -> set[str]:
    path = skill_root / "references/documented-syntax.md"
    names: set[str] = set()
    for block in parse_blocks(path):
        if block.language != "text":
            continue
        names.update(
            name.lower()
            for name in re.findall(r"'([A-Za-z_][A-Za-z0-9_]*)'", block.code)
        )
        grammar = block.code.replace("'", "")
        names.update(match.group(1).lower() for match in CALL.finditer(grammar))
    return names


def strip_non_code_values(code: str) -> str:
    code = re.sub(r"--[^\n]*|//[^\n]*", " ", code)
    code = re.sub(r"'(?:''|\\.|[^'])*'", "''", code)
    code = re.sub(r'"(?:\\.|[^"])*"', '""', code)
    return re.sub(r"<[A-Za-z_][A-Za-z0-9_]*>", "", code)


def validate_links(skill_root: Path) -> int:
    checked = 0
    failures: list[str] = []
    for path in sorted(skill_root.rglob("*.md")):
        content = path.read_text(encoding="utf-8")
        for target in MARKDOWN_LINK.findall(content):
            if target.startswith(("#", "http://", "https://", "mailto:")):
                continue
            relative = target.split("#", 1)[0]
            if not relative:
                continue
            checked += 1
            if not (path.parent / relative).resolve().exists():
                failures.append(
                    f"{path.relative_to(ROOT)}: missing Markdown target {target}"
                )
    if failures:
        raise SystemExit("\n".join(failures))
    return checked


def validate_policy(skill_root: Path) -> None:
    failures = []
    for path in sorted(skill_root.rglob("*.md")):
        if path.name in CATALOG_FILES:
            continue
        content = path.read_text(encoding="utf-8")
        for snippet in FORBIDDEN_POLICY_SNIPPETS:
            if snippet in content:
                failures.append(
                    f"{path.relative_to(ROOT)}: high-frequency reference used "
                    "as a second allowlist"
                )
    if failures:
        raise SystemExit("\n".join(failures))


def validate_path_pushdown_regression() -> None:
    query_examples = (
        ROOT / "src/gql-query-generator/references/examples.md"
    ).read_text(encoding="utf-8")
    _, marker, remainder = query_examples.partition(PATH_PUSHDOWN_HEADING)
    section = remainder.split("\n### ", 1)[0] if marker else ""
    failures = []
    if not marker:
        failures.append("query examples: missing path predicate pushdown regression")
    for snippet in sorted(PATH_PUSHDOWN_REQUIRED):
        if snippet not in section:
            failures.append(f"query path pushdown regression: missing {snippet}")
    for snippet in sorted(PATH_PUSHDOWN_FORBIDDEN):
        if snippet in section:
            failures.append(f"query path pushdown regression: redundant {snippet}")

    _, marker, remainder = query_examples.partition(DUPLICATE_PATH_HEADING)
    section = remainder.split("\n### ", 1)[0] if marker else ""
    if not marker:
        failures.append("query examples: missing duplicate-path regression")
    for snippet in sorted(DUPLICATE_PATH_REQUIRED):
        if snippet not in section:
            failures.append(f"query duplicate-path regression: missing {snippet}")
    for snippet in sorted(DUPLICATE_PATH_FORBIDDEN):
        if snippet in section:
            failures.append(f"query duplicate-path regression: invalid {snippet}")

    procedure_rules = "\n".join(
        (ROOT / relative).read_text(encoding="utf-8")
        for relative in (
            "src/gql-procedure-generator/SKILL.md",
            "src/gql-procedure-generator/references/procedure-language.md",
            "src/gql-procedure-generator/references/validation.md",
        )
    )
    for snippet in sorted(PROCEDURE_PUSHDOWN_REQUIRED):
        if snippet not in procedure_rules:
            failures.append(f"procedure path pushdown policy: missing {snippet}")
    if failures:
        raise SystemExit("\n".join(failures))


def is_procedure_name(code: str, start: int) -> bool:
    line_prefix = code[code.rfind("\n", 0, start) + 1 : start]
    return bool(PROCEDURE_PREFIX.search(line_prefix))


def audit_skill(skill_name: str) -> tuple[int, int, int]:
    skill_root = ROOT / "src" / skill_name
    validate_policy(skill_root)
    function_catalog = (
        skill_root / "references/documented-functions.md"
    ).read_text(encoding="utf-8")
    syntax_catalog = (
        skill_root / "references/documented-syntax.md"
    ).read_text(encoding="utf-8")
    functions = catalog_function_names(skill_root)
    missing_required = REQUIRED_DOCUMENTED_CALLS - functions
    forbidden_present = FORBIDDEN_UNDOCUMENTED_CALLS & functions
    if missing_required:
        raise SystemExit(
            f"{skill_name}: required documented calls missing: "
            + ", ".join(sorted(missing_required))
        )
    if forbidden_present:
        raise SystemExit(
            f"{skill_name}: undocumented calls entered the catalog: "
            + ", ".join(sorted(forbidden_present))
        )
    missing_non_calls = {
        item for item in REQUIRED_DOCUMENTED_NON_CALLS if item not in function_catalog
    }
    if missing_non_calls:
        raise SystemExit(
            f"{skill_name}: required documented non-call forms missing: "
            + ", ".join(sorted(missing_non_calls))
        )
    hidden_snippets = {
        item for item in FORBIDDEN_HIDDEN_DOC_SNIPPETS if item in syntax_catalog
    }
    if hidden_snippets:
        raise SystemExit(
            f"{skill_name}: hidden HTML-comment syntax entered the catalog: "
            + ", ".join(sorted(hidden_snippets))
        )
    allowed = functions | catalog_syntax_calls(skill_root)
    failures: list[str] = []
    checked_blocks = 0
    checked_calls = 0

    for path in sorted(skill_root.rglob("*.md")):
        if path.name in CATALOG_FILES:
            continue
        for block in parse_blocks(path):
            if block.language != "gql":
                continue
            if any(marker in block.context for marker in NEGATIVE_MARKERS):
                continue
            checked_blocks += 1
            code = strip_non_code_values(block.code)
            for match in CALL.finditer(code):
                name = match.group(1).lower()
                if name in allowed or name in STRUCTURAL_WORDS:
                    continue
                if is_procedure_name(code, match.start()):
                    continue
                checked_calls += 1
                failures.append(
                    f"{path.relative_to(ROOT)}:{block.line}: undocumented call {match.group(1)}()"
                )

    if failures:
        raise SystemExit("\n".join(failures))
    return checked_blocks, checked_calls, validate_links(skill_root)


def main() -> None:
    validate_path_pushdown_regression()
    total_blocks = 0
    total_unlisted = 0
    total_links = 0
    for skill_name in SKILLS:
        blocks, unlisted, links = audit_skill(skill_name)
        total_blocks += blocks
        total_unlisted += unlisted
        total_links += links
        print(
            f"Validated {skill_name}: {blocks} positive GQL blocks, "
            f"{links} local Markdown links"
        )
    print(
        f"Validated {total_blocks} positive GQL blocks; "
        f"undocumented global calls: {total_unlisted}; local links: {total_links}"
    )


if __name__ == "__main__":
    main()
