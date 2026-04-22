#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_URL="${1:-https://github.com/berry-lang/berry.git}"

if ! git remote get-url upstream >/dev/null 2>&1; then
    git remote add upstream "$UPSTREAM_URL"
fi

git fetch upstream
git remote -v | grep '^upstream'
