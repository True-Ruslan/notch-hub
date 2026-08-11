#!/usr/bin/env python3
from __future__ import annotations

import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ShellRSSBisectTests(unittest.TestCase):
    def test_runner_compares_exact_v0_1_0_and_m1_candidates_with_same_steady_collector(self):
        runner_path = REPOSITORY_ROOT / "scripts" / "run-shell-rss-bisect.sh"
        self.assertTrue(runner_path.is_file(), "missing shell RSS bisect runner")
        runner = runner_path.read_text(encoding="utf-8") if runner_path.is_file() else ""

        required = (
            "set -euo pipefail",
            "8e913dcddfdec7d9aa920df8c37afb23b8c40884",
            "cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc",
            "505235050",
            "f6de06f5d045fc9375b3b31b0a7feb97a13cebe4",
            "3a6ead1a716e6cf813d2125a7cdecf18a41a3ac2179bf5ca08f5cd4474856945",
            "9021802122",
            "31257399497",
            "hdiutil attach",
            "-readonly",
            "shipping_media_compact_acceptance.py",
            "--mode steady",
            "NSRunningApplication(processIdentifier:",
            ".terminate()",
            '"diagnostic": "shell-rss-bisect"',
            '"baseline":',
            '"m1":',
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, runner)

        self.assertEqual(runner.count("--mode steady"), 2)
        self.assertNotIn("--mode stability", runner)
        for forbidden in ("osascript", "System Events", "kill -9", "pkill"):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, runner)


if __name__ == "__main__":
    unittest.main()
