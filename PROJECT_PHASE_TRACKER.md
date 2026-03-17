# HealthcareForm Phase Tracker

This file tracks the active project-fix path across database, backend API, frontend integration, and local dev tooling.

## Current Position

- Current phase: **Phase 12 - Unused Schema Activation (Completed)**
- Previous phase completed: **Phase 11 - Schema Utilization Audit**
- Current checkpoint: **Phase 12E - Admin Diagnostics (Completed)**

## Phase Summary

1. Foundation and shell setup: completed
2. Patient flow implementation: completed
3. Clinical workflow implementation: completed
4. Operations and revenue module setup: completed
5. Admin and compliance module setup: completed
6. Hardening (accessibility/perf/guards): completed
7. Live data integration and runtime stability: completed
8. Performance and release readiness: completed
9. Post-completion improvements (docs alignment + integration tests): completed
10. Operational readiness and maintenance: completed
11. Schema utilization audit: completed
12. Unused schema activation: completed

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

## Phase 9A Checkpoint (Completed)

### Objective

Isolate legacy migration documentation so current backend docs are not confusing or duplicated.

### Exit Criteria

- Legacy migration docs moved into `002-code/HealthcareForm/legacy-migration/`.
- A clear README exists in the legacy folder describing scope and purpose.
- Plan and process log updated.

### Tasks

- [x] Move migration package docs into `002-code/HealthcareForm/legacy-migration/`.
- [x] Add `README.md` in legacy migration folder.
- [x] Capture work in `PHASED_IMPLEMENTATION_PLAN.md` and `PROCESS_LOG.md`.

## Phase 9B Checkpoint (Completed)

### Objective

Align database deployment documentation with the current schema, table, procedure, and trigger/function scripts.

### Exit Criteria

- Schema count and names match `001-database/002-schema/001_schema_script.sql`.
- Table, procedure, trigger/function, and insert-script counts match the current folders.
- Master deployment docs reference the source-of-truth scripts.

### Tasks

- [x] Update counts and schema names across deployment docs.
- [x] Add source-of-truth references in key documentation.
- [x] Align master deployment guide, manifest, and quick reference with current script inventory.

## Phase 9C Checkpoint (Completed)

### Objective

Add stored-procedure integration tests for API endpoints with safe skipping when DB config is missing.

### Exit Criteria

- Tests cover patients, lookups, operations, revenue, and admin endpoints.
- Tests skip cleanly when no DB connection string is configured.
- Test auth bypasses policies without touching production code paths.

### Tasks

- [x] Add WebApplicationFactory-based integration test harness.
- [x] Add test auth handler and DB-guarded test helpers.
- [x] Add endpoint coverage for stored-procedure-backed APIs.

## Phase 10A Checkpoint (Completed)

### Objective

Define operational and contributor guidance for ongoing maintenance.

### Exit Criteria

- Contributor/developer guide exists.
- CI guidance documents DB-backed integration test expectations.
- Local editor/config artifacts are either documented or untracked.

### Tasks

- [x] Decide on tracked editor settings policy (`.vscode/settings.json`).
- [x] Create `DEVELOPING.md` with local workflows.
- [x] Document DB-backed test expectations for CI.

## Phase 11A Checkpoint (Completed)

### Objective

Audit schema utilization by mapping API endpoints to stored procedures and tables.

### Exit Criteria

- API endpoints and stored procedures are mapped in a single reference document.
- Tables not referenced by API stored procedures are listed for follow-up.
- Tracking artifacts updated to capture completion.

### Tasks

- [x] Enumerate API stored procedure usage from backend services.
- [x] Map stored procedures to referenced tables.
- [x] Publish `TABLE_USAGE_MATRIX.md` with coverage summary and gaps.

## Phase 12A Checkpoint (Completed)

### Objective

Select and plan the first unused schema slice to integrate.

### Exit Criteria

- One slice chosen and scoped.
- Implementation tasks listed (procedures, API endpoints, tests).

### Tasks

- [x] Confirm scope of unused tables and group into slices.
- [x] Choose the first slice to implement.

## Phase 12B Checkpoint (Completed)

### Objective

Activate the client/clinic admin slice using existing stored procedures.

### Exit Criteria

- API exposes client clinic categories, client directory, departments, and staff lists.
- Stored-procedure integration tests cover the new endpoints.
- `TABLE_USAGE_MATRIX.md` updated to reflect new coverage.

### Tasks

- [x] Add client admin contracts, service, and API controller.
- [x] Register new service and add integration tests.
- [x] Update table usage matrix counts and gaps.

## Phase 12C Checkpoint (Completed)

### Objective

Activate clinical history tables and lookup reference data via stored procedures and API endpoints.

### Exit Criteria

- API exposes patient allergies, medications, vaccinations, consultation notes, and referrals.
- Lookup endpoints include allergies and medications reference data.
- Stored-procedure integration tests cover the new endpoints.
- `TABLE_USAGE_MATRIX.md` updated to reflect new coverage and remaining gaps.

### Tasks

- [x] Add lookup stored procedures for allergies and medications.
- [x] Add clinical history stored procedures for patient allergies, medications, vaccinations, consultation notes, and referrals.
- [x] Add API contracts, service methods, and endpoints for the new procedures.
- [x] Add integration test coverage for the new endpoints.
- [x] Update table usage matrix counts and remaining gaps.

## Phase 12D Checkpoint (Completed)

### Objective

Activate dynamic form data access for submissions by exposing field values and attachments.

### Exit Criteria

- API exposes form field values and attachments for a submission.
- Stored-procedure integration tests cover the new endpoints.
- `TABLE_USAGE_MATRIX.md` updated to reflect new coverage and remaining gaps.

### Tasks

- [x] Add stored procedures for form field values and attachments.
- [x] Add API contracts, service methods, and endpoints for the form data endpoints.
- [x] Add integration test coverage for the new endpoints.
- [x] Update table usage matrix counts and remaining gaps.

## Phase 12E Checkpoint (Completed)

### Objective

Expose database error diagnostics to the admin API surface.

### Exit Criteria

- API exposes DB error rows for admin review.
- Stored-procedure integration tests cover the new endpoint.
- `TABLE_USAGE_MATRIX.md` updated to reflect full schema coverage.

### Tasks

- [x] Add stored procedure for DB error reporting.
- [x] Add admin contracts, service method, and endpoint for DB errors.
- [x] Add integration test coverage for the admin DB errors endpoint.
- [x] Update table usage matrix counts and remaining gaps.
