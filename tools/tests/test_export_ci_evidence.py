"""CI-only evidence export tests; not runtime or target proof."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
EXPORTER = ROOT / "tools" / "export_ci_evidence.py"


class ExportCiEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.build = self.source / "build"
        self.destination = self.root / "artifacts"
        self.build.mkdir(parents=True)

    def receipt(self, name, results="{}\n", log="compiler output\n"):
        directory = self.build / name
        directory.mkdir(parents=True)
        (directory / "results.json").write_text(results)
        (directory / "test.log").write_text(log)
        directory.chmod(0o700)
        return directory

    def run_exporter(self, *extra):
        return subprocess.run(
            [sys.executable, str(EXPORTER), "--source-build", str(self.build),
             "--output-dir", str(self.destination), "--required-results", "2", *extra],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )

    def test_workflow_runs_export_regressions(self):
        workflow = (ROOT / ".github/workflows/c-cpp.yml").read_text()
        self.assertIn(
            "python3 -m unittest discover -s tools/tests -p test_export_ci_evidence.py",
            workflow,
        )

    def test_exports_only_receipts_and_logs_as_collector_readable_copies(self):
        first = self.receipt("p2-clock-private", '{"clock": true}\n', "clock log\n")
        second = self.receipt("p2-vm-private", '{"vm": true}\n', "vm log\n")
        (first / "binary").write_bytes(b"never export")
        (first / "secret.txt").write_text("never export")

        result = self.run_exporter()

        self.assertEqual(result.returncode, 0, result.stderr)
        exported = sorted(p.relative_to(self.destination).as_posix()
                          for p in self.destination.rglob("*") if p.is_file())
        self.assertEqual(exported, [
            "p2-clock-private/results.json", "p2-clock-private/test.log",
            "p2-vm-private/results.json", "p2-vm-private/test.log",
        ])
        for path in self.destination.rglob("*"):
            self.assertFalse(path.is_symlink())
            self.assertEqual(path.stat().st_mode & 0o777, 0o755 if path.is_dir() else 0o644)
        self.assertEqual(first.stat().st_mode & 0o777, 0o700)
        self.assertEqual(second.stat().st_mode & 0o777, 0o700)

    def test_nested_export_directories_are_collector_traversable(self):
        receipt = self.receipt("nested/receipt")
        self.receipt("other")
        result = self.run_exporter()
        self.assertEqual(result.returncode, 0, result.stderr)
        for path in (self.destination, self.destination / "nested",
                     self.destination / "nested/receipt"):
            self.assertEqual(path.stat().st_mode & 0o777, 0o755)
        self.assertEqual(receipt.stat().st_mode & 0o777, 0o700)

    def test_rejects_symlink_and_leaves_no_export_tree(self):
        self.receipt("good")
        evil = self.receipt("evil")
        (evil / "results.json").unlink()
        (evil / "results.json").symlink_to(self.root / "outside.json")

        result = self.run_exporter()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("symlink", result.stderr.lower())
        self.assertFalse(self.destination.exists())

    def test_fails_when_required_receipts_are_missing(self):
        self.receipt("only-one")

        result = self.run_exporter()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("required", result.stderr.lower())
        self.assertFalse(self.destination.exists())

    def test_rejects_source_or_destination_root_symlink_before_resolution(self):
        self.receipt("one")
        self.receipt("two")
        source_link = self.root / "source-link"
        source_link.symlink_to(self.build, target_is_directory=True)
        source_result = subprocess.run(
            [sys.executable, str(EXPORTER), "--source-build", str(source_link),
             "--output-dir", str(self.destination), "--required-results", "2"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
        self.assertNotEqual(source_result.returncode, 0)
        self.assertIn("symlink", source_result.stderr.lower())
        destination_link = self.root / "artifact-link"
        destination_link.symlink_to(self.root / "elsewhere", target_is_directory=True)
        destination_result = subprocess.run(
            [sys.executable, str(EXPORTER), "--source-build", str(self.build),
             "--output-dir", str(destination_link), "--required-results", "2"],
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )
        self.assertNotEqual(destination_result.returncode, 0)
        self.assertIn("symlink", destination_result.stderr.lower())


if __name__ == "__main__":
    unittest.main()
