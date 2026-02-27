#!/bin/bash
set -euo pipefail

########################################################

echo "Setting up SSH."

USER="group6"
PORT="22000"
SERVER="paffenroth-23.dyn.wpi.edu"
KEY_PATH="./ssh_keys/group_key"

LOCAL_DIR="./app/frontend/src/."
REMOTE_DIR="./app"

SSH_BASE=(ssh -i "${KEY_PATH}" -p "${PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)
SCP_BASE=(scp -i "${KEY_PATH}" -P "${PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

########################################################

echo "Copying app frontend to frontend server"

"${SSH_BASE[@]}" "rm -rf \"${REMOTE_DIR}\" && mkdir -p \"${REMOTE_DIR}\""
"${SCP_BASE[@]}" -r "${LOCAL_DIR}" "${USER}@${SERVER}:${REMOTE_DIR}"

########################################################

echo "Installing APT packages."

"${SSH_BASE[@]}" \
"sudo apt update && \
sudo apt install -y tmux python3 python3-venv python3-pip"

########################################################

echo "Creating Python virtual environment."

"${SSH_BASE[@]}" \
"cd \"${REMOTE_DIR}\" && \
python3 -m venv .venv && \
source .venv/bin/activate && \
pip install --upgrade pip --no-cache-dir && \
pip install gradio requests --no-cache-dir"

########################################################

echo "Start app frontend."

"${SSH_BASE[@]}" \
"cd \"${REMOTE_DIR}\" && \
(sudo fuser -k 7006/tcp || true) && \
(tmux kill-session -t frontend || true) && \
tmux new -d -s frontend \".venv/bin/python frontend.py\""

echo "Done."