# HealthcareForm Phase Tracker

This file tracks the active project-fix path across database, backend API, frontend integration, and local dev tooling.

## Current Position

- Current phase: **Phase 8 - Performance & Release Readiness (Completed)**
- Previous phase completed: **Phase 7 - Live Data Integration & Runtime Stability**
- Current checkpoint: **Phase 8 Complete**

## Phase Summary

1. Foundation and shell setup: completed
2. Patient flow implementation: completed
3. Clinical workflow implementation: completed
4. Operations and revenue module setup: completed
5. Admin and compliance module setup: completed
6. Hardening (accessibility/perf/guards): completed
7. Live data integration and runtime stability: completed
8. Performance and release readiness: completed

## Phase 7A Checkpoint (Completed)

### Objective

Deliver stable end-to-end runtime for core patient live-data flow with repeatable local startup and smoke validation.

### Exit Criteria

- `./scripts/dev-start.sh` reliably starts API + frontend without silent backend failure.
- API reachable at `http://127.0.0.1:5099/api/health/live`.
- Frontend proxy can reach backend APIs through `http://localhost:4200/api/*`.
- `/api/patients/worklist` returns live data against deployed stored procedures.
- Stored procedure call graph has no missing runtime procedure definitions.

### Tasks

- [x] Add missing `Profile.spGetPatientWorklistSourceRows` procedure.
- [x] Add migration `V18__patients_worklist_stored_procedure.sql`.
- [x] Include new SP in modular procedure deployment script.
- [x] Validate SP called-vs-defined set (no missing called SPs).
- [x] Smoke test `/api/patients/worklist` on API host (`5099` and `8080` paths).
- [x] Harden `scripts/dev-start.sh` startup diagnostics/logging for backend failures.
- [x] Add backend JWT runtime env in `docker-compose.mssql.persistent.yml`.
- [x] Add automated script-level smoke check for login + worklist after startup.
- [x] Add CI validation for called-vs-defined SP diff.

## Phase 7B Checkpoint (Completed)

### Objective

Replace remaining module placeholders with live backend snapshots and standardize integration error UX.

### Candidate Tasks

- [x] Wire scheduling board to `/api/operations/scheduling`.
- [x] Wire operations queue to `/api/operations/task-queue`.
- [x] Wire revenue claims view to `/api/revenue/claims`.
- [x] Add consistent load/retry/empty/error states for all live snapshot pages.
- [x] Add integration smoke tests for operations and revenue endpoints.

## Phase 8A Checkpoint (Completed)

### Objective

Reduce frontend initial bundle pressure and prepare release-quality build/CI gates.

### Candidate Tasks

- [x] Convert route-level component imports to lazy loading.
- [x] Re-run production build and verify initial bundle budget warning is cleared.
- [x] Add frontend production build workflow gate in CI.

## Phase 8B Checkpoint (Completed)

### Objective

Enforce backend/frontend build health and define a repeatable local release gate.

### Candidate Tasks

- [x] Restore backend release build baseline (missing JWT settings type/config binding).
- [x] Add backend production build workflow gate in CI.
- [x] Add single-command local release readiness gate script.
- [x] Add backend automated tests (API/service level) to CI.
