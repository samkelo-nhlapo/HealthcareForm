#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import subprocess
import tempfile
from pathlib import Path


ROOT = Path("/home/samkelo/HealthcareForm")
DEFAULT_CSV = ROOT / "generated" / "hospital_network_merged_20260404.csv"
DEFAULT_ENV = ROOT / ".env.dev"
SQLCMD = Path("/opt/mssql-tools18/bin/sqlcmd")
IMPORT_PREFIX = "hospital-network:"
IMPORT_ACTOR = "Hospital Network CSV Import 2026-04-04"

PROVINCE_ALIASES = {
    "Kwazulu-Natal": "KwaZulu-Natal",
    "Kwazulu Natal": "KwaZulu-Natal",
}

PRIVATE_OPERATORS = {
    "AKESO",
    "BUSAMED",
    "CLINIX",
    "INTERCARE",
    "LENMED",
    "LIFE HEALTHCARE",
    "MEDICLINIC",
    "MEDICROSS",
    "MELOMED",
    "NETCARE",
    "NHN",
    "NURTURE",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import the merged hospital-network CSV into the HealthcareForm database."
    )
    parser.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="Path to the merged hospital CSV.")
    parser.add_argument("--env", type=Path, default=DEFAULT_ENV, help="Path to the .env file with the DB connection.")
    return parser.parse_args()


def read_connection_string(env_path: Path) -> str:
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if not line.startswith("ConnectionStrings__HealthcareEntity="):
            continue

        _, value = line.split("=", 1)
        value = value.strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        return value

    raise RuntimeError("ConnectionStrings__HealthcareEntity was not found in the env file.")


def parse_connection_string(connection_string: str) -> dict[str, str]:
    values: dict[str, str] = {}
    for part in connection_string.split(";"):
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        values[key.strip().lower()] = value.strip()

    server = values.get("server")
    database = values.get("database")
    user = values.get("user id")
    password = values.get("password")

    if not server or not database or not user or password is None:
        raise RuntimeError("The connection string is missing one of Server, Database, User Id, or Password.")

    return {
        "server": server,
        "database": database,
        "user": user,
        "password": password,
    }


def clean_text(value: str | None) -> str:
    if value is None:
        return ""
    value = value.replace("\xa0", " ")
    value = re.sub(r"\s+", " ", value)
    return value.strip()


def normalize_province(value: str) -> str:
    value = clean_text(value)
    return PROVINCE_ALIASES.get(value, value)


def normalize_town(value: str) -> str:
    value = clean_text(value)
    if not value:
        return ""

    value = re.sub(r"\s+\+?\d(?:[\d\s-]{5,}\d)\??$", "", value).strip(" -,")
    if not re.search(r"[A-Za-z]", value) and re.search(r"\d", value):
        return ""
    return value


def normalize_source(value: str) -> str:
    tokens = []
    seen: set[str] = set()
    for token in clean_text(value).split(","):
        normalized = clean_text(token)
        if not normalized:
            continue
        if normalized == "EVO":
            normalized = "EVO Network"
        if normalized in seen:
            continue
        seen.add(normalized)
        tokens.append(normalized)
    return ", ".join(tokens)


def infer_organization_type(name: str) -> str:
    upper = name.upper()
    if "HOSPITAL" in upper:
        return "Hospital"
    if any(token in upper for token in ("CLINIC", "MEDICAL", "TREATMENT", "CENTRE", "CENTER")):
        return "Clinic"
    return "Clinic"


def infer_ownership_type(name: str, operator: str) -> str:
    upper_name = name.upper()
    upper_operator = operator.upper()
    if "PRIVATE" in upper_name or upper_operator in PRIVATE_OPERATORS:
        return "Private"
    if any(token in upper_name for token in ("DISTRICT", "PROVINCIAL", "REGIONAL", "ACADEMIC", "COMMUNITY", "GOVERNMENT", "MILITARY")):
        return "Public"
    return "Unknown"


def is_valid_phone_candidate(value: str) -> bool:
    normalized = value
    has_plus = normalized.startswith("+")
    for token in (" ", "-", "(", ")", ".", "/", "\\"):
        normalized = normalized.replace(token, "")
    if normalized.startswith("00"):
        normalized = "+" + normalized[2:]
    elif has_plus and not normalized.startswith("+"):
        normalized = "+" + normalized

    digits = normalized.replace("+", "")
    return digits.isdigit() and 7 <= len(digits) <= 15


def select_primary_phone(value: str) -> str:
    cleaned = clean_text(value).rstrip("?")
    if not cleaned:
        return ""

    candidates = re.split(r"[;/]+", cleaned)
    for candidate in candidates:
        normalized = clean_text(candidate).rstrip("?")
        if normalized and is_valid_phone_candidate(normalized):
            return normalized

    return cleaned


def apply_location_overrides(name: str, town: str, province: str, country: str) -> tuple[str, str, str]:
    if town:
        return town, province, country

    parts = [clean_text(part) for part in name.split(",") if clean_text(part)]
    if len(parts) < 2:
        return town, province, country

    last = parts[-1]
    if last in {"Namibia", "Lesotho"}:
        return parts[-2], "", last

    return town, province, country


def build_external_key(name: str, town: str, province: str, country: str) -> str:
    source = "|".join(part.strip().lower() for part in (name, town, province, country))
    digest = hashlib.sha1(source.encode("utf-8")).hexdigest()
    return f"{IMPORT_PREFIX}{digest}"


def build_client_code(external_key: str) -> str:
    digest = hashlib.sha1(external_key.encode("utf-8")).hexdigest()[:12].upper()
    return f"FAC-{digest}"


def sql_literal(value: str | None) -> str:
    if value is None:
        return "NULL"
    escaped = value.replace("'", "''")
    return f"N'{escaped}'"


