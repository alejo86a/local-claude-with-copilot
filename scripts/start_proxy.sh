#!/usr/bin/env bash
set -u

PORT="${PORT:-4141}"
LOG_FILE="${LOG_FILE:-/tmp/copilot-api.log}"

ensure_command() {
  if ! command -v copilot-api >/dev/null 2>&1; then
    echo "Error: 'copilot-api' no está instalado o no está en PATH."
    echo "Instalar con: npm install -g copilot-api"
    exit 1
  fi
}

cleanup_stale_jobs() {
  local pid
  pid="$(lsof -t -nP -iTCP:${PORT} -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -n "$pid" ]]; then
    echo "Puerto ${PORT} ocupado por PID ${pid}. Limpieza previa..."
    kill "$pid" 2>/dev/null || true
    sleep 1
  fi
}

start_proxy() {
  echo "Levantando proxy local en puerto ${PORT}..."
  nohup copilot-api start -p "${PORT}" >"${LOG_FILE}" 2>&1 &
  sleep 2
}

wait_for_proxy() {
  local retries=30
  for ((i=1; i<=retries; i++)); do
    if curl -fsS "http://localhost:${PORT}/usage" >/dev/null 2>&1; then
      echo "Proxy listo: http://localhost:${PORT}"
      return 0
    fi
    sleep 1
  done

  echo "El proxy no respondió en http://localhost:${PORT}."
  echo "Ver log: ${LOG_FILE}"
  exit 1
}

ensure_command
cleanup_stale_jobs
start_proxy
wait_for_proxy
