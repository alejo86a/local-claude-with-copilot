#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-4141}"
BASE_URL="http://localhost:${PORT}"
LOG_FILE="${LOG_FILE:-/tmp/copilot-api.log}"
SETTINGS_FILE="${CLAUDE_SETTINGS_FILE:-${HOME}/.claude/settings.json}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/copilot-model-check.XXXXXX")"
MODEL_LIST_FILE="${WORK_DIR}/models.json"
RESPONSE_FILE="${WORK_DIR}/response.json"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

ensure_command() {
  local command_name
  for command_name in copilot-api curl node lsof; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
      echo "Error: '${command_name}' is required but was not found in PATH."
      if [[ "${command_name}" == "copilot-api" ]]; then
        echo "Install it with: npm install -g copilot-api"
      fi
      exit 1
    fi
  done
}

proxy_is_ready() {
  curl -fsS --max-time 3 "${BASE_URL}/usage" >/dev/null 2>&1
}

clear_stale_listener() {
  local pids pid command_line
  pids="$(lsof -t -nP -iTCP:"${PORT}" -sTCP:LISTEN 2>/dev/null || true)"
  [[ -z "${pids}" ]] && return 0

  while IFS= read -r pid; do
    [[ -z "${pid}" ]] && continue
    command_line="$(ps -p "${pid}" -o command= 2>/dev/null || true)"
    if [[ "${command_line}" != *copilot-api* ]]; then
      echo "Error: port ${PORT} is occupied by a non-copilot-api process (PID ${pid})."
      echo "Inspect it with: lsof -nP -iTCP:${PORT} -sTCP:LISTEN"
      exit 1
    fi
    echo "Stopping stale copilot-api process ${pid} on port ${PORT}."
    kill "${pid}" 2>/dev/null || true
  done <<< "${pids}"

  for ((i=1; i<=10; i++)); do
    [[ -z "$(lsof -t -nP -iTCP:"${PORT}" -sTCP:LISTEN 2>/dev/null || true)" ]] && return 0
    sleep 1
  done
  echo "Error: stale proxy process did not release port ${PORT}."
  exit 1
}

start_proxy() {
  echo "Starting local Copilot proxy on port ${PORT}..."
  nohup copilot-api start -p "${PORT}" >"${LOG_FILE}" 2>&1 </dev/null &
}

wait_for_proxy() {
  for ((i=1; i<=30; i++)); do
    if proxy_is_ready; then
      echo "Proxy ready: ${BASE_URL}"
      return 0
    fi
    sleep 1
  done

  echo "Error: proxy did not respond at ${BASE_URL}/usage."
  echo "Check log: ${LOG_FILE}"
  exit 1
}

read_configured_model() {
  local setting_key="$1"
  node - "${SETTINGS_FILE}" "${setting_key}" <<'NODE'
const fs = require('fs');
const [file, key] = process.argv.slice(2);
try {
  const settings = JSON.parse(fs.readFileSync(file, 'utf8'));
  process.stdout.write(String(settings.env?.[key] || ''));
} catch {
  process.stdout.write('');
}
NODE
}

get_model_candidates() {
  local family="$1"
  local configured_model="$2"
  node - "${MODEL_LIST_FILE}" "${family}" "${configured_model}" <<'NODE'
const fs = require('fs');
const [file, family, preferred] = process.argv.slice(2);
const catalog = JSON.parse(fs.readFileSync(file, 'utf8'));
const ids = family === 'provider-fallback'
  ? ['gpt-4.1', 'gpt-4o']
  : [...new Set((catalog.data || [])
      .map(model => model.id)
      .filter(id => typeof id === 'string' && id.startsWith('claude-') &&
        (family === 'all' || id.includes(family))))];
const ordered = [];
if (preferred && (family === 'all' || family === 'provider-fallback' ||
    (preferred.startsWith('claude-') && preferred.includes(family)))) {
  ordered.push(preferred);
}
const priority = id => id.includes('sonnet') ? 0 : id.includes('haiku') ? 1 : id.includes('opus') ? 2 : 3;
for (const id of ids.sort((left, right) => priority(left) - priority(right))) {
  if (!ordered.includes(id)) ordered.push(id);
}
process.stdout.write(`${ordered.join('\n')}\n`);
NODE
}

