#!/bin/bash
set -euo pipefail

########################################################

echo "Setting up SSH."

USER="group06"
PORT="22000"
SERVER="paffenroth-23.dyn.wpi.edu"
GROUP_KEY="./ssh_keys/group_key"
SECURE_KEY="./ssh_keys/secure_key"
SECURE_PUB="./ssh_keys/secure_key.pub"
GITHUB_REPO="https://github.com/Perazok008/Case-Study-2.git"

REPO_DIR="./app"
APP_DIR="${REPO_DIR}/frontend"
FRONTEND_PORT="7006"
BACKEND_URL="http://paffenroth-23.dyn.wpi.edu:9006"

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

########################################################

echo "Setting up SSH keys."

SECURE_PUB_KEY="$(cat "${SECURE_PUB}")"
ssh -i "${GROUP_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "grep -qF '${SECURE_PUB_KEY}' ~/.ssh/authorized_keys || echo '${SECURE_PUB_KEY}' >> ~/.ssh/authorized_keys" || true

########################################################

echo "Installing APT packages."

ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
"sudo DEBIAN_FRONTEND=noninteractive apt update && \
sudo DEBIAN_FRONTEND=noninteractive apt install -y tmux python3 python3-venv python3-pip git"

########################################################

echo "Cloning repository."

ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "rm -rf ${REPO_DIR} && git clone --depth 1 ${GITHUB_REPO} ${REPO_DIR}"

########################################################

echo "Writing environment file."

ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "printf 'export BACKEND_URL=%s\nexport PORT=%s\n' '${BACKEND_URL}' '${FRONTEND_PORT}' > ${APP_DIR}/.env"

########################################################

echo "Creating Python virtual environment."

ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
"cd ${APP_DIR} && \
python3 -m venv .venv && \
source .venv/bin/activate && \
pip install --upgrade pip --no-cache-dir && \
pip install -r requirements.txt --no-cache-dir"

########################################################

echo "Starting app frontend."

ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
"(sudo fuser -k ${FRONTEND_PORT}/tcp || true) && \
(tmux kill-session -t frontend 2>/dev/null || true) && \
tmux new-session -d -s frontend && \
tmux send-keys -t frontend '. ${APP_DIR}/.env && cd ${APP_DIR} && . .venv/bin/activate && python app.py' Enter"

echo "Verifying frontend is up..."
sleep 5
ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "curl -sf http://localhost:${FRONTEND_PORT}/ > /dev/null && echo 'Frontend OK'" || \
  echo "WARNING: Frontend health check failed -- check tmux session 'frontend' on the VM."

echo "Done."
