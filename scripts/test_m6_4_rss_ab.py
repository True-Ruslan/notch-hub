#!/usr/bin/env python3
from __future__ import annotations

import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class M64RSSABTests(unittest.TestCase):
    def test_runner_compares_exact_v0_1_0_and_frozen_m6_4_with_one_shared_collector(self):
        runner_path = REPOSITORY_ROOT / "scripts" / "run-m6-4-rss-ab.sh"
        self.assertTrue(runner_path.is_file(), "missing M6.4 RSS A/B runner")
        runner = runner_path.read_text(encoding="utf-8") if runner_path.is_file() else ""

        required = (
            "set -euo pipefail",
            "8e913dcddfdec7d9aa920df8c37afb23b8c40884",
            "cf53be6081b1836551fcbbb91b85fed800de4c089451961f3c6a21f6b77768bc",
            "505235050",
            "fdbe987d8f22768b2a75406c8f1e721fa1da2845",
            "6371e8695e30f06697d37d2d018e043674e8b27a44022e3d8e846d0e1dad01fd",
            "9093958828",
            "31472420797",
            "shipping_media_compact_acceptance.py",
            "--mode steady",
            "NSRunningApplication(processIdentifier:",
            ".terminate()",
            '"diagnostic": "m6.4-rss-ab"',
            '"baseline":',
            '"candidate":',
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, runner)

        self.assertEqual(runner.count("shipping_media_compact_acceptance.py"), 1)
        self.assertEqual(runner.count("--mode steady"), 1)
        self.assertNotIn("--mode stability", runner)
        for forbidden in ("osascript", "System Events", "kill -9", "pkill"):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, runner)


if __name__ == "__main__":
    unittest.main()
