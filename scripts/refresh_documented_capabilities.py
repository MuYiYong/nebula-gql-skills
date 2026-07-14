#!/usr/bin/env python3
"""Generate complete public GQL capability catalogs from rendered user docs."""

from __future__ import annotations

import argparse
import html
import re
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION = "5.3.0"
FUNCTION_SIGNATURE = "\u51fd\u6570\u7b7e\u540d"
SYNTAX = "\u8bed\u6cd5"

QUERY_SYNTAX_ROOTS = (
    "database-gql-reference/dql",
    "database-gql-reference/dml",
    "database-gql-reference/patterns",
    "database-gql-reference/data-types",
    "database-gql-reference/fe/expressions",
    "database-gql-reference/fe/predicates",
    "database-gql-reference/executions",
    "database-gql-reference/set",
)

PROCEDURE_SYNTAX_ROOTS = (
    "analytics-gql-reference/procedures",
    "analytics-gql-reference/dql",
    "analytics-gql-reference/match-compute",
    "analytics-gql-reference/patterns",
    "analytics-gql-reference/server-prog",
    "analytics-gql-reference/variable-definition",
    "analytics-gql-reference/data-types",
    "analytics-gql-reference/control-flow",
    "analytics-gql-reference/statement-block",
    "analytics-gql-reference/ddl",
    "analytics-gql-reference/fe/expressions",
    "analytics-gql-reference/fe/predicates",
    "analytics-gql-reference/executions",
    "analytics-gql-reference/set",
    "analytics-gql-reference/in-out",
    "analytics-gql-reference/log",
    "database-gql-reference/procedures",
    "database-gql-reference/server-prog",
    "database-gql-reference/variable-definition",
    "database-gql-reference/statement-block",
    "database-gql-reference/control-flow",
    "database-gql-reference/dql/call",
    "database-gql-reference/in-out",
    "database-gql-reference/log",
)

AGGREGATOR_NAMES = {
    "avg_agg": "AvgAgg",
    "list_agg": "ListAgg",
    "map_agg": "MapAgg",
    "max_agg": "MaxAgg",
    "min_agg": "MinAgg",
    "set_agg": "SetAgg",
    "sum_agg": "SumAgg",
    "topk_agg": "TopKAgg",
}


@dataclass
class FunctionRecord:
    family: str
    name: str
    database: bool = False
    analytics: bool = False
    signatures: set[str] = field(default_factory=set)
    sources: set[str] = field(default_factory=set)


@dataclass
class FormRecord:
    family: str
    signature: str
    database: bool = False
    analytics: bool = False
    sources: set[str] = field(default_factory=set)


@dataclass(frozen=True)
class MemberRecord:
    receiver: str
    name: str
    signature: str
    source: str


@dataclass(frozen=True)
class SyntaxPage:
    key: str
    title: str
    summary: str
    syntax_blocks: tuple[str, ...]


def clean_text(fragment: str) -> str:
    fragment = re.sub(r"<script\b.*?</script>", " ", fragment, flags=re.I | re.S)
    fragment = re.sub(r"<style\b.*?</style>", " ", fragment, flags=re.I | re.S)
    fragment = re.sub(r"<br\s*/?>", "\n", fragment, flags=re.I)
    fragment = re.sub(r"<[^>]+>", "", fragment)
    value = html.unescape(fragment).replace("\u00b6", "")
    return re.sub(r"\s+", " ", value).strip()


def visible_html(raw: str) -> str:
    return re.sub(r"<!--.*?-->", "", raw, flags=re.S)


def clean_code(fragment: str) -> str:
    fragment = re.sub(r"<br\s*/?>", "\n", fragment, flags=re.I)
    value = html.unescape(re.sub(r"<[^>]+>", "", fragment))
    return "\n".join(line.rstrip() for line in value.strip().splitlines())


def headings(raw: str) -> list[re.Match[str]]:
    return list(
        re.finditer(
            r"<h(?P<level>[1-6])\b[^>]*>(?P<body>.*?)</h(?P=level)>",
            raw,
            flags=re.I | re.S,
        )
    )


