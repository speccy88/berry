#!/usr/bin/env python3
import argparse
import errno
import os
import pty
import select
import shlex
import sys
import termios
import time
import tty


def _wait_status(pid):
    try:
        _, status = os.waitpid(pid, 0)
    except ChildProcessError:
        return 0
    if os.WIFEXITED(status):
        return os.WEXITSTATUS(status)
    if os.WIFSIGNALED(status):
        return 128 + os.WTERMSIG(status)
    return 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--noninteractive-timeout", type=float, default=0)
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
    stdin_is_tty = os.isatty(stdin_fd)
    old_tty = termios.tcgetattr(stdin_fd) if stdin_is_tty else None
    recent = bytearray()
    pending_quit = False
    saw_oom = False

    pid, master_fd = pty.fork()
    if pid == 0:
        os.execvp(cmd[0], cmd)

    try:
        if stdin_is_tty:
            tty.setraw(stdin_fd)
        elif args.noninteractive_timeout <= 0:
            args.noninteractive_timeout = 45.0

        deadline = time.monotonic() + args.noninteractive_timeout if not stdin_is_tty else None
        sent_disconnect = False
        while True:
            read_fds = [master_fd]
            if stdin_is_tty:
                read_fds.append(stdin_fd)
            timeout = None
            if deadline is not None:
                timeout = max(0, deadline - time.monotonic())
            readable, _, _ = select.select(read_fds, [], [], timeout)
            if not readable and deadline is not None:
                try:
                    os.write(master_fd, b"\x1d")
                except OSError:
                    pass
                sent_disconnect = True
                deadline = time.monotonic() + 2.0
                continue
            if master_fd in readable:
                try:
                    data = os.read(master_fd, 4096)
                except OSError as exc:
                    if exc.errno == errno.EIO:
                        break
                    raise
                if not data:
                    break
                stdout.write(data)
                stdout.flush()
                recent.extend(data)
                if len(recent) > 128:
                    recent = recent[-128:]
                if b"error: REPL ran out of memory" in recent:
                    saw_oom = True
                if not stdin_is_tty and not sent_disconnect:
                    if b"berry>" in recent or b"error:" in recent.lower():
                        try:
                            os.write(master_fd, b"\x1d")
                        except OSError:
                            pass
                        sent_disconnect = True
                        deadline = time.monotonic() + 2.0
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
            if stdin_is_tty and stdin_fd in readable:
                data = os.read(stdin_fd, 1)
                if not data:
                    pending_quit = True
                    os.write(master_fd, b"\x04")
                    continue
                if data[0] in (0x03, 0x04):
                    pending_quit = True
                os.write(master_fd, data)
    finally:
        if old_tty is not None:
            termios.tcsetattr(stdin_fd, termios.TCSANOW, old_tty)
        try:
            os.close(master_fd)
        except OSError:
            pass
    return _wait_status(pid)


if __name__ == "__main__":
    raise SystemExit(main())
