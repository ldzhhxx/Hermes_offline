#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="${FRONTEND_DIR:-/app/frontend}"
BACKEND_DIR="${BACKEND_DIR:-/app/backend}"
FRONTEND_PORT="${FRONTEND_PORT:-18789}"
BACKEND_PORT="${BACKEND_PORT:-5000}"
FRONTEND_DEV_CMD="${FRONTEND_DEV_CMD:-npm run dev -- --host 0.0.0.0 --port ${FRONTEND_PORT}}"
BACKEND_DEV_CMD="${BACKEND_DEV_CMD:-python app.py}"

if [[ ! -d "$FRONTEND_DIR" ]]; then
  echo "[ERROR] FRONTEND_DIR not found: $FRONTEND_DIR" >&2
  exit 1
fi

if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "[ERROR] BACKEND_DIR not found: $BACKEND_DIR" >&2
  exit 1
fi

if [[ -f "$FRONTEND_DIR/package-lock.json" ]]; then
  npm --prefix "$FRONTEND_DIR" ci
elif [[ -f "$FRONTEND_DIR/package.json" ]]; then
  npm --prefix "$FRONTEND_DIR" install
else
  echo "[ERROR] package.json not found in $FRONTEND_DIR" >&2
  exit 1
fi

if [[ -f "$BACKEND_DIR/requirements.txt" ]]; then
  pip install --no-cache-dir -r "$BACKEND_DIR/requirements.txt"
fi

cd /app
concurrently \
  --prefix "[{name}]" \
  --names "backend,frontend" \
  --kill-others-on-fail \
  "cd $BACKEND_DIR && $BACKEND_DEV_CMD" \
  "cd $FRONTEND_DIR && $FRONTEND_DEV_CMD"