def section_end(all_headings: list[re.Match[str]], index: int, raw_length: int) -> int:
    level = int(all_headings[index].group("level"))
    for later in all_headings[index + 1 :]:
        if int(later.group("level")) <= level:
            return later.start()
    return raw_length


def code_blocks(fragment: str) -> list[str]:
    blocks: list[str] = []
    for pre in re.finditer(r"<pre[^>]*>(.*?)</pre>", fragment, flags=re.I | re.S):
        code = re.search(r"<code[^>]*>(.*?)</code>", pre.group(1), flags=re.I | re.S)
        if code:
            value = clean_code(code.group(1))
            if value and value not in blocks:
                blocks.append(value)
    return blocks


def signature_names(signature: str) -> set[str]:
    return {
        name.lower()
        for name in re.findall(
            r"(?m)^\s*(?:\|\s*)?([A-Za-z_][A-Za-z0-9_]*)\s*\(", signature
        )
    }


def relative_key(path: Path, docs_root: Path) -> str:
    key = path.relative_to(docs_root).as_posix()
    return key.removesuffix("index.html")


def extract_scope_functions(
    docs_root: Path, scope: str
) -> tuple[
    dict[tuple[str, str], FunctionRecord], dict[tuple[str, str], FormRecord]
]:
    base = docs_root / f"{scope}-gql-reference/fe/functions"
    if not base.is_dir():
        raise SystemExit(f"Missing {scope} function documentation: {base}")

    records: dict[tuple[str, str], FunctionRecord] = {}
    forms: dict[tuple[str, str], FormRecord] = {}
    for page in sorted(base.glob("*/index.html")):
        family = page.parent.name
        raw = visible_html(page.read_text(encoding="utf-8", errors="ignore"))
        page_headings = headings(raw)
        source = relative_key(page, docs_root)

        for index, heading in enumerate(page_headings):
            if clean_text(heading.group("body")) != FUNCTION_SIGNATURE:
                continue
            end = section_end(page_headings, index, len(raw))
            blocks = code_blocks(raw[heading.end() : end])
            if not blocks:
                raise SystemExit(f"Missing function signature block in {source}")
            for signature in blocks:
                names = signature_names(signature)
                if not names:
                    key = (family, signature)
                    form = forms.setdefault(
                        key, FormRecord(family=family, signature=signature)
                    )
                    setattr(form, scope, True)
                    form.sources.add(source)
                    continue
                for name in names:
                    key = (family, name)
                    record = records.setdefault(
                        key, FunctionRecord(family=family, name=name)
                    )
                    setattr(record, scope, True)
                    record.signatures.add(signature)
                    record.sources.add(source)

        for index, heading in enumerate(page_headings):
            end = section_end(page_headings, index, len(raw))
            section = clean_text(raw[heading.end() : end])
            if "\u5173\u952e\u5b57\u5f62\u5f0f\u7684\u96f6\u53c2\u51fd\u6570" not in section:
                continue
            title = clean_text(heading.group("body"))
            for name in re.findall(r"(?<![A-Za-z0-9_])([A-Z][A-Z0-9_]+)", title):
                key = (family, name)
                form = forms.setdefault(
                    key, FormRecord(family=family, signature=name)
                )
                setattr(form, scope, True)
                form.sources.add(source)

        if scope == "analytics":
            for item in re.findall(r"<li\b[^>]*>(.*?)</li>", raw, flags=re.I | re.S):
                if "database-gql-reference/fe/functions/" not in item:
                    continue
                item_text = clean_text(item)
                for name in re.findall(
                    r"([A-Za-z_][A-Za-z0-9_]*)\s*\(\)",
                    item_text,
                ):
                    key = (family, name.lower())
                    record = records.setdefault(
                        key, FunctionRecord(family=family, name=name.lower())
                    )
                    record.analytics = True
                    record.sources.add(source)
                for name in re.findall(
                    r"(?<![A-Za-z0-9_])(CURRENT_[A-Z0-9_]+)", item_text
                ):
                    key = (family, name)
                    form = forms.setdefault(
                        key, FormRecord(family=family, signature=name)
                    )
                    form.analytics = True
                    form.sources.add(source)
    return records, forms


