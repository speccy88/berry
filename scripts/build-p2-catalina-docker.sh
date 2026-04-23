#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"

if [ -z "${TARGET}" ]; then
    echo "usage: $0 <make-target>" >&2
    exit 1
fi

WORKDIR="${PWD}"
DEFAULT_BASE_IMAGE="ubuntu:24.04"
DOCKER_IMAGE="${CATALINA_DOCKER_IMAGE:-berry-p2-catalina-builder:ubuntu24.04}"
DOCKER_PLATFORM="${CATALINA_DOCKER_PLATFORM:-linux/amd64}"
CATALINA_DIR="${CATALINA_DIR:-.third_party_cache/catalina}"
FLEXPROP_DIR="${FLEXPROP_DIR:-.third_party_cache/flexprop}"
CATALINA_PLATFORM="${CATALINA_PLATFORM:-P2_EDGE}"
CATALINA_MODEL="${CATALINA_MODEL:-COMPACT}"

if ! docker image inspect "${DOCKER_IMAGE}" >/dev/null 2>&1; then
    echo "[Docker] Building Catalina builder image: ${DOCKER_IMAGE}"
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
    -e TARGET="${TARGET}" \
    -e CATALINA_DIR="${CATALINA_DIR}" \
    -e FLEXPROP_DIR="${FLEXPROP_DIR}" \
    -e CATALINA_PLATFORM="${CATALINA_PLATFORM}" \
    -e CATALINA_MODEL="${CATALINA_MODEL}" \
    -v "${WORKDIR}:/work" \
    -w /work \
    "${DOCKER_IMAGE}" \
    bash -lc '
        set -euo pipefail
        export LCCDIR="${CATALINA_DIR}"
        source "${LCCDIR}/use_catalina" >/dev/null
        make "${TARGET}" \
            TOOLCHAIN=catalina \
            CATALINA_DIR="${CATALINA_DIR}" \
            FLEXPROP_DIR="${FLEXPROP_DIR}" \
            CATALINA_PLATFORM="${CATALINA_PLATFORM}" \
            CATALINA_MODEL="${CATALINA_MODEL}"
    '
