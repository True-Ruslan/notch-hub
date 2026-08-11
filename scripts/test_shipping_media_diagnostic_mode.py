#!/usr/bin/env python3
from __future__ import annotations

import unittest
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent


class ShippingMediaDiagnosticModeTests(unittest.TestCase):
    def test_target_runner_separates_compact_background_from_expanded_feature_cost(self):
        runner = (
            REPOSITORY_ROOT / "scripts" / "run-shipping-media-target-acceptance.sh"
        ).read_text(encoding="utf-8")

        required = (
            'RUN_MODE="compact-full"',
            "--run-mode",
            "compact-full|expanded-steady",
            'if [[ "$RUN_MODE" == "compact-full" ]]',
            "shipping_media_compact_acceptance.py",
            '"resourceScope": "compact-parent-only"',
            '"runMode": run_mode',
            '"adapterAbsent": True',
            "expanded-steady",
            "Waiting for settled expanded media runtime",
            "shipping_media_acceptance.py\" resources",
            '"steadySampleCount": reports["steady"]["sampleCount"]',
        )
        for fragment in required:
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, runner)


if __name__ == "__main__":
    unittest.main()
