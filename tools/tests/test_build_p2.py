"""Wrapper unit tests only: subprocess seams are NOT Catalina target proof."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_p2 as build


class BuildTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "repo"
        self.sdk = self.root / "Catalina"
        self.output = self.root / "proof"
        self.calls = []
        self.build_code = 0
        self.image_data = b"unit-test-image-not-target-proof\n" * 3000
        self.produce_image = True
        self.old_image = False
        self.sdk_head = build.SDK_COMMIT
        for name, text in {
            "Makefile": "include mk/p2.mk\n",
            "mk/p2.mk": "p2:\n\tfalse\n",
            "src/be_vm.c": '#include "../generate/test.h"\n',
            "src/new_runtime.c": "/* untracked current input */\n",
            "default/berry_conf.h": "/* original config */\n",
            "port/p2/runtime/main_p2.c": "/* real source fixture */\n",
            "tools/bootstrap_catalina.py": "# bootstrap fixture\n",
            "tools/patches/catalina-linux64.patch": "host patch fixture\n",
            "tools/p2/bootstrap/patch-catalina-p2.sh": "# patch fixture\n",
            "tests/json_test_cases.json": "{\"positive\": {}}\n",
            "generate/test.h": "ORIGINAL GENERATED HEADER\n",
            "build/p2/catalina/xmm/berry_p2.binary": "STALE IMAGE\n",
            ".p2.local.mk": "P2_PROFILE=minimal\n",
            ".git/config": "not copied\n",
            "src/.env": "not a real secret\n",
            "src/credentials.json": "not a real credential\n",
            "src/private.pem": "not a real private key\n",
            "src/__pycache__/cached.pyc": "not copied\n",
            "tools/Catalina/src/compiler.c": "SDK must not be copied\n",
            "unrelated/data.txt": "not copied\n",
        }.items():
            self.put(self.source / name, text)
        self.make_sdk()
        self.addCleanup(patch.stopall)
        patch.object(build.platform, "system", return_value="Linux").start()
        patch.object(build.platform, "machine", return_value="x86_64").start()
        patch.object(build.bootstrap, "verify_tools", return_value={"catalina": "a" * 64}).start()
        patch.object(build.subprocess, "run", side_effect=self.fake_run).start()

    @staticmethod
    def put(path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def make_sdk(self):
        self.sdk.mkdir(exist_ok=True)
        self.put(self.sdk / "berry-bootstrap.json", json.dumps({
            "source_commit": build.SDK_COMMIT,
            "host_patch_sha256": hashlib.sha256(
                (self.source / "tools/patches/catalina-linux64.patch").read_bytes()).hexdigest(),
            "tools_sha256": {"catalina": "a" * 64},
        }))

    def fake_run(self, argv, **kwargs):
        argv = list(map(str, argv))
        self.calls.append((argv, str(kwargs.get("cwd"))))
        code, text = 0, ""
        if "rev-parse" in argv:
            text = (self.sdk_head if str(self.sdk) in argv else "1" * 40) + "\n"
        elif "status" in argv:
            text = " M src/be_vm.c\n?? src/new_runtime.c\n"
        elif any(a.endswith("bootstrap_catalina.py") for a in argv):
            self.make_sdk()
        elif argv[0] == "make":
            snap = Path(kwargs["cwd"])
            self.assertEqual((snap / "src/new_runtime.c").read_bytes(),
                             (self.source / "src/new_runtime.c").read_bytes())
            self.assertFalse((snap / "generate/test.h").exists())
            self.put(snap / "generate/test.h", "isolated generated configuration\n")
            image = snap / build.IMAGE_RELATIVE
            self.assertFalse(image.exists(), "stale input image was copied")
            if self.produce_image:
                image.parent.mkdir(parents=True, exist_ok=True)
                image.write_bytes(self.image_data)
                if self.old_image:
                    os.utime(image, ns=(1, 1))
            code, text = self.build_code, "unit compiler output\n"
        stream = kwargs.get("stdout")
        if hasattr(stream, "write"):
            stream.write(text)
            stream.flush()
        return subprocess.CompletedProcess(argv, code, stdout=text, stderr="")

    def invoke(self, *extra):
        return build.main(["--sdk-dir", str(self.sdk), "--output-dir", str(self.output),
                           *extra], source_root=self.source)

    def receipt(self):
        return json.loads((self.output / "result.json").read_text())

    def test_snapshot_includes_integrated_gate_runners(self):
        names = ("tools/test_p2_cog_handles.py", "tools/test_p2_module_config.py",
                 "tools/test_repl.py")
        for name in names:
            self.put(self.source / name, "# current gate runner\n")
        hashes = build.snapshot_source(self.source, self.output)
        for name in names:
            self.assertIn(name, hashes)
            self.assertEqual((self.output / name).read_bytes(),
                             (self.source / name).read_bytes())

    def test_required_arguments(self):
        with self.assertRaises(SystemExit) as error:
            build.main([], source_root=self.source)
        self.assertEqual(error.exception.code, 2)

    def test_unsupported_host_is_failure(self):
        with patch.object(build.platform, "machine", return_value="aarch64"):
            self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(self.calls)

    def test_output_must_be_empty_and_preserve_stale_result(self):
        self.put(self.output / "result.json", "old receipt")
        self.assertNotEqual(self.invoke(), 0)
        self.assertEqual((self.output / "result.json").read_text(), "old receipt")
        self.assertFalse(self.calls)

    def test_source_overlap_rejected(self):
        for destination in [self.source, self.source / "src/proof", self.root]:
            with self.subTest(destination=destination):
                self.output = destination
                self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(self.calls)

    def test_sdk_inside_source_rejected(self):
        self.sdk = self.source / "Catalina"
        self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(self.calls)

    def test_shell_sensitive_paths_rejected(self):
        for name in ["sdk with spaces", "sdk;touch", "sdk$HOME"]:
            self.sdk = self.root / name
            self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(self.calls)

    def test_offline_missing_sdk_never_bootstraps(self):
        self.sdk = self.root / "missing-sdk"
        self.assertNotEqual(self.invoke("--offline"), 0)
        self.assertFalse(any("bootstrap_catalina.py" in " ".join(a) for a, _ in self.calls))
        self.assertEqual(self.receipt()["status"], "failed")

    def test_offline_unprepared_sdk_never_bootstraps(self):
        (self.sdk / "berry-bootstrap.json").unlink()
        self.assertNotEqual(self.invoke("--offline"), 0)
        self.assertFalse(any("bootstrap_catalina.py" in " ".join(a) for a, _ in self.calls))

    def test_sdk_mismatch_fails_without_build_or_bootstrap(self):
        self.sdk_head = "0" * 40
        self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(any(a[0] == "make" for a, _ in self.calls))
        self.assertFalse(any("bootstrap_catalina.py" in " ".join(a) for a, _ in self.calls))

    def test_missing_sdk_bootstrap_then_patch_then_real_target(self):
        self.sdk = self.root / "new-sdk"
        self.assertEqual(self.invoke(), 0)
        commands = [a for a, _ in self.calls]
        boot = next(i for i, a in enumerate(commands) if any(x.endswith("bootstrap_catalina.py") for x in a))
        prep = next(i for i, a in enumerate(commands) if any(x.endswith("patch-catalina-p2.sh") for x in a))
        target = next(i for i, a in enumerate(commands) if a[0] == "make")
        self.assertLess(boot, prep)
        self.assertLess(prep, target)
        self.assertEqual(commands[prep][-4:], ["P2_EDGE", "LARGE", "cx", "direct"])
        for arg in ["p2", "TOOLCHAIN=catalina", "P2_PROFILE=xmm", "P2_BOARD=p2edge32",
                    "CATALINA_MODEL=LARGE", "CATALINA_CLIB=-lcx", "CATALINA_SERIAL_LIB=-lpsram"]:
            self.assertIn(arg, commands[target])

    def test_compiler_failure_cannot_publish_even_if_image_exists(self):
        self.build_code = 7
        self.assertEqual(self.invoke("--offline"), 7)
        result = self.receipt()
        self.assertEqual(result["status"], "failed")
        self.assertNotIn("image_sha256", result)
        self.assertEqual(result["commands"][-1]["returncode"], 7)
        self.assertIn("unit compiler output", (self.output / result["commands"][-1]["log"]).read_text())

    def test_success_without_image_rejected(self):
        self.produce_image = False
        self.assertNotEqual(self.invoke(), 0)
        self.assertEqual(self.receipt()["status"], "failed")

    def test_empty_small_and_oversized_images_rejected(self):
        for index, size in enumerate([0, 65536, 16777217]):
            with self.subTest(size=size):
                self.output = self.root / f"size-{index}"
                self.image_data = b"x" * size
                self.assertNotEqual(self.invoke(), 0)
                self.assertNotIn("image_sha256", self.receipt())

    def test_old_mtime_image_rejected(self):
        self.old_image = True
        self.assertNotEqual(self.invoke(), 0)
        self.assertEqual(self.receipt()["status"], "failed")

    def test_source_isolation_and_provenance(self):
        before = {str(p.relative_to(self.source)): p.read_bytes()
                  for p in self.source.rglob("*") if p.is_file()}
        self.assertEqual(self.invoke("--offline"), 0)
        after = {str(p.relative_to(self.source)): p.read_bytes()
                 for p in self.source.rglob("*") if p.is_file()}
        self.assertEqual(before, after)
        result = self.receipt()
        self.assertEqual(result["source_head"], "1" * 40)
        self.assertTrue(result["source_dirty"])
        self.assertEqual(result["sdk_commit"], build.SDK_COMMIT)
        self.assertEqual(result["image_bytes"], len(self.image_data))
        self.assertEqual(result["image_sha256"], hashlib.sha256(self.image_data).hexdigest())
        image = Path(result["image_path"])
        self.assertTrue(image.is_relative_to(self.output))
        self.assertEqual(image.read_bytes(), self.image_data)
        inputs = result["input_sha256"]
        self.assertIn("src/new_runtime.c", inputs)
        self.assertIn("port/p2/runtime/main_p2.c", inputs)
        self.assertIn("tests/json_test_cases.json", inputs)
        for excluded in [".git", ".p2.local.mk", "generate", "build", "unrelated", "tools/Catalina"]:
            self.assertFalse((self.output / "source" / excluded).exists() if excluded not in ("generate", "build")
                             else any(p.startswith(excluded + "/") for p in inputs))
        for excluded in ["src/.env", "src/credentials.json", "src/private.pem", "src/__pycache__/cached.pyc"]:
            self.assertNotIn(excluded, inputs)

    def test_symlink_source_cannot_escape_snapshot(self):
        outside = self.root / "outside.c"
        self.put(outside, "outside content")
        (self.source / "src/escape.c").symlink_to(outside)
        self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(any(a[0] == "make" for a, _ in self.calls))

    def test_symlink_ancestor_cannot_escape_snapshot(self):
        outside = self.root / "outside-port"
        (self.source / "port").rename(outside)
        (self.source / "port").symlink_to(outside, target_is_directory=True)
        self.assertNotEqual(self.invoke(), 0)
        self.assertFalse(any(a[0] == "make" for a, _ in self.calls))

    def test_online_unprepared_sdk_retains_distinct_command_logs(self):
        (self.sdk / "berry-bootstrap.json").unlink()
        self.assertEqual(self.invoke(), 0)
        commands = self.receipt()["commands"]
        self.assertEqual(len(commands), len({record["log"] for record in commands}))
        for record in commands:
            self.assertEqual(record["log_sha256"], build.sha256(self.output / record["log"]))

    def test_host_patch_or_tool_hash_mismatch_is_offline_failure(self):
        for key in ["host_patch_sha256", "tools_sha256"]:
            with self.subTest(key=key):
                self.output = self.root / key
                self.make_sdk()
                path = self.sdk / "berry-bootstrap.json"
                receipt = json.loads(path.read_text())
                receipt[key] = "wrong"
                path.write_text(json.dumps(receipt))
                self.assertNotEqual(self.invoke("--offline"), 0)

    def test_command_launch_failure_is_recorded(self):
        with patch.object(build.subprocess, "run", side_effect=FileNotFoundError("missing git")):
            self.assertNotEqual(self.invoke(), 0)
        result = self.receipt()
        self.assertEqual(result["status"], "failed")
        self.assertNotEqual(result["commands"][-1]["returncode"], 0)

    def test_bootstrap_and_library_patch_failures_stop_before_make(self):
        for index, script in enumerate(["bootstrap_catalina.py", "patch-catalina-p2.sh"]):
            with self.subTest(script=script):
                self.calls.clear()
                self.output = self.root / f"failure-{index}"
                if index == 0:
                    self.sdk = self.root / "unbootstrapped"

                def fail(argv, **kwargs):
                    result = self.fake_run(argv, **kwargs)
                    if any(str(a).endswith(script) for a in argv):
                        result.returncode = 19
                    return result

                with patch.object(build.subprocess, "run", side_effect=fail):
                    self.assertEqual(self.invoke(), 19)
                self.assertFalse(any(a[0] == "make" for a, _ in self.calls))
                self.assertEqual(self.receipt()["status"], "failed")

    def test_source_mutation_during_build_invalidates_receipt(self):
        def change(argv, **kwargs):
            result = self.fake_run(argv, **kwargs)
            if argv[0] == "make":
                self.put(self.source / "src/be_vm.c", "changed by another writer\n")
            return result

        with patch.object(build.subprocess, "run", side_effect=change):
            self.assertNotEqual(self.invoke(), 0)
        self.assertNotIn("image_sha256", self.receipt())

    def test_inherited_build_and_git_environment_is_not_forwarded(self):
        observed = []

        def observe(argv, **kwargs):
            observed.append(kwargs["env"])
            return self.fake_run(argv, **kwargs)

        with patch.dict(os.environ, {"MAKEFLAGS": "-n", "GIT_CONFIG_COUNT": "1",
                                     "CATALINA_MODEL": "COMPACT", "PYTHONPATH": "/unsafe"}):
            with patch.object(build.subprocess, "run", side_effect=observe):
                self.assertEqual(self.invoke(), 0)
        self.assertTrue(observed)
        for env in observed:
            self.assertEqual(env.get("GIT_OPTIONAL_LOCKS"), "0")
            for key in ["MAKEFLAGS", "GIT_CONFIG_COUNT", "CATALINA_MODEL", "PYTHONPATH"]:
                self.assertNotIn(key, env)


class CommandTests(unittest.TestCase):
    def test_real_subprocess_exit_and_stderr_are_retained(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            result = {"commands": []}
            run = build.BuildRun(output, result)
            with self.assertRaises(build.BuildError) as failure:
                run.command("real-failure", [sys.executable, "-c",
                            "import sys; print('real stderr', file=sys.stderr); sys.exit(23)"], output)
            self.assertEqual(failure.exception.code, 23)
            self.assertEqual(result["commands"][0]["returncode"], 23)
            self.assertEqual((output / "logs/real-failure.log").read_text(), "real stderr\n")


if __name__ == "__main__":
    unittest.main()