def merge_functions(
    docs_root: Path,
) -> tuple[
    dict[tuple[str, str], FunctionRecord], dict[tuple[str, str], FormRecord]
]:
    database, database_forms = extract_scope_functions(docs_root, "database")
    analytics, analytics_forms = extract_scope_functions(docs_root, "analytics")
    merged: dict[tuple[str, str], FunctionRecord] = {}
    merged_forms: dict[tuple[str, str], FormRecord] = {}

    for key in sorted(set(database) | set(analytics)):
        db = database.get(key)
        an = analytics.get(key)
        record = FunctionRecord(family=key[0], name=key[1])
        if db:
            record.database = True
            record.signatures.update(db.signatures)
            record.sources.update(db.sources)
        if an:
            record.analytics = True
            record.signatures.update(an.signatures)
            record.sources.update(an.sources)
        if not record.signatures:
            raise SystemExit(f"No public signature found for {key[1]} in family {key[0]}")
        merged[key] = record

    add_coalesce(docs_root, merged)
    for key in sorted(set(database_forms) | set(analytics_forms)):
        db = database_forms.get(key)
        an = analytics_forms.get(key)
        record = FormRecord(family=key[0], signature=key[1])
        if db:
            record.database = True
            record.sources.update(db.sources)
        if an:
            record.analytics = True
            record.sources.update(an.sources)
        merged_forms[key] = record
    return merged, merged_forms


def add_coalesce(
    docs_root: Path, records: dict[tuple[str, str], FunctionRecord]
) -> None:
    sources = []
    for scope in ("database", "analytics"):
        page = docs_root / f"{scope}-gql-reference/fe/expressions/case/index.html"
        raw = visible_html(page.read_text(encoding="utf-8", errors="ignore"))
        if not re.search(r"coalesce\s*\(\s*\)", clean_text(raw), flags=re.I):
            raise SystemExit(f"Missing documented coalesce() expression in {page}")
        sources.append(relative_key(page, docs_root))

    records[("conditional", "coalesce")] = FunctionRecord(
        family="conditional",
        name="coalesce",
        database=True,
        analytics=True,
        signatures={"coalesce(value_expression, value_expression, ...) -> first non-NULL value"},
        sources=set(sources),
    )


def extract_members(docs_root: Path) -> list[MemberRecord]:
    base = docs_root / "analytics-gql-reference/variable-definition/agg"
    members: set[MemberRecord] = set()
    for page in sorted(base.glob("*/index.html")):
        receiver = AGGREGATOR_NAMES.get(page.parent.name)
        if not receiver:
            continue
        raw = visible_html(page.read_text(encoding="utf-8", errors="ignore"))
        page_headings = headings(raw)
        source = relative_key(page, docs_root)
        for index, heading in enumerate(page_headings):
            if clean_text(heading.group("body")) != FUNCTION_SIGNATURE:
                continue
            end = section_end(page_headings, index, len(raw))
            blocks = code_blocks(raw[heading.end() : end])
            if not blocks:
                continue
            signature = blocks[0]
            for name in signature_names(signature):
                members.add(
                    MemberRecord(
                        receiver=receiver,
                        name=name,
                        signature=signature,
                        source=source,
                    )
                )
    return sorted(members, key=lambda item: (item.receiver, item.name, item.signature))


def extract_summary(raw: str, first_heading: re.Match[str]) -> str:
    next_heading = re.search(r"<h[1-6]\b", raw[first_heading.end() :], flags=re.I)
    end = first_heading.end() + next_heading.start() if next_heading else len(raw)
    section = raw[first_heading.end() : end]
    paragraph = re.search(r"<p[^>]*>(.*?)</p>", section, flags=re.I | re.S)
    return clean_text(paragraph.group(1)) if paragraph else ""


