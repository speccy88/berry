#!/usr/bin/env python3
"""Load Catalina's flash programmer without taking over an occupied serial port."""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import os
import pty
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import time


class PortOwnershipError(RuntimeError):
    """The serial port cannot be proven unused by another process."""


class LockContentionError(RuntimeError):
    """Another cooperative Catalina flash wrapper is already running."""


class ExclusiveWrapperLock:
    """An advisory, non-blocking lock held for the complete loader run."""

    def __init__(self, path: str):
        self.path = path
        self._file = None

    def __enter__(self):
        try:
            self._file = open(self.path, "a+", encoding="utf-8")
            fcntl.flock(self._file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            self._close()
            raise LockContentionError(
                f"wrapper lock is already held: {self.path}; refusing to load"
            ) from exc
        except OSError:
            self._close()
            raise
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self._close()
        return False

    def _close(self):
        if self._file is None:
            return
        try:
            fcntl.flock(self._file.fileno(), fcntl.LOCK_UN)
        finally:
            self._file.close()
            self._file = None


def default_lockfile(port: str) -> str:
    """Return a stable, safe per-port default lock path."""
    identity = hashlib.sha256(port.encode("utf-8")).hexdigest()[:16]
    return os.path.join(tempfile.gettempdir(), f"catalina-flash-program-{identity}.lock")


def stop_stale_port_users(port, *, run=subprocess.run, which=shutil.which):
    """Refuse an occupied or unverifiable port; never signal its holders.

    The legacy name is kept for callers, but this function intentionally no
    longer tries to stop anything.  A process holding the device might be an
    unrelated program, so only the operator can decide how to release it.
    """
    if not which("lsof"):
        raise PortOwnershipError(
            f"cannot verify whether {port} is in use because lsof is unavailable; refusing to load"
        )
    try:
        proc = run(
            ["lsof", "-t", port],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        raise PortOwnershipError(
            f"cannot verify whether {port} is in use; refusing to load"
        ) from exc

    if proc.returncode == 1 and not proc.stdout.strip() and not proc.stderr.strip():
        return
    if proc.returncode != 0:
        raise PortOwnershipError(
            f"cannot verify whether {port} is in use; refusing to load"
        )

    holders = []
    for line in proc.stdout.splitlines():
        token = line.strip()
        if not token:
            continue
        try:
            pid = int(token)
        except ValueError as exc:
            raise PortOwnershipError(
                f"cannot determine who holds {port}; refusing to load"
            ) from exc
        if pid <= 0:
            raise PortOwnershipError(
                f"cannot determine who holds {port}; refusing to load"
            )
        holders.append(pid)

    if not holders:
        raise PortOwnershipError(
            f"cannot determine whether {port} is in use; refusing to load"
        )
    raise PortOwnershipError(f"{port} is already in use; refusing to load")


def cleanup_owned_child(pid, *, kill=os.kill, waitpid=os.waitpid):
    """Terminate and reap only the child PID returned by this wrapper's fork."""
    try:
        kill(pid, signal.SIGTERM)
    except OSError:
        pass
    try:
        waitpid(pid, 0)
    except ChildProcessError:
        pass


def run_loader(args):
    cmd = [
        args.loadp2,
        "-p",
        args.port,
        "-b",
        args.baud,
        "-t",
        args.image,
    ]

    print("[Flash] Loading Catalina flash programmer", flush=True)
    print("[Flash] Waiting for an observed Berry prompt after loader output...", flush=True)

    pid, master_fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)

    deadline = time.time() + args.timeout
    recent = bytearray()
    saw_prompt = False

    try:
        while time.time() < deadline:
            readable, _, _ = select.select([master_fd], [], [], 0.25)
            if master_fd not in readable:
                continue
            try:
                data = os.read(master_fd, 4096)
            except OSError:
                break
            if not data:
                break
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
            recent.extend(data)
            if len(recent) > 4096:
                recent = recent[-4096:]
            normalized = bytes(recent).replace(b"\r", b"\n")
            if b"berry>" in normalized:
                saw_prompt = True
                break
            if b"error:" in normalized.lower():
                break

        if saw_prompt:
            print(
                "\n[Flash] Observed Berry prompt after loader output; this does not verify "
                "the flashed image or persistence.",
                flush=True,
            )
            try:
                os.write(master_fd, b"\x1d")
            except OSError:
                pass
            return 0

        print(
            "\nerror: timed out waiting for an observed Berry prompt "
            "(not image or persistence verification)",
            file=sys.stderr,
        )
        return 1
    finally:
        try:
            os.close(master_fd)
        except OSError:
            pass
        cleanup_owned_child(pid)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--loadp2", required=True)
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--timeout", type=float, default=90.0)
    parser.add_argument(
        "--lockfile",
        help="exclusive cooperative lock path (default: stable per-port file in the system temp directory)",
    )
    args = parser.parse_args()

    lockfile = args.lockfile or default_lockfile(args.port)
    try:
        with ExclusiveWrapperLock(lockfile):
            stop_stale_port_users(args.port)
            return run_loader(args)
    except (LockContentionError, PortOwnershipError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    except OSError as exc:
        print(f"error: cannot use wrapper lock {lockfile}: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
