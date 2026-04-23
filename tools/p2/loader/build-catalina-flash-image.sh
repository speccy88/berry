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
DOCKER_IMAGE="${CATALINA_DOCKER_IMAGE:-berry-p2-catalina-builder:ubuntu24.04}"
DOCKER_PLATFORM="${CATALINA_DOCKER_PLATFORM:-linux/amd64}"

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

build_local() {
    export LCCDIR="$CATALINA_ABS"
    # shellcheck disable=SC1090
    source "$LCCDIR/use_catalina" >/dev/null
    cd "$WORK_ABS"
    bindump "$INPUT_ABS" -p " long $" > flash_program.inc
    p2_asm "$CATALINA_ABS/target/p2/flshload.t" -I . -o tmp_flash
    cp tmp_flash.bin "$OUTPUT_ABS"
}

build_docker() {
    local catalina_docker input_docker output_docker work_docker

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
    input_docker="$(to_docker_path "$INPUT_ABS")"
    output_docker="$(to_docker_path "$OUTPUT_ABS")"
    work_docker="$(to_docker_path "$WORK_ABS")"

    docker run --rm \
        --platform "$DOCKER_PLATFORM" \
        -v "$ROOT_DIR:/work" \
        -w /work \
        "$DOCKER_IMAGE" \
        bash -lc "set -euo pipefail; export LCCDIR='$catalina_docker'; source \"\$LCCDIR/use_catalina\" >/dev/null; mkdir -p '$work_docker'; cd '$work_docker'; bindump '$input_docker' -p ' long \$' > flash_program.inc; p2_asm \"\$LCCDIR/target/p2/flshload.t\" -I . -o tmp_flash; cp tmp_flash.bin '$output_docker'"
}

if command -v bindump >/dev/null 2>&1 && command -v p2_asm >/dev/null 2>&1; then
    build_local
elif command -v docker >/dev/null 2>&1; then
    build_docker
else
    echo "error: Catalina flash image generation needs bindump+p2_asm or Docker" >&2
    exit 1
fi