probe_model() {
  local model="$1"
  local http_status
  local payload
  payload="$(node -e 'process.stdout.write(JSON.stringify({model:process.argv[1],max_tokens:4,messages:[{role:"user",content:"Reply only OK"}]}))' "${model}")"

  if ! http_status="$(curl -sS --max-time 30 -o "${RESPONSE_FILE}" -w '%{http_code}' \
    -X POST "${BASE_URL}/v1/messages" \
    -H 'content-type: application/json' \
    -H 'anthropic-version: 2023-06-01' \
    -H 'x-api-key: sk-dummy' \
    --data "${payload}")"; then
    http_status="000"
  fi

  if [[ "${http_status}" =~ ^2[0-9][0-9]$ ]] && node - "${RESPONSE_FILE}" <<'NODE'
const fs = require('fs');
try {
  const response = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  process.exit(response.type === 'message' && Array.isArray(response.content) ? 0 : 1);
} catch {
  process.exit(1);
}
NODE
  then
    return 0
  fi

  if grep -q 'model_not_supported' "${RESPONSE_FILE}"; then
    return 1
  fi

  echo "Error: real model probe failed for ${model} (HTTP ${http_status})."
  echo "This is not a model-name mismatch. Check GitHub Copilot authentication, entitlement, and proxy log: ${LOG_FILE}"
  return 2
}

select_supported_model() {
  local family="$1"
  local preferred="$2"
  local model result
  local candidates=()
  local count=0

  while IFS= read -r model; do
    [[ -n "${model}" ]] && candidates+=("${model}")
  done < <(get_model_candidates "${family}" "${preferred}")

  if [[ "${#candidates[@]}" -eq 0 ]]; then
    echo "Error: the proxy provides no candidates for model family '${family}'."
    return 1
  fi

  for model in "${candidates[@]}"; do
    count=$((count + 1))
    if probe_model "${model}"; then
      printf '%s' "${model}"
      return 0
    else
      result=$?
      [[ "${result}" -eq 1 ]] || return "${result}"
      echo "Model candidate ${model} was rejected by Copilot; trying the next ${family} candidate." >&2
    fi
  done

  echo "Error: no candidate in model family '${family}' accepted a real request."
  return 1
}

persist_model_settings() {
  local sonnet_backend="$1"
  local haiku_backend="$2"
  local opus_backend="$3"
  mkdir -p "$(dirname "${SETTINGS_FILE}")"
  node - "${SETTINGS_FILE}" "${BASE_URL}" "${sonnet_backend}" "${haiku_backend}" "${opus_backend}" <<'NODE'
const fs = require('fs');
const [file, baseUrl, sonnetBackend, haikuBackend, opusBackend] = process.argv.slice(2);
const models = {
  sonnet: { id: sonnetBackend, behavesAs: 'claude-sonnet-5' },
  haiku: { id: haikuBackend, behavesAs: 'claude-sonnet-5' },
  opus: { id: opusBackend, behavesAs: 'claude-sonnet-5' }
};
let settings = {};
let mode = 0o600;
try {
  const stat = fs.statSync(file);
  mode = stat.mode & 0o777;
  settings = JSON.parse(fs.readFileSync(file, 'utf8'));
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}
settings.env = settings.env || {};
settings.env.ANTHROPIC_BASE_URL = baseUrl;
settings.env.ANTHROPIC_AUTH_TOKEN = settings.env.ANTHROPIC_AUTH_TOKEN || 'sk-dummy';
settings.env.ANTHROPIC_MODEL = sonnetBackend;
settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL = sonnetBackend;
settings.env.ANTHROPIC_DEFAULT_HAIKU_MODEL = haikuBackend;
settings.env.ANTHROPIC_SMALL_FAST_MODEL = haikuBackend;
settings.env.ANTHROPIC_DEFAULT_OPUS_MODEL = opusBackend;
settings.model = sonnetBackend;
const modelOptions = new Map();
for (const model of Object.values(models)) {
  if (!modelOptions.has(model.id)) {
    modelOptions.set(model.id, {
      model: model.id,
      label: `Copilot via ${model.id}`,
      behavesAs: model.behavesAs
    });
  }
}
settings.modelPicker = settings.modelPicker || {};
settings.modelPicker.replaceBuiltInOptions = true;
settings.modelPicker.options = [...modelOptions.values()];
for (const staleId of ['claude-sonnet-5', 'claude-haiku-4.5', 'claude-opus-4.8']) {
  if (settings.modelOverrides) delete settings.modelOverrides[staleId];
}
if (settings.modelOverrides && Object.keys(settings.modelOverrides).length === 0) {
  delete settings.modelOverrides;
}
const temporary = `${file}.${process.pid}.tmp`;
fs.writeFileSync(temporary, `${JSON.stringify(settings, null, 2)}\n`, { mode });
fs.chmodSync(temporary, mode);
fs.renameSync(temporary, file);
NODE
}

