#!/bin/bash
PATH=/usr/local/bin:/usr/bin:/bin

LOCKFILE="/tmp/cs2_monitor.lock"
exec 200>"${LOCKFILE}"
flock -n 200 || { echo "[$(date)] Another monitor instance running, exiting."; exit 0; }

BACKEND_URL="http://paffenroth-23.dyn.wpi.edu:9006/health"
FRONTEND_URL="http://paffenroth-23.dyn.wpi.edu:7006"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TIMEOUT=10

echo "[$(date)] Checking backend..."
if ! curl -sf --max-time "${TIMEOUT}" "${BACKEND_URL}" > /dev/null 2>&1; then
    echo "[$(date)] Backend DOWN -- redeploying..."
    cd "${REPO_DIR}" && bash scripts/deploy_backend.sh
    sleep 120
else
    echo "[$(date)] Backend OK"
fi

echo "[$(date)] Checking frontend..."
if ! curl -sf --max-time "${TIMEOUT}" "${FRONTEND_URL}" > /dev/null 2>&1; then
    echo "[$(date)] Frontend DOWN -- redeploying..."
    cd "${REPO_DIR}" && bash scripts/deploy_frontend.sh
    sleep 120
else
    echo "[$(date)] Frontend OK"
fi
