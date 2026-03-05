# Dev Launcher

Run backend and frontend together from repo root:

```bash
./scripts/dev-start.sh
```

## Setup

1. Create a local env file:

```bash
cp .env.dev.example .env.dev
```

2. Recommended: set secrets once with .NET User Secrets:

```bash
cd 002-code/HealthcareForm
dotnet user-secrets set "ConnectionStrings:HealthcareEntity" "Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=YOUR_REAL_PASSWORD;TrustServerCertificate=true"
dotnet user-secrets set "Jwt:Key" "YOUR_SECRET_AT_LEAST_32_CHARS"
```

3. Optional fallback: edit `.env.dev` and set:
- `ConnectionStrings__HealthcareEntity`
- `Jwt__Key` (at least 32 characters)
Do not leave placeholder values.

## Notes

- Backend: `http://127.0.0.1:5099`
- Frontend: `http://localhost:4200`
- API live health check: `http://127.0.0.1:5099/api/health/live`
- API DB health check: `http://127.0.0.1:5099/api/health/db`
- Press `Ctrl+C` to stop. If the script started the backend process, it will stop it automatically.
- To skip DB health enforcement (not recommended): `HF_API_REQUIRE_DB_HEALTH=0 ./scripts/dev-start.sh`

## Stored Procedure Validation

Validate backend-called stored procedures against definitions in `001-database/006-stored-procedures`:

```bash
./scripts/validate-stored-procedures.sh
```

## Release Readiness

Run the local release gates in one command (stored procedures + backend release build/tests + frontend production build):

```bash
./scripts/release-readiness.sh
```

To skip `npm ci` when dependencies are already installed:

```bash
HF_SKIP_NPM_CI=1 ./scripts/release-readiness.sh
```
