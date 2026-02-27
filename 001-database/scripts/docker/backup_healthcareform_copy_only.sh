#!/usr/bin/env bash
set -euo pipefail

DB_NAME="${1:-HealthcareForm}"
CONTAINER_NAME="${MSSQL_CONTAINER_NAME:-healthcare-mssql}"
SA_PASSWORD="${MSSQL_SA_PASSWORD:?Set MSSQL_SA_PASSWORD first}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="/var/opt/mssql/backup/${DB_NAME}_${TIMESTAMP}.bak"

SQLCMD_PATH="$(docker exec "$CONTAINER_NAME" bash -lc '
if [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
  echo /opt/mssql-tools18/bin/sqlcmd
elif [ -x /opt/mssql-tools/bin/sqlcmd ]; then
  echo /opt/mssql-tools/bin/sqlcmd
else
  exit 1
fi
')"

docker exec "$CONTAINER_NAME" "$SQLCMD_PATH" \
  -S localhost \
  -U sa \
  -P "$SA_PASSWORD" \
  -Q "BACKUP DATABASE [${DB_NAME}] TO DISK=N'${BACKUP_FILE}' WITH COPY_ONLY, COMPRESSION, CHECKSUM, INIT, STATS=10;"

echo "Backup created: ${BACKUP_FILE}"
