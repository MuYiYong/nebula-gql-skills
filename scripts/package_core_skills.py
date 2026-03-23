from __future__ import annotations

import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
import os
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SKILLS_ROOT = ROOT / ".github" / "skills"
DIST_ROOT = ROOT / "dist"
EXCLUDED_SKILLS = {"planning-with-files"}


def resolve_release_version() -> str:
    value = os.getenv("RELEASE_VERSION", "").strip()
    if value:
        return value
    return datetime.now(timezone.utc).strftime("%Y%m%d")


RELEASE_VERSION = resolve_release_version()
MEGA_BUNDLE_NAME = f"nebula-skills-v{RELEASE_VERSION}"
ROOT_PACKAGE_DOCS = (
    "README.md",
    "README.zh-CN.md",
    "INSTALL.md",
    "PROMPTS.md",
)
PACKAGE_TOP_LEVEL_KEEP = {
    "EXAMPLES.md",
    "FEATURES_INDEX.md",
    "INSTALL.md",
    "PROMPTS.md",
    "README.md",
    "README.zh-CN.md",
    "SKILL.md",
    "tests",
}


@dataclass(frozen=True)
class PackageSpec:
    source_dir: Path
    manifest_path: Path

    @property
    def name(self) -> str:
        return self.source_dir.name


def discover_specs() -> list[PackageSpec]:
    specs: list[PackageSpec] = []
    for skill_dir in sorted(SKILLS_ROOT.iterdir()):
        if not skill_dir.is_dir() or skill_dir.name in EXCLUDED_SKILLS:
            continue
        manifest_path = skill_dir / "FEATURES.manifest"
        if manifest_path.exists():
            specs.append(PackageSpec(source_dir=skill_dir, manifest_path=manifest_path))
    return specs


def read_manifest(manifest_path: Path) -> list[str]:
    patterns: list[str] = []
    for raw_line in manifest_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        patterns.append(line)
    return patterns


def resolve_feature_files(patterns: list[str]) -> list[Path]:
    files: set[Path] = set()
    missing_patterns: list[str] = []
    for pattern in patterns:
        matches = [path for path in ROOT.glob(pattern) if path.is_file()]
        if not matches:
            missing_patterns.append(pattern)
            continue
        files.update(matches)
    if missing_patterns:
        missing = "\n".join(f"- {pattern}" for pattern in missing_patterns)
        raise SystemExit(f"Manifest patterns matched no files:\n{missing}")
    return sorted(files)


def copy_skill_source(source_dir: Path, target_dir: Path) -> None:
    shutil.copytree(source_dir, target_dir, dirs_exist_ok=True)


def copy_package_docs(target_dir: Path) -> None:
    for doc_name in ROOT_PACKAGE_DOCS:
        shutil.copy2(ROOT / doc_name, target_dir / doc_name)


def cleanup_target_dir(target_dir: Path) -> None:
    for child in target_dir.iterdir():
        if child.name in PACKAGE_TOP_LEVEL_KEEP:
            continue
        if child.is_dir():
            shutil.rmtree(child)
        else:
            child.unlink()


def cleanup_duplicate_test_dirs(target_dir: Path) -> None:
    for child in target_dir.iterdir():
        if not child.is_dir():
            continue
        if child.name.startswith("tests "):
            shutil.rmtree(child)


def copy_feature_files(feature_files: list[Path], target_dir: Path) -> None:
    features_target = target_dir / "tests" / "features"
    for feature_file in feature_files:
        relative = feature_file.relative_to(ROOT / "features")
        destination = features_target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(feature_file, destination)


def write_feature_index(feature_files: list[Path], target_dir: Path) -> None:
    lines = [
        "# Packaged Feature Index",
        "",
        "The following test assets were bundled into this distribution package.",
        "",
    ]
    lines.extend(f"- features/{feature_file.relative_to(ROOT / 'features').as_posix()}" for feature_file in feature_files)
    (target_dir / "FEATURES_INDEX.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def create_archive(package_dir: Path) -> Path:
    archive_base = DIST_ROOT / f"{package_dir.name}-v{RELEASE_VERSION}"
    archive_path = archive_base.with_suffix(".zip")
    for existing_archive in DIST_ROOT.glob(f"{package_dir.name}*.zip"):
        existing_archive.unlink()
    shutil.make_archive(str(archive_base), "zip", root_dir=DIST_ROOT, base_dir=package_dir.name)
    return archive_path


def create_named_archive(directory: Path, archive_stem: str) -> Path:
    archive_base = DIST_ROOT / archive_stem
    archive_path = archive_base.with_suffix(".zip")
    if archive_path.exists():
        archive_path.unlink()
    shutil.make_archive(str(archive_base), "zip", root_dir=DIST_ROOT, base_dir=directory.name)
    return archive_path


def create_mega_bundle(specs: list[PackageSpec]) -> Path:
    bundle_dir = DIST_ROOT / MEGA_BUNDLE_NAME
    if bundle_dir.exists():
        shutil.rmtree(bundle_dir)

    (bundle_dir / ".github" / "skills").mkdir(parents=True, exist_ok=True)
    for doc_name in ROOT_PACKAGE_DOCS:
        shutil.copy2(ROOT / doc_name, bundle_dir / doc_name)

    for spec in specs:
        packaged_skill_dir = DIST_ROOT / spec.name
        target_skill_dir = bundle_dir / ".github" / "skills" / spec.name
        shutil.copytree(packaged_skill_dir, target_skill_dir, dirs_exist_ok=True)

    return create_named_archive(bundle_dir, MEGA_BUNDLE_NAME)


def package_skill(spec: PackageSpec) -> tuple[str, int, Path]:
    target_dir = DIST_ROOT / spec.name
    if target_dir.exists():
        shutil.rmtree(target_dir)
    copy_skill_source(spec.source_dir, target_dir)
    copy_package_docs(target_dir)
    feature_files = resolve_feature_files(read_manifest(spec.manifest_path))
    copy_feature_files(feature_files, target_dir)
    write_feature_index(feature_files, target_dir)
    cleanup_target_dir(target_dir)
    archive_path = create_archive(target_dir)
    cleanup_target_dir(target_dir)
    cleanup_duplicate_test_dirs(target_dir)
    return spec.name, len(feature_files), archive_path


def main() -> None:
    specs = discover_specs()
    if not specs:
        raise SystemExit("No core skill manifests found.")

    DIST_ROOT.mkdir(parents=True, exist_ok=True)
    summaries = [package_skill(spec) for spec in specs]
    mega_bundle_archive = create_mega_bundle(specs)

    excluded = ", ".join(sorted(EXCLUDED_SKILLS))
    print(f"Excluded skills from distribution: {excluded}")
    for name, count, archive_path in summaries:
        print(f"Packaged {name}: {count} feature files -> {archive_path.relative_to(ROOT)}")
    print(f"Packaged mega bundle -> {mega_bundle_archive.relative_to(ROOT)}")
    print(f"Release version: v{RELEASE_VERSION}")


if __name__ == "__main__":
    main()
