#!/usr/bin/env bash
set -euo pipefail

# Fetch FlexProp host tools into this repository's ./bin directory.
# Defaults:
#   FLEXPROP_REPO=https://github.com/totalspectrum/flexprop.git
#   FLEXPROP_REF=master

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN_DIR="${ROOT_DIR}/bin"
TMP_DIR="${TMPDIR:-/tmp}/berry-flexprop-tools.$$"
FLEXPROP_REPO="${FLEXPROP_REPO:-https://github.com/totalspectrum/flexprop.git}"
FLEXPROP_REF="${FLEXPROP_REF:-master}"

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "[1/4] Cloning ${FLEXPROP_REPO} (${FLEXPROP_REF})..."
git clone --depth 1 --branch "${FLEXPROP_REF}" "${FLEXPROP_REPO}" "${TMP_DIR}/flexprop"

echo "[2/4] Preparing bin directory..."
mkdir -p "${BIN_DIR}"

echo "[3/4] Copying tools..."
for tool in \
    flexcc.mac flexcc.exe \
    flexspin.mac flexspin.exe \
    loadp2.mac loadp2.exe \
    proploader.mac proploader.exe \
    mac_terminal.sh
do
    src="${TMP_DIR}/flexprop/bin/${tool}"
    if [ -f "${src}" ]; then
        cp -f "${src}" "${BIN_DIR}/${tool}"
    fi
done

chmod +x \
    "${BIN_DIR}/flexcc.mac" \
    "${BIN_DIR}/flexspin.mac" \
    "${BIN_DIR}/loadp2.mac" \
    "${BIN_DIR}/proploader.mac" \
    "${BIN_DIR}/mac_terminal.sh" 2>/dev/null || true

echo "[4/4] Done."
echo "Tools now available in: ${BIN_DIR}"
