#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/002-code/HealthcareForm"
STORED_PROCS_DIR="$ROOT_DIR/001-database/006-stored-procedures"

if ! command -v rg >/dev/null 2>&1; then
  echo "Missing required command: rg" >&2
  exit 1
fi

if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Backend directory not found: $BACKEND_DIR" >&2
  exit 1
fi

if [[ ! -d "$STORED_PROCS_DIR" ]]; then
  echo "Stored procedures directory not found: $STORED_PROCS_DIR" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

called_file="$tmp_dir/called.txt"
defined_file="$tmp_dir/defined.txt"
missing_file="$tmp_dir/missing.txt"
unused_file="$tmp_dir/unused.txt"

rg --pcre2 -o --no-filename '"[A-Za-z][A-Za-z0-9_]*\.sp[A-Za-z0-9_]+"' "$BACKEND_DIR" \
  -g '*.cs' \
  -g '!**/bin/**' \
  -g '!**/obj/**' \
  -g '!**/packages/**' \
  | tr -d '"' \
  | tr '[:upper:]' '[:lower:]' \
  | sort -u > "$called_file"

rg --pcre2 -o --no-filename \
  'CREATE(?:\s+OR\s+ALTER)?\s+PROC(?:EDURE)?\s+\[[A-Za-z0-9_]+\]\.\[sp[A-Za-z0-9_]+\]' "$STORED_PROCS_DIR" \
  -g '*.sql' \
  | sed -E 's/.*\[([A-Za-z0-9_]+)\]\.\[(sp[A-Za-z0-9_]+)\].*/\1.\2/' \
  | tr '[:upper:]' '[:lower:]' \
  | sort -u > "$defined_file"

comm -23 "$called_file" "$defined_file" > "$missing_file"
comm -13 "$called_file" "$defined_file" > "$unused_file"

called_count="$(wc -l < "$called_file" | tr -d ' ')"
defined_count="$(wc -l < "$defined_file" | tr -d ' ')"
missing_count="$(wc -l < "$missing_file" | tr -d ' ')"
unused_count="$(wc -l < "$unused_file" | tr -d ' ')"

echo "Stored procedure validation summary:"
echo "  called in backend: $called_count"
echo "  defined in 006-stored-procedures: $defined_count"
echo "  missing definitions: $missing_count"
echo "  defined but unused: $unused_count"

if [[ "$missing_count" -gt 0 ]]; then
  echo
  echo "Missing stored procedure definitions for backend calls:" >&2
  sed 's/^/  - /' "$missing_file" >&2
  exit 1
fi

if [[ "$unused_count" -gt 0 ]]; then
  echo
  echo "Defined but currently unused stored procedures:"
  sed 's/^/  - /' "$unused_file"
fi

echo
echo "Stored procedure validation passed."
