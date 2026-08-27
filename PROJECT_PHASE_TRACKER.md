# HealthcareForm Phase Tracker

This file tracks the active project-fix path across database, backend API, frontend integration, and local dev tooling.

## Current Position

- Current phase: **Phase 21 - Client Staff Dummy Data Seeding (Completed)**
- Previous phase completed: **Phase 20 - Medication Reconciliation Live Data Activation**
- Current checkpoint: **Phase 21B - Tracker and Deployment Wiring (Completed)**

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
13. Patient hub consolidation: completed
14. Shared patient context: completed
15. Shared patient search model: completed
16. Shared patient selection and cross-view actions: completed
17. Separate registration navigation: completed
18. Unified patient search and hub UX cleanup: completed
19. Orders and results live data activation: completed
20. Medication reconciliation live data activation: completed
21. Client staff dummy data seeding: completed

## Phase 21A Checkpoint (Completed)

### Objective

Add realistic client-staff dummy data for development/UAT to cover clinical, admin, and facilities roles.

### Exit Criteria

- A reusable idempotent seed script creates representative staff records for active clients.
- Seeded roles include doctors, nurses, receptionists, matrons, admins, cleaners, janitors, and pharmacists.
- Supporting staff designations and client departments are seeded when missing.

### Tasks

- [x] Add a client-staff dummy seed script under `005-table-inserts`.
- [x] Seed realistic staff roles across `Clinical`, `Administrative`, `Management`, and `Support` staff types.
- [x] Ensure script is rerunnable without creating duplicates.

## Phase 21B Checkpoint (Completed)

### Objective

Track the dummy-staff rollout and expose it as an optional development seed in modular deployment.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 21 completion.
- Modular deployment script references the staff dummy seed as an optional run.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 21 checkpoints and completion state.
- [x] Add optional modular deployment reference to `018. Insert ClientStaffDummyData.sql`.

## Phase 20A Checkpoint (Completed)

### Objective

Replace medication reconciliation placeholder rows with live medication history from the patient API.

### Exit Criteria

- Patient-facing medication endpoint is available from `/api/patients/{idNumber}/medications`.
- Backend contract exposes structured medication fields for reconciliation workflows.
- Medication reconciliation can consume API-backed records instead of relying on static in-component defaults.

### Tasks

- [x] Confirm backend medication endpoint contract and fields used by clinical workflows.
- [x] Extend Angular patient models with medication-history DTO support.
- [x] Extend the Angular patient API service with the medications endpoint call.

## Phase 20B Checkpoint (Completed)

### Objective

Wire the medication reconciliation clinical view to live medication data while preserving patient context and safe fallback behavior.

### Exit Criteria

- Medication reconciliation loads medication history from the selected patient ID.
- The page surfaces loading/error states for medication data and keeps chart/encounter quick links intact.
- Fallback medication rows use chart data (and patient-reported defaults when needed) when API rows are unavailable.

### Tasks

- [x] Replace static medication seeding with API-backed medication loading.
- [x] Add medication loading/error state handling and safer finalize behavior.
- [x] Enrich medication row display with live structured metadata (status, schedule, prescriber, dates).

## Phase 20C Checkpoint (Completed)

### Objective

Record the medication reconciliation rollout in the tracker and verify the Angular workspace still builds with the new live-data flow.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 20 completion.
- Stored procedure API integration coverage passes for the medication endpoint.
- Frontend build passes with medication reconciliation live-data integration.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 20 checkpoints and completion state.
- [x] Run stored procedure API integration tests covering patient medication retrieval.
- [x] Run frontend build validation for medication reconciliation live-data changes.

## Phase 19A Checkpoint (Completed)

### Objective

Replace the placeholder Orders & Results experience with live patient lab data exposed through the patient API.

### Exit Criteria

- Patient-facing orders/results endpoint returns a combined snapshot for the requested patient.
- Backend reads from `Profile.LabResults` through a dedicated stored procedure instead of hard-coded UI data.
- Pending lab rows are surfaced as open orders while completed rows are surfaced as results.

### Tasks

- [x] Add a patient lab-results stored procedure and backend snapshot contracts.
- [x] Add `/api/patients/{idNumber}/orders-results` to the patient API.
- [x] Partition live lab rows into pending orders and completed results in the backend service.

## Phase 19B Checkpoint (Completed)

### Objective

Wire the clinical Orders & Results page to live data while preserving the shared patient context flow used across the workspace.

### Exit Criteria

- Orders & Results page loads live pending orders and recent results for the selected patient.
- Abnormal-only filtering works against API-backed result data.
- The page shows useful loading, empty, and error states instead of placeholder content.

### Tasks

- [x] Extend Angular patient models and service methods for the orders/results snapshot.
- [x] Replace hard-coded Orders & Results page data with live API state.
- [x] Preserve patient quick links and add clearer loading and empty-state messaging.

## Phase 19C Checkpoint (Completed)

### Objective

