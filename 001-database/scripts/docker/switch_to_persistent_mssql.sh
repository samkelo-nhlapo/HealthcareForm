#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   MSSQL_SA_PASSWORD='...' ./scripts/docker/switch_to_persistent_mssql.sh [current_container_name]
#
# If current_container_name is not provided, the script picks the first container exposing port 1433.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CURRENT_CONTAINER="${1:-}"
SA_PASSWORD="${MSSQL_SA_PASSWORD:?Set MSSQL_SA_PASSWORD first}"
VOLUME_ROOT="${MSSQL_VOLUME_ROOT:-${ROOT_DIR}/docker-volumes/mssql}"

if [[ -z "${CURRENT_CONTAINER}" ]]; then
  CURRENT_CONTAINER="$(docker ps --filter publish=1433 --format '{{.Names}}' | head -n 1)"
fi

if [[ -z "${CURRENT_CONTAINER}" ]]; then
  echo "No running SQL Server container found on host port 1433."
  exit 1
fi

if [[ "${CURRENT_CONTAINER}" == "healthcare-mssql" ]]; then
  echo "Current container is already named healthcare-mssql. Skipping stop/remove step."
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE_IN_CONTAINER="/var/opt/mssql/backup/HealthcareForm_${TIMESTAMP}.bak"
BACKUP_FILE_ON_HOST="${VOLUME_ROOT}/backup/HealthcareForm_${TIMESTAMP}.bak"

SQLCMD_PATH="$(docker exec "${CURRENT_CONTAINER}" bash -lc '
if [ -x /opt/mssql-tools18/bin/sqlcmd ]; then
  echo /opt/mssql-tools18/bin/sqlcmd
elif [ -x /opt/mssql-tools/bin/sqlcmd ]; then
  echo /opt/mssql-tools/bin/sqlcmd
else
  exit 1
fi
')"

echo "[1/6] Creating COPY_ONLY backup inside container..."
docker exec "${CURRENT_CONTAINER}" "${SQLCMD_PATH}" \
  -S localhost \
  -U sa \
  -P "${SA_PASSWORD}" \
  -Q "BACKUP DATABASE [HealthcareForm] TO DISK=N'${BACKUP_FILE_IN_CONTAINER}' WITH COPY_ONLY, COMPRESSION, CHECKSUM, INIT, STATS=10;"

echo "[2/6] Ensuring host persistent directories..."
mkdir -p "${VOLUME_ROOT}/data" \
         "${VOLUME_ROOT}/log" \
         "${VOLUME_ROOT}/backup"

echo "[3/6] Copying backup to host path..."
docker cp "${CURRENT_CONTAINER}:${BACKUP_FILE_IN_CONTAINER}" "${BACKUP_FILE_ON_HOST}"

if [[ "${CURRENT_CONTAINER}" != "healthcare-mssql" ]]; then
  echo "[4/6] Stopping and removing current container ${CURRENT_CONTAINER}..."
  docker stop "${CURRENT_CONTAINER}"
  docker rm "${CURRENT_CONTAINER}"
else
  echo "[4/6] Skipping stop/remove (container already healthcare-mssql)."
fi

echo "[5/6] Starting persistent SQL Server container..."
(
  cd "${ROOT_DIR}"
  docker compose -f docker-compose.mssql.persistent.yml up -d
)

echo "[6/6] Done."
echo "Host backup file: ${BACKUP_FILE_ON_HOST}"
echo "Persistent compose file: ${ROOT_DIR}/docker-compose.mssql.persistent.yml"
