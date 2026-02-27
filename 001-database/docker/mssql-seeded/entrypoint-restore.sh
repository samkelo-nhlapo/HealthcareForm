#!/usr/bin/env bash
set -euo pipefail

SQLSERVR_PID=""

log() {
  printf '[seeded-mssql] %s\n' "$*"
}

find_sqlcmd() {
  if [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
    echo /opt/mssql-tools18/bin/sqlcmd
  elif [ -x /opt/mssql-tools/bin/sqlcmd ]; then
    echo /opt/mssql-tools/bin/sqlcmd
  else
    return 1
  fi
}

shutdown() {
  if [[ -n "${SQLSERVR_PID}" ]] && kill -0 "${SQLSERVR_PID}" >/dev/null 2>&1; then
    kill -TERM "${SQLSERVR_PID}" >/dev/null 2>&1 || true
    wait "${SQLSERVR_PID}" || true
  fi
}

trap shutdown SIGINT SIGTERM

if [[ $# -eq 0 ]]; then
  set -- /opt/mssql/bin/sqlservr
fi

/opt/mssql/bin/permissions_check.sh "$@" &
SQLSERVR_PID=$!

AUTO_RESTORE_RAW="${MSSQL_AUTO_RESTORE:-true}"
AUTO_RESTORE="$(printf '%s' "${AUTO_RESTORE_RAW}" | tr '[:upper:]' '[:lower:]')"

if [[ "${AUTO_RESTORE}" == "true" || "${AUTO_RESTORE}" == "1" || "${AUTO_RESTORE}" == "yes" ]]; then
  BACKUP_FILE="${MSSQL_BACKUP_FILE:-/seed/HealthcareForm.bak}"
  DB_NAME="${MSSQL_RESTORE_DB_NAME:-HealthcareForm}"
  SA_PASSWORD_VALUE="${MSSQL_SA_PASSWORD:-${SA_PASSWORD:-}}"
  READY_TIMEOUT_SECONDS="${MSSQL_RESTORE_TIMEOUT_SECONDS:-240}"

  if [[ -z "${SA_PASSWORD_VALUE}" ]]; then
    log "Skipping restore because MSSQL_SA_PASSWORD/SA_PASSWORD is not set."
  elif [[ ! -f "${BACKUP_FILE}" ]]; then
    log "Skipping restore because backup file is missing: ${BACKUP_FILE}"
  else
    SQLCMD_PATH="$(find_sqlcmd || true)"
    if [[ -z "${SQLCMD_PATH}" ]]; then
      log "Skipping restore because sqlcmd was not found in container."
    else
      SQLCMD_BASE_ARGS=(-S localhost -U sa -P "${SA_PASSWORD_VALUE}" -b)
      if [[ "${SQLCMD_PATH}" == *"/mssql-tools18/"* ]]; then
        SQLCMD_BASE_ARGS+=(-C)
      fi

      log "Waiting for SQL Server to accept connections..."
      elapsed=0
      until "${SQLCMD_PATH}" "${SQLCMD_BASE_ARGS[@]}" -Q "SELECT 1" >/dev/null 2>&1; do
        sleep 2
        elapsed=$((elapsed + 2))
        if (( elapsed >= READY_TIMEOUT_SECONDS )); then
          log "Timed out after ${READY_TIMEOUT_SECONDS}s waiting for SQL Server."
          exit 1
        fi
      done

      DB_EXISTS="$("${SQLCMD_PATH}" "${SQLCMD_BASE_ARGS[@]}" -h -1 -W \
        -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'${DB_NAME}') IS NULL THEN 0 ELSE 1 END;" | tr -d '\r')"

      if [[ "${DB_EXISTS}" == "1" ]]; then
        log "Database ${DB_NAME} already exists. Skipping restore."
      else
        log "Restoring ${DB_NAME} from ${BACKUP_FILE}..."
        "${SQLCMD_PATH}" "${SQLCMD_BASE_ARGS[@]}" \
          -Q "RESTORE DATABASE [${DB_NAME}] FROM DISK = N'${BACKUP_FILE}' WITH REPLACE, RECOVERY, STATS=10;"
        log "Restore completed."
      fi
    fi
  fi
else
  log "Auto-restore disabled by MSSQL_AUTO_RESTORE=${AUTO_RESTORE_RAW}."
fi

wait "${SQLSERVR_PID}"
