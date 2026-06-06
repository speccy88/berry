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
DOCKER_IMAGE="${CATALINA_DOCKER_IMAGE:-berry-p2-catalina-builder:ubuntu24.04}"
DOCKER_PLATFORM="${CATALINA_DOCKER_PLATFORM:-linux/amd64}"
FLASH_LOADER_SRC="tools/p2/loader/catalina_xmm_flash_loader.c"
STAGE1_SRC="tools/p2/loader/flshboot_xmm_stage1.t"
COMPOSE_SCRIPT="tools/p2/loader/compose-catalina-xmm-flash.py"
LOADER_FLASH_ADDR="${P2_XMM_FLASH_LOADER_ADDR:-0x10000}"
APP_FLASH_ADDR="${P2_XMM_FLASH_APP_ADDR:-0x40000}"

case "$CATALINA_DIR" in
    /*) CATALINA_ABS="$CATALINA_DIR" ;;
    *) CATALINA_ABS="$ROOT_DIR/$CATALINA_DIR" ;;
esac
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

to_docker_path() {
    local path="$1"
    case "$path" in
        "$ROOT_DIR"/*) printf '/work/%s' "${path#"$ROOT_DIR"/}" ;;
        "$ROOT_DIR") printf '/work' ;;
        *) return 1 ;;
    esac
}

compile_loader_local() {
    export LCCDIR="$CATALINA_ABS"
    # shellcheck disable=SC1090
    source "$LCCDIR/use_catalina" >/dev/null
    catalina "$ROOT_DIR/$FLASH_LOADER_SRC" \
        -p2 \
        -lci \
        -lpsram \
        -R0x10000 \
        -C NO_HMI \
        -C P2_CUSTOM \
        -D "BERRY_XMM_FLASH_ADDR=$APP_FLASH_ADDR" \
        -o "$WORK_ABS/xmm_flash_loader"
    cp "$WORK_ABS/xmm_flash_loader.bin" "$WORK_ABS/xmm_flash_loader.binary"
    p2_asm "$ROOT_DIR/$STAGE1_SRC" -o "$WORK_ABS/xmm_flash_stage1"
    cp "$WORK_ABS/xmm_flash_stage1.bin" "$WORK_ABS/xmm_flash_stage1.binary"
}

compile_loader_docker() {
    local catalina_docker work_docker loader_src_docker stage1_src_docker

    if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        echo "[Docker] Building Catalina builder image: $DOCKER_IMAGE"
        docker build \
            --platform "$DOCKER_PLATFORM" \
            -t "$DOCKER_IMAGE" \
            -<<'EOF'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends make python3 \
    && rm -rf /var/lib/apt/lists/*
EOF
    fi

    catalina_docker="$(to_docker_path "$CATALINA_ABS")"
    work_docker="$(to_docker_path "$WORK_ABS")"
    loader_src_docker="$(to_docker_path "$ROOT_DIR/$FLASH_LOADER_SRC")"
    stage1_src_docker="$(to_docker_path "$ROOT_DIR/$STAGE1_SRC")"

    docker run --rm \
        --platform "$DOCKER_PLATFORM" \
        -v "$ROOT_DIR:/work" \
        -w /work \
        "$DOCKER_IMAGE" \
        bash -lc "set -euo pipefail; export LCCDIR='$catalina_docker'; source \"\$LCCDIR/use_catalina\" >/dev/null; mkdir -p '$work_docker'; catalina '$loader_src_docker' -p2 -lci -lpsram -R0x10000 -C NO_HMI -C P2_CUSTOM -D 'BERRY_XMM_FLASH_ADDR=$APP_FLASH_ADDR' -o '$work_docker/xmm_flash_loader'; cp '$work_docker/xmm_flash_loader.bin' '$work_docker/xmm_flash_loader.binary'; p2_asm '$stage1_src_docker' -o '$work_docker/xmm_flash_stage1'; cp '$work_docker/xmm_flash_stage1.bin' '$work_docker/xmm_flash_stage1.binary'"
}

if "$CATALINA_ABS/bin/catalina" -h >/dev/null 2>&1 && command -v p2_asm >/dev/null 2>&1; then
    compile_loader_local
elif command -v docker >/dev/null 2>&1; then
    compile_loader_docker
else
    echo "error: Catalina XMM flash image generation needs Catalina+p2_asm or Docker" >&2
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