def extract_syntax_pages(
    docs_root: Path, roots: tuple[str, ...]
) -> list[SyntaxPage]:
    paths: set[Path] = set()
    for relative in roots:
        base = docs_root / relative
        if not base.exists():
            raise SystemExit(f"Missing syntax documentation root: {base}")
        if base.is_file():
            paths.add(base)
        else:
            paths.update(base.rglob("index.html"))

    pages: list[SyntaxPage] = []
    for page in sorted(paths):
        raw = visible_html(page.read_text(encoding="utf-8", errors="ignore"))
        page_headings = headings(raw)
        if not page_headings:
            continue
        first = next(
            (heading for heading in page_headings if int(heading.group("level")) == 1),
            None,
        )
        if not first:
            continue

        blocks: list[str] = []
        for index, heading in enumerate(page_headings):
            title = clean_text(heading.group("body"))
            if SYNTAX not in title:
                continue
            end = section_end(page_headings, index, len(raw))
            for block in code_blocks(raw[heading.end() : end]):
                if block not in blocks:
                    blocks.append(block)

        pages.append(
            SyntaxPage(
                key=relative_key(page, docs_root),
                title=clean_text(first.group("body")),
                summary=extract_summary(raw, first),
                syntax_blocks=tuple(blocks),
            )
        )
    return pages


def scope_label(record: FunctionRecord | FormRecord) -> str:
    if record.database and record.analytics:
        return "Database and Analytics"
    if record.database:
        return "Database only"
    return "Analytics only"


def render_functions(
    records: dict[tuple[str, str], FunctionRecord],
    forms: dict[tuple[str, str], FormRecord],
    members: list[MemberRecord] | None,
    skill_name: str,
) -> str:
    database_names = {record.name for record in records.values() if record.database}
    analytics_names = {record.name for record in records.values() if record.analytics}
    lines = [
        "# Documented Function Catalog",
        "",
        f"Generated from NebulaGraph `{VERSION}` user documentation by "
        "`scripts/refresh_documented_capabilities.py`. Do not edit manually.",
        "",
        f"This is the complete public function allowlist for `{skill_name}`. "
        "Every listed function may be generated when its documented signature, target "
        "environment, input types, and prerequisites match. Absence from feature files or "
        "high-frequency examples is not a reason to reject a listed function.",
        "",
        "Use exact-name search in this file before retaining or generating a function. "
        "If a name is absent, do not generate it unless the user explicitly provides an installed UDF.",
        "The final non-call section preserves documented operators, expressions, and "
        "keyword-form zero-argument functions; search it by exact keyword when relevant.",
        "",
        "## Coverage",
        "",
        f"- Database documented callable names: `{len(database_names)}`",
        f"- Analytics documented callable names: `{len(analytics_names)}`",
        f"- Shared names: `{len(database_names & analytics_names)}`",
        f"- Documented non-call forms: `{len(forms)}`",
        "- Database-only names: "
        + ", ".join(f"`{name}()`" for name in sorted(database_names - analytics_names)),
        "- Analytics-only names: "
        + (
            ", ".join(f"`{name}()`" for name in sorted(analytics_names - database_names))
            or "none"
        ),
        "",
    ]

    by_family: dict[str, list[FunctionRecord]] = defaultdict(list)
    for record in records.values():
        by_family[record.family].append(record)

    for family in sorted(by_family):
        lines.extend([f"## {family}", ""])
        for record in sorted(by_family[family], key=lambda item: item.name):
            lines.extend(
                [
                    f"### `{record.name}()`",
                    "",
                    f"- Scope: {scope_label(record)}",
                    "- Documentation keys: "
                    + ", ".join(f"`{source}`" for source in sorted(record.sources)),
                    "- Signatures:",
                    "",
                ]
            )
            for signature in sorted(record.signatures):
                lines.extend(["```text", signature, "```", ""])

    if forms:
        lines.extend(
            [
                "## Documented Non-Call Forms",
                "",
                "These public forms are documented beside functions but are operators, "
                "expressions, or keyword-form zero-argument functions rather than ordinary calls.",
                "",
            ]
        )
        for record in sorted(forms.values(), key=lambda item: (item.family, item.signature)):
            title = record.signature.splitlines()[0]
            lines.extend(
                [
                    f"### `{title}`",
                    "",
                    f"- Family: {record.family}",
                    f"- Scope: {scope_label(record)}",
                    "- Documentation keys: "
                    + ", ".join(f"`{source}`" for source in sorted(record.sources)),
                    "- Documented form:",
                    "",
                    "```text",
                    record.signature,
                    "```",
                    "",
                ]
            )

    if members is not None:
        lines.extend(
            [
                "## Analytics Aggregator Member Methods",
                "",
                "These are receiver methods, not global functions. Generate them only on the "
                "documented aggregator type.",
                "",
            ]
        )
        for member in members:
            lines.extend(
                [
                    f"### `{member.receiver}.{member.name}()`",
                    "",
                    "- Scope: Analytics only",
                    f"- Documentation key: `{member.source}`",
                    "- Signature:",
                    "",
                    "```text",
                    member.signature,
                    "```",
                    "",
                ]
            )
    return "\n".join(lines).rstrip() + "\n"


