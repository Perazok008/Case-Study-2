#!/bin/bash
set -euo pipefail

########################################################

echo "Setting up SSH."

USER="group06"
PORT="22006"
SERVER="paffenroth-23.dyn.wpi.edu"
KEY_PATH="./ssh_keys/secure_key"

LOCAL_DIR="./backend/."
REMOTE_DIR="./app"
BACKEND_PORT="9006"
HF_TOKEN_FILE="./ssh_keys/token.txt"

SSH_BASE=(ssh -i "${KEY_PATH}" -p "${PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${USER}@${SERVER}")
SCP_BASE=(scp -i "${KEY_PATH}" -P "${PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

########################################################

echo "Copying app backend to backend server."

"${SSH_BASE[@]}" "rm -rf ${REMOTE_DIR} && mkdir -p ${REMOTE_DIR}"
"${SCP_BASE[@]}" -r "${LOCAL_DIR}" "${USER}@${SERVER}:${REMOTE_DIR}"
"${SCP_BASE[@]}" ./backend/requirements.txt "${USER}@${SERVER}:${REMOTE_DIR}/requirements.txt"

########################################################

echo "Writing environment file."

HF_TOKEN="$(tr -d '[:space:]' < "${HF_TOKEN_FILE}")"
"${SSH_BASE[@]}" "printf 'export HF_TOKEN=%s\n' '${HF_TOKEN}' > ${REMOTE_DIR}/.env"

########################################################

echo "Installing APT packages."

"${SSH_BASE[@]}" \
"sudo DEBIAN_FRONTEND=noninteractive apt update && \
sudo DEBIAN_FRONTEND=noninteractive apt install -y tmux python3 python3-venv python3-pip"

########################################################

echo "Creating Python virtual environment."

"${SSH_BASE[@]}" \
"cd ${REMOTE_DIR} && \
python3 -m venv .venv && \
source .venv/bin/activate && \
pip install --upgrade pip --no-cache-dir && \
pip install -r requirements.txt --no-cache-dir"

########################################################

echo "Starting app backend."

"${SSH_BASE[@]}" \
"(pkill -f 'uvicorn' || true) && \
(tmux kill-session -t backend || true) && \
tmux new -d -s backend 'source ${REMOTE_DIR}/.env && cd ${REMOTE_DIR} && source .venv/bin/activate && uvicorn backend:app --host 0.0.0.0 --port ${BACKEND_PORT}'"

echo "Done."
