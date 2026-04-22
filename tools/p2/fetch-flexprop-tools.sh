#!/usr/bin/env bash
set -euo pipefail

# Fetch FlexProp host tools (and matching headers) into this repository.
# Defaults:
#   FLEXPROP_REPO=https://github.com/totalspectrum/flexprop.git
#   FLEXPROP_REF=master

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOOLCHAIN_DIR="${ROOT_DIR}/tools/flexprop"
BIN_DIR="${TOOLCHAIN_DIR}/bin"
INC_DIR="${TOOLCHAIN_DIR}/include"
TMP_DIR="${TMPDIR:-/tmp}/berry-flexprop-tools.$$"
FLEXPROP_REPO="${FLEXPROP_REPO:-https://github.com/totalspectrum/flexprop.git}"
FLEXPROP_REF="${FLEXPROP_REF:-master}"
RELEASE_API="${RELEASE_API:-https://api.github.com/repos/totalspectrum/flexprop/releases/latest}"

TOOLS=(
    flexcc.mac flexcc.exe
    flexspin.mac flexspin.exe
    loadp2.mac loadp2.exe
    proploader.mac proploader.exe
    mac_terminal.sh
)

NATIVE_TOOLS=(
    flexcc
    flexspin
    loadp2
    proploader
)

CURL_API_OPTS=(-fsSL)
CURL_DOWNLOAD_OPTS=(-fL)
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        CURL_API_OPTS+=(--ssl-no-revoke)
        CURL_DOWNLOAD_OPTS+=(--ssl-no-revoke)
        ;;
esac

cleanup() {
    rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "[1/4] Preparing bin directory..."
mkdir -p "${BIN_DIR}"
mkdir -p "${INC_DIR}"

copy_tools_from() {
    local src_dir="$1"
    local copied=0
    for tool in "${TOOLS[@]}"; do
        if [ -f "${src_dir}/${tool}" ]; then
            cp -f "${src_dir}/${tool}" "${BIN_DIR}/${tool}"
            copied=$((copied + 1))
        fi
    done
    return "${copied}"
}

copy_include_from() {
    local src_dir="$1"
    if [ -d "${src_dir}" ]; then
        rm -rf "${INC_DIR}"
        mkdir -p "${TOOLCHAIN_DIR}"
        cp -R "${src_dir}" "${INC_DIR}"
    fi
}

echo "[2/4] Trying FlexProp latest release assets..."
ZIP_URL="$(curl "${CURL_API_OPTS[@]}" "${RELEASE_API}" | grep -Eo 'https://[^"]*\.zip' | grep -E 'flexprop|FlexProp' | head -n1 || true)"

if [ -n "${ZIP_URL}" ]; then
    mkdir -p "${TMP_DIR}"
    curl "${CURL_DOWNLOAD_OPTS[@]}" "${ZIP_URL}" -o "${TMP_DIR}/flexprop.zip"
    unzip -q "${TMP_DIR}/flexprop.zip" -d "${TMP_DIR}/release"
    if [ -d "${TMP_DIR}/release/flexprop/bin" ]; then
        copy_tools_from "${TMP_DIR}/release/flexprop/bin" || true
    fi
    if [ -d "${TMP_DIR}/release/flexprop/include" ]; then
        copy_include_from "${TMP_DIR}/release/flexprop/include"
    fi
else
    echo "No flexprop.zip release asset found; falling back to source build."
fi

if [ ! -f "${BIN_DIR}/flexcc.mac" ] || [ ! -f "${BIN_DIR}/loadp2.mac" ] || \
   [ ! -f "${BIN_DIR}/flexcc.exe" ] || [ ! -f "${BIN_DIR}/loadp2.exe" ]; then
    echo "[3/4] Release did not provide the full host tool set, building native tools from source..."
    git clone --recursive --depth 1 --branch "${FLEXPROP_REF}" "${FLEXPROP_REPO}" "${TMP_DIR}/flexprop-src"
    (
        cd "${TMP_DIR}/flexprop-src"
        # Build native host tools (works on standard macOS/Linux toolchains).
        make bin/flexspin bin/flexcc bin/loadp2
        make bin/proploader || true
        cp -f mac_scripts/mac_terminal.sh bin/mac_terminal.sh
    )
    copy_tools_from "${TMP_DIR}/flexprop-src/bin" || true
    copy_include_from "${TMP_DIR}/flexprop-src/spin2cpp/include"
    for t in "${NATIVE_TOOLS[@]}"; do
        if [ -f "${TMP_DIR}/flexprop-src/bin/${t}" ] && [ ! -f "${BIN_DIR}/${t}.mac" ]; then
            cp -f "${TMP_DIR}/flexprop-src/bin/${t}" "${BIN_DIR}/${t}.mac"
        fi
    done
else
    echo "[3/4] Required macOS and Windows tools already populated from release."
fi

chmod +x \
    "${BIN_DIR}/flexcc.mac" \
    "${BIN_DIR}/flexspin.mac" \
    "${BIN_DIR}/loadp2.mac" \
    "${BIN_DIR}/proploader.mac" \
    "${BIN_DIR}/mac_terminal.sh" 2>/dev/null || true

if [ ! -f "${BIN_DIR}/flexcc.mac" ] || [ ! -f "${BIN_DIR}/loadp2.mac" ] || \
   [ ! -f "${BIN_DIR}/flexcc.exe" ] || [ ! -f "${BIN_DIR}/loadp2.exe" ]; then
    echo "ERROR: required tools were not found (need flexcc/loadp2 in both .mac and .exe forms)." >&2
    echo "Check the release asset layout above and ensure the download completed successfully." >&2
    exit 1
fi
if [ ! -f "${INC_DIR}/stddef.h" ]; then
    echo "ERROR: required FlexProp headers were not found (${INC_DIR}/stddef.h)." >&2
    echo "The compiler needs matching include files from FlexProp." >&2
    exit 1
fi

echo "[4/4] Done."
echo "Toolchain now available in: ${TOOLCHAIN_DIR}"
echo "Installed:"
ls -1 "${BIN_DIR}" | grep -E '^(flexcc|flexspin|loadp2|proploader|mac_terminal)\.' || true
