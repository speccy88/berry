#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ]; then
    echo "usage: $0 <catalina-dir> <input-xmm-bin> <output-flash-bin> <work-dir>" >&2
    exit 1
fi

CATALINA_DIR="$1"
INPUT_BIN="$2"
OUTPUT_BIN="$3"
WORK_DIR="$4"

ROOT_DIR="$(pwd)"
FLASH_LOADER_SRC="tools/p2/loader/catalina_xmm_flash_loader.c"
STAGE1_SRC="tools/p2/loader/flshboot_xmm_stage1.t"
COMPOSE_SCRIPT="tools/p2/loader/compose-catalina-xmm-flash.py"
LOADER_FLASH_ADDR="${P2_XMM_FLASH_LOADER_ADDR:-0x10000}"
APP_FLASH_ADDR="${P2_XMM_FLASH_APP_ADDR:-0x40000}"

case "$CATALINA_DIR" in
    /*) CATALINA_ABS="$CATALINA_DIR" ;;
    *) CATALINA_ABS="$ROOT_DIR/$CATALINA_DIR" ;;
esac
CATALINA_BIN="${CATALINA_ABS}/bin/catalina"
P2_ASM_TOOL="${CATALINA_ABS}/bin/p2_asm"
case "$INPUT_BIN" in
    /*) INPUT_ABS="$INPUT_BIN" ;;
    *) INPUT_ABS="$ROOT_DIR/$INPUT_BIN" ;;
esac
case "$OUTPUT_BIN" in
    /*) OUTPUT_ABS="$OUTPUT_BIN" ;;
    *) OUTPUT_ABS="$ROOT_DIR/$OUTPUT_BIN" ;;
esac
case "$WORK_DIR" in
    /*) WORK_ABS="$WORK_DIR" ;;
    *) WORK_ABS="$ROOT_DIR/$WORK_DIR" ;;
esac

mkdir -p "$WORK_ABS" "$(dirname "$OUTPUT_ABS")"

normalize_binary_output() {
    local base="$1"
    local dest="$2"

    if [ -f "${base}.bin" ]; then
        cp "${base}.bin" "$dest"
    elif [ -f "${base}.binary" ]; then
        cp "${base}.binary" "$dest"
    elif [ -f "$base" ]; then
        cp "$base" "$dest"
    else
        echo "error: expected Catalina binary output for ${base}" >&2
        exit 1
    fi
}

repo_relative_path() {
    local path="$1"

    case "$path" in
        "$ROOT_DIR"/*) printf '%s\n' "${path#"$ROOT_DIR"/}" ;;
        *) printf '%s\n' "$path" ;;
    esac
}

compile_loader_local() {
    local loader_base
    local stage1_base
    local loader_src
    local stage1_src

    loader_base="$(repo_relative_path "$WORK_ABS/xmm_flash_loader")"
    stage1_base="$(repo_relative_path "$WORK_ABS/xmm_flash_stage1")"
    loader_src="$(repo_relative_path "$ROOT_DIR/$FLASH_LOADER_SRC")"
    stage1_src="$(repo_relative_path "$ROOT_DIR/$STAGE1_SRC")"

    export CATALINA_DIR="$CATALINA_ABS"
    export CATALINA_INCLUDE="$CATALINA_ABS/include"
    export CATALINA_TARGET="$CATALINA_ABS/target"
    export CATALINA_LIBRARY="$CATALINA_ABS"
    export LCCDIR="$CATALINA_ABS"
    export PATH="$CATALINA_ABS/bin:$PATH"
    "$CATALINA_BIN" \
        -C99 \
        -p2 \
        -lci \
        -lpsram \
        -R0x10000 \
        -C NO_HMI \
        -C P2_CUSTOM \
        -D "BERRY_XMM_FLASH_ADDR=$APP_FLASH_ADDR" \
        -o "$loader_base" \
        "$loader_src"
    normalize_binary_output "$loader_base" "$WORK_ABS/xmm_flash_loader.binary"
    "$P2_ASM_TOOL" "$stage1_src" -o "$stage1_base"
    normalize_binary_output "$stage1_base" "$WORK_ABS/xmm_flash_stage1.binary"
}

if [ -x "$CATALINA_BIN" ] && [ -x "$P2_ASM_TOOL" ]; then
    compile_loader_local
else
    echo "error: Catalina XMM flash image generation needs native Catalina and p2_asm" >&2
    exit 1
fi

"${PYTHON:-python3}" "$COMPOSE_SCRIPT" \
    --stage1 "$WORK_ABS/xmm_flash_stage1.binary" \
    --loader "$WORK_ABS/xmm_flash_loader.binary" \
    --app "$INPUT_ABS" \
    --output "$OUTPUT_ABS" \
    --loader-addr "$LOADER_FLASH_ADDR" \
    --app-addr "$APP_FLASH_ADDR" \
    --metadata "$WORK_ABS/xmm_flash_image.json"
