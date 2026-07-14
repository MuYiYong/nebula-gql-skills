#!/usr/bin/env python3
"""Package the maintained Nebula skills from src/ into standalone and mega zips."""

from __future__ import annotations

import os
import posixpath
import re
import shutil
import stat
import zipfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path, PurePosixPath
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / "src"
DIST_ROOT = ROOT / "dist"
CORE_SKILLS = ("gql-query-generator", "gql-procedure-generator")
ROOT_PACKAGE_DOCS = ("README.md", "README.zh-CN.md")
RELEASE_VERSION = os.environ.get("RELEASE_VERSION") or datetime.now().strftime("%y.%m.%d")
MEGA_BUNDLE_NAME = f"nebula-skills-{RELEASE_VERSION}"
MARKDOWN_LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
LOCAL_WORKSPACE_PATH = re.compile(
    rb"(?:/(?:Users|home)/[^/\s]+/(?:Documents|Desktop|Downloads|workspace)/"
    rb"|[A-Za-z]:\\Users\\[^\\\s]+\\(?:Documents|Desktop|Downloads|workspace)\\)"
)
TEXT_SUFFIXES = {
    ".feature",
    ".json",
    ".md",
    ".py",
    ".sh",
    ".toml",
    ".txt",
    ".yaml",
    ".yml",
}
REQUIRED_SKILL_FILES = {
    "SKILL.md",
    "agents/openai.yaml",
    "references/documented-functions.md",
    "references/documented-syntax.md",
    "FEATURES_INDEX.md",
}


@dataclass(frozen=True)
class PackageSpec:
    name: str
    source_dir: Path


def discover_specs() -> list[PackageSpec]:
    specs: list[PackageSpec] = []
    for name in CORE_SKILLS:
        source_dir = SKILLS_ROOT / name
        if not (source_dir / "SKILL.md").is_file():
            raise SystemExit(f"Missing skill source: {source_dir / 'SKILL.md'}")
        specs.append(PackageSpec(name=name, source_dir=source_dir))
    return specs


def copy_skill_source(spec: PackageSpec, target_dir: Path) -> None:
    if target_dir.exists():
        shutil.rmtree(target_dir)
    shutil.copytree(
        spec.source_dir,
        target_dir,
        ignore=shutil.ignore_patterns(".DS_Store", "__pycache__", "*.pyc"),
    )


def feature_files(skill_dir: Path) -> list[Path]:
    return sorted((skill_dir / "tests" / "features").rglob("*.feature"))


def render_feature_index(relative_paths: list[str]) -> str:
    lines = [
        "# Packaged Feature Index",
        "",
        "NebulaGraph 5.3.0 feature assets bundled with this skill:",
        "",
    ]
    lines.extend(f"- {path}" for path in relative_paths)
    return "\n".join(lines) + "\n"


def write_feature_index(skill_dir: Path, files: list[Path]) -> None:
    relative_paths = [path.relative_to(skill_dir).as_posix() for path in files]
    (skill_dir / "FEATURES_INDEX.md").write_text(
        render_feature_index(relative_paths), encoding="utf-8"
    )


def remove_old_archives(prefix: str) -> None:
    for archive in DIST_ROOT.glob(f"{prefix}-*.zip"):
        archive.unlink()


def create_archive(directory: Path, archive_stem: str) -> Path:
    archive_path = DIST_ROOT / f"{archive_stem}.zip"
    if archive_path.exists():
        archive_path.unlink()
    shutil.make_archive(
        str(DIST_ROOT / archive_stem),
        "zip",
        root_dir=DIST_ROOT,
        base_dir=directory.name,
    )
    return archive_path


def directory_payload(directory: Path) -> dict[str, bytes]:
    return {
        f"{directory.name}/{path.relative_to(directory).as_posix()}": path.read_bytes()
        for path in sorted(directory.rglob("*"))
        if path.is_file()
    }


def archive_payload(archive: Path) -> dict[str, bytes]:
    payload: dict[str, bytes] = {}
    with zipfile.ZipFile(archive) as package:
        for item in package.infolist():
            archive_name = item.filename.rstrip("/")
            path = PurePosixPath(archive_name)
            if (
                not archive_name
                or "\\" in item.filename
                or path.as_posix() != archive_name
                or path.is_absolute()
                or ".." in path.parts
            ):
                raise SystemExit(
                    f"Package verification failed for {archive.name}: unsafe path {item.filename}"
                )
            mode = (item.external_attr >> 16) & 0o170000
            if mode == stat.S_IFLNK:
                raise SystemExit(
                    f"Package verification failed for {archive.name}: symlink {item.filename}"
                )
            if item.is_dir():
                continue
            if archive_name in payload:
                raise SystemExit(
                    f"Package verification failed for {archive.name}: duplicate {item.filename}"
                )
            payload[archive_name] = package.read(item)
    return payload


def summarize_paths(paths: set[str]) -> str:
    ordered = sorted(paths)
    summary = ", ".join(ordered[:5])
    if len(ordered) > 5:
        summary += f", ... ({len(ordered)} total)"
    return summary


def markdown_target(raw_target: str) -> str:
    target = raw_target.strip()
    if target.startswith("<") and ">" in target:
        return target[1 : target.index(">")]
    return target.split(maxsplit=1)[0]