def build_import_script(rows: list[dict[str, str]]) -> str:
    batches: list[str] = [
        "SET ANSI_NULLS ON;",
        "SET QUOTED_IDENTIFIER ON;",
        "SET ANSI_PADDING ON;",
        "SET ANSI_WARNINGS ON;",
        "SET ARITHABORT ON;",
        "SET CONCAT_NULL_YIELDS_NULL ON;",
        "SET NUMERIC_ROUNDABORT OFF;",
        "SET NOCOUNT ON;",
        "SET XACT_ABORT ON;",
    ]

    for row in rows:
        name = clean_text(row.get("Hospital Name"))
        if not name:
            continue

        raw_town = clean_text(row.get("Town"))
        town = normalize_town(raw_town)
        raw_province = normalize_province(row.get("Province", ""))
        raw_country = clean_text(row.get("Country")) or "South Africa"
        province = raw_province
        country = raw_country
        town, province, country = apply_location_overrides(name, town, province, country)
        operator = clean_text(row.get("Group/Operator"))
        address = clean_text(row.get("Address"))
        phone = select_primary_phone(row.get("Phone", ""))
        sources = normalize_source(row.get("Source", ""))

        external_key = build_external_key(name, raw_town, raw_province, raw_country)
        client_code = build_client_code(external_key)
        organization_type = infer_organization_type(name)
        ownership_type = infer_ownership_type(name, operator)

        batch = f"""
DECLARE @StatusCode INT, @Message VARCHAR(250), @ClientId UNIQUEIDENTIFIER;
EXEC [Profile].[spUpsertFacilityClient]
    @ClientCode = {sql_literal(client_code)},
    @DisplayName = {sql_literal(name)},
    @OrganizationType = {sql_literal(organization_type)},
    @OwnershipType = {sql_literal(ownership_type)},
    @Town = {sql_literal(town or None)},
    @Province = {sql_literal(province or None)},
    @Country = {sql_literal(country)},
    @GroupOperator = {sql_literal(operator or None)},
    @AddressText = {sql_literal(address or None)},
    @PhoneNumber = {sql_literal(phone or None)},
    @NetworkSources = {sql_literal(sources or None)},
    @DirectoryExternalKey = {sql_literal(external_key)},
    @CreatedBy = {sql_literal(IMPORT_ACTOR)},
    @ClientIdOutput = @ClientId OUTPUT,
    @StatusCode = @StatusCode OUTPUT,
    @Message = @Message OUTPUT;
IF ISNULL(@StatusCode, -1) <> 0
BEGIN
    SET @Message = COALESCE(NULLIF(@Message, ''), 'Directory import failed.');
    RAISERROR('%s', 16, 1, @Message);
END
"""
        batches.append(batch.strip())
        batches.append("GO")

    batches.extend(
        [
            f"UPDATE Profile.Clients SET FacilityTownName = NULL, UpdatedDate = GETDATE(), UpdatedBy = {sql_literal(IMPORT_ACTOR)} WHERE DirectoryExternalKey LIKE {sql_literal(f'{IMPORT_PREFIX}%')} AND ISNULL(FacilityTownName, '') <> '' AND FacilityTownName NOT LIKE '%[A-Za-z]%' AND FacilityTownName LIKE '%[0-9]%';",
            "GO",
            f"UPDATE Profile.Clients SET FacilityProvinceName = NULL, UpdatedDate = GETDATE(), UpdatedBy = {sql_literal(IMPORT_ACTOR)} WHERE DirectoryExternalKey LIKE {sql_literal(f'{IMPORT_PREFIX}%')} AND FacilityCountryName IN ('Namibia', 'Lesotho') AND FacilityProvinceName = 'Western Cape';",
            "GO",
            f"PRINT 'Imported facility records from {DEFAULT_CSV.name}.';",
            "GO",
            f"SELECT COUNT(*) AS ImportedFacilityCount FROM Profile.Clients WHERE DirectoryExternalKey LIKE {sql_literal(f'{IMPORT_PREFIX}%')} AND IsDeleted = 0;",
            "GO",
            "SELECT COUNT(*) AS TotalClientCount FROM Profile.Clients WHERE IsDeleted = 0;",
            "GO",
        ]
    )

    return "\n".join(batches) + "\n"


def run_import(connection: dict[str, str], sql_script: str) -> None:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".sql", delete=False) as handle:
        handle.write(sql_script)
        script_path = Path(handle.name)

    try:
        command = [
            str(SQLCMD),
            "-C",
            "-b",
            "-S",
            connection["server"],
            "-U",
            connection["user"],
            "-P",
            connection["password"],
            "-d",
            connection["database"],
            "-f",
            "65001",
            "-i",
            str(script_path),
        ]
        completed = subprocess.run(command, check=True, text=True, capture_output=True)
        if completed.stdout.strip():
            print(completed.stdout.strip())
    except subprocess.CalledProcessError as exc:
        if exc.stdout:
            print(exc.stdout.strip())
        if exc.stderr:
            print(exc.stderr.strip())
        raise
    finally:
        script_path.unlink(missing_ok=True)


def main() -> int:
    args = parse_args()
    if not args.csv.exists():
        raise FileNotFoundError(f"CSV file not found: {args.csv}")
    if not args.env.exists():
        raise FileNotFoundError(f"Env file not found: {args.env}")
    if not SQLCMD.exists():
        raise FileNotFoundError(f"sqlcmd not found at {SQLCMD}")

    with args.csv.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle))

    connection_string = read_connection_string(args.env)
    connection = parse_connection_string(connection_string)
    sql_script = build_import_script(rows)
    run_import(connection, sql_script)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
