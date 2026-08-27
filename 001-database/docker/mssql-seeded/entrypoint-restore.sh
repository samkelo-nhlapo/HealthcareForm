#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status,
# but allow evaluated loops/conditions to handle connection checks safely.
set -uo pipefail

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

# 🔄 BACKGROUND SEEDING TASK
perform_restore_background() {
  # 1. NEW: Download the file from MEGA before SQL Server initialization!
  # Replace the URL with your actual MEGA public file link
  MEGA_LINK="https://mega.nz/file/v08RjBaQ#OI-Jc4Cq09Grfw1PA-rP4rGGyyAoasRUzwLcuDHJ9WE"
  BACKUP_FILE="${MSSQL_BACKUP_FILE:-/seed/HealthcareForm.bak}"

  log "Downloading latest backup from MEGA..."
  # mega-get will fetch the file and save it to the BACKUP_FILE path
  if mega-get "${MEGA_LINK}" "${BACKUP_FILE}"; then
    log "MEGA download successful."
  else
    log "Warning: MEGA download failed. Checking if a local backup file already exists..."
  fi

  # Give the core engine a moment to process initial SA credentials
  # and run internal system database schema upgrades.
  log "Waiting 8 seconds for engine initialization routines..."
  sleep 8

  AUTO_RESTORE_RAW="${MSSQL_AUTO_RESTORE:-true}"
  AUTO_RESTORE="$(printf '%s' "${AUTO_RESTORE_RAW}" | tr '[:upper:]' '[:lower:]')"

  if [[ "${AUTO_RESTORE}" != "true" && "${AUTO_RESTORE}" != "1" && "${AUTO_RESTORE}" != "yes" ]]; then
    log "Auto-restore disabled by configuration."
    return 0
  fi

  DB_NAME="${MSSQL_RESTORE_DB_NAME:-HealthcareForm}"
  SA_PASSWORD_VALUE="${MSSQL_SA_PASSWORD:-${SA_PASSWORD:-}}"
  READY_TIMEOUT_SECONDS="${MSSQL_RESTORE_TIMEOUT_SECONDS:-240}"

  if [[ -z "${SA_PASSWORD_VALUE}" ]]; then
    log "Skipping restore because SA_PASSWORD is not set."
    return 0
  fi

  # This check now runs AFTER the MEGA download attempt
  if [[ ! -f "${BACKUP_FILE}" ]]; then
    log "Skipping restore because backup file is missing: ${BACKUP_FILE}"
    return 0
  fi

  SQLCMD_PATH="$(find_sqlcmd || true)"
  if [[ -z "${SQLCMD_PATH}" ]]; then
    log "Skipping restore because sqlcmd was not found."
    return 0
  fi

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
      log "Timed out waiting for SQL Server to boot."
      return 1
    fi
  done

  DB_EXISTS="$("${SQLCMD_PATH}" "${SQLCMD_BASE_ARGS[@]}" -h -1 -W \
    -Q "SET NOCOUNT ON; SELECT CASE WHEN DB_ID(N'${DB_NAME}') IS NULL THEN 0 ELSE 1 END;" | tr -d '\r')"

  if [[ "${DB_EXISTS}" == "1" ]]; then
    log "Database ${DB_NAME} already exists. Skipping restore."
  else
    log "Restoring ${DB_NAME} from ${BACKUP_FILE} with explicit path mappings..."
    "${SQLCMD_PATH}" "${SQLCMD_BASE_ARGS[@]}" \
      -Q "RESTORE DATABASE [${DB_NAME}] FROM DISK = N'${BACKUP_FILE}' WITH REPLACE, RECOVERY, MOVE N'HealthcareForm_Primary' TO N'/var/opt/mssql/data/HealthcareForm.mdf', MOVE N'HealthcareForm_Log' TO N'/var/opt/mssql/data/HealthcareForm_log.ldf', STATS=10;"
    log "Restore completed successfully."
  fi
}

# 1. Fire off the monitoring loop ONCE independently in the background
perform_restore_background &

# 2. FOREGROUND EXECUTION (Launches the actual database service directly)
log "Starting SQL Server core engine..."
exec /opt/mssql/bin/sqlservr
