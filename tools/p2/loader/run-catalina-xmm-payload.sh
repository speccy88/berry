#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ]; then
    echo "usage: $0 <payload> <port> <baud> <loader-image> <app-image> [payload-flags...]" >&2
    exit 2
fi

payload="$1"
port="$2"
baud="$3"
loader_image="$4"
app_image="$5"
shift 5

interval="${P2_XMM_LOAD_PROGRESS_INTERVAL:-10}"
if ! [[ "${interval}" =~ ^[0-9]+$ ]] || [ "${interval}" -lt 1 ]; then
    interval=10
fi

app_bytes="$(wc -c < "${app_image}" | tr -d '[:space:]')"
loader_bytes="$(wc -c < "${loader_image}" | tr -d '[:space:]')"

echo "[XMM Load] Port ${port} @ ${baud}"
echo "[XMM Load] Loader ${loader_image} (${loader_bytes} bytes)"
echo "[XMM Load] Image ${app_image} (${app_bytes} bytes)"
echo "[XMM Load] Catalina payload may be quiet while transferring to PSRAM."

start="$(date +%s)"
"${payload}" -p "${port}" -b "${baud}" "$@" "${loader_image}" "${app_image}" &
pid="$!"

while kill -0 "${pid}" 2>/dev/null; do
    sleep "${interval}"
    if kill -0 "${pid}" 2>/dev/null; then
        now="$(date +%s)"
        echo "[XMM Load] Still transferring after $((now - start))s..."
    fi
done

if wait "${pid}"; then
    end="$(date +%s)"
    echo "[XMM Load] Payload finished after $((end - start))s."
    echo "[XMM Load] Waiting for Berry banner/prompt is the next step."
else
    status="$?"
    end="$(date +%s)"
    echo "[XMM Load] Payload failed with status ${status} after $((end - start))s." >&2
    exit "${status}"
fi
