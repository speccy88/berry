#!/usr/bin/env bash
set -u

if [ "$#" -ne 1 ]; then
    echo "usage: $0 LOG" >&2
    exit 2
fi

log=$1
mkdir -p "$(dirname "$log")"
rm -f "$log"

set +e
bash -lc 'set -o pipefail; (printf "%s\n" "P2_CATALINA_PIPEFAIL_SELFTEST"; exit 37) 2>&1 | tee "$1"' bash "$log"
status=$?
set -e

if [ "$status" -eq 0 ]; then
    echo "error: failing Catalina pipeline was reported as success" >&2
    exit 1
fi

if [ "$status" -ne 37 ]; then
    echo "error: expected pipefail status 37, got $status" >&2
    exit 1
fi

if ! grep -q "P2_CATALINA_PIPEFAIL_SELFTEST" "$log"; then
    echo "error: failing pipeline output was not captured in $log" >&2
    exit 1
fi

rm -f "$log"
echo "ok: Catalina build-log pipefail guard reports failures and captures output"