Record the Orders & Results rollout in the tracker and verify the new backend/frontend wiring builds cleanly.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 19 completion.
- Stored procedure validation passes with the new backend dependency.
- Backend tests and frontend build pass with the live Orders & Results implementation.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 19 checkpoints and completion state.
- [x] Run stored procedure validation and backend test coverage for the new endpoint.
- [x] Run frontend build validation for the Orders & Results live-data changes.

## Phase 18A Checkpoint (Completed)

### Objective

Collapse the patient hub's duplicated search/context controls into one shared patient-search flow that is easier to understand and act on.

### Exit Criteria

- Patient hub uses one search input for worklist and directory discovery.
- Exact 13-digit patient ID searches can pin a focused patient from the same search surface.
- Patient workflow actions no longer depend on a separate patient-ID form inside the hub.

### Tasks

- [x] Replace the split patient-context and shared-search forms with one patient-search command bar.
- [x] Let exact 13-digit searches pin a focused patient from the unified search flow.
- [x] Keep registration, chart, and encounter actions working from the focused patient state.

## Phase 18B Checkpoint (Completed)

### Objective

Make the patient hub easier to work in by simplifying the visual hierarchy and removing redundant search feedback from child views.

### Exit Criteria

- Patient hub presents a clearer command area, focused-patient card, and view switcher.
- Worklist and directory no longer repeat the same shared-search status banner inside each child panel.
- Patient hub panels have explicit styling so the workspace reads as one cohesive interface.

### Tasks

- [x] Refresh the patient hub layout around search, focus, and view switching.
- [x] Remove duplicated shared-search banners from worklist and directory.
- [x] Add dedicated patient hub panel styling for a clearer workspace hierarchy.

## Phase 18C Checkpoint (Completed)

### Objective

Capture the unified-search hub refresh in the tracker and verify the Angular app still builds cleanly after the patient hub UI changes.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 18 completion.
- Frontend build passes with the patient hub unified-search changes.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 18 checkpoints and completion state.
- [x] Run frontend build validation for the patient hub unified-search changes.

## Phase 17A Checkpoint (Completed)

### Objective

Remove patient registration from the patient hub canvas so the hub stays focused on browsing workflows while registration becomes its own destination.

### Exit Criteria

- Patient hub only presents worklist and directory views.
- Existing registration-focused hub deep links redirect into the standalone registration route.
- Hub context actions open the standalone registration workspace instead of switching tabs inside the hub.

### Tasks

- [x] Remove the registration tab from the patient hub UI.
- [x] Add a standalone patient registration route.
- [x] Redirect legacy hub/workbench registration entry paths into the new registration destination.

## Phase 17B Checkpoint (Completed)

### Objective

Expose patient registration as an easy-to-reach sidebar destination and rewire patient actions so navigation between hub and registration stays straightforward.

### Exit Criteria

- Sidebar shows Patient Registration directly beneath Patient Hub.
- Patient edit/open-registration actions point to the standalone registration route.
- Focused patient context remains available when moving between patient hub and patient registration.

### Tasks

- [x] Add Patient Registration to the clinical sidebar beneath Patient Hub.
- [x] Rewire patient edit and registration links to the standalone registration route.
- [x] Lift focused-patient state to the shared clinical shell so hub and registration can both use it.

## Phase 17C Checkpoint (Completed)

### Objective

Capture the registration-navigation split in the tracker and verify the Angular app still builds cleanly after the route and sidebar changes.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 17 completion.
- Frontend build passes with the patient registration navigation changes.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 17 checkpoints and completion state.
- [x] Run frontend build validation for the registration route and sidebar changes.

## Phase 16A Checkpoint (Completed)

### Objective

Add a shared focused-patient state to the patient hub so staff can pin one patient while moving between worklist, directory, and registration workflows.

### Exit Criteria

- Patient hub surfaces a focused patient summary with reusable workflow actions.
- Focused patient context persists while switching between patient hub tabs.
- Deleted patient focus blocks unsafe chart and encounter shortcuts from the hub.

### Tasks

- [x] Add hub-scoped focused-patient state for cross-view patient selection.
- [x] Surface focused patient details and status feedback in the patient hub.
- [x] Guard chart and encounter actions when the focused patient is a deleted record.

## Phase 16B Checkpoint (Completed)

### Objective

Let the worklist, directory, and registration workspace feed the same focused-patient state so clinicians can move through patient data without reselecting the record each time.

### Exit Criteria

- Worklist rows can focus a patient into the hub state.
- Directory rows can focus a patient into the hub state.
- Registration loads and saves sync back into the shared focused-patient state.

### Tasks

- [x] Add row-level focus actions to the worklist and patient directory.
- [x] Highlight the currently focused patient in both hub list views.
- [x] Sync registration loads, saves, and deletes into the shared focused-patient state.

## Phase 16C Checkpoint (Completed)

### Objective

