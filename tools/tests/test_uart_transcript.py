"""Offline parser unit tests with synthetic inputs; never hardware evidence."""
import copy
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock


SCRIPT = Path(__file__).parents[1] / "p2/hil/verify_uart_transcript.py"
SPEC = importlib.util.spec_from_file_location("uart_transcript", SCRIPT)
uart = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(uart)


def fixture():
    return {"mode": "ready", "token": "unit_nonce",
            "boot_contains": ["UNIT TEST ONLY", "berry> "],
            "cases": [{"name": "arithmetic", "tx_hex": b"6 * 7\r".hex(),
                       "prompt": "berry> ", "line": "42", "contains": None}]}


def transcript(spec, rx=b"6 * 7\r\n42\r\nberry> "):
    case = spec["cases"][0]
    return "\n".join([
        "UART_RX_HEX " + b"UNIT TEST ONLY\r\nberry> ".hex(),
        "UART_CASE " + case["name"],
        "UART_TX_HEX " + case["tx_hex"],
        "UART_RX_HEX " + rx.hex(),
        "UART_TRANSPORT_COMPLETE", ""])


class TranscriptTests(unittest.TestCase):
    def setUp(self):
        self.spec = fixture()
        self.log = transcript(self.spec)

    def test_matching_bytes_and_exact_result_are_accepted(self):
        raw, frames = uart.verify(self.spec, self.log)
        self.assertIn(b"42\r\n", raw)
        self.assertEqual([x["name"] for x in frames], ["arithmetic"])

    def test_all_available_negative_controls_are_rejected(self):
        checked = uart.negative_controls(self.spec, self.log)
        self.assertIn("wrong_arithmetic", checked)
        self.assertIn("echo_only", checked)
        self.assertGreaterEqual(len(checked), 6)

    def test_completion_must_be_an_exact_standalone_marker(self):
        bad = self.log.replace("UART_TRANSPORT_COMPLETE", "NOT_UART_TRANSPORT_COMPLETE")
        with self.assertRaises(uart.Rejected):
            uart.verify(self.spec, bad)

    def test_duplicated_completion_is_rejected(self):
        with self.assertRaises(uart.Rejected):
            uart.verify(self.spec, self.log + "UART_TRANSPORT_COMPLETE\n")

    def test_received_bytes_after_completion_are_rejected(self):
        with self.assertRaises(uart.Rejected):
            uart.verify(self.spec, self.log + "UART_RX_HEX 626f6f74\n")

    def test_wrong_boot_is_rejected(self):
        spec = copy.deepcopy(self.spec)
        spec["boot_contains"] = ["another profile"]
        with self.assertRaises(uart.Rejected):
            uart.verify(spec, self.log)

    def test_empty_or_invalid_boot_requirements_are_rejected(self):
        for value in ([], "UNIT TEST ONLY", [""], [1]):
            with self.subTest(value=value), self.assertRaises(uart.Rejected):
                uart.verify(dict(self.spec, boot_contains=value), self.log)

    def test_legacy_fixture_still_requires_original_boot(self):
        spec = copy.deepcopy(self.spec)
        del spec["boot_contains"]
        with self.assertRaises(uart.Rejected):
            uart.verify(spec, self.log)

    def test_result_must_be_an_exact_received_line(self):
        with self.assertRaises(uart.Rejected):
            uart.verify(self.spec, transcript(self.spec, b"prefix 42\r\nberry> "))

    def test_echo_cannot_supply_the_output_oracle(self):
        spec = copy.deepcopy(self.spec)
        spec["cases"][0]["tx_hex"] = b'print("42")\r'.hex()
        with self.assertRaises(uart.Rejected):
            uart.verify(spec, transcript(spec))

    def test_unexpected_exception_is_rejected(self):
        with self.assertRaises(uart.Rejected):
            uart.verify(self.spec, transcript(self.spec, b"42\r\nmemory_error: OOM\r\nberry> "))

    def test_expected_exception_label_is_accepted(self):
        spec = copy.deepcopy(self.spec)
        spec["cases"][0].update(line=None, contains="value_error:")
        uart.verify(spec, transcript(spec, b"value_error: unit\r\nberry> "))

    def test_case_name_tx_and_count_are_bound_to_fixture(self):
        bad_logs = [self.log.replace("UART_CASE arithmetic", "UART_CASE different"),
                    self.log.replace("UART_TX_HEX ", "UART_TX_HEX 00", 1),
                    self.log.replace("UART_CASE arithmetic\n", "")]
        for log in bad_logs:
            with self.subTest(log=log), self.assertRaises(uart.Rejected):
                uart.verify(self.spec, log)

    def test_malformed_hex_is_rejected(self):
        with self.assertRaises(ValueError):
            uart.verify(self.spec, self.log.replace("UART_RX_HEX ", "UART_RX_HEX zz", 1))

    def test_full_mode_requires_example_and_help_completion(self):
        spec = dict(self.spec, mode="full")
        with self.assertRaises(uart.Rejected):
            uart.verify(spec, self.log)
        rx = b"42\r\ninteractive example passed\r\ninteractive help checks passed\r\nberry> "
        uart.verify(spec, transcript(spec, rx))

    def test_cli_records_consistency_scope_and_hashes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            spec, log = root / "input.json", root / "capture.log"
            spec.write_text(json.dumps(self.spec), encoding="utf-8")
            log.write_text(self.log, encoding="utf-8")
            with mock.patch.object(sys, "argv", [str(SCRIPT), str(spec), str(log), "--selftest"]), mock.patch("sys.stdout", new_callable=io.StringIO):
                uart.main()
            receipt = json.loads((root / "capture.verified.json").read_text(encoding="utf-8"))
            self.assertEqual(receipt["scope"], "offline transcript consistency only; no hardware attestation")
            self.assertEqual(receipt["case_count"], 1)
            self.assertEqual(len(receipt["log_sha256"]), 64)

    def test_cli_rejects_without_writing_success_artifacts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            spec, log = root / "input.json", root / "capture.log"
            spec.write_text(json.dumps(self.spec), encoding="utf-8")
            log.write_text("host PASS only", encoding="utf-8")
            with mock.patch.object(sys, "argv", [str(SCRIPT), str(spec), str(log)]), mock.patch("sys.stderr", new_callable=io.StringIO), self.assertRaises(SystemExit):
                uart.main()
            self.assertFalse((root / "capture.verified.json").exists())


if __name__ == "__main__":
    unittest.main()
