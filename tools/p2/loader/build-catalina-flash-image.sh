#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 4 ]; then
    echo "usage: $0 <catalina-dir> <input-bin> <output-bin> <work-dir>" >&2
    exit 1
fi

CATALINA_DIR="$1"
INPUT_BIN="$2"
OUTPUT_BIN="$3"
WORK_DIR="$4"

ROOT_DIR="$(pwd)"

case "$CATALINA_DIR" in
    /*) CATALINA_ABS="$CATALINA_DIR" ;;
    *) CATALINA_ABS="$ROOT_DIR/$CATALINA_DIR" ;;
esac
BINDUMP_TOOL="${CATALINA_ABS}/bin/bindump"
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

prepare_flash_loader() {
    cp "$CATALINA_ABS/target/p2/flshload.t" "$WORK_ABS/flshload_berry.t"
    python3 - "$WORK_ABS/flshload_berry.t" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
old = """        outh    #spi_cs
        coginit #0,#0

send_byte2  rep @.loop,#8
"""
new = """        outh    #spi_cs
        call    #release_flash2
        call    #sd_idle2
        coginit #0,#0

release_flash2
        callpa  #enable_reset,#send_command2
        callpa  #device_reset,#send_command2
        waitx   ##sys_clk/1000
        callpa  #$B9,#send_command2
        waitx   ##sys_clk/100000
        drvh    #spi_cs
        drvl    #spi_clk
        drvh    #spi_di
        fltl    #spi_do
        fltl    #spi_di
        fltl    #spi_clk
        fltl    #spi_cs
        ret

sd_idle2
        drvh    #spi_clk     ' SD CS high on P2 Edge shared flash/SD pins
        drvl    #spi_cs      ' SD CLK low on P2 Edge shared flash/SD pins
        drvh    #spi_di
        fltl    #spi_do
        waitx   ##sys_clk/1000
        mov     count,#96
.idle_loop
        drvh    #spi_cs
        waitx   ##sys_clk/200000
        drvl    #spi_cs
        waitx   ##sys_clk/200000
        djnz    count,#.idle_loop
        waitx   ##sys_clk/100
        ret

send_command2
        drvl    #spi_cs
        call    #send_byte2
        drvh    #spi_cs
        ret

send_byte2  rep @.loop,#8
"""
if new not in text:
    if old not in text:
        raise SystemExit(f"flash loader patch pattern not found in {path}")
    text = text.replace(old, new)
path.write_text(text)
PY
}

build_local() {
    export LCCDIR="$CATALINA_ABS"
    # shellcheck disable=SC1090
    source "$LCCDIR/use_catalina" >/dev/null
    cd "$WORK_ABS"
    "$BINDUMP_TOOL" "$INPUT_ABS" -p " long $" > flash_program.inc
    "$P2_ASM_TOOL" "$WORK_ABS/flshload_berry.t" -I . -o tmp_flash
    cp tmp_flash.bin "$OUTPUT_ABS"
}

prepare_flash_loader

if [ -x "$BINDUMP_TOOL" ] && [ -x "$P2_ASM_TOOL" ]; then
    build_local
elif command -v bindump >/dev/null 2>&1 && command -v p2_asm >/dev/null 2>&1; then
    BINDUMP_TOOL="$(command -v bindump)"
    P2_ASM_TOOL="$(command -v p2_asm)"
    build_local
else
    echo "error: Catalina flash image generation needs native bindump and p2_asm" >&2
    exit 1
fi
