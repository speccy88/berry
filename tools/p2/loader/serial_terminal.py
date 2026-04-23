#!/usr/bin/env python3
import argparse
import os
import pty
import select
import shlex
import sys
import termios
import tty


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("loadp2")
    parser.add_argument("port")
    parser.add_argument("baud")
    parser.add_argument("flags")
    parser.add_argument("image")
    args = parser.parse_args()

    cmd = [
        args.loadp2,
        "-p",
        args.port,
        "-b",
        args.baud,
        *shlex.split(args.flags),
        args.image,
    ]

    stdin_fd = sys.stdin.fileno()
    stdout = sys.stdout.buffer
    old_tty = termios.tcgetattr(stdin_fd)
    recent = bytearray()
    pending_quit = False
    saw_oom = False

    pid, master_fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)

    try:
        tty.setraw(stdin_fd)
        while True:
            readable, _, _ = select.select([stdin_fd, master_fd], [], [])
            if master_fd in readable:
                data = os.read(master_fd, 4096)
                if not data:
                    break
                stdout.write(data)
                stdout.flush()
                recent.extend(data)
                if len(recent) > 128:
                    recent = recent[-128:]
                if b"error: REPL ran out of memory" in recent:
                    saw_oom = True
                compact = bytes(recent).replace(b"\r", b"\n")
                if pending_quit or saw_oom:
                    if b"bye" in compact.split():
                        try:
                            os.write(master_fd, b"\x1d")
                        except OSError:
                            pass
                        pending_quit = False
                        saw_oom = False
                while b"\n" in recent:
                    line, _, rest = recent.partition(b"\n")
                    recent = bytearray(rest)
                    stripped = line.replace(b"\r", b"").strip()
                    if (pending_quit or saw_oom) and stripped == b"bye":
                        try:
                            os.write(master_fd, b"\x1d")
                        except OSError:
                            pass
                        pending_quit = False
                        saw_oom = False
            if stdin_fd in readable:
                data = os.read(stdin_fd, 1)
                if not data:
                    pending_quit = True
                    os.write(master_fd, b"\x04")
                    continue
                if data[0] in (0x03, 0x04):
                    pending_quit = True
                os.write(master_fd, data)
    finally:
        termios.tcsetattr(stdin_fd, termios.TCSANOW, old_tty)
        try:
            os.close(master_fd)
        except OSError:
            pass
        try:
            os.waitpid(pid, 0)
        except ChildProcessError:
            pass


if __name__ == "__main__":
    main()
