#!/usr/bin/env python3
from __future__ import annotations

import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ShellOnlyTargetDiagnosticTests(unittest.TestCase):
    def test_runner_pins_exact_m6_3_shell_only_candidate_and_collects_parent_only_evidence(self):
        runner_path = REPOSITORY_ROOT / "scripts" / "run-shell-only-target-diagnostic.sh"
        self.assertTrue(runner_path.is_file(), "missing shell-only target diagnostic runner")
        runner = runner_path.read_text(encoding="utf-8") if runner_path.is_file() else ""

        required = (
            "set -euo pipefail",
            "30de94c0cb6ea17dc21bd366404937db2bc73783",
            "b1da6681ce49da3c34b3720c39caa32c3fc4508e0abf7d209b63b46f78713fb7",
            "9063213178",
            "31389611697",
            "hdiutil attach",
            "-readonly",
            "shipping_media_compact_acceptance.py",
            "--mode steady",
            "--mode stability",
            "NSRunningApplication(processIdentifier:",
            ".terminate()",
            '"resourceScope": "compact-parent-only"',
            '"adapterAbsent": True',
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, runner)

        for forbidden in ("osascript", "System Events", "kill -9", "pkill"):
            with self.subTest(forbidden=forbidden):
                self.assertNotIn(forbidden, runner)


if __name__ == "__main__":
    unittest.main()
