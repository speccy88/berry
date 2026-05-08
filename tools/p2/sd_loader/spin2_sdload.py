#!/usr/bin/env python3
"""Transfer Spin2 binaries to a P2 SD card through a temporary RAM loader."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import select
import shutil
import signal
import subprocess
import sys
import time
import zlib


READY = b"BERRY_SDLOAD READY"
BYE = b"BERRY_SDLOAD BYE"
VALID_83 = re.compile(r"^[A-Z0-9_~$%'-]{1,8}(?:\\.[A-Z0-9_~$%'-]{1,3})?$")


def stop_stale_port_users(port: str) -> None:
    if not shutil.which("lsof"):
        return
    proc = subprocess.run(["lsof", "-t", port], check=False, capture_output=True, text=True)
    for line in proc.stdout.splitlines():
        try:
            pid = int(line.strip())
        except ValueError:
            continue
        cmd = subprocess.run(
            ["ps", "-p", str(pid), "-o", "command="],
            check=False,
            capture_output=True,
            text=True,
        ).stdout
        if any(token in cmd for token in ("loadp2", "proploader", "serial_terminal.py", "tio")):
            print(f"[SDLoad] stopping stale terminal on {port} (pid {pid})")
            try:
                os.kill(pid, signal.SIGCONT)
            except OSError:
                pass
            try:
                os.kill(pid, signal.SIGTERM)
            except OSError:
                pass


def sanitize_part(text: str, limit: int) -> str:
    clean = []
    for ch in text.upper():
        if ch.isalnum() or ch in "_~$%'":
            clean.append(ch)
        elif ch in "-.":
            clean.append("_")
    result = "".join(clean).strip("_")
    return (result or "FILE")[:limit]


def short_name(path: Path, used: set[str]) -> str:
    raw = path.name.upper()
    if VALID_83.match(raw) and raw not in used:
        used.add(raw)
        return raw

    stem = sanitize_part(path.stem, 8)
    ext = sanitize_part(path.suffix[1:] or "BIN", 3)
    candidate = f"{stem}.{ext}"
    if len(stem) <= 8 and len(ext) <= 3 and candidate not in used:
        used.add(candidate)
        return candidate

    base = sanitize_part(path.stem, 6)[:6] or "FILE"
    for index in range(1, 100):
        candidate = f"{base[: max(1, 8 - len(str(index)) - 1)]}~{index}.{ext[:3]}"
        if candidate not in used:
            used.add(candidate)
            return candidate
    raise RuntimeError(f"could not make unique 8.3 name for {path}")


class LoaderSession:
    def __init__(self, cmd: list[str], timeout: float) -> None:
        self.proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=0,
        )
        assert self.proc.stdin is not None
        assert self.proc.stdout is not None
        self.stdin = self.proc.stdin
        self.stdout = self.proc.stdout
        self.buffer = bytearray()
        self.timeout = timeout

    def close(self) -> None:
        if self.proc.poll() is None:
            try:
                self.send_line("QUIT")
                self.read_until(BYE, timeout=3.0)
            except Exception:
                pass
            try:
                self.proc.terminate()
            except OSError:
                pass
        try:
            self.proc.wait(timeout=3.0)
        except subprocess.TimeoutExpired:
            self.proc.kill()

    def _read_some(self, timeout: float) -> bytes:
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.proc.poll() is not None:
                data = self.stdout.read() or b""
                if data:
                    return data
                raise RuntimeError("loader process exited")
            readable, _, _ = select.select([self.stdout], [], [], 0.1)
            if self.stdout in readable:
                data = os.read(self.stdout.fileno(), 4096)
                if data:
                    return data
        return b""

    def read_until(self, marker: bytes, timeout: float | None = None) -> bytes:
        deadline = time.time() + (self.timeout if timeout is None else timeout)
        while marker not in self.buffer:
            data = self._read_some(max(0.1, deadline - time.time()))
            if not data:
                break
            self.buffer.extend(data)
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()
            if time.time() >= deadline:
                break
        if marker not in self.buffer:
            raise TimeoutError(f"timed out waiting for {marker.decode(errors='replace')}")
        data = bytes(self.buffer)
        self.buffer.clear()
        return data

    def read_response(self) -> str:
        deadline = time.time() + self.timeout
        while time.time() < deadline:
            if b"\n" not in self.buffer:
                data = self._read_some(max(0.1, deadline - time.time()))
                if data:
                    self.buffer.extend(data)
                    sys.stdout.buffer.write(data)
                    sys.stdout.buffer.flush()
                    continue
            if b"\n" in self.buffer:
                line, _, rest = self.buffer.partition(b"\n")
                self.buffer = bytearray(rest)
                text = line.decode("ascii", errors="replace").strip()
                if text.startswith("OK ") or text.startswith("ERR "):
                    return text
        raise TimeoutError("timed out waiting for loader response")

    def send_line(self, line: str) -> None:
        self.stdin.write(line.encode("ascii") + b"\n")
        self.stdin.flush()

    def put_bytes(self, target: str, data: bytes, chunk_size: int, line_delay: float) -> None:
        crc = zlib.crc32(data) & 0xFFFFFFFF
        self.send_line(f"PUT {target} {len(data)} {crc:08X}")
        for offset in range(0, len(data), chunk_size):
            self.send_line(":" + data[offset : offset + chunk_size].hex().upper())
            if line_delay > 0:
                time.sleep(line_delay)
        self.send_line("END")
        response = self.read_response()
        if not response.startswith("OK "):
            raise RuntimeError(response)


def target_join(directory: str, name: str) -> str:
    directory = "/" + directory.strip("/")
    if directory == "/":
        return f"/{name}"
    return f"{directory}/{name}"


def collect_transfers(args: argparse.Namespace) -> list[tuple[Path, str]]:
    used: set[str] = set()
    transfers: list[tuple[Path, str]] = []

    for filename in args.file:
        src = Path(filename)
        if not src.is_file():
            raise FileNotFoundError(src)
        name = args.target_name if args.target_name else short_name(src, used)
        transfers.append((src, target_join(args.target_dir, name.upper())))

    if args.directory:
        directory = Path(args.directory)
        if not directory.is_dir():
            raise FileNotFoundError(directory)
        for src in sorted(path for path in directory.iterdir() if path.suffix.lower() == ".bin"):
            transfers.append((src, target_join(args.target_dir, short_name(src, used))))

    return transfers


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--loadp2", required=True)
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", required=True)
    parser.add_argument("--loader", required=True)
    parser.add_argument("--target-dir", default="/spin2")
    parser.add_argument("--file", action="append", default=[])
    parser.add_argument("--directory")
    parser.add_argument("--target-name")
    parser.add_argument("--chunk-size", type=int, default=128)
    parser.add_argument("--line-delay", type=float, default=0.01)
    parser.add_argument("--timeout", type=float, default=30.0)
    parser.add_argument("--no-index", action="store_true")
    args = parser.parse_args()

    if not args.file and not args.directory:
        parser.error("provide --file or --directory")
    if args.target_name and len(args.file) != 1:
        parser.error("--target-name is only valid with one --file")
    if args.chunk_size <= 0 or args.chunk_size > 256:
        parser.error("--chunk-size must be 1..256")

    transfers = collect_transfers(args)
    loader = Path(args.loader)
    if not loader.is_file():
        raise FileNotFoundError(loader)

    stop_stale_port_users(args.port)
    cmd = [args.loadp2, "-p", args.port, "-b", str(args.baud), "-t", str(loader)]
    print("[SDLoad] loading temporary SD receiver")
    session = LoaderSession(cmd, timeout=args.timeout)
    try:
        session.read_until(READY)
        session.send_line(f"MKDIR {args.target_dir}")
        response = session.read_response()
        if not response.startswith("OK "):
            raise RuntimeError(response)

        index_lines = []
        for src, target in transfers:
            data = src.read_bytes()
            crc = zlib.crc32(data) & 0xFFFFFFFF
            print(f"[SDLoad] {src} -> {target} ({len(data)} bytes, crc {crc:08X})")
            session.put_bytes(target, data, args.chunk_size, args.line_delay)
            index_lines.append(f"{target} {len(data)} {crc:08X} {src.name}\n")

        if transfers and not args.no_index:
            index_data = "".join(index_lines).encode("ascii")
            session.put_bytes(target_join(args.target_dir, "INDEX.TXT"), index_data, args.chunk_size, args.line_delay)

        session.send_line("QUIT")
        try:
            session.read_until(BYE, timeout=5.0)
        except TimeoutError:
            # Some loadp2 terminal sessions reset back into Berry immediately
            # after the loader returns; all file transfers have already been
            # acknowledged by this point.
            pass
        print("[SDLoad] done")
        return 0
    finally:
        session.close()


if __name__ == "__main__":
    raise SystemExit(main())