ensure_command

if ! proxy_is_ready; then
  clear_stale_listener
  start_proxy
  wait_for_proxy
else
  echo "Reusing healthy local proxy: ${BASE_URL}"
fi

if ! curl -fsS --max-time 15 "${BASE_URL}/v1/models" -o "${MODEL_LIST_FILE}"; then
  echo "Error: proxy is healthy but its model catalog could not be read."
  echo "Check log: ${LOG_FILE}"
  exit 1
fi

if ! node - "${MODEL_LIST_FILE}" <<'NODE'
const fs = require('fs');
try {
  const catalog = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
  process.exit(Array.isArray(catalog.data) ? 0 : 1);
} catch {
  process.exit(1);
}
NODE
then
  echo "Error: proxy returned an invalid model catalog."
  exit 1
fi

CURRENT_SONNET="$(read_configured_model ANTHROPIC_DEFAULT_SONNET_MODEL)"
[[ -n "${CURRENT_SONNET}" ]] || CURRENT_SONNET="$(read_configured_model ANTHROPIC_MODEL)"
CURRENT_HAIKU="$(read_configured_model ANTHROPIC_DEFAULT_HAIKU_MODEL)"
CURRENT_OPUS="$(read_configured_model ANTHROPIC_DEFAULT_OPUS_MODEL)"

echo "Checking Claude model support with real, minimal requests..."
if ! SONNET_MODEL="$(select_supported_model sonnet "${CURRENT_SONNET}")"; then
  echo "No Sonnet model passed the real-request check; checking documented Copilot fallback models." >&2
  if ! SONNET_MODEL="$(select_supported_model provider-fallback "${CURRENT_SONNET}")"; then
    echo "No documented fallback passed; checking the remaining advertised Claude models." >&2
    SONNET_MODEL="$(select_supported_model all "")" || {
      echo "No Claude or documented fallback model accepted a real request. Check 'copilot-api check-usage', account model access, and run 'copilot-api auth' if the GitHub session expired."
      exit 1
    }
  fi
  HAIKU_MODEL="${SONNET_MODEL}"
  OPUS_MODEL="${SONNET_MODEL}"
  echo "Using verified Copilot backend ${SONNET_MODEL} for Claude Code's model slots." >&2
else
  HAIKU_MODEL="$(select_supported_model haiku "${CURRENT_HAIKU}")" || HAIKU_MODEL="${SONNET_MODEL}"
  OPUS_MODEL="$(select_supported_model opus "${CURRENT_OPUS}")" || OPUS_MODEL="${SONNET_MODEL}"
fi

persist_model_settings "${SONNET_MODEL}" "${HAIKU_MODEL}" "${OPUS_MODEL}"
echo "Claude Code model picker configured with verified Copilot backend(s): Sonnet=${SONNET_MODEL}, Haiku=${HAIKU_MODEL}, Opus=${OPUS_MODEL}"
echo "Updated Claude settings: ${SETTINGS_FILE}"
