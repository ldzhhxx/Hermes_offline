#!/bin/sh
set -eu

HERMES_AGENT_PORT="${HERMES_AGENT_PORT:-${BACKEND_PORT:-5000}}"
HERMES_WEBUI_PORT="${HERMES_WEBUI_PORT:-${FRONTEND_PORT:-18789}}"
HERMES_AGENT_START_CMD="${HERMES_AGENT_START_CMD:-${BACKEND_START_CMD:-python app.py}}"
HERMES_WEBUI_START_CMD="${HERMES_WEBUI_START_CMD:-${FRONTEND_START_CMD:-python server.py --host 0.0.0.0 --port $HERMES_WEBUI_PORT}}"

cd /app/hermes-agent
sh -c "$HERMES_AGENT_START_CMD" &
HERMES_AGENT_PID=$!

cd /app/hermes-webui
sh -c "$HERMES_WEBUI_START_CMD" &
HERMES_WEBUI_PID=$!

term_handler() {
  kill -TERM "$HERMES_AGENT_PID" "$HERMES_WEBUI_PID" 2>/dev/null || true
  wait "$HERMES_AGENT_PID" "$HERMES_WEBUI_PID" 2>/dev/null || true
}

trap term_handler INT TERM

wait -n "$HERMES_AGENT_PID" "$HERMES_WEBUI_PID"
EXIT_CODE=$?
term_handler
exit "$EXIT_CODE"
