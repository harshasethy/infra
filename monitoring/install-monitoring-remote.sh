#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: $0 --host <control-plane-ip> --key <ssh-key.pem> [--user <ssh-user>]

Deploys the monitoring installer on a remote Kubernetes control plane node via SSH.

Options:
  --host     Control plane host IP or hostname
  --key      SSH private key file for remote access
  --user     SSH user (default: ubuntu)
  --port     SSH port (default: 22)
  --help     Show this help message
EOF
  exit 1
}

REMOTE_USER=ubuntu
REMOTE_HOST=""
SSH_KEY=""
SSH_PORT=22

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      REMOTE_HOST="$2"
      shift 2
      ;;
    --key)
      SSH_KEY="$2"
      shift 2
      ;;
    --user)
      REMOTE_USER="$2"
      shift 2
      ;;
    --port)
      SSH_PORT="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

if [[ -z "$REMOTE_HOST" || -z "$SSH_KEY" ]]; then
  usage
fi

for cmd in ssh scp; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command '$cmd' not found."
    exit 1
  fi
done

REMOTE_DIR="/tmp/monitoring-install"

ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p '${REMOTE_DIR}'"

scp -i "$SSH_KEY" -P "$SSH_PORT" -o StrictHostKeyChecking=no -r "${DIR}/install-monitoring.sh" "${DIR}/values.yaml" "${DIR}/namespace.yaml" "${DIR}/alerts" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "cd '${REMOTE_DIR}' && sudo chmod +x install-monitoring.sh && sudo ./install-monitoring.sh"

echo "Remote Prometheus install completed on ${REMOTE_HOST}."
