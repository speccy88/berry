#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
import time


SUITES = {
    "quick": [
        ("print(6*7)", "42"),
        ('s="abc"; print(s+"def")', "abcdef"),
        ('m={"a":2,"b":5}; print(m["a"]+m["b"])', "7"),
        ("import math; print(math.sqrt(81))", "9"),
    ],
    "full": [
        ('run_file("/tests/p2/smoke_all.be")', "P2_SMOKE_PASS all"),
    ],
    "edge32": [
        ('run_file("/tests/p2/smoke_edge32_all.be")', "P2_SMOKE_PASS edge32_all"),
    ],
}

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


def run_command(ser, command: str, expected: str, line_ending: bytes, prompt: bytes, timeout: float) -> str:
    ser.write(command.encode("utf-8") + line_ending)
    ser.flush()
    output = read_until(ser, prompt, timeout)
    text = decode(output)
    if expected and expected not in text:
        raise AssertionError(
            f"expected {expected!r} after command {command!r}; saw:\n{text}"
        )
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Berry P2 REPL smoke commands over serial.")
    parser.add_argument("--port", required=True, help="serial device, for example /dev/cu.usbserial-P97cvdxp")
    parser.add_argument("--baud", type=int, default=230400, help="serial baud rate")
    parser.add_argument("--suite", choices=sorted(SUITES), default="full")
    parser.add_argument("--timeout", type=float, default=20.0, help="seconds to wait for each prompt")
    parser.add_argument("--startup-timeout", type=float, default=20.0, help="seconds to wait for the first prompt")
    parser.add_argument("--line-ending", choices=sorted(LINE_ENDINGS), default="cr")
    parser.add_argument("--prompt", default="berry>")
    parser.add_argument(
        "--no-wait-start",
        action="store_true",
        help="send commands immediately instead of waiting for the initial prompt",
    )
    args = parser.parse_args()

    serial = load_serial_module()
    prompt = args.prompt.encode("utf-8")
    line_ending = LINE_ENDINGS[args.line_ending]

    with serial.Serial(args.port, args.baud, timeout=0.05, write_timeout=2.0) as ser:
        ser.reset_input_buffer()
        if not args.no_wait_start:
            print(f"[p2-smoke] waiting for {args.prompt!r} on {args.port} at {args.baud}")
            text = decode(read_until(ser, prompt, args.startup_timeout))
            sys.stdout.write(text)
            if text and not text.endswith("\n"):
                sys.stdout.write("\n")

        for command, expected in SUITES[args.suite]:
            print(f"[p2-smoke] {command}")
            text = run_command(ser, command, expected, line_ending, prompt, args.timeout)
            sys.stdout.write(text)
            if text and not text.endswith("\n"):
                sys.stdout.write("\n")

    print(f"[p2-smoke] PASS {args.suite}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
