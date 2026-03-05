# HealthcareForm Phase Tracker

This file tracks the active project-fix path across database, backend API, frontend integration, and local dev tooling.

## Current Position

- Current phase: **Phase 7 - Live Data Integration & Runtime Stability**
- Previous phase completed: **Phase 6 - Hardening**
- Current checkpoint: **Phase 7A - Core Runtime Baseline**

## Phase Summary

1. Foundation and shell setup: completed
2. Patient flow implementation: completed
3. Clinical workflow implementation: completed
4. Operations and revenue module setup: completed
5. Admin and compliance module setup: completed
6. Hardening (accessibility/perf/guards): completed
7. Live data integration and runtime stability: in progress

## Phase 7A Checkpoint (Active)

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
- [ ] Add automated script-level smoke check for login + worklist after startup.
- [ ] Add CI validation for called-vs-defined SP diff.

## Next Checkpoint (Planned): Phase 7B

### Objective

Replace remaining module placeholders with live backend snapshots and standardize integration error UX.

### Candidate Tasks

- [ ] Wire scheduling board to `/api/operations/scheduling`.
- [ ] Wire operations queue to `/api/operations/task-queue`.
- [ ] Wire revenue claims view to `/api/revenue/claims`.
- [ ] Add consistent load/retry/empty/error states for all live snapshot pages.
- [ ] Add integration smoke tests for operations and revenue endpoints.

