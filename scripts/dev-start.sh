#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PROJECT="$ROOT_DIR/002-code/HealthcareForm/HealthcareForm.csproj"
API_PROJECT_DIR="$(dirname "$API_PROJECT")"
FRONTEND_DIR="$ROOT_DIR/002-code/healthcareform-angular"
ENV_FILE="${HF_ENV_FILE:-$ROOT_DIR/.env.dev}"
RUNTIME_DIR="${HF_RUNTIME_DIR:-$ROOT_DIR/.dev-runtime}"
API_LOG_FILE="${HF_API_LOG_FILE:-$RUNTIME_DIR/api.log}"
API_OUTPUT_PATH="${HF_API_OUTPUT_PATH:-$API_PROJECT_DIR/bin/dev-start/}"

API_PORT="${HF_API_PORT:-5099}"
UI_PORT="${HF_UI_PORT:-4200}"
API_URL="${HF_API_URL:-http://127.0.0.1:${API_PORT}}"
API_HEALTH_PATH="${HF_API_HEALTH_PATH:-/api/health/live}"
API_DB_HEALTH_PATH="${HF_API_DB_HEALTH_PATH:-/api/health/db}"
REQUIRE_DB_HEALTH="${HF_API_REQUIRE_DB_HEALTH:-1}"
REQUIRE_API_SMOKE_CHECK="${HF_API_SMOKE_CHECK:-1}"
API_SMOKE_USERNAME="${HF_API_SMOKE_USERNAME:-}"
API_SMOKE_PASSWORD="${HF_API_SMOKE_PASSWORD:-}"
CONNECTION_STRING_FROM_ENV="${ConnectionStrings__HealthcareEntity:-}"
JWT_KEY_FROM_ENV="${Jwt__Key:-}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

if [[ -n "$CONNECTION_STRING_FROM_ENV" ]]; then
  ConnectionStrings__HealthcareEntity="$CONNECTION_STRING_FROM_ENV"
fi

if [[ -n "$JWT_KEY_FROM_ENV" ]]; then
  Jwt__Key="$JWT_KEY_FROM_ENV"
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

is_placeholder_connection_string() {
  local value="${1:-}"
  [[ -z "$value" \
     || "$value" == "YOUR_CONNECTION_STRING" \
     || "$value" == "__SET_CONNECTIONSTRINGS__HEALTHCAREENTITY_ENV_VAR__" \
     || "$value" == REPLACE_WITH_* \
     || "$value" == *"REPLACE_WITH_"* \
     || "$value" == *"__SET_CONNECTIONSTRINGS__"* \
     || "$value" == *"<password>"* \
     || "$value" != *"="* \
     || "$value" != *";"* ]]
}

