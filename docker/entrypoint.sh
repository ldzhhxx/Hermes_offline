#!/bin/sh
set -eu

BACKEND_PORT="${BACKEND_PORT:-5000}"
FRONTEND_PORT="${FRONTEND_PORT:-18789}"
BACKEND_START_CMD="${BACKEND_START_CMD:-python app.py}"
FRONTEND_DIR="${FRONTEND_DIR:-/app/frontend}"
FRONTEND_BUILD_DIR="${FRONTEND_BUILD_DIR:-$FRONTEND_DIR/dist}"

if [ ! -d "$FRONTEND_BUILD_DIR" ]; then
  if [ -d "$FRONTEND_DIR/build" ]; then
    FRONTEND_BUILD_DIR="$FRONTEND_DIR/build"
  else
    echo "[ERROR] Frontend build output not found at dist/ or build/." >&2
    exit 1
  fi
fi

cd /app/backend
sh -c "$BACKEND_START_CMD" &
BACKEND_PID=$!

serve -s "$FRONTEND_BUILD_DIR" -l "$FRONTEND_PORT" &
FRONTEND_PID=$!

term_handler() {
  kill -TERM "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
  wait "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
}

trap term_handler INT TERM

wait -n "$BACKEND_PID" "$FRONTEND_PID"
EXIT_CODE=$?
term_handler
exit "$EXIT_CODE"
