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

2. Edit `.env.dev` and set `ConnectionStrings__HealthcareEntity`.
Do not leave placeholder values such as `YOUR_CONNECTION_STRING`.

## Notes

- Backend: `http://127.0.0.1:5099`
- Frontend: `http://localhost:4200`
- API live health check: `http://127.0.0.1:5099/api/health/live`
- API DB health check: `http://127.0.0.1:5099/api/health/db`
- Press `Ctrl+C` to stop. If the script started the backend process, it will stop it automatically.
- To skip DB health enforcement (not recommended): `HF_API_REQUIRE_DB_HEALTH=0 ./scripts/dev-start.sh`
