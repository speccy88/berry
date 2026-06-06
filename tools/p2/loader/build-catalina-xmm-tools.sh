#!/usr/bin/env bash
set -euo pipefail

CATALINA_DIR="${1:?usage: $0 <catalina-dir> <host-out-dir> <loader-out-dir>}"
HOST_OUT_DIR="${2:?usage: $0 <catalina-dir> <host-out-dir> <loader-out-dir>}"
LOADER_OUT_DIR="${3:?usage: $0 <catalina-dir> <host-out-dir> <loader-out-dir>}"

CATALINA_BIN="${CATALINA_DIR}/bin/catalina"
CATALINA_SRC="${CATALINA_DIR}/source/catalina"
LUA_SRC="${CATALINA_SRC}/lua-5.4.8/src"
LOADER_SRC="${CATALINA_DIR}/utilities/Catalina_SIO_Loader.c"

mkdir -p "${HOST_OUT_DIR}" "${LOADER_OUT_DIR}"

if [ ! -x "${CATALINA_BIN}" ]; then
    echo "error: Catalina compiler not found at ${CATALINA_BIN}" >&2
    exit 1
fi

if [ ! -f "${CATALINA_SRC}/payload.c" ]; then
    echo "error: Catalina payload source not found under ${CATALINA_SRC}" >&2
    exit 1
fi

case "$(uname -s)" in
    Darwin)
        LUA_MAKE_TARGET=macosx
        CURSES_LIB=-lcurses
        ;;
    Linux)
        LUA_MAKE_TARGET=linux
        CURSES_LIB=-lncurses
        ;;
    *)
        echo "error: unsupported host OS for native Catalina payload build: $(uname -s)" >&2
        exit 1
        ;;
esac

make -C "${LUA_SRC}" "${LUA_MAKE_TARGET}" >/dev/null

cc \
    -Wno-format-security \
    -Wno-implicit-function-declaration \
    -Wno-int-conversion \
    -Wno-incompatible-pointer-types \
    -Wno-deprecated-non-prototype \
    -I"${CATALINA_SRC}" \
    -I"${LUA_SRC}" \
    -o "${HOST_OUT_DIR}/payload" \
    "${CATALINA_SRC}/payload.c" \
    "${CATALINA_SRC}/rs232.c" \
    "${CATALINA_SRC}/base64.c" \
    "${CATALINA_SRC}/fymodem.c" \
    "${CATALINA_SRC}/kb.c" \
    "${LUA_SRC}/linit.c" \
    -L"${LUA_SRC}" \
    -llua \
    -lm \
    ${CURSES_LIB}

loader_cmd=$(printf '%q ' \
    "${CATALINA_BIN}" \
    "${LOADER_SRC}" \
    -p2 \
    -lci \
    -lserial2 \
    -lpsram \
    -R0x10000 \
    -C NO_HMI \
    -C P2_CUSTOM \
    -o "${LOADER_OUT_DIR}/XMM_USB")

if "${CATALINA_BIN}" -h >/dev/null 2>&1; then
    CATALINA_DIR="${CATALINA_DIR}" \
    CATALINA_INCLUDE="${CATALINA_DIR}/include" \
    CATALINA_TARGET="${CATALINA_DIR}/target" \
    CATALINA_LIBRARY="${CATALINA_DIR}" \
    LCCDIR="${CATALINA_DIR}" \
    PATH="${CATALINA_DIR}/bin:${PATH}" \
        bash -lc "${loader_cmd}"
else
    DOCKER_IMAGE="${CATALINA_DOCKER_IMAGE:-berry-p2-catalina-builder:ubuntu24.04}"
    DOCKER_PLATFORM="${CATALINA_DOCKER_PLATFORM:-linux/amd64}"
    DEFAULT_BASE_IMAGE="${CATALINA_DOCKER_BASE_IMAGE:-ubuntu:24.04}"

    if ! docker image inspect "${DOCKER_IMAGE}" >/dev/null 2>&1; then
        docker build \
            --platform "${DOCKER_PLATFORM}" \
            -t "${DOCKER_IMAGE}" \
            -<<EOF
FROM ${DEFAULT_BASE_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \\
    && apt-get install -y --no-install-recommends make python3 \\
    && rm -rf /var/lib/apt/lists/*
EOF
    fi

    docker run --rm \
        --platform "${DOCKER_PLATFORM}" \
        -v "${PWD}:/work" \
        -w /work \
        -e CATALINA_DIR="${CATALINA_DIR}" \
        -e CATALINA_INCLUDE="${CATALINA_DIR}/include" \
        -e CATALINA_TARGET="${CATALINA_DIR}/target" \
        -e CATALINA_LIBRARY="${CATALINA_DIR}" \
        -e LCCDIR="${CATALINA_DIR}" \
        "${DOCKER_IMAGE}" \
        bash -lc "set -euo pipefail; source \"${CATALINA_DIR}/use_catalina\" >/dev/null; export PATH=\"${CATALINA_DIR}/bin:\${PATH}\"; ${loader_cmd}"
fi

if [ ! -f "${LOADER_OUT_DIR}/XMM_USB.bin" ]; then
    echo "error: Catalina did not create ${LOADER_OUT_DIR}/XMM_USB.bin" >&2
    exit 1
fi
cp "${LOADER_OUT_DIR}/XMM_USB.bin" "${LOADER_OUT_DIR}/XMM_USB.binary"
