# Developing

This repo contains a SQL Server database, a .NET API, and an Angular frontend. Use the workflows below
to keep local development repeatable and aligned with CI expectations.

## Prerequisites
- .NET SDK 10
- Node.js 20+
- SQL Server 2019+
- `rg` (ripgrep) for repo scripts

## Local Setup
1. Copy the dev env file:
   ```bash
   cp .env.dev.example .env.dev
   ```
2. Configure secrets (recommended):
   ```bash
   cd 002-code/HealthcareForm
   dotnet user-secrets set "ConnectionStrings:HealthcareEntity" "Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=YOUR_REAL_PASSWORD;TrustServerCertificate=true"
   dotnet user-secrets set "Jwt:Key" "YOUR_SECRET_AT_LEAST_32_CHARS"
   ```

## Run the Stack Locally
From repo root:
```bash
./scripts/dev-start.sh
```

Manual run:
```bash
cd 002-code/HealthcareForm
dotnet run --project HealthcareForm.csproj --urls http://127.0.0.1:5099
```

```bash
cd 002-code/healthcareform-angular
npm start
```

## Test Matrix

### Unit tests (default)
```bash
dotnet test 002-code/HealthcareForm/HealthcareForm.sln
```

### Stored-procedure integration tests (DB-backed)
These require a live SQL Server connection. Provide the connection string via
`HF_TEST_DB_CONNECTION` or `ConnectionStrings__HealthcareEntity`:

```bash
HF_TEST_DB_CONNECTION="Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=YOUR_REAL_PASSWORD;TrustServerCertificate=true" \
dotnet test 002-code/HealthcareForm/HealthcareForm.sln
```

If no DB connection string is provided, the integration tests will skip silently.

## Release Readiness (Local)
Run the full release gate (stored procedures + backend build/tests + frontend build):
```bash
./scripts/release-readiness.sh
```

## Stored Procedure Validation
Validate backend-called procedures vs definitions:
```bash
./scripts/validate-stored-procedures.sh
```

## Repository Conventions
- The database deployment source of truth is `001-database/` and the master deployment scripts.
- Keep API contracts in sync with stored procedure outputs.
- Prefer updating deployment docs when schema or procedure counts change.