def validate_markdown_links(
    archive: Path, payload: dict[str, bytes], skill_root: str
) -> int:
    checked = 0
    prefix = f"{skill_root}/"
    for name, data in sorted(payload.items()):
        if not name.startswith(prefix) or not name.endswith(".md"):
            continue
        relative_name = name.removeprefix(prefix)
        content = data.decode("utf-8")
        for raw_target in MARKDOWN_LINK.findall(content):
            target = markdown_target(raw_target)
            if target.startswith(("#", "http://", "https://", "mailto:")):
                continue
            target_path = unquote(target.split("#", 1)[0].split("?", 1)[0])
            if not target_path:
                continue
            if target_path.startswith("/") or re.match(r"^[A-Za-z]:", target_path):
                raise SystemExit(
                    f"Package verification failed for {archive.name}: "
                    f"absolute Markdown target {target} in {name}"
                )
            relative_target = posixpath.normpath(
                posixpath.join(posixpath.dirname(relative_name), target_path)
            )
            if relative_target == ".." or relative_target.startswith("../"):
                raise SystemExit(
                    f"Package verification failed for {archive.name}: "
                    f"Markdown target escapes skill root in {name}: {target}"
                )
            packaged_target = f"{prefix}{relative_target}"
            if packaged_target not in payload:
                raise SystemExit(
                    f"Package verification failed for {archive.name}: "
                    f"missing Markdown target {target} in {name}"
                )
            checked += 1
    return checked


def validate_skill_payload(
    archive: Path, payload: dict[str, bytes], skill_root: str
) -> tuple[int, int]:
    prefix = f"{skill_root}/"
    relative_files = {
        name.removeprefix(prefix) for name in payload if name.startswith(prefix)
    }
    missing = REQUIRED_SKILL_FILES - relative_files
    if missing:
        raise SystemExit(
            f"Package verification failed for {archive.name}: "
            f"missing required skill files: {summarize_paths(missing)}"
        )

    features = sorted(
        name
        for name in relative_files
        if name.startswith("tests/features/") and name.endswith(".feature")
    )
    if not features:
        raise SystemExit(
            f"Package verification failed for {archive.name}: no packaged feature assets"
        )
    expected_index = render_feature_index(features).encode("utf-8")
    if payload[f"{prefix}FEATURES_INDEX.md"] != expected_index:
        raise SystemExit(
            f"Package verification failed for {archive.name}: stale FEATURES_INDEX.md"
        )

    return len(features), validate_markdown_links(archive, payload, skill_root)


def verify_archive(archive: Path, directory: Path, skill_roots: list[str]) -> None:
    expected = directory_payload(directory)
    actual = archive_payload(archive)
    missing = set(expected) - set(actual)
    extra = set(actual) - set(expected)
    changed = {
        name
        for name in expected.keys() & actual.keys()
        if expected[name] != actual[name]
    }
    if missing or extra or changed:
        details = []
        if missing:
            details.append(f"missing {summarize_paths(missing)}")
        if extra:
            details.append(f"extra {summarize_paths(extra)}")
        if changed:
            details.append(f"changed {summarize_paths(changed)}")
        raise SystemExit(
            f"Package verification failed for {archive.name}: " + "; ".join(details)
        )

    for name, data in actual.items():
        is_text = PurePosixPath(name).suffix.lower() in TEXT_SUFFIXES
        if is_text and LOCAL_WORKSPACE_PATH.search(data):
            raise SystemExit(
                f"Package verification failed for {archive.name}: local workspace path in {name}"
            )

    feature_count = 0
    link_count = 0
    for skill_root in skill_roots:
        features, links = validate_skill_payload(archive, actual, skill_root)
        feature_count += features
        link_count += links
    print(
        f"Verified {archive.relative_to(ROOT)}: {len(actual)} files, "
        f"{feature_count} feature assets, {link_count} local Markdown links"
    )


def package_skill(spec: PackageSpec) -> tuple[str, int, Path]:
    target_dir = DIST_ROOT / spec.name
    copy_skill_source(spec, target_dir)
    files = feature_files(target_dir)
    if not files:
        raise SystemExit(f"No feature assets found for {spec.name}")
    write_feature_index(target_dir, files)
    remove_old_archives(spec.name)
    archive = create_archive(target_dir, f"{spec.name}-{RELEASE_VERSION}")
    verify_archive(archive, target_dir, [target_dir.name])
    return spec.name, len(files), archive


def create_mega_bundle(specs: list[PackageSpec]) -> Path:
    bundle_dir = DIST_ROOT / MEGA_BUNDLE_NAME
    if bundle_dir.exists():
        shutil.rmtree(bundle_dir)

    skills_dir = bundle_dir / ".github" / "skills"
    skills_dir.mkdir(parents=True)
    for doc_name in ROOT_PACKAGE_DOCS:
        source = ROOT / doc_name
        if source.is_file():
            shutil.copy2(source, bundle_dir / doc_name)

    for spec in specs:
        shutil.copytree(DIST_ROOT / spec.name, skills_dir / spec.name)

    remove_old_archives("nebula-skills")
    archive = create_archive(bundle_dir, MEGA_BUNDLE_NAME)
    skill_roots = [
        f"{bundle_dir.name}/.github/skills/{spec.name}" for spec in specs
    ]
    verify_archive(archive, bundle_dir, skill_roots)
    return archive


def main() -> None:
    specs = discover_specs()
    DIST_ROOT.mkdir(parents=True, exist_ok=True)

    summaries = [package_skill(spec) for spec in specs]
    mega_archive = create_mega_bundle(specs)

    for name, count, archive in summaries:
        print(f"Packaged {name}: {count} feature files -> {archive.relative_to(ROOT)}")
    print(f"Packaged mega bundle -> {mega_archive.relative_to(ROOT)}")
    print(f"Package version: {RELEASE_VERSION}")


if __name__ == "__main__":
    main()
