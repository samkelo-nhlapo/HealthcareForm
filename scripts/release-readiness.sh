#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/002-code/HealthcareForm"
FRONTEND_DIR="$ROOT_DIR/002-code/healthcareform-angular"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command dotnet
require_command npm

echo "==> Stored procedure validation"
"$ROOT_DIR/scripts/validate-stored-procedures.sh"

echo
echo "==> Backend restore/build (Release)"
dotnet restore "$BACKEND_DIR/HealthcareForm.sln"
dotnet build "$BACKEND_DIR/HealthcareForm.sln" -c Release --no-restore
dotnet test "$BACKEND_DIR/HealthcareForm.sln" -c Release --no-build

echo
echo "==> Frontend install/build (production)"
cd "$FRONTEND_DIR"
if [[ "${HF_SKIP_NPM_CI:-0}" != "1" ]]; then
  npm ci
fi
npm run build

echo
echo "Release readiness checks passed."
