#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
import sys
import time


LINE_ENDINGS = {
    "cr": b"\r",
    "lf": b"\n",
    "crlf": b"\r\n",
}


def load_serial_module():
    try:
        import serial  # type: ignore

        return serial
    except ImportError:
        print("error: pyserial is required: python3 -m pip install pyserial", file=sys.stderr)
        raise SystemExit(2)


def decode(data: bytes) -> str:
    return data.decode("utf-8", errors="replace")


def read_until(ser, marker: bytes, timeout: float) -> bytes:
    deadline = time.monotonic() + timeout
    data = bytearray()
    while time.monotonic() < deadline:
        chunk = ser.read(256)
        if chunk:
            data.extend(chunk)
            if marker in data:
                return bytes(data)
        else:
            time.sleep(0.02)
    raise TimeoutError(f"timed out waiting for {marker!r}; saw:\n{decode(bytes(data))}")


def berry_string(text: str) -> str:
    out = []
    for ch in text:
        code = ord(ch)
        if ch == "\\":
            out.append("\\\\")
        elif ch == '"':
            out.append('\\"')
        elif ch == "\n":
            out.append("\\n")
        elif ch == "\r":
            out.append("\\r")
        elif ch == "\t":
            out.append("\\t")
        elif code < 32 or code == 127:
            raise ValueError(f"unsupported control character U+{code:04X}")
        else:
            out.append(ch)
    return '"' + "".join(out) + '"'


def split_chunks(text: str, max_literal_body: int) -> list[str]:
    chunks: list[str] = []
    current: list[str] = []
    current_len = 0

    for ch in text:
        encoded = berry_string(ch)[1:-1]
        if current and current_len + len(encoded) > max_literal_body:
            chunks.append("".join(current))
            current = []
            current_len = 0
        current.append(ch)
        current_len += len(encoded)
    if current:
        chunks.append("".join(current))
    return chunks


def run_command(ser, command: str, line_ending: bytes, prompt: bytes, timeout: float) -> str:
    ser.write(command.encode("utf-8") + line_ending)
    ser.flush()
    text = decode(read_until(ser, prompt, timeout))
    if "syntax_error:" in text or "stack traceback:" in text:
        raise RuntimeError(f"Berry command failed: {command!r}\n{text}")
    return text


def run_command_allow_error(ser, command: str, line_ending: bytes, prompt: bytes, timeout: float) -> str:
    ser.write(command.encode("utf-8") + line_ending)
    ser.flush()
    return decode(read_until(ser, prompt, timeout))


def mount_sd(ser, line_ending: bytes, prompt: bytes, timeout: float) -> None:
    command = "import p2; assert(p2.fs_info(\"/\")[\"mount_result_name\"] == \"ok\")"
    last = ""
    for _ in range(5):
        last = run_command_allow_error(ser, command, line_ending, prompt, timeout)
        if "stack traceback:" not in last and "assert_failed:" not in last and "syntax_error:" not in last:
            return
        time.sleep(0.2)
    raise RuntimeError(f"Berry SD mount failed before upload\n{last}")


def target_join(directory: str, rel: str) -> str:
    directory = "/" + directory.strip("/")
    rel = rel.strip("/")
    if directory == "/":
        return "/" + rel
    return directory + "/" + rel


def ensure_path_parts(ser, parts: list[str], line_ending: bytes, prompt: bytes, timeout: float) -> None:
    if not parts:
        return
    run_command(ser, "import os", line_ending, prompt, timeout)
    current = ""
    for part in parts:
        current += "/" + part
        command = f"os.mkdir({berry_string(current)})"
        text = run_command_allow_error(ser, command, line_ending, prompt, timeout)
        if "stack traceback:" in text and "exist" not in text.lower():
            raise RuntimeError(f"Berry mkdir failed for {current!r}\n{text}")


def ensure_dirs(ser, target_path: str, line_ending: bytes, prompt: bytes, timeout: float) -> None:
    parts = [part for part in target_path.strip("/").split("/")[:-1] if part]
    ensure_path_parts(ser, parts, line_ending, prompt, timeout)


def ensure_dir(ser, target_dir: str, line_ending: bytes, prompt: bytes, timeout: float) -> None:
    parts = [part for part in target_dir.strip("/").split("/") if part]
    ensure_path_parts(ser, parts, line_ending, prompt, timeout)


def collect_files(directory: Path) -> list[Path]:
    return sorted(path for path in directory.rglob("*") if path.is_file() and not any(part.startswith(".") for part in path.parts))


def upload_file(ser, src: Path, target: str, line_ending: bytes, prompt: bytes, timeout: float, chunk_body: int) -> None:
    text = src.read_text(encoding="utf-8")
    ensure_dirs(ser, target, line_ending, prompt, timeout)
    print(f"[p2-upload] {src} -> {target} ({len(text.encode('utf-8'))} bytes)")
    run_command(ser, f"f=open({berry_string(target)},\"w\")", line_ending, prompt, timeout)
    for chunk in split_chunks(text, chunk_body):
        run_command(ser, f"f.write({berry_string(chunk)})", line_ending, prompt, timeout)
    run_command(ser, "f.close()", line_ending, prompt, timeout)


def main() -> int:
    parser = argparse.ArgumentParser(description="Upload text files to a running Berry P2 REPL.")
    parser.add_argument("--port", required=True)
    parser.add_argument("--baud", type=int, default=230400)
    parser.add_argument("--target-dir", required=True)
    parser.add_argument("--mkdir", action="append", default=[], help="create an empty target directory; repeat as needed")
    parser.add_argument("--recursive-directory", action="append", default=[])
    parser.add_argument("--file", action="append", default=[])
    parser.add_argument("--timeout", type=float, default=20.0)
    parser.add_argument("--line-ending", choices=sorted(LINE_ENDINGS), default="cr")
    parser.add_argument("--prompt", default="berry>")
    parser.add_argument("--chunk-body", type=int, default=96)
    args = parser.parse_args()

    if not args.mkdir and not args.recursive_directory and not args.file:
        parser.error("provide --mkdir, --file, or --recursive-directory")
    if args.chunk_body <= 0 or args.chunk_body > 160:
        parser.error("--chunk-body must be 1..160")

    transfers: list[tuple[Path, str]] = []
    for filename in args.file:
        src = Path(filename)
        if not src.is_file():
            raise FileNotFoundError(src)
        transfers.append((src, target_join(args.target_dir, src.name)))
    for dirname in args.recursive_directory:
        directory = Path(dirname)
        if not directory.is_dir():
            raise FileNotFoundError(directory)
        for src in collect_files(directory):
            rel = src.relative_to(directory).as_posix()
            transfers.append((src, target_join(args.target_dir, rel)))

    serial = load_serial_module()
    prompt = args.prompt.encode("utf-8")
    line_ending = LINE_ENDINGS[args.line_ending]
    ser = serial.Serial()
    ser.port = args.port
    ser.baudrate = args.baud
    ser.timeout = 0.05
    ser.write_timeout = 2.0
    ser.dtr = False
    ser.rts = False

    with ser:
        ser.reset_input_buffer()
        ser.write(line_ending)
        ser.flush()
        read_until(ser, prompt, args.timeout)
        mount_sd(ser, line_ending, prompt, args.timeout)
        for target_dir in args.mkdir:
            print(f"[p2-upload] mkdir {target_dir}")
            ensure_dir(ser, target_dir, line_ending, prompt, args.timeout)
        for src, target in transfers:
            upload_file(ser, src, target, line_ending, prompt, args.timeout, args.chunk_body)

    print("[p2-upload] done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
