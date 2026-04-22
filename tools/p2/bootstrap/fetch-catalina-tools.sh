#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${1:-.third_party_cache/catalina}"

if [ -f "${INSTALL_DIR}/bin/catalina" ] || [ -f "${INSTALL_DIR}/bin/catalina.exe" ]; then
    echo "Catalina already present at ${INSTALL_DIR}"
    exit 0
fi

cat <<EOF
Catalina is not installed in ${INSTALL_DIR}.

This repository no longer vendors Catalina.

To use TOOLCHAIN=catalina, do one of the following:
  1. Point CATALINA_DIR at an existing Catalina installation.
  2. Set CATALINA_REPO to a cloneable Catalina source repository and rerun this script.

Example:
  CATALINA_REPO=<repo-url> bash tools/p2/bootstrap/fetch-catalina-tools.sh ${INSTALL_DIR}
EOF

if [ -z "${CATALINA_REPO:-}" ]; then
    exit 1
fi

mkdir -p "$(dirname "${INSTALL_DIR}")"
git clone --depth 1 "${CATALINA_REPO}" "${INSTALL_DIR}"
echo "Catalina source cloned to ${INSTALL_DIR}"
