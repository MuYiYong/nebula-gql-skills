import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

from scripts import package_core_skills as packager


class MegaBundleLayoutTest(unittest.TestCase):
    def test_places_skills_directly_at_archive_root(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            source_root = root / "src"
            dist_root = root / "dist"
            self._write_package_fixture(root, source_root)

            with patch.multiple(
                packager,
                ROOT=root,
                SKILLS_ROOT=source_root,
                DIST_ROOT=dist_root,
                RELEASE_VERSION="99.01.02",
                MEGA_BUNDLE_NAME="nebula-gql-skills-99.01.02",
            ):
                specs = packager.discover_specs()
                standalone_archives = {
                    spec.name: packager.package_skill(spec)[2] for spec in specs
                }
                archive = packager.create_mega_bundle(specs)

            with zipfile.ZipFile(archive) as package:
                files = {
                    item.filename
                    for item in package.infolist()
                    if not item.is_dir()
                }

            self.assertEqual(
                {name.split("/", 1)[0] for name in files},
                {
                    "README.md",
                    "README.zh-CN.md",
                    "gql-query-generator",
                    "gql-procedure-generator",
                },
            )
            self.assertIn("gql-query-generator/SKILL.md", files)
            self.assertIn("gql-procedure-generator/SKILL.md", files)
            self.assertFalse(
                any(".github" in Path(name).parts for name in files),
                "the release archive must not hide skills under .github",
            )

            for skill_name, standalone_archive in standalone_archives.items():
                with zipfile.ZipFile(standalone_archive) as package:
                    standalone_roots = {
                        Path(item.filename).parts[0]
                        for item in package.infolist()
                        if not item.is_dir()
                    }
                self.assertEqual(standalone_roots, {skill_name})

    def test_rejects_unexpected_archive_root_entries(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            dist_root = root / "dist"
            bundle_root = dist_root / "bundle"
            bundle_root.mkdir(parents=True)
            (bundle_root / "README.md").write_text("# Bundle\n", encoding="utf-8")
            (bundle_root / "unexpected.txt").write_text("extra\n", encoding="utf-8")

            with patch.multiple(packager, ROOT=root, DIST_ROOT=dist_root):
                archive = packager.create_archive(
                    bundle_root, "bundle", include_root=False
                )
                with self.assertRaisesRegex(SystemExit, "unexpected root entries"):
                    packager.verify_archive(
                        archive,
                        bundle_root,
                        [],
                        include_root=False,
                        expected_root_entries={"README.md"},
                    )

    def test_rejects_hidden_github_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            dist_root = root / "dist"
            bundle_root = dist_root / "bundle"
            hidden_root = bundle_root / ".github" / "skills"
            hidden_root.mkdir(parents=True)
            (hidden_root / "marker.txt").write_text("hidden\n", encoding="utf-8")

            with patch.multiple(packager, ROOT=root, DIST_ROOT=dist_root):
                archive = packager.create_archive(
                    bundle_root, "bundle", include_root=False
                )
                with self.assertRaisesRegex(SystemExit, "forbidden path component"):
                    packager.verify_archive(
                        archive,
                        bundle_root,
                        [],
                        include_root=False,
                        forbidden_parts={".github"},
                    )

    def _write_package_fixture(self, root: Path, source_root: Path) -> None:
        (root / "README.md").write_text("# English\n", encoding="utf-8")
        (root / "README.zh-CN.md").write_text("# 中文\n", encoding="utf-8")

        for skill_name in packager.CORE_SKILLS:
            skill_root = source_root / skill_name
            (skill_root / "agents").mkdir(parents=True)
            (skill_root / "references").mkdir()
            (skill_root / "tests" / "features").mkdir(parents=True)
            (skill_root / "SKILL.md").write_text(
                "# Skill\n\n[Syntax](references/documented-syntax.md)\n",
                encoding="utf-8",
            )
            (skill_root / "agents" / "openai.yaml").write_text(
                "interface: {}\n", encoding="utf-8"
            )
            (skill_root / "references" / "documented-functions.md").write_text(
                "# Functions\n", encoding="utf-8"
            )
            (skill_root / "references" / "documented-syntax.md").write_text(
                "# Syntax\n", encoding="utf-8"
            )
            (skill_root / "tests" / "features" / "Example.feature").write_text(
                "Feature: example\n", encoding="utf-8"
            )


if __name__ == "__main__":
    unittest.main()
