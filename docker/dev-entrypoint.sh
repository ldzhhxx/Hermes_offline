#!/usr/bin/env bash
set -euo pipefail

HERMES_WEBUI_DIR="${HERMES_WEBUI_DIR:-${FRONTEND_DIR:-/app/hermes-webui}}"
HERMES_AGENT_DIR="${HERMES_AGENT_DIR:-${BACKEND_DIR:-/app/hermes-agent}}"
HERMES_WEBUI_PORT="${HERMES_WEBUI_PORT:-${FRONTEND_PORT:-18789}}"
HERMES_AGENT_PORT="${HERMES_AGENT_PORT:-${BACKEND_PORT:-5000}}"
HERMES_WEBUI_DEV_CMD="${HERMES_WEBUI_DEV_CMD:-${FRONTEND_DEV_CMD:-npm run dev -- --host 0.0.0.0 --port ${HERMES_WEBUI_PORT}}}"
HERMES_AGENT_DEV_CMD="${HERMES_AGENT_DEV_CMD:-${BACKEND_DEV_CMD:-python app.py}}"

if [[ ! -d "$HERMES_WEBUI_DIR" ]]; then
  echo "[ERROR] HERMES_WEBUI_DIR not found: $HERMES_WEBUI_DIR" >&2
  exit 1
fi

if [[ ! -d "$HERMES_AGENT_DIR" ]]; then
  echo "[ERROR] HERMES_AGENT_DIR not found: $HERMES_AGENT_DIR" >&2
  exit 1
fi

if [[ -f "$HERMES_WEBUI_DIR/package-lock.json" ]]; then
  npm --prefix "$HERMES_WEBUI_DIR" ci
elif [[ -f "$HERMES_WEBUI_DIR/package.json" ]]; then
  npm --prefix "$HERMES_WEBUI_DIR" install
else
  echo "[ERROR] package.json not found in $HERMES_WEBUI_DIR" >&2
  exit 1
fi

if [[ -f "$HERMES_AGENT_DIR/requirements.txt" ]]; then
  pip install --no-cache-dir -r "$HERMES_AGENT_DIR/requirements.txt"
fi

cd /app
concurrently \
  --prefix "[{name}]" \
  --names "hermes-agent,hermes-webui" \
  --kill-others-on-fail \
  "cd $HERMES_AGENT_DIR && $HERMES_AGENT_DEV_CMD" \
  "cd $HERMES_WEBUI_DIR && $HERMES_WEBUI_DEV_CMD"
