#!/usr/bin/env python3
"""Safety tests for the Catalina flash-program wrapper; no hardware is used."""

from __future__ import annotations

import importlib.util
import io
import os
from pathlib import Path
import tempfile
import types
import unittest
from unittest import mock


SCRIPT = Path(__file__).parents[1] / "p2" / "loader" / "catalina_flash_program.py"
SPEC = importlib.util.spec_from_file_location("catalina_flash_program_under_test", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
flash_program = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(flash_program)


class PortOwnershipTests(unittest.TestCase):
    def test_empty_result_with_detection_errors_is_not_a_free_port(self):
        for stdout, stderr in (("", "permission denied"), ("415\n", "")):
            with self.subTest(stdout=stdout, stderr=stderr):
                def run(argv, **kwargs):
                    return types.SimpleNamespace(returncode=1, stdout=stdout, stderr=stderr)
                with self.assertRaises(flash_program.PortOwnershipError):
                    flash_program.stop_stale_port_users(
                        "/dev/ttyUSB0", run=run, which=lambda _: "/usr/bin/lsof")

    def test_verified_empty_result_allows_loading(self):
        def run(argv, **kwargs):
            return types.SimpleNamespace(returncode=1, stdout="", stderr="")
        flash_program.stop_stale_port_users(
            "/dev/ttyUSB0", run=run, which=lambda _: "/usr/bin/lsof")

    def test_refuses_holder_without_signalling_process(self):
        calls = []
        kills = []
        original_kill = flash_program.os.kill
        flash_program.os.kill = lambda pid, sig: kills.append((pid, sig))
        try:
            def run(argv, **kwargs):
                calls.append(argv)
                if argv[:2] == ["lsof", "-t"]:
                    return types.SimpleNamespace(returncode=0, stdout="415\n", stderr="")
                return types.SimpleNamespace(returncode=0, stdout="tio /dev/ttyUSB0\n", stderr="")

            with self.assertRaises(flash_program.PortOwnershipError):
                flash_program.stop_stale_port_users(
                    "/dev/ttyUSB0", run=run, which=lambda _: "/usr/bin/lsof"
                )
        finally:
            flash_program.os.kill = original_kill

        self.assertEqual([["lsof", "-t", "/dev/ttyUSB0"]], calls)
        self.assertEqual([], kills)

    def test_refuses_when_holder_detection_is_unknown(self):
        def run(argv, **kwargs):
            return types.SimpleNamespace(returncode=2, stdout="", stderr="permission denied")

        with self.assertRaises(flash_program.PortOwnershipError):
            flash_program.stop_stale_port_users(
                "/dev/ttyUSB0", run=run, which=lambda _: "/usr/bin/lsof"
            )

    def test_refuses_ambiguous_success_without_holder_pid(self):
        def run(argv, **kwargs):
            return types.SimpleNamespace(returncode=0, stdout="\n", stderr="")

        with self.assertRaises(flash_program.PortOwnershipError):
            flash_program.stop_stale_port_users(
                "/dev/ttyUSB0", run=run, which=lambda _: "/usr/bin/lsof"
            )

    def test_refuses_when_lsof_is_unavailable(self):
        with self.assertRaises(flash_program.PortOwnershipError):
            flash_program.stop_stale_port_users(
                "/dev/ttyUSB0", which=lambda _: None
            )


class CooperativeLockTests(unittest.TestCase):
    def test_lock_contention_is_rejected_and_release_allows_reacquire(self):
        with tempfile.TemporaryDirectory() as directory:
            lockfile = os.path.join(directory, "catalina.lock")
            with flash_program.ExclusiveWrapperLock(lockfile):
                with self.assertRaises(flash_program.LockContentionError):
                    with flash_program.ExclusiveWrapperLock(lockfile):
                        self.fail("contended lock must not be acquired")
            with flash_program.ExclusiveWrapperLock(lockfile):
                pass


class OwnedChildCleanupTests(unittest.TestCase):
    def test_cleanup_signals_only_the_wrapper_child_pid(self):
        kills = []
        waits = []

        flash_program.cleanup_owned_child(
            415,
            kill=lambda pid, sig: kills.append((pid, sig)),
            waitpid=lambda pid, options: waits.append((pid, options)),
        )

        self.assertEqual([(415, flash_program.signal.SIGTERM)], kills)
        self.assertEqual([(415, 0)], waits)


class PromptQualificationTests(unittest.TestCase):
    def test_prompt_only_output_is_explicitly_not_flash_verification(self):
        args = types.SimpleNamespace(
            loadp2="/nonexistent/loadp2",
            port="/dev/not-a-serial-device",
            baud="115200",
            image="image.binary",
            timeout=1.0,
        )

        class CapturingStdout:
            def __init__(self):
                self._text = io.StringIO()
                self.buffer = io.BytesIO()

            def write(self, value):
                return self._text.write(value)

            def flush(self):
                self._text.flush()

            def getvalue(self):
                return self._text.getvalue()

        stdout = CapturingStdout()
        with (
            mock.patch.object(flash_program.pty, "fork", return_value=(741, 18)),
            mock.patch.object(flash_program.select, "select", return_value=([18], [], [])),
            mock.patch.object(flash_program.os, "read", return_value=b"berry>\r\n"),
            mock.patch.object(flash_program.os, "write"),
            mock.patch.object(flash_program.os, "close"),
            mock.patch.object(flash_program, "cleanup_owned_child") as cleanup,
            mock.patch.object(flash_program.sys, "stdout", stdout),
        ):
            result = flash_program.run_loader(args)

        output = stdout.getvalue()
        self.assertEqual(0, result)
        self.assertIn("Observed Berry prompt", output)
        self.assertIn("does not verify the flashed image or persistence", output)
        self.assertNotIn("Berry booted from flash", output)
        cleanup.assert_called_once_with(741)


if __name__ == "__main__":
    unittest.main()