is_placeholder_jwt_key() {
  local value="${1:-}"
  [[ -z "$value" \
     || "$value" == "__SET_JWT__KEY_ENV_VAR_MIN_32_CHARS__" \
     || "$value" == REPLACE_WITH_* \
     || ${#value} -lt 32 ]]
}

read_user_secret() {
  local key="$1"
  dotnet user-secrets list --project "$API_PROJECT" 2>/dev/null \
    | awk -v k="$key" 'index($0, k " = ") == 1 { print substr($0, length(k) + 4); exit }'
}

listening_pid() {
  lsof -tiTCP:"$1" -sTCP:LISTEN 2>/dev/null | head -n 1 || true
}

process_command() {
  ps -p "$1" -o cmd= 2>/dev/null || true
}

check_api_health() {
  curl -fsS "http://127.0.0.1:${API_PORT}${API_HEALTH_PATH}" >/dev/null 2>&1
}

check_api_db_health() {
  curl -fsS "http://127.0.0.1:${API_PORT}${API_DB_HEALTH_PATH}" >/dev/null 2>&1
}

run_api_smoke_check() {
  local login_body login_status login_response_body token worklist_status worklist_response_body
  local login_response_file worklist_response_file

  if [[ "$REQUIRE_API_SMOKE_CHECK" != "1" ]]; then
    return 0
  fi

  if [[ -z "$API_SMOKE_USERNAME" || -z "$API_SMOKE_PASSWORD" ]]; then
    cat >&2 <<EOF
API smoke check is enabled (HF_API_SMOKE_CHECK=1) but credentials are missing.
Set:
  HF_API_SMOKE_USERNAME=<username-or-email>
  HF_API_SMOKE_PASSWORD=<password>
Or disable this check:
  HF_API_SMOKE_CHECK=0
EOF
    return 1
  fi

  login_response_file="$(mktemp)"
  worklist_response_file="$(mktemp)"
  trap 'rm -f "$login_response_file" "$worklist_response_file"' RETURN

  login_body=$(printf '{"usernameOrEmail":"%s","password":"%s"}' "$API_SMOKE_USERNAME" "$API_SMOKE_PASSWORD")
  login_status="$(curl -sS -o "$login_response_file" -w "%{http_code}" \
    -X POST "http://127.0.0.1:${API_PORT}/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "$login_body")"
  login_response_body="$(cat "$login_response_file")"

  if [[ "$login_status" != "200" ]]; then
    echo "API smoke check failed: login returned HTTP ${login_status}." >&2
    echo "Login response: ${login_response_body}" >&2
    return 1
  fi

  token="$(printf '%s' "$login_response_body" | sed -n 's/.*"AccessToken":"\([^"]*\)".*/\1/p')"
  if [[ -z "$token" ]]; then
    echo "API smoke check failed: login succeeded but no AccessToken was returned." >&2
    echo "Login response: ${login_response_body}" >&2
    return 1
  fi

  worklist_status="$(curl -sS -o "$worklist_response_file" -w "%{http_code}" \
    "http://127.0.0.1:${API_PORT}/api/patients/worklist" \
    -H "Authorization: Bearer ${token}")"
  worklist_response_body="$(cat "$worklist_response_file")"

  if [[ "$worklist_status" != "200" ]]; then
    echo "API smoke check failed: /api/patients/worklist returned HTTP ${worklist_status}." >&2
    echo "Worklist response: ${worklist_response_body}" >&2
    return 1
  fi

  if [[ "${worklist_response_body:0:1}" != "[" ]]; then
    echo "API smoke check failed: /api/patients/worklist did not return a JSON array." >&2
    echo "Worklist response: ${worklist_response_body}" >&2
    return 1
  fi

  rm -f "$login_response_file" "$worklist_response_file"
  trap - RETURN
  return 0
}

require_command dotnet
require_command npm
require_command lsof
require_command curl

mkdir -p "$RUNTIME_DIR"

if is_placeholder_connection_string "${ConnectionStrings__HealthcareEntity:-}"; then
  USER_SECRET_CONNECTION_STRING="$(read_user_secret "ConnectionStrings:HealthcareEntity")"
  if [[ -n "$USER_SECRET_CONNECTION_STRING" ]]; then
    ConnectionStrings__HealthcareEntity="$USER_SECRET_CONNECTION_STRING"
    echo "Loaded ConnectionStrings__HealthcareEntity from dotnet user-secrets."
  fi
fi

if is_placeholder_connection_string "${ConnectionStrings__HealthcareEntity:-}"; then
  cat >&2 <<EOF
ConnectionStrings__HealthcareEntity appears to be a placeholder or invalid format.
Current value starts with: ${ConnectionStrings__HealthcareEntity:0:48}

Set it using dotnet user-secrets (recommended):
  dotnet user-secrets set "ConnectionStrings:HealthcareEntity" "Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=<password>;TrustServerCertificate=true" --project "$API_PROJECT"

Or set a valid SQL Server connection string in ${ENV_FILE} or your shell.
Example:
ConnectionStrings__HealthcareEntity="Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=<password>;TrustServerCertificate=true"
EOF
  exit 1
fi

if is_placeholder_jwt_key "${Jwt__Key:-}"; then
  USER_SECRET_JWT_KEY="$(read_user_secret "Jwt:Key")"
  if [[ -n "$USER_SECRET_JWT_KEY" ]]; then
    Jwt__Key="$USER_SECRET_JWT_KEY"
    echo "Loaded Jwt__Key from dotnet user-secrets."
  fi
fi

if is_placeholder_jwt_key "${Jwt__Key:-}"; then
  cat >&2 <<EOF
Jwt__Key appears to be a placeholder or too short.
It must be at least 32 characters.

Set it using dotnet user-secrets (recommended):
  dotnet user-secrets set "Jwt:Key" "<at-least-32-char-secret>" --project "$API_PROJECT"

Or set Jwt__Key in ${ENV_FILE} or your shell.
EOF
  exit 1
fi

API_STARTED_BY_SCRIPT=0
API_PID=""
API_WATCHER_PID=""

existing_api_pid="$(listening_pid "$API_PORT")"
if [[ -n "$existing_api_pid" ]]; then
  existing_api_cmd="$(process_command "$existing_api_pid")"
  if [[ "$existing_api_cmd" == *"HealthcareForm"* ]]; then
    if ! check_api_health; then
      echo "API process on port ${API_PORT} is not healthy (${API_HEALTH_PATH} failed)." >&2
      echo "Stop it and rerun the script." >&2
      exit 1
    fi

    if [[ "$REQUIRE_DB_HEALTH" == "1" ]] && ! check_api_db_health; then
      echo "API process on port ${API_PORT} failed DB health check (${API_DB_HEALTH_PATH})." >&2
      echo "Fix connection string/database and rerun the script." >&2
      exit 1
    fi

    echo "API already running on port ${API_PORT} (pid ${existing_api_pid}). Reusing it."
  else
    echo "Port ${API_PORT} is in use by pid ${existing_api_pid}: ${existing_api_cmd}" >&2
    echo "Stop that process or set HF_API_PORT/HF_API_URL before running this script." >&2
    exit 1
  fi
else
  echo "Starting backend API on ${API_URL}..."
  : > "$API_LOG_FILE"
  dotnet run --project "$API_PROJECT" --urls "$API_URL" \
    -p:BaseOutputPath="$API_OUTPUT_PATH" \
    >> "$API_LOG_FILE" 2>&1 &
  API_PID=$!
  API_STARTED_BY_SCRIPT=1

  echo -n "Waiting for API"
  for _ in {1..80}; do
    if check_api_health; then
      echo " ready."
      break
    fi
    echo -n "."
    sleep 0.25
  done
  echo

  if ! check_api_health; then
    echo "API did not start on ${API_URL}. Check startup output above." >&2
    echo "Startup log: ${API_LOG_FILE}" >&2
    tail -n 60 "$API_LOG_FILE" >&2 || true
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
    exit 1
  fi

  if [[ "$REQUIRE_DB_HEALTH" == "1" ]] && ! check_api_db_health; then
    echo "API started but DB health check failed at ${API_DB_HEALTH_PATH}." >&2
    echo "Fix connection string/database and rerun the script." >&2
    echo "Startup log: ${API_LOG_FILE}" >&2
    tail -n 60 "$API_LOG_FILE" >&2 || true
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
    exit 1
  fi

  if ! run_api_smoke_check; then
    echo "API smoke check failed. Startup log: ${API_LOG_FILE}" >&2
    tail -n 60 "$API_LOG_FILE" >&2 || true
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
    exit 1
  fi

  echo "API smoke check passed (/api/auth/login -> /api/patients/worklist)."
fi

start_api_watcher() {
  if [[ "$API_STARTED_BY_SCRIPT" -ne 1 || -z "$API_PID" ]]; then
    return
  fi

  (
    while true; do
      sleep 2
      if ! kill -0 "$API_PID" >/dev/null 2>&1; then
        echo
        echo "Backend API exited unexpectedly (pid ${API_PID})." >&2
        echo "Backend log: ${API_LOG_FILE}" >&2
        tail -n 60 "$API_LOG_FILE" >&2 || true
        break
      fi
    done
  ) &

  API_WATCHER_PID=$!
}

cleanup() {
  if [[ -n "$API_WATCHER_PID" ]] && kill -0 "$API_WATCHER_PID" >/dev/null 2>&1; then
    kill "$API_WATCHER_PID" >/dev/null 2>&1 || true
    wait "$API_WATCHER_PID" >/dev/null 2>&1 || true
  fi

  if [[ "$API_STARTED_BY_SCRIPT" -eq 1 && -n "$API_PID" ]] && kill -0 "$API_PID" >/dev/null 2>&1; then
    echo
    echo "Stopping backend API (pid ${API_PID})..."
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

existing_ui_pid="$(listening_pid "$UI_PORT")"
if [[ -n "$existing_ui_pid" ]]; then
  existing_ui_cmd="$(process_command "$existing_ui_pid")"
  if [[ "$existing_ui_cmd" == *"ng serve"* ]]; then
    echo "Frontend already running on port ${UI_PORT} (pid ${existing_ui_pid})."
    echo "Open http://localhost:${UI_PORT}/"
    if [[ "$API_STARTED_BY_SCRIPT" -eq 1 ]]; then
      echo "Press Ctrl+C to stop backend started by this script."
      wait "$API_PID"
    fi
    exit 0
  fi

  echo "Port ${UI_PORT} is in use by pid ${existing_ui_pid}: ${existing_ui_cmd}" >&2
  echo "Stop that process and rerun the script." >&2
  exit 1
fi

echo "Starting Angular frontend on http://localhost:${UI_PORT}/ ..."
start_api_watcher
cd "$FRONTEND_DIR"
npm start
