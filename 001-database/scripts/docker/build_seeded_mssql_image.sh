#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_VOLUME_ROOT="${MSSQL_VOLUME_ROOT:-${ROOT_DIR}/docker-volumes/mssql}"
IMAGE_TAG="${MSSQL_SEEDED_IMAGE_TAG:-healthcare-form/mssql-seeded:latest}"
BASE_IMAGE="${MSSQL_BASE_IMAGE:-mcr.microsoft.com/mssql/server:2019-latest}"

BACKUP_FILE_INPUT="${1:-${MSSQL_SEED_BACKUP_FILE:-}}"
if [[ -z "${BACKUP_FILE_INPUT}" ]]; then
  BACKUP_FILE_INPUT="$(ls -1t "${DEFAULT_VOLUME_ROOT}/backup/"*.bak 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "${BACKUP_FILE_INPUT}" ]]; then
  echo "No .bak file found."
  echo "Pass a backup path as arg, or set MSSQL_SEED_BACKUP_FILE, or place a .bak in ${DEFAULT_VOLUME_ROOT}/backup."
  exit 1
fi

ABS_BACKUP_FILE="$(readlink -f "${BACKUP_FILE_INPUT}")"
ABS_ROOT_DIR="$(readlink -f "${ROOT_DIR}")"

if [[ ! -f "${ABS_BACKUP_FILE}" ]]; then
  echo "Backup file not found: ${BACKUP_FILE_INPUT}"
  exit 1
fi

case "${ABS_BACKUP_FILE}" in
  "${ABS_ROOT_DIR}"/*) ;;
  *)
    echo "Backup file must be inside repo so Docker build context can access it."
    echo "Repo root: ${ABS_ROOT_DIR}"
    echo "Current backup: ${ABS_BACKUP_FILE}"
    exit 1
    ;;
esac

REL_BACKUP_FILE="${ABS_BACKUP_FILE#${ABS_ROOT_DIR}/}"

echo "Building seeded SQL Server image..."
echo "Base image : ${BASE_IMAGE}"
echo "Backup file: ${REL_BACKUP_FILE}"
echo "Tag        : ${IMAGE_TAG}"

(
  cd "${ROOT_DIR}"
  docker build \
    --build-arg MSSQL_BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg BACKUP_FILE="${REL_BACKUP_FILE}" \
    -f docker/mssql-seeded/Dockerfile \
    -t "${IMAGE_TAG}" \
    .
)

echo "Build complete: ${IMAGE_TAG}"
