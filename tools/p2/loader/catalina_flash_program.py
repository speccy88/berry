#!/usr/bin/env python3
import argparse
import os
import pty
import signal
import select
import shutil
import subprocess
import sys
import time


def stop_stale_port_users(port):
    if not shutil.which("lsof"):
        return
    try:
        proc = subprocess.run(
            ["lsof", "-t", port],
            check=False,
            capture_output=True,
            text=True,
        )
    except OSError:
        return

    pids = []
    for line in proc.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            pids.append(int(line))
        except ValueError:
            continue

    for pid in pids:
        try:
            cmd = subprocess.run(
                ["ps", "-p", str(pid), "-o", "command="],
                check=False,
                capture_output=True,
                text=True,
            ).stdout.strip()
        except OSError:
            continue
        if any(token in cmd for token in ("loadp2", "proploader", "serial_terminal.py", "tio")):
            try:
                os.kill(pid, signal.SIGCONT)
            except OSError:
                pass
            try:
                os.kill(pid, signal.SIGTERM)
            except OSError:
                pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--loadp2", required=True)
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--timeout", type=float, default=90.0)
    args = parser.parse_args()

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
    print("[Flash] Waiting for Berry to boot from flash...", flush=True)
    stop_stale_port_users(args.port)

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
            print("\n[Flash] Berry booted from flash.", flush=True)
            try:
                os.write(master_fd, b"\x1d")
            except OSError:
                pass
            return 0

        print("\nerror: timed out waiting for Berry to boot from flash", file=sys.stderr)
        return 1
    finally:
        try:
            os.close(master_fd)
        except OSError:
            pass
        try:
            os.kill(pid, signal.SIGTERM)
        except OSError:
            pass
        try:
            os.waitpid(pid, 0)
        except ChildProcessError:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
