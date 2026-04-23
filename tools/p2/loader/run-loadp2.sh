#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 6 ]; then
    echo "usage: $0 <loadp2> <port> <baud> <flags> <image> <python>" >&2
    exit 1
fi

LOADP2="$1"
PORT="$2"
BAUD="$3"
FLAGS="$4"
IMAGE="$5"
PYTHON="$6"

if [[ "$IMAGE" != @* ]] && [ ! -f "$IMAGE" ]; then
    echo "error: missing image: $IMAGE" >&2
    exit 1
fi

if command -v lsof >/dev/null 2>&1; then
    PIDS="$(lsof -t "$PORT" 2>/dev/null || true)"
    PIDS="$(printf '%s' "$PIDS" | tr '\n' ' ')"
    if [ -n "${PIDS// }" ]; then
        for pid in $PIDS; do
            cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
            case "$cmd" in
                *loadp2*" $PORT "*|*loadp2*"$PORT"*|*proploader*" $PORT "*|*proploader*"$PORT"*|*serial_terminal.py*" $PORT "*|*serial_terminal.py*"$PORT"*|*tio*" $PORT "*|*tio*"$PORT"*)
                    echo "[Loader] stopping stale terminal on $PORT (pid $pid)"
                    kill -CONT "$pid" 2>/dev/null || true
                    kill "$pid" 2>/dev/null || true
                    ;;
            esac
        done

        for _ in 1 2 3 4 5 6 7 8 9 10; do
            if ! lsof "$PORT" >/dev/null 2>&1; then
                break
            fi
            sleep 0.1
        done
    fi
fi

case " $FLAGS " in
    *" -t "*|*" -T "*|*" -xTERM "*)
        echo "[Loader] Press Ctrl-D or Ctrl-C at an empty berry prompt to quit Berry."
        echo "[Loader] Press Ctrl-] to disconnect from the serial terminal."
        exec "$PYTHON" tools/p2/loader/serial_terminal.py -- "$LOADP2" "$PORT" "$BAUD" "$FLAGS" "$IMAGE"
        ;;
    *)
        exec "$LOADP2" -p "$PORT" -b "$BAUD" $FLAGS "$IMAGE"
        ;;
esac
