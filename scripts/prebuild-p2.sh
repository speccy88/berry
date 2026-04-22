#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ]; then
    echo "usage: $0 <coc> <output-dir> <config> <src> [<src> ...]" >&2
    exit 1
fi

PYTHON_CMD="${PYTHON_CMD:-python3}"
COC="$1"
OUTPUT_DIR="$2"
CONFIG="$3"
shift 3

mkdir -p "$OUTPUT_DIR"
"$PYTHON_CMD" "$COC" -o "$OUTPUT_DIR" "$@" -c "$CONFIG"
