#!/usr/bin/env python3
import argparse
import os
import pty
import select
import signal
import sys
import time


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
