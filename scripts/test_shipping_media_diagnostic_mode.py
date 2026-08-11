#!/usr/bin/env python3
from __future__ import annotations

import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ShippingMediaDiagnosticModeTests(unittest.TestCase):
    def test_target_runner_supports_short_steady_mode_without_changing_default_full_run(self):
        runner = (
            REPOSITORY_ROOT / "scripts" / "run-shipping-media-target-acceptance.sh"
        ).read_text(encoding="utf-8")

        required = (
            'RUN_MODE="full"',
            "--run-mode",
            "full|steady",
            'if [[ "$RUN_MODE" == "full" ]]',
            '"runMode": run_mode',
            '"steadySampleCount": reports["steady"]["sampleCount"]',
            'reports["stability"]',
            "stabilitySampleCount",
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, runner)


if __name__ == "__main__":
    unittest.main()
