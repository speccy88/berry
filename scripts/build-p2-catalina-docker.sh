#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"

if [ -z "${TARGET}" ]; then
    echo "usage: $0 <make-target>" >&2
    exit 1
fi

WORKDIR="${PWD}"
DOCKER_IMAGE="${CATALINA_DOCKER_IMAGE:-ubuntu:24.04}"
DOCKER_PLATFORM="${CATALINA_DOCKER_PLATFORM:-linux/amd64}"
CATALINA_DIR="${CATALINA_DIR:-.third_party_cache/catalina}"
FLEXPROP_DIR="${FLEXPROP_DIR:-.third_party_cache/flexprop}"
CATALINA_PLATFORM="${CATALINA_PLATFORM:-P2_EDGE}"
CATALINA_MODEL="${CATALINA_MODEL:-COMPACT}"

docker run --rm \
    --platform "${DOCKER_PLATFORM}" \
    -e DEBIAN_FRONTEND=noninteractive \
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
        apt-get update >/dev/null
        apt-get install -y make python3 >/dev/null
        export LCCDIR="${CATALINA_DIR}"
        source "${LCCDIR}/use_catalina" >/dev/null
        make "${TARGET}" \
            TOOLCHAIN=catalina \
            CATALINA_DIR="${CATALINA_DIR}" \
            FLEXPROP_DIR="${FLEXPROP_DIR}" \
            CATALINA_PLATFORM="${CATALINA_PLATFORM}" \
            CATALINA_MODEL="${CATALINA_MODEL}"
    '
