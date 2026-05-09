#!/usr/bin/env bash
set -euo pipefail

cd /app

BACKEND_CMD=${BACKEND_CMD:-"python -m flask --app hermes-agent run --host 0.0.0.0 --port ${HERMES_BACKEND_PORT}"}
FRONTEND_CMD=${FRONTEND_CMD:-"npm --prefix /app/hermes-webui run dev -- --host 0.0.0.0 --port ${HERMES_FRONTEND_PORT}"}

if [ -f /app/hermes-agent/main.py ] && [ -z "${BACKEND_CMD_OVERRIDE:-}" ]; then
  BACKEND_CMD="python /app/hermes-agent/main.py"
fi

if [ -f /app/hermes-webui/package.json ] && npm --prefix /app/hermes-webui run | grep -q "start"; then
  FRONTEND_CMD=${FRONTEND_CMD_OVERRIDE:-"npm --prefix /app/hermes-webui run start -- --host 0.0.0.0 --port ${HERMES_FRONTEND_PORT}"}
fi

echo "[Hermes] Starting backend: $BACKEND_CMD"
bash -lc "$BACKEND_CMD" &
BACK_PID=$!

echo "[Hermes] Starting frontend: $FRONTEND_CMD"
bash -lc "$FRONTEND_CMD" &
FRONT_PID=$!

cleanup() {
  kill -TERM "$BACK_PID" "$FRONT_PID" 2>/dev/null || true
}
trap cleanup SIGTERM SIGINT

wait -n "$BACK_PID" "$FRONT_PID"
EXIT_CODE=$?
cleanup
wait || true
exit "$EXIT_CODE"
