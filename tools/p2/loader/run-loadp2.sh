#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ]; then
    echo "usage: $0 <loadp2> <port> <baud> <flags> <image>" >&2
    exit 1
fi

LOADP2="$1"
PORT="$2"
BAUD="$3"
FLAGS="$4"
IMAGE="$5"

if [ ! -f "$IMAGE" ]; then
    echo "error: missing image: $IMAGE" >&2
    exit 1
fi

exec "$LOADP2" -p "$PORT" -b "$BAUD" $FLAGS "$IMAGE"
