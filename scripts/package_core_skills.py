#!/usr/bin/env python3
"""Package the maintained Nebula skills from src/ into standalone and mega zips."""

from __future__ import annotations

import os
import shutil
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SKILLS_ROOT = ROOT / "src"
DIST_ROOT = ROOT / "dist"
CORE_SKILLS = ("gql-query-generator", "gql-procedure-generator")
ROOT_PACKAGE_DOCS = ("README.md", "README.zh-CN.md")
RELEASE_VERSION = os.environ.get("RELEASE_VERSION") or datetime.now().strftime("%y.%m.%d")
MEGA_BUNDLE_NAME = f"nebula-skills-{RELEASE_VERSION}"


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


def write_feature_index(skill_dir: Path, files: list[Path]) -> None:
    lines = [
        "# Packaged Feature Index",
        "",
        "NebulaGraph 5.3.0 feature assets bundled with this skill:",
        "",
    ]
    lines.extend(f"- {path.relative_to(skill_dir).as_posix()}" for path in files)
    (skill_dir / "FEATURES_INDEX.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


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


def package_skill(spec: PackageSpec) -> tuple[str, int, Path]:
    target_dir = DIST_ROOT / spec.name
    copy_skill_source(spec, target_dir)
    files = feature_files(target_dir)
    if not files:
        raise SystemExit(f"No feature assets found for {spec.name}")
    write_feature_index(target_dir, files)
    remove_old_archives(spec.name)
    archive = create_archive(target_dir, f"{spec.name}-{RELEASE_VERSION}")
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
    return create_archive(bundle_dir, MEGA_BUNDLE_NAME)


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
