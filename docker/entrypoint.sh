#!/bin/sh
set -eu

HERMES_AGENT_PORT="${HERMES_AGENT_PORT:-${BACKEND_PORT:-5000}}"
HERMES_WEBUI_PORT="${HERMES_WEBUI_PORT:-${FRONTEND_PORT:-18789}}"
HERMES_AGENT_START_CMD="${HERMES_AGENT_START_CMD:-${BACKEND_START_CMD:-python app.py}}"
HERMES_WEBUI_DIR="${HERMES_WEBUI_DIR:-${FRONTEND_DIR:-/app/hermes-webui}}"
HERMES_WEBUI_BUILD_DIR="${HERMES_WEBUI_BUILD_DIR:-${FRONTEND_BUILD_DIR:-$HERMES_WEBUI_DIR/dist}}"

if [ ! -d "$HERMES_WEBUI_BUILD_DIR" ]; then
  if [ -d "$HERMES_WEBUI_DIR/build" ]; then
    HERMES_WEBUI_BUILD_DIR="$HERMES_WEBUI_DIR/build"
  else
    echo "[ERROR] Frontend build output not found at dist/ or build/." >&2
    exit 1
  fi
fi

cd /app/hermes-agent
sh -c "$HERMES_AGENT_START_CMD" &
HERMES_AGENT_PID=$!

serve -s "$HERMES_WEBUI_BUILD_DIR" -l "$HERMES_WEBUI_PORT" &
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
