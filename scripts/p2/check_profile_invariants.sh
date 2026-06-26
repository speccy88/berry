#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 REPO_ROOT" >&2
    exit 2
fi

repo=$1
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

run_show_config() {
    local name=$1
    shift
    make -C "$repo" --no-print-directory show-config "$@" > "$tmpdir/$name"
}

require_line() {
    local file=$1
    local expected=$2
    if ! grep -Fxq "$expected" "$file"; then
        echo "error: expected '$expected' in $file" >&2
        echo "--- $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

require_absent() {
    local file=$1
    local needle=$2
    if grep -Fq -- "$needle" "$file"; then
        echo "error: unexpected '$needle' in $file" >&2
        echo "--- $file ---" >&2
        cat "$file" >&2
        exit 1
    fi
}

run_show_config edge32 TOOLCHAIN=catalina P2_PROFILE=edge32 P2_BOARD=p2edge32 \
    CATALINA_DIR=../Catalina CATALINA_MODEL=COMPACT CATALINA_CLIB=-lcx \
    CATALINA_SERIAL_LIB=-lpsram

require_line "$tmpdir/edge32" "P2_PROFILE=edge32"
require_line "$tmpdir/edge32" "P2_BOARD=p2edge32"
require_line "$tmpdir/edge32" "P2_BOARD_HAS_PSRAM=1"
require_line "$tmpdir/edge32" "P2_LED0_PIN=38"
require_line "$tmpdir/edge32" "P2_LED1_PIN=39"
require_line "$tmpdir/edge32" "CATALINA_MODEL=COMPACT"
require_line "$tmpdir/edge32" "CATALINA_CLIB=-lcx"
require_line "$tmpdir/edge32" "CATALINA_SERIAL_LIB=-lpsram"
require_line "$tmpdir/edge32" "CATALINA_DIR=../Catalina"
require_line "$tmpdir/edge32" "P2_IMAGE_LIMIT_NAME=P2 Hub RAM limit"
require_absent "$tmpdir/edge32" "CATALINA_MODEL=LARGE"
require_absent "$tmpdir/edge32" "-C PSRAM"

run_show_config xmm TOOLCHAIN=catalina P2_PROFILE=xmm P2_BOARD=p2edge32 \
    CATALINA_DIR=../Catalina CATALINA_MODEL=LARGE CATALINA_CLIB=-lcx \
    CATALINA_SERIAL_LIB=-lpsram

require_line "$tmpdir/xmm" "P2_PROFILE=xmm"
require_line "$tmpdir/xmm" "P2_BOARD=p2edge32"
require_line "$tmpdir/xmm" "P2_BOARD_HAS_PSRAM=1"
require_line "$tmpdir/xmm" "CATALINA_MODEL=LARGE"
require_line "$tmpdir/xmm" "CATALINA_SERIAL_LIB=-lpsram"
require_line "$tmpdir/xmm" "CATALINA_DIR=../Catalina"
require_line "$tmpdir/xmm" "P2_IMAGE_LIMIT_NAME=Catalina P2 XMM load image limit"
if ! grep -F "CATALINA_CONFIG_FLAGS=" "$tmpdir/xmm" | grep -Fq -- "-C PSRAM"; then
    echo "error: expected XMM config flags to include -C PSRAM" >&2
    cat "$tmpdir/xmm" >&2
    exit 1
fi

echo "ok: P2 Edge32 COMPACT fallback and XMM profile invariants hold"
