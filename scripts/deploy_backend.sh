#!/bin/bash
set -euo pipefail

########################################################

echo "Setting up SSH."

USER="group06"
PORT="22006"
SERVER="paffenroth-23.dyn.wpi.edu"
GROUP_KEY="./ssh_keys/group_key"
SECURE_KEY="./ssh_keys/secure_key"
SECURE_PUB="./ssh_keys/secure_key.pub"
HF_TOKEN_FILE="./ssh_keys/token.txt"
GITHUB_REPO="https://github.com/Perazok008/Case-Study-2.git"

REPO_DIR="./app"
APP_DIR="${REPO_DIR}/backend"
BACKEND_PORT="9006"

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null)

########################################################

echo "Setting up SSH keys."

SECURE_PUB_KEY="$(cat "${SECURE_PUB}")"
ssh -i "${GROUP_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "echo '${SECURE_PUB_KEY}' > ~/.ssh/authorized_keys" || true

echo "Verifying secure key access."
ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" "echo 'SSH OK'" || {
  echo "ERROR: Cannot connect with secure key."; exit 1;
}

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

HF_TOKEN="$(tr -d '[:space:]' < "${HF_TOKEN_FILE}")"
ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "printf 'export HF_TOKEN=%s\n' '${HF_TOKEN}' > ${APP_DIR}/.env"

########################################################

echo "Creating Python virtual environment."

ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
"cd ${APP_DIR} && \
python3 -m venv .venv && \
source .venv/bin/activate && \
pip install --upgrade pip --no-cache-dir && \
pip install -r requirements.txt --no-cache-dir"

########################################################

echo "Writing startup script."

ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "printf '%s\n' '#!/bin/bash' '. ${APP_DIR}/.env' 'cd ${APP_DIR}' '. .venv/bin/activate' 'exec uvicorn backend:app --host 0.0.0.0 --port ${BACKEND_PORT}' > ${APP_DIR}/start.sh && chmod +x ${APP_DIR}/start.sh"

echo "Starting app backend."

ssh -t -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "pkill -f 'uvicorn' 2>/dev/null || true; tmux kill-session -t backend 2>/dev/null || true; tmux new-session -d -s backend 'bash ${APP_DIR}/start.sh'" || true

echo "Verifying backend is up..."
sleep 5
ssh -i "${SECURE_KEY}" -p "${PORT}" "${SSH_OPTS[@]}" "${USER}@${SERVER}" \
  "curl -sf http://localhost:${BACKEND_PORT}/health > /dev/null && echo 'Backend OK'" || \
  echo "WARNING: Backend health check failed -- check tmux session 'backend' on the VM."

echo "Done."
