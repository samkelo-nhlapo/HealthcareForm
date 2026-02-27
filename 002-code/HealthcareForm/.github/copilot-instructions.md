# HealthcareForm - Copilot Instructions

## Project Overview
HealthcareForm backend is an ASP.NET Core Web API (`net10.0`) serving an Angular 20 client. The API uses SQL Server and JWT authentication with role-based authorization policies.

## Architecture

### Runtime
- Entry point: `Program.cs`
- Controllers: `Controllers/Api/*` + `Controllers/HealthController.cs`
- Services: `Services/*` (business logic and SQL access)
- Contracts/DTOs: `Contracts/*`
- Authorization constants: `Security/AuthorizationPolicies.cs`

### API Surface
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/health/live`
- `GET /api/health/db`
- `/api/patients/*`, `/api/lookups/*`, `/api/operations/*`, `/api/revenue/*`, `/api/admin/*`

### Data Access
- Database calls are implemented via `SqlConnection`/`SqlCommand` in services.
- No EF DbContext query layer is used for core operations.
- Current schema naming in SQL is `Auth`, `Profile`, `Location`, `Contacts`, `Exceptions`, `Lookup`.

## Configuration & Secrets

Required configuration keys (validated at startup):
- `ConnectionStrings:HealthcareEntity`
- `Jwt:Issuer`
- `Jwt:Audience`
- `Jwt:Key` (must be at least 32 chars)

Configuration sources in development:
1. `appsettings.json` (contains placeholders)
2. `dotnet user-secrets` (`AddUserSecrets<Program>(optional: true)`)
3. `.env.dev` overlay for placeholder values

Use user-secrets for local sensitive values:

```bash
cd 002-code/HealthcareForm
dotnet user-secrets set "ConnectionStrings:HealthcareEntity" "<sql-connection-string>"
dotnet user-secrets set "Jwt:Key" "<at-least-32-char-secret>"
```

## Coding Conventions

- Keep controllers thin; place logic in services.
- Prefer async APIs with cancellation tokens.
- Return explicit status codes for common failure modes.
- Use existing DTO/contracts in `Contracts/*`.
- Follow existing policy constants in `AuthorizationPolicies` rather than hardcoding role names in controllers.

## Local Run Commands

Backend only:

```bash
cd 002-code/HealthcareForm
dotnet run --project HealthcareForm.csproj --urls http://127.0.0.1:5099
```

Frontend only:

```bash
cd 002-code/healthcareform-angular
npm start
```

Full dev startup:

```bash
./scripts/dev-start.sh
```
