#!/usr/bin/env bash
# Run the Python gRPC/relay service and the NestJS API in one container.
# If either process exits, kill the other so the platform restarts the whole
# container (rather than silently limping along with half the backend down).
set -euo pipefail

term() {
  echo "start.sh: shutting down..."
  kill -TERM "${PY_PID:-}" "${API_PID:-}" 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}
trap term TERM INT

echo "start.sh: launching Python gRPC + relay..."
( cd /app/grpc && python server.py ) &
PY_PID=$!

echo "start.sh: launching NestJS API..."
( cd /app/api && node dist/main ) &
API_PID=$!

# Exit (and let the platform restart us) as soon as either process dies.
wait -n "$PY_PID" "$API_PID"
echo "start.sh: a process exited; stopping container."
term
