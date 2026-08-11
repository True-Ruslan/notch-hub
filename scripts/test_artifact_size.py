#!/usr/bin/env python3
from __future__ import annotations

import pathlib
import tempfile
import unittest

from artifact_size import physical_tree_size_bytes


class ArtifactSizeTests(unittest.TestCase):
    def test_physical_tree_size_counts_regular_payload_once_and_skips_symlink_aliases(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            versions = root / "Framework.framework" / "Versions" / "A"
            versions.mkdir(parents=True)
            binary = versions / "Framework"
            resource = versions / "Resources.txt"
            binary.write_bytes(b"x" * 100)
            resource.write_bytes(b"y" * 23)

            current = root / "Framework.framework" / "Versions" / "Current"
            current.symlink_to("A", target_is_directory=True)
            (root / "Framework.framework" / "Framework").symlink_to(
                "Versions/Current/Framework"
            )
            (root / "Framework.framework" / "Resources.txt").symlink_to(
                "Versions/Current/Resources.txt"
            )

            self.assertEqual(123, physical_tree_size_bytes(root))

    def test_physical_tree_size_counts_top_level_regular_file(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            (root / "payload.bin").write_bytes(b"z" * 7)
            self.assertEqual(7, physical_tree_size_bytes(root))

    def test_physical_tree_size_rejects_missing_or_non_directory_root(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = pathlib.Path(temp_dir)
            file_path = root / "payload.bin"
            file_path.write_bytes(b"z")

            with self.assertRaises(ValueError):
                physical_tree_size_bytes(root / "missing")
            with self.assertRaises(ValueError):
                physical_tree_size_bytes(file_path)


if __name__ == "__main__":
    unittest.main()
