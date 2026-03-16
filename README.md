# HealthcareForm

HealthcareForm is a healthcare management monorepo with:
- SQL Server database scripts and migrations
- ASP.NET Core Web API (`net10.0`)
- Angular frontend (`@angular/* 20.x`)

## Project Layout

- `001-database/` SQL schema, migrations, inserts, deployment assets
- `002-code/HealthcareForm/` backend API
- `002-code/healthcareform-angular/` frontend app
- `scripts/dev-start.sh` local backend+frontend launcher
- `PROJECT_PHASE_TRACKER.md` active phase/checkpoint tracker for ongoing fixes

## Tech Stack

- Backend: ASP.NET Core Web API (`net10.0`)
- Frontend: Angular 20
- Database: SQL Server
- Auth: JWT bearer + role-based authorization policies

## Prerequisites

- .NET SDK 10
- Node.js 20+ and npm
- SQL Server 2019+

## Local Development (Recommended)

From repo root:

```bash
cp .env.dev.example .env.dev
```

Set secrets once with user-secrets:

```bash
cd 002-code/HealthcareForm
dotnet user-secrets set "ConnectionStrings:HealthcareEntity" "Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=YOUR_REAL_PASSWORD;TrustServerCertificate=true"
dotnet user-secrets set "Jwt:Key" "YOUR_SECRET_AT_LEAST_32_CHARS"
```

Run both backend and frontend:

```bash
cd <repo-root>
./scripts/dev-start.sh
```

## Manual Run

Backend:

```bash
cd 002-code/HealthcareForm
dotnet run --project HealthcareForm.csproj --urls http://127.0.0.1:5099
```

Frontend:

```bash
cd 002-code/healthcareform-angular
npm start
```

## Integration Tests (DB-backed)

The stored-procedure integration tests require a live SQL Server connection. Provide a connection
string via `HF_TEST_DB_CONNECTION` (or `ConnectionStrings__HealthcareEntity`) when running tests:

```bash
HF_TEST_DB_CONNECTION="Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=YOUR_REAL_PASSWORD;TrustServerCertificate=true" \
dotnet test 002-code/HealthcareForm/HealthcareForm.sln
```

## API Quick Checks

- Live: `http://127.0.0.1:5099/api/health/live`
- DB: `http://127.0.0.1:5099/api/health/db`

## Configuration Notes

`Program.cs` enforces required values at startup:
- `ConnectionStrings:HealthcareEntity`
- `Jwt:Issuer`
- `Jwt:Audience`
- `Jwt:Key` (minimum 32 chars)

In development, placeholders can be overlaid from `.env.dev`, and user-secrets are also loaded.

## Security

- Do not commit real secrets to source control.
- Use `dotnet user-secrets` for local secret values.
- Keep `.env.dev` local and treat it as sensitive when it contains credentials.
