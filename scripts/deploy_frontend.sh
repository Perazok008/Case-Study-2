#!/bin/bash
set -euo pipefail

########################################################

echo "Setting up SSH."

USER="group06"
PORT="22000"
SERVER="paffenroth-23.dyn.wpi.edu"
KEY_PATH="./ssh_keys/group_key"

LOCAL_DIR="./frontend/."
REMOTE_DIR="./app"
FRONTEND_PORT="7006"
BACKEND_URL="http://paffenroth-23.dyn.wpi.edu:9006"

SSH_BASE=(ssh -i "${KEY_PATH}" -p "${PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${USER}@${SERVER}")
SCP_BASE=(scp -i "${KEY_PATH}" -P "${PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

########################################################

echo "Copying app frontend to frontend server."

"${SSH_BASE[@]}" "rm -rf ${REMOTE_DIR} && mkdir -p ${REMOTE_DIR}"
"${SCP_BASE[@]}" -r "${LOCAL_DIR}" "${USER}@${SERVER}:${REMOTE_DIR}"
"${SCP_BASE[@]}" ./frontend/requirements.txt "${USER}@${SERVER}:${REMOTE_DIR}/requirements.txt"

########################################################

echo "Writing environment file."

"${SSH_BASE[@]}" "printf 'export BACKEND_URL=%s\nexport PORT=%s\n' '${BACKEND_URL}' '${FRONTEND_PORT}' > ${REMOTE_DIR}/.env"

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

echo "Starting app frontend."

"${SSH_BASE[@]}" \
"(sudo fuser -k ${FRONTEND_PORT}/tcp || true) && \
(tmux kill-session -t frontend || true) && \
tmux new -d -s frontend 'source ${REMOTE_DIR}/.env && cd ${REMOTE_DIR} && source .venv/bin/activate && python app.py'"

echo "Done."
