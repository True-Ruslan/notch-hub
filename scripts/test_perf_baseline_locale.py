#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import os
import pathlib
import subprocess
import unittest
from unittest import mock

from performance_policy import ProcessSample


def _load_perf_baseline_module():
    path = pathlib.Path(__file__).with_name("perf-baseline.py")
    spec = importlib.util.spec_from_file_location("perf_baseline_under_test", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PerfBaselineLocaleTests(unittest.TestCase):
    def test_process_sampling_forces_c_locale_and_preserves_parent_environment(self):
        module = _load_perf_baseline_module()
        calls: list[tuple[list[str], dict[str, object]]] = []

        def fake_run(args, **kwargs):
            calls.append((list(args), dict(kwargs)))
            if args[:3] == ["/bin/ps", "-p", "42"] and "%cpu=" in args:
                return subprocess.CompletedProcess(args, 0, stdout=" 1.2  58464\n", stderr="")
            if args[:3] == ["/bin/ps", "-M", "42"]:
                return subprocess.CompletedProcess(
                    args,
                    0,
                    stdout=(
                        "PID TT STAT TIME COMMAND\n"
                        "42 ?? S 0:00.01 App\n"
                        "42 ?? S 0:00.00 App\n"
                        "42 ?? S 0:00.00 App\n"
                    ),
                    stderr="",
                )
            raise AssertionError(f"Unexpected subprocess args: {args!r}")

        with mock.patch.dict(
            os.environ,
            {
                "LC_ALL": "pl_PL.UTF-8",
                "LANG": "pl_PL.UTF-8",
                "NOTCHHUB_TEST_SENTINEL": "preserve-me",
            },
            clear=False,
        ):
            with mock.patch.object(module.subprocess, "run", side_effect=fake_run):
                sample = module._sample_process(42)

        self.assertEqual(ProcessSample(1.2, 58464, 3), sample)
        self.assertEqual(2, len(calls))
        for args, kwargs in calls:
            with self.subTest(args=args):
                environment = kwargs.get("env")
                self.assertIsInstance(environment, dict)
                self.assertEqual("C", environment.get("LC_ALL"))
                self.assertEqual("preserve-me", environment.get("NOTCHHUB_TEST_SENTINEL"))


if __name__ == "__main__":
    unittest.main()
