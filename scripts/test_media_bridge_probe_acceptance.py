import importlib.util
import json
import pathlib
import tempfile
import unittest


SCRIPT_PATH = pathlib.Path(__file__).with_name("media-bridge-probe-acceptance.py")
SPEC = importlib.util.spec_from_file_location("media_bridge_probe_acceptance", SCRIPT_PATH)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class MediaBridgeProbeAcceptanceTests(unittest.TestCase):
    def test_build_acceptance_record_has_exact_privacy_safe_schema(self):
        record = MODULE.build_acceptance_record(
            source_commit="a" * 40,
            macos_version="26.6",
            hardware_model="Mac16,8",
            result_values=[
                "NH-MEDIA-BRIDGE-001=PASS",
                "NH-MEDIA-BRIDGE-016=NEEDS_REDESIGN",
            ],
        )

        self.assertEqual(
            {"schemaVersion", "sourceCommit", "adapterCommit", "platform", "results"},
            set(record),
        )
        self.assertEqual(
            {
                "NH-MEDIA-BRIDGE-001": "PASS",
                "NH-MEDIA-BRIDGE-016": "NEEDS_REDESIGN",
            },
            record["results"],
        )
        encoded = json.dumps(record)
        for forbidden in ("title", "artist", "album", "artworkData", "notes", "metadata"):
            self.assertNotIn(forbidden, encoded)

    def test_unknown_scenario_and_invalid_result_are_rejected(self):
        with self.assertRaises(ValueError):
            MODULE.parse_result("NH-MEDIA-BRIDGE-999=PASS")
        with self.assertRaises(ValueError):
            MODULE.parse_result("NH-MEDIA-BRIDGE-001=MAYBE")

    def test_source_sha_and_duplicate_scenarios_are_rejected(self):
        with self.assertRaises(ValueError):
            MODULE.build_acceptance_record(
                source_commit="abc",
                macos_version="26.6",
                hardware_model="Mac16,8",
                result_values=["NH-MEDIA-BRIDGE-001=PASS"],
            )

        with self.assertRaises(ValueError):
            MODULE.build_acceptance_record(
                source_commit="a" * 40,
                macos_version="26.6",
                hardware_model="Mac16,8",
                result_values=[
                    "NH-MEDIA-BRIDGE-001=PASS",
                    "NH-MEDIA-BRIDGE-001=FAIL",
                ],
            )

    def test_cli_writes_only_normalized_json(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            output = pathlib.Path(temp_dir) / "acceptance.json"
            result = MODULE.main(
                [
                    "--source-commit",
                    "b" * 40,
                    "--macos",
                    "26.6",
                    "--hardware-model",
                    "Mac16,8",
                    "--result",
                    "NH-MEDIA-BRIDGE-003=PASS",
                    "--output",
                    str(output),
                ]
            )

            self.assertEqual(0, result)
            record = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual({"NH-MEDIA-BRIDGE-003": "PASS"}, record["results"])
            self.assertEqual(MODULE.ADAPTER_COMMIT, record["adapterCommit"])


if __name__ == "__main__":
    unittest.main()
