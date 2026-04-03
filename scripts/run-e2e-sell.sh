#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="d:/SUM25/second-hand-evn-battery-trading-platform"
BE_DIR="$ROOT_DIR/be"
FE_DIR="$ROOT_DIR/FE"
SCRIPT_DIR="$ROOT_DIR/scripts"
BE_LOG="$(mktemp)"
FE_LOG="$(mktemp)"

cleanup() {
  local exit_code=$?
  if [[ -n "${FE_PID:-}" ]]; then
    kill "$FE_PID" 2>/dev/null || true
    wait "$FE_PID" 2>/dev/null || true
  fi
  if [[ -n "${BE_PID:-}" ]]; then
    kill "$BE_PID" 2>/dev/null || true
    wait "$BE_PID" 2>/dev/null || true
  fi
  if [[ -f "$BE_LOG" ]]; then
    echo "\n--- Backend log tail ---"
    tail -n 20 "$BE_LOG" || true
  fi
  if [[ -f "$FE_LOG" ]]; then
    echo "\n--- Frontend log tail ---"
    tail -n 20 "$FE_LOG" || true
  fi
  exit "$exit_code"
}
trap cleanup EXIT

cd "$BE_DIR"
yarn start:dev >"$BE_LOG" 2>&1 &
BE_PID=$!

echo "Waiting for backend to boot..."
for _ in {1..30}; do
  if curl -fsS "http://localhost:3000/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -fsS "http://localhost:3000/api/health" >/dev/null 2>&1; then
  echo "Backend failed to start within timeout"
  exit 1
fi

cd "$FE_DIR"
yarn dev >"$FE_LOG" 2>&1 &
FE_PID=$!

echo "Waiting for frontend to boot..."
for _ in {1..30}; do
  if curl -fsS "http://localhost:3001" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -fsS "http://localhost:3001" >/dev/null 2>&1; then
  echo "Frontend failed to start within timeout"
  exit 1
fi

echo "Running E2E sell flow via FE proxy..."
FE_BASE_URL="http://localhost:3001/be" node "$SCRIPT_DIR/e2e-sell.mjs"