Record the focused-patient rollout in the tracker and verify the Angular app still builds cleanly after the hub selection changes.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 16 completion.
- Frontend build passes with the hub focused-patient changes.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 16 checkpoints and completion state.
- [x] Run frontend build validation for the shared patient selection changes.

## Phase 15A Checkpoint (Completed)

### Objective

Create a shared patient-search model in the patient hub so worklist and directory views follow one search intent instead of carrying separate search boxes.

### Exit Criteria

- Patient hub exposes a shared search input for patient discovery.
- Shared search persists while switching between worklist and directory tabs.
- Worklist and directory both respond to the same applied search term.

### Tasks

- [x] Add hub-scoped patient search state for shared patient discovery.
- [x] Add patient hub search controls with apply and clear actions.
- [x] Preserve shared search while switching between patient hub tabs.

## Phase 15B Checkpoint (Completed)

### Objective

Remove duplicated patient-search ownership from the child list views so the worklist and directory stay aligned with the hub-level search state.

### Exit Criteria

- Worklist filters rows using the shared patient search term.
- Directory reloads against the shared patient search term.
- Child views no longer depend on their own independent patient-search text boxes.

### Tasks

- [x] Wire worklist filtering to the shared patient search state.
- [x] Wire directory query loading to the shared patient search state.
- [x] Remove duplicate child-view patient-search inputs in favor of the hub search flow.

## Phase 15C Checkpoint (Completed)

### Objective

Capture the shared-search rollout in the tracker and verify the Angular app still builds cleanly after consolidating patient discovery behavior.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 15 completion.
- Frontend build passes with the hub search-state changes.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 15 checkpoints and completion state.
- [x] Run frontend build validation for the shared patient search changes.

## Phase 14A Checkpoint (Completed)

### Objective

Add a shared patient context control surface inside the patient hub so staff can carry one patient through registration, chart, and encounter workflows.

### Exit Criteria

- Patient hub includes a shared patient ID context control.
- Staff can launch registration, chart, and encounter workflows from the shared hub context.
- Patient context remains available while switching between hub tabs.

### Tasks

- [x] Add shared patient context controls to the patient hub.
- [x] Add hub quick actions for registration, chart, and encounter workflows.
- [x] Preserve patient context while switching between worklist, directory, and registration tabs.

## Phase 14B Checkpoint (Completed)

### Objective

Make the registration workspace respect the loaded patient context so edit, delete, and restore actions cannot drift away from the active record.

### Exit Criteria

- Registration syncs loaded patient context back into the hub query state.
- Update actions target the loaded patient record rather than a stray lookup value.
- Delete and restore block mismatched lookup-vs-loaded-patient actions.
- Date-only patient fields no longer drift when rendered through the patient workspace.

### Tasks

- [x] Sync workbench patient loads and creates back into shared hub context.
- [x] Tighten update, delete, and restore targeting around the loaded patient record.
- [x] Normalize date-only handling in registration, directory, and patient chart views.

## Phase 14C Checkpoint (Completed)

### Objective

Capture the shared-patient-context rollout in the tracker and verify the Angular app still builds cleanly after the workflow-safety changes.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects Phase 14 completion.
- Frontend build passes with the hub context and workbench safety changes.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 14 checkpoints and completion state.
- [x] Run frontend build validation for the shared patient context changes.

## Phase 13A Checkpoint (Completed)

### Objective

Consolidate patient worklist, directory, and registration entry points behind a single patient hub route.

### Exit Criteria

- A dedicated patient hub route exists.
- Shell navigation points clinicians to the patient hub instead of three separate patient destinations.
- Legacy patient routes continue to resolve without breaking bookmarks or deep links.

### Tasks

- [x] Add `patients/hub` route with tab-based patient workspace composition.
- [x] Update shell navigation to use a single patient hub entry point.
- [x] Preserve legacy `patients/worklist`, `patients/directory`, and `patients/workbench` links through redirects.

## Phase 13B Checkpoint (Completed)

### Objective

Move patient actions into the consolidated workspace so clinicians can stay in one flow while switching between triage, registry, and registration tasks.

### Exit Criteria

- Worklist actions target the registration mode inside the patient hub.
- Directory actions target the registration mode inside the patient hub.
- Cross-module patient links point back into the patient hub instead of the legacy routes.

### Tasks

- [x] Rewire worklist patient-edit actions to the patient hub registration tab.
- [x] Rewire directory patient-edit actions to the patient hub registration tab.
- [x] Update patient chart and client detail patient links to use the patient hub flow.

## Phase 13C Checkpoint (Completed)

### Objective

Capture the patient-hub rollout in the active tracker and verify the Angular app still builds cleanly after route consolidation.

### Exit Criteria

- `PROJECT_PHASE_TRACKER.md` reflects the new patient hub rollout.
- Frontend build passes with the new route/component composition.

### Tasks

- [x] Update `PROJECT_PHASE_TRACKER.md` with Phase 13 checkpoints and completion state.
- [x] Run frontend build validation for the patient hub changes.

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