def syntax_category(key: str) -> str:
    parts = key.split("/")
    return parts[1] if len(parts) > 1 else "other"


def render_syntax(pages: list[SyntaxPage], skill_name: str) -> str:
    grammar_count = sum(len(page.syntax_blocks) for page in pages)
    lines = [
        "# Documented Syntax Catalog",
        "",
        f"Generated from NebulaGraph `{VERSION}` user documentation by "
        "`scripts/refresh_documented_capabilities.py`. Do not edit manually.",
        "",
        f"This is the complete documented language-page index for `{skill_name}` within "
        "the skill's declared scope. A listed capability must not be rejected merely because "
        "it lacks a vendored feature or a dedicated example. Apply its documented grammar, "
        "environment, prerequisites, and restrictions; feature/code evidence may only narrow "
        "a verified implementation boundary.",
        "",
        "Search this file by exact keyword, clause, predicate, expression, data type, or "
        "documentation key. Pages without a standalone grammar block remain documented "
        "capabilities; use their summary and the specialized skill references for constraints.",
        "",
        "## Coverage",
        "",
        f"- Documented pages: `{len(pages)}`",
        f"- Extracted syntax blocks: `{grammar_count}`",
        "",
    ]

    grouped: dict[str, list[SyntaxPage]] = defaultdict(list)
    for page in pages:
        grouped[syntax_category(page.key)].append(page)

    for category in sorted(grouped):
        lines.extend([f"## {category}", ""])
        for page in sorted(grouped[category], key=lambda item: item.key):
            lines.extend(
                [
                    f"### {page.title}",
                    "",
                    f"- Documentation key: `{page.key}`",
                ]
            )
            if page.summary:
                lines.append(f"- Summary: {page.summary}")
            if page.syntax_blocks:
                lines.extend(["- Documented syntax:", ""])
                for block in page.syntax_blocks:
                    lines.extend(["```text", block, "```", ""])
            else:
                lines.extend(
                    [
                        "- Documented syntax: no standalone grammar block in the rendered page; "
                        "do not treat the capability as unsupported.",
                        "",
                    ]
                )
    return "\n".join(lines).rstrip() + "\n"


def expected_outputs(docs_root: Path) -> dict[Path, str]:
    functions, forms = merge_functions(docs_root)
    members = extract_members(docs_root)
    query_syntax = extract_syntax_pages(docs_root, QUERY_SYNTAX_ROOTS)
    procedure_syntax = extract_syntax_pages(docs_root, PROCEDURE_SYNTAX_ROOTS)
    return {
        ROOT / "src/gql-query-generator/references/documented-functions.md": render_functions(
            functions, forms, None, "gql-query-generator"
        ),
        ROOT / "src/gql-query-generator/references/documented-syntax.md": render_syntax(
            query_syntax, "gql-query-generator"
        ),
        ROOT / "src/gql-procedure-generator/references/documented-functions.md": render_functions(
            functions, forms, members, "gql-procedure-generator"
        ),
        ROOT / "src/gql-procedure-generator/references/documented-syntax.md": render_syntax(
            procedure_syntax, "gql-procedure-generator"
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--docs-root", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    docs_root = args.docs_root.resolve()
    outputs = expected_outputs(docs_root)
    mismatches = []
    for path, content in outputs.items():
        if args.check:
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                mismatches.append(path.relative_to(ROOT).as_posix())
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")
            print(f"Wrote {path.relative_to(ROOT)}")

    if mismatches:
        raise SystemExit("Catalogs are stale or missing:\n" + "\n".join(mismatches))
    if args.check:
        print(f"Validated {len(outputs)} documented capability catalogs")


if __name__ == "__main__":
    main()
