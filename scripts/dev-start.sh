#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PROJECT="$ROOT_DIR/002-code/HealthcareForm/HealthcareForm.csproj"
FRONTEND_DIR="$ROOT_DIR/002-code/healthcareform-angular"
ENV_FILE="${HF_ENV_FILE:-$ROOT_DIR/.env.dev}"

API_PORT="${HF_API_PORT:-5099}"
UI_PORT="${HF_UI_PORT:-4200}"
API_URL="${HF_API_URL:-http://127.0.0.1:${API_PORT}}"
API_HEALTH_PATH="${HF_API_HEALTH_PATH:-/api/health/live}"
API_DB_HEALTH_PATH="${HF_API_DB_HEALTH_PATH:-/api/health/db}"
REQUIRE_DB_HEALTH="${HF_API_REQUIRE_DB_HEALTH:-1}"
CONNECTION_STRING_FROM_ENV="${ConnectionStrings__HealthcareEntity:-}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

if [[ -n "$CONNECTION_STRING_FROM_ENV" ]]; then
  ConnectionStrings__HealthcareEntity="$CONNECTION_STRING_FROM_ENV"
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
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

require_command dotnet
require_command npm
require_command lsof
require_command curl

if [[ -z "${ConnectionStrings__HealthcareEntity:-}" ]]; then
  cat >&2 <<EOF
ConnectionStrings__HealthcareEntity is not set.
Set it in your shell or add it to ${ENV_FILE}.

Example:
ConnectionStrings__HealthcareEntity="Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=<password>;TrustServerCertificate=true"
EOF
  exit 1
fi

if [[ "${ConnectionStrings__HealthcareEntity}" == "YOUR_CONNECTION_STRING" \
   || "${ConnectionStrings__HealthcareEntity}" == "__SET_CONNECTIONSTRINGS__HEALTHCAREENTITY_ENV_VAR__" \
   || "${ConnectionStrings__HealthcareEntity}" == *"<password>"* \
   || "${ConnectionStrings__HealthcareEntity}" != *"="* \
   || "${ConnectionStrings__HealthcareEntity}" != *";"* ]]; then
  cat >&2 <<EOF
ConnectionStrings__HealthcareEntity appears to be a placeholder or invalid format.
Current value starts with: ${ConnectionStrings__HealthcareEntity:0:48}

Set a valid SQL Server connection string in ${ENV_FILE} or your shell.
Example:
ConnectionStrings__HealthcareEntity="Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=<password>;TrustServerCertificate=true"
EOF
  exit 1
fi

API_STARTED_BY_SCRIPT=0
API_PID=""

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
  dotnet run --project "$API_PROJECT" --urls "$API_URL" &
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
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
    exit 1
  fi

  if [[ "$REQUIRE_DB_HEALTH" == "1" ]] && ! check_api_db_health; then
    echo "API started but DB health check failed at ${API_DB_HEALTH_PATH}." >&2
    echo "Fix connection string/database and rerun the script." >&2
    kill "$API_PID" >/dev/null 2>&1 || true
    wait "$API_PID" >/dev/null 2>&1 || true
    exit 1
  fi
fi

cleanup() {
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
cd "$FRONTEND_DIR"
npm start
